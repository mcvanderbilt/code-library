# codeGrader

Quickly check whether student homework written in R **runs without error**, and audit how it was written, without opening and running each file by hand.

| Field | Value |
|---|---|
| Language | R (package) |
| Author | Matthew C. Vanderbilt (@mcvanderbilt) |
| Created / Modified | 2026-10-03 / 2026-10-03 |
| Version | 1.6 (package version 1.6.1 in `DESCRIPTION`) |
| Status | `draft` (written with AI assistance; **not yet run in R**) |
| Level | `intermediate` |
| Tags | `automation`, `data-validation`, `reporting`, `teaching` |
| AI-Assisted | `generated (Claude)` — see [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) |
| Dependencies | callr, knitr, utils, tools, stats, grDevices; optional: openxlsx, rstudioapi |
| License | Pending — placeholder `LICENSE` here; final text tracked as code-library BL-012 / CG-002. See [LICENSE](../../LICENSE) for the library's current terms. |

> **Where this lives.** codeGrader is an R package temporarily housed at `r/codeGrader/` inside the code library. It is larger than the library's usual single-snippet scope and will move to its own repository (CG-026); until then it keeps its own `BACKLOG.md` (`CG-NNN` items), independent of the library backlog.

Supported submissions: `.R` scripts (National University ANA600) and `.Rmd` files (ANA605). Other file types are reported as unsupported. The instructor still reviews correctness manually.

## What it does

* Runs every file in its **own R process** (several at once), so one broken or looping student file never stops the run.
* **Packages are attached exactly as the student loads them** (the approved ones named in their own `library()` / `require()` calls, in the student's order), so masking and missing packages behave as they would for the student. The student's `library()` / `install.packages()` calls themselves are *never executed*; they are analysed and reported: unapproved packages, packages used but never loaded (named via the approved packages' export lists) or never installed in the script, packages loaded but unused, packages loaded or installed redundantly (`library(ggplot2)` after `library(tidyverse)`), the same package loaded more than once, package set-up that comes after other code has run (a convention note, not an error), and package lists built in loops (resolved when they are constants). Installing or loading `tidyverse` counts as installing or loading every package it attaches.
* `setwd()`, `file.choose()`, system commands, deletion, and `quit()` are replaced with harmless stand-ins and logged. Every `read.csv()`-style import is redirected to the **data file you choose**.
* Evaluates the **whole script**, not only up to the first error. A **syntax error** no longer stops the check: the unreadable expression is skipped (reported with its line range) and everything else is still scanned and run. Root errors are separated from **cascade errors** (follow-on failures) and from **repeats** of the same error later in the script, which are reported once. Reports the line range (or Rmd line and chunk) and the failing function.
* `set.seed()` calls run a **standard seed you enter**, never the student's value. Random-number code with no earlier `set.seed()` in its code block is flagged, and the grader runs the seed itself so the script still executes.
* Flags hard-coded file paths, file names, and URLs written directly inside function calls (values stored in a variable first are fine; numbers such as `round()` digits are fine).
* Convention notes (never errors): numbered template sections with no code under them; `png()`/`pdf()` opened without `dev.off()`; `attach()`, `View()`, mid-script `rm(list = ls())`, unguarded `install.packages()`; and, with `codeGrader(style = TRUE)`, a small `lintr` pass (naming, `<-`, operator spacing, commas, line length, `T`/`F`).
* When an assignment requires a saved file, you can name the required file(s); the grader checks that a file with that name was actually written.
* Drafts feedback text per student (for you to review and paste into the student information system by hand).
* Appends to **cumulative CSV files** and a **cohort workbook** with one worksheet per assignment (your typed scores/comments are preserved on re-runs). A permanent audit log records the grader version, Git commit, seed, and file fingerprints (MD5) for every graded file.

## Using it (inside the code library)

```r
# one time
install.packages(c("devtools", "callr", "knitr", "openxlsx", "rstudioapi"))

# each session
devtools::load_all("D:/GitHub/code-library/r/codeGrader")

grader_check_setup()                       # once, before a real batch
res <- codeGrader(assignment = 3)
```

Recommended first-run sequence: `grader_check_setup()` → a **dry run** of the real folder (nothing executed) → **one file** → the whole folder (optionally with your instructor solution checked first).

`codeGrader()` opens pop-ups for: the mode (whole folder / one file / re-run earlier failures / dry run), the standard seed, the student folder, the data file, the output folder, a results name (use one name per cohort, e.g. `ANA600_Fall2026`), the approved-packages list (cancel to get a template), whether students must save a file, and an optional instructor solution.

## Output files (in the output folder you choose)

| File | Contents |
|---|---|
| `<name>.csv` | One row per file per run (cumulative); the system of record |
| `<name>_errors.csv` | Every error with location, function, and type (syntax / root / cascade / repeat) |
| `<name>_feedback.csv` | Draft feedback per student, with a blank `instructor_comments` column |
| `<name>_class_summary.csv` | Class-level counts per run |
| `<name>_workbook.xlsx` | Cohort workbook: sheet "Assignment N" per assignment plus "Class summaries" |
| `<name>_run_info.txt` | Settings, versions, and Git commit for each run |
| `<name>_console/<run>/`, `<name>_saved_files/<run>/` | Each student's console output and any files they saved |
| `grading_audit_log.csv` | Permanent log across all runs |

Close the CSVs and the workbook in Excel before a run so rows can be appended (otherwise a `_PENDING_` copy is written, nothing is lost).

## Folder layout (R package)

```
codeGrader/
  DESCRIPTION  NAMESPACE  LICENSE  NEWS.md  README.md  PRIVACY.md  codeGrader.Rproj
  R/            package code (one file per concern)
  inst/extdata/ approved-packages.txt (starter list)
  tests/        testthat tests (scanner, reports, worker)
  notes/        requirements/spec record (project-description-and-instructions.md),
                gitignore snippet for the library root
  man/          generated by devtools::document() (not yet created)
  BACKLOG.md    this package's own backlog (CG-001, CG-002, ...)
  staging/      the pre-repo handoff copy; delete once the package runs (not part of the package)
```

The hand-written material is in `notes/`, not `docs/`, because `docs/` is where pkgdown writes a package website and the code-library root `.gitignore` ignores every `docs/` folder for that reason.

## Student privacy

Outputs contain student work and file names. **Never commit them to GitHub**; read `PRIVACY.md`. The folder-picker warns if a chosen folder is inside a Git repository, and `.gitignore` already excludes the output file patterns.

## Moving this to its own repository / package

1. Copy the `codeGrader` folder out of `code-library/r/` and run `git init` (or create the GitHub repo and push).
2. In `DESCRIPTION`: set `URL` and `BugReports` to the new repo, add the maintainer **email** to `Authors@R`, and finalize `License` (replace the placeholder `LICENSE`).
3. Run `devtools::document()` (creates `man/`), then `devtools::test()` and `devtools::check()`.
4. Optionally add `usethis::use_github_action("check-standard")` and a pkgdown site.
5. Decide whether to keep the code-library header block in each `R/` file (Tags, Status, Level, and AI-Assisted already use the library's `TAGS.md` vocabulary) or drop it once the package no longer lives in the library.

## Known limitations

See `notes/project-description-and-instructions.md` (section 9) and this package's own `BACKLOG.md` (kept separate from the code-library backlog so it moves with the package). In short: not yet run in R; blocked-call list guards against accidents, not malicious code (a sandbox/VM is backlogged); the cohort workbook is rewritten with openxlsx, which can drop charts or pivot tables; Rmd files are converted with `knitr::purl()` rather than knitted.
