# =============================================================================
# Purpose:      Per-file pipeline: prepare (Rmd conversion, parse, scan), run in parallel workers, finalize results; dry-run mode.
# Author:       Matthew C. Vanderbilt
# Created:      2026-10-03
# Modified:     2026-10-03
# Tags:         [TO CONFIRM against code-library root TAGS.md] education; grading; code-evaluation
# Status:       draft
# Level:        intermediate
# AI-Assisted:  Yes - Claude (Anthropic). See AI-DISCLOSURE.md (pending).
# Dependencies: callr, knitr, tools, utils
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_worker_failed <- function(msg) {
  structure(list(msg = gsub("\\s+", " ", msg)), class = "worker_failed")
}

grader_error_row <- function(f, status, msg) {
  r <- grader_row_template()
  r$file <- basename(f); r$status <- status
  r$n_errors <- 1L; r$n_root_errors <- 1L
  r$first_error <- gsub("\\s+", " ", msg)
  r
}

# ---------------------------------------------------------------------
# Phase 1 (in this session): convert Rmd, parse, static scan.
# Returns list(done = TRUE, row, errors) for files that cannot be run,
# otherwise list(done = FALSE, ...) holding what the worker/finalizer needs.
# ---------------------------------------------------------------------
grader_prepare_file <- function(f, ctx) {
  fname  <- basename(f)
  is_rmd <- grepl("\\.rmd$", f, ignore.case = TRUE)
  row <- grader_row_template()
  row$file <- fname
  row$file_type <- if (is_rmd) "Rmd" else "R"

  code_path <- f
  if (is_rmd) {                       # Rmd -> plain R code (nothing executed)
    code_path <- tempfile(fileext = ".R")
    err <- NULL
    ok <- tryCatch({
      suppressMessages(knitr::purl(f, output = code_path, documentation = 1, quiet = TRUE))
      TRUE
    }, error = function(e) { err <<- gsub("\\s+", " ", conditionMessage(e)); FALSE })
    if (!ok) {
      row$status <- "Rmd conversion error"; row$n_errors <- 1L; row$n_root_errors <- 1L
      row$first_error <- err
      return(list(done = TRUE, row = row, errors = NULL))
    }
  }

  code_lines <- suppressWarnings(tryCatch(readLines(code_path, warn = FALSE, encoding = "UTF-8"),
                                          error = function(e) NULL))
  if (is.null(code_lines)) {
    if (is_rmd) unlink(code_path)
    row$status <- "Parse error"; row$n_errors <- 1L; row$n_root_errors <- 1L
    row$first_error <- "The file could not be read as text"
    return(list(done = TRUE, row = row, errors = NULL))
  }
  parse_err <- NULL
  exprs <- tryCatch(parse(file = code_path, keep.source = TRUE, encoding = "UTF-8"),
                    error = function(e) { parse_err <<- gsub("\\s+", " ", conditionMessage(e)); NULL })
  if (!is.null(parse_err)) {
    if (is_rmd) unlink(code_path)
    row$status <- "Parse error"; row$n_errors <- 1L; row$n_root_errors <- 1L
    row$first_error <- parse_err
    if (any(grepl("[\u2018\u2019\u201c\u201d]", code_lines))) {
      row$other_flags <- "SMART_QUOTES (curly quotes pasted from Word/web)"
    }
    return(list(done = TRUE, row = row, errors = NULL))
  }

  # If the static scan itself fails, still run the script (flagged STATIC_SCAN_FAILED)
  scan_failed <- NULL
  sc <- tryCatch(grader_scan_script(exprs, code_lines, is_rmd, ctx$rng_fns),
                 error = function(e) { scan_failed <<- gsub("\\s+", " ", conditionMessage(e)); NULL })
  if (is.null(sc)) sc <- grader_empty_scan(exprs)
  info <- sc$expr_info
  info$src_first <- info$first; info$src_last <- info$last; info$note <- ""
  if (is_rmd) {
    info <- tryCatch(grader_map_rmd_lines(info, readLines(f, warn = FALSE, encoding = "UTF-8"), code_lines),
                     error = function(e) { info$note <- "purled"; info })
  }

  run_dir <- tempfile("grader_run_"); dir.create(run_dir)
  if (!isTRUE(ctx$dry)) file.copy(ctx$data_file, run_dir)
  list(done = FALSE, f = f, fname = fname, is_rmd = is_rmd, code_path = code_path,
       sc = sc, info = info, run_dir = run_dir, row = row, scan_failed = scan_failed)
}

