# codeGrader: handoff to a Claude Cowork session

**Written/updated:** 2026-10-03 | **Package version at handoff:** 1.6.0 (requirements record v1.10) | **Author of the code:** Matthew C. Vanderbilt, drafted with Claude (Anthropic)
**Where this file lives after extraction:** `D:\GitHub\code-library\r\codeGrader\staging\HANDOFF.md`

This document lets a new Claude Cowork session, inside the Code Library Claude project, continue exactly where the previous chat stopped. The previous chat had **no access to the D: drive**, so nothing was ever written into the repo; everything is in this staging folder. **None of the code has been run in R.**

---

## 0. Paste this into the new Cowork session

(The same prompt, with the click-by-click steps, is in `NEXT-STEPS.md`.)

> Read `D:\GitHub\code-library\r\codeGrader\staging\HANDOFF.md` completely, then `staging\codeGrader\BACKLOG.md`. Follow the Code Library project rules. Decisions are already made (HANDOFF section 9): the folder is `D:\GitHub\code-library\r\codeGrader\`; the main function is `codeGrader()`; Status is `draft` and Level is `intermediate` from the code-library root `TAGS.md` (do not create a separate TAGS.md); codeGrader keeps its own `BACKLOG.md` with `CG-NNN` IDs and nothing is added to the library `BACKLOG.md`; the maintainer email and the license/AI-disclosure wording are pending, so leave them as placeholders. Before creating anything, tell me what you found in the repo (TAGS.md, GOVERNANCE.md, conventions) and what you plan to create, then propose the final folder structure and wait for my OK.

## 1. What this is

`codeGrader` is an R tool that **quickly tells an instructor whether student homework runs without error**, and audits how it was written, without opening and running each file by hand.

* **Courses:** National University ANA600 (students submit `.R` scripts) and ANA605 (students submit `.Rmd`). No other file types are allowed.
* **The instructor still reviews correctness manually.** The tool only checks: does it run; which packages did the student load/install/need and are they approved; is `set.seed()` placed correctly; are file paths hard-coded; where did it fail and why.
* **Grades are kept for reference** in a per-cohort Excel workbook (one worksheet per assignment); feedback text is drafted and **pasted by hand** into the student information system (no export format needed).
* **Privacy:** outputs contain student work and file names. They must never be committed to GitHub. The tool does not identify students beyond file names (a student-ID feature was deliberately removed).

## 2. Ground rules from the Code Library project (must be followed)

Taken from the project's custom instructions and description:

* Matthew writes the initial code; Claude's role is documentation, review, cleanup, refactoring suggestions, governance consistency. **Exception:** he explicitly asked for this package to be built by Claude, and he approved renaming the main function to `codeGrader()`. Do not originate *other* new snippets without being asked.
* **Do not restructure folders, rename conventions, or edit governance files** (`GOVERNANCE.md`, `CONTRIBUTING.md`, `TAGS.md`, `AI-DISCLOSURE.md`, `LICENSE`) without proposing the change and getting confirmation.
* Every code object needs the standard header (Purpose, Author, Created, Modified, Tags, Status, Level, AI-Assisted, Dependencies, License) **and a co-located README**. Check before treating a file as finished.
* Tags/Status/Level must come from the code library's root `TAGS.md`; flag any ad hoc value. **Decided:** Status `draft`, Level `intermediate`; no separate `TAGS.md` for codeGrader. The Tags field is still `[TO CONFIRM against code-library root TAGS.md]` (backlog CG-001).
* Language-appropriate naming and style (R here). Code quality: professional, optimized, **commented thoroughly enough for students to learn from**, always consider error handling.
* Anything not done now goes into a backlog item. **For codeGrader that means `r\codeGrader\BACKLOG.md`, its own file with `CG-NNN` IDs (CG-001 to CG-027 exist).** Matthew's decision: it is a standalone file that will move with the package to its own repo; the code-library `BACKLOG.md` does **not** reference it and codeGrader items are **not** added there. Do not read the library backlog for format; the codeGrader file defines its own. (The library's license item is written "code-library BL-012".)
* Code only: do not bring in personal knowledge management, notes, or meeting-tracking from other projects.
* Use the full name **Matthew C. Vanderbilt** wherever his name appears.
* Folders: language folders for finished code; `/staging/` for larger projects headed to their own repo; `/archive/`, `/learning/`, `/research/` as defined in `GOVERNANCE.md`. Once code is depended on, breaking changes create a new version rather than overwriting.
* Repo: `https://github.com/mcvanderbilt/code-library`, local primary working copy `D:\GitHub\code-library` (GitHub Desktop). Make changes there, not just in chat.
* Matthew's working style in this thread: short answers that lead with the answer; asks before structural decisions; wants to understand *why*; likes clear numbered options; prefers dialogs/prompts at the start of a run over hard-coded paths.

