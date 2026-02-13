# Closeout Policy

Use this policy for every terminal response.

## Default Artifacts

- Required markdown report artifact: `.agent/runs/<timestamp>/verification-report.md`.
- Verification Brief is required in final chat response and is chat-only.
- Do not generate `verification-brief.md` by default.
- PDF generation is optional and only performed when explicitly requested.

## Closeout Flow

1. Generate report markdown from `references/report-template.md`.
2. Validate with `scripts/validate-vdd-report.sh <report_md>`.
3. If validation fails, fix report and rerun validation.
4. Render full Verification Certificate block inline in chat.

## Missing Validator Handling

- If `scripts/validate-vdd-report.sh` is missing, terminal state is `BLOCKED ⛔`.
- Report the missing setup explicitly; do not claim fallback validation.

## Structure Rules

- Do not use free-form report structure.
- Keep artifact paths explicit and stable.
- Include command ownership summary and known limits.