# ---------------------------------------------------------------------
# Phase 3 (in this session): combine static findings + worker results.
# ---------------------------------------------------------------------
grader_finalize_file <- function(prep, w, ctx) {
  on.exit({
    unlink(prep$run_dir, recursive = TRUE)
    if (prep$is_rmd) unlink(prep$code_path)
  }, add = TRUE)
  row <- prep$row; sc <- prep$sc; info <- prep$info
  fname <- prep$fname; run_dir <- prep$run_dir
  worker_ok <- !inherits(w, "worker_failed")

  # ---- package findings -----------------------------------------------
  loaded_real    <- setdiff(sc$loaded, "<dynamic>")
  installed_real <- setdiff(sc$installed, "<dynamic>")
  fn_pkg   <- if (worker_ok) w$fn_pkg else character()
  nec_bare <- setdiff(intersect(unique(fn_pkg[!is.na(fn_pkg)]), ctx$approved_ok), ctx$base_pkgs)
  nec_ns   <- setdiff(sc$ns_used, ctx$base_pkgs)
  necessary <- union(nec_bare, nec_ns)
  covered   <- union(loaded_real, unlist(ctx$attach_map[intersect(loaded_real, names(ctx$attach_map))]))
  not_loaded <- setdiff(nec_bare, covered)
  installed_eff <- if (sc$dyn_install) union(installed_real, loaded_real) else installed_real
  no_install <- setdiff(necessary, installed_eff)
  unapproved <- setdiff(unique(c(loaded_real, installed_real, sc$ns_used)),
                        c(ctx$base_pkgs, ctx$approved))
  is_needed <- function(p) p %in% nec_ns || any(c(p, ctx$attach_map[[p]]) %in% nec_bare)
  cand <- loaded_real[loaded_real %in% ctx$approved_ok]
  loaded_unneeded <- cand[!vapply(cand, is_needed, logical(1))]
  if (isTRUE(ctx$dry)) {            # 'necessary' needs a real run; leave those checks blank in a dry run
    necessary <- not_loaded <- no_install <- loaded_unneeded <- character()
  }

  row$pkgs_loaded <- grader_fmt(sc$loaded)
  row$pkgs_install_attempted <- grader_fmt(sc$installed)
  row$pkgs_necessary <- grader_fmt(necessary)
  row$pkgs_necessary_not_loaded <- grader_fmt(not_loaded)
  row$pkgs_necessary_no_install_attempt <- grader_fmt(no_install)
  row$pkgs_loaded_not_necessary <- grader_fmt(loaded_unneeded)
  row$pkgs_unapproved <- grader_fmt(unapproved)
  row$other_data_calls <- grader_fmt(sc$other_reads)

  lib_flags <- c(
    if (length(unapproved))   "UNAPPROVED_PKG",
    if (length(not_loaded))   "NECESSARY_PKG_NOT_LOADED",
    if (length(no_install))   "NECESSARY_PKG_NO_INSTALL_ATTEMPT",
    if (length(loaded_unneeded)) "UNNECESSARY_PKG_LOADED",
    if (sc$dyn_load || sc$dyn_install) "LIBRARY_LIST_UNRESOLVED"
  )

  # ---- seed + hard-coding findings ------------------------------------
  row$set_seed_calls <- length(sc$seed_idx)
  row$rng_blocks <- sc$rng_blocks
  row$rng_blocks_missing_seed <- paste(vapply(sc$rng_missing_idx, grader_location, character(1), info = info),
                                       collapse = "; ")
  io <- sc$io[sc$io$kind == "literal", , drop = FALSE]
  hc <- rbind(data.frame(fn = io$fn, idx = io$idx, text = io$text, stringsAsFactors = FALSE),
              sc$hc[, c("fn", "idx", "text"), drop = FALSE])
  hc <- hc[!duplicated(hc[, c("fn", "idx", "text")]), , drop = FALSE]
  abs_pat <- "^([A-Za-z]:[/\\\\]|\\\\\\\\|/|~)"
  n_abs <- sum(grepl(abs_pat, hc$text))
  row$hardcode_check <- if (nrow(hc)) "Fail (hard-coded file/path in function call)"
                        else "Pass (no hard-coded paths in function calls)"
  if (nrow(hc)) {
    row$hardcoded_calls <- paste(sprintf("%s (%s): %s", hc$fn,
                                         vapply(hc$idx, grader_location, character(1), info = info),
                                         substr(hc$text, 1, 40)), collapse = "; ")
  }
  oth_flags <- c(
    if (length(sc$rng_missing_idx)) "SEED_MISSING_BEFORE_RANDOM",
    if (nrow(hc)) "HARDCODED_PATH_OR_FILE",
    if (n_abs > 0) "ABSOLUTE_PATH_LITERAL",
    if (sc$n_exprs == 0) "EMPTY_SCRIPT",
    if (!is.null(prep$scan_failed)) "STATIC_SCAN_FAILED"
  )

  # ---- execution results ----------------------------------------------
  errdf <- NULL
  row$exprs_total <- sc$n_exprs
  if (isTRUE(ctx$dry)) {
    row$status <- "Dry run (not executed)"
  } else if (!worker_ok) {
    row$status <- "Process failed or timed out"
    row$n_errors <- 1L; row$n_root_errors <- 1L
    row$first_error <- w$msg
  } else {
    row$exprs_ok <- w$n_ok
    row$n_errors <- length(w$errors)
    row$n_warnings <- w$n_warn
    row$runtime_sec <- round(w$elapsed, 2)
    row$pct_exprs_ok <- if (sc$n_exprs) round(100 * w$n_ok / sc$n_exprs, 1) else NA_real_
    row$status <- if (length(w$errors)) "Executed with errors" else "Executed without error"
    row$data_reads_redirected <- w$reads
    if (length(w$blocked)) {
      tb <- table(w$blocked)
      row$blocked_calls <- paste0(names(tb), "(", as.integer(tb), ")", collapse = "; ")
    }
    if (length(w$preload_failed)) oth_flags <- c(oth_flags, "APPROVED_PKG_FAILED_TO_LOAD")

    if (length(w$errors)) {
      idx <- vapply(w$errors, function(er) er$i, integer(1))
      cls <- grader_classify_errors(idx, sc)
      errdf <- do.call(rbind, lapply(seq_along(w$errors), function(j) {
        er <- w$errors[[j]]
        data.frame(
          file = fname, expr_number = er$i, error_type = cls$type[j],
          caused_by = if (is.na(cls$by[j])) "" else grader_location(cls$by[j], info),
          location = grader_location(er$i, info),
          failing_function = if (is.na(er$fn)) "" else er$fn,
          failing_call = if (is.na(er$call)) "" else er$call,
          message = er$message, stringsAsFactors = FALSE)
      }))
      row$n_root_errors    <- sum(errdf$error_type == "root")
      row$n_cascade_errors <- sum(errdf$error_type == "cascade")
      row$pct_exprs_no_root_error <- if (sc$n_exprs) round(100 * (sc$n_exprs - row$n_root_errors) / sc$n_exprs, 1) else NA_real_
      roots <- errdf[errdf$error_type == "root", , drop = FALSE]
      row$root_error_summary <- paste(sprintf("%s%s: %s", roots$location,
                                              ifelse(nzchar(roots$failing_function), paste0(" in ", roots$failing_function, "()"), ""),
                                              sub("\\.$", "", substr(roots$message, 1, 100))), collapse = " | ")
      row$first_error_location <- errdf$location[1]
      row$first_error_function <- errdf$failing_function[1]
      row$first_error <- errdf$message[1]
    } else {
      row$pct_exprs_no_root_error <- if (sc$n_exprs) 100 else NA_real_
    }

    # saved files
    saved <- w$files_written
    row$files_saved <- paste(saved, collapse = "; ")
    if (isTRUE(ctx$expect_saved) && !length(saved)) oth_flags <- c(oth_flags, "EXPECTED_FILE_NOT_SAVED")
    if (!isTRUE(ctx$expect_saved) && length(saved))  oth_flags <- c(oth_flags, "UNEXPECTED_FILE_SAVED")
    if (length(saved)) {
      dd <- file.path(ctx$saved_dir, tools::file_path_sans_ext(fname))
      for (ff in saved) {
        dest <- file.path(dd, ff)
        dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
        if (!isTRUE(file.copy(file.path(run_dir, ff), dest, overwrite = TRUE))) {
          message("WARNING: could not copy saved file '", ff, "' for ", fname)
        }
      }
    }
    # console output for your manual review
    cl <- file.path(run_dir, ".grader_console.txt")
    if (ctx$save_console && file.exists(cl)) {
      dir.create(ctx$console_dir, recursive = TRUE, showWarnings = FALSE)
      if (isTRUE(file.copy(cl, file.path(ctx$console_dir, paste0(fname, ".txt")), overwrite = TRUE))) {
        row$console_log <- paste0(fname, ".txt")
      }
    }
  }

  row$library_flags <- paste(lib_flags, collapse = "; ")
  row$other_flags   <- paste(oth_flags, collapse = "; ")
  list(row = row, errors = errdf)
}

