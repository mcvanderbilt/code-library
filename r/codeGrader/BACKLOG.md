# codeGrader backlog

This is the **backlog for codeGrader only**. It lives at `r/codeGrader/BACKLOG.md`, is independent of the code-library `BACKLOG.md` (which does not link to it and does not track these items), and moves with the package when codeGrader gets its own GitHub repository and R package.

* **Last updated:** 2026-10-03 (v1.7.0 after first real run: parse recovery, student-order package check, redundant loads, repeat errors; CG-030, CG-031 added; CG-032 to CG-036 added and done) | **Owner:** Matthew C. Vanderbilt
* **IDs:** `CG-NNN`, numbered from `CG-001`. The `CG-` prefix keeps these distinct from the library's `BL-NNN` items; the one library item referenced here is written "code-library BL-012" (its license item).
* **Statuses:** Backlog (not started) | In progress | Done | Dropped. Closed items move to "Closed" at the bottom with the date and a one-line outcome.
* **Adding an item:** next free `CG-` number, same fields as below (Area, Status, Priority, Added, Why, Next step). Anything not being done right now goes here rather than getting lost in chat.

## Index

| ID | Title | Area | Priority | Status |
|---|---|---|---|---|
| CG-001 | Confirm Tags values against the code-library `TAGS.md` (Status and Level are set) | Governance | - | Done |
| CG-002 | Replace the placeholder codeGrader `LICENSE` once code-library BL-012 is resolved | Governance (`LICENSE`) | High | Backlog |
| CG-003 | `AI-DISCLOSURE.md` and the AI-Assisted field | Governance (`AI-DISCLOSURE.md`) | - | Done |
| CG-004 | Maintainer email in `DESCRIPTION` | Packaging | Medium (needed before `R CMD check` / standalone repo) | Backlog |
| CG-005 | Student-data patterns in the code-library root `.gitignore` (while codeGrader lives in the library) | Repo hygiene / privacy (library-side change; needs confirmation) | Medium | Backlog |
| CG-006 | README convention for a package inside the library | Governance | - | Done |
| CG-007 | Comment density versus the "students can learn from it" standard | Code quality | Medium | Backlog |
| CG-008 | First real run and shake-out (nothing has been executed in R yet) | Testing | High | Backlog |
| CG-009 | Full self-test fixtures | Testing | Medium | Backlog |
| CG-010 | Continuous integration for the standalone repo | Packaging | Low | Backlog |
| CG-011 | Windows VM / sandbox for hard isolation | Security | Medium (before grading unfamiliar or large batches) | Backlog |
| CG-012 | Template-unchanged check | Feature | Medium | Backlog |
| CG-013 | Correctness checks against an instructor key | Feature | Medium | Backlog |
| CG-014 | Rmd YAML validation and full knit/render check | Feature | Medium (ANA605) | Backlog |
| CG-015 | Grades-only export at term end | Feature / records | Medium | Backlog |
| CG-016 | Saved assignment profile | Feature | Low | Backlog |
| CG-017 | Rubric file mapping flags to point deductions | Feature | Low | Backlog |
| CG-018 | Non-interactive entry point | Feature / testing | Medium | Backlog |
| CG-019 | Optional "load only needed packages" mode | Performance | Low | Backlog |
| CG-020 | Relative paths for recursive folders | Feature | Low | Backlog |
| CG-021 | Per-assignment approved lists and data files; `renv` version pinning; numeric ("magic number") hard-coding check | Feature | Low | Backlog |
| CG-022 | Cascade-error detection beyond plain assignments | Accuracy | Low | Backlog |
| CG-023 | Decide whether the cohort workbook should be machine-owned only | Design | Low | Backlog |
| CG-024 | Runtime auto-install of `openxlsx` | Packaging | - | Dropped |
| CG-025 | Tag a codeGrader release each term; archive cumulative files per term | Operations | Low | Backlog |
| CG-026 | Move codeGrader to its own repository and R package | Packaging | Planned | Backlog |
| CG-027 | Optional settings file (JSON or YAML) for defaults | Feature | Low | Backlog |
| CG-028 | Minimum package versions in header `Dependencies` fields | Governance | Low | Backlog |
| CG-029 | List codeGrader in an `r/README.md` (library-side; folder README does not exist yet) | Governance (library-side) | Low | Backlog |
| CG-030 | Assignment templates: store file names in variables (national-university repo) | Course materials (other repo) | Medium | Backlog |
| CG-031 | "Did you forget library(X)?" hint when a base function of the same name fails | Accuracy | Low | Backlog |
| CG-032 | Section coverage: numbered template sections with no code | Feature | - | Done |
| CG-033 | Graphics-device balance: `png()`/`pdf()` without `dev.off()` | Feature | - | Done |
| CG-034 | Bad-practice calls: `attach()`, mid-script `rm(list = ls())`, `View()`, unguarded `install.packages()` | Feature | - | Done |
| CG-035 | Optional style pass with `lintr` (naming, spacing, line length) as a separate column | Feature | - | Done |
| CG-036 | Check saved file names against the names the assignment requires | Feature | - | Done |

