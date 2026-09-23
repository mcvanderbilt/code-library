# Code Library
**Matthew C. Vanderbilt, MSBA**

A home for small, standalone code snippets and functions — not full repos, packages, or libraries — for use as reference, duplication, or adaptation across other work. Spans R, Python, SQL, VBA, VSTO, HTML, and other languages as added. Full scope, rationale, and rules: see [`GOVERNANCE.md`](GOVERNANCE.md).

---

## Repository structure

```
code-library/
├── README.md               This file
├── GOVERNANCE.md            Rules: folder structure, naming, headers, versioning, quality
├── CONTRIBUTING.md          Process for adding/changing code (not yet written)
├── TAGS.md                  Controlled vocabulary for Tags/Status/Level/AI-Assisted
├── AI-DISCLOSURE.md         AI tool usage statement
├── SPEC.md                  System-level spec: Claude Project config, workflows, decision log
├── LICENSE                  Licensing terms
├── BACKLOG.md               Tracked enhancements and open questions (BL-NNN)
├── templates/                Header and README templates to copy for a new code object
│
├── r/                        R snippets, by topic
├── python/                   Python snippets, by topic
├── sql/                      SQL snippets, by task (tables/, views/, stored-procedures/,
│                              functions/, queries/, triggers/, indexes/)
├── vba/                       True VBA modules (.bas/.cls/.frm), by host app
│   └── excel/  access/  outlook/
├── vsto/                      VSTO (C#/VB.NET) add-in projects, by host app
│   └── excel/  access/  outlook/
├── html/                      Standalone HTML snippets and templates
│
├── staging/                  Larger projects headed for their own repo         (synced)
├── research/                  Reference material for this repo's code          (synced)
│   └── local/                 Reference material that must not sync            (ignored)
├── learning/                  In-progress learning material, mirrors languages (ignored)
└── archive/                   Deprecated or uncertain-value code               (ignored)
```

Every language folder and topic subfolder has its own `README.md`. Each code object lives in its own folder alongside its README — see `GOVERNANCE.md` §2 for the full layout and the reasoning behind it.

## Getting started

To add a new code object: check `GOVERNANCE.md` §2 for where it belongs, copy the matching header template from [`templates/`](templates/), fill it in using `TAGS.md`'s controlled vocabulary, and add a README from `templates/readme-code-object.md`. `GOVERNANCE.md` §7 has the full "definition of done."

## Governance

| File | Covers |
|---|---|
| [`GOVERNANCE.md`](GOVERNANCE.md) | Folder structure, naming conventions, standard header, versioning, quality bar |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Process for adding or changing something *(not yet written)* |
| [`TAGS.md`](TAGS.md) | Allowed values for Tags, Status, Level, and AI-Assisted |
| [`AI-DISCLOSURE.md`](AI-DISCLOSURE.md) | How AI tools may be involved in this repo's code and documentation |
| [`BACKLOG.md`](BACKLOG.md) | Tracked enhancements and open questions |
| [`SPEC.md`](SPEC.md) | How the pieces above fit together, plus a dated decision log |

## License

Free for academic or personal use with attribution; commercial or corporate use requires permission. See [`LICENSE`](LICENSE) for full terms.

## AI usage

Some code and documentation in this repository may be developed or supported with AI tools. See [`AI-DISCLOSURE.md`](AI-DISCLOSURE.md) for the full statement and which tools may be involved.
