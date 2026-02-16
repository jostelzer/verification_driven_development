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
- Operator-facing run steps must use real product entrypoints (CLI/API/UI), not ad-hoc probe scripts created during the run.
- Do not point humans to ephemeral harness files under `.agent/runs/` or `/tmp/`, or to `playwright_*.js`/`*_check.js`/`*.spec.js` scripts.
- A compact **Human Verification Card** in this exact order:
1. Preconditions (max 2 short lines).
2. Steps (numbered, copy/paste commands or clicks only).
3. Pass signal(s) (exact text/status/artifact expected).
4. Fail signal(s) (exact text/status/artifact expected).
5. Return condition (what to send back, and when to stop).
- Hard cap for the card: max 8 lines or 120 words, whichever is smaller.
- Style rules for the card: imperative voice, no hedging, no policy recap, no extra narrative.

## Skill Failover Mode (Mandatory)

Use failover mode when VDD tooling itself breaks (for example: validator crash, render script exception, missing required skill file, or internal instruction conflict).

Rules:
- Do not hide the failure and do not continue with normal closeout/certificate flow.
- Terminal state must be `BLOCKED ⛔`.
- Return a compact failover block that includes:
1. Error summary.
2. Exact failed command, execution location, and exit code.
3. Stack trace in a fenced `text` block.
4. Prefilled GitHub issue link for this skill repository.
5. Copy/paste-ready issue body.
- Generate failover issue content using this resolver order:
1. `<active-repo>/scripts/render-vdd-failover-issue.sh ...`
2. `<skill-root>/scripts/render-vdd-failover-issue.sh ...`
- If neither script exists, manually provide:
  - `https://github.com/jostelzer/verification_driven_development/issues/new`
  - issue title, summary, command, exit code, and full stack trace body for user copy/paste.

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
- UI gate for `VERIFIED ✅`: when acceptance criteria include UI behavior/click flow, `VERIFIED ✅` requires at least one executed browser-path signal; unit tests and static checks alone are insufficient.
- If implementation is complete but the UI gate cannot be satisfied after reasonable agent-side attempts, emit `READY FOR HUMAN VERIFICATION 🧑‍🔬` with a real CLI/API/UI checklist.

## Communication Style (Default: Compact)

Keep user-facing plans concise by default.
- Target 6 to 10 bullets total, or one compact table with up to 5 steps.
- Include only decisions that affect execution: change surfaces, commands, pass/fail signals, blockers, and timing.
- Avoid restating policy text or obvious repository context.
- Expand detail only when the user asks for it or when risk/ambiguity is high.
- For `READY FOR HUMAN VERIFICATION 🧑‍🔬`, always provide the Human Verification Card format above (precise and concise by construction).

## Operating Loop (Mandatory)

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
- For each acceptance criterion, design a discriminating check: state `H1` (the claim) vs `H0` (a plausible alternative / "no change"), the observable (with units), and the decision rule (threshold).
- Include a Ground-Truth Plan: source, acquisition method, sample size, metric(s), threshold(s), and artifact location.
- Choose a target evidence tier (`Bronze` | `Silver` | `Gold`) using `references/evidence-tiers.md`, and state why that tier is appropriate.
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
- Try to falsify your own claim: include at least one control/counterexample check for non-trivial criteria (noisy metrics, visuals, UI flows, performance) so evidence can distinguish `H1` from `H0`.
- Execute ground-truth checks and retain inputs/outputs as artifacts.
- If failing, summarize observed failure signals (not guesses), adjust code/probes, and rerun.

### Phase P3: Closeout

Produce:
- Verification Report using `references/report-template.md`.
- Verification Certificate using `references/certificate-template.md`.
- Verification Brief using `references/verification-brief-template.md` (sections: Claim, Evidence, How YOU Can Run This).
- Validate report format before terminal output by resolving the validator in this order:
  1. `<active-repo>/scripts/validate-vdd-report.sh <report_md>` (project-local copy).
  2. `<skill-root>/scripts/validate-vdd-report.sh <report_md>` (bundled with this skill; `<skill-root>` is the directory containing this `SKILL.md`).
