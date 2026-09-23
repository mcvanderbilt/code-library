# README Templates

> **Status: PROPOSED — pending approval.** Two templates: (A) code object, (B) language/topic folder. Copy the block, delete the guidance comments.

---

## A. Code-object README

````markdown
# <object_name>

<One-sentence summary — matches the header's Purpose.>

| Field | Value |
|---|---|
| Language | R / Python / SQL / VBA / VSTO / HTML |
| Status | `stable` |
| Level | `beginner` |
| Tags | `data-cleaning`, `utility` |
| AI-Assisted | `documentation (Claude)` — see [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) |
| Dependencies | None |
| Version | v1 |

## When to use it
<The problem it solves and when NOT to use it.>

## Usage
```r
result <- object_name(x, option = TRUE)
```

## Arguments / Parameters
| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `x` | data.frame | Yes | — | Input data. |

## Returns
<Type, shape, and meaning of the output. Note any side effects.>

## Example
```r
# Runnable with synthetic or built-in data only
object_name(mtcars)
```

## Error handling
<Which inputs are validated, what errors/warnings are raised, and what the caller should expect on failure.>

## How it works
<Short walkthrough of the approach for learners — key steps and why they were chosen.>

## Adapting it
<What to change to fit a different context: parameters, assumptions, known limitations.>

## Version history
| Date | Version | Change |
|---|---|---|
| YYYY-MM-DD | v1 | Initial version |

## License
Free for academic or personal use with attribution. Commercial/corporate use requires permission. See [LICENSE](../../../LICENSE).
````

---

## B. Language or topic folder README

````markdown
# <Language or Topic>

<Two or three sentences: what lives here and how it's organized.>

## Contents
| Object | Purpose | Status | Level |
|---|---|---|---|
| [object_name](object_name/) | One-line purpose | `stable` | `beginner` |

## Conventions for this folder
<Language-specific notes beyond GOVERNANCE.md: required runtime versions, style guide, how to import/load the code (e.g., importing .bas modules into the VBA editor).>

## See also
- [GOVERNANCE.md](../GOVERNANCE.md) · [TAGS.md](../TAGS.md) · [AI-DISCLOSURE.md](../AI-DISCLOSURE.md)
````
