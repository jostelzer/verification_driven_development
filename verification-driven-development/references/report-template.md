# Verification Report Template

Use this template for all terminal states: `VERIFIED`, `READY FOR HUMAN VERIFICATION`, and `BLOCKED`.
This structure is the source of truth for:
- the full report markdown
- the Verification Brief rendered in chat
- cross-checking the report against the verification manifest

## Verification Outcome (Required)

Include exactly one status badge line at the top of the report:
- `Status Badge: 🟩 VERIFIED ✅`
- `Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬`
- `Status Badge: 🟥 BLOCKED ⛔`

## Verification Snapshot (Required)

Use compact badge-style lines near the top so the verdict is easy to scan:
- `- Status Chip: 🟩 VERIFIED ✅ | 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬 | 🟥 BLOCKED ⛔`
- `- Tier Chip: 🥇 Gold | 🥈 Silver | 🥉 Bronze`
- `- Ground-Truth Rung: R1 | R2 | R3 | R4 | R5`
- `- Cleanup Chip: 🧹 COMPLETE | 🧹 INCOMPLETE`
- `- Human Step Chip: 🤖 none | 🧑‍🔬 required`

## Verification Profile (Required)

- Profile: `api-service|ui-browser|data-pipeline|ml-model|deploy-infra|library-refactor|remote-ssh`
- Why this profile: `<one sentence>`

## Closeout Artifacts (Required)

- Report Markdown: `REPORT_PATH_PLACEHOLDER`
- Verification Manifest: `MANIFEST_PATH_PLACEHOLDER`
- Evidence Root: `RUN_DIR_PLACEHOLDER`

Verification Brief delivery:
- Render directly in chat using the standardized Verification Brief structure.
- Do not generate a default `verification-brief.md` artifact.

## Verification Brief Claim (Required)

Write one sentence with outcome and impact.

## Verification Brief Evidence (Required)

Provide 1 to 3 concise evidence bullets with concrete signals.
Include at least one graphic when available.
If no graphic is available, add `Graphic unavailable: <reason>`.

## Goal

State the user request and acceptance criteria in one concise paragraph.

## Acceptance Criteria

List explicit acceptance criteria as short bullets.

## What Changed

List 3 to 8 concrete implementation changes.

## Runtime

- Execution context: `local` | `docker` | `ssh`
- Host or container identifiers when relevant.
- Versions that materially affect behavior.

## Ground-Truth Plan and Data

- Target evidence tier: Gold | Silver | Bronze, with one-line rationale.
- Achieved evidence tier: Gold | Silver | Bronze, with one-line rationale.
- Gold runtime estimate: `<minutes>`.
- Gold decision gate: `<=10m (auto-Gold)` | `>10m (user choice required)`.
- User tier choice when Gold >10m: `Bronze | Silver | Gold + short reason` or `n/a`.
- Source: `<ground-truth source>`.
- Acquisition: `<how it was obtained>`.
- Sample size and selection: `<what was sampled and why>`.
- Metrics and thresholds: `<exact thresholds>`.
- Data/artifact location: `<path(s)>`.
- Waiver (if any): `<none or explicit waiver>`.
- Discrimination: `H1=<claim>; H0=<confounder>; decision rule=<threshold>`.
- Controls (when applicable): `<baseline/noise floor>`.

## Commands Run

Provide copy/paste command list in execution order.

```bash
<command 1>
<command 2>
```

## Results by Criterion

Map each acceptance criterion to evidence:
- Criterion: `<criterion text>`
- Result: PASS | FAIL | INCONCLUSIVE
- Evidence: `<artifact path, metric, excerpt, or log line>`

## Standard Certificate (Required)

Paste the full Verification Certificate block here, verbatim, using the certificate template.
The certificate heading should be `## 🏅 Verification Certificate`.

## Verification Brief How YOU Can Run This (Required)

Place this section below the verification certificate.

Provide copy/paste steps and explicit pass/fail signals:
1. Use real operator entrypoints.
2. Do not reference ad-hoc probe scripts created during the run.

```bash
<command 1>
<command 2>
```

Pass signal: `<exact text/status/artifact>`
Fail signal: `<exact text/status/artifact>`

## Evidence and Inspection

Provide the strongest verification signals with short excerpts:
- Signal 1: expected behavior observed.
- Signal 2: correlation signal.
- Signal 3: control, counterexample, or negative evidence.

Scientific interpretation:
- Why these signals discriminate `H1` from `H0`.
- If signals are noisy: show effect size versus baseline or noise floor.
- Threats to validity: 1 to 3 bullets.

## Artifact Index

Prefer a compact markdown table:

| Path | Kind | Proves |
| --- | --- | --- |
| `<artifact path>` | `<image|chart|screenshot|trace|log|table|dataset|other>` | `<one line>` |

For `image`, `chart`, or `screenshot` rows, use an absolute filesystem path so the same file can be embedded inline below.

## Inline Visual Evidence

If the Artifact Index includes any `image`, `chart`, or `screenshot` rows, embed each one here inline with the same absolute filesystem path used in the Artifact Index:

```markdown
![alt text](/absolute/path/to/visual.png)
```

If no pictures or graphs were produced, write:

`No inline visuals were produced.`

## Command Ownership

- Agent-ran commands summary: `<what the agent executed>`
- Agent-side failures: `<what failed and how it was handled>`
- Why any human step was unavoidable: `<none|reason>`

## Timing

- Estimated per-step + total: `<estimate>`
- Actual per-step + total: `<actual>`
- Tier gate outcome: `<mandatory Gold or user-selected tier>`
- Note if actual total exceeded estimate and why: `<short note>`

## Cleanup

- Resources started by verification: `<list or none>`
- Teardown commands run: `<exact commands or none>`
- Post-cleanup check: `<exact command and observed signal>`
- Cleanup status: COMPLETE | INCOMPLETE

## Known Limits

State what was not verified and why.

## Final State

Final State: `VERIFIED ✅|READY FOR HUMAN VERIFICATION 🧑‍🔬|BLOCKED ⛔`
