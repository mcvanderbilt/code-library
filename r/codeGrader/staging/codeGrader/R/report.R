# =============================================================================
# Purpose:      Output table template, cumulative CSV appends, draft feedback, audit log, class summary, and the cohort Excel workbook.
# Author:       Matthew C. Vanderbilt
# Created:      2026-10-03
# Modified:     2026-10-03
# Tags:         [TO CONFIRM against code-library root TAGS.md] education; grading; code-evaluation
# Status:       draft
# Level:        intermediate
# AI-Assisted:  Yes - Claude (Anthropic). See AI-DISCLOSURE.md (pending).
# Dependencies: utils, tools, stats; openxlsx (optional, for Excel output)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_row_template <- function() {
  list(
    file_role = "student", file = "", file_md5 = "", file_type = "", status = "",
    pct_exprs_ok = NA_real_, exprs_total = NA_integer_, exprs_ok = NA_integer_,
    n_errors = 0L, n_root_errors = 0L, n_cascade_errors = 0L, pct_exprs_no_root_error = NA_real_,
    n_warnings = NA_integer_, runtime_sec = NA_real_,
    first_error_location = "", first_error_function = "", first_error = "", root_error_summary = "",
    library_flags = "", other_flags = "",
    pkgs_loaded = "", pkgs_install_attempted = "", pkgs_necessary = "",
    pkgs_necessary_not_loaded = "", pkgs_necessary_no_install_attempt = "",
    pkgs_loaded_not_necessary = "", pkgs_unapproved = "",
    set_seed_calls = NA_integer_, rng_blocks = NA_integer_, rng_blocks_missing_seed = "",
    hardcode_check = "", hardcoded_calls = "",
    data_reads_redirected = NA_integer_, blocked_calls = "", other_data_calls = "",
    files_saved = "", console_log = "", feedback_text = ""
  )
}

grader_row_df <- function(row) as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)

# "lines 12-14 [chunk or section label]" for expression number i
grader_location <- function(i, info) {
  if (is.null(i) || is.na(i) || i < 1 || i > nrow(info)) return("")
  a <- info$src_first[i]; b <- info$src_last[i]
  s <- if (is.na(a)) "" else if (!is.na(b) && b > a) sprintf("lines %d-%d", a, b) else sprintf("line %d", a)
  lab <- info$label[i]
  if (!is.na(lab) && nzchar(lab)) s <- paste0(s, " [", lab, "]")
  if (identical(info$note[i], "purled")) s <- paste0(s, " (line in code extracted from Rmd)")
  s
}

