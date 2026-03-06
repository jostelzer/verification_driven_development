# Closeout Policy

Use this policy for every terminal response.

## Default Artifacts

- Required manifest artifact: `.agent/runs/<timestamp>/verification-manifest.json`.
- Required markdown report artifact: `.agent/runs/<timestamp>/verification-report.md`.
- Verification Brief is required in the final chat response and is chat-only.
- PDF generation is optional and only performed when explicitly requested.

## Closeout Flow

1. Generate or update the verification manifest.
2. Validate the manifest.
3. Generate the report markdown from `references/report-template.md`.
4. Validate the report.
5. Render the Verification Brief.
6. Render the full Verification Certificate block inline in chat.
7. Keep the Verification Snapshot visually compact and the Artifact Index table easy to scan.

## Missing Validator Handling

- If neither manifest validator location exists, terminal state is `BLOCKED ⛔`.
- If neither report validator location exists, terminal state is `BLOCKED ⛔`.
- Report the missing setup explicitly; do not claim fallback validation.

## Skill Failover Handling

Use this only when VDD tooling itself fails:
- validator crash
- renderer crash
- missing required skill file
- internal workflow exception

When failover triggers:
1. Set terminal state to `BLOCKED ⛔`.
2. Include error summary, failed command, exit code, and stack trace.
3. Generate a prefilled GitHub issue link and copy/paste issue body.

## Structure Rules

- Do not use free-form report structure.
- Keep artifact paths explicit and stable.
- Use a top-of-report Verification Snapshot with status, tier, ground-truth rung, cleanup, and human-step badges.
- Prefer an Artifact Index markdown table with `Path`, `Kind`, and `Proves` columns.
- If pictures or graphs are produced, list them with absolute filesystem paths in the artifact table and embed each one inline in the report.
- Include command ownership and cleanup summaries.
- The report must not contradict the manifest.
