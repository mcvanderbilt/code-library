# Backlog

Bugs, enhancement requests, and open questions for Code Library, in one
place. Follows the same format as the "AI + LLM + PKM" project's
`BACKLOG.md`.

**Format:** every item has a stable ID (`BL-NNN`) that is never reused or
renumbered, even if the item is later dropped -- so we can refer to
"BL-004" precisely instead of re-describing it. Checkbox = done. When an
item is finished, check it off and move it into **Done** at the bottom
with the date; leave everything else where it is rather than renumbering.
New items get the next unused ID, appended to the relevant section.

---

## Bugs

(none yet)

## Enhancements

- [ ] **BL-001** — CI (lint/tests/docs build via GitHub Actions). Deferred until the folder structure, header template, and tag governance are settled -- revisit as a later phase, not now.
- [ ] **BL-003** — Expand `/sql/` further (e.g., dialect subfolders under each task folder) if dialect conflicts or volume ever warrant it -- task-based split (`tables/`, `views/`, `stored-procedures/`, `functions/`, `queries/`, `triggers/`, `indexes/`) is the starting structure.
- [ ] **BL-009** — Execute the folder restructure per the finalized plan. **Done 2026-09-23:** `/vsto/` (excel/, access/, outlook/), `/vba/` (excel/, access/, outlook/), `/sql/` (tables/, views/, stored-procedures/, functions/, queries/, triggers/, indexes/), `/python/` (functions/, scripts/), `/html/` (snippets/, templates/), `/staging/`, `/archive/`, `/learning/`, `/research/` (local/) all created with placeholder READMEs; `.gitignore` updated for `/archive/`, `/learning/`, `/research/local/`; `r/bayesToolkit` copied to `/archive/bayesToolkit/`; `vba-excel/excel-formatting` copied to `/staging/excel-formatting/`. **Still needed (manual, by Matthew):** delete the old `r/bayesToolkit/` and `vba-excel/` folders -- this session has no shell/delete access on the local machine, so the copies exist at both the old and new locations until removed by hand.
- [ ] **BL-010** — VS Code extension: a Command Palette / menu-driven "New Snippet" and "New Staged Project" flow (mirroring the AI + LLM + PKM extension's "New X" pattern) that, on invocation, prompts for language/topic/name, creates the code object's own folder in the right place per `GOVERNANCE.md` §2's placement rules, copies and pre-fills the language's header template from `templates/` (Author, Created, and as many fields as can be defaulted), and copies `templates/readme-code-object.md` into the new folder -- all the "standardized bones" initialized in one step instead of assembled by hand each time. Evaluate/build once conventions (header template, tags, folder structure) are stable enough not to require reworking the extension immediately after -- they're stable as of 2026-09-23 (`GOVERNANCE.md`/`TAGS.md`/`AI-DISCLOSURE.md` approved), so this is now buildable, not blocked on further design.
- [ ] **BL-011** — VS Code user snippets for the header template -- a cheaper first step than BL-010 (autocomplete boilerplate without building/maintaining an extension). Try this before deciding on BL-010.
- [ ] **BL-012** — Decide and adopt final `LICENSE` text: leading candidate is PolyForm Noncommercial 1.0.0 (software-specific, plain-language, noncommercial-only) plus a supplementary attribution clause (PolyForm's standard text doesn't itself mandate attribution). Alternative: CC-BY-NC 4.0 (attribution built in, but written for creative works generally, vaguer on patents/sublicensing/source forms). Needs a read of the actual PolyForm text before committing -- currently only the intent ("free academic/personal use with attribution; commercial use requires permission") is settled, not the license file itself.
- [ ] **BL-017** — Write `CONTRIBUTING.md` (process: how Matthew adds/changes something, pointing back to `GOVERNANCE.md` rather than repeating it -- lightweight, since real outside collaboration isn't expected). Split off from BL-008 once `GOVERNANCE.md` itself was written and approved.

## Questions

(none yet)

## Done

- [x] **BL-002** — `/vsto/` created, split by host app (`excel/`, `access/`, `outlook/`) (2026-09-23)
- [x] **BL-004** — Header/comment template developed: `templates/header.R`, `header.py`, `header.sql`, `header.bas`, `header.vb`, `header.cs`, `header.html` (2026-09-23)
- [x] **BL-005** — Per-object README template developed: `templates/readme-code-object.md` (plus `templates/readme-folder.md` for folder-level READMEs) (2026-09-23)
- [x] **BL-006** — `AI-DISCLOSURE.md` written and approved (2026-09-23)
- [x] **BL-007** — `TAGS.md` written and approved as its own file, separate from `GOVERNANCE.md` (2026-09-23)
- [x] **BL-008** — `GOVERNANCE.md` written and approved: rules, header/tag/status/level schema, naming conventions, folder-structure diagram, AI-assistance disclosure requirement, quality bar, versioning mechanism. (`CONTRIBUTING.md` split out separately as BL-017, still open.) (2026-09-23)
- [x] **BL-013** — Versioning mechanism decided and documented in `GOVERNANCE.md` §5: `MAJOR.MINOR` header field, `_v2`-style folder suffix for breaking changes, original marked `superseded` with a README link to the replacement (2026-09-23)
- [x] **BL-014** — Finalized the Claude Project description (folded in that Matthew preps the initial programming; Claude documents/reviews/cleans up). Pasted into the Project's description field and backed up at `claude/project-description.md` in the project's knowledge base (2026-09-23)
- [x] **BL-015** — Resolved a case mismatch: `GOVERNANCE.md`'s folder diagram originally used capitalized top-level/host-app folders (`R/`, `VBA/`, `VSTO/Excel/`, etc.) while the actual folders on disk were lowercase. Fixed by editing `GOVERNANCE.md` to lowercase throughout, matching what's on disk and the lowercase-first naming conventions already in §3 (2026-09-23)
- [x] **BL-016** — Created `/vba/` split by host app (`excel/`, `access/`, `outlook/`) for true VBA modules, distinct from `/vsto/`. No content moved into it yet -- no VBA (as opposed to VSTO) code currently exists elsewhere in the repo to move (2026-09-23)
- [x] **BL-018** — `SPEC.md` initialized: documents the Claude Project's own configuration (description, custom instructions), the governance-file map, the folder structure, and a decision log (2026-09-23)
- [x] **BL-019** — Confirmed: the folder-per-code-object layout in `GOVERNANCE.md` §2 stays as-is. Rationale (now documented in `GOVERNANCE.md` §2 and `SPEC.md`'s decision log): it's what lets a snippet escalate cleanly to `/staging/` or its own repo without a mid-life restructure, matching what already happened with `bayesToolkit` and `excel-formatting` (2026-09-23)
