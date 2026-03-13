# Closeout UX Guide

Use this guide to make the final closeout fast to scan without turning it into decoration-first fluff.

## Compact First

Lead with the verdict and the minimum evidence needed to trust it.
If a compact snapshot helps, use one. It is optional.
- `Status Chip: 🟩 VERIFIED ✅ | 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬 | 🟥 BLOCKED ⛔`
- `Tier Chip: 🥇 Gold | 🥈 Silver | 🥉 Bronze`
- `Ground-Truth Rung: R1 | R2 | R3 | R4 | R5`
- `Cleanup Chip: 🧹 COMPLETE | 🧹 INCOMPLETE`
- `Human Step Chip: 🤖 none | 🧑‍🔬 required`

Rules:
- Keep it short and badge-like.
- Any snapshot must agree with the manifest and the detailed sections below.
- Use the human-step badge only for whether a remaining human verification step exists, not as a generic blocker signal.

## Certificate

- Use a state-specific heading:
  - `## ✅ Verified Report`
  - `## 🧑‍🔬 Human Check Report`
  - `## 🚫 Blocked Report`
- Keep VERIFIED certificates terse.
- Put `How YOU Can Run This` close to the certificate in the final chat response.

## Artifact Index

Prefer a compact markdown table:

| Path | Kind | Proves |
| --- | --- | --- |
| `/abs/path/to/artifact` | `log` | `One-line proof statement` |

Rules:
- Only include load-bearing artifacts.
- The `Proves` column should name the actual claim the artifact supports.
- Avoid dumping every generated file into the table.
- Use absolute filesystem paths for `image`, `chart`, and `screenshot` rows so the report can render them inline directly.
- If there are no standalone artifacts, say so explicitly instead of inventing filler rows.

## Inline Visual Evidence

- If the artifact table includes any `image`, `chart`, or `screenshot` rows, show each of those visuals inline in the report with the same absolute filesystem path used in the table.
- Do not make the reader jump to a path when the report can render the picture directly.
- If no pictures or graphs were produced, say so explicitly with `No inline visuals were produced.`
