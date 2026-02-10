---
name: verification-driven-development
description: Verification-first coding workflow (VDD) that prevents task completion until executable verification runs and evidence is captured. Use for feature, bugfix, integration, service, deployment, and data-pipeline work where runtime behavior matters. Require a joint implementation plus verification plan, iterative implement-run-inspect-fix loops, and a final Verification Report plus Certificate. Allow static-only verification only as a rare exception after explicitly asking the user and receiving approval.
---

# Verification-Driven Development (VDD)

Enforce a hard verification gate:
- Do not declare task completion without executed verification commands and observed evidence.
- Do not issue terminal-state certificates until verification is complete.

## Command Execution Ownership (Mandatory)

Human command execution is a last resort.

Must:
- Attempt every runnable implementation and verification command directly in the agent environment first.
- If a command fails, capture evidence (exact command, location, exit status, key stderr/stdout signals), diagnose why, and attempt the next reasonable fix/workaround.
- Exhaust agent-side options before delegating any command to the human.
- When blocked by permissions/sandboxing, request full access/escalated execution instead of asking the human to run commands.
- Ask the human to run commands only when execution is genuinely impossible for the agent (for example: physical device action, MFA-bound identity step, browser click-path unavailable to agent, or out-of-band system the agent cannot reach).

Any human-run request must include:
- What was attempted by the agent.
- Why it failed, with observed evidence (not guesses).
- Why the human is required specifically.
- Exact command/checklist the human should run, plus expected pass/fail signals.

## Inputs Required Before Claiming `VERIFIED`

Require all of the following:
- Task request and acceptance criteria.
- Ground-truth source or baseline specification (user-provided data, reference implementation, golden outputs, public dataset, or an explicit user waiver).
- Runtime instructions, in this order of authority:
1. `agent.md` when present.
2. Repository automation (`Makefile`, scripts, compose files, CI workflows).
3. User-provided runtime instructions (env, conda, ssh, secrets handling).
- Runtime access (local, container, or SSH) sufficient to execute verification.

Treat SSH/runtime access as first-class when available.

## Ground-Truth Requirement (Mandatory)

Verification should approximate ground truth as closely as practical.

Rules:
- If ground truth is plausibly obtainable, you must pursue it (ask the user and propose sources). Any credible source is acceptable; prefer high-quality datasets when available.
- Default to a small, representative sample that is fast to run but still convincing; scale up only if the user asks for thoroughness or risk justifies it.
- Make a reasonable choice for the initial ground-truth check without blocking on user input; offer a stronger follow-up option after the first pass.
- If ground truth is not provided and no reasonable default can be inferred, present 2 to 3 options that trade off fidelity, time, and cost; ask the user to choose.
- If ground truth is unavailable or explicitly waived, record the waiver and lower the terminal state unless the user explicitly accepts the reduced evidence tier.

## Terminal States

Use exactly one final state:
- `VERIFIED ✅`: implementation complete, executable verification passed, ground-truth tier met, evidence supports success.
- `READY FOR HUMAN VERIFICATION 🧑‍🔬`: implementation complete, human interaction is required to complete verification, harness and checklist provided.
- `BLOCKED ⛔`: required runtime access/instructions are missing and verification cannot run after agent-side attempts (including requesting full access when permissions are the blocker).

## Communication Style (Default: Compact)

Keep user-facing plans concise by default.
- Target 6 to 10 bullets total, or one compact table with up to 5 steps.
- Include only decisions that affect execution: change surfaces, commands, pass/fail signals, blockers, and timing.
- Avoid restating policy text or obvious repository context.
- Expand detail only when the user asks for it or when risk/ambiguity is high.

## Operating Loop (Mandatory)

### Phase P0 (Optional): Orientation

Run this phase when repo/runtime is unclear.
- Locate build/run/test entry points.
- Locate observability surfaces (logs, endpoints, db tables, files, metrics).
- Identify missing runtime inputs and minimal unblock questions.
- Consult external docs only when needed to unblock execution.

Output:
- Short findings bullets (max 5).
- Draft plan covering both implementation and verification in compact form.

### Phase P1: Joint Plan

Produce one integrated plan before coding.
Present it in a compact format.

Implementation plan:
- Specify files/surfaces to change (1 to 3 bullets).
- Specify expected behavior change (1 to 2 bullets).
- List risky assumptions (max 3) and how verification will validate each one.

Verification plan:
- List exact command(s) per step (target max 5 steps).
- Specify execution location (`local`, `docker`, `ssh`) per step.
- Specify what to inspect and concrete pass/fail signals per step.
- Include a Ground-Truth Plan: source, acquisition method, sample size, metric(s), threshold(s), and artifact location.
- When ground truth is uncertain or costly, present 2 to 3 verification options with estimated time/cost and evidence tier.
- Estimate time per step and total (compact format is fine).
- Warn when estimated total exceeds 10 minutes, then proceed automatically.

Uncertainty rule:
- If any verification prerequisite is unknown (host, ports, env, secrets, credentials), ask the user in the plan before coding.
- Unknown prerequisites do not justify delegating runnable commands to the user; the agent still owns execution attempts.
- When reasonable defaults exist, choose them and proceed; ask only when blocked or the choice would materially change verification cost/validity.

### Phase P2: Implement -> Run -> Inspect -> Fix

Loop until terminal state.
- Implement minimal changes.
- Run planned verification.
- Inspect evidence with at least one correlation step (for example, payload field to server log `request_id`).
- Execute ground-truth checks and retain inputs/outputs as artifacts.
- If failing, summarize observed failure signals (not guesses), adjust code/probes, and rerun.

### Phase P3: Closeout

Produce:
- Verification Report using `references/report-template.md`.
- Verification Certificate using `references/certificate-template.md`.
- Always render the Verification Certificate block directly in the final chat response (user-visible), not only in `.md` artifacts.
- Artifact index with links/paths to evidence and one line per artifact stating what it proves.
- Explicit command ownership summary: what the agent ran, what failed, and why any remaining human step was unavoidable.

## Verification Policy

Must:
- Execute behavior through the same path a careful human would execute.
- Collect concrete evidence and perform light introspection.
- Keep verification practical; escalate to human verification when interaction is required.
- Prefer a "show, don't tell" style: screenshots, charts, structured metrics/tables, audio captures, or similarly data-rich artifacts that can be included in chat.
- Map each acceptance criterion to at least one artifact-backed signal.
- Use sanity checks only as preflight; they are not sufficient for `VERIFIED ✅` without an explicit, documented user waiver.

Evidence tiers (aim for the highest feasible tier):
- Sanity: readiness, environment, and basic non-error execution.
- Ground truth: outputs compared against trusted data, reference outputs, or labeled datasets.
- Quantitative: metrics with thresholds and sample sizes; include confidence or variance where relevant.

Allowed:
- Temporary probes, debug flags, and one-off scripts.
- Early smoke probes plus full verification.

Forbidden:
- Source-text checks as stand-ins for behavior validation.
- Success claims without executed commands and observed outputs.
- Bare success assertions (for example, "it worked") without artifacts or concrete data signals.
- Asking the human to run commands the agent has not attempted.
- Asking the human to run commands when the blocker is permissions that should be handled via full-access/escalated execution.

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
- `.agent/ground-truth/` for datasets, reference outputs, and evaluation summaries.

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
