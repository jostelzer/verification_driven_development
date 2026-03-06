#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

VALID_REPORT="$REPO_ROOT/tests/fixtures/reports/valid-report.md"
VALID_INLINE_VISUAL_TEMPLATE="$REPO_ROOT/tests/fixtures/reports/valid-inline-visual-report.md"
INVALID_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-missing-final-state.md"
INVALID_BRIEF_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-brief-operator-flow.md"
INVALID_GOLD_GATE_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-gold-gate.md"
INVALID_CLEANUP_REPORT="$REPO_ROOT/tests/fixtures/reports/invalid-cleanup-status.md"
INVALID_INLINE_VISUAL_TEMPLATE="$REPO_ROOT/tests/fixtures/reports/invalid-inline-visual-report.md"

VALID_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/valid-manifest.json"
READY_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/ready-manifest.json"
INVALID_GOLD_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/invalid-auto-gold-manifest.json"
INVALID_CLEANUP_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/invalid-cleanup-manifest.json"
INVALID_READY_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/invalid-ready-no-human-manifest.json"
INVALID_REMOTE_SSH_MANIFEST="$REPO_ROOT/tests/fixtures/manifests/invalid-remote-ssh-manifest.json"

ROOT_REPORT_VALIDATOR="$REPO_ROOT/scripts/validate-vdd-report.sh"
ROOT_MANIFEST_VALIDATOR="$REPO_ROOT/scripts/validate-vdd-manifest.sh"
ROOT_BRIEF_RENDERER="$REPO_ROOT/scripts/render-verification-brief.sh"
ROOT_CARD_RENDERER="$REPO_ROOT/scripts/render-human-verification-card.sh"

BUNDLED_REPORT_VALIDATOR="$REPO_ROOT/verification-driven-development/scripts/validate-vdd-report.sh"
BUNDLED_MANIFEST_VALIDATOR="$REPO_ROOT/verification-driven-development/scripts/validate-vdd-manifest.sh"
BUNDLED_BRIEF_RENDERER="$REPO_ROOT/verification-driven-development/scripts/render-verification-brief.sh"
BUNDLED_CARD_RENDERER="$REPO_ROOT/verification-driven-development/scripts/render-human-verification-card.sh"
BUNDLED_INIT_RUN="$REPO_ROOT/verification-driven-development/scripts/init-vdd-run.sh"

FAILOVER_STACKTRACE="$REPO_ROOT/tests/fixtures/errors/vdd-stacktrace.txt"
FAILOVER_RENDERER="$REPO_ROOT/scripts/render-vdd-failover-issue.sh"
VISUAL_ARTIFACT="$REPO_ROOT/tests/fixtures/artifacts/latency-chart.svg"

TMP_OUT="$(mktemp)"
TMP_CARD="$(mktemp)"
TMP_FAILOVER="$(mktemp)"
TMP_VALID_INLINE_VISUAL_REPORT="$(mktemp)"
TMP_INVALID_INLINE_VISUAL_REPORT="$(mktemp)"
TMP_RELATIVE_INLINE_VISUAL_REPORT="$(mktemp)"
TMP_REPO="$(mktemp -d)"
cleanup() {
  rm -f "$TMP_OUT" "$TMP_CARD" "$TMP_FAILOVER" "$TMP_VALID_INLINE_VISUAL_REPORT" "$TMP_INVALID_INLINE_VISUAL_REPORT" "$TMP_RELATIVE_INLINE_VISUAL_REPORT"
  rm -rf "$TMP_REPO"
}
trap cleanup EXIT

for path in \
  "$ROOT_REPORT_VALIDATOR" \
  "$ROOT_MANIFEST_VALIDATOR" \
  "$ROOT_BRIEF_RENDERER" \
  "$ROOT_CARD_RENDERER" \
  "$BUNDLED_REPORT_VALIDATOR" \
  "$BUNDLED_MANIFEST_VALIDATOR" \
  "$BUNDLED_BRIEF_RENDERER" \
  "$BUNDLED_CARD_RENDERER" \
  "$BUNDLED_INIT_RUN"
do
  if [ ! -f "$path" ]; then
    echo "error: required script missing: $path" >&2
    exit 1
  fi
done

"$ROOT_REPORT_VALIDATOR" --help >/dev/null
"$ROOT_MANIFEST_VALIDATOR" --help >/dev/null
"$ROOT_BRIEF_RENDERER" --help >/dev/null
"$ROOT_CARD_RENDERER" --help >/dev/null
"$BUNDLED_REPORT_VALIDATOR" --help >/dev/null
"$BUNDLED_MANIFEST_VALIDATOR" --help >/dev/null
"$BUNDLED_BRIEF_RENDERER" --help >/dev/null
"$BUNDLED_CARD_RENDERER" --help >/dev/null
"$BUNDLED_INIT_RUN" --help >/dev/null

"$ROOT_MANIFEST_VALIDATOR" "$VALID_MANIFEST" >/dev/null
"$BUNDLED_MANIFEST_VALIDATOR" "$VALID_MANIFEST" >/dev/null
"$ROOT_REPORT_VALIDATOR" "$VALID_REPORT" >/dev/null
"$BUNDLED_REPORT_VALIDATOR" "$VALID_REPORT" >/dev/null

