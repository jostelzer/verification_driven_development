# Verification Certificate Template

Issue exactly one certificate at terminal state.
The certificate should summarize empirical proof, not process narration.

## VERIFIED ✅

```markdown
## 🏅 Verification Certificate
Status: VERIFIED
✅ <short proof 1 tied to an observable or artifact>
✅ <short proof 2 tied to an observable or artifact>
```

## READY FOR HUMAN VERIFICATION 🧑‍🔬

```markdown
## 🏅 Verification Certificate
Status Badge: 🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬
Verdict: READY FOR HUMAN VERIFICATION 🧑‍🔬
Task: <one-line task summary>
What was empirically verified by agent: <short summary of exact checks run>
Evidence gathered by agent: <concrete observations from those checks>
Artifact index: <path/link(s) + what each artifact proves>
Ground-Truth Gap: <what ground-truth data or comparison is missing or waived>
Why this is not yet conclusive: <what still requires human interaction or access>
Run this harness: <real CLI/API/UI command(s)>
Human checks:
- <action and expected outcome>
- <action and expected outcome>
How human evidence will confirm completion: <what result would close remaining risk>
```

## BLOCKED ⛔

```markdown
## 🏅 Verification Certificate
Status Badge: 🟥 BLOCKED ⛔
Verdict: BLOCKED ⛔
Task: <one-line task summary>
Empirical attempts performed: <exact commands/actions run>
Evidence gathered from attempts: <key errors/signals observed>
Why verification remains inconclusive: <what cannot be validated yet>
Blocked by: <missing runtime/access/instructions/tooling>
Unblock by:
- <minimal question 1>
- <minimal question 2>
```
