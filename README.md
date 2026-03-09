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
evidence (a short Verification Manifest, Verification Report, and
Verification Certificate).

## What VDD Enforces

The skill now emphasizes:
- verification profiles (`api-service`, `ui-browser`, `data-pipeline`, `ml-model`, `deploy-infra`, `library-refactor`, `remote-ssh`)
- a machine-readable Verification Manifest that records commands, artifacts, cleanup, and command ownership
- a compact Verification Snapshot with badge-style status, tier, ground-truth, cleanup, and human-step lines
- a compact Human Verification Card with optional operator notes
- an anti-pattern library for catching weak evidence and fake-confidence closeouts before terminal output
- bundled helper scripts inside the installed skill, so manifest/report validation still works after install

## Quick Start

1. Install the skill for your tool:
   - Codex: `./install.sh --target codex`
   - Claude Code: `./install.sh --target claude`
   - Cursor: `./install.sh --target cursor --cursor-project <project-root>`
2. Invoke it:
   - Codex: `$verification-driven-development` or `VDD`
   - Claude Code: `/verification-driven-development`
   - Cursor: apply `.cursor/rules/verification-driven-development.mdc`
3. Use it on a task where "done" is cheap but proof is not: API bugfixes,
   browser flows, containerized services, or remote-host verification.

## Good Fit / Bad Fit

Good fit:
- API bugs where "200 OK" is not enough
- UI flows that need a real browser signal
- Docker or deploy work where readiness and cleanup matter
- Data or ML tasks that need grounded evaluation evidence
- Remote SSH work where the decisive behavior happens off-box

Bad fit:
- trivial copy edits
- docs-only changes
- low-stakes static rewrites where no runtime claim is being made

## What Closeout Looks Like

The output is meant to be inspectable, not just confident:

```text
Terminal State: VERIFIED ✅
Profile: api-service
Ground Truth: Silver
Command: curl -sSf http://127.0.0.1:8000/health
Observed Signal: HTTP 200 with expected readiness payload
Cleanup: PASS, no verification resources left running
```

## Examples

These examples matter because VDD is strongest when the success claim can be
confused with a plausible false positive.

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
- Show any load-bearing screenshot, chart, or diff inline in the report instead of only citing a path.
- Treat mismatches as failing checks until resolved, then capture evidence.

### 3) Fix a boring but real API bug

The common case matters:
- Pick the `api-service` profile.
- Capture the failing request and the expected response or state change.
- Fix the bug and rerun the real operator path.
- Corroborate the result with one independent signal: logs, DB state, or telemetry.
- Record commands, artifacts, and cleanup in the manifest.

### 4) Verify behavior on a remote host over SSH

When the runtime lives elsewhere, verification should too:
- Pick the `remote-ssh` profile.
- Run the decisive checks over SSH, not just locally.
- Capture host identity, remote outputs, and teardown evidence.
- Do not close `VERIFIED` unless the remote cleanup check passes.

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

## Install and Invoke

GitHub folder:
[https://github.com/jostelzer/verification_driven_development/tree/main/verification-driven-development](https://github.com/jostelzer/verification_driven_development/tree/main/verification-driven-development)

Install:
- Codex: `./install.sh --target codex`
- Claude Code: `./install.sh --target claude`
- Cursor: `./install.sh --target cursor --cursor-project <project-root>`
- All targets: `./install.sh --target all --cursor-project <project-root>`

Invoke:
- Codex: `$verification-driven-development` (or `VDD`)
- Claude Code: `/verification-driven-development`
- Cursor: install the project rule, which writes
  `.cursor/rules/verification-driven-development.mdc`; Cursor then applies it
  as a project rule in that workspace.

What gets installed:
- Validator paths:
  `<skill-root>/scripts/validate-vdd-report.sh` and
  `<skill-root>/scripts/validate-vdd-manifest.sh`
- Helper scripts:
  - `<skill-root>/scripts/init-vdd-run.sh`
  - `<skill-root>/scripts/render-verification-brief.sh`
  - `<skill-root>/scripts/render-human-verification-card.sh`
  - `<skill-root>/scripts/ensure-agent-ignore.sh`
  (source-repo wrappers remain under `scripts/`)

Agent behavior is defined in `verification-driven-development/SKILL.md` and `verification-driven-development/agents/openai.yaml`.

License: Apache License 2.0. See `LICENSE`.
