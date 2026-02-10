# Verification Report Template

Use this template for `VERIFIED` and `READY FOR HUMAN VERIFICATION`.

## Verification Outcome (Required)

Include exactly one status badge line at the top of the report:
- `Status Badge: 🟩 VERIFIED ✅`
- `Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬`
- `Status Badge: 🟥 BLOCKED ⛔`

## Goal

State the user request and acceptance criteria in one concise paragraph.

## What Changed

List 3 to 8 concrete implementation changes.

## Runtime

State runtime surface and key versions:
- Execution context: `local` / `docker` / `ssh`.
- Host/container identifiers when relevant.
- Language/runtime/tool versions that materially affect behavior.

## Ground-Truth Plan and Data

Specify how verification approximated ground truth:
- Source: user-provided | reference implementation | golden outputs | public dataset | synthetic baseline (with rationale). Any credible source is acceptable; prefer high-quality datasets when available.
- Acquisition: how data or baseline was obtained (include commands if applicable).
- Sample size and selection: default to a small, representative sample unless a thorough run is explicitly requested.
- Metrics and thresholds: include exact thresholds and whether they were met.
- Data/artifact location: paths to datasets, outputs, and evaluation summaries.
- Waiver (if any): explicit user waiver and the reduced evidence tier.

## Commands Run

Provide copy/paste command list in execution order.

```bash
# example
<command 1>
<command 2>
```

## Standard Certificate (Required)

Paste the full Verification Certificate block here, verbatim, using the certificate template. Do not summarize or paraphrase it.

## Evidence and Inspection

Provide strongest verification signals with short excerpts:
- Signal 1: expected behavior observed.
- Signal 2: correlation signal (for example, request payload to log line).
- Signal 3: negative evidence (absence of errors/timeouts/regressions where applicable).

Prefer "show, don't tell" artifacts over prose-only claims:
- Include at least one artifact per acceptance criterion when feasible (image, chart, audio clip, structured table, metric dump).
- For each artifact, provide path/link and one line on what it proves.
- If artifacts are not feasible, provide compact structured data (key-value table) rather than a plain statement.
- Include ground-truth comparison outputs (tables, charts, or metric summaries) when available.

## Timing

Provide estimates from the plan and actual runtime:
- Estimated per-step + total.
- Actual per-step + total.
- Note if total exceeded 10 minutes and why.

## Known Limits

State what was not verified and why.

## Final State

Set one:
- `VERIFIED ✅`
- `READY FOR HUMAN VERIFICATION 🧑‍🔬`
