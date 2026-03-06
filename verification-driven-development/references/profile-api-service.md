# Profile: API Service

Use for HTTP services, CLIs with network effects, backend integrations, and agent endpoints.

Prioritize:
- real operator requests
- response shape and status
- one corroborating signal from logs, state, or telemetry
- one failure-path or guardrail check

Good artifacts:
- response payloads
- structured logs
- request and response tables
- latency or throughput summaries when relevant

Common `H0`:
- unit tests passed but the deployed or running path still behaves the same as before
