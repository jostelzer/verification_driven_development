# Profile: UI Browser

Use for click flows, visibility state, navigation, forms, and visual regressions.

Prioritize:
- executed browser-path signals
- screenshot or trace artifacts
- one corroborating DOM, network, URL, or console signal
- explicit cleanup of browser and temporary servers

Good artifacts:
- screenshots
- Playwright traces
- network logs
- DOM assertions tied to visible behavior

Common `H0`:
- backend behavior changed but the user-visible interaction path did not