---

## Dependencies on code-library governance (codeGrader-side work)

*These track what codeGrader needs from the code library's governance files. The governance files themselves (`TAGS.md`, `LICENSE`, `AI-DISCLOSURE.md`, `GOVERNANCE.md`, library `.gitignore`) are changed only after Matthew confirms, and those changes are NOT tracked in the library's `BACKLOG.md` by this file. When codeGrader moves to its own repo, this section becomes codeGrader's own governance tasks.*

### CG-002: Replace the placeholder codeGrader `LICENSE` once code-library BL-012 is resolved
- **Area:** Governance (`LICENSE`) | **Status:** Backlog | **Priority:** High | **Added:** 2026-10-03
- **Why:** `codeGrader/LICENSE` is a placeholder that points to code-library BL-012; `DESCRIPTION` says `License: file LICENSE`. It must be real before the package is published or leaves the library.
- **Next step:** Paste the final license text; confirm the `License:` field.

### CG-004: Maintainer email in `DESCRIPTION`
- **Area:** Packaging | **Status:** Backlog | **Priority:** Medium (needed before `R CMD check` / standalone repo) | **Added:** 2026-10-03
- **Why:** `Authors@R` has no email; one is required for a maintainer.
- **Next step:** Matthew supplies the address; add it to `person(...)`.

### CG-005: Student-data patterns in the code-library root `.gitignore` (while codeGrader lives in the library)
- **Area:** Repo hygiene / privacy (library-side change; needs confirmation) | **Status:** Backlog | **Priority:** Medium (lowered 2026-10-03) | **Added:** 2026-10-03
- **Why:** Grading outputs contain student work and must never be committed. The package `.gitignore` already excludes them; the library root does not necessarily.
- **Checked 2026-10-03:** the library root `.gitignore` already ignores `*.csv`, `*.xlsx`, `*.bak`, and `*.log` everywhere, and Git honours the package's own `.gitignore` for anything under `r/codeGrader/`. The only uncovered patterns are `*_run_info.txt`, `*_console/`, `*_saved_files/`, and the `submissions/`-style folders (which would hold student `.R` files), and only if outputs were saved elsewhere inside the library. The folder picker already warns when a chosen folder is inside a Git repo.
- **Next step:** Propose adding the lines from `notes/gitignore-snippet-for-code-library.txt` to the library `.gitignore`; apply only after Matthew confirms. Becomes moot once codeGrader is its own repo (its own `.gitignore` already covers this).

### CG-007: Comment density versus the "students can learn from it" standard
- **Area:** Code quality | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** The library requires code commented thoroughly enough for students to follow. The codeGrader code has section comments and header blocks, but many functions (especially `scan.R` and `worker.R`) would benefit from more explanatory comments and roxygen-style descriptions of internals.
- **Next step:** Documentation pass over all `R/` files; consider `@noRd` roxygen blocks for internals.

### CG-028: Minimum package versions in header `Dependencies` fields
- **Area:** Governance | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** The code-library header template asks for `package (>= x.y.z)`; the codeGrader headers list bare package names because nothing has been run yet and the minimum versions are unknown.
- **Next step:** After the first successful run (CG-008), record the versions actually used (`callr`, `knitr`, `openxlsx`, `rstudioapi`) in each header and in `DESCRIPTION`.

### CG-029: List codeGrader in an `r/README.md` (library-side; folder README does not exist yet)
- **Area:** Governance (library-side) | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** `GOVERNANCE.md` §2 requires a README in every language folder and §7 requires the parent folder README to list each object. `r/` has no README today, and `GOVERNANCE.md` §1 routes packages to `/staging/`, so codeGrader's placement at `r/codeGrader/` (Matthew's decision, HANDOFF row 28) is not described anywhere in the library itself.
- **Next step:** When an `r/README.md` is written, list codeGrader as a package temporarily housed under `r/` and headed to its own repo. Library-side change; needs confirmation.

## Verification and quality

