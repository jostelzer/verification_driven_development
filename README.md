# Verification-Driven Development (VDD) Skill

<img src="verification-driven-development/assets/vdd.png" alt="Verification-Driven Development logo" width="50%" />

## TLDR: Closed-loop verification = build fast, with proof.

This skill is great if you find yourself:
- pasting stack traces back to your coding agent
- getting code that compiles, but doesn't match your spec
  (wrong behavior, broken integration)
- being unsure if and what the agent actually ran

VDD closes this loop by teaching your coding agent a strict
verification-first workflow: define executable checks up front, run real
commands, inspect real outputs, iterate until checks pass, and close with
evidence (a short Verification Report plus a Verification Certificate).

## Examples

### 1) From "naked model repo" to Dockerized HTTP inference

(e.g. YOLO face detection)

A GitHub repo is just model code/weights: no Dockerfile, no server, no API.
The goal is a Docker image that runs an HTTP inference server.

What VDD forces (beyond "it builds"):
- Add a minimal server (`/health`, `/predict`) and pin dependencies so rebuilds are deterministic.
- Build the Docker image, run the container, and prove readiness with a health check.
- Prove a client can reach the server from the host (not just "container is up").
- Download a real JPEG from the internet that contains a face.
- POST that JPEG to `/predict` and assert the response contains detections
  (and sensible fields/shape).
- Capture the exact commands, outputs, and pass/fail signals in the closeout.

### 2) Port WebGL to ModernGL without changing output

A port that "seems fine" isn't verification. VDD forces a visual proof:
- Capture a baseline screenshot from the original WebGL renderer (fixed seed/camera).
- Port to ModernGL and generate the same screenshot.
- Compare outputs with a calibrated visual metric (tolerance + "no-change" baseline) and save diff + metric summary.
- Treat mismatches as failing checks until resolved, then capture evidence.

## Failover Mode for VDD Tooling Errors

If VDD workflow tooling itself breaks (validator crash, render script
exception, missing required skill files), use the failover helper to create a
user-ready issue payload:

```bash
./scripts/render-vdd-failover-issue.sh \
  --summary "validator crashed during closeout" \
  --failed-command "./scripts/validate-vdd-report.sh .agent/runs/20260216-000000/verification-report.md" \
  --exit-code 1 \
  --stacktrace-file /tmp/vdd-error.log
```

The command prints:
- a prefilled GitHub issue URL for this repository
- an issue title
- a full markdown body (including stack trace) for copy/paste

## Installer

- Skill Installer (GitHub folder):
  [https://github.com/jostelzer/verification_driven_development/tree/main/verification-driven-development](https://github.com/jostelzer/verification_driven_development/tree/main/verification-driven-development)
- Or local: `./install.sh --target codex|claude|cursor`
- Invoke: `$verification-driven-development` (or `VDD`)
- Bundled validator path after install:
  `<skill-root>/scripts/validate-vdd-report.sh`
  (source-repo wrapper remains at `scripts/validate-vdd-report.sh`).

Agent behavior is defined in `verification-driven-development/SKILL.md` and `verification-driven-development/agents/openai.yaml`.

License: Apache License 2.0. See `LICENSE`.
