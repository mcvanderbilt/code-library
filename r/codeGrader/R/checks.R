# =============================================================================
# Purpose:      Safety helpers (safe wrapper, argument and folder checks), Git version info, and the setup self-check.
# Author:       Matthew C. Vanderbilt (@mcvanderbilt)
# Created:      2026-10-03
# Modified:     2026-10-03 — Moved into code-library r/codeGrader; header aligned to GOVERNANCE.md
# Version:      1.6
# Tags:         automation, data-validation, reporting, teaching
# Status:       draft
# Level:        intermediate
# AI-Assisted:  generated (Claude) — see code-library AI-DISCLOSURE.md
# Dependencies: callr, utils, tools; knitr, openxlsx, rstudioapi (optional)
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

# Run `expr`; on error print a warning and return `default` instead of stopping.
grader_safely <- function(label, expr, default = NA_character_) {
  tryCatch(expr, error = function(e) {
    message("WARNING: ", label, " failed: ", conditionMessage(e))
    default
  })
}

grader_validate_args <- function(workers, expr_timeout_sec, script_timeout_sec, assignment) {
  pos <- function(x) is.numeric(x) && length(x) == 1 && is.finite(x) && x > 0
  if (!pos(workers)) stop("'workers' must be a single positive number.", call. = FALSE)
  if (!pos(expr_timeout_sec) || !pos(script_timeout_sec)) {
    stop("The timeouts must be single positive numbers (seconds).", call. = FALSE)
  }
  if (script_timeout_sec < expr_timeout_sec) {
    stop("'script_timeout_sec' must be at least as large as 'expr_timeout_sec'.", call. = FALSE)
  }
  if (!is.null(assignment) && !pos(assignment)) {
    stop("'assignment' must be a single positive number (for example 3), or left out.", call. = FALSE)
  }
  invisible(TRUE)
}

