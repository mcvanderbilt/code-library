# GOVERNANCE.md — Code Library Rules

> **Status: APPROVED — 2026-09-23.**

This file is the authority for repo structure, naming, headers, versioning, and quality. Allowed field *values* live in `TAGS.md`. Process for making changes lives in `CONTRIBUTING.md`. AI usage is described in `AI-DISCLOSURE.md`.

---

## 1. Scope

This repo holds **small, standalone snippets and functions** for reference, duplication, and adaptation. Full applications, packages, or multi-file projects go in `/staging/` until they graduate to their own repo. Personal notes and knowledge management do not belong here.

## 2. Folder structure

```
code-library/
├── README.md               Repo overview and navigation
├── GOVERNANCE.md           This file
├── CONTRIBUTING.md         Process for adding/changing code
├── TAGS.md                 Controlled vocabulary
├── AI-DISCLOSURE.md        AI tool usage statement
├── SPEC.md                 System-level spec (this Project's own config, workflows, decision log)
├── LICENSE
├── BACKLOG.md              Enhancements and open questions (BL-NNN)
├── .gitignore
│
├── templates/              Header and README templates to copy
│
├── r/
│   └── <topic>/            e.g., data-cleaning/, reporting/, statistics/
├── python/
│   └── <topic>/
├── sql/
│   ├── tables/  views/  stored-procedures/  functions/
│   └── queries/  triggers/  indexes/
├── vba/
│   └── excel/  access/  outlook/
├── vsto/
│   └── excel/  access/  outlook/
├── html/
│   └── <topic>/
│
├── staging/                Larger projects headed for their own repo   (synced)
├── research/               Reference material for this repo's code     (synced)
│   └── local/              Reference material that must not sync       (ignored)
├── learning/               In-progress learning material, mirrors langs (ignored)
└── archive/                Deprecated / uncertain-value code            (ignored)
```

All top-level and subfolder names are **lowercase** (matches the file-naming conventions in §3 — kebab-case for topic folders, no capitalized directories anywhere in the repo).

Every language folder and every topic subfolder has a `README.md`. Each code object lives in **its own folder** with its README:

```
r/data-cleaning/clean_column_names/
├── clean_column_names.R
└── README.md
```

This is deliberate, not incidental: a code object's own folder is what lets it **escalate cleanly** if it ever outgrows "small snippet" status. `bayesToolkit` and `excel-formatting` both had to be carved out into `/staging/` and eventually their own repos after the fact — the object-per-folder pattern means any future object can grow (add a test file, a sample dataset, a `_v2` sibling) without a mid-life restructure, and a graduation to its own repo is a folder move, not a file hunt across a shared topic folder.

### Placement rules

| Code is… | Goes in |
|---|---|
| Finished, reviewed, professional-grade | Language folder |
| A multi-file project needing its own repo eventually | `/staging/<project-name>/` |
| In progress, experimental, or a learning exercise | `/learning/<language>/` |
| Deprecated with no dependents, or of uncertain value | `/archive/` |
| Deprecated but still depended on | Stays in place, Status `deprecated` or `superseded` |

New top-level or language-level folders require approval (see `CONTRIBUTING.md`).

## 3. Naming conventions

