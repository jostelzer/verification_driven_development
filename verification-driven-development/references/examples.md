# Examples

## Example A: CRUD API Bugfix (`api-service`)

1. Capture the failing request and the expected response shape.
2. Fix the bug, rerun the request, and confirm the response plus one corroborating log or state signal.
3. Add one failure-path or guardrail check so `H0` is still plausible and testable.
4. Record commands, artifacts, and cleanup in the manifest.

## Example B: UI Checkout Flow (`ui-browser`)

1. Run the UI preflight and execute the browser harness from `.agent/probes/ui/`.
2. Capture at least one screenshot or trace plus one corroborating DOM, URL, or network signal.
3. If screenshots or charts matter to the verdict, list them with absolute filesystem paths and embed them inline in the report.
4. If the last discriminating step requires manual interaction, close as `READY FOR HUMAN VERIFICATION 🧑‍🔬`.

## Example C: Remote Server Verification

1. Run remote commands over SSH and capture the exact host plus observed outputs.
2. Require at least one command whose execution location is `ssh`.
3. Clean up remote processes or containers and prove teardown remotely before closeout.

## Example D: Data Pipeline Fix (`data-pipeline`)

1. Use a representative sample or historical baseline as ground truth.
2. Verify both success-path output and one guardrail case such as malformed input or duplicate data.
3. Attach structured outputs or tables, not only prose.

## Example E: Behavior-Preserving Refactor (`library-refactor`)

1. Run the old and new operator entrypoints on the same input sample.
2. Compare outputs, logs, or invariants and retain the paired artifacts.
3. Treat “unit tests passed” as preflight, not as final proof.

## Example F: Tier Choice Prompt

When runtime or cost tradeoffs matter, present the choice like this:
- `🥉 Bronze — 8m total`: real operator path, success check, and one guardrail check.
- `🥈 Silver — 14m total`: Bronze plus representative baseline comparison and two observables.
- `🥇 Gold — 22m total`: Silver plus broader quantitative rigor or repeatability.
