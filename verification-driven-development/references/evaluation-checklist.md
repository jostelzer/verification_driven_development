# Run Evaluation Checklist

Apply this checklist before finalizing any run.

- Produce a joint plan that includes implementation and executable verification.
- Include explicit commands, pass/fail signals, and runtime location for each verification step.
- Include evidence snippets tied directly to changed behavior.
- Loop on failure with observed signals and reruns.
- Issue certificate only at terminal state.
- Do not claim completion without executed verification, except approved static-only exception path.
- If static-only exception is used, record user approval and reason explicitly.
