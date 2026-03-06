# Profile: Library Refactor

Use for behavior-preserving refactors, CLI rewrites, and internal code motion where the external contract should stay the same.

Prioritize:
- same input sample before and after
- output equivalence or invariant preservation
- one guardrail case
- real entrypoints over source inspection

Good artifacts:
- paired command outputs
- invariant tables
- snapshot diffs with thresholds
- log excerpts tied to the same input

Common `H0`:
- tests still pass, but a contract edge case or operator path changed
