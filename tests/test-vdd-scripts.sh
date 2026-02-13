#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
VALID_REPORT="$REPO_ROOT/tests/fixtures/reports/valid-report.md"
INVALID_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-missing-final-state.md"
INVALID_BRIEF_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-brief-operator-flow.md"

TMP_OUT="$(mktemp)"
cleanup() {
  rm -f "$TMP_OUT"
}
trap cleanup EXIT

"$REPO_ROOT/scripts/validate-vdd-report.sh" "$VALID_REPORT" >/dev/null

if "$REPO_ROOT/scripts/validate-vdd-report.sh" "$INVALID_REPORT" >/dev/null 2>&1; then
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

echo "script tests passed"
