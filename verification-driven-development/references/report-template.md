# Verification Report Template

Use the smallest report that still proves the claim.
The validator now checks for runnable evidence, cleanup, and manifest alignment,
not a single oversized markdown ritual.

## Required Core Sections

These sections are required:

## Verification Outcome

Include exactly one status badge line near the top:
- `Status Badge: 🟩 VERIFIED ✅`
- `Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬`
- `Status Badge: 🟥 BLOCKED ⛔`

## Closeout Artifacts

- Verification Manifest: `MANIFEST_PATH_PLACEHOLDER`
- Report Markdown: `REPORT_PATH_PLACEHOLDER`  # optional but recommended
- Evidence Root: `RUN_DIR_PLACEHOLDER`  # optional when artifacts live elsewhere

## Goal

State the task and acceptance criteria in one concise paragraph.

## Commands Run

Provide the actual commands used for verification in execution order.

```bash
<command 1>
<command 2>
```

## Results by Criterion

Use one block per acceptance criterion:

- Criterion: `<criterion text>`
- Result: PASS | FAIL | INCONCLUSIVE
- Evidence: `<artifact path, metric, log line, or observed output>`

## Evidence and Inspection

Summarize the strongest load-bearing signals and why they support the verdict.
Bullets are fine; prose is fine; keep it concrete.

## Artifact Index

Use one of:
- a compact markdown table with `Path | Kind | Proves`
- bullet lines in the form `- <path> | <kind> | <proves>`
- `No standalone artifacts.` if the decisive evidence is inline or in the manifest

For `image`, `chart`, and `screenshot` entries, use absolute filesystem paths.

## Command Ownership

State what the agent ran, what failed agent-side, and whether any human step is still required.

## Cleanup

Include:
- what verification resources were started, or `none`
- what teardown ran, or `none`
- a post-cleanup check, or an explicit note that no resources were started
- `- Cleanup status: COMPLETE` or `- Cleanup status: INCOMPLETE`

## How YOU Can Run This

Use real operator entrypoints, not ad-hoc probe scripts.

```bash
<command 1>
<command 2>
```

Pass signal: `<exact expected text/status/artifact>`
Fail signal: `<exact expected text/status/artifact>`

## Final State

Final State: `VERIFIED ✅|READY FOR HUMAN VERIFICATION 🧑‍🔬|BLOCKED ⛔`

## Optional Sections

Add these only when they help:
- `## Verification Snapshot`
- `## Ground-Truth Plan and Data`
- `## Verification Brief Claim`
- `## Verification Brief Evidence`
- `## Verification Brief How YOU Can Run This`
- `## ✅ Verified Report`
- `## 🧑‍🔬 Human Check Report`
- `## 🚫 Blocked Report`
- `## Inline Visual Evidence`
- `## Timing`
- `## Known Limits`

Use optional sections to add rigor when the task merits it, not to satisfy formatting for its own sake.