### CG-008: First real run and shake-out (nothing has been executed in R yet)
- **Area:** Testing | **Status:** Backlog | **Priority:** High | **Added:** 2026-10-03
- **Why:** All code was written without being run. Sequence: `devtools::load_all()` → `devtools::document()` → `devtools::test()` → `grader_check_setup()` → dry run on real past submissions → one file → whole folder (with instructor solution check).
- **Next step:** Run it, fix failures; see "Highest-risk areas" in `HANDOFF.md`.

### CG-009: Full self-test fixtures
- **Area:** Testing | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** Tests cover pure functions and one worker run. A fixtures folder of small fake student scripts with known problems and expected results (clean, parse error, missing library, package loop, no seed, hard-coded path, Rmd, crash, cascade errors, timeout) would regression-test the whole pipeline. These are test cases for the grader, not study material.
- **Next step:** Build `tests/testthat/fixtures/` and an end-to-end test that runs `codeGrader()` non-interactively (needs a non-dialog input path; see CG-018).

### CG-010: Continuous integration for the standalone repo
- **Area:** Packaging | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Next step:** `usethis::use_github_action("check-standard")` after the package moves to its own repo.

## Isolation and security

### CG-011: Windows VM / sandbox for hard isolation
- **Area:** Security | **Status:** Backlog | **Priority:** Medium (before grading unfamiliar or large batches) | **Added:** 2026-10-03
- **Why:** The grader runs each student file in a separate R process with a temporary working directory and a blocked-call list. That protects the grading run, not the machine: student code still has the instructor's Windows permissions. **Not covered:** writes to absolute paths, reading arbitrary files, network calls other than `download.file`/`browseURL`, `Sys.setenv`, any call not on the blocked list.
- **Options, cheapest first:** Windows Sandbox (`.wsb`, no network, mapped folders; Windows 11 Pro/Enterprise) → Hyper-V VM with snapshot → Docker (`rocker/r-ver`, `--network none`) → low-privilege Windows account.
- **Acceptance:** student code cannot read or write outside the mapped input/output folders; no network; one command launches the same workflow; approved packages pre-installed; outputs land in the chosen output folder. Keep the blocked-call list and callr isolation (defense in depth).

## Features deferred

### CG-012: Template-unchanged check
- **Area:** Feature | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** Confirm students changed only the answer areas between the questions in the homework template. Needs a marker convention for answer regions, or a diff that ignores them.

### CG-013: Correctness checks against an instructor key
- **Area:** Feature | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** Version 1 only checks that code runs and follows conventions; Matthew reviews correctness manually. Later: expected objects, dimensions, values, plots; saving plots to PDF/PNG for review.

### CG-014: Rmd YAML validation and full knit/render check
- **Area:** Feature | **Status:** Backlog | **Priority:** Medium (ANA605) | **Added:** 2026-10-03
- **Why:** Today `.Rmd` is converted with `knitr::purl()` and its code is run; YAML errors, inline R code, and rendering failures are not tested.

### CG-015: Grades-only export at term end
- **Area:** Feature / records | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** The cohort workbook holds the grades Matthew keeps for reference. A minimal export (assignment, file, score) lets detailed run data (console logs, saved files, error files, audit log) be archived or deleted separately, per records policy.

### CG-016: Saved assignment profile
- **Area:** Feature | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Reload the startup answers (folders, data file, approved list, seed, etc.) for the next run of the same assignment.

### CG-017: Rubric file mapping flags to point deductions
- **Area:** Feature | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Could pre-fill a suggested deduction next to `instructor_score`.

### CG-018: Non-interactive entry point
- **Area:** Feature / testing | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** All inputs currently come from pop-up dialogs, which blocks scripted runs and end-to-end tests. Add an arguments-based path (a list of inputs) that skips the dialogs; keep dialogs as the default.

### CG-019: Optional "load only needed packages" mode
- **Area:** Performance | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Each worker loads all approved packages; a one-time function-to-package map could load only what each student needs. Default must stay "load all approved" for fidelity (masking order).

### CG-020: Relative paths for recursive folders
- **Area:** Feature | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Results are identified by file name, so duplicate names in different sub-folders currently stop the run.

### CG-021: Per-assignment approved lists and data files; `renv` version pinning; numeric ("magic number") hard-coding check
- **Area:** Feature | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03

