# Ground-Truth Ladder

Use the strongest feasible rung that fits the task, time budget, and access constraints.

## Rungs

1. Golden outputs or labeled datasets
   Best when exact correctness matters and trusted examples already exist.

2. Reference implementation or prior known-good release
   Good for behavior-preserving work, migrations, and regressions.

3. Sampled real production or production-like data
   Good when labels do not exist but realistic inputs do.

4. Historical baseline or telemetry baseline
   Good for performance, reliability, or trend-based behavior.

5. Synthetic fallback with explicit rationale
   Use only when better sources are unavailable; record residual risk clearly.

## Selection Rules

- Start at rung 1 and move downward only when blocked by time, cost, access, or absence of data.
- Use a small representative sample first unless the user asks for a thorough run.
- State the selected rung in the plan, manifest, and report.
- If you fall below rung 3, explain why and what risk remains.

## Controls

- For noisy signals, capture a baseline or “no-change” control before trusting a claimed improvement.
- For visual signals, pair screenshots or traces with one corroborating non-visual signal when practical.
