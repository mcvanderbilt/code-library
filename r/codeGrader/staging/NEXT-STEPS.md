# codeGrader: exact next steps for Matthew

Written 2026-10-03. Do Part A first (File Explorer), then Part B (Cowork). `HANDOFF.md` in this folder is what the new Cowork session reads.

## Part A: put the files in place (File Explorer and GitHub Desktop)

1. **Download** `codeGrader_staging.zip` from the chat (for example to your Downloads folder).
2. In File Explorer open `D:\GitHub\code-library\`. Open the `r` folder (it may display as `R`; Windows treats them the same).
3. Inside `r`, create a folder named `codeGrader` if it is not there yet. Inside it, create a folder named `staging`. You should now have the empty folder:
   `D:\GitHub\code-library\r\codeGrader\staging\`
4. Right-click the zip, choose **Extract All...**, and **replace the destination path completely** with:
   `D:\GitHub\code-library\r\codeGrader\staging`
   then click **Extract**. (Windows suggests a destination ending in `codeGrader_staging`; do not keep that.)
5. **Check the result.** All of these must exist:
   * `D:\GitHub\code-library\r\codeGrader\staging\HANDOFF.md`
   * `...\staging\NEXT-STEPS.md` (this file)
   * `...\staging\codeGrader\DESCRIPTION`
   * `...\staging\codeGrader\BACKLOG.md`
   * `...\staging\codeGrader\R\` with 9 files, including `codeGrader.R`
   * `...\staging\codeGrader\tests\testthat\` with 4 test files
   If you see `staging\staging\` or `staging\codeGrader_staging\`, move the contents up one level so the paths above are right.
6. Open **GitHub Desktop**. You will see about 28 new files under `r/codeGrader/staging`. **Do not commit or push yet.** Leave them as uncommitted changes.
7. Keep any student submissions and data files **outside** `D:\GitHub\code-library\` (for example `D:\GradingWork\`). They must never be in the repo.

## Part B: start the Cowork session

1. Open the Claude desktop app, open the **Code Library** project, and start a **new Cowork session**.
2. If Cowork asks which folder it may use, choose the **repo root** `D:\GitHub\code-library` (not the staging folder). It needs to read `TAGS.md`, `GOVERNANCE.md`, and the other library files.
3. **Paste this as your first message:**

> Read `D:\GitHub\code-library\r\codeGrader\staging\HANDOFF.md` completely, then `staging\codeGrader\BACKLOG.md`. Follow the Code Library project rules. Decisions are already made (HANDOFF section 9): the folder is `D:\GitHub\code-library\r\codeGrader\`; the main function is `codeGrader()`; Status is `draft` and Level is `intermediate` from the code-library root `TAGS.md` (do not create a separate TAGS.md); codeGrader keeps its own `BACKLOG.md` with `CG-NNN` IDs and nothing is added to the library `BACKLOG.md`; the maintainer email and the license/AI-disclosure wording are pending, so leave them as placeholders. Before creating anything, tell me what you found in the repo (TAGS.md, GOVERNANCE.md, conventions) and what you plan to create, then propose the final folder structure and wait for my OK.

4. **Expected reply:** a summary of what it found in the repo, the Tags it suggests from `TAGS.md`, the two pending items (email, license/AI disclosure), and a proposed folder tree. If it asks for the email or license text, answer: *"Pending. Leave placeholders."*
5. **Reply "Approved"** if the proposed tree matches the one in `HANDOFF.md` section 11 (step 4), or tell it what to change.
6. When it says the files are created, check that `D:\GitHub\code-library\r\codeGrader\` contains `DESCRIPTION`, `NAMESPACE`, `README.md`, `BACKLOG.md`, `R\`, `tests\`, `inst\`, and `docs\`.
7. **In RStudio**, run these one at a time (the first line only once):
   ```r
   install.packages(c("devtools", "callr", "knitr", "openxlsx", "rstudioapi", "testthat", "withr"))
   devtools::load_all("D:/GitHub/code-library/r/codeGrader")
   devtools::document()
   devtools::test()
   grader_check_setup()
   ```
   Copy any error messages or failing test output into the Cowork conversation. (Never paste student work or names.)
8. **First real runs** (when you have a data file and a few past submissions stored outside the repo). In RStudio:
   ```r
   codeGrader()                  # choose "Dry run" in the first pop-up
   codeGrader(assignment = 1)    # then "Grade one file", then "Grade the whole folder"
   ```
9. When Cowork confirms everything is in place and working, **delete** `D:\GitHub\code-library\r\codeGrader\staging\` in File Explorer.
10. In GitHub Desktop, review the changes (no student data, no `staging`), write a commit message such as *"Add codeGrader package skeleton (draft)"*, commit, and push when you are ready.
11. From then on, continue all codeGrader discussion in that Cowork conversation.
