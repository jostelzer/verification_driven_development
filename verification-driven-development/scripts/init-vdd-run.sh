#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verification-driven-development/scripts/init-vdd-run.sh [run_id] [--repo-root <path>]

Description:
  Creates a run directory under `.agent/runs/<run_id>` and seeds:
    - verification-report.md
    - verification-manifest.json

  The active repository defaults to the current working directory. Run this from
  the repo you are verifying, not from the skill directory.
EOF
}

RUN_ID=""
REPO_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-root)
      REPO_ARG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -n "$RUN_ID" ]; then
        echo "error: unexpected extra argument: $1" >&2
        usage >&2
        exit 2
      fi
      RUN_ID="$1"
      shift
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: required command not found: python3" >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="${REPO_ARG:-$PWD}"
if git -C "$REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$REPO_ROOT" rev-parse --show-toplevel)"
else
  REPO_ROOT="$(cd -- "$REPO_ROOT" && pwd)"
fi

RUN_ID="${RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
RUN_DIR="$REPO_ROOT/.agent/runs/$RUN_ID"
REPORT_MD="$RUN_DIR/verification-report.md"
MANIFEST_JSON="$RUN_DIR/verification-manifest.json"
REPORT_TEMPLATE="$SKILL_ROOT/references/report-template.md"
MANIFEST_TEMPLATE="$SKILL_ROOT/references/verification-manifest-template.json"

if [ ! -f "$REPORT_TEMPLATE" ]; then
  echo "error: report template not found: $REPORT_TEMPLATE" >&2
  exit 1
fi

if [ ! -f "$MANIFEST_TEMPLATE" ]; then
  echo "error: manifest template not found: $MANIFEST_TEMPLATE" >&2
  exit 1
fi

if [ -e "$REPORT_MD" ] || [ -e "$MANIFEST_JSON" ]; then
  echo "error: run scaffold already exists in $RUN_DIR" >&2
  exit 1
fi

mkdir -p "$RUN_DIR"
cp "$REPORT_TEMPLATE" "$REPORT_MD"
cp "$MANIFEST_TEMPLATE" "$MANIFEST_JSON"

python3 - "$REPORT_MD" "$MANIFEST_JSON" "$RUN_DIR" "$RUN_ID" <<'PY'
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
run_dir = sys.argv[3]
run_id = sys.argv[4]

replacements = {
    "RUN_ID_PLACEHOLDER": run_id,
    "RUN_DIR_PLACEHOLDER": run_dir,
    "REPORT_PATH_PLACEHOLDER": str(report_path),
    "MANIFEST_PATH_PLACEHOLDER": str(manifest_path),
}

for path in (report_path, manifest_path):
    text = path.read_text(encoding="utf-8")
    for old, new in replacements.items():
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")
PY

IGNORE_NOTE="not a git repository; .agent ignore not updated"
if git -C "$REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
  IGNORE_NOTE="$("$SCRIPT_DIR/ensure-agent-ignore.sh" "$REPO_ROOT" 2>&1 || true)"
fi

cat <<NEXT
Initialized VDD run scaffold
- Run ID: $RUN_ID
- Repository: $REPO_ROOT
- Manifest: $MANIFEST_JSON
- Report: $REPORT_MD
- Ignore handling: $IGNORE_NOTE

Next commands:
./scripts/validate-vdd-manifest.sh "$MANIFEST_JSON"
./scripts/validate-vdd-report.sh "$REPORT_MD"
./scripts/render-verification-brief.sh "$REPORT_MD"
NEXT
