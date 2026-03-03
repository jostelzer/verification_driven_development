# UI Automation Protocol (Playwright)

Apply this protocol whenever acceptance criteria mention UI behavior, click flow, visibility changes, or browser-driven interactions.

## Mandatory UI Preflight (Run In Order)

1. `node -e "require.resolve('@playwright/test')" || npm install --prefix .agent/tools/pw @playwright/test@1.58.2`
2. `NODE_PATH=.agent/tools/pw/node_modules node -e "require('playwright').chromium"`
3. `node .agent/tools/pw/node_modules/playwright/cli.js install chromium`
4. `NODE_PATH=.agent/tools/pw/node_modules node -e "require('playwright').chromium.launch({headless:true}).then(b=>b.close())"`

If preflight fails:
- Capture exact command plus key error output.
- Continue fallback logic; do not stop at first failure.

## Playwright Decision Tree

1. Try package preflight.
2. Try browser install.
3. Run harness.
4. If still blocked after reasonable attempts, switch to `READY FOR HUMAN VERIFICATION 🧑‍🔬` and provide a real CLI/API/UI checklist.

## Harness Location Rules

- Agent-run UI probes must live in `.agent/probes/ui/`.
- Do not use ad-hoc filenames in run folders for UI probes.

## Cleanup Requirements

- Stop all UI verification-spawned instances (temporary servers, browsers, containers, tunnels, workers) before closeout.
- Verify cleanup with at least one explicit post-cleanup signal (for example, port closed, process absent, container absent).
- Record cleanup actions and cleanup status in the Verification Report.
