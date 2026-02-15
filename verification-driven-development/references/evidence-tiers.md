# Evidence Tiers

Select a target evidence tier during Phase P1 planning and report the achieved tier in closeout.

## Bronze

- Scope: sanity checks only (readiness and non-error execution).
- Use when: constrained discovery/prototyping, or explicit user waiver.
- Limit: weak discrimination (often cannot separate "it ran" from "it worked"); normally insufficient for `VERIFIED ✅` without explicit user acceptance.

## Silver

- Scope: behavior validated against a credible baseline or ground-truth source on a representative sample, using evidence that can distinguish the claim (`H1`) from a plausible alternative (`H0`).
- Use when: standard feature/bugfix verification where practical confidence is needed.
- Expectation: include concrete pass/fail signals (decision rules) and artifact-backed mapping to acceptance criteria. For noisy/proxy metrics, include at least one control (for example, "no-change" baseline) so the signal is interpretable.

## Gold

- Scope: Silver plus quantitative evaluation (thresholds, sample sizes, variance/confidence where relevant) and calibrated measurement when noise is plausible.
- Use when: high-risk changes, performance-sensitive systems, or user-requested thoroughness.
- Expectation: explicit metrics table or chart artifacts, control/baseline comparisons, and threshold verdicts.

## Selection Rule

- Choose the highest feasible tier for available runtime, time budget, and risk.
- If a lower tier is used, document why and the residual risk.
