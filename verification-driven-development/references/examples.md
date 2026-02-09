# Examples

## Example A: Server and client over SSH

1. Run smoke probe: start server and hit `/health`; expect HTTP 200.
2. Run full probe: execute client call and capture response payload.
3. Inspect correlation: match payload request id with server logs.
4. Pass only when schema and key values match acceptance criteria.

## Example B: UI or game behavior

1. Verify non-interactive pieces directly (config loaded, debug log markers).
2. Provide human harness and checklist for interaction-dependent behavior.
3. Request screenshots/log snippets and validate against expected outcomes.
4. Close as `READY FOR HUMAN VERIFICATION` until evidence returns.

## Example C: Expensive cold Docker build

1. Estimate 15 to 25 minutes; include >10 minute warning in plan.
2. Run fast smoke probe early to catch cheap failures.
3. Run full verification after build and compare outputs against criteria.
4. Report estimate versus actual timing and note cache effects.

## Example D: Show-don't-tell performance fix

1. Capture baseline metrics and generate a small table or chart from run output.
2. Apply fix and rerun the same command with identical scope.
3. Attach artifact paths (for example: chart image, CSV, or log extract) and map each to an acceptance criterion.
4. Avoid prose-only verdicts; close only with concrete before/after signals.
