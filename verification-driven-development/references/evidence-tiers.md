# Evidence Tiers

Estimate Gold first during Phase P1 planning, then report both target and achieved tier in closeout.

## Bronze

- Scope: valid end-to-end verification through the real operator path.
- Must include: at least one success-path check and one failure or guardrail check.
- Must include: evidence that separates `H1` from `H0`.
- Use when: Gold exceeds 10 minutes and the user explicitly selects Bronze.
- Closeout: state residual risk clearly.

## Silver

- Scope: Bronze plus representative sample coverage against a credible baseline.
- Must include: at least one control or baseline comparison and at least two independent observables.
- Use when: Gold exceeds 10 minutes and the user explicitly selects Silver.
- Closeout: map each acceptance criterion to evidence and thresholds.

## Gold

- Scope: Silver plus quantitative rigor or broader confidence as the profile demands.
- Must include: explicit metrics tables, repeated samples or calibrated baselines when signals are noisy.
- Use when: Gold is estimated at 10 minutes or less, or when the user explicitly selects Gold.

## Selection Rule

- Always estimate a Gold plan first.
- If estimated Gold total is 10 minutes or less, run Gold.
- If estimated Gold total exceeds 10 minutes, ask the user to choose exactly one of:
  - `🥉 Bronze — <estimated total time>`
  - `🥈 Silver — <estimated total time>`
  - `🥇 Gold — <estimated total time>`
- Each option must include both the total time estimate and the exact checks included in that tier.
- Lower tiers still require real operator-path verification.