- If no validator is found at either location, treat closeout as `BLOCKED ⛔` and report the missing file/setup issue explicitly (no fallback validation note).
- If VDD tooling fails before normal closeout is possible, enter Skill Failover Mode and include issue link + stack trace payload.
- Always render the Verification Certificate block directly in the final chat response (user-visible), not only in `.md` artifacts.
- In the report markdown, place `## Verification Brief How YOU Can Run This` below `## Verification Certificate`.
- In the final chat response, place `How YOU Can Run This` immediately below the Verification Certificate block.
- Artifact index with links/paths to evidence and one line per artifact stating what it proves.
- Explicit command ownership summary: what the agent ran, what failed, and why any remaining human step was unavoidable.
- For UI tasks, include a mandatory browser assertion summary (step entered, button visible/hidden, request fired/not fired) with artifact path.
- Apply closeout defaults and formatting rules from `references/closeout-policy.md`.

## Verification Policy

Must:
- Execute behavior through the same path a careful human would execute.
- Collect concrete evidence and perform light introspection.
- Keep verification practical; escalate to human verification when interaction is required.
- Prefer a "show, don't tell" style: screenshots, charts, structured metrics/tables, audio captures, or similarly data-rich artifacts that can be included in chat.
- Map each acceptance criterion to at least one artifact-backed signal.
- Use sanity checks only as preflight; they are not sufficient for `VERIFIED ✅` without an explicit, documented user waiver.

Evidence tiers (aim for the highest feasible tier) are defined in `references/evidence-tiers.md`.

### Scientific Mindset (Lean)

Treat verification like a small experiment, not a pile of artifacts.
- Always identify the competing explanation: `H1` (your claim) versus `H0` ("no change" or a plausible confounder).
- Evidence must discriminate `H1` from `H0` via an observable and a decision rule; artifacts without a decision rule are not evidence.
- Prefer direct observables (state, telemetry, invariants). If using a proxy metric, justify why it tracks the observable.
- For noisy signals, calibrate quickly: measure a "no-change" baseline (negative control) and repeat enough to estimate a noise floor.
- When evidence includes images/video/UI screenshots, use your vision capabilities to extract semantic observables (text, object presence/positions, UI state) instead of relying only on pixel diffs. Treat vision-derived signals as proxies: corroborate with state/logs or programmatic detectors when feasible, calibrate with a simple "no-change" control when noise is plausible, and prefer `INCONCLUSIVE` over overconfident interpretation when ambiguity remains.
- If the measurement cannot distinguish `H1` from `H0`, do not claim `VERIFIED ✅`; redesign the check or escalate to `READY FOR HUMAN VERIFICATION 🧑‍🔬`.

Allowed:
- Temporary probes, debug flags, and one-off scripts.
- Early smoke probes plus full verification.

Forbidden:
- Source-text checks as stand-ins for behavior validation.
- Success claims without executed commands and observed outputs.
- Bare success assertions (for example, "it worked") without artifacts or concrete data signals.
- Asking the human to run commands the agent has not attempted.
- Asking the human to run commands when the blocker is permissions that should be handled via full-access/escalated execution.
- Providing "How YOU Can Run This" steps that rely on temporary probe/test scripts instead of the real operator workflow.

## UI Automation Protocol (Playwright)

Apply this protocol whenever acceptance criteria mention UI behavior, click flow, visibility changes, or browser-driven interactions.

Use `references/ui-automation-protocol.md` as the source of truth for:
- Mandatory preflight command order.
- Decision tree and fallback behavior.
- Harness location rules and cleanup requirements.

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

Before writing artifacts under `.agent/`:
- Ensure the active repository ignores `.agent`.
- If the repo root `.gitignore` does not include `.agent` or `.agent/`, append `.agent`.
- If editing `.gitignore` is not allowed, add `.agent` to `.git/info/exclude` and record that fallback in the Verification Report.

Use `.agent/`:
- `.agent/probes/`
- `.agent/probes/ui/` for Playwright/browser-path harnesses.
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
- Verification brief format: `references/verification-brief-template.md`
- Closeout defaults and formatting rules: `references/closeout-policy.md`
- Evidence tier rubric: `references/evidence-tiers.md`
- UI preflight/decision tree: `references/ui-automation-protocol.md`
- Usage patterns and examples: `references/examples.md`
- Self-check checklist: `references/evaluation-checklist.md`
