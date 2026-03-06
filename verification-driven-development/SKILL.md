---
name: verification-driven-development
description: >-
  Verification-first coding workflow (VDD) that prevents task completion until
  executable verification runs and evidence is captured. Use for feature,
  bugfix, integration, service, deployment, and data-pipeline work where
  runtime behavior matters. Require a joint implementation plus verification
  plan, iterative implement-run-inspect-fix loops, and a final Verification
  Report plus Certificate. Allow static-only verification only as a rare
  exception after explicitly asking the user and receiving approval.
---

# Verification-Driven Development (VDD)

Enforce a hard verification gate:
- Do not declare task completion without executed verification commands and observed evidence.
- Do not issue terminal-state certificates until verification is complete.
- Prefer semantic evidence over report theatrics: the manifest, artifacts, and observed signals are the source of truth.

## Core Invariants

Always:
- Execute the real operator path whenever practical.
- Collect enough evidence to distinguish `H1` (the claim) from `H0` (no change or a plausible confounder).
- Track resources you start and prove cleanup before any terminal state.
- Treat SSH, containers, and browsers as first-class runtime surfaces, not exceptions.

## Verification Profiles (Mandatory)

Select exactly one primary verification profile before coding.
Use the closest fit and load only that reference unless the task truly spans multiple surfaces.

- `api-service`: HTTP/CLI services, integrations, agents, and backend bugfixes. See `references/profile-api-service.md`.
- `ui-browser`: browser click flows, visibility, interaction state, and visual regressions. See `references/profile-ui-browser.md`.
- `data-pipeline`: ETL, batch jobs, queue workers, and data quality checks. See `references/profile-data-pipeline.md`.
- `ml-model`: inference quality, model serving, evaluation datasets, and regression checks. See `references/profile-ml-model.md`.
- `deploy-infra`: build/deploy pipelines, containers, infra wiring, and runtime readiness. See `references/profile-deploy-infra.md`.
- `library-refactor`: internal refactors, CLI/library changes, and behavior-preserving rewrites. See `references/profile-library-refactor.md`.
- `remote-ssh`: verification that primarily runs on remote hosts over SSH. See `references/profile-remote-ssh.md`.

Profile rules:
- Pick the profile in Phase P1 and record it in the manifest and the report.
- If the task has a secondary surface, borrow only the specific check patterns needed from that reference.
- `remote-ssh` is a real profile, not a transport footnote. If the critical evidence lives on a remote machine, plan for it explicitly.

## Command Execution Ownership (Mandatory)

Human command execution is a last resort.

Must:
- Attempt every runnable implementation and verification command directly in the agent environment first.
- Track every process/container/tunnel started by the agent for verification so teardown can be completed.
- If a command fails, capture evidence: exact command, location, exit status, and key stderr/stdout signals.
- Exhaust agent-side options before delegating any command to the human.
- Ask the human to run commands only when execution is genuinely impossible for the agent.

Any human-run request must include:
- What was attempted by the agent.
- Why it failed, with observed evidence.
- Why the human is required specifically.
- Exact command/checklist the human should run, plus expected pass/fail signals.
- Operator-facing run steps must use real product entrypoints, not ad-hoc probe scripts created during the run.
- Do not point humans to ephemeral harness files under `.agent/runs/` or `/tmp/`, or to `playwright_*.js`, `*_check.js`, or `*.spec.js` scripts.
- A compact Human Verification Card in this exact order:
1. Preconditions.
2. Steps.
3. Pass signal(s).
4. Fail signal(s).
5. Return condition.
- Optional `Operator Notes` may follow the card when the flow needs extra context.

Use `references/human-verification-card-template.md` and prefer rendering via:
1. `<active-repo>/scripts/render-human-verification-card.sh <manifest_json>`
2. `<skill-root>/scripts/render-human-verification-card.sh <manifest_json>`

## Skill Failover Mode (Mandatory)

Use failover mode when VDD tooling itself breaks: validator crash, renderer crash, missing required skill file, or internal workflow conflict.

Rules:
- Do not hide the failure and do not continue with normal closeout or certificate flow.
- Terminal state must be `BLOCKED ⛔`.
- Return a compact failover block that includes:
1. Error summary.
2. Exact failed command, execution location, and exit code.
3. Stack trace in a fenced `text` block.
4. Prefilled GitHub issue link for this skill repository.
5. Copy/paste-ready issue body.

Generate failover issue content using this resolver order:
1. `<active-repo>/scripts/render-vdd-failover-issue.sh ...`
2. `<skill-root>/scripts/render-vdd-failover-issue.sh ...`

## Inputs Required Before Claiming `VERIFIED`

