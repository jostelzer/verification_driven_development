# Verification Certificate Templates

Issue exactly one certificate at terminal state.

## VERIFIED ✅

```text
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ VERIFICATION CERTIFICATE — VGC (FINAL)            ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Verdict      : VERIFIED ✅                         ┃
┃ Task         : <task summary>                      ┃
┃ Revision     : <commit/sha/working-tree marker>   ┃
┃ Runtime      : <local/docker/ssh host>            ┃
┃ Est / Actual : <estimate> / <actual>              ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Evidence Digest (strongest signals)               ┃
┃  • <signal 1>                                     ┃
┃  • <signal 2>                                     ┃
┃  • <signal 3>                                     ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃ Artifacts (paths)                                 ┃
┃  • .agent/runs/<timestamp>/...                    ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## READY FOR HUMAN VERIFICATION 🧑‍🔬

Use same box with:
- `Verdict: READY FOR HUMAN VERIFICATION 🧑‍🔬`
- Harness command(s): one-command launch when possible.
- Human checklist: actions and expected outcomes.
- Return package: logs/screenshot/video/exported state required from user.

## BLOCKED ⛔

Use same box with:
- `Verdict: BLOCKED ⛔`
- Missing requirements: runtime/access/instructions.
- Minimal unblock questions.
