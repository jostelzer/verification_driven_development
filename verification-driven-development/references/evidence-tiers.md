# Evidence Tiers

Use evidence tiers only when they help discuss a real time, cost, or confidence tradeoff.
Do not let tier naming become paperwork.

## Bronze

- Scope: valid end-to-end verification through the real operator path.
- Must include: at least one success-path check and one failure or guardrail check.
- Must include: evidence that separates `H1` from `H0`.
- Use when: a fast but honest end-to-end check is the right tradeoff.
- Closeout: state residual risk clearly.

## Silver

- Scope: Bronze plus representative sample coverage against a credible baseline.
- Must include: at least one control or baseline comparison and at least two independent observables.
- Use when: you need stronger corroboration without paying full Gold cost.
- Closeout: map each acceptance criterion to evidence and thresholds.

## Gold

- Scope: Silver plus quantitative rigor or broader confidence as the runtime surface demands.
- Must include: explicit metrics tables, repeated samples or calibrated baselines when signals are noisy.
- Use when: the task justifies broader rigor or repeatability.

## Selection Rule

- Start with the lightest end-to-end check that can realistically falsify the claim.
- Escalate to Silver or Gold when risk, ambiguity, or cost of being wrong justifies it.
- If you use tier labels, include the total time estimate and the exact checks included.
- Lower tiers still require real operator-path verification.