## 3. What is in the staging zip

After extraction at `D:\GitHub\code-library\r\codeGrader\staging\`:

```
staging/
  HANDOFF.md                this file
  NEXT-STEPS.md             exact steps for Matthew + the kickoff prompt
  codeGrader/               the R package skeleton exactly as built so far
    DESCRIPTION  NAMESPACE  LICENSE (placeholder)  NEWS.md  README.md  .gitignore  .Rbuildignore
    BACKLOG.md              codeGrader's OWN backlog, CG-001 to CG-027 (move to r\codeGrader\BACKLOG.md)
    R/                      9 files, ~2,150 lines
    inst/extdata/           approved-packages.txt (starter list)
    tests/                  testthat.R + 4 test files (~180 lines)
    docs/                   PRIVACY.md, gitignore-snippet-for-code-library.txt,
                            project-description-and-instructions.md (requirements record v1.8)
```

## 4. Current state of each file

All R files start with the library header block (Author: Matthew C. Vanderbilt; Created/Modified 2026-10-03; Status: `draft`; Level: `intermediate`; Tags: to confirm against `TAGS.md`; AI-Assisted: Yes). "Run" = executed in R. **Nothing has been run.** Bracket balance of every R file was checked with a script; syntax and behavior were not.

| File | Lines | Purpose | Key functions | Notes / risks |
|---|---|---|---|---|
| `R/codeGrader.R` | 269 | Exported main entry point (function `codeGrader()`) | `codeGrader(assignment, workers = 3, recursive, open_in_rstudio, expr_timeout_sec = 60, script_timeout_sec = 300, save_console, rng_fns, exclude_pattern)` | Orchestrates the whole run (see section 5). Has roxygen docs, `@export`. Returns the results data frame invisibly (no global assignment). |
| `R/process.R` | 339 | Per-file pipeline | `grader_prepare_file`, `grader_finalize_file`, `grader_run_jobs`, `grader_dry_run`, `grader_worker_failed`, `grader_error_row` | Parallel scheduler uses `callr::r_bg(..., wd, stdout = NULL, stderr = NULL, supervise = TRUE)` and polls; kills a worker past `script_timeout_sec`; on exit kills all workers; checkpoints each finished row. |
| `R/worker.R` | 189 | Runs ONE student file in a fresh R process | `grader_worker` (self-contained; callr copies only the function), `grader_attach_map` | Preloads all approved packages; records which package each called function resolves to (`utils::find`); builds the sandbox environment; runs expression by expression with per-expression time limit; console output to `.grader_console.txt`; plots to a null device. |
| `R/scan.R` | 465 | Static analysis; **never executes student code** | `grader_scan_script`, `grader_classify_errors`, `grader_expr_symbols`, `grader_first_call_pos`, `grader_is_pathlike`, `grader_classify_arg`, `grader_find_io_arg`, `grader_header_label`, `grader_map_rmd_lines`, `grader_empty_scan`; constants `grader_default_rng_fns`, `grader_io_specs` | Resolves package vectors only from "safe constant" code (c, paste, paste0, file.path, etc.). Detects library/require/p_load/install calls, `pkg::fn`, loops and apply-family over constants, set.seed vs RNG per code block, hard-coded path-like literals. |
| `R/report.R` | 392 | Outputs | `grader_row_template`, `grader_append_csv`, `grader_save_results`, `grader_feedback_text`, `grader_feedback_df`, `grader_save_feedback`, `grader_append_audit_log`, `grader_checkpoint`, `grader_class_summary`, `grader_location`, Excel: `grader_xl_styles`, `grader_add_df_sheet`, `grader_format_results_sheet`, `grader_sheet_name`, `grader_sheet_df`, `grader_merge_sheet`, `grader_update_workbook`, `grader_write_excel` | Cumulative CSV appends (header once; layout change goes to `*_newlayout.csv`; locked file goes to `*_PENDING_*.csv`). `openxlsx` is optional (guarded). Highest-uncertainty area: openxlsx round-trip of the workbook. |
| `R/prompts.R` | 185 | Pop-up dialogs | `grader_collect_inputs`, `grader_pick`, `grader_ask_text`, `grader_ask_yes_no`, `grader_ask_choice`, `grader_ask_seed`, `grader_valid_seed`, `grader_in_git_repo` | Uses `rstudioapi` when available, falls back to `utils::choose.dir/choose.files/readline`. `utils::select.list(graphics = TRUE)` for the mode menu. |
| `R/checks.R` | 227 | Safety helpers + setup check | `grader_check_setup` (exported), `grader_safely`, `grader_validate_args`, `grader_preflight_output`, `grader_check_worker`, `grader_git_info` | `grader_check_setup()` runs PASS/WARN/FAIL checks including a real end-to-end worker test and a scanner test. `grader_git_info()` reads `.git` directly (no Git needed) for commit/branch/tag and, if Git exists, an uncommitted-changes flag. |
| `R/utils-constants.R` | 60 | Shared constants/helpers | `grader_base_pkgs`, `grader_version()` (reads DESCRIPTION), `grader_is_installed`, `grader_install`, `grader_fmt`, `grader_read_approved`, `grader_write_approved_template` | Template copies `inst/extdata/approved-packages.txt`. |
| `R/codeGrader-package.R` | 21 | Package-level roxygen | `"_PACKAGE"` | |
| `DESCRIPTION` | | Package metadata | Version 1.6.0; Depends R >= 4.0.0; Imports callr, grDevices, knitr, stats, tools, utils; Suggests openxlsx, rstudioapi, testthat (>= 3.0.0), withr | **No maintainer email** (open question). `License: file LICENSE`. |
| `NAMESPACE` | | Hand-written to match roxygen tags | `export(codeGrader)`, `export(grader_check_setup)` | Regenerate with `devtools::document()`. `man/` does not exist yet. |
| `LICENSE` | | **Placeholder only** | | Real text pending code-library BL-012 (tracked as CG-002). Do not invent terms. |
| `README.md` | 86 | Package README | | Quick start, outputs table, folder layout, privacy, how to move to its own repo. |
| `NEWS.md`, `.gitignore`, `.Rbuildignore` | | | | `.gitignore` already excludes all grading output patterns; `.Rbuildignore` ignores `docs`, `staging`, and `BACKLOG.md`. |
| `BACKLOG.md` | 173 | **This package's own backlog** | 27 entries CG-001 to CG-027 with an index table | Standalone by Matthew's decision; not linked from or tracked in the code-library backlog. |
| `inst/extdata/approved-packages.txt` | 15 | Starter approved list | dplyr, tidyr, ggplot2, readr, tibble, stringr, forcats, lubridate, purrr, janitor, skimr, broom, data.table | Edit per assignment. Format: one package per line, `#` comments. |
| `tests/testthat.R`, `tests/testthat/test-*.R` | ~180 | Unit + one integration test | scanner, seed validation, args, git helpers, append/merge/feedback/summary, worker run | `test-worker.R` runs a real child R process (skipped on CRAN). Written without running; expect fixes. |
| `docs/PRIVACY.md` | 34 | Student-data handling checklist | | Not legal advice; has a blank for the retention period. Grades in the workbook are treated as a grade record. |
| `docs/gitignore-snippet-for-code-library.txt` | | Patterns for the library root `.gitignore` | | Proposal only (CG-005). |
| `docs/project-description-and-instructions.md` | 124 | Requirements/decisions record v1.8 | | Formerly the standalone Claude project; now historical. Sections 5 to 9 are still accurate and useful. |

