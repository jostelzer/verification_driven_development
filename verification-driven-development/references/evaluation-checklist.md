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
- Do not claim completion without executed verification, except approved static-only exception path.
- If static-only exception is used, record user approval and reason explicitly.
