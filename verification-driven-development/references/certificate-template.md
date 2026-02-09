# Verification Certificate Template

Issue exactly one certificate at terminal state.
Keep it concise but explicit: target 10 to 16 lines.

## VERIFIED ✅

```markdown
## Verification Certificate
Verdict: VERIFIED ✅
Task: <one-line task summary>
Revision: <commit sha or working-tree marker>
Runtime: <local | docker | ssh host>
Empirical verification efforts performed:
- <exact command/action run, what input/scope it used, and observed pass outcome>
- <second command/action run, what it covered, and observed pass outcome>
Evidence gathered:
- <concrete observation #1: values, response fields, log/result signal>
- <concrete observation #2: values, metrics, or absence of errors/regressions>
Why this evidence is convincing:
- <map acceptance criterion to specific observed evidence>
- <briefly state what false-positive/risk was ruled out>
```

## READY FOR HUMAN VERIFICATION 🧑‍🔬

```markdown
## Verification Certificate
Verdict: READY FOR HUMAN VERIFICATION 🧑‍🔬
Task: <one-line task summary>
What was empirically verified by agent: <short summary of exact checks run>
Evidence gathered by agent: <concrete observations from those checks>
Why this is not yet conclusive: <what still requires human interaction or access>
Run this harness: <command(s)>
Human checks:
- <action and expected outcome>
- <action and expected outcome>
How human evidence will confirm completion: <what result would close remaining risk>
```

## BLOCKED ⛔

```markdown
## Verification Certificate
Verdict: BLOCKED ⛔
Task: <one-line task summary>
Empirical attempts performed: <exact commands/actions run>
Evidence gathered from attempts: <key errors/signals observed>
Why verification remains inconclusive: <what cannot be validated yet>
Blocked by: <missing runtime/access/instructions>
Unblock by:
- <minimal question 1>
- <minimal question 2>
```
