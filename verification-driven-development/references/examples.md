# Examples

## Example A: Server and client over SSH

1. Run smoke probe: start server and hit `/health`; expect HTTP 200.
2. Run full probe: execute client call and capture response payload.
3. Inspect correlation: match payload request id with server logs.
4. Stop verification-started server/session, then verify no process remains.
5. Pass only when schema/key values match acceptance criteria and cleanup check passes.

## Example B: UI or game behavior

1. Verify non-interactive pieces directly (config loaded, debug log markers).
2. Provide human harness and checklist for interaction-dependent behavior.
3. Request screenshots/log snippets and validate against expected outcomes.
4. Close as `READY FOR HUMAN VERIFICATION` until evidence returns.

## Example C: Expensive cold Docker build

1. Estimate Gold first (for example 15 to 25 minutes total).
2. Since Gold exceeds 10 minutes, present concise Bronze/Silver/Gold options with exact checks and runtimes, then wait for user choice.
3. Run the selected tier; Bronze/Silver must still execute real end-to-end operator paths.
4. Tear down verification-started containers/networks and verify they are stopped.
5. Report Gold gate decision, selected tier, cleanup status, and residual risk if below Gold.

## Example D: Show-don't-tell performance fix

1. Capture baseline metrics and generate a small table or chart from run output.
2. Apply fix and rerun the same command with identical scope.
3. Attach artifact paths (for example: chart image, CSV, or log extract) and map each to an acceptance criterion.
4. Avoid prose-only verdicts; close only with concrete before/after signals.