## 5. How a run works (architecture)

1. `codeGrader(assignment = NULL, ...)` validates arguments, then `grader_collect_inputs()` shows dialogs: **mode** (whole folder / one file / re-run earlier failures / dry run), for re-run the previous results CSV and which statuses to redo (latest result per file), **seed** (validated whole number within R's integer range; re-ask or cancel), student folder or single file, **data file**, **output folder** (warns if inside a Git repo), **results name** (= the cohort, e.g. `ANA600_Fall2026`), **approved-packages list** (cancel writes a template and stops), whether students must **save a file**, and an optional **instructor solution** to check first.
2. Pre-flight: output folder writable; a worker process can start (`callr`); data file readable; approved packages installed (missing ones are installed); `grader_attach_map()` records what each approved package attaches (e.g., tidyverse), so "loaded dplyr via tidyverse" counts.
3. Files collected (`.R`/`.Rmd`; others become "Unsupported file type" rows; dot-files and `~$` temp files ignored; duplicate names stop the run).
4. Optional **instructor solution** is run first; it must be clean (no error, no flags) or Matthew decides whether to continue.
5. `grader_run_jobs()`: for each file, `grader_prepare_file()` (Rmd to R with `knitr::purl`, parse, static scan, Rmd line mapping, temp run folder with a copy of the data file) → `callr::r_bg(grader_worker, ...)` (up to `workers` at once) → `grader_finalize_file()` combines static findings and worker results. Each finished row is also written to a checkpoint CSV immediately.
6. Rows get `run_id`, `run_time`, `assignment`. **Main results CSV is saved first**, then errors CSV, run-info text, feedback CSV, audit log, class summary CSV, cohort workbook (fallback: stand-alone per-run workbook), then the checkpoint is deleted. Every step after the main CSV is wrapped (`grader_safely`) so a failure there never stops the run.
7. Results table opens (`View`); class summary prints; function returns the data frame invisibly.

**Dry run:** parse and static scan only; nothing executed; "necessary package" checks are blank; saved to `<name>_dryrun.csv`.

### Worker sandbox (what student code can and cannot do)
* **Blocked / stood in (logged in `blocked_calls`):** `library`, `require` (returns TRUE), `install.packages`, `update.packages`, `remove.packages`, `install_github`, `install_version`, `install_cran`, `install`, `p_load`, `p_install`, `setwd`, `file.choose` and `choose.files` (return the data file), `choose.dir` (returns its folder), `readline` (""), `menu` (1), `system`, `system2`, `shell`, `shell.exec`, `unlink`, `file.remove`, `quit`, `q`, `browseURL`, `download.file`, `View`, `browser`, `debug`, `debugonce`.
* **Replaced:** `set.seed` (always runs the **standard seed**, never the student's value); `read.csv`, `read.csv2`, `read.delim`, `read.table` (always read the chosen data file; the `file` argument is never evaluated); `read_csv`/`read_delim` if readr is approved; `fread` if data.table is approved; `::` and `:::` (block installers, error on unapproved packages, redirect readers).
* **Seed injection:** if random-number code has no earlier `set.seed()` in its code block, the worker runs the standard seed right before it, and the row is still flagged.
* **Not covered (needs the VM item):** writing to absolute paths, reading arbitrary files, other network calls, `Sys.setenv`, and any call not on the list.

## 6. Output contract

**Results columns:** `run_id, run_time, assignment, file_role, file, file_md5, file_type, status, pct_exprs_ok, exprs_total, exprs_ok, n_errors, n_root_errors, n_cascade_errors, pct_exprs_no_root_error, n_warnings, runtime_sec, first_error_location, first_error_function, first_error, root_error_summary, library_flags, other_flags, pkgs_loaded, pkgs_install_attempted, pkgs_necessary, pkgs_necessary_not_loaded, pkgs_necessary_no_install_attempt, pkgs_loaded_not_necessary, pkgs_unapproved, set_seed_calls, rng_blocks, rng_blocks_missing_seed, hardcode_check, hardcoded_calls, data_reads_redirected, blocked_calls, other_data_calls, files_saved, console_log, feedback_text`

**Status values:** Executed without error; Executed with errors; Parse error; Rmd conversion error; Process failed or timed out; Grader error; Unsupported file type; Dry run (not executed).

**library_flags:** UNAPPROVED_PKG, NECESSARY_PKG_NOT_LOADED, NECESSARY_PKG_NO_INSTALL_ATTEMPT, UNNECESSARY_PKG_LOADED, LIBRARY_LIST_UNRESOLVED.
**other_flags:** SEED_MISSING_BEFORE_RANDOM, HARDCODED_PATH_OR_FILE, ABSOLUTE_PATH_LITERAL, EMPTY_SCRIPT, STATIC_SCAN_FAILED, APPROVED_PKG_FAILED_TO_LOAD, EXPECTED_FILE_NOT_SAVED, UNEXPECTED_FILE_SAVED, UNSUPPORTED_FILE_TYPE, SMART_QUOTES.

**Files in the output folder** (all append run after run; every row has `run_id`/`run_time`): `<name>.csv` (system of record), `<name>_errors.csv`, `<name>_feedback.csv` (with blank `instructor_comments`), `<name>_class_summary.csv`, `<name>_run_info.txt`, `<name>_workbook.xlsx` (+ rolling `.bak`), `<name>_console/<run_id>/`, `<name>_saved_files/<run_id>/`, `<name>_dryrun.csv`, `grading_audit_log.csv` (grader/R versions, Git commit/branch/tag/uncommitted flag, seed, MD5 of student file, data file and approved list, status, flags, feedback), plus temporary `_checkpoint_` and, when needed, `_PENDING_` / `_newlayout` files.

**Cohort workbook:** one workbook per results name; sheet "Assignment N" per `assignment` argument (no argument = a run-date/time sheet name); sheet columns start with `file, status, instructor_score, instructor_comments, feedback_text` (yellow entry cells); re-running an assignment **upserts by file name**, keeping the instructor's typed scores/comments and any extra columns and leaving files not in the run untouched; a "Class summaries" sheet accumulates.

## 7. Decisions made, and why

| # | Decision | Why |
|---|---|---|
| 1 | Run every file in its **own R process** (callr), several at a time | Matthew wanted isolation and that one student's crash/loop must never stop the run. Started as same-session evaluation, changed on request. A full VM was declined for now (cost) and backlogged. |
| 2 | **Never execute** student `library()`/install calls; instead preload all **approved** packages in the worker | Student code should run "as if the correct, allowed function was called"; missing library/install calls are *reported*, not allowed to cause "could not find function" failures. |
| 3 | Redirect every `read.csv`-style import to the instructor's data file; the `file` argument is never evaluated | Student paths are on their machines; also removes `file.choose()`/`setwd()` problems. |
| 4 | All inputs by **dialogs at the start**, never hard-coded | Matthew's preference; reuse across assignments and cohorts. |
| 5 | **Seed** is asked at the start and validated; student `set.seed()` calls are replaced with the standard seed; unseeded random code gets a seed injected **and** a flag | Matthew wants outputs comparable and to detect missing seeds, which would break reproducibility. |
| 6 | "Right before" a random event means **an earlier `set.seed()` in the same code block** (blank-line group in scripts; chunk in Rmd; section-header comments also split blocks) | Matthew: it need not be the immediately preceding line, just done properly. |
| 7 | Hard-coding check = file paths, file names (by extension), URLs written directly in a function call; plain assignment to a variable is fine; numbers like `round()` digits are fine | Matthew teaches students to put such values in a variable first and pass the variable. |
| 8 | Evaluate the **whole script**; classify errors as **root vs cascade** | He wants all independent problems reported, not just the first, and a fairer `pct_exprs_no_root_error`. |
| 9 | `.Rmd` handled with `knitr::purl()` (run the code, don't knit); line numbers mapped back to the Rmd with chunk labels | Simplest safe option for v1; render/YAML check deferred (CG-014). |
| 10 | **Cumulative outputs** (append with run_id/run_time; header once); same results name = same cohort | Matthew wants one growing log and grades kept for reference. Layout-change and locked-file protection added so nothing is lost. |
| 11 | **Cohort workbook with a worksheet per assignment** plus the CSV as system of record | Hybrid recommended: CSV for analysis/never overwritten; workbook for review and typing grades. Worksheet named by `assignment` number or date stamp. |
| 12 | Draft **feedback text**, pasted by hand into the SIS; **no SIS export** and **no student-ID prompt** | Matthew: he pastes by hand; files are identified by file name only (ID feature removed on request). |
| 13 | Modes: whole folder, **single file**, **re-run** selected statuses (latest result per file), **dry run**, **instructor solution check** | Requested features for safe rollout and debugging. |
| 14 | **Class summary** (common root errors; flags errors shared by half or more of a class of 5+ as a likely data/instructions/grader problem) | Helps distinguish grader or assignment problems from student problems. |
| 15 | Error-handling pass: pre-flight checks, argument validation, checkpoint file, `grader_safely` around extras, scan fallback (`STATIC_SCAN_FAILED`), cleanup on interrupt | Matthew asked whether there were enough error handlers. |
| 16 | Record the **Git commit/branch/tag/uncommitted flag** in run info and audit log | Lets a logged grade be traced to exact code; the version number alone can be forgotten. A release tag each term is deferred. |
| 17 | **Privacy**: warn if a chosen folder is inside a Git repo; `.gitignore` patterns; `PRIVACY.md`; grades in the workbook treated as a grade record | Student work and grades are education records. |
| 18 | **Package skeleton** (R/, inst/, tests/, docs/, DESCRIPTION, NAMESPACE) instead of sourced scripts; version from DESCRIPTION; no global assignments | So it can later move to its own repo and R package. |
| 19 | Only `.R` and `.Rmd`; other types reported as unsupported | Course rules (ANA600 R, ANA605 Rmd). |
| 20 | Correctness stays a **manual** review in v1 | Matthew will look at each student's file after the automated checks. |
| 21 | Main function renamed `grade_student_scripts()` to **`codeGrader()`**; `grader_check_setup()` kept | Matthew suggested matching the package name. Done before first use, so no compatibility shim. Mechanical to reverse if wanted. |
| 22 | **Status `draft`, Level `intermediate`**, taken from the code-library root `TAGS.md`; **no separate TAGS.md** for codeGrader | Matthew's decision; the library keeps one controlled vocabulary. |
| 23 | A unique **package-level `README.md`** at `r/codeGrader/` is required; no per-file READMEs | Matthew's decision (CG-006 closed). |
| 24 | Defaults stay **function arguments with defaults** (seed 123, `workers = 3`, 60 s per expression, 300 s per script). A settings file (JSON/YAML) is a possible later layer | Matthew: defaults are fine. Arguments are discoverable with `?codeGrader`, need no extra dependency, and are easy to test. A file would help per-course settings later (CG-027), with precedence argument > file > built-in default. |
| 25 | **Keep the single cohort workbook** that the grader updates and Matthew types scores into (provisional) | Simplest, already built, rolling `.bak` kept; the alternative (separate scores file) is only worth it if something is lost (CG-023, low priority). |
| 26 | `openxlsx` stays an on-demand optional install | Matthew: yes (CG-024 dropped). |
| 27 | Backlog is `r/codeGrader/BACKLOG.md` with `CG-NNN` IDs, independent of the library backlog and never linked from it | Matthew's decision; the package will move to its own repo. |
| 28 | Folder is `D:\GitHub\code-library\r\codeGrader\` | Confirmed; "courseGrader" was a typo. |

## 8. Highest-risk areas: test these first (nothing has been run)

1. Package load: `devtools::load_all()`, then `devtools::document()` (regenerates `NAMESPACE`, creates `man/`), `devtools::test()`.
2. `callr::r_bg()` call: arguments `wd`, `stdout = NULL`, `stderr = NULL`, `supervise = TRUE`; `proc$get_result()` after exit; `proc$kill()`.
3. Dialogs: `rstudioapi::selectFile/selectDirectory/showPrompt/showQuestion`, `utils::select.list(graphics = TRUE)`.
4. Regex strings written inside R strings (path-like detector, absolute-path pattern, worksheet-name cleaner, error-message normalizer).
5. Scanner on odd syntax: `match.call(base::library, e)`, empty-argument handling (`identical(e[[i]], quote(expr = ))`), pipes, formulas, `function` bodies.
6. Worker: sink to `.grader_console.txt`, `setTimeLimit`, `utils::find` resolution, `::`/`:::` overrides with `substitute()`.
7. `openxlsx` workbook round trip: `loadWorkbook`, `names(wb)`, `read.xlsx(wb, sheet =)`, `removeWorksheet`, `conditionalFormatting(type = "contains" / "expression")`, `freezePane`, `saveWorkbook`.
8. `knitr::purl(documentation = 1)` chunk-header format and the Rmd line mapping.
9. Windows specifics: path handling, `normalizePath(winslash = "/")`, locked files, `system2("git", ...)`.

## 9. Decisions and pending items

**Decided (do not re-ask):** see section 7, rows 21 to 28 (function name `codeGrader()`, Status `draft` / Level `intermediate` from the library `TAGS.md`, package README, argument defaults, single cohort workbook, `openxlsx` on demand, own `CG-` backlog, folder name). Dropped by Matthew: the question about supplying real submissions now (they will be provided when he is ready to run; they must stay outside the repo).

**Pending (leave as placeholders; do not ask for them to be solved now):**
1. **Maintainer email** for `Authors@R` (CG-004).
2. **License text** (code-library BL-012; tracked here as CG-002) and **`AI-DISCLOSURE.md`** wording (CG-003).

**Still to do inside the repo (not questions):** choose the Tags values from the library `TAGS.md` (CG-001).

## 10. Deferred work

Everything deferred is already filed in **`codeGrader/BACKLOG.md`** (CG-001 to CG-027, with an index table at the top). It is codeGrader's own backlog, independent of the code-library `BACKLOG.md`. Keep adding new deferred items there as work continues. Summary of what is in it: governance dependencies (tags, license, AI disclosure, maintainer email, root `.gitignore` lines, README convention, comment density); first real run; self-test fixtures; CI; Windows VM/sandbox; template-unchanged check; correctness checks vs a key; Rmd YAML/render check; grades-only export; saved assignment profile; rubric mapping; non-interactive entry point; load-only-needed-packages mode; relative paths for recursive folders; per-assignment lists / renv / magic-number check; cascade detection limits; workbook ownership design; openxlsx auto-install; term tagging and archiving; migration to its own repo.

## 11. Tasks for the Cowork session, in order

1. **Verify access** to `D:\GitHub\code-library`; read `GOVERNANCE.md`, `CONTRIBUTING.md`, `TAGS.md`, `AI-DISCLOSURE.md`, `LICENSE`, the root `README.md`, and `r/functions/load-packages.r` (to match header and style conventions). Do not read or edit the library `BACKLOG.md` for codeGrader work.
2. **Report back**: what you found, any conflict with the decisions in section 9, and what you plan to create. Mention the two pending items; do not block on them.
3. **Pick the Tags** for the file headers from the library `TAGS.md` (CG-001), proposing values to Matthew if more than one fits. Status `draft` and Level `intermediate` are already in place.
4. **Propose the final structure and wait for approval.** Suggested target (inside `D:\GitHub\code-library\r\codeGrader\`):
   ```
   codeGrader/
     DESCRIPTION  NAMESPACE  LICENSE  NEWS.md  README.md  BACKLOG.md  .gitignore  .Rbuildignore
     codeGrader.Rproj          (create for live RStudio work)
     R/                        copy from staging, same file names (main function file is R/codeGrader.R)
     man/                      generated by devtools::document()
     inst/extdata/             approved-packages.txt
     tests/testthat.R  tests/testthat/   (+ fixtures/ later, CG-009)
     docs/                     PRIVACY.md, gitignore-snippet..., requirements record
     .github/workflows/        later, when it becomes its own repo (CG-010)
   ```
5. **Create the structure and copy the files** from `staging\codeGrader\` into `r\codeGrader\`. Keep `BACKLOG.md` as is. Do not edit governance files; propose changes instead.
6. **Make it load and run** (Matthew runs R in RStudio unless Cowork can run it): `devtools::load_all("D:/GitHub/code-library/r/codeGrader")`, `devtools::document()`, `devtools::test()`; fix failures; then `grader_check_setup()`.
7. **Dry run, then single-file run, then full run** on real past submissions when Matthew provides them (kept outside the repo); fix what breaks.
8. Update `Modified` dates and headers, `NEWS.md`, the requirements record, and `BACKLOG.md` (new `CG-` numbers) as changes are made.
9. When everything is working, tell Matthew the staging folder can be deleted. **Do not delete it yourself.**

## 12. Definition of done

* **(a) Live work:** the package loads with `devtools::load_all()`, tests pass or failures are explained, `grader_check_setup()` has no FAIL rows, and a dry run, single-file run, and full run succeed on real submissions.
* **(b) Migration to its own repo/package:** `devtools::check()` clean (or only documented notes); `LICENSE` final; maintainer email set; tags from `TAGS.md`; `URL`/`BugReports` point to the new repo; README up to date; `BACKLOG.md` travels with the package; no student data in the folder or Git history.

## 13. History in one paragraph

The work began as a single R script that opened every file in a folder and ran it with `setwd()`/`file.choose()` neutralized and `read.csv()` redirected to a chosen data file. Over one long conversation it grew into: dynamic prompts and an approved-packages check; per-file process isolation; preloaded approved packages with a necessary/loaded/installed audit; root vs cascade errors with line/function locations; set.seed standardization and checks; hard-coding checks; Rmd support; saved-file handling; draft feedback and an audit log; parallel workers, re-run, single-file, dry-run and solution-check modes; a class summary; cumulative outputs and a cohort workbook with a worksheet per assignment; an error-handling pass; and finally a restructure into an R package skeleton for the code library (versions 1.0 to 1.6 of the code, requirements record v1.8). The explicit non-goals: identifying students beyond file names, checking correctness automatically, exporting to the student information system, and building a VM.
