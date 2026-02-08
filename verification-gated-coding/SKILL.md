---
name: verification-gated-coding
description: Verification-first coding workflow that prevents task completion until executable verification runs and evidence is captured. Use for feature, bugfix, integration, service, deployment, and data-pipeline work where runtime behavior matters. Require a joint implementation plus verification plan, iterative implement-run-inspect-fix loops, and a final Verification Report plus Certificate. Allow static-only verification only as a rare exception after explicitly asking the user and receiving approval.
---

# Verification-Gated Coding (VGC)

Enforce a hard verification gate:
- Do not declare task completion without executed verification commands and observed evidence.
- Do not issue terminal-state certificates until verification is complete.

## Inputs Required Before Claiming `VERIFIED`

Require all of the following:
- Task request and acceptance criteria.
- Runtime instructions, in this order of authority:
1. `agent.md` when present.
2. Repository automation (`Makefile`, scripts, compose files, CI workflows).
3. User-provided runtime instructions (env, conda, ssh, secrets handling).
- Runtime access (local, container, or SSH) sufficient to execute verification.

Treat SSH/runtime access as first-class when available.

## Terminal States

Use exactly one final state:
- `VERIFIED ✅`: implementation complete, executable verification passed, evidence supports success.
- `READY FOR HUMAN VERIFICATION 🧑‍🔬`: implementation complete, human interaction is required to complete verification, harness and checklist provided.
- `BLOCKED ⛔`: required runtime access/instructions are missing and verification cannot run.

## Operating Loop (Mandatory)

### Phase P0 (Optional): Orientation

Run this phase when repo/runtime is unclear.
- Locate build/run/test entry points.
- Locate observability surfaces (logs, endpoints, db tables, files, metrics).
- Identify missing runtime inputs and minimal unblock questions.
- Consult external docs only when needed to unblock execution.

Output:
- Short findings bullets.
- Draft plan covering both implementation and verification.

### Phase P1: Joint Plan

Produce one integrated plan before coding.

Implementation plan:
- Specify files/surfaces to change.
- Specify expected behavior change.
- List risky assumptions and how verification will validate each one.

Verification plan:
- List exact command(s) per step.
- Specify execution location (`local`, `docker`, `ssh`).
- Specify what to inspect (payload, log fields, db rows, files, metrics).
- Specify concrete pass/fail signals.
- Estimate time per step and total.
- Warn when estimated total exceeds 10 minutes, then proceed automatically.

Uncertainty rule:
- If any verification prerequisite is unknown (host, ports, env, secrets, credentials), ask the user in the plan before coding.

### Phase P2: Implement -> Run -> Inspect -> Fix

Loop until terminal state.
- Implement minimal changes.
- Run planned verification.
- Inspect evidence with at least one correlation step (for example, payload field to server log `request_id`).
- If failing, summarize observed failure signals (not guesses), adjust code/probes, and rerun.

### Phase P3: Closeout

Produce:
- Verification Report using `references/report-template.md`.
- Verification Certificate using `references/certificate-template.md`.

## Verification Policy

Must:
- Execute behavior through the same path a careful human would execute.
- Collect concrete evidence and perform light introspection.
- Keep verification practical; escalate to human verification when interaction is required.

Allowed:
- Temporary probes, debug flags, and one-off scripts.
- Early smoke probes plus full verification.

Forbidden:
- Source-text checks as stand-ins for behavior validation.
- Success claims without executed commands and observed outputs.

## Static-Only Exception (Strict)

Treat static-only verification as rare exception handling.

Rule:
- Do not switch to static-only verification silently.
- Ask the user first, explain why runtime verification is unavailable or inappropriate, and list proposed static checks.
- Continue only after explicit user approval.

Default result for approved static-only exception:
- Emit `READY FOR HUMAN VERIFICATION 🧑‍🔬`, unless user explicitly confirms static-only evidence is sufficient for `VERIFIED ✅`.

## Time Estimation Policy

- Estimate every verification step and total expected duration.
- Warn in plan when total estimate exceeds 10 minutes.
- Proceed automatically after warning.
- Report estimated versus actual timing in closeout.

## Probes and Artifacts

Use `.agent/` (gitignored by convention):
- `.agent/probes/`
- `.agent/runs/<timestamp>/`

Default behavior:
- Avoid committing probes.
- Retain only evidence needed to justify report and certificate.

## Secrets and Remote Access

- Source secrets from environment variables or SSH environment.
- Never embed secrets in code or commits.
- Never auto-edit `agent.md`; propose edits and ask first.

## Required Reference Files

Load as needed:
- Report format: `references/report-template.md`
- Certificate format: `references/certificate-template.md`
- Usage patterns and examples: `references/examples.md`
- Self-check checklist: `references/evaluation-checklist.md`
