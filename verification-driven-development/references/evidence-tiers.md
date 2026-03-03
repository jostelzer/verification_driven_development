# Evidence Tiers

Estimate Gold first during Phase P1 planning, then report both target and achieved tier in closeout.

## Bronze

- Scope: valid end-to-end verification through the real operator path (CLI/API/UI), not smoke-only.
- Must include: at least one success-path check and one failure/guardrail check with explicit pass/fail decision rules.
- Must include: artifact-backed discrimination of `H1` (claim) vs `H0` (no change/plausible confounder).
- Use when: Gold exceeds 10 minutes and the user explicitly selects Bronze.
- Limit: lower sample depth/quantification; closeout must state residual risk.

## Silver

- Scope: Bronze plus representative sample coverage against a credible baseline/ground-truth source.
- Must include: at least one control/baseline comparison and at least two independent observables (for example, user-visible output plus logs/state).
- Use when: Gold exceeds 10 minutes and the user explicitly selects Silver.
- Expectation: concrete thresholds and artifact-backed mapping to each acceptance criterion.

## Gold

- Scope: Silver plus quantitative rigor (sample size/repeatability, variance/confidence where relevant, calibrated noise floor when signals are noisy).
- Use when: Gold is estimated at 10 minutes or less (mandatory), or when the user chooses Gold despite higher runtime.
- Expectation: explicit metrics table/chart artifacts, baseline/control comparisons, and threshold verdicts.

## Selection Rule

- Always estimate a Gold plan first.
- If estimated Gold total is 10 minutes or less, run Gold (mandatory, no downgrade prompt).
- If estimated Gold total exceeds 10 minutes, ask user to choose exactly one option (`Bronze`, `Silver`, or `Gold`) with concise per-option checks and estimated runtime.
- Proceed only after explicit user choice when Gold exceeds 10 minutes.
- If a lower tier is selected, document user choice, reason, and residual risk.
