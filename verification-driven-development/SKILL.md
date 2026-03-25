---
name: verification-driven-development
description: >-
  Verification-first coding workflow (VDD) that keeps the hard requirement on
  executed checks and observed evidence, while staying lightweight on ritual
  and paperwork. Use for feature, bugfix, integration, service, deployment,
  and data-pipeline work where runtime behavior matters.
---

# Verification-Driven Development (VDD)

Enforce a proof gate, not a paperwork gate:
- Do not declare task completion without executed verification commands and observed evidence.
- Do not issue terminal-state certificates until verification is complete.
- Prefer semantic evidence over report theatrics: the manifest, artifacts, and observed signals are the source of truth.
- Use the lightest plan and closeout structure that still makes the result believable and reproducible.

## Core Invariants

Always:
- Execute the real operator path whenever practical.
- Collect enough evidence to distinguish `H1` (the claim) from `H0` (no change or a plausible confounder).
- Track resources you start and prove cleanup before any terminal state.
- Treat SSH, containers, and browsers as first-class runtime surfaces, not exceptions.

## Runtime Surface (Mandatory)

Use common sense about the actual runtime surface instead of forcing a named profile.

Rules:
- Write checks that match the real path being changed: HTTP, CLI, browser, batch job, model inference, deployment, SSH, or a combination.
- If the critical evidence lives on a remote machine, plan for it explicitly and record commands with location `ssh`.
- If browser interaction matters, include at least one browser-path signal before calling the result conclusive.

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

Prefer rendering the Human Verification Card via:
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
- Ground-truth source or an explicit waiver when the task needs one.
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
- Record commands, observed signals, artifacts when present, criteria results, cleanup, and command ownership.
- Update the manifest during the loop, not only at the end.
- Keep artifact paths explicit and stable.
- Treat the manifest as stronger evidence than prose summary. The report and certificate must not contradict it.

Validate the manifest before validating the report:
1. `<active-repo>/scripts/validate-vdd-manifest.sh <manifest_json>`
2. `<skill-root>/scripts/validate-vdd-manifest.sh <manifest_json>`

## Terminal States

Use exactly one final state:
- `VERIFIED ✅`: implementation complete, executable verification passed, and evidence supports success.
- `READY FOR HUMAN VERIFICATION 🧑‍🔬`: implementation complete, the agent verified everything it could, and a human must complete the final discriminating step.
- `BLOCKED ⛔`: required runtime access, tooling, or instructions are missing after agent-side attempts.

Gates:
- UI gate for `VERIFIED ✅`: when acceptance criteria include browser-driven interaction, `VERIFIED ✅` requires at least one executed browser-path signal.
- Cleanup gate for all terminal states: if any spawned verification resource cannot be stopped, terminal state must be `BLOCKED ⛔`.

## Communication Style (Default: Compact)

Keep user-facing plans concise by default.
- Target 6 to 10 bullets total, or one compact table with up to 5 steps.
- Include only decisions that affect execution: change surface, commands, pass/fail signals, blockers, and timing.
- Expand detail only when the user asks for it or when ambiguity is high.

## Operating Loop (Mandatory)

### Phase P1: Joint Plan

Produce one integrated plan before coding.

Implementation plan:
- Specify files or surfaces to change.
- Specify expected behavior change.
- List risky assumptions and how verification will validate each one.

Verification plan:
- List exact command(s) per step, with execution location (`local`, `docker`, `ssh`).
- For each acceptance criterion, define a discriminating check: `H1`, `H0`, observable, and decision rule.
- Include a Ground-Truth Plan when a baseline, sample, or waiver is load-bearing.
- If verification cost or runtime is high, summarize the tradeoff and get user input before running the expensive path.
- Bronze/Silver/Gold can be used as planning shorthand, but they are optional aids, not mandatory ceremony.
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
- Verification Certificate inline in chat.
- Verification Brief rendered from the report.

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
- Apply the visual closeout conventions from `references/closeout-ux-guide.md`.
- Keep the report compact by default. Required content is commands, results by criterion, evidence, reproducibility, command ownership, cleanup, final state, and a matching manifest.
- If pictures or graphs are produced, embed them inline in the report and in the final chat response with the same local absolute filesystem paths instead of only listing their paths.
- If visual artifacts were produced over SSH or on another machine, copy them locally before embedding them in chat; remote filesystem paths do not render for the user.
- Include the Artifact Index, Command Ownership summary, and Cleanup summary in the report.

## Verification Policy

Must:
- Execute behavior through the same path a careful human would execute.
- Collect concrete evidence and perform light introspection.
- Map each acceptance criterion to at least one concrete signal.
- Prefer “show, don’t tell” artifacts: screenshots, charts, tables, logs, trace files, or structured outputs.
- Treat smoke checks as preflight unless they really are the operator path.
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

## Anti-Patterns

Before any terminal state, do a quick self-check against `references/anti-patterns.md`.

Use it to catch recurring VDD failures such as:
- tests or source inspection being treated as final proof
- pretty closeout structure with weak evidence underneath
- screenshot-only verdicts without corroboration
- remote runtimes being “verified” locally
- missing cleanup or missing controls

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
- Only escalate into tiered Bronze/Silver/Gold planning when that helps a real tradeoff discussion.
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
- `references/verification-manifest-template.json`
- `references/closeout-policy.md`
- `references/closeout-ux-guide.md`
- `references/evidence-tiers.md`
- `references/ground-truth-ladder.md`
- `references/anti-patterns.md`
- `references/ui-automation-protocol.md`
- `references/examples.md`