### CG-030: Assignment templates: store file names in variables (national-university repo)
- **Area:** Course materials (lives in the national-university repo, not here) | **Status:** Backlog | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** The ANA600 A11 template itself writes `read.csv("vehicles.csv")` and tells students to save to `"wk1Data.comb08.hist.png"`, so the grader's hard-coded-path check flags every student who follows the template. Matthew's decision (2026-10-03): keep the check and change the templates, so students practise the habit being checked (`dataFile <- "vehicles.csv"; read.csv(dataFile)`; same for the `ggsave()`/`png()` file name). Until the templates change, these two flags are expected on every A11 submission.
- **Next step:** Update the ANA600 (and ANA605 Rmd) templates and the assignment text in the national-university repo; re-run a graded folder to confirm the flag disappears for template-following students.

### CG-031: "Did you forget library(X)?" hint when a base function of the same name fails
- **Area:** Accuracy | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Since v1.7.0 the worker attaches only the student's own packages, so `filter(df, x > 1)` without `library(dplyr)` resolves to `stats::filter` and fails at run time. The student gets the real error (correct) but not the hint that an approved package exports a function of that name. The export map (`ctx$export_map`) already has what is needed.
- **Next step:** In `grader_finalize_file()`, for a root error whose `failing_function` resolved to a base package while an approved package exports the same name, append "(an approved package, dplyr, has a function of this name; did you mean to load it?)" to the message.

### CG-032: Section coverage: numbered template sections with no code
- **Area:** Feature | **Status:** Done 2026-10-03 (v1.7.0) | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** Students sometimes skip a question entirely. The scanner already labels every expression with its nearest `# 7. BAR CHART ... ----` header, so a header with no expression under it is cheap to detect and would save the instructor a scroll through each file.
- **Next step:** In `grader_scan_script()`, list header labels with zero expressions (ignoring the help / install / working-directory preamble); new column `sections_without_code`, feedback sentence "No code was found under: 7. BAR CHART OF EXPLANATORY VARIABLE".

### CG-033: Graphics-device balance: `png()`/`pdf()` without `dev.off()`
- **Area:** Feature | **Status:** Done 2026-10-03 (v1.7.0) | **Priority:** Medium | **Added:** 2026-10-03
- **Why:** A common A11 mistake: `png("file.png")` opened and never closed, so the file is empty and every later plot goes into it; or a stray `dev.off()` with no device open (a run-time error the student does not understand). The worker already opens `pdf(NULL)` and can watch `dev.list()` between expressions.
- **Next step:** Static count of device-opening calls versus `dev.off()` per code block, plus a worker check of `dev.cur()` at the end; flag `GRAPHICS_DEVICE_LEFT_OPEN`.

### CG-034: Bad-practice calls: `attach()`, mid-script `rm(list = ls())`, `View()`, unguarded `install.packages()`
- **Area:** Feature | **Status:** Done 2026-10-03 (v1.7.0) | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Each is harmless in the sandbox (`View()` and installs are already neutralised) but is a habit worth a one-line comment: `attach()` hides where variables come from; `rm(list = ls())` after set-up wipes the student's own objects; a bare `install.packages("x")` reinstalls on every run (the template's `if (!require(...))` guard is the convention).
- **Next step:** Add to the static scan as a `practice_notes` column with one short sentence per pattern; `View()` and `install.packages()` counts are already available from `blocked_calls` and `sc$installed`.

### CG-035: Optional style pass with `lintr` (naming, spacing, line length) as a separate column
- **Area:** Feature | **Status:** Done 2026-10-03 (v1.7.0) | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Course conventions on naming (`wk1Data`), spacing around `<-`, and line length are currently reviewed by eye. `lintr::lint()` with a small, chosen set of linters would give a count and the first few examples without executing anything. Off by default so run time and noise stay down; approved list is unaffected.
- **Next step:** `codeGrader(style = TRUE)`; linters: `object_name_linter`, `assignment_linter`, `infix_spaces_linter`, `line_length_linter(100)`, `commas_linter`. New columns `style_issues` (count) and `style_examples`.

### CG-036: Check saved file names against the names the assignment requires
- **Area:** Feature | **Status:** Done 2026-10-03 (v1.7.0) | **Priority:** Low | **Added:** 2026-10-03
- **Why:** `expect_saved` only says whether *a* file was saved. A11 requires exactly `wk1Data.comb08.hist.png`; students save `histogram.png` or `wk1Data.comb08.hist` (no extension) and lose the point without knowing why.
- **Next step:** Let the prompt accept one or more required file names (pattern allowed); compare with `files_written`; feedback "Your script saved 'histogram.png' but the assignment requires 'wk1Data.comb08.hist.png'". Ties in with CG-016 (saved assignment profile).

