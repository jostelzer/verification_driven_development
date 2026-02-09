# Verification Report Template

Use this template for `VERIFIED` and `READY FOR HUMAN VERIFICATION`.

## Goal

State the user request and acceptance criteria in one concise paragraph.

## What Changed

List 3 to 8 concrete implementation changes.

## Runtime

State runtime surface and key versions:
- Execution context: `local` / `docker` / `ssh`.
- Host/container identifiers when relevant.
- Language/runtime/tool versions that materially affect behavior.

## Commands Run

Provide copy/paste command list in execution order.

```bash
# example
<command 1>
<command 2>
```

## Evidence and Inspection

Provide strongest verification signals with short excerpts:
- Signal 1: expected behavior observed.
- Signal 2: correlation signal (for example, request payload to log line).
- Signal 3: negative evidence (absence of errors/timeouts/regressions where applicable).

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
