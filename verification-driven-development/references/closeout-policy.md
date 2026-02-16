# Closeout Policy

Use this policy for every terminal response.

## Default Artifacts

- Required markdown report artifact: `.agent/runs/<timestamp>/verification-report.md`.
- Verification Brief is required in final chat response and is chat-only.
- Do not generate `verification-brief.md` by default.
- PDF generation is optional and only performed when explicitly requested.

## Closeout Flow

1. Generate report markdown from `references/report-template.md`.
2. Resolve and run the validator in this order:
   - `<active-repo>/scripts/validate-vdd-report.sh <report_md>`.
   - `<skill-root>/scripts/validate-vdd-report.sh <report_md>` (`<skill-root>` is the directory containing `SKILL.md`).
3. If validation fails, fix report and rerun validation.
4. Render full Verification Certificate block inline in chat.

## Missing Validator Handling

- If neither validator location exists, terminal state is `BLOCKED ⛔`.
- Report the missing setup explicitly; do not claim fallback validation.

## Skill Failover Handling

Use this only when VDD tooling itself fails (validator/render script crash, missing required skill file, internal workflow exception):

1. Set terminal state to `BLOCKED ⛔`.
2. Include error summary, failed command, exit code, and stack trace (` ```text ` block).
3. Generate a prefilled GitHub issue link plus copy/paste issue body using:
   - `<active-repo>/scripts/render-vdd-failover-issue.sh ...`
   - else `<skill-root>/scripts/render-vdd-failover-issue.sh ...`
4. If no renderer exists, provide `https://github.com/jostelzer/verification_driven_development/issues/new` and include the same fields for manual paste.

## Structure Rules

- Do not use free-form report structure.
- Keep artifact paths explicit and stable.
- Include command ownership summary and known limits.
