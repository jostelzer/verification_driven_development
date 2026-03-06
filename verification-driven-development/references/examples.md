# Examples

## Example A: CRUD API Bugfix (`api-service`)

1. Pick `api-service`.
2. Capture the failing request and the expected response shape.
3. Fix the bug, rerun the request, and confirm the response plus one corroborating log or state signal.
4. Add one failure-path or guardrail check so `H0` is still plausible and testable.
5. Record commands, artifacts, and cleanup in the manifest.

## Example B: UI Checkout Flow (`ui-browser`)

1. Pick `ui-browser`.
2. Run the UI preflight and execute the browser harness from `.agent/probes/ui/`.
3. Capture at least one screenshot or trace plus one corroborating DOM, URL, or network signal.
4. If the last discriminating step requires manual interaction, close as `READY FOR HUMAN VERIFICATION 🧑‍🔬`.

## Example C: Remote Server Verification (`remote-ssh`)

1. Pick `remote-ssh`.
2. Run remote commands over SSH and capture the exact host plus observed outputs.
3. Require at least one command whose execution location is `ssh`.
4. Clean up remote processes or containers and prove teardown remotely before closeout.

## Example D: Data Pipeline Fix (`data-pipeline`)

1. Pick `data-pipeline`.
2. Use a representative sample or historical baseline as ground truth.
3. Verify both success-path output and one guardrail case such as malformed input or duplicate data.
4. Attach structured outputs or tables, not only prose.

## Example E: Behavior-Preserving Refactor (`library-refactor`)

1. Pick `library-refactor`.
2. Run the old and new operator entrypoints on the same input sample.
3. Compare outputs, logs, or invariants and retain the paired artifacts.
4. Treat “unit tests passed” as preflight, not as final proof.
