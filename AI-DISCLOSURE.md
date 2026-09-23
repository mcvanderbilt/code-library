# AI-DISCLOSURE.md — Use of AI Tools

> **Status: APPROVED — 2026-09-23.**

## Summary

Some code and documentation in this repository was developed or supported with AI tools. Every code object states its level of AI involvement in the **AI-Assisted** header field, and every README links here. The author, Matthew Vanderbilt, is responsible for all content regardless of how it was produced.

## Tools that may be used

| Tool | Typical use |
|---|---|
| Claude (Anthropic) | Documentation, review, cleanup, refactoring suggestions, governance consistency |
| GitHub Copilot (Microsoft/GitHub) | In-editor completions and suggestions |
| Gemini (Google) | Review and explanation |
| Perplexity | Research and reference lookup |

Other tools may be added; the list is updated when they are.

## What the AI-Assisted field means

Allowed values are defined in [TAGS.md](TAGS.md). When more than one applies, the highest level is recorded, optionally with the tool in parentheses, e.g., `documentation (Claude)`.

| Value | Meaning |
|---|---|
| `none` | No AI involvement. |
| `review` | AI reviewed code or suggested fixes; the author wrote the code. |
| `documentation` | AI drafted comments, headers, or READMEs. |
| `refactor` | AI proposed restructuring that the author reviewed and accepted. |
| `generated` | AI originated substantial code at the author's explicit request. |

## Standards applied to AI-assisted work

- **Author-originated by default.** Code is written by the author first; AI is used to document, review, and improve it. `generated` code is the exception, not the norm.
- **Human review is required.** Nothing is committed without the author reading, understanding, and testing it. AI output meets the same quality bar as everything else in [GOVERNANCE.md](GOVERNANCE.md).
- **No sensitive data goes to AI tools.** No PHI, PII, credentials, proprietary data, or institution-specific details are shared with AI tools while developing this code.
- **Accuracy is the author's responsibility.** AI tools can produce plausible but incorrect code or explanations. Report problems via GitHub Issues.

## For students and educators

AI involvement is disclosed so learners can see how these tools fit into professional practice. When using this code in coursework, follow your institution's and instructor's AI policies; this disclosure does not override them.

## Licensing

AI involvement does not change the terms in [LICENSE](LICENSE): free academic or personal use with attribution; commercial or corporate use requires permission.
