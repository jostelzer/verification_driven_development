#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-vdd-run.sh [run_id]

Description:
  Creates a run directory under .agent/runs and seeds verification-report.md
  from the canonical report template.

Arguments:
  run_id  Optional run identifier. Default: current timestamp YYYYMMDD-HHMMSS
USAGE
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -gt 1 ]; then
  usage
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
RUN_ID="${1:-$(date +%Y%m%d-%H%M%S)}"
RUN_DIR="$REPO_ROOT/.agent/runs/$RUN_ID"
REPORT_MD="$RUN_DIR/verification-report.md"
TEMPLATE_MD="$REPO_ROOT/verification-driven-development/references/report-template.md"
GITIGNORE="$REPO_ROOT/.gitignore"

if [ ! -f "$TEMPLATE_MD" ]; then
  echo "error: report template not found: $TEMPLATE_MD" >&2
  exit 1
fi

if [ -e "$REPORT_MD" ]; then
  echo "error: report already exists: $REPORT_MD" >&2
  exit 1
fi

mkdir -p "$RUN_DIR"
cp "$TEMPLATE_MD" "$REPORT_MD"

if [ -f "$GITIGNORE" ] && ! grep -Eq '^\.agent/?$' "$GITIGNORE"; then
  echo "warning: .agent is not ignored in .gitignore; add '.agent' to avoid committing run artifacts" >&2
fi

cat <<NEXT
Initialized VDD run scaffold
- Run ID: $RUN_ID
- Report: $REPORT_MD

Next commands:
./scripts/validate-vdd-report.sh "$REPORT_MD"
./scripts/render-verification-brief.sh "$REPORT_MD"
make report-closeout INPUT="$REPORT_MD"
NEXT