| Language | Folders & files | Objects in code |
|---|---|---|
| R | `snake_case.R` | functions & variables `snake_case` (tidyverse style guide) |
| Python | `snake_case.py` | functions/variables `snake_case`, classes `PascalCase`, constants `UPPER_SNAKE` (PEP 8) |
| SQL | `schema.object_name.sql` | objects `snake_case` with type prefix: `vw_`, `usp_`, `fn_`, `tr_`, `ix_`; tables unprefixed; keywords UPPERCASE |
| VBA | `modModuleName.bas`, `clsClassName.cls`, `frmFormName.frm` | procedures `PascalCase`, variables `camelCase`, constants `UPPER_SNAKE` |
| VSTO (C#/VB.NET) | `PascalCase.cs` / `.vb` | .NET conventions: `PascalCase` public members, `_camelCase` private fields |
| HTML/CSS/JS | `kebab-case.html` | CSS classes `kebab-case`, JS `camelCase` |

Topic folders use `kebab-case` across all languages. Code-object folders match the primary file's name without extension. Top-level and language folders themselves are always lowercase (`r/`, `vba/`, `vsto/`, etc.) even though file contents inside them follow the case conventions above (e.g., a `.cs` file inside `vsto/excel/` still uses `PascalCase.cs`).

## 4. Standard header

Every code file begins with this header, in the language's comment syntax. All fields are required; use `None` rather than omitting a field.

| Field | Content |
|---|---|
| Purpose | One or two sentences: what it does and when to use it. |
| Author | Name (and GitHub handle). |
| Created | `YYYY-MM-DD` |
| Modified | `YYYY-MM-DD — short description` (most recent first; full history in README) |
| Version | `MAJOR.MINOR` — see §5 |
| Tags | 2–5 values from `TAGS.md`, comma-separated |
| Status | One value from `TAGS.md` |
| Level | One value from `TAGS.md` |
| AI-Assisted | One value from `TAGS.md` |
| Dependencies | Packages/libraries with minimum versions, other snippets by path, or `None` |
| License | `See LICENSE — free for academic/personal use with attribution` |

Copy the header for your language from [`/templates/`](templates/): `header.R`, `header.py`, `header.sql`, `header.bas`, `header.vb`, `header.cs`, `header.html`. Placement rules:

- **Python:** the header is the module docstring, so `help()` shows it.
- **SQL:** directly above `CREATE`/`ALTER`, so it is stored with the object definition.
- **VBA:** after the `Attribute VB_Name` line the editor writes on export, before `Option Explicit`.
- **VSTO:** comment block first, then an XML `<summary>` repeating Purpose for IntelliSense.
- **HTML:** immediately after `<!DOCTYPE html>`.

## 5. Versioning

- **Version** is `MAJOR.MINOR`, starting at `1.0`. MINOR increments for non-breaking changes; MAJOR increments only for a breaking change and always matches the folder suffix (`_v2` → `2.0`).
- Once a snippet is `stable` and depended on, a **breaking change produces a new version** rather than editing in place.
- New versions sit beside the original with a suffix: `clean_column_names_v2/`. The original becomes `superseded` and its README links to the replacement.
- Non-breaking fixes (bugs, comments, performance with identical interface) edit in place and add a `Modified` line.
- A breaking change is anything that alters arguments, return type/shape, side effects, or required dependencies.

## 6. Quality bar

- **Professional and optimized:** vectorized where the language allows, no dead code, no hard-coded paths or credentials.
- **Teachable:** comments at the density appropriate to the `Level`.
- **Error handling is mandatory:** validate inputs, fail with informative messages, clean up resources (`on.exit()`, `try/finally`, `On Error GoTo` with cleanup label, `TRY...CATCH` with transaction handling).
- **Portable:** no institution-specific server names, schemas, file paths, or business rules. Parameterize them.
- **No sensitive data:** no PHI, PII, credentials, or real datasets. Examples use synthetic data or built-in datasets.

## 7. Definition of done

A code object is finished only when:
1. The header is complete and uses `TAGS.md` values.
2. A co-located README follows `templates/readme-code-object.md`.
3. Error handling is present and described in the README.
4. It has run successfully against at least one example in its README.
5. The parent folder README lists it.

## 8. Sync rules

`/archive/`, `/learning/`, and `/research/local/` are excluded by `.gitignore` and never pushed. Data files are ignored by default; small synthetic samples may be force-added deliberately.

## 9. Changing governance

Changes to this file, `CONTRIBUTING.md`, `TAGS.md`, `AI-DISCLOSURE.md`, or `LICENSE` are proposed, reviewed, and approved before being committed. Commit messages start with the file name, e.g., `GOVERNANCE: clarify versioning suffix`.
