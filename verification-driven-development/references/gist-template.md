# Gist Template (Chat Output)

Use this exact structure in chat.
Keep it short, concrete, and convincing.

```markdown
## Gist

Claim: <one sentence, outcome + impact>

Evidence:
- <strongest quantitative or concrete signal>
- <strongest behavioral signal>
![evidence-1](/absolute/path/to/evidence-1.png)
Graphic unavailable: <reason>  # use this line only if no graphic exists

How Human Can Run This:
```bash
<copy/paste command 1>
<copy/paste command 2>
```
Pass signal: <exact expected text/status/artifact>
Fail signal: <exact expected text/status/artifact>
```

Rules:
- Claim max 18 words.
- Evidence max 2 bullets.
- At least 1 graphic when available.
- If no graphic is feasible, include exactly one `Graphic unavailable:` line.
- `How Human Can Run This` must use real operator entrypoints (no ad-hoc harness scripts).
- Forbidden command patterns: `.agent/runs/...`, `/tmp/...`, `playwright_*.js`, `*_check.js`, `*.spec.js`.
