# Student data handling for codeGrader

*Practical checklist, not legal advice. Confirm retention periods and approved storage with your institution(s) (National University / University of San Diego records, registrar, or compliance office).*

## What the grader creates (all contain student work or identifiable file names)
| Output | Contains |
|---|---|
| `<name>.csv` | Per-file results, flags, draft feedback (grows with every run) |
| `<name>_errors.csv` | Error messages and code locations (grows) |
| `<name>_feedback.csv` | Draft feedback text for the student information system (grows) |
| `<name>_class_summary.csv` | Class-level counts per run (no per-student detail) |
| `<name>_workbook.xlsx` (+ `.bak`) | Cohort workbook: one worksheet per assignment with results, draft feedback, and YOUR scores/comments |
| `<name>_review_<run>.xlsx` | Stand-alone workbook for one run (only if the cohort workbook could not be updated) |
| `<name>_checkpoint_<run>.csv` | Temporary safety copy written while grading; deleted when the run finishes normally |
| `<name>_dryrun.csv` | Dry-run listing (grows) |
| `<name>_console/<run>/` | Each student's console output |
| `<name>_saved_files/<run>/` | Files the students' scripts saved |
| `<name>_run_info.txt` | Settings, paths, versions (one block per run) |
| `grading_audit_log.csv` | Permanent log across all runs (hashes, status, feedback) |

## Rules of thumb
1. **Never commit any of the above to GitHub.** The grader asks you to confirm if a chosen folder is inside a Git repository. The package `.gitignore` already excludes these patterns; add `notes/gitignore-snippet-for-code-library.txt` to the code-library `.gitignore` as a second safeguard. Keep the student submissions folder and the output folder outside `code-library`.
2. **Store outputs only in institution-approved locations** (for example, an encrypted drive or approved cloud storage), not on personal cloud services.
3. **The grader runs locally.** Student code and results are not sent to Claude unless you paste or upload them into a chat. If you want help debugging a student's script or a results file, check your institution's AI policy first and remove identifying information.
4. **Share minimum necessary.** Send each student only their own feedback. Do not share the class-wide results or audit log.
5. **Cumulative files keep growing.** Results, errors, feedback and the audit log are appended run after run, so one file can hold a whole term of student work. Back it up under the same rules, and archive or delete it when the retention period ends.
6. **Grades you keep.** The cohort workbook holds the grades you enter (`instructor_score`, `instructor_comments`), so treat it as a grade record under your institution's grade-records policy. Detailed run data (console logs, saved files, error files, the audit log) may be kept for a shorter or different period if your policy allows; ask your records office.
7. **Retention.** Keep the audit log for as long as your institution's grade-records policy requires, then delete it together with the matching results, console, and saved-file folders. Record the retention period you are following here: `_______________`.
8. **File names can identify students.** Treat the `file` column as identifying information.
9. **Backups** of the output folder should follow the same access rules as the originals.
10. **Delete working copies** of student submissions after grading if your policy requires it. The grader itself already deletes its temporary run folders after every file.

## Feedback is a draft
The feedback text is generated from automated checks. Review it (and add your own comments in `instructor_comments`) before posting anything to the student information system.
