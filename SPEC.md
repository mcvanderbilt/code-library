# SPEC.md — Code Library System Specification

> Initialized 2026-09-23. This file documents how the Code Library *system* fits
> together: the Claude Project this repo is developed alongside, how the
> governance files relate to each other, the standing workflows, and a dated
> decision log. It is the "how the pieces connect" document; the pieces
> themselves (rules, vocabulary, disclosure, process) live in their own files
> and are not duplicated here.

---

## 1. What this repo is

A home for small, standalone code snippets and functions (R, Python, SQL,
VBA, VSTO, HTML, and others as added) — not full repos, packages, or
libraries. Matthew writes the initial code; Claude's role is documentation,
review, cleanup, and governance consistency. Full scope and rationale: see
`GOVERNANCE.md` §1 and `claude/project-description.md` (below).

## 2. The Claude Project this repo is developed alongside

This repo (`D:\GitHub\code-library`, synced to
https://github.com/mcvanderbilt/code-library) is the primary working copy.
Development happens in a **claude.ai Project called "Code Library"**, linked
to this local folder via the Claude desktop app. That Project carries two
pieces of configuration that live in claude.ai itself (not as files in this
repo), each with a backup copy stored in the Project's own knowledge base so
the text is recoverable without re-deriving it:

| Claude Project field | Backup copy (in the Project's knowledge base) |
|---|---|
| Description (what the project is) | `claude/project-description.md` |
| Custom instructions (how Claude should behave here) | `claude/custom-instructions.md` |

If either field is changed in claude.ai, the matching backup file should be
updated to match in the same session (per the note at the top of each backup
file). These two files are *not* part of this git repo — they live in the
Claude Project's knowledge base, addressed separately from `D:\GitHub\code-library`.

Custom-instruction highlights worth restating here since they shape every
session's behavior in this repo:
- Claude documents/reviews/cleans up; Matthew originates the code.
- Claude proposes structural or governance changes and waits for confirmation
  rather than executing them unilaterally.
- Anything deferred goes into `BACKLOG.md` as a new `BL-NNN` item rather than
  getting lost in chat.
- This project is code only — no PKM/notes/meeting-tracking content.

## 3. Governance file map

| File | Purpose | Status (as of 2026-09-23) |
|---|---|---|
| `README.md` | Repo overview and navigation | existing |
| `GOVERNANCE.md` | Rules: folder structure, naming, headers, versioning, quality bar | **Approved** |
| `CONTRIBUTING.md` | Process for adding/changing something | **Not yet written** (BL-017) |
| `TAGS.md` | Controlled vocabulary for Status/Level/AI-Assisted/Tags | **Approved** |
| `AI-DISCLOSURE.md` | AI tool usage statement, referenced by every README | **Approved** |
| `LICENSE` | Licensing terms | Intent settled (free academic/personal + attribution; commercial needs permission); **exact license text not yet finalized** (BL-012) |
| `BACKLOG.md` | Tracked enhancements/questions, `BL-NNN` format | living document |
| `SPEC.md` | This file | living document |
| `templates/` | Header templates (`header.R`, `.py`, `.sql`, `.bas`, `.vb`, `.cs`, `.html`) and README templates (`readme-code-object.md`, `readme-folder.md`) | in place |

Every README in the repo (folder-level and per-code-object) should reference
`LICENSE`, `AI-DISCLOSURE.md`, and (once written) `CONTRIBUTING.md`, per
`GOVERNANCE.md` §7's "definition of done."

## 4. Folder structure (authoritative diagram lives in `GOVERNANCE.md` §2)

Top-level: `r/`, `python/`, `sql/`, `vba/`, `vsto/`, `html/` (all lowercase),
plus `staging/`, `archive/` (gitignored), `learning/` (gitignored),
`research/` (with `research/local/` gitignored), and `templates/`. Full
diagram, placement rules, and naming conventions: `GOVERNANCE.md` §2–3.

## 5. Standing workflows

**Adding a new code object**
1. Confirm where it belongs per `GOVERNANCE.md` §2's placement-rules table
   (language folder vs. `/staging/` vs. `/learning/`).
2. Copy the language's header template from `templates/` and fill every
   field — use `TAGS.md` values for Tags/Status/Level/AI-Assisted.
3. Create the code object's own folder (per `GOVERNANCE.md` §2) and add a
   README from `templates/readme-code-object.md`.
4. Confirm it meets `GOVERNANCE.md` §7's definition of done before
   considering it finished, and add it to the parent folder's README.

**Making a breaking change to a `stable` snippet**
Follow `GOVERNANCE.md` §5: new version in a `_v2`-suffixed folder, bump the
`Version` header field, mark the original `superseded`, link forward from
the original's README.

**Deferring something**
Add a new `BL-NNN` item to `BACKLOG.md` under the right section (Bugs /
Enhancements / Questions) rather than leaving it only in chat history.

**Changing governance itself**
Per `GOVERNANCE.md` §9 and the custom instructions above: propose the change,
get confirmation, then edit. `SPEC.md` §7 (below) gets a dated entry for any
governance-level decision.

## 6. Known gaps (see `BACKLOG.md` for full detail, not duplicated here)

- `CONTRIBUTING.md` doesn't exist yet (BL-017).
- Final `LICENSE` text not yet chosen (BL-012).
- Old duplicate folders (`r/bayesToolkit/`, `vba-excel/`) still need manual
  deletion by Matthew — no delete access from this session (BL-009).
- Whether every code object truly needs its own subfolder (vs. a flatter
  file+README layout) is still open for confirmation (BL-019).

## 7. Decision log

| Date | Decision |
|---|---|
| 2026-09-22 | Repo purpose scoped: small snippets/functions only, not full packages; `/staging/` and `/archive/` folders defined for projects on their way out or of uncertain value |
| 2026-09-22 | VSTO (C#/VB.NET, compiled add-ins) separated from VBA (true `.bas`/`.cls`/`.frm` modules) — different toolchains, different folders |
| 2026-09-23 | SQL organized by task (`tables/`, `views/`, `stored-procedures/`, `functions/`, `queries/`, `triggers/`, `indexes/`), not by dialect |
| 2026-09-23 | `/learning/` and `/research/local/` added as gitignored folders for in-progress/private material; `/research/` (synced) added for shareable reference material |
| 2026-09-23 | `TAGS.md` kept as its own file, separate from `GOVERNANCE.md`, since it changes more often |
| 2026-09-23 | AI-Assisted disclosure implemented as both a per-file header field (travels with the code when copied elsewhere) and a repo-level `AI-DISCLOSURE.md` policy statement — not one or the other |
| 2026-09-23 | Per-object README approach: one README co-located with each code object, in its own folder |
| 2026-09-23 | Versioning mechanism: `MAJOR.MINOR` header field + `_v2` folder-suffix convention for breaking changes |
| 2026-09-23 | License direction: PolyForm Noncommercial 1.0.0 + a supplementary attribution clause is the leading candidate over CC-BY-NC 4.0; exact text still pending (BL-012) |
| 2026-09-23 | `/vsto/` and `/vba/` both created, each split by host app (`excel/`, `access/`, `outlook/`) |
| 2026-09-23 | Folder-naming case resolved to lowercase throughout (`GOVERNANCE.md` originally specified capitalized top-level folders; corrected to match what was actually built and the lowercase-first naming conventions already in place) |
| 2026-09-23 | `GOVERNANCE.md`, `TAGS.md`, `AI-DISCLOSURE.md` moved from "proposed" to "approved" |