# ---- append to a cumulative CSV --------------------------------------
# Header is written only when the file is created. If the column layout changed
# (new grader version) rows go to a matching "_newlayout" file instead of corrupting
# the old one. If the file is locked (open in Excel) rows go to a _PENDING_ file.
grader_append_csv <- function(df, path) {
  want <- names(df)
  base <- sub("\\.csv$", "", basename(path))
  others <- list.files(dirname(path), full.names = TRUE)
  others <- others[startsWith(basename(others), paste0(base, "_")) & endsWith(basename(others), "_newlayout.csv")]
  target <- NULL; first <- TRUE
  for (cnd in c(path, others)) {
    if (!file.exists(cnd)) { target <- cnd; first <- TRUE; break }
    hdr <- tryCatch(names(utils::read.csv(cnd, nrows = 1, check.names = FALSE)), error = function(e) character())
    if (identical(hdr, want)) { target <- cnd; first <- FALSE; break }
  }
  if (is.null(target)) {
    target <- file.path(dirname(path), paste0(base, "_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_newlayout.csv"))
    first <- TRUE
    message("Existing file has different columns (grader version change?). Starting: ", basename(target))
  }
  ok <- tryCatch({
    utils::write.table(df, target, sep = ",", row.names = FALSE, col.names = first,
                       append = !first, qmethod = "double", na = "")
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok) {
    pending <- file.path(dirname(path), paste0(base, "_PENDING_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"))
    utils::write.csv(df, pending, row.names = FALSE, na = "")
    message("Could not write to ", basename(target), " (is it open in Excel?). Saved this run to ", basename(pending),
            " - append its rows to the main file later.")
    return(pending)
  }
  target
}

grader_save_results <- function(results, err_df, inp, run_lines, run_id) {
  dir.create(inp$output_folder, recursive = TRUE, showWarnings = FALSE)
  paths <- list(
    summary = grader_append_csv(results, file.path(inp$output_folder, paste0(inp$output_name, ".csv"))),
    errors  = NA_character_,
    info    = file.path(inp$output_folder, paste0(inp$output_name, "_run_info.txt"))
  )
  if (!is.null(err_df) && nrow(err_df)) {
    paths$errors <- grader_append_csv(err_df, file.path(inp$output_folder, paste0(inp$output_name, "_errors.csv")))
  }
  tryCatch(cat(c(paste0("==================== run ", run_id, " ===================="), run_lines, ""),
               file = paths$info, sep = "\n", append = TRUE),
           error = function(e) message("WARNING: could not write the run-info file: ", conditionMessage(e)),
           warning = function(w) message("WARNING: could not write the run-info file: ", conditionMessage(w)))
  paths
}

grader_show_results <- function(results) {
  if (interactive()) try(utils::View(results, title = "Grading results"), silent = TRUE)
  invisible(results)
}

# ---- draft student feedback (instructor reviews before posting) ----------
grader_feedback_text <- function(r) {
  s <- character()
  st <- r$status
  fl <- paste(r$library_flags, r$other_flags)
  if (st == "Unsupported file type") {
    return("This file type is not accepted for this assignment (only .R or .Rmd files are accepted).")
  }
  if (st == "Grader error" || st == "Rmd conversion error") {
    return("The automated check could not be completed for this file; your instructor will review it manually.")
  }
  if (st == "Parse error") {
    s <- c(s, sprintf("Your file could not be read by R because of a syntax error (%s).", r$first_error))
    if (grepl("SMART_QUOTES", fl)) s <- c(s, "It contains curly quotes, usually pasted from Word or a web page; use straight quotes instead.")
  } else if (st == "Process failed or timed out") {
    s <- c(s, "Your script did not finish running (it crashed or exceeded the time limit).")
  } else if (st == "Executed with errors") {
    follow <- if (r$n_cascade_errors > 0) sprintf(" (plus %d follow-on error(s) caused by them)", r$n_cascade_errors) else ""
    s <- c(s, sprintf("Your script has %d independent error(s)%s: %s.", r$n_root_errors, follow, r$root_error_summary))
  } else if (st == "Executed without error") {
    s <- c(s, "Your script ran from start to finish without errors.")
  }
  if (nzchar(r$pkgs_unapproved))
    s <- c(s, sprintf("Packages not on the approved list: %s. Use only approved packages.", r$pkgs_unapproved))
  if (nzchar(r$pkgs_necessary_not_loaded))
    s <- c(s, sprintf("Your code uses functions from %s but does not load them with library().", r$pkgs_necessary_not_loaded))
  if (nzchar(r$pkgs_necessary_no_install_attempt))
    s <- c(s, sprintf("Your script does not include code to install: %s.", r$pkgs_necessary_no_install_attempt))
  if (nzchar(r$pkgs_loaded_not_necessary))
    s <- c(s, sprintf("These packages are loaded but not used: %s.", r$pkgs_loaded_not_necessary))
  if (grepl("LIBRARY_LIST_UNRESOLVED", fl))
    s <- c(s, "Your package list could not be read completely by the automated check; your instructor will verify it.")
  if (nzchar(r$rng_blocks_missing_seed))
    s <- c(s, sprintf("Code that generates random numbers (%s) has no set.seed() earlier in its code block. Add set.seed() before random code so results can be reproduced.", r$rng_blocks_missing_seed))
  if (nzchar(r$hardcoded_calls))
    s <- c(s, sprintf("Hard-coded file paths or names appear directly in function calls (%s). Store such values in a variable first, then pass the variable to the function.", r$hardcoded_calls))
  if (grepl("EXPECTED_FILE_NOT_SAVED", fl))
    s <- c(s, "No saved output file was found, but this assignment requires one.")
  if (grepl("UNEXPECTED_FILE_SAVED", fl))
    s <- c(s, sprintf("Your script saved a file (%s) that this assignment does not require.", r$files_saved))
  s <- c(s, "These automated checks cover whether your code runs and follows course conventions; the accuracy of your results is reviewed separately by your instructor.")
  paste(s, collapse = " ")
}

# CSV for the student information system. instructor_comments is yours to fill in.
grader_feedback_df <- function(results, run_id) {
  st <- results[results$file_role == "student" & nzchar(results$feedback_text), , drop = FALSE]
  data.frame(run_id = run_id, file = st$file, status = st$status, feedback_text = st$feedback_text,
             instructor_comments = "", stringsAsFactors = FALSE)
}

grader_save_feedback <- function(results, inp, run_id) {
  fb <- grader_feedback_df(results, run_id)
  if (!nrow(fb)) return(NA_character_)
  grader_append_csv(fb, file.path(inp$output_folder, paste0(inp$output_name, "_feedback.csv")))
}

# Permanent, append-only log across ALL runs and assignments in this output folder.
grader_append_audit_log <- function(results, inp, run_id, results_path, git = NULL) {
  if (is.null(git)) git <- list(commit = "", branch = "", tag = "", uncommitted = "")
  md5 <- function(p) if (!is.null(p) && file.exists(p)) unname(tools::md5sum(p)) else ""
  new <- data.frame(
    run_id = run_id, run_time = results$run_time, assignment = results$assignment,
    grader_version = grader_version(), git_commit = git$commit, git_branch = git$branch,
    git_tag = git$tag, git_uncommitted_changes = git$uncommitted,
    r_version = R.version.string, seed_value = inp$seed_value,
    data_file = basename(inp$data_file), data_file_md5 = md5(inp$data_file),
    approved_list = basename(inp$approved_file), approved_list_md5 = md5(inp$approved_file),
    file_role = results$file_role, file = results$file, file_md5 = results$file_md5,
    status = results$status, library_flags = results$library_flags, other_flags = results$other_flags,
    n_errors = results$n_errors, first_error = results$first_error,
    feedback_text = results$feedback_text, results_file = basename(results_path),
    stringsAsFactors = FALSE)
  grader_append_csv(new, file.path(inp$output_folder, "grading_audit_log.csv"))
}

# Checkpoint: each finished file is written immediately so a crash mid-run loses nothing.
grader_checkpoint <- function(ctx, row) {
  if (is.null(ctx$checkpoint)) return(invisible())
  tryCatch({
    first <- !file.exists(ctx$checkpoint)
    utils::write.table(grader_row_df(row), ctx$checkpoint, sep = ",", row.names = FALSE,
                       col.names = first, append = !first, qmethod = "double", na = "")
  }, error = function(e) NULL, warning = function(w) NULL)
  invisible()
}

# ---- class summary (long format so it can be appended run after run) -----
grader_class_summary <- function(results, err_df, run_id, assignment = NA_real_) {
  st <- results[results$file_role == "student", , drop = FALSE]
  n <- nrow(st); out <- list()
  add <- function(section, item, k, note = "") {
    out[[length(out) + 1L]] <<- data.frame(
      run_id = run_id, assignment = assignment, section = section, item = item, n = as.integer(k),
      pct = if (n > 0) round(100 * k / n, 1) else NA_real_, note = note, stringsAsFactors = FALSE)
  }
  count_items <- function(x, sep) {
    x <- x[!is.na(x) & nzchar(x)]
    items <- trimws(unlist(strsplit(x, sep)))
    items <- items[nzchar(items)]
    if (!length(items)) return(NULL)
    sort(table(items), decreasing = TRUE)
  }
  add_counts <- function(section, tb) {
    if (is.null(tb)) return(invisible())
    for (nm in names(tb)) add(section, nm, tb[[nm]])
  }

  add("overview", "student files graded", n)
  clean <- sum(st$status == "Executed without error" & !nzchar(st$library_flags) & !nzchar(st$other_flags))
  add("overview", "ran without error and no flags", clean)
  rt <- st$runtime_sec[!is.na(st$runtime_sec)]
  if (length(rt)) add("overview", "runtime", NA, sprintf("median %.1f sec, max %.1f sec", stats::median(rt), max(rt)))

  tb <- table(st$status)
  for (s in names(tb)) add("status", s, tb[[s]])
  add_counts("flags", count_items(paste(st$library_flags, st$other_flags, sep = "; "), ";"))
  add_counts("unapproved packages", count_items(st$pkgs_unapproved, ","))
  add_counts("necessary but not loaded", count_items(st$pkgs_necessary_not_loaded, ","))

  if (!is.null(err_df) && nrow(err_df)) {
    e <- err_df[err_df$error_type == "root" & err_df$file %in% st$file, , drop = FALSE]
    if (nrow(e)) {
      msg <- gsub("'[^']*'", "'<x>'", e$message)
      msg <- gsub("\"[^\"]*\"", "\"<x>\"", msg)
      msg <- gsub("[0-9]+", "<n>", msg)
      e$key <- paste0(ifelse(nzchar(e$failing_function), e$failing_function, "?"), ": ", substr(msg, 1, 90))
      agg <- stats::aggregate(file ~ key, data = e, FUN = function(x) length(unique(x)))
      agg <- agg[order(-agg$file), , drop = FALSE]
      for (i in seq_len(min(10, nrow(agg)))) {
        shared <- n >= 5 && agg$file[i] / n >= 0.5
        add("top root errors (students affected)", agg$key[i], agg$file[i],
            if (shared) "Shared by half or more of the class: check the data file, instructions, approved list or grader before judging students" else "")
      }
    }
  }
  add("code practices", "random code without an earlier set.seed()", sum(nzchar(st$rng_blocks_missing_seed)))
  add("code practices", "hard-coded paths/files in function calls", sum(nzchar(st$hardcoded_calls)))
  do.call(rbind, out)
}

# ---- Excel helpers ---------------------------------------------------------
grader_xl_styles <- function() {
  list(
    hdr   = openxlsx::createStyle(textDecoration = "bold", fontColour = "#FFFFFF", fgFill = "#1F3864",
                                  halign = "left", valign = "center", wrapText = TRUE),
    good  = openxlsx::createStyle(fontColour = "#006100", bgFill = "#C6EFCE"),
    bad   = openxlsx::createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE"),
    warn  = openxlsx::createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C"),
    grey  = openxlsx::createStyle(fontColour = "#595959", bgFill = "#E7E6E6"),
    input = openxlsx::createStyle(fgFill = "#FFF2CC"),
    wrap  = openxlsx::createStyle(wrapText = TRUE, valign = "top")
  )
}

grader_add_df_sheet <- function(wb, name, df, st, freeze_col = FALSE) {
  openxlsx::addWorksheet(wb, name)
  openxlsx::writeData(wb, name, df, headerStyle = st$hdr)
  openxlsx::freezePane(wb, name, firstActiveRow = 2, firstActiveCol = if (freeze_col) 2 else 1)
  w <- vapply(seq_len(ncol(df)), function(j) {
    v <- c(names(df)[j], as.character(df[[j]]))
    min(60, max(8, suppressWarnings(max(nchar(v), na.rm = TRUE)) + 2))
  }, numeric(1))
  openxlsx::setColWidths(wb, name, cols = seq_len(ncol(df)), widths = w)
  invisible(NULL)
}

# colors for status, flags, and root errors; yellow cells where you type your own entries
grader_format_results_sheet <- function(wb, name, df, st) {
  if (!nrow(df)) return(invisible(NULL))
  rows <- 2:(nrow(df) + 1)
  cf <- function(col_name, style, rule, type = "contains") {
    j <- which(names(df) == col_name)
    if (length(j)) openxlsx::conditionalFormatting(wb, name, cols = j, rows = rows, type = type, rule = rule, style = style)
  }
  cf("status", st$good, "Executed without error")
  for (txt in c("Executed with errors", "Parse error", "Process failed", "Grader error", "Rmd conversion"))
    cf("status", st$bad, txt)
  for (txt in c("Unsupported", "Dry run")) cf("status", st$grey, txt)
  cf("hardcode_check", st$bad, "Fail")
  for (nm in c("library_flags", "other_flags", "pkgs_unapproved", "rng_blocks_missing_seed", "hardcoded_calls")) {
    j <- which(names(df) == nm)
    if (length(j)) cf(nm, st$warn, sprintf("LEN(%s2)>0", openxlsx::int2col(j)), type = "expression")
  }
  j <- which(names(df) == "n_root_errors")
  if (length(j)) cf("n_root_errors", st$bad, sprintf("%s2>0", openxlsx::int2col(j)), type = "expression")
  inp_cols <- which(names(df) %in% c("instructor_score", "instructor_comments"))
  if (length(inp_cols)) openxlsx::addStyle(wb, name, st$input, rows = rows, cols = inp_cols, gridExpand = TRUE, stack = TRUE)
  j <- which(names(df) == "feedback_text")
  if (length(j)) {
    openxlsx::setColWidths(wb, name, cols = j, widths = 70)
    openxlsx::addStyle(wb, name, st$wrap, rows = rows, cols = j, gridExpand = TRUE, stack = TRUE)
  }
  invisible(NULL)
}

# ---- cohort workbook: one worksheet per assignment ---------------------------
grader_sheet_name <- function(assignment, run_id) {
  nm <- if (is.null(assignment) || is.na(assignment)) run_id else paste0("Assignment ", format(assignment, trim = TRUE))
  substr(gsub("[\\[\\]:*?/\\\\]", "-", nm, perl = TRUE), 1, 31)
}

# Column order for the worksheet: what you need first, your own entry cells next to it.
grader_sheet_df <- function(results) {
  lead <- data.frame(file = results$file, status = results$status,
                     instructor_score = NA_real_, instructor_comments = NA_character_,
                     feedback_text = results$feedback_text, stringsAsFactors = FALSE)
  rest <- results[, setdiff(names(results), c("file", "status", "feedback_text")), drop = FALSE]
  cbind(lead, rest)
}

# Refreshed rows replace old rows for the same file but keep your typed entries and
# any extra columns you added; files not in this run stay untouched.
grader_merge_sheet <- function(old, new) {
  if (is.null(old) || !nrow(old) || !"file" %in% names(old)) return(new)
  idx <- match(new$file, old$file)
  for (m in c("instructor_score", "instructor_comments")) {
    if (m %in% names(old)) {
      v <- old[[m]][idx]; keep <- !is.na(idx) & !is.na(v)
      if (any(keep)) { if (!is.character(v) && is.character(new[[m]])) new[[m]] <- as.character(new[[m]]); new[[m]][keep] <- v[keep] }
    }
  }
  extra <- setdiff(names(old), names(new))
  for (x in extra) new[[x]] <- old[[x]][idx]
  keep_old <- old[!(old$file %in% new$file), , drop = FALSE]
  for (cn in setdiff(names(new), names(keep_old))) keep_old[[cn]] <- NA
  merged <- rbind(new, keep_old[, names(new), drop = FALSE])
  first_solution <- if ("file_role" %in% names(merged)) merged$file_role != "instructor_solution" else FALSE
  merged[order(first_solution, merged$file), , drop = FALSE]
}

# Adds/refreshes this assignment's worksheet in <name>_workbook.xlsx (one workbook per cohort).
# A rolling backup (.bak) of the previous workbook is kept. Errors here never stop the run:
# the caller falls back to a stand-alone workbook for this run.
grader_update_workbook <- function(results, cs, inp, run_id, assignment) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) stop("openxlsx is not installed")
  path  <- file.path(inp$output_folder, paste0(inp$output_name, "_workbook.xlsx"))
  sheet <- grader_sheet_name(assignment, run_id)
  new   <- grader_sheet_df(results)
  st    <- grader_xl_styles()
  if (file.exists(path)) {
    file.copy(path, paste0(path, ".bak"), overwrite = TRUE)
    wb <- openxlsx::loadWorkbook(path)
  } else {
    wb <- openxlsx::createWorkbook()
  }
  existing <- names(wb)
  merged <- new
  if (sheet %in% existing) {
    old <- openxlsx::read.xlsx(wb, sheet = sheet)
    merged <- grader_merge_sheet(old, new)
    openxlsx::removeWorksheet(wb, sheet)
  }
  grader_add_df_sheet(wb, sheet, merged, st, freeze_col = TRUE)
  grader_format_results_sheet(wb, sheet, merged, st)

  cs_sheet <- "Class summaries"
  cs_out <- cs
  if (cs_sheet %in% existing) {
    old_cs <- tryCatch(openxlsx::read.xlsx(wb, sheet = cs_sheet), error = function(e) NULL)
    if (!is.null(old_cs) && nrow(old_cs)) {
      for (cn in setdiff(names(cs_out), names(old_cs))) old_cs[[cn]] <- NA
      for (cn in setdiff(names(old_cs), names(cs_out))) cs_out[[cn]] <- NA
      cs_out <- rbind(old_cs[, names(cs_out), drop = FALSE], cs_out)
    }
    openxlsx::removeWorksheet(wb, cs_sheet)
  }
  grader_add_df_sheet(wb, cs_sheet, cs_out, st)
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  path
}

# ---- stand-alone workbook for ONE run (fallback if the cohort workbook is locked/unreadable) ----
grader_write_excel <- function(results, err_df, cs, inp, run_id) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    message("openxlsx is not installed; skipping the Excel workbook.")
    return(NA_character_)
  }
  path <- file.path(inp$output_folder, paste0(inp$output_name, "_review_", run_id, ".xlsx"))
  wb <- openxlsx::createWorkbook()
  st <- grader_xl_styles()
  sheet_df <- grader_sheet_df(results)
  grader_add_df_sheet(wb, "Results", sheet_df, st, freeze_col = TRUE)
  grader_format_results_sheet(wb, "Results", sheet_df, st)
  if (!is.null(cs) && nrow(cs)) grader_add_df_sheet(wb, "Class summary", cs, st)
  if (!is.null(err_df) && nrow(err_df)) grader_add_df_sheet(wb, "Errors", err_df, st)
  ok <- tryCatch({ openxlsx::saveWorkbook(wb, path, overwrite = TRUE); TRUE }, error = function(e) FALSE)
  if (!ok) { message("Could not save the Excel workbook: ", path); return(NA_character_) }
  path
}
