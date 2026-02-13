# Run Evaluation Checklist

Apply this checklist before finalizing any run.

- Produce a joint plan that includes implementation and executable verification.
- Keep the joint plan compact by default (6 to 10 bullets total or one compact table).
- Include explicit commands, pass/fail signals, and runtime location for each verification step.
- Include evidence snippets tied directly to changed behavior.
- Prefer artifact-backed evidence (images/charts/audio/structured metrics) over prose-only "pass" claims.
- Loop on failure with observed signals and reruns.
- Issue certificate only at terminal state.
- Include the full Verification Certificate block inline in the final chat response (not just in artifacts).
- Include a standardized Verification Brief with sections: `Claim`, `Evidence`, `How YOU Can Run This`.
- Ensure `How YOU Can Run This` uses real operator commands, not temporary test harness scripts.
- Present the Verification Brief directly in chat by default (not as `verification-brief.md` artifact).
- Generate markdown report artifact by default (`verification-report.md`).
- Run `scripts/validate-vdd-report.sh <report_md>` and fix all validation errors before closeout.
- Do not claim fallback validation when the script is missing; report setup as blocked instead.
- Do not claim completion without executed verification, except approved static-only exception path.
- If static-only exception is used, record user approval and reason explicitly.