### CG-022: Cascade-error detection beyond plain assignments
- **Area:** Accuracy | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Only plain `x <- ...`, `assign("x")`, and `for` variables are tracked. A failed `df$col <- ...` or `names(x) <- ...` can leave later errors mislabeled as root errors. Related limits: functions passed as values (`sapply(x, mean)`) and dataset objects are not counted when deciding which packages are necessary; random-number calls inside function definitions are not checked until called.

### CG-023: Decide whether the cohort workbook should be machine-owned only
- **Area:** Design | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** The workbook is reloaded and rewritten with `openxlsx`, which can drop charts, pivot tables, or images and may change formatting on older sheets. A rolling `.bak` is kept. Alternative: keep the workbook as a pure output and store instructor scores in a separate file merged by file name.
- **Provisional decision 2026-10-03:** keep the single cohort workbook as built (one Excel file the grader updates and Matthew types scores into; a rolling `.bak` copy is kept). Do not build the alternative now. Revisit only if something is lost when the workbook is updated.

### CG-027: Optional settings file (JSON or YAML) for defaults
- **Area:** Feature | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** Defaults (`workers = 3`, expression timeout 60 s, script timeout 300 s, `recursive`, `save_console`, the random-number function list, the exclude pattern, the seed default 123) are `codeGrader()` arguments with defaults; Matthew confirmed the defaults are fine. Per-course or per-cohort settings (for example ANA600 vs ANA605) could live in a small file kept outside the code.
- **Next step:** add `settings = NULL` (path to a JSON file or a named list). Precedence: explicit argument > settings file > built-in default. Read with `jsonlite` (Suggests). Fold in CG-016 (saved assignment profile) so one file can hold settings and startup answers.

## Operations

### CG-025: Tag a codeGrader release each term; archive cumulative files per term
- **Area:** Operations | **Status:** Backlog | **Priority:** Low | **Added:** 2026-10-03
- **Why:** The run info records commit, branch, tag, and an uncommitted-changes flag, but only a tag gives a human-readable version. Results, errors, feedback, and the audit log grow every run and need a per-term archive/rotation routine that follows records-retention policy.

### CG-026: Move codeGrader to its own repository and R package
- **Area:** Packaging | **Status:** Backlog | **Priority:** Planned | **Added:** 2026-10-03
- **Next step:** Follow the checklist in `codeGrader/README.md` ("Moving this to its own repository / package"); depends on CG-001, CG-002, CG-004 (and CG-003 if required).

---

## Closed

### CG-001: Confirm Tags values against the code-library `TAGS.md`: Done 2026-10-03
- **Outcome:** Tags set to `automation, data-validation, reporting, teaching` (one set package-wide, Matthew's choice) in every `R/*.R` header and the README. All four are in the library's `TAGS.md` vocabulary; nothing was added to it. Status `draft` and Level `intermediate` unchanged.

### CG-003: `AI-DISCLOSURE.md` and the AI-Assisted field: Done 2026-10-03
- **Outcome:** The library's `AI-DISCLOSURE.md` was already approved (2026-09-23). Headers changed from the ad hoc "Yes - Claude" to the `TAGS.md` value `generated (Claude)`; the README links to the disclosure. No change to the disclosure file was needed.

### CG-006: README convention for a package inside the library: Done 2026-10-03
- **Outcome:** Matthew decided that a unique package-level `README.md` at `r/codeGrader/` is required (it exists). No per-file READMEs and no `GOVERNANCE.md` change are needed.

### CG-024: Runtime auto-install of `openxlsx`: Dropped 2026-10-03
- **Outcome:** accepted as is. `openxlsx` (a Suggests dependency) installs on demand with a message. Revisit only if the package is ever prepared for CRAN.

### CG-032: Section coverage: Done 2026-10-03
- `sections_without_code` column and `SECTION_WITHOUT_CODE` flag (v1.7.0). Detail block kept under "Features deferred" for the design notes.
### CG-033: Graphics-device balance: Done 2026-10-03
- Static open/close counts, worker `devices_left_open`, `dev.off()`/`graphics.off()` stand-ins (v1.7.0).
### CG-034: Bad-practice calls: Done 2026-10-03
- `practice_notes` column, one note per kind (v1.7.0).
### CG-035: Optional `lintr` style pass: Done 2026-10-03
- `codeGrader(style = TRUE, style_naming, style_line_length)`; `style_issues` / `style_examples` (v1.7.0). `lintr` in `Suggests`.
### CG-036: Required saved file names: Done 2026-10-03
- Prompt for required name(s); `required_files_missing` column and `REQUIRED_FILE_NOT_SAVED` flag (v1.7.0).