sed "s|__VISUAL_PATH__|$VISUAL_ARTIFACT|g" "$VALID_INLINE_VISUAL_TEMPLATE" > "$TMP_VALID_INLINE_VISUAL_REPORT"
sed "s|__VISUAL_PATH__|$VISUAL_ARTIFACT|g" "$INVALID_INLINE_VISUAL_TEMPLATE" > "$TMP_INVALID_INLINE_VISUAL_REPORT"
sed "s|__VISUAL_PATH__|tests/fixtures/artifacts/latency-chart.svg|g" "$VALID_INLINE_VISUAL_TEMPLATE" > "$TMP_RELATIVE_INLINE_VISUAL_REPORT"

"$ROOT_REPORT_VALIDATOR" "$TMP_VALID_INLINE_VISUAL_REPORT" >/dev/null
"$BUNDLED_REPORT_VALIDATOR" "$TMP_VALID_INLINE_VISUAL_REPORT" >/dev/null

if "$ROOT_MANIFEST_VALIDATOR" "$INVALID_GOLD_MANIFEST" >/dev/null 2>&1; then
  echo "error: expected manifest validator failure for invalid Gold gate fixture" >&2
  exit 1
fi

if "$ROOT_MANIFEST_VALIDATOR" "$INVALID_CLEANUP_MANIFEST" >/dev/null 2>&1; then
  echo "error: expected manifest validator failure for invalid cleanup fixture" >&2
  exit 1
fi

if "$ROOT_MANIFEST_VALIDATOR" "$INVALID_READY_MANIFEST" >/dev/null 2>&1; then
  echo "error: expected manifest validator failure for missing human verification card fixture" >&2
  exit 1
fi

if "$ROOT_MANIFEST_VALIDATOR" "$INVALID_REMOTE_SSH_MANIFEST" >/dev/null 2>&1; then
  echo "error: expected manifest validator failure for remote-ssh fixture without ssh command" >&2
  exit 1
fi

if "$ROOT_REPORT_VALIDATOR" "$INVALID_REPORT" >/dev/null 2>&1; then
  echo "error: expected report validator failure for invalid fixture: $INVALID_REPORT" >&2
  exit 1
fi

if "$ROOT_REPORT_VALIDATOR" "$INVALID_GOLD_GATE_REPORT" >/dev/null 2>&1; then
  echo "error: expected report validator failure for invalid Gold gate fixture: $INVALID_GOLD_GATE_REPORT" >&2
  exit 1
fi

if "$ROOT_REPORT_VALIDATOR" "$INVALID_CLEANUP_REPORT" >/dev/null 2>&1; then
  echo "error: expected report validator failure for invalid cleanup fixture: $INVALID_CLEANUP_REPORT" >&2
  exit 1
fi

if "$ROOT_REPORT_VALIDATOR" "$TMP_INVALID_INLINE_VISUAL_REPORT" >/dev/null 2>&1; then
  echo "error: expected report validator failure for invalid inline visual fixture" >&2
  exit 1
fi

if "$ROOT_REPORT_VALIDATOR" "$TMP_RELATIVE_INLINE_VISUAL_REPORT" >/dev/null 2>&1; then
  echo "error: expected report validator failure for relative inline visual path fixture" >&2
  exit 1
fi

"$ROOT_BRIEF_RENDERER" "$VALID_REPORT" > "$TMP_OUT"

if ! grep -q '^## Verification Brief$' "$TMP_OUT"; then
  echo "error: rendered verification brief missing header" >&2
  exit 1
fi

if ! grep -q '^How YOU Can Run This:$' "$TMP_OUT"; then
  echo "error: rendered verification brief missing run section" >&2
  exit 1
fi

if "$ROOT_BRIEF_RENDERER" "$INVALID_BRIEF_REPORT" >/dev/null 2>&1; then
  echo "error: expected render-verification-brief failure for invalid operator-flow fixture" >&2
  exit 1
fi

"$ROOT_CARD_RENDERER" "$READY_MANIFEST" > "$TMP_CARD"
if ! grep -q '^## Human Verification Card$' "$TMP_CARD"; then
  echo "error: rendered human verification card missing header" >&2
  exit 1
fi
if ! grep -q '^Operator Notes:$' "$TMP_CARD"; then
  echo "error: rendered human verification card missing operator notes section" >&2
  exit 1
fi

git -C "$TMP_REPO" init >/dev/null
"$BUNDLED_INIT_RUN" fixture-run --repo-root "$TMP_REPO" >/dev/null

if [ ! -f "$TMP_REPO/.agent/runs/fixture-run/verification-report.md" ]; then
  echo "error: init-vdd-run did not create verification-report.md" >&2
  exit 1
fi
if [ ! -f "$TMP_REPO/.agent/runs/fixture-run/verification-manifest.json" ]; then
  echo "error: init-vdd-run did not create verification-manifest.json" >&2
  exit 1
fi
if ! grep -q '^\.agent$' "$TMP_REPO/.git/info/exclude"; then
  echo "error: init-vdd-run did not ensure .agent ignore rule" >&2
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