Require all of the following:
- Task request and acceptance criteria.
- Chosen verification profile.
- Ground-truth source or an explicit waiver.
- Runtime instructions, in this order of authority:
1. `agent.md` when present.
2. Repository automation (`Makefile`, scripts, compose files, CI workflows).
3. User-provided runtime instructions (env, conda, SSH, secrets handling).
- Runtime access sufficient to execute verification.

## Ground-Truth Ladder (Mandatory)

Use `references/ground-truth-ladder.md` as the source of truth.

Rules:
- Start from the strongest feasible rung and only fall back when cost, availability, or permissions make that rung impractical.
- Default to a small but representative sample first; scale up only when risk justifies it.
- If ground truth is not provided and no reasonable default can be inferred, present 2 to 3 options that trade off fidelity, time, and cost.
- If ground truth is waived or degraded, record the waiver, the selected rung, and the residual risk.

## Verification Manifest (Mandatory)

Use a run manifest as the machine-readable source of truth for the run.

Initialization:
1. `<active-repo>/scripts/init-vdd-run.sh [run_id]`
2. `<skill-root>/scripts/init-vdd-run.sh [run_id]`

Manifest rules:
- Store the manifest at `.agent/runs/<timestamp>/verification-manifest.json`.
- Record the chosen profile, tier decision, commands, observed signals, artifacts, criteria results, cleanup, and command ownership.
- Update the manifest during the loop, not only at the end.
- Keep artifact paths explicit and stable.
- Treat the manifest as stronger evidence than prose summary. The report and certificate must not contradict it.

Validate the manifest before validating the report:
1. `<active-repo>/scripts/validate-vdd-manifest.sh <manifest_json>`
2. `<skill-root>/scripts/validate-vdd-manifest.sh <manifest_json>`

## Terminal States

Use exactly one final state:
- `VERIFIED ✅`: implementation complete, executable verification passed, tier decision respected, and evidence supports success.
- `READY FOR HUMAN VERIFICATION 🧑‍🔬`: implementation complete, the agent verified everything it could, and a human must complete the final discriminating step.
- `BLOCKED ⛔`: required runtime access, tooling, or instructions are missing after agent-side attempts.

Gates:
- UI gate for `VERIFIED ✅`: when acceptance criteria include browser-driven interaction, `VERIFIED ✅` requires at least one executed browser-path signal.
- Evidence-tier gate for `VERIFIED ✅`: if Gold is estimated at 10 minutes or less, `VERIFIED ✅` requires Gold evidence.
- Cleanup gate for all terminal states: if any spawned verification resource cannot be stopped, terminal state must be `BLOCKED ⛔`.

## Communication Style (Default: Compact)

Keep user-facing plans concise by default.
- Target 6 to 10 bullets total, or one compact table with up to 5 steps.
- Include only decisions that affect execution: profile, change surface, commands, pass/fail signals, blockers, and timing.
- Expand detail only when the user asks for it or when ambiguity is high.

## Operating Loop (Mandatory)

### Phase P1: Joint Plan

Produce one integrated plan before coding.

Implementation plan:
- Specify files or surfaces to change.
- Specify expected behavior change.
- List risky assumptions and how verification will validate each one.

Verification plan:
- State the chosen verification profile.
- List exact command(s) per step, with execution location (`local`, `docker`, `ssh`).
- For each acceptance criterion, define a discriminating check: `H1`, `H0`, observable, and decision rule.
- Include a Ground-Truth Plan: selected ladder rung, source, acquisition method, sample size, metrics, thresholds, and artifact location.
- Set initial target evidence tier to `Gold` and estimate its runtime.
- If estimated Gold total is 10 minutes or less, run Gold.
- If estimated Gold total exceeds 10 minutes, pause and ask the user with exactly 3 concise options: `Bronze`, `Silver`, `Gold`.
- Bronze and Silver must still be real end-to-end operator-path verification.
- Initialize the run scaffold and manifest before substantial execution when practical.

### Phase P2: Implement -> Run -> Inspect -> Fix

Loop until terminal state:
- Implement minimal changes.
- Run planned verification.
- Update the manifest with every meaningful command, signal, artifact, and failure.
- Inspect evidence with at least one correlation step.
- Try to falsify your own claim with a control or counterexample for non-trivial criteria.
- Execute ground-truth checks and retain inputs and outputs as artifacts.
- Tear down all verification-spawned instances and prove teardown with a post-cleanup check.
- If failing, summarize observed failure signals, adjust code or probes, and rerun.

### Phase P3: Closeout

Produce:
- Verification Manifest using `references/verification-manifest-template.json`.
- Verification Report using `references/report-template.md`.
- Verification Certificate using `references/certificate-template.md`.
- Verification Brief using `references/verification-brief-template.md`.

