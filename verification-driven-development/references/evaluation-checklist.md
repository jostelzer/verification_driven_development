# Run Evaluation Checklist

Apply this checklist before finalizing any run.

- Produce a joint plan that includes implementation and executable verification.
- Keep the joint plan compact by default (6 to 10 bullets total or one compact table).
- Include explicit commands, pass/fail signals, and runtime location for each verification step.
- For each acceptance criterion, make the evidence discriminating: state `H1` (claim) vs `H0` (no change/plausible confounder), the observable (units), and the decision rule (threshold).
- Estimate a Gold plan first and record total estimated runtime.
- If Gold estimate is 10 minutes or less, select Gold (mandatory).
- If Gold estimate exceeds 10 minutes, present concise Bronze/Silver/Gold options with exact checks and runtime; proceed only after explicit user choice.
- Ensure Bronze/Silver options remain true end-to-end verification (not smoke-only).
- Record target tier, achieved tier, and (if not Gold) explicit user choice plus residual risk.
- Include evidence snippets tied directly to changed behavior.
- Prefer artifact-backed evidence (images/charts/audio/structured metrics) over prose-only "pass" claims.
- For noisy/proxy signals, include at least one control/baseline (for example, "no-change" run) so the metric is interpretable.
- If evidence includes images/video/UI screenshots, include a semantic interpretation step using vision capabilities (what changed, measured as an observable), not just raw diffs.
- If a vision-derived signal is important to the verdict, corroborate it (logs/state/programmatic detector) or mark the result as `INCONCLUSIVE` and redesign the check.
- Loop on failure with observed signals and reruns.
- Issue certificate only at terminal state.
- Include the full Verification Certificate block inline in the final chat response (not just in artifacts).
- Include a standardized Verification Brief with sections: `Claim`, `Evidence`, `How YOU Can Run This`.
- Ensure `How YOU Can Run This` uses real operator commands, not temporary test harness scripts.
- Present the Verification Brief directly in chat by default (not as `verification-brief.md` artifact).
- Generate markdown report artifact by default (`verification-report.md`).
- Run `scripts/validate-vdd-report.sh <report_md>` and fix all validation errors before closeout.
- Do not claim fallback validation when the script is missing; report setup as blocked instead.
- If VDD tooling fails internally, emit failover output with stack trace and a prefilled GitHub issue link/body.
- Do not claim completion without executed verification, except approved static-only exception path.
- Stop all verification-spawned instances before closeout; include teardown commands and a post-cleanup check.
- If cleanup is incomplete, do not close as `VERIFIED` or `READY FOR HUMAN VERIFICATION`; use `BLOCKED`.
- If static-only exception is used, record user approval and reason explicitly.
