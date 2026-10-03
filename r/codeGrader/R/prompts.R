# =============================================================================
# Purpose:      Pop-up dialogs asked once at the start of a grading run (mode, seed, folders, data file, approved list).
# Author:       Matthew C. Vanderbilt (@mcvanderbilt)
# Created:      2026-10-03
# Modified:     2026-10-03 — Moved into code-library r/codeGrader; header aligned to GOVERNANCE.md
# Version:      1.6
# Tags:         automation, data-validation, reporting, teaching
# Status:       draft
# Level:        intermediate
# AI-Assisted:  generated (Claude) — see code-library AI-DISCLOSURE.md
# Dependencies: utils; rstudioapi (optional, for dialogs)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

# ---- dialogs ---------------------------------------------------------
grader_pick <- function(type = c("dir", "file"), caption) {
  type <- match.arg(type)
  path <- NULL
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    path <- tryCatch({
      if (type == "dir") rstudioapi::selectDirectory(caption = caption)
      else               rstudioapi::selectFile(caption = caption, label = "Select")
    }, error = function(e) NULL)
  } else if (.Platform$OS.type == "windows") {
    path <- tryCatch({
      if (type == "dir") utils::choose.dir(caption = caption)
      else               utils::choose.files(caption = caption, multi = FALSE)
    }, error = function(e) NULL)
  } else {
    path <- tryCatch({
      if (type == "dir") readline(paste0(caption, ": "))
      else               file.choose()
    }, error = function(e) NULL)
  }
  if (length(path) != 1 || is.na(path) || !nzchar(path)) return(NULL)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

grader_ask_text <- function(title, message, default = "") {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    return(tryCatch(rstudioapi::showPrompt(title, message, default = default), error = function(e) NULL))
  }
  ans <- readline(paste0(message, " [", default, "]: "))
  if (nzchar(ans)) ans else default
}

grader_ask_yes_no <- function(title, message) {
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    ans <- tryCatch(rstudioapi::showQuestion(title, message, ok = "Yes", cancel = "No"),
                    error = function(e) FALSE)
    return(isTRUE(ans))
  }
  isTRUE(utils::askYesNo(message, default = FALSE))
}

# A valid seed is a single whole number within R's integer range.
grader_valid_seed <- function(x) {
  v <- suppressWarnings(as.numeric(trimws(as.character(x))))
  length(v) == 1 && !is.na(v) && is.finite(v) && v == floor(v) && abs(v) <= .Machine$integer.max
}

# Ask for the standard seed; re-ask on a bad value or cancel the whole run.
grader_ask_seed <- function(default = 123) {
  repeat {
    ans <- grader_ask_text("Seed value",
      "Standard seed for set.seed() (a whole number between -2147483647 and 2147483647). Cancel stops grading.",
      as.character(default))
    if (is.null(ans)) stop("Grading cancelled at the seed prompt.", call. = FALSE)
    if (grader_valid_seed(ans)) return(as.integer(as.numeric(trimws(ans))))
    retry <- grader_ask_yes_no("Invalid seed",
      paste0("'", ans, "' cannot be used with set.seed(). Enter a new value?\n(Choose No to cancel grading.)"))
    if (!isTRUE(retry)) stop("Grading cancelled: invalid seed value.", call. = FALSE)
  }
}

