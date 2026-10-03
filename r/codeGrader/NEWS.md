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