# Fail early (before grading anything) if results cannot be written.
grader_preflight_output <- function(folder) {
  good <- tryCatch({
    dir.create(folder, recursive = TRUE, showWarnings = FALSE)
    probe <- file.path(folder, paste0(".grader_write_test_", Sys.getpid()))
    writeLines("test", probe)
    present <- file.exists(probe)
    unlink(probe)
    present
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!isTRUE(good)) {
    stop("Cannot write to the output folder: ", folder,
         "\nChoose a folder you have permission to write to.", call. = FALSE)
  }
  invisible(TRUE)
}

# Can a separate R worker process be started at all?
grader_check_worker <- function() {
  good <- tryCatch(identical(callr::r(function() 1L + 1L, timeout = 60), 2L), error = function(e) FALSE)
  if (!isTRUE(good)) {
    message("A separate R worker process could not be started. Check that R is installed normally ",
            "(Rscript available), that antivirus is not blocking it, and that the 'callr' package works.")
  }
  isTRUE(good)
}

# ---- which version of the code did the grading? ------------------------
# Reads the Git commit of the package folder when loaded from a repository, e.g.
# devtools::load_all() inside the code library (no Git program needed). An installed copy has no Git data.
# `uncommitted` is "TRUE"/"FALSE" when Git is available, otherwise "".
grader_git_info <- function(dir = system.file(package = "codeGrader")) {
  none <- list(repo = "", branch = "", commit = "", tag = "", uncommitted = "")
  if (is.null(dir) || !nzchar(dir)) return(none)
  root <- grader_in_git_repo(dir)
  if (is.null(root)) return(none)
  gitdir <- file.path(root, ".git")
  if (!dir.exists(gitdir)) return(none)
  head <- tryCatch(readLines(file.path(gitdir, "HEAD"), warn = FALSE)[1], error = function(e) NA_character_)
  if (is.na(head)) return(none)
  commit <- ""; branch <- ""
  if (startsWith(head, "ref: ")) {
    ref <- sub("^ref: ", "", head)
    branch <- sub("^refs/heads/", "", ref)
    rf <- file.path(gitdir, ref)
    if (file.exists(rf)) {
      commit <- trimws(readLines(rf, warn = FALSE)[1])
    } else if (file.exists(file.path(gitdir, "packed-refs"))) {
      ln <- readLines(file.path(gitdir, "packed-refs"), warn = FALSE)
      hit <- ln[endsWith(ln, paste0(" ", ref))]
      if (length(hit)) commit <- sub(" .*$", "", hit[1])
    }
  } else {
    commit <- trimws(head)                      # detached HEAD
  }
  tag <- ""
  tdir <- file.path(gitdir, "refs", "tags")
  if (nzchar(commit) && dir.exists(tdir)) {
    tf <- list.files(tdir, full.names = TRUE)
    tf <- tf[!dir.exists(tf)]
    hits <- basename(tf)[vapply(tf, function(f) identical(trimws(readLines(f, warn = FALSE)[1]), commit), logical(1))]
    tag <- paste(hits, collapse = ", ")
  }
  uncommitted <- ""
  if (nzchar(Sys.which("git"))) {
    out <- tryCatch(suppressWarnings(system2("git", c("-C", shQuote(root), "status", "--porcelain", "--", shQuote(dir)),
                                             stdout = TRUE, stderr = FALSE)),
                    error = function(e) NULL)
    if (!is.null(out) && is.null(attr(out, "status"))) uncommitted <- as.character(length(out) > 0)
  }
  list(repo = basename(root), branch = branch, commit = substr(commit, 1, 12), tag = tag, uncommitted = uncommitted)
}

# ---- setup self-check -----------------------------------------------------
#' Check that the grader is ready to use
#'
#' Run this once before a real grading batch. It checks that the required and
#' optional packages are installed, that a separate R worker process can start,
#' and it runs a few tiny test scripts through the real worker and the static scanner.
#' Nothing from any student file is run.
#'
#' @param output_folder Optional folder to test for write access.
#' @return Invisibly, a data frame with one row per check (PASS / WARN / FAIL).
#' @export
#' @examples
#' \dontrun{
#' grader_check_setup()
#' }
grader_check_setup <- function(output_folder = NULL) {
  res <- list()
  add <- function(check, ok, detail = "") {
    res[[length(res) + 1L]] <<- data.frame(
      check = check,
      result = if (isTRUE(ok)) "PASS" else if (is.na(ok)) "WARN" else "FAIL",
      detail = detail, stringsAsFactors = FALSE)
  }
  run <- function(check, expr) {
    tryCatch(expr, error = function(e) add(check, FALSE, substr(gsub("\\s+", " ", conditionMessage(e)), 1, 160)))
  }

  add("R version (4.0 or newer)", getRversion() >= "4.0.0", R.version.string)
  for (p in c("callr", "knitr")) add(paste("package:", p, "(required)"), grader_is_installed(p),
                                     if (grader_is_installed(p)) "installed" else "install.packages()")
  for (p in c("openxlsx", "rstudioapi")) add(paste("package:", p, "(optional)"),
                                             if (grader_is_installed(p)) TRUE else NA,
                                             if (grader_is_installed(p)) "installed" else "needed for the Excel workbook / pop-up dialogs")
  add("RStudio dialogs available", if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) TRUE else NA,
      "run from RStudio to get folder/file pop-ups")

  if (!is.null(output_folder)) {
    ok <- tryCatch({ grader_preflight_output(output_folder); TRUE }, error = function(e) FALSE)
    add("output folder is writable", ok, output_folder)
  }

  if (grader_is_installed("callr")) {
    run("worker process starts", add("worker process starts", grader_check_worker(), "callr::r()"))

    # --- end-to-end test of the worker on two tiny scripts
    run("worker end-to-end test", {
      td <- tempfile("grader_selftest_"); dir.create(td)
      on.exit(unlink(td, recursive = TRUE), add = TRUE)
      data_csv <- file.path(td, "data.csv")
      utils::write.csv(data.frame(x = 1:3), data_csv, row.names = FALSE)
      good <- file.path(td, "good.R")
      writeLines(c("library(stats)", "d <- read.csv(\"C:/not/a/real/path.csv\")", "x <- rnorm(3)",
                   "stopifnot(nrow(d) == 3)", "y <- sum(d$x)"), good)
      bad <- file.path(td, "bad.R")
      writeLines(c("a <- 1", "b <- undefined_object + 1", "c2 <- b * 2", "d2 <- a + 1"), bad)
      run_worker <- function(path, inject = integer()) {
        rd <- file.path(td, paste0("run_", basename(path))); dir.create(rd)
        callr::r(grader_worker,
                 args = list(code_path = path, data_file = data_csv, approved = character(),
                             base_pkgs = grader_base_pkgs, fn_names = c("sum", "rnorm"),
                             expr_timeout_sec = 30, seed_value = 123L, seed_inject_idx = inject),
                 wd = rd, timeout = 120)
      }
      w1 <- run_worker(good, inject = 3L)
      add("worker: clean script has no errors", length(w1$errors) == 0 && w1$n_ok == 5L,
          paste("expressions ok:", w1$n_ok, "of", w1$n_exprs))
      add("worker: data import redirected", identical(w1$reads, 1L), "read.csv() pointed at the chosen data file")
      add("worker: library()/set.seed handling", all(c("library", "set.seed_injected") %in% w1$blocked),
          paste(w1$blocked, collapse = ", "))
      w2 <- run_worker(bad)
      add("worker: errors are caught (2 expected)", length(w2$errors) == 2L && w2$n_ok == 2L,
          paste("errors:", length(w2$errors), "ok:", w2$n_ok))
      ex <- parse(bad, keep.source = TRUE)
      sc <- grader_scan_script(ex, readLines(bad), FALSE)
      cls <- grader_classify_errors(vapply(w2$errors, function(er) er$i, integer(1)), sc)
      add("root vs cascade classification", identical(cls$type, c("root", "cascade")), paste(cls$type, collapse = ", "))
    })

    # --- static scan test
    run("static scan test", {
      snip <- c("pk <- c(\"dplyr\", \"ggplot2\")", "for (p in pk) library(p, character.only = TRUE)",
                "install.packages(pk)", "x <- rnorm(5)", "z <- read.csv(\"C:/Users/a/data.csv\")",
                "path <- \"data/x.csv\"", "w <- read.csv(path)")
      ex <- parse(text = snip, keep.source = TRUE)
      sc <- grader_scan_script(ex, snip, FALSE)
      add("scan: package loop resolved", setequal(sc$loaded, c("dplyr", "ggplot2")), paste(sc$loaded, collapse = ", "))
      add("scan: install vector resolved", setequal(sc$installed, c("dplyr", "ggplot2")), paste(sc$installed, collapse = ", "))
      add("scan: random code without set.seed found", length(sc$rng_missing_idx) == 1L, "")
      add("scan: hard-coded path flagged, variable path not",
          any(grepl("data.csv", sc$hc$text, fixed = TRUE)) && !any(sc$hc$text == "data/x.csv"), "")
    })
  }

  if (grader_is_installed("openxlsx")) {
    run("Excel workbook can be written", {
      f <- tempfile(fileext = ".xlsx")
      wb <- openxlsx::createWorkbook(); openxlsx::addWorksheet(wb, "t"); openxlsx::writeData(wb, "t", data.frame(a = 1))
      openxlsx::saveWorkbook(wb, f, overwrite = TRUE)
      add("Excel workbook can be written", file.exists(f), "")
      unlink(f)
    })
  }

  gi <- grader_git_info()
  add("code version can be recorded (Git)", if (nzchar(gi$commit)) TRUE else NA,
      if (nzchar(gi$commit)) paste0(gi$repo, " @ ", gi$commit, if (nzchar(gi$tag)) paste0(" (", gi$tag, ")") else "",
                                    if (identical(gi$uncommitted, "TRUE")) " - has UNCOMMITTED changes" else "")
      else "grader folder is not inside a Git repository (run info will say so)")

  out <- do.call(rbind, res)
  print(out, row.names = FALSE, right = FALSE)
  nf <- sum(out$result == "FAIL"); nw <- sum(out$result == "WARN")
  message(if (nf == 0) "\nSetup check: no failures" else paste0("\nSetup check: ", nf, " FAILURE(S) - fix these before grading"),
          if (nw) paste0(" (", nw, " warning(s))") else "", ".")
  message("Reminder: close the results CSV files and the cohort workbook in Excel before a run, so rows can be appended.")
  invisible(out)
}
