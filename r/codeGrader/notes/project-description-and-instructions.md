# codeGrader: requirements and decisions record (formerly the "R Homework Auto-Checker" Claude project)

> **Status (v1.8):** the standalone Claude project is retired. Work continues in a Claude Cowork session inside the Code Library project; the code-library project instructions govern. This file is kept as the requirements/spec record. Sections 3 (instructions) and 4 (knowledge files) describe the former project setup and are historical.

**File version:** 1.10  |  **Last updated:** 2026-10-03
**Update protocol:** Claude bumps the version and adds a change-log line whenever a discussion changes the code, requirements, or decisions below, then tells Matthew "Project files changed: <section>" so he can refresh the actual Claude project.
**Code home:** `mcvanderbilt/code-library` > `r/codeGrader/` (R package skeleton, ready to move to its own repo; see its README). Deferred items live in this package's own `BACKLOG.md` (not the code-library one).

---

## 1. Project name
R Homework Auto-Checker

## 2. Project description (paste into the project's description field)
Framework (part of Matthew's R code library) that quickly evaluates whether student homework executes without error, without running each file by hand. Supported submissions: .R scripts (National University ANA600) and .Rmd files (ANA605); no other file types are allowed. Each file runs in its own isolated R process with all approved packages preloaded, risky calls neutralized, and every data-import call redirected to an instructor-chosen data file. The run produces a results table (opened automatically and saved to a CSV) that reports execution status with line/function of failures, package-use audit against an approved list (installed? loaded? necessary? unapproved?), set.seed() placement before random-number code, hard-coded file paths vs. variables, and saved-file names. Matthew still reviews each student's work manually for correctness after the checks.

## 3. Custom instructions (paste into the project's instructions field)
**Context**
- The user is an instructor/course developer in data science and R programming (graduate level). Code runs on Windows 11 in RStudio. Python is still being learned: explain any Python code a bit more.
- Code lives in the user's GitHub code library as an R package skeleton at `r/codeGrader/` (files in `R/`, kebab-case names, `.R` extension; internal functions prefixed `grader_`; exported: `codeGrader()`, `grader_check_setup()`). Every code file carries the standard code-library header; Status is `draft` and Level is `intermediate` (library root TAGS.md); Tags stay marked [TO CONFIRM] until chosen from TAGS.md. Keep the package ready to move to its own repository.
- Goal of every task: quickly determine whether student homework executes without error and surface package, seed, and hard-coding problems. Correctness is checked manually by the user.

**Hard requirements for all code produced**
- Dialogs ask ONCE at the start: the mode (whole folder / one file / re-run / dry run), for a re-run the previous results file and statuses, the standard seed value, script folder, data file, output folder, output file name, approved-packages file, whether students are expected to save a file, and an optional instructor solution to check first. There is NO student-ID prompt (files are identified by file name). Nothing is hard-coded. The seed must be a whole number within R's integer range; on a bad value, re-ask or cancel the run.
- Never execute install or load functions from student files. The runner installs/loads all APPROVED packages itself so approved functions always resolve; missing library()/install calls in student code are reported, not allowed to cause "could not find function" failures.
- Student setwd()/file.choose() and other risky calls are replaced with harmless stand-ins and logged in `blocked_calls`. Data-import calls (read.csv family, plus read_csv/read_delim/fread) are redirected to the chosen data file.
- Student set.seed() calls are blocked and replaced with the STANDARD seed the user entered at the start (never the student's value) at the same location. Flag any code block that generates random data without a set.seed() somewhere earlier in that block (it does not need to be the line immediately before) AND run the standard set.seed() before that code so it still executes reproducibly (logged as set.seed_injected in blocked_calls).
- Package audit per student: which packages were loaded, which install attempts, which are NECESSARY (by functions actually used), which necessary ones were not loaded / not installed, which loaded ones were unnecessary, which are unapproved. Resolve package vectors fed to loops or lapply/sapply when they are constant.
- Each file runs in its own R process (callr), several at a time (`workers`, default 3). A failing student must never stop the run. Always record failure status with line number/chunk and failing function.
- Evaluate ALL of a script, not just up to the first error: classify each error as ROOT (own cause) or CASCADE (uses an object/function that a failed earlier line should have created), and report all root errors.
- Re-run support: the user can re-run only selected statuses (latest result per file) from a previous, possibly cumulative, results CSV. Single-file grading is also supported.
- Flag hard-coded file paths, file names, and URLs passed directly into any function call, and list those calls for manual review. Values stored in a variable first are fine; small literals such as digits in round() are fine.
- Results table is opened at the end and saved to the user-named file in the output folder. Choosing the same results name again APPENDS to it: every row carries run_id and run_time, and the header row is written only when the file is first created. If the column layout changes or the file is locked (open in Excel), rows go to a `_newlayout` or `_PENDING_` file so nothing is lost or overwritten.
- Also produce a class summary (appended CSV + console) and update the COHORT WORKBOOK `<name>_workbook.xlsx`: one worksheet per assignment (`assignment` argument, e.g. 3 -> "Assignment 3"; omitted -> a run date/time stamp), refreshed by file name so the instructor's typed `instructor_score` / `instructor_comments` (and any extra columns) are preserved, plus a "Class summaries" sheet. The cumulative CSV (long table with an `assignment` column) is the system of record; the workbook is the working view. If the workbook is locked, save a stand-alone per-run workbook instead.
- Robustness rules: every output step after the main results CSV is wrapped so a failure there is reported but never stops the run; each finished file is written to a checkpoint file immediately; pre-flight checks (output folder writable, worker process starts, arguments valid) run before grading; if the static scan fails the script is still executed and flagged STATIC_SCAN_FAILED.
- Record which code version graded each run (Git commit, branch, tag, uncommitted-changes flag) in the run info and audit log.
- Optional instructor-solution check before grading students: it must run cleanly (no errors, no flags) or the user decides whether to continue.
- Dry run: parse and statically scan only; nothing is executed; the necessary-package checks are left blank.
- Also produce: a draft feedback CSV for the student information system (with a blank instructor_comments column) and a permanent append-only audit log (grader/R versions, seed, MD5 hashes of the student file, data file and approved list, status, flags, feedback). Student data is private: keep outputs and logs out of GitHub (the grader warns if a chosen folder is inside a Git repository; see docs/PRIVACY.md and the package .gitignore).

**Style**
- Write R first (base R + tidyverse where it helps). Deliver complete, runnable files, not fragments. Comment concisely. Lead with the answer; keep it short.
- State assumptions and trade-offs; flag anything that could not be tested (Claude cannot run R in its environment).
- When behavior or requirements change, update this file (version + change log) and tell the user what to refresh in the Claude project.

## 4. Project knowledge files to upload
- `r/codeGrader/R/*.R`, `DESCRIPTION`, `NAMESPACE`, `README.md`
- `r/codeGrader/inst/extdata/approved-packages.txt` (starter list; edit per assignment)
- `r/codeGrader/tests/testthat/*.R`

## 5. Design decisions (so they are not re-litigated)
- Isolation: one callr background process per student file (callr::r_bg), up to `workers` at once, temporary working directory, per-expression and per-script time limits; a timed-out process is killed and recorded.
- All approved packages are loaded at the start of each worker so student code runs as if the correct allowed library() calls were made. A one-time map records which packages each approved package attaches (e.g., tidyverse).
- NECESSARY packages = approved packages that the functions the student called resolve to (plus pkg:: use). Meta-packages count as covering what they attach.
- Package vectors in `for (p in pkgs)` / `lapply(pkgs, library, character.only = TRUE)` are resolved statically from constant assignments only (student code is never evaluated for this). Unresolvable lists are flagged LIBRARY_LIST_UNRESOLVED.
- Temporary working directory per script; files written are listed (and copied to the output folder when saving is expected); console output is saved per student for manual review.
- Rmd files are converted with knitr::purl (not knitted); error locations are mapped back to Rmd line numbers and chunk labels where possible.
- Code block = blank-line-separated group of expressions (scripts) or a chunk (Rmd); section-header comments also start a new block.

## 6. Blocked student calls (neutralized, logged in `blocked_calls`)
- Packages: library, require (returns TRUE), install.packages, update.packages, remove.packages, install_github, install_version, install_cran, install, p_load, p_install
- Files/working directory: setwd, file.choose (returns data file), choose.files (returns data file), choose.dir (returns data folder), unlink, file.remove
- Interaction/debug: readline (returns ""), menu (returns 1), View, browser, debug, debugonce
- System/network/exit: system, system2, shell, shell.exec, browseURL, download.file, quit, q
- Replaced (not just blocked): set.seed (standard grader seed), read.csv/read.csv2/read.delim/read.table/read_csv/read_delim/fread (redirected), pkg::fn (blocks unapproved packages)
- Not covered (needs a VM/sandbox): writes to absolute paths, reading arbitrary files, network calls other than those above, Sys.setenv and similar

## 7. Output table columns
run_id, run_time, assignment, file_role, file, file_md5, file_type, status, pct_exprs_ok, exprs_total, exprs_ok, n_errors, n_root_errors, n_cascade_errors, pct_exprs_no_root_error, n_warnings, runtime_sec, first_error_location, first_error_function, first_error, root_error_summary, library_flags, other_flags, pkgs_loaded, pkgs_install_attempted, pkgs_necessary, pkgs_necessary_not_loaded, pkgs_necessary_no_install_attempt, pkgs_loaded_not_necessary, pkgs_unapproved, set_seed_calls, rng_blocks, rng_blocks_missing_seed, hardcode_check, hardcoded_calls, data_reads_redirected, blocked_calls, other_data_calls, files_saved, console_log, feedback_text

Status values: Dry run (not executed), Executed without error, Executed with errors, Parse error, Rmd conversion error, Process failed or timed out, Grader error, Unsupported file type

library_flags: UNAPPROVED_PKG, NECESSARY_PKG_NOT_LOADED, NECESSARY_PKG_NO_INSTALL_ATTEMPT, UNNECESSARY_PKG_LOADED, LIBRARY_LIST_UNRESOLVED
other_flags: STATIC_SCAN_FAILED, SEED_MISSING_BEFORE_RANDOM (grader still ran set.seed itself), HARDCODED_PATH_OR_FILE, ABSOLUTE_PATH_LITERAL, EMPTY_SCRIPT, EXPECTED_FILE_NOT_SAVED, UNEXPECTED_FILE_SAVED, APPROVED_PKG_FAILED_TO_LOAD, SMART_QUOTES, UNSUPPORTED_FILE_TYPE

## 8. Confirmed decisions (2026-10-03)
- set.seed: student calls stay in place but run with the standard seed entered at the start, not the student's value. Where random-number code has no earlier set.seed() in its block, the grader runs set.seed() itself and still flags it.
- Seed check: each code block that generates random data must have a set.seed() earlier in the same block; adjacency is not required.
- Output files are cumulative (appended); per-student console/saved-file folders are separated by run_id. Results name = cohort (e.g., ANA600_Fall2026): one cohort workbook per results name, one worksheet per assignment, re-running an assignment updates its sheet in place (upsert by file name).
- Student feedback is pasted into the student information system by hand (no SIS export needed).
- Class summary flags errors shared by half or more of the class (with at least 5 students) as a likely data-file, instructions, approved-list or grader problem.
- Student ID is NOT collected (removed 2026-10-03); the file name identifies the submission.
- Cascade rule: an error is a cascade error if its expression uses an object/function assigned by an earlier failed expression (plain `x <- ...` assignments only).
- Seed value is entered by the user at the start of each run (validated). The `seed_mode`/"honor" option was removed.
- Hard-coding check: flag file paths, file names (by extension), and URLs written directly inside any function call, and list the calls. Plain assignments of such values to a variable are not flagged. Numeric arguments such as round() digits are not flagged.

## 9. Known limitations
- Not tested in R by Claude (no R in its environment); first run may need small fixes.
- Static detection cannot resolve package names built from non-constant code.
- Failure locations are the top-level expression (line range), plus the failing function from the error; exact line inside a multi-line expression is not available.
- Functions passed as values (e.g., `sapply(x, mean)`) and objects from packages (datasets) are not counted when deciding which packages are necessary.
- Random-number calls inside function definitions are not checked until called.
- The cohort workbook is rewritten with openxlsx, which can drop charts, pivot tables or images; keep the workbook for grader sheets and keep your own analysis in a separate copy. Keep it closed in Excel during a run. A rolling `.bak` copy of the previous version is kept.
- Not knitted: Rmd YAML, inline R code, and rendering problems are not tested (see backlog).
- Hard-coding detection is limited to path-like strings: relative paths with no extension (e.g., "data/raw") and other literal values are not detected.

## 10. Backlog
All deferred work is tracked in this package's own `BACKLOG.md` (CG-001 onward), kept separate from the code-library backlog so it migrates with the package. Do not duplicate it here.

## 11. Change log
| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-10-03 | Initial single-file runner |
| 1.1 | 2026-10-03 | Rebuilt as modular framework for the code library; callr isolation; approved packages preloaded; necessary/loaded/installed audit; loop/lapply package resolution; set.seed standardization + check; hard-coding check; Rmd support; saved-file prompt and column; line/function failure reporting; results opened and saved to user-named file; VM moved to code-library backlog |
| 1.2 | 2026-10-03 | Standard-seed decision confirmed; seed check = earlier set.seed in same block; hard-coding check now flags path/file/URL literals in any function call with a review list (`hardcoded_calls`); Rmd YAML/render check added to backlog |
| 1.3 | 2026-10-03 | Seed value asked and validated at start (re-ask/cancel); grader runs set.seed itself before unseeded random code and still flags it; student-ID file-name pattern; draft feedback text + feedback CSV for the SIS (blank instructor_comments); append-only audit log with file hashes and versions; backlog: self-test fixtures, speed options, re-run, assignment profiles, cascade errors, rubric |
| 1.4 | 2026-10-03 | Student-ID prompt removed; parallel workers (callr::r_bg) with timeout kill; root vs cascade error classification and root_error_summary; re-run of selected statuses from a previous results CSV; Git-repo warning, PRIVACY-student-grader.md and gitignore-snippet.txt; data-file pre-flight; package versions in run info; backlog: template-unchanged check, assignment profiles, rubric, class summary, solution sanity run, dry run |
| 1.5 | 2026-10-03 | Cumulative (appended) outputs with run_id/run_time and header-once, layout-change and locked-file protection; mode menu (whole folder, one file, re-run, dry run); instructor-solution check; class summary; Excel review workbook with conditional formatting; per-run console/saved-file folders; re-run uses latest result per file; backlog: setup self-check, SIS export, release tagging, archiving |
| 1.6 | 2026-10-03 | Error-handling pass (pre-flight checks, argument validation, checkpoint file, safe output steps, static-scan fallback, worker supervision and cleanup on interrupt, duplicate-name stop); grader_check_setup() with worker end-to-end and static-scan tests; Git commit/tag/uncommitted flag recorded; cohort workbook with one worksheet per assignment (assignment argument), upsert preserving instructor entries, Class summaries sheet, stand-alone fallback; assignment column added to outputs; SIS export dropped (feedback pasted by hand); backlog refreshed |
| 1.7 | 2026-10-03 | Restructured as an R package skeleton at r/codeGrader/ (R/, inst/extdata, tests/testthat, docs/, DESCRIPTION, NAMESPACE, LICENSE placeholder); library header on every file; global-environment assignments removed (results returned invisibly); version read from DESCRIPTION; testthat tests added; backlog items drafted for BACKLOG.md |
| 1.8 | 2026-10-03 | Standalone Claude project retired; work moves to a Cowork session in the Code Library project; this file becomes the requirements record; backlog moved to code-library BACKLOG.md |
| 1.9 | 2026-10-03 | Backlog moved into the package's own BACKLOG.md (CG-001 to CG-026, `CG-` prefix), separate from the code-library backlog |
| 1.10 | 2026-10-03 | Main function renamed to `codeGrader()`; Status `draft` / Level `intermediate` from the library TAGS.md; package-level README confirmed; defaults stay function arguments (settings file backlogged as CG-027); single cohort workbook kept (provisional); `openxlsx` on-demand install accepted; backlog IDs are `CG-NNN`; folder confirmed as r/codeGrader |
