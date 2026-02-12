# Verification Report Template

Use this template for `VERIFIED` and `READY FOR HUMAN VERIFICATION`.
This structure is the source of truth for:
- Full report (PDF).
- Gist shown in agent chat (generated from the three Gist sections).

## Verification Outcome (Required)

Include exactly one status badge line at the top of the report:
- `Status Badge: 🟩 VERIFIED ✅`
- `Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬`
- `Status Badge: 🟥 BLOCKED ⛔`

## Gist Claim (Required)

Write one sentence with outcome and impact (target <=18 words).

## Gist Evidence (Required)

Provide concise, convincing evidence:
1. Exactly 2 evidence bullets with concrete signals (metric, output, or log).
2. Include at least 1 graphic (image/chart screenshot) if available.
3. If no graphic is available, add `Graphic unavailable: <reason>`.

Example:
- p95 latency improved from 92ms to 74ms across the same input sample.
- End-to-end probe returned HTTP 200 and expected payload schema.
Graphic: /absolute/path/to/probe-chart.png

## Gist Human Run (Required)

Provide copy/paste steps and explicit pass/fail signals:

```bash
<command 1>
<command 2>
```

Pass signal: <exact text/status/artifact expected>
Fail signal: <exact text/status/artifact expected>

## Goal

State the user request and acceptance criteria in one concise paragraph.

## Acceptance Criteria

List explicit acceptance criteria as short bullets.

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

## Results by Criterion

Map each acceptance criterion to evidence:
- Criterion: <criterion text>
- Result: PASS | FAIL
- Evidence: <artifact path, metric, excerpt, or log line>

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
