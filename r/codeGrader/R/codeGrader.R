# =============================================================================
# Purpose:      Main entry point: grade a folder, one file, a re-run, or a dry run of student .R / .Rmd homework.
# Author:       Matthew C. Vanderbilt (@mcvanderbilt)
# Created:      2026-10-03
# Modified:     2026-10-03 — Moved into code-library r/codeGrader; header aligned to GOVERNANCE.md
# Version:      1.6
# Tags:         automation, data-validation, reporting, teaching
# Status:       draft
# Level:        intermediate
# AI-Assisted:  generated (Claude) — see code-library AI-DISCLOSURE.md
# Dependencies: callr, knitr, utils, tools; openxlsx, rstudioapi (optional)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

#' Check whether student R homework runs, and audit how it was written
#'
#' Pop-up dialogs ask what to do (grade a folder, one file, re-run earlier failures,
#' or a dry run), the standard seed, the folders and data file, the approved-packages
#' list, and whether students must save a file. Each .R / .Rmd file then runs in its
#' own isolated R process (several at a time). Student `library()`/`install.packages()`
#' calls are never executed; approved packages are loaded for them. Every data-import
#' call is redirected to the data file you choose.
#'
#' Results are appended to cumulative CSV files (every row carries `run_id`, `run_time`
#' and `assignment`) and to a cohort workbook with one worksheet per assignment.
#'
#' @param assignment Optional assignment number (for example `3`). It becomes the
#'   worksheet name "Assignment 3" in the cohort workbook. If omitted, the worksheet is
#'   named with the run date and time.
#' @param workers Number of student scripts to run at the same time.
#' @param recursive Also look in sub-folders of the script folder.
#' @param open_in_rstudio Show each file in the RStudio editor as it starts.
#' @param expr_timeout_sec Maximum seconds for one top-level expression.
#' @param script_timeout_sec Maximum seconds for a whole script.
#' @param save_console Save each student's console output for manual review.
#' @param rng_fns Names of functions that generate random numbers (checked for a
#'   preceding `set.seed()` in the same code block).
#' @param exclude_pattern Regular expression for file names to ignore.
#' @return Invisibly, a data frame with one row per file for this run.
#' @export
#' @examples
#' \dontrun{
#' grader_check_setup()                 # once, before a real batch
#' res <- codeGrader(assignment = 3)
#' }
codeGrader <- function(assignment         = NULL,  # assignment number (e.g. 3) -> worksheet "Assignment 3"; omit for a date-stamped sheet
                                  workers            = 3,     # student scripts run at the same time
                                  recursive          = FALSE,
                                  open_in_rstudio    = TRUE,
                                  expr_timeout_sec   = 60,      # max seconds per top-level expression
                                  script_timeout_sec = 300,     # max seconds per whole script
                                  save_console       = TRUE,
                                  rng_fns            = grader_default_rng_fns,
                                  exclude_pattern    = "^(codeGrader|run_all_scripts)\\.[Rr]$") {
  grader_validate_args(workers, expr_timeout_sec, script_timeout_sec, assignment)
  if (!grader_is_installed("openxlsx")) {                      # optional (Excel workbook)
    message("Installing optional package openxlsx (needed for the cohort Excel workbook)...")
    grader_install("openxlsx")
  }
  workers <- max(1L, as.integer(workers))
  assign_val <- if (is.null(assignment)) NA_real_ else as.numeric(assignment)

  inp <- grader_collect_inputs()
  if (is.null(inp$approved_file)) {
    tmpl <- grader_write_approved_template(inp$output_folder)
    message("Template written to: ", tmpl, "\nEdit it, then run codeGrader() again.")
    return(invisible(NULL))
  }
  grader_preflight_output(inp$output_folder)
  dry <- identical(inp$mode, "dry")
  if (!dry && !isTRUE(grader_check_worker())) stop("Cannot start worker processes; see the message above.", call. = FALSE)
  run_id   <- format(Sys.time(), "%Y%m%d_%H%M%S")
  run_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  git <- grader_git_info()

  # data file pre-flight (fail early, not 60 times)
  if (!dry) {
    ext <- tolower(tools::file_ext(inp$data_file))
    if (!ext %in% c("csv", "tsv", "txt", "tab")) {
      message("WARNING: the data file is .", ext, ". Import calls are redirected to read.csv()-style readers, which expect delimited text.")
    }
    if (!isTRUE(tryCatch({ utils::read.csv(inp$data_file, nrows = 5); TRUE }, error = function(e) FALSE))) {
      message("WARNING: the data file could not be read with read.csv(); students' import calls will likely fail.")
    }
  }

  # approved packages
  approved <- tryCatch(setdiff(grader_read_approved(inp$approved_file), grader_base_pkgs),
                       error = function(e) stop("Could not read the approved-packages list: ", conditionMessage(e), call. = FALSE))
  if (!length(approved)) message("NOTE: the approved list is empty; every non-base package will be flagged as unapproved.")
  if (!dry) {
    miss <- approved[!vapply(approved, grader_is_installed, logical(1))]
    if (length(miss)) {
      message("Installing missing APPROVED packages: ", paste(miss, collapse = ", "))
      grader_install(miss)
    }
  }
  approved_ok <- approved[vapply(approved, grader_is_installed, logical(1))]
  if (length(setdiff(approved, approved_ok))) {
    message(if (dry) "Note - approved but not installed here: " else "WARNING - could not install: ",
            paste(setdiff(approved, approved_ok), collapse = ", "))
  }
  attach_map <- list()
  if (!dry) {
    message("Mapping what each approved package attaches (one-time)...")
    attach_map <- grader_attach_map(approved_ok)
  }

  # collect files
  all_files <- list.files(inp$script_folder, full.names = TRUE, recursive = recursive)
  all_files <- all_files[!dir.exists(all_files)]
  bn <- basename(all_files)
  keep <- !startsWith(bn, ".") & !startsWith(bn, "~$") & !grepl(exclude_pattern, bn)
  all_files <- all_files[keep]
  is_code <- grepl("\\.(r|rmd)$", all_files, ignore.case = TRUE)
  code_files <- all_files[is_code]; other_files <- all_files[!is_code]
  if (!is.null(inp$only_files)) {                       # single file or re-run: only the chosen files
    code_files  <- code_files[basename(code_files) %in% inp$only_files]
    other_files <- character()
    missing_now <- setdiff(inp$only_files, basename(code_files))
    if (length(missing_now)) message("Not found in the script folder (skipped): ", paste(missing_now, collapse = ", "))
  }
  if (!length(code_files)) stop("No .R or .Rmd files to grade in: ", inp$script_folder, call. = FALSE)
  dups <- unique(basename(code_files)[duplicated(basename(code_files))])
  if (length(dups)) {
    stop("Several files share the same name (", paste(dups, collapse = ", "),
         "). Rename them or turn off recursive = TRUE; results are identified by file name.", call. = FALSE)
  }

  ctx <- list(
    dry = dry, data_file = inp$data_file, approved = approved, approved_ok = approved_ok,
    attach_map = attach_map, base_pkgs = grader_base_pkgs,
    expr_timeout_sec = expr_timeout_sec, script_timeout_sec = script_timeout_sec,
    seed_value = inp$seed_value, rng_fns = rng_fns,
    expect_saved = inp$expect_saved, save_console = save_console,
    saved_dir   = file.path(inp$output_folder, paste0(inp$output_name, "_saved_files"), run_id),
    console_dir = file.path(inp$output_folder, paste0(inp$output_name, "_console"), run_id),
    checkpoint  = if (dry) NULL else file.path(inp$output_folder, paste0(inp$output_name, "_checkpoint_", run_id, ".csv")),
    use_editor  = isTRUE(open_in_rstudio) && requireNamespace("rstudioapi", quietly = TRUE) &&
                  rstudioapi::isAvailable()
  )

  # ---- optional: instructor solution must run cleanly first ---------------
  sol <- NULL
  if (!dry && !is.null(inp$solution_file)) {
    message("Checking the instructor solution first...")
    s_res <- grader_run_jobs(inp$solution_file, ctx, 1L)[[1]]
    sr <- s_res$row; sr$file_role <- "instructor_solution"
    clean <- identical(sr$status, "Executed without error") && !nzchar(sr$library_flags) && !nzchar(sr$other_flags)
    if (clean) {
      message("Instructor solution ran cleanly.")
    } else {
      detail <- paste0("Status: ", sr$status,
                       if (nzchar(sr$root_error_summary)) paste0("\nErrors: ", sr$root_error_summary) else "",
                       if (nzchar(sr$library_flags)) paste0("\nLibrary flags: ", sr$library_flags) else "",
                       if (nzchar(sr$other_flags)) paste0("\nOther flags: ", sr$other_flags) else "")
      message("Instructor solution is NOT clean:\n", detail)
      go <- grader_ask_yes_no("Instructor solution is not clean",
        paste0(detail, "\n\nProblems here usually mean the data file, approved list, or grader needs fixing. Continue grading students anyway?"))
      if (!isTRUE(go)) stop("Grading stopped after the instructor-solution check.", call. = FALSE)
    }
    sol <- list(row = sr, errors = s_res$errors, path = inp$solution_file)
  }

  # ---- run ----------------------------------------------------------------
  if (dry) {
    message(sprintf("Dry run of %d file(s): nothing will be executed.", length(code_files)))
    res <- grader_dry_run(code_files, ctx)
  } else {
    message(sprintf("Grading %d file(s), %d at a time...", length(code_files), workers))
    res <- grader_run_jobs(code_files, ctx, workers)
  }

  rows <- vector("list", length(code_files)); err_list <- list()
  for (k in seq_along(code_files)) {
    r <- res[[k]]$row
    r$file_md5 <- unname(tools::md5sum(code_files[k]))
    r$feedback_text <- if (dry) "" else grader_safely("drafting feedback", grader_feedback_text(r), default = "")
    rows[[k]] <- grader_row_df(r)
    if (!is.null(res[[k]]$errors)) err_list[[length(err_list) + 1L]] <- res[[k]]$errors
  }
  for (of in other_files) {
    r <- grader_row_template()
    r$file <- basename(of); r$file_type <- tools::file_ext(of)
    r$status <- "Unsupported file type"; r$other_flags <- "UNSUPPORTED_FILE_TYPE"
    r$file_md5 <- unname(tools::md5sum(of))
    r$feedback_text <- if (dry) "" else grader_feedback_text(r)
    rows[[length(rows) + 1L]] <- grader_row_df(r)
  }
  if (!is.null(sol)) {
    sol$row$file_md5 <- unname(tools::md5sum(sol$path))
    sol$row$feedback_text <- ""
    rows[[length(rows) + 1L]] <- grader_row_df(sol$row)
    if (!is.null(sol$errors)) err_list[[length(err_list) + 1L]] <- sol$errors
  }

  results <- do.call(rbind, rows)
  results <- results[order(results$file_role != "instructor_solution", results$file), , drop = FALSE]
  rownames(results) <- NULL
  results <- data.frame(run_id = run_id, run_time = run_time, assignment = assign_val, results,
                        check.names = FALSE, stringsAsFactors = FALSE)
  err_df <- if (length(err_list)) do.call(rbind, err_list) else NULL
  if (!is.null(err_df)) err_df <- data.frame(run_id = run_id, assignment = assign_val, err_df,
                                             check.names = FALSE, stringsAsFactors = FALSE)

  # ---- dry run: save + show, then stop ------------------------------------
  if (dry) {
    p <- grader_append_csv(results, file.path(inp$output_folder, paste0(inp$output_name, "_dryrun.csv")))
    message("\nDry run saved to: ", p, "\n(No execution happened; 'necessary package' checks need a real run.)")
    grader_show_results(results)
    return(invisible(results))
  }

  # ---- save everything: main results FIRST, then the extras ----------------
  pkg_versions <- paste0(approved_ok, " ", vapply(approved_ok, function(p) as.character(utils::packageVersion(p)), character(1)),
                         collapse = ", ")
  run_lines <- c(
    paste("Run id / time:      ", run_id, "/", run_time),
    paste("Assignment:         ", if (is.na(assign_val)) "(none given)" else assign_val),
    paste("Mode:               ", inp$mode),
    paste("Grader version:     ", grader_version()),
    paste("Code version (Git): ", if (nzchar(git$commit)) paste0(git$repo, " ", git$branch, " @ ", git$commit,
                                    if (nzchar(git$tag)) paste0(" tag ", git$tag) else "",
                                    if (identical(git$uncommitted, "TRUE")) " (UNCOMMITTED CHANGES)" else "") else "not in a Git repository"),
    paste("R version:          ", R.version.string),
    paste("Script folder:      ", inp$script_folder),
    paste("Data file:          ", inp$data_file),
    paste("Approved list:      ", inp$approved_file),
    paste("Approved packages:  ", pkg_versions),
    paste("Standard seed value:", inp$seed_value),
    paste("Parallel workers:   ", workers),
    paste("Expression timeout: ", expr_timeout_sec, "sec; script timeout:", script_timeout_sec, "sec"),
    paste("Saved files expected:", inp$expect_saved),
    paste("Instructor solution:", if (is.null(sol)) "not checked" else sol$path),
    paste("Re-run of:          ", if (is.null(inp$rerun_of)) "no" else inp$rerun_of),
    paste("Files checked:      ", length(code_files), "(+", length(other_files), "unsupported)")
  )
  paths <- grader_save_results(results, err_df, inp, run_lines, run_id)
  paths$feedback <- grader_safely("saving feedback", grader_save_feedback(results, inp, run_id))
  paths$audit    <- grader_safely("writing the audit log", grader_append_audit_log(results, inp, run_id, paths$summary, git))

  cs <- grader_safely("building the class summary", grader_class_summary(results, err_df, run_id, assign_val), default = NULL)
  paths$class_summary <- NA_character_
  if (!is.null(cs)) {
    paths$class_summary <- grader_safely("saving the class summary",
      grader_append_csv(cs, file.path(inp$output_folder, paste0(inp$output_name, "_class_summary.csv"))))
  }
  paths$workbook <- grader_safely("updating the cohort workbook", grader_update_workbook(results, cs, inp, run_id, assignment))
  if (is.na(paths$workbook)) {
    paths$workbook <- grader_safely("writing a stand-alone review workbook", grader_write_excel(results, err_df, cs, inp, run_id))
    if (!is.na(paths$workbook)) message("The cohort workbook could not be updated (is it open in Excel?). This run was saved to: ", paths$workbook)
  }

  if (!grepl("_PENDING_", basename(paths$summary), fixed = TRUE)) unlink(ctx$checkpoint)   # not needed once results are safely saved

  message("\nResults (appended): ", paths$summary)
  if (!is.na(paths$feedback)) message("Feedback to copy into the student information system (appended): ", paths$feedback)
  if (!is.na(paths$class_summary)) message("Class summary (appended): ", paths$class_summary)
  if (!is.na(paths$audit)) message("Audit log (appended): ", paths$audit)
  if (!is.na(paths$workbook)) message("Excel: ", paths$workbook)

  if (!is.null(cs)) {
    cat("\n----- Class summary -----\n")
    print(cs[cs$section %in% c("overview", "status", "flags", "top root errors (students affected)"),
             c("section", "item", "n", "pct")], row.names = FALSE)
  }
  grader_show_results(results)
  invisible(results)
}
