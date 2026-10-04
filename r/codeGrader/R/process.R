# =============================================================================
# Purpose:      Per-file pipeline: prepare (Rmd conversion, parse, scan), run in parallel workers, finalize results; dry-run mode.
# Author:       Matthew C. Vanderbilt (@mcvanderbilt)
# Created:      2026-10-03
# Modified:     2026-10-03 — Parse recovery; student-order package checks; redundant/repeated loads; set-up order; empty sections; graphics devices; practice notes; lintr style pass; required saved files; repeated root errors once
# Version:      1.7.0
# Tags:         automation, data-validation, reporting, teaching
# Status:       draft
# Level:        intermediate
# AI-Assisted:  generated (Claude) — see code-library AI-DISCLOSURE.md
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
  # Parse with recovery: a syntax error no longer stops the check. The lines
  # of each unreadable expression are replaced by comments (line numbers are
  # preserved) and recorded; everything else is still scanned and executed.
  pr <- grader_parse_recover(code_lines, fname)
  exprs <- pr$exprs
  syntax <- pr$errors                 # data.frame: first, last, message, text
  syntax$label <- character(nrow(syntax))
  if (nrow(syntax)) {
    # section label (nearest "# 7. BAR CHART ----" header above) for each skipped range
    hdr <- grep("^[[:space:]]*#.*(-{4,}|={4,}|#{4,})", code_lines)
    syntax$label <- vapply(syntax$first, function(l) {
      h <- hdr[hdr < l]
      if (length(h)) grader_header_label(code_lines[max(h)]) else ""
    }, character(1))
    if (any(grepl("[\u2018\u2019\u201c\u201d]", code_lines))) {
      row$other_flags <- "SMART_QUOTES (curly quotes pasted from Word/web)"
    }
    if (length(exprs) == 0) {         # nothing survived: old-style parse-error row
      if (is_rmd) unlink(code_path)
      row$status <- "Parse error"
      row$n_errors <- nrow(syntax); row$n_root_errors <- nrow(syntax); row$n_syntax_errors <- nrow(syntax)
      row$first_error <- syntax$message[1]
      return(list(done = TRUE, row = row, errors = NULL))
    }
    # the worker must run the cleaned code, never the unparseable original
    clean_path <- tempfile(fileext = ".R")
    writeLines(pr$clean_lines, clean_path, useBytes = TRUE)
    if (is_rmd) unlink(code_path)
    code_path <- clean_path
    code_lines <- pr$clean_lines
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

  # optional style pass (lintr; static, nothing executed). Runs on the original
  # .Rmd so chunk line numbers are right, unless syntax errors forced a cleaned copy.
  style <- NULL
  if (isTRUE(ctx$style)) {
    lint_path <- if (is_rmd && nrow(syntax) == 0) f else code_path
    style <- grader_style_check(lint_path, ctx)
  }

  run_dir <- tempfile("grader_run_"); dir.create(run_dir)
  if (!isTRUE(ctx$dry)) file.copy(ctx$data_file, run_dir)
  list(done = FALSE, f = f, fname = fname, is_rmd = is_rmd, code_path = code_path,
       code_tmp = is_rmd || nrow(syntax) > 0, syntax = syntax, style = style,
       sc = sc, info = info, run_dir = run_dir, row = row, scan_failed = scan_failed)
}

# ---------------------------------------------------------------------
# Style check with lintr (CG-035): a small, fixed set of linters chosen for
# course conventions. Returns list(n, examples, failed) or NULL if lintr is
# missing. Nothing from the student file is executed.
# ---------------------------------------------------------------------
grader_style_check <- function(path, ctx, max_examples = 5L) {
  if (!requireNamespace("lintr", quietly = TRUE)) return(NULL)
  res <- tryCatch({
    linters <- list(
      lintr::object_name_linter(styles = ctx$style_naming),
      lintr::assignment_linter(),
      lintr::infix_spaces_linter(),
      lintr::commas_linter(),
      lintr::line_length_linter(as.integer(ctx$style_line_length)),
      lintr::T_and_F_symbol_linter()
    )
    lintr::lint(path, linters = linters, parse_settings = FALSE)
  }, error = function(e) e)
  if (inherits(res, "error")) {
    return(list(n = NA_integer_, examples = "", failed = gsub("\\s+", " ", conditionMessage(res))))
  }
  n <- length(res)
  ex <- vapply(utils::head(res, max_examples), function(l) {
    sprintf("line %d: %s", l$line_number, sub("\\.$", "", l$message))
  }, character(1))
  list(n = n, examples = paste(ex, collapse = "; "), failed = NULL)
}

