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
