# Human Verification Card Template

Use this for `READY FOR HUMAN VERIFICATION 🧑‍🔬`.
Keep the card compact and operator-facing.

```markdown
## Human Verification Card

Preconditions:
- <short prerequisite 1>
- <short prerequisite 2>

Steps:
1. <copy/paste command or click path>
2. <copy/paste command or click path>

Pass signal(s): <exact text/status/artifact expected>
Fail signal(s): <exact text/status/artifact expected>
Return condition: <what to send back, and when to stop>

Operator Notes:
- <optional note>
```

Rules:
- The card order is fixed.
- `Operator Notes` are optional and should only appear when they reduce operator confusion.
- Use real operator entrypoints, not temporary probes under `.agent/runs/` or `/tmp/`.