# ---------------------------------------------------------------------
# Parse with recovery. R's parse() gives up at the first syntax error; students
# then get no feedback on anything else. This walks the file line by line,
# accumulating lines until they form complete expression(s):
#   * complete        -> accept, start a new buffer on the next line
#   * still incomplete (open bracket, trailing operator, open string) -> keep going
#   * a real syntax error -> record it, replace the buffered lines with comment
#                            markers (so line numbers stay intact) and move on
# The cleaned text is then parsed once more with a srcfile named after the
# student's file, so later locations and messages carry the file name only
# (never the grader's folder path). Nothing from the student file is executed.
# Returns list(exprs, clean_lines, errors = data.frame(first, last, message, text)).
# ---------------------------------------------------------------------
grader_parse_recover <- function(code_lines, fname = "<student file>", max_errors = 50L) {
  n <- length(code_lines)
  clean <- code_lines
  err_first <- err_last <- integer(); err_msg <- err_txt <- character()
  marker <- "# [codeGrader: line skipped - syntax error]"
  incomplete_pat <- "unexpected end of input|INCOMPLETE_STRING|unexpected end of line"

  try_parse <- function(lines) {
    tryCatch({ parse(text = lines, keep.source = FALSE); "ok" },
             error = function(e) conditionMessage(e))
  }
  # "<text>:3:7: unexpected symbol\n3: drive counts\n ^" -> "unexpected symbol"
  core_msg <- function(msg) {
    first <- strsplit(msg, "\n", fixed = TRUE)[[1]][1]
    sub("^<text>:[0-9]+:[0-9]+: *", "", first)
  }
  record <- function(a, b, msg) {
    err_first <<- c(err_first, a); err_last <<- c(err_last, b)
    shown <- trimws(code_lines[a:b]); shown <- shown[nzchar(shown) & !startsWith(shown, "#")]
    shown <- if (length(shown)) substr(shown[1], 1, 60) else ""
    err_txt <<- c(err_txt, shown)
    where <- if (b > a) sprintf("lines %d-%d", a, b) else sprintf("line %d", a)
    err_msg <<- c(err_msg, sprintf("%s: %s%s", where, core_msg(msg),
                                   if (nzchar(shown)) sprintf(" in \"%s\"", shown) else ""))
    clean[a:b] <<- marker
  }

  start <- 1L; i <- 1L
  while (i <= n && length(err_first) < max_errors) {
    res <- try_parse(code_lines[start:i])
    if (identical(res, "ok")) {
      start <- i + 1L
    } else if (grepl(incomplete_pat, res)) {
      if (i == n) { record(start, n, res); start <- n + 1L }   # never closed before end of file
    } else {
      record(start, i, res); start <- i + 1L
    }
    i <- i + 1L
  }
  if (length(err_first) >= max_errors && start <= n) {        # give up on the remainder
    record(start, n, "<text>:1:1: too many syntax errors; remaining lines skipped")
  }

  exprs <- tryCatch(parse(text = clean, keep.source = TRUE,
                          srcfile = srcfilecopy(fname, clean, isFile = FALSE)),
                    error = function(e) NULL)
  if (is.null(exprs)) {                 # recovery itself failed: treat the whole file as unreadable
    msg <- tryCatch(parse(text = code_lines, keep.source = FALSE), error = function(e) conditionMessage(e))
    return(list(exprs = expression(), clean_lines = rep(marker, n),
                errors = data.frame(first = 1L, last = n, text = "",
                                    message = sprintf("line 1: %s", core_msg(as.character(msg))),
                                    stringsAsFactors = FALSE)))
  }
  list(exprs = exprs, clean_lines = clean,
       errors = data.frame(first = err_first, last = err_last, message = err_msg, text = err_txt,
                           stringsAsFactors = FALSE))
}

