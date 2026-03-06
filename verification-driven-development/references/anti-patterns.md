# VDD Anti-Patterns

Use this as a final self-check before any terminal state.

## 1. Tests As Proof

- Symptom: unit tests or static checks are presented as the main verification evidence.
- Why it fails: they often prove code shape or narrow behavior, not the real operator path.
- Better move: treat them as preflight and add a real runtime check.

## 2. Pretty Closeout, Weak Evidence

- Symptom: the report looks polished, but the evidence is only prose.
- Why it fails: formatting cannot compensate for missing observables.
- Better move: attach artifact-backed signals and decision rules.

## 3. Screenshot-Only Verdict

- Symptom: a visual result is accepted from screenshots alone.
- Why it fails: screenshots are easy to misread and often miss causal context.
- Better move: pair visuals with a corroborating DOM, log, network, or state signal.

## 4. No `H0`

- Symptom: the closeout explains only why the change seems good.
- Why it fails: without a competing explanation, the evidence may not discriminate anything.
- Better move: write down `H0` and include a control or falsification step.

## 5. Remote Runtime, Local Proof

- Symptom: decisive behavior lives on a remote host, but verification happened only locally.
- Why it fails: you may have proven the wrong environment.
- Better move: run at least one decisive command where the runtime actually lives.

## 6. Human Asked Too Early

- Symptom: the human is asked to run commands before the agent has attempted them.
- Why it fails: command ownership is broken and evidence quality drops.
- Better move: exhaust agent-side runnable options first and show what failed.

## 7. Missing Cleanup

- Symptom: the change looks verified, but spawned processes, containers, or tunnels are still running.
- Why it fails: leftover state can fake success and pollute later runs.
- Better move: teardown explicitly and prove teardown with a post-cleanup check.

## 8. No Ground Truth

- Symptom: a claim is accepted without a baseline, sample, reference output, or explicit waiver.
- Why it fails: you cannot tell whether the result is actually better or just different.
- Better move: pick the strongest feasible rung from the ground-truth ladder.

## 9. Ad-Hoc Operator Flow

- Symptom: `How YOU Can Run This` points to temporary harness files or probe scripts.
- Why it fails: the user cannot reproduce the result through the real product entrypoint.
- Better move: use the real CLI, API, UI, or deployment path.

## 10. Gold In Name Only

- Symptom: Gold is claimed, but the evidence is really Bronze or Silver depth.
- Why it fails: tier labels lose meaning and users stop trusting the workflow.
- Better move: downgrade honestly or run the extra checks that Gold requires.
