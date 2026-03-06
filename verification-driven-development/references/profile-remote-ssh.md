# Profile: Remote SSH

Use when the decisive runtime lives on one or more remote hosts.

Prioritize:
- explicit host identity and execution location
- remote commands that exercise the real operator path
- remote artifact capture or log retrieval
- remote teardown proof before closeout

Good artifacts:
- SSH command outputs
- remote logs
- service status checks
- copied-back reports or metrics

Rules:
- At least one manifest command must have location `ssh`.
- Treat local edits and remote execution separately; verification lives where the runtime lives.