# ---------------------------------------------------------------------
# Phase 3 (in this session): combine static findings + worker results.
# ---------------------------------------------------------------------
grader_finalize_file <- function(prep, w, ctx) {
  on.exit({
    unlink(prep$run_dir, recursive = TRUE)
    if (isTRUE(prep$code_tmp)) unlink(prep$code_path)
  }, add = TRUE)
  row <- prep$row; sc <- prep$sc; info <- prep$info
  fname <- prep$fname; run_dir <- prep$run_dir
  syntax <- prep$syntax
  if (is.null(syntax)) syntax <- data.frame(first = integer(), last = integer(), message = character(),
                                            text = character(), label = character(), stringsAsFactors = FALSE)
  worker_ok <- !inherits(w, "worker_failed")

  # ---- package findings -----------------------------------------------
  # The worker attached only the packages the student loads, in the student's
  # order, so fn_pkg says what each call really resolved to for this student:
  #   resolved to a non-base package  -> that package is used (and was loaded)
  #   NA (not found)                  -> look the function up in the approved
  #                                      packages' export map: that package is
  #                                      used but never loaded
  loaded_real    <- setdiff(sc$loaded, "<dynamic>")       # in the student's order
  installed_real <- setdiff(sc$installed, "<dynamic>")
  expand <- function(p) unique(c(p, unlist(ctx$attach_map[intersect(p, names(ctx$attach_map))], use.names = FALSE)))
  fn_pkg   <- if (worker_ok) w$fn_pkg else character()
  used_pkgs <- setdiff(intersect(unique(fn_pkg[!is.na(fn_pkg)]), ctx$approved_ok), ctx$base_pkgs)
  unresolved <- names(fn_pkg)[is.na(fn_pkg)]
  covered    <- expand(loaded_real)                           # loaded directly or attached by another load
  not_loaded <- character()
  if (length(unresolved) && length(ctx$export_map)) {
    not_loaded <- unique(unlist(lapply(unresolved, function(fn) {
      hits <- names(ctx$export_map)[vapply(ctx$export_map, function(ex) fn %in% ex, logical(1))]
      hits <- setdiff(hits, c(ctx$base_pkgs, covered))
      if (length(hits) == 1) hits else if (length(hits) > 1) paste(hits, collapse = " or ") else character()
    }), use.names = FALSE))
  }
  nec_ns     <- setdiff(sc$ns_used, ctx$base_pkgs)
  necessary  <- unique(c(used_pkgs, nec_ns, not_loaded))
  installed_eff <- expand(installed_real)                   # installing tidyverse installs ggplot2, dplyr, ...
  if (sc$dyn_install) installed_eff <- union(installed_eff, expand(loaded_real))
  no_install <- setdiff(necessary, installed_eff)
  unapproved <- setdiff(unique(c(loaded_real, installed_real, sc$ns_used)),
                        c(ctx$base_pkgs, ctx$approved))

  # loaded but nothing from it (or from what it attaches) is used
  is_needed <- function(p) p %in% nec_ns || any(expand(p) %in% used_pkgs)
  cand <- loaded_real[loaded_real %in% ctx$approved_ok]
  loaded_unneeded <- cand[!vapply(cand, is_needed, logical(1))]

  # loaded or installed separately although another package already brings it
  # in: library(tidyverse) + library(ggplot2) -> "ggplot2 (included in tidyverse)"
  redundant_in <- function(p, set) {
    others <- setdiff(set, p)
    owners <- others[vapply(others, function(q) p %in% ctx$attach_map[[q]], logical(1))]
    if (length(owners)) sprintf("%s (included in %s)", p, owners[1]) else NA_character_
  }
  loaded_redundant    <- stats::na.omit(vapply(loaded_real,    redundant_in, character(1), set = loaded_real))
  installed_redundant <- stats::na.omit(vapply(installed_real, redundant_in, character(1), set = installed_real))
  if (isTRUE(ctx$dry)) {            # 'necessary' needs a real run; leave those checks blank in a dry run
    necessary <- not_loaded <- no_install <- loaded_unneeded <- character()
  }

  # library() called more than once for the same package (a require() used as
  # the condition of an install guard is not counted): "ggplot2 (2 calls)"
  lc <- sc$load_calls
  if (is.null(lc)) lc <- data.frame(pkg = character(), idx = integer(), guard = logical())
  lc <- lc[!lc$guard & lc$pkg != "<dynamic>", , drop = FALSE]
  tab <- table(lc$pkg)
  loaded_repeated <- if (length(tab)) sprintf("%s (%d calls)", names(tab)[tab > 1], as.integer(tab[tab > 1])) else character()

  # package install/load calls that come after other code has already run
  late <- if (is.null(sc$late_setup_idx)) integer() else sc$late_setup_idx
  setup_after_code <- vapply(late, function(i) {
    pk <- unique(c(sc$load_calls$pkg[sc$load_calls$idx == i]))
    pk <- setdiff(pk, "<dynamic>")
    sprintf("%s (%s)", if (length(pk)) paste(pk, collapse = "/") else "install.packages", grader_location(i, info))
  }, character(1))

  row$pkgs_loaded <- grader_fmt(sc$loaded)
  row$pkgs_install_attempted <- grader_fmt(sc$installed)
  row$pkgs_necessary <- grader_fmt(necessary)
  row$pkgs_necessary_not_loaded <- grader_fmt(not_loaded)
  row$pkgs_necessary_no_install_attempt <- grader_fmt(no_install)
  row$pkgs_loaded_not_necessary <- grader_fmt(loaded_unneeded)
  row$pkgs_loaded_redundant <- grader_fmt(loaded_redundant)
  row$pkgs_installed_redundant <- grader_fmt(installed_redundant)
  row$pkgs_loaded_repeated <- grader_fmt(loaded_repeated)
  row$pkgs_setup_after_code <- paste(setup_after_code, collapse = "; ")

  # ---- numbered sections with no code (CG-032) --------------------------
  # a section whose only code was skipped for a syntax error is not "empty"
  sections_empty <- setdiff(if (is.null(sc$sections_empty)) character() else sc$sections_empty, syntax$label)
  row$sections_without_code <- paste(sections_empty, collapse = "; ")

  # ---- graphics devices (CG-033): opened vs. closed ---------------------
  dev_opens <- if (is.null(sc$dev_opens)) data.frame(fn = character(), idx = integer()) else sc$dev_opens
  n_dev_open <- nrow(dev_opens); n_dev_close <- length(sc$dev_close_idx)
  dev_left_open <- if (worker_ok && !is.null(w$devices_left_open)) w$devices_left_open else 0L
  dev_note <- character()
  if (n_dev_open > n_dev_close || dev_left_open > 0) {
    opens <- vapply(seq_len(n_dev_open), function(k) sprintf("%s() at %s", dev_opens$fn[k], grader_location(dev_opens$idx[k], info)), character(1))
    dev_note <- sprintf("%s; dev.off() called %d time(s)%s", paste(opens, collapse = ", "), n_dev_close,
                        if (dev_left_open > 0) sprintf("; %d device(s) still open when the script ended", dev_left_open) else "")
  }
  row$graphics_devices <- if (n_dev_open || n_dev_close) sprintf("%d opened, %d closed", n_dev_open, n_dev_close) else ""
  row$graphics_device_note <- paste(dev_note, collapse = "")

  # ---- coding-practice notes (CG-034) ------------------------------------
  pr <- if (is.null(sc$practice)) data.frame(kind = character(), idx = integer()) else sc$practice
  practice_text <- c(
    attach = "attach() hides where variables come from; use data$column or with()",
    View = "View() opens a viewer window and does nothing in a script that is run or knitted; remove it before submitting",
    rm_ls = "rm(list = ls()) in the middle of a script deletes your own objects; if you use it, put it on the first line only",
    install_unguarded = "install.packages() runs (and re-downloads) every time the script is run; wrap it as if (!require(pkg)) install.packages(\"pkg\")"
  )
  practice_notes <- character()
  if (nrow(pr)) {
    pr <- pr[!duplicated(pr$kind), , drop = FALSE]                 # one note per kind, at its first location
    practice_notes <- sprintf("%s (%s)", practice_text[pr$kind], vapply(pr$idx, grader_location, character(1), info = info))
  }
  row$practice_notes <- paste(practice_notes, collapse = "; ")

  # ---- style check (CG-035) -----------------------------------------------
  st <- prep$style
  if (!is.null(st)) {
    row$style_issues <- st$n
    row$style_examples <- if (!is.null(st$failed)) paste("style check failed:", st$failed) else st$examples
  }
  row$pkgs_unapproved <- grader_fmt(unapproved)
  row$other_data_calls <- grader_fmt(sc$other_reads)

  lib_flags <- c(
    if (length(unapproved))   "UNAPPROVED_PKG",
    if (length(not_loaded))   "NECESSARY_PKG_NOT_LOADED",
    if (length(no_install))   "NECESSARY_PKG_NO_INSTALL_ATTEMPT",
    if (length(loaded_unneeded)) "UNNECESSARY_PKG_LOADED",
    if (length(loaded_redundant) || length(installed_redundant)) "REDUNDANT_PKG",
    if (length(loaded_repeated))  "PKG_LOADED_REPEATEDLY",
    if (length(late))             "PKG_SETUP_AFTER_CODE",
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
    if (nzchar(row$other_flags)) row$other_flags,         # e.g. SMART_QUOTES, set while parsing
    if (length(sc$rng_missing_idx)) "SEED_MISSING_BEFORE_RANDOM",
    if (nrow(hc)) "HARDCODED_PATH_OR_FILE",
    if (n_abs > 0) "ABSOLUTE_PATH_LITERAL",
    if (sc$n_exprs == 0) "EMPTY_SCRIPT",
    if (!is.null(prep$scan_failed)) "STATIC_SCAN_FAILED",
    if (length(sections_empty)) "SECTION_WITHOUT_CODE",
    if (length(dev_note)) "GRAPHICS_DEVICE_LEFT_OPEN",
    if (length(practice_notes)) "PRACTICE_NOTE",
    if (!is.null(st) && !is.na(st$n) && st$n > 0) "STYLE_ISSUES"
  )

  # ---- syntax errors (lines skipped by the parse recovery) -------------
  # Reported like root errors: each is the student's own, independent mistake.
  syndf <- NULL
  row$n_syntax_errors <- nrow(syntax)
  if (nrow(syntax)) {
    oth_flags <- c(oth_flags, "SYNTAX_ERROR_SKIPPED")
    lab <- syntax$label
    syndf <- data.frame(
      file = fname, expr_number = NA_integer_, error_type = "syntax", caused_by = "",
      location = ifelse(nzchar(lab), paste0(sub(":.*$", "", syntax$message), " [", lab, "]"),
                        sub(":.*$", "", syntax$message)),
      failing_function = "", failing_call = syntax$text,
      message = sub("^lines? [0-9-]+: ", "", syntax$message),
      .line = syntax$first, stringsAsFactors = FALSE)
  }

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
    row$n_warnings <- w$n_warn
    row$runtime_sec <- round(w$elapsed, 2)
    row$pct_exprs_ok <- if (sc$n_exprs) round(100 * w$n_ok / sc$n_exprs, 1) else NA_real_
    row$status <- if (length(w$errors) || nrow(syntax)) "Executed with errors" else "Executed without error"
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
          message = er$message,
          .line = if (er$i >= 1 && er$i <= nrow(info)) info$src_first[er$i] else NA_integer_,
          stringsAsFactors = FALSE)
      }))
      # The same root error repeated (e.g. "object 'wk1data' not found" at every
      # later use) is reported once; repeats point back to the first occurrence.
      is_root <- errdf$error_type == "root"
      first_at <- match(errdf$message, errdf$message[is_root])
      rep_of <- which(is_root)[first_at]
      repeat_i <- which(is_root & !is.na(rep_of) & rep_of < seq_len(nrow(errdf)))
      if (length(repeat_i)) {
        errdf$error_type[repeat_i] <- "repeat"
        errdf$caused_by[repeat_i]  <- errdf$location[rep_of[repeat_i]]
      }
    }
    errdf <- rbind(syndf, errdf)                      # syntax + runtime errors, in file order
    if (!is.null(errdf) && nrow(errdf)) {
      errdf <- errdf[order(errdf$.line, na.last = TRUE), , drop = FALSE]; errdf$.line <- NULL
      rownames(errdf) <- NULL
      row$n_errors         <- nrow(errdf)
      row$n_root_errors    <- sum(errdf$error_type %in% c("root", "syntax"))
      row$n_cascade_errors <- sum(errdf$error_type == "cascade")
      row$n_repeat_errors  <- sum(errdf$error_type == "repeat")
      row$pct_exprs_no_root_error <- if (sc$n_exprs) round(100 * (sc$n_exprs - sum(errdf$error_type == "root")) / sc$n_exprs, 1) else NA_real_
      roots <- errdf[errdf$error_type %in% c("root", "syntax"), , drop = FALSE]
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
    # required file names (CG-036): each required name/pattern must match a saved file (case-insensitive)
    req <- ctx$required_files
    if (isTRUE(ctx$expect_saved) && length(req) && length(saved)) {
      got <- vapply(req, function(r) any(grepl(utils::glob2rx(r), basename(saved), ignore.case = TRUE)), logical(1))
      if (any(!got)) {
        row$required_files_missing <- paste(req[!got], collapse = "; ")
        oth_flags <- c(oth_flags, "REQUIRED_FILE_NOT_SAVED")
      }
    }
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

  if (is.null(errdf) && !is.null(syndf)) {          # dry run or failed worker: still report syntax errors
    errdf <- syndf; errdf$.line <- NULL
    row$n_errors <- row$n_errors + nrow(syndf); row$n_root_errors <- row$n_root_errors + nrow(syndf)
    if (!nzchar(row$first_error)) row$first_error <- syndf$message[1]
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
                                seed_inject_idx = prep$sc$rng_missing_idx,
                                # the student's own library()/require() packages, in order
                                student_pkgs = intersect(setdiff(prep$sc$loaded, "<dynamic>"), ctx$approved_ok)),
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