Validation order:
1. Validate the manifest.
2. Validate the report.
3. Render the Verification Brief.
4. Render the Human Verification Card when terminal state is `READY FOR HUMAN VERIFICATION 🧑‍🔬`.

Closeout rules:
- If no manifest validator is found at either location, treat closeout as `BLOCKED ⛔`.
- If no report validator is found at either location, treat closeout as `BLOCKED ⛔`.
- If VDD tooling fails before normal closeout is possible, enter Skill Failover Mode.
- Always render the Verification Certificate block directly in the final chat response.
- In the report markdown, place `## Verification Brief How YOU Can Run This` below `## Verification Certificate`.
- In the final chat response, place `How YOU Can Run This` immediately below the Verification Certificate block.
- Include the Artifact Index, Command Ownership summary, and Cleanup summary in the report.

## Verification Policy

Must:
- Execute behavior through the same path a careful human would execute.
- Collect concrete evidence and perform light introspection.
- Map each acceptance criterion to at least one artifact-backed signal.
- Prefer “show, don’t tell” artifacts: screenshots, charts, tables, logs, trace files, or structured outputs.
- Use smoke checks only as preflight; they do not count as Bronze, Silver, or Gold evidence.
- Stop verification-spawned instances before closeout and prove teardown with at least one check.

### Scientific Mindset (Lean)

Treat verification like a small experiment:
- Always identify `H1` versus `H0`.
- Evidence must discriminate `H1` from `H0` via an observable and a decision rule.
- Prefer direct observables over proxy metrics.
- For noisy signals, measure a baseline or negative control before trusting the effect.
- When evidence includes images, video, or UI screenshots, use vision capabilities to extract semantic observables and corroborate them when they are load-bearing.
- If the measurement cannot distinguish `H1` from `H0`, do not claim `VERIFIED ✅`.

Forbidden:
- Source-text checks as stand-ins for behavior validation.
- Success claims without executed commands and observed outputs.
- Bare success assertions without artifacts or concrete data signals.
- Asking the human to run commands the agent has not attempted.

## UI Automation Protocol (Playwright)

Apply this whenever acceptance criteria mention UI behavior, click flow, visibility changes, or browser-driven interactions.

Use `references/ui-automation-protocol.md` as the source of truth for:
- preflight command order
- browser-path signals that count
- harness location rules
- cleanup requirements

## Static-Only Exception (Strict)

Treat static-only verification as rare exception handling.

Rule:
- Do not switch to static-only verification silently.
- Ask the user first, explain why runtime verification is unavailable or inappropriate, and list the proposed static checks.
- Continue only after explicit user approval.

Default result for approved static-only exception:
- Emit `READY FOR HUMAN VERIFICATION 🧑‍🔬`, unless the user explicitly accepts static-only evidence for `VERIFIED ✅`.

## Time Estimation Policy

- Estimate every verification step and total expected duration.
- Estimate a Gold plan first and state the total explicitly.
- If Gold total is 10 minutes or less, run Gold.
- If Gold total exceeds 10 minutes, ask the user to choose Bronze, Silver, or Gold before running verification.
- Report estimated versus actual timing in closeout.

## Probes and Artifacts

Before writing artifacts under `.agent/`, resolve this helper:
1. `<active-repo>/scripts/ensure-agent-ignore.sh`
2. `<skill-root>/scripts/ensure-agent-ignore.sh`

Artifact rules:
- Prefer `.git/info/exclude` by default so `.agent` scaffolding does not become a tracked diff accidentally.
- Edit `.gitignore` only when the repository intentionally wants `.agent` ignored for everyone.
- Use `.agent/probes/` for reusable probes.
- Use `.agent/probes/ui/` for browser harnesses.
- Use `.agent/runs/<timestamp>/` for reports, manifests, and run-local evidence.
- Use `.agent/ground-truth/` for datasets, baselines, and evaluation summaries.

## Secrets and Remote Access

- Source secrets from environment variables or SSH environment.
- Never embed secrets in code or commits.
- Never auto-edit `agent.md`; propose edits and ask first.

## Required Reference Files

Load as needed:
- `references/report-template.md`
- `references/certificate-template.md`
- `references/verification-brief-template.md`
- `references/verification-manifest-template.json`
- `references/closeout-policy.md`
- `references/evidence-tiers.md`
- `references/ground-truth-ladder.md`
- `references/human-verification-card-template.md`
- `references/ui-automation-protocol.md`
- `references/examples.md`
- `references/profile-api-service.md`
- `references/profile-ui-browser.md`
- `references/profile-data-pipeline.md`
- `references/profile-ml-model.md`
- `references/profile-deploy-infra.md`
- `references/profile-library-refactor.md`
- `references/profile-remote-ssh.md`