# Returns the repo root if `path` sits inside a Git repository, otherwise NULL.
grader_in_git_repo <- function(path) {
  p <- normalizePath(path, winslash = "/", mustWork = FALSE)
  repeat {
    if (file.exists(file.path(p, ".git"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) return(NULL)
    p <- parent
  }
}

# Pick one item from a list (pop-up window). NULL if cancelled.
grader_ask_choice <- function(title, choices) {
  ans <- tryCatch(utils::select.list(choices, title = title, graphics = TRUE), error = function(e) "")
  if (!length(ans) || !nzchar(ans)) NULL else ans
}

# Everything the user is asked, once, at the start.
grader_collect_inputs <- function() {
  modes <- c("Grade the whole folder",
             "Grade one file",
             "Re-run files from a previous results file",
             "Dry run (list files and package use; nothing is executed)")
  ans <- grader_ask_choice("What would you like to do?", modes)
  if (is.null(ans)) stop("Cancelled.", call. = FALSE)
  mode <- c("folder", "single", "rerun", "dry")[match(ans, modes)]

  only_files <- NULL; rerun_of <- NULL; seed_value <- NA_integer_; data_file <- NA_character_
  expect_saved <- NA; solution_file <- NULL

  if (mode == "rerun") {
    message("Select the PREVIOUS results CSV (the main file, not _errors / _feedback)")
    rerun_of <- grader_pick("file", "Select the PREVIOUS results CSV (not the _errors or _feedback file)")
    if (is.null(rerun_of)) stop("No previous results file selected.", call. = FALSE)
    prev <- tryCatch(utils::read.csv(rerun_of, stringsAsFactors = FALSE, check.names = FALSE),
                     error = function(e) stop("Could not read the previous results file: ", conditionMessage(e), call. = FALSE))
    if (!all(c("file", "status") %in% names(prev))) stop("That file is not a grader results CSV.", call. = FALSE)
    if ("file_role" %in% names(prev)) prev <- prev[prev$file_role == "student", , drop = FALSE]
    if ("run_id" %in% names(prev)) prev <- prev[order(prev$run_id), , drop = FALSE]
    latest <- prev[!duplicated(prev$file, fromLast = TRUE), , drop = FALSE]    # most recent result per file
    st <- grader_ask_text("Statuses to re-run",
      paste0("Comma-separated statuses to re-run (latest result per file). Found: ", paste(unique(latest$status), collapse = "; ")),
      "Process failed or timed out, Grader error")
    if (is.null(st)) stop("Re-run cancelled.", call. = FALSE)
    st <- trimws(strsplit(st, ",")[[1]])
    only_files <- latest$file[latest$status %in% st]
    if (!length(only_files)) stop("No files in the previous results have those statuses.", call. = FALSE)
    message(length(only_files), " file(s) will be re-run.")
  }

  if (mode != "dry") {
    message("Seed value for set.seed()")
    seed_value <- grader_ask_seed()
  }

  if (mode == "single") {
    message("Choose the ONE student file to grade")
    one <- grader_pick("file", "Select the student .R / .Rmd file")
    if (is.null(one)) stop("No file selected.", call. = FALSE)
    script_folder <- dirname(one); only_files <- basename(one)
  } else {
    message("Choose the folder containing the student .R / .Rmd files")
    script_folder <- grader_pick("dir", "Select the folder containing student .R / .Rmd files")
    if (is.null(script_folder)) stop("No script folder selected.", call. = FALSE)
  }

  if (mode != "dry") {
    message("Choose the data file that replaces every data-import path")
    data_file <- grader_pick("file", "Select the data file student code should load")
    if (is.null(data_file)) stop("No data file selected.", call. = FALSE)
  }

  message("Choose the folder where results will be saved")
  output_folder <- grader_pick("dir", "Select the OUTPUT folder for results")
  if (is.null(output_folder)) stop("No output folder selected.", call. = FALSE)
  for (pth in unique(c(output_folder, script_folder))) {
    repo <- grader_in_git_repo(pth)
    if (!is.null(repo)) {
      go <- grader_ask_yes_no("Folder is inside a Git repository",
        paste0("'", pth, "' is inside the Git repository at:\n", repo,
               "\n\nStudent work and grading results could be committed to GitHub. Continue anyway?"))
      if (!isTRUE(go)) stop("Grading cancelled: choose folders outside a Git repository.", call. = FALSE)
    }
  }

  message("Name the results file")
  nm <- grader_ask_text("Results file name",
    "Name for this cohort's results (no extension), e.g. ANA600_Fall2026. Use the SAME name every time for that cohort: the CSV files and the cohort workbook (_workbook.xlsx) keep growing, and every row gets the run date/time.",
    "grading_results")
  if (is.null(nm) || !nzchar(trimws(nm))) nm <- "grading_results"
  nm <- gsub("[^A-Za-z0-9._-]", "_", sub("\\.csv$", "", trimws(nm), ignore.case = TRUE))

  message("Choose the approved-packages list (Cancel = create a template)")
  approved_file <- grader_pick("file", "Select approved packages list (.txt). Cancel to create a template")

  if (!is.null(approved_file) && mode != "dry") {
    expect_saved <- grader_ask_yes_no("Saved files",
      "Does this assignment require students to SAVE a file (e.g., write.csv, ggsave)?")
    if (mode != "single" &&
        grader_ask_yes_no("Instructor solution", "Check an instructor solution file first?\n(It should run cleanly; if not, the data file, approved list or grader probably needs fixing.)")) {
      solution_file <- grader_pick("file", "Select the instructor solution (.R / .Rmd)")
      if (is.null(solution_file)) message("No solution file selected; skipping that check.")
    }
  }

  list(mode = mode, seed_value = seed_value, script_folder = script_folder, data_file = data_file,
       output_folder = output_folder, output_name = nm, approved_file = approved_file,
       expect_saved = expect_saved, only_files = only_files, rerun_of = rerun_of,
       solution_file = solution_file)
}
