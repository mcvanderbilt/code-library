# =============================================================================
# Purpose:      Shared constants and small helpers (base-package list, version, install/read helpers).
# Author:       Matthew C. Vanderbilt
# Created:      2026-10-03
# Modified:     2026-10-03
# Tags:         [TO CONFIRM against code-library root TAGS.md] education; grading; code-evaluation
# Status:       draft
# Level:        intermediate
# AI-Assisted:  Yes - Claude (Anthropic). See AI-DISCLOSURE.md (pending).
# Dependencies: utils
# License:      See ../LICENSE (license text pending - code-library BL-012)
# Package:      codeGrader
# =============================================================================

grader_base_pkgs <- c("base", "compiler", "datasets", "graphics", "grDevices", "grid",
                      "methods", "parallel", "splines", "stats", "stats4", "tcltk",
                      "tools", "utils")

# Single source of truth for the version is DESCRIPTION.
grader_version <- function() as.character(utils::packageVersion("codeGrader"))

grader_is_installed <- function(p) nzchar(system.file(package = p))

grader_install <- function(pkgs) {
  repos <- getOption("repos")
  if (is.null(repos) || isTRUE(unname(repos["CRAN"]) == "@CRAN@")) {
    repos <- c(CRAN = "https://cloud.r-project.org")
  }
  try(utils::install.packages(pkgs, repos = repos), silent = TRUE)
}

grader_fmt <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x)) paste(sort(x), collapse = ", ") else ""
}

grader_read_approved <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  x <- sub("^\ufeff", "", x)
  x <- trimws(sub("#.*$", "", x))
  x <- gsub("[\"',;]", "", x)
  unique(x[nzchar(x)])
}

grader_write_approved_template <- function(output_folder) {
  dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)
  tmpl <- file.path(output_folder, "approved-packages.txt")
  if (!file.exists(tmpl)) {
    shipped <- system.file("extdata", "approved-packages.txt", package = "codeGrader")
    if (nzchar(shipped)) {
      file.copy(shipped, tmpl)
    } else {
      writeLines(c("# Approved packages - one per line. Lines starting with # are ignored.",
                   "# Base R packages (stats, utils, graphics, etc.) are always allowed.",
                   "dplyr", "tidyr", "ggplot2", "readr", "tibble", "stringr", "forcats",
                   "lubridate", "purrr", "janitor", "skimr", "broom", "data.table"), tmpl)
    }
  }
  tmpl
}
