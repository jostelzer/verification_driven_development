# Profile: Data Pipeline

Use for ETL jobs, queue workers, scheduled tasks, and data quality checks.

Prioritize:
- representative sample inputs
- before/after row counts or metric tables
- one guardrail case such as malformed input, duplicates, or partial failure
- stable artifact paths for generated outputs

Good artifacts:
- CSV summaries
- metric tables
- diff reports
- log excerpts tied to a sample identifier

Common `H0`:
- the pipeline still produces the old output shape or quality despite code changes
