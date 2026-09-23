# TAGS.md — Controlled Vocabulary

> **Status: APPROVED — 2026-09-23.** Values below are a starting set. Add new values only through a change to this file (see "Changing the vocabulary").

This file defines the only permitted values for the **Status**, **Level**, **AI-Assisted**, and **Tags** header fields. Rules for *where* those fields appear live in `GOVERNANCE.md`; this file only defines *what values are allowed*, because it changes more often.

---

## Status (exactly one)

| Value | Meaning |
|---|---|
| `draft` | Written but not yet reviewed or tested against real inputs. Not safe to depend on. |
| `review` | Under review/cleanup; interface may still change. |
| `stable` | Tested, documented, safe to depend on. Breaking changes require a new version. |
| `deprecated` | Still works but should not be used for new work; README names the replacement. |
| `superseded` | Replaced by a newer version in-place alongside it; retained so dependents aren't broken. |

Code whose Status would be anything other than these belongs in `/learning/` or `/archive/`, not a language folder.

## Level (exactly one)

Describes the reader, not the code's sophistication alone.

| Value | Reader can follow it if they know… |
|---|---|
| `beginner` | Basic syntax, variables, simple functions. Comments explain *every* non-obvious step. |
| `intermediate` | Control flow, data structures, common packages/libraries. Comments explain design choices. |
| `advanced` | Performance, APIs, error-handling patterns, internals. Comments explain *why*, not *what*. |

## AI-Assisted (exactly one)

Details and tool list live in `AI-DISCLOSURE.md`.

| Value | Meaning |
|---|---|
| `none` | No AI involvement. |
| `review` | AI reviewed or suggested fixes; author wrote the code. |
| `documentation` | AI drafted comments, header, or README only. |
| `refactor` | AI proposed restructuring the author accepted. |
| `generated` | AI originated substantial code (explicitly requested; reviewed by author). |

If more than one applies, use the highest in the list (e.g., `review` + `documentation` → `documentation`). Optionally name the tool in parentheses: `documentation (Claude)`.

## Tags (2–5 per code object)

Format: lowercase, hyphen-separated, singular where sensible. **Do not tag the language or the host app** — the folder path already says that.

### Task (what it does) — at least one required
`data-import` · `data-export` · `data-cleaning` · `data-validation` · `transformation` · `aggregation` · `reshaping` · `joining` · `string-manipulation` · `date-time` · `file-io` · `reporting` · `visualization` · `statistics` · `modeling` · `automation` · `formatting` · `logging` · `error-handling` · `utility`

### Domain (where it's used) — optional
`business-intelligence` · `finance` · `healthcare-ops` · `higher-ed` · `survey` · `teaching`

### Technique (how it works) — optional
`performance` · `vectorized` · `recursion` · `regex` · `api` · `parameterized` · `dynamic-sql` · `window-functions` · `functional`

---

## Changing the vocabulary

1. Propose the new value (and which facet it belongs to) — flag it rather than using it ad hoc.
2. Add it here with a one-line meaning if not self-evident.
3. Note the change in the commit message: `TAGS: add <value>`.
4. Renaming or removing a value requires updating every file that uses it in the same commit.
