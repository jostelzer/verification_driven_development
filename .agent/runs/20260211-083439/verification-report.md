Status Badge: 🟩 VERIFIED ✅

# Goal
Add Apache-2.0 licensing to the repository and extend installers to support Claude Code and Cursor, then prove behavior with executable verification.

# What Changed
- Added Apache License 2.0 text at `LICENSE`.
- Added Cursor rule template at `verification-driven-development/agents/cursor.mdc`.
- Extended `install.sh` targets to `claude`, `cursor`, and `all`.
- Added `--cursor-project` to `install.sh` for Cursor project-rule installation.
- Extended `uninstall.sh` targets to `claude`, `cursor`, and `all`.
- Added path safety checks for move/remove operations in install/uninstall scripts.
- Updated `README.md` with Codex/Claude/Cursor install instructions and uninstall examples.
- Added license section to `README.md`.

# Runtime
- Execution context: `local`.
- Host: `/Users/jjj/git/verification_driven_development`.
- Shell/runtime: `bash`.

# Ground-Truth Plan and Data
- Source: executable installer behavior in isolated environments that mimic user homes/projects.
- Acquisition: run install/uninstall script commands with sandboxed `HOME`, `CODEX_HOME`, and Cursor project directories.
- Sample size and selection: one complete install/uninstall cycle per target (`codex`, `claude`, `cursor`, `auto`, `all`) plus syntax checks.
- Metrics and thresholds:
  - Scripts parse (`bash -n`): required pass.
  - Install creates expected artifact(s) per target: required pass.
  - Uninstall removes expected artifact(s): required pass.
  - Auto-selection behavior follows documented precedence: required pass.
- Data/artifact location:
  - `.agent/runs/20260211-083439/verify-final.log`
  - `.agent/runs/20260211-083439/verify.log` (first failed run)
  - `.agent/runs/20260211-083439/verify-rerun.log` (second failed run)
- Waiver: none.

# Commands Run
```bash
# edit/inspection
sed -n '1,260p' install.sh
sed -n '1,260p' uninstall.sh
sed -n '1,260p' README.md

# verification runs
bash -n install.sh
bash -n uninstall.sh

# full multi-target executable checks (isolated HOME/CODEX_HOME and cursor project)
bash -lc '<script written to .agent/runs/20260211-083439/verify.log>'
bash -lc '<script written to .agent/runs/20260211-083439/verify-rerun.log>'
bash -lc '<script written to .agent/runs/20260211-083439/verify-final.log>'
```

# Standard Certificate
```markdown
## Verification Certificate
Status: 🟩 VERIFIED ✅
Green Flags: ✅ Apache-2.0 license and new installer targets were implemented | ✅ Executable install/uninstall checks passed for codex, claude, cursor, auto, and all
```

# Evidence and Inspection
- Signal 1: executable install/uninstall success for `codex`, `claude`, `cursor`, `auto`, and `all` in `verify-final.log` with `[ok]` creation/removal lines.
- Signal 2: Cursor install creates expected rule file and content check passes (`rg -n "Verification-Driven Development" .../verification-driven-development.mdc`).
- Signal 3: negative evidence and fix loop captured: first verification failed with `install.sh: line 166: SKILL_ROOTS[@]: unbound variable` for cursor target; scripts were patched (`declare -a` + guarded loops) and verification reran to passing state.

Artifacts:
- `.agent/runs/20260211-083439/verify-final.log` proves final all-target behavior is correct.
- `.agent/runs/20260211-083439/verify.log` proves first failing signal for root-cause traceability.
- `.agent/runs/20260211-083439/verify-rerun.log` proves second iteration and corrected understanding of auto behavior.
- `.agent/runs/20260211-083439/verification-certificate.md` stores issued certificate.

# Timing
- Estimated:
  - Design and edits: 6 min
  - Verification cycles: 6 min
  - Closeout artifacts: 2 min
  - Total: 14 min
- Actual:
  - Design and edits: ~7 min
  - Verification cycles (including two failing loops and fixes): ~10 min
  - Closeout artifacts: ~2 min
  - Total: ~19 min
- Note: exceeded 10 minutes due iterative failure/fix loops in verification.

# Known Limits
- Cursor support is implemented as a project rule file install (`<project>/.cursor/rules/...`) rather than a global Cursor setting injection.
- `shellcheck` was not available in this environment (`shellcheck_not_installed`).

# Final State
VERIFIED ✅
