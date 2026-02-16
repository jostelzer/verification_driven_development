#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VALID_REPORT="$REPO_ROOT/tests/fixtures/reports/valid-report.md"
INVALID_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-missing-final-state.md"
INVALID_BRIEF_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-brief-operator-flow.md"
ROOT_VALIDATOR="$REPO_ROOT/scripts/validate-vdd-report.sh"
BUNDLED_VALIDATOR="$REPO_ROOT/verification-driven-development/scripts/validate-vdd-report.sh"
FAILOVER_STACKTRACE="$REPO_ROOT/tests/fixtures/errors/vdd-stacktrace.txt"
FAILOVER_RENDERER="$REPO_ROOT/scripts/render-vdd-failover-issue.sh"

TMP_OUT="$(mktemp)"
TMP_FAILOVER="$(mktemp)"
cleanup() {
  rm -f "$TMP_OUT" "$TMP_FAILOVER"
}
trap cleanup EXIT

if [ ! -f "$ROOT_VALIDATOR" ]; then
  echo "error: root validator missing: $ROOT_VALIDATOR" >&2
  exit 1
fi

if [ ! -f "$BUNDLED_VALIDATOR" ]; then
  echo "error: bundled validator missing: $BUNDLED_VALIDATOR" >&2
  echo "debug: available files under verification-driven-development/scripts:" >&2
  ls -la "$REPO_ROOT/verification-driven-development/scripts" >&2 || true
  exit 1
fi

"$ROOT_VALIDATOR" --help >/dev/null
"$BUNDLED_VALIDATOR" --help >/dev/null

"$ROOT_VALIDATOR" "$VALID_REPORT" >/dev/null
"$BUNDLED_VALIDATOR" "$VALID_REPORT" >/dev/null

if "$ROOT_VALIDATOR" "$INVALID_REPORT" >/dev/null 2>&1; then
  echo "error: expected validator failure for invalid fixture: $INVALID_REPORT" >&2
  exit 1
fi

"$REPO_ROOT/scripts/render-verification-brief.sh" "$VALID_REPORT" > "$TMP_OUT"

if ! grep -q '^## Verification Brief$' "$TMP_OUT"; then
  echo "error: rendered verification brief missing header" >&2
  exit 1
fi

if ! grep -q '^How YOU Can Run This:$' "$TMP_OUT"; then
  echo "error: rendered verification brief missing run section" >&2
  exit 1
fi

if "$REPO_ROOT/scripts/render-verification-brief.sh" "$INVALID_BRIEF_REPORT" >/dev/null 2>&1; then
  echo "error: expected render-verification-brief failure for invalid operator-flow fixture" >&2
  exit 1
fi

"$FAILOVER_RENDERER" \
  --repo "owner/repo" \
  --title "VDD failover smoke test" \
  --summary "validator crashed during closeout" \
  --failed-command "./scripts/validate-vdd-report.sh .agent/runs/20260216-000000/verification-report.md" \
  --exit-code 1 \
  --stacktrace-file "$FAILOVER_STACKTRACE" \
  --max-stack-lines 3 \
  > "$TMP_FAILOVER"

if ! grep -q '^Issue Link:$' "$TMP_FAILOVER"; then
  echo "error: failover renderer output missing 'Issue Link:' header" >&2
  exit 1
fi

if ! grep -q '^https://github.com/owner/repo/issues/new?' "$TMP_FAILOVER"; then
  echo "error: failover renderer output missing expected prefilled issue URL" >&2
  exit 1
fi

if ! grep -q 'title=VDD%20failover%20smoke%20test' "$TMP_FAILOVER"; then
  echo "error: failover renderer output missing encoded title in issue URL" >&2
  exit 1
fi

if ! grep -q '^Issue Body (copy/paste):$' "$TMP_FAILOVER"; then
  echo "error: failover renderer output missing copy/paste body section" >&2
  exit 1
fi

if ! grep -q '\.\.\. \[truncated [0-9][0-9]* additional line(s)\]' "$TMP_FAILOVER"; then
  echo "error: failover renderer expected truncated stack trace marker" >&2
  exit 1
fi

echo "script tests passed"