# ---------------------------------------------------------------------
# Phase 2: scheduler. Keeps up to `workers` student scripts running at once,
# each in its own R process; a timeout or crash only affects that student.
# Each finished file is also written to a checkpoint file right away.
# ---------------------------------------------------------------------
grader_run_jobs <- function(code_files, ctx, workers) {
  n <- length(code_files)
  results <- vector("list", n)
  queue <- seq_len(n); active <- list(); n_done <- 0L
  on.exit(for (j in active) try(j$proc$kill(), silent = TRUE), add = TRUE)   # Esc / error: stop workers

  store <- function(k, res) {
    results[[k]] <<- res
    n_done <<- n_done + 1L
    grader_checkpoint(ctx, res$row)
    message(sprintf("[%d/%d done] %s -> %s", n_done, n, basename(code_files[k]), res$row$status))
  }
  finish <- function(k, prep, w) {
    res <- tryCatch(grader_finalize_file(prep, w, ctx), error = function(e) {
      unlink(prep$run_dir, recursive = TRUE)
      list(row = grader_error_row(prep$f, "Grader error", conditionMessage(e)), errors = NULL)
    })
    store(k, res)
  }

  while (length(queue) || length(active)) {
    # launch as many as allowed
    while (length(queue) && length(active) < workers) {
      k <- queue[1]; queue <- queue[-1]
      f <- code_files[k]
      prep <- tryCatch(grader_prepare_file(f, ctx),
                       error = function(e) list(done = TRUE, row = grader_error_row(f, "Grader error", conditionMessage(e)), errors = NULL))
      if (isTRUE(prep$done)) {
        store(k, list(row = prep$row, errors = prep$errors))
        next
      }
      if (ctx$use_editor) try(rstudioapi::navigateToFile(f), silent = TRUE)
      message(sprintf("[%d/%d started] %s", k, n, basename(f)))
      proc <- tryCatch(
        callr::r_bg(grader_worker,
                    args = list(code_path = prep$code_path, data_file = ctx$data_file,
                                approved = ctx$approved_ok, base_pkgs = ctx$base_pkgs,
                                fn_names = setdiff(prep$sc$called, prep$sc$defined),
                                expr_timeout_sec = ctx$expr_timeout_sec,
                                seed_value = ctx$seed_value,
                                seed_inject_idx = prep$sc$rng_missing_idx),
                    wd = prep$run_dir, stdout = NULL, stderr = NULL, supervise = TRUE),
        error = function(e) e)
      if (inherits(proc, "error")) {
        finish(k, prep, grader_worker_failed(paste("Could not start worker:", conditionMessage(proc))))
        next
      }
      active[[as.character(k)]] <- list(proc = proc, prep = prep, start = Sys.time())
    }
    # check running ones (a problem with one worker never affects the others)
    for (key in names(active)) {
      job <- active[[key]]
      outcome <- tryCatch({
        elapsed <- as.numeric(difftime(Sys.time(), job$start, units = "secs"))
        alive <- job$proc$is_alive()
        if (alive && elapsed <= ctx$script_timeout_sec) {
          NULL
        } else if (alive) {
          try(job$proc$kill(), silent = TRUE)
          grader_worker_failed(sprintf("Script exceeded %d seconds and was stopped", ctx$script_timeout_sec))
        } else {
          tryCatch(job$proc$get_result(), error = function(e) grader_worker_failed(conditionMessage(e)))
        }
      }, error = function(e) grader_worker_failed(paste("Lost contact with worker:", conditionMessage(e))))
      if (is.null(outcome)) next
      active[[key]] <- NULL
      finish(as.integer(key), job$prep, outcome)
    }
    if (length(active)) Sys.sleep(0.25)
  }
  results
}

# ---------------------------------------------------------------------
# Dry run: parse + static scan only. Nothing from any student file is executed.
# ---------------------------------------------------------------------
grader_dry_run <- function(code_files, ctx) {
  stub <- grader_worker_failed("Dry run: not executed")
  lapply(seq_along(code_files), function(k) {
    f <- code_files[k]
    message(sprintf("[%d/%d] %s", k, length(code_files), basename(f)))
    tryCatch({
      prep <- grader_prepare_file(f, ctx)
      if (isTRUE(prep$done)) list(row = prep$row, errors = NULL) else grader_finalize_file(prep, stub, ctx)
    }, error = function(e) list(row = grader_error_row(f, "Grader error", conditionMessage(e)), errors = NULL))
  })
}
