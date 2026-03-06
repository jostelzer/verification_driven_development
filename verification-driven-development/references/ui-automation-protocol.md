# UI Automation Protocol (Playwright)

Apply this protocol whenever acceptance criteria mention UI behavior, click flow, visibility changes, or browser-driven interactions.

## Mandatory UI Preflight

Run in this order:
1. `node -e "require.resolve('@playwright/test')" || npm install --prefix .agent/tools/pw @playwright/test@1.58.2`
2. `NODE_PATH=.agent/tools/pw/node_modules node -e "require('playwright').chromium"`
3. `node .agent/tools/pw/node_modules/playwright/cli.js install chromium`
4. `NODE_PATH=.agent/tools/pw/node_modules node -e "require('playwright').chromium.launch({headless:true}).then(b=>b.close())"`

If preflight fails:
- capture the exact command and key error output
- continue fallback logic; do not stop at first failure

## Browser-Path Signals That Count

A browser-path signal is load-bearing only when the agent executed a real browser step and captured at least one corroborating signal:
- DOM or text state changed as expected
- URL or route changed as expected
- request or response fired as expected
- screenshot or trace matches the expected semantic state
- console or application log confirms the same transition

Unit tests and static checks alone do not satisfy the UI gate.

## Harness Rules

- Agent-run UI probes must live in `.agent/probes/ui/`.
- Name harnesses by behavior, not by timestamp.
- Capture at least one screenshot or trace artifact when the result matters.
- Record console errors and failed network requests when present.
- Prefer explicit waits tied to state, network, or text over arbitrary sleeps.

## Fallback Decision Tree

1. Try package preflight.
2. Try browser install.
3. Run the harness.
4. If still blocked after reasonable attempts, switch to `READY FOR HUMAN VERIFICATION 🧑‍🔬` and provide a real CLI/API/UI checklist.

## Cleanup Requirements

- Stop all UI verification-spawned instances: temporary servers, browsers, containers, tunnels, workers.
- Verify cleanup with at least one explicit post-cleanup signal.
- Record cleanup actions and cleanup status in the manifest and the report.
