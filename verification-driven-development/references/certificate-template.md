# Verification Certificate Template

Issue exactly one certificate at terminal state.
Keep it concise but explicit: target 10 to 16 lines.

## VERIFIED ✅

```markdown
## Verification Certificate
Status Badge: 🟩 VERIFIED ✅ (GREEN FLAGS)
Verdict: VERIFIED ✅
Task: <one-line task summary>
Revision: <commit sha or working-tree marker>
Runtime: <local | docker | ssh host>
Green Flags:
- ✅ <command(s) run + scope + pass signal>
- ✅ <key evidence observed + value(s)>
Ground-Truth Evidence: <source + metric + threshold + result>
Artifacts:
- <path/link to screenshot/chart/audio/table + one line about what it proves>
Why this is convincing: <map acceptance criterion to evidence + risk ruled out>
```

## READY FOR HUMAN VERIFICATION 🧑‍🔬

```markdown
## Verification Certificate
Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬
Verdict: READY FOR HUMAN VERIFICATION 🧑‍🔬
Task: <one-line task summary>
What was empirically verified by agent: <short summary of exact checks run>
Evidence gathered by agent: <concrete observations from those checks>
Artifact index: <path/link(s) + what each artifact proves>
Ground-Truth Gap: <what ground-truth data or comparison is missing or waived>
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
Status Badge: 🟥 BLOCKED ⛔
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
