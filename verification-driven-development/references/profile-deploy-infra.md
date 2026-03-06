# Profile: Deploy / Infra

Use for container builds, deploy pipelines, readiness checks, and runtime wiring.

Prioritize:
- real build and deploy entrypoints
- readiness or health checks
- one client-path confirmation, not only “container is running”
- explicit teardown of containers, tunnels, and temporary infra

Good artifacts:
- build logs
- health check output
- service discovery or port probes
- deployment summaries

Common `H0`:
- the artifact built successfully, but the running service is still miswired or unreachable
