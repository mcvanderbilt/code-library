# codeGrader 1.7.0

Changes from the first real run against ANA600 A11 submissions (2026-10-03). Result CSVs gain new columns, so rows from this version go to a `_newlayout` file beside any existing cumulative file.

* **Parse recovery.** A syntax error no longer stops the check. `grader_parse_recover()` walks the file line by line, skips only the unreadable expression (its lines become comment markers so line numbers are preserved), records it, and the rest of the script is scanned and executed as usual. Each skipped range appears in the errors table as type `syntax` with its section label, and in the feedback as an independent error. A file where nothing survives still gets the old `Parse error` status.
* **Parse-error messages name only the student's file** (`line 101: unexpected symbol in "drive counts<- table(...)"`), never the grader's local folder path.
* **Packages are judged on the student's own `library()` list and order.** The worker now attaches only the approved packages the student loads, in the student's order, instead of every approved package. `sd()` therefore resolves to `stats` unless the student loaded `mosaic`, which removes the false "uses functions from mosaic" flag; a function the student never made available is looked up in a new one-time export map of the approved packages (`grader_pkg_maps()`, which replaced `grader_attach_map()`) to name the package that was not loaded. `readr` / `data.table` readers are redirected only when the student attached those packages.
* **Installing `tidyverse` counts as installing what it attaches**, so `install.packages("tidyverse")` no longer produces "does not include code to install: ggplot2".
* **Redundant loads and installs are reported**: `library(ggplot2)` after `library(tidyverse)` gives `pkgs_loaded_redundant = "ggplot2 (included in tidyverse)"` and a feedback sentence; same for `install.packages()`. Flag `REDUNDANT_PKG`.
* **Repeated root errors are reported once.** The same message at later expressions (e.g. `object 'wk1data' not found` at every use) becomes type `repeat`, pointing back to the first occurrence; the feedback counts repeats rather than listing them.
* **Repeated `library()` calls** for the same package are reported (`pkgs_loaded_repeated = "ggplot2 (2 calls)"`, flag `PKG_LOADED_REPEATEDLY`). A `require()` used as the condition of the standard `if (!require(x)) install.packages(x)` guard is not counted as a load.
* **Package set-up after other code** is reported as a convention note, not an error (`pkgs_setup_after_code`, flag `PKG_SETUP_AFTER_CODE`): any `library()` / `require()` / `install.packages()` / `p_load()` that comes after the first real code expression. Constant assignments, `setwd()`, `options()`, `rm()`, `set.seed()` and `Sys.*` settings do not count as "other code".
* **Numbered sections with no code** (CG-032): a template header such as `# 2. VIEW THE DATA STRUCTURE ----` with no expression under it is listed in `sections_without_code` (flag `SECTION_WITHOUT_CODE`). The unnumbered preamble is ignored, and a section whose only code was skipped for a syntax error is not counted as empty.
* **Graphics devices** (CG-033): `png()`/`pdf()`/`jpeg()` opens are counted against `dev.off()` calls (`graphics_devices`, `graphics_device_note`, flag `GRAPHICS_DEVICE_LEFT_OPEN`), and the worker reports devices still open when the script ends. `dev.off()` with no student device open is now a run-time error with a plain message, as it would be for the student, instead of silently closing the grader's own device; `graphics.off()` closes only the student's devices.
* **Coding-practice notes** (CG-034): `attach()`, `View()`, `rm(list = ls())` after set-up has started, and `install.packages()` not wrapped in an `if (!require(...))` guard, one note per kind at its first location (`practice_notes`, flag `PRACTICE_NOTE`).
* **Optional style pass** (CG-035): `codeGrader(style = TRUE, style_naming = c("camelCase", "snake_case"), style_line_length = 100)` runs `lintr` with six linters (object naming, `<-` assignment, infix spaces, commas, line length, `T`/`F` symbols); `style_issues` (count) and `style_examples` (first five) plus a feedback sentence. `lintr` is installed on first use and listed in `Suggests`.
* **Required saved file names** (CG-036): when an assignment requires a saved file, the prompts now also ask for the required name(s) (comma-separated, wildcards allowed). Names are matched case-insensitively against the files the script wrote; misses go to `required_files_missing` (flag `REQUIRED_FILE_NOT_SAVED`) with a feedback sentence naming what was saved instead.
* New result columns: `n_syntax_errors`, `n_repeat_errors`, `pkgs_loaded_redundant`, `pkgs_installed_redundant`, `pkgs_loaded_repeated`, `pkgs_setup_after_code`, `sections_without_code`, `graphics_devices`, `graphics_device_note`, `practice_notes`, `style_issues`, `style_examples`, `required_files_missing`. New flags: `SYNTAX_ERROR_SKIPPED`, `REDUNDANT_PKG`, `PKG_LOADED_REPEATEDLY`, `PKG_SETUP_AFTER_CODE`, `SECTION_WITHOUT_CODE`, `GRAPHICS_DEVICE_LEFT_OPEN`, `PRACTICE_NOTE`, `STYLE_ISSUES`, `REQUIRED_FILE_NOT_SAVED`. Run `devtools::document()` to refresh `man/codeGrader.Rd` for the three new arguments. `grader_worker()` gains a `student_pkgs` argument; `grader_scan_script()` returns `load_calls`, `setup_idx`, `late_setup_idx`.
* New tests: `tests/testthat/test-process.R` (parse recovery), a search-path test in `test-worker.R`, and load-count / set-up-order / empty-section / device / practice-note tests in `test-scan.R`. Written with AI assistance; not yet run in R (CG-008).

# codeGrader 1.6.1

* Moved from the handoff staging folder into the code library at `r/codeGrader/` (2026-10-03). No code changes; still **not yet run in R**.
* File headers aligned to the code-library `GOVERNANCE.md` schema: `Version` field added (1.6); Tags set to `automation, data-validation, reporting, teaching` from `TAGS.md` (closes CG-001); AI-Assisted set to `generated (Claude)` per `TAGS.md` / `AI-DISCLOSURE.md` (closes CG-003).
* `PRIVACY.md` moved to the package root. `docs/` renamed to `notes/` because the code-library root `.gitignore` ignores every `docs/` folder (pkgdown output) and would have kept these files off GitHub; `.Rbuildignore` updated to match.
* `codeGrader.Rproj` added for RStudio package development.
* `README.md` field table aligned to the library's code-object README template.

# codeGrader 1.6.0

* First package-structured version (previously a set of sourced scripts under
  `r/functions/student-grader/`, versions 1.0 to 1.6).
* Isolated, parallel execution of each student file (callr); root vs. cascade error
  classification; approved-package preloading and package-use audit; set.seed() checks
  with grader-run seed; hard-coded path detection; draft feedback; cumulative CSV logs;
  cohort workbook with one worksheet per assignment; dry-run, single-file and re-run modes;
  setup self-check; Git commit recorded in run info.
* Main function is `codeGrader()` (renamed from `grade_student_scripts()` before first use); `grader_check_setup()` is unchanged.
* Status `draft`, level `intermediate` (code-library `TAGS.md`). Written with AI assistance and not yet run in R.
