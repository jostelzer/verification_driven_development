#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/render-gist.sh <input_report_md> [output_gist_md]

Description:
  Extracts standardized chat gist content from a full verification report.
  Required report sections:
    - ## Gist Claim
    - ## Gist Evidence
    - ## Gist Human Run
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 2
fi

INPUT_REPORT_MD="$1"
OUTPUT_GIST_MD="${2:-}"

if [ ! -f "$INPUT_REPORT_MD" ]; then
  echo "error: input report markdown file does not exist: $INPUT_REPORT_MD" >&2
  exit 1
fi

extract_section() {
  local header_pattern="$1"
  awk -v pat="$header_pattern" '
    BEGIN { in_section=0 }
    $0 ~ pat { in_section=1; next }
    in_section && /^##[[:space:]]+/ { exit }
    in_section { print }
  ' "$INPUT_REPORT_MD"
}

trim_block() {
  awk '
    BEGIN { started=0; n=0 }
    {
      if (!started && $0 ~ /^[[:space:]]*$/) {
        next
      }
      started=1
      lines[++n]=$0
    }
    END {
      while (n > 0 && lines[n] ~ /^[[:space:]]*$/) {
        n--
      }
      for (i=1; i<=n; i++) {
        print lines[i]
      }
    }
  '
}

CLAIM_BLOCK="$(extract_section '^##[[:space:]]+Gist Claim' | trim_block)"
EVIDENCE_BLOCK="$(extract_section '^##[[:space:]]+Gist Evidence' | trim_block)"
HUMAN_RUN_BLOCK="$(extract_section '^##[[:space:]]+Gist Human Run' | trim_block)"

if [ -z "$CLAIM_BLOCK" ]; then
  echo "error: missing section content: ## Gist Claim" >&2
  exit 1
fi
if [ -z "$EVIDENCE_BLOCK" ]; then
  echo "error: missing section content: ## Gist Evidence" >&2
  exit 1
fi
if [ -z "$HUMAN_RUN_BLOCK" ]; then
  echo "error: missing section content: ## Gist Human Run" >&2
  exit 1
fi

CLAIM_LINE="$(printf '%s\n' "$CLAIM_BLOCK" | awk 'NF { print; exit }')"
CLAIM_LINE="${CLAIM_LINE#- }"
CLAIM_LINE="${CLAIM_LINE#Claim: }"
CLAIM_LINE="$(printf '%s' "$CLAIM_LINE" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

if [ -z "$CLAIM_LINE" ]; then
  echo "error: gist claim could not be parsed from ## Gist Claim" >&2
  exit 1
fi

evidence_bullets="$(printf '%s\n' "$EVIDENCE_BLOCK" | awk '/^- / { c++ } END { print c+0 }')"
if [ "$evidence_bullets" -gt 2 ]; then
  echo "warning: gist evidence has more than 2 bullets; keep it concise" >&2
fi

has_graphic="0"
if printf '%s\n' "$EVIDENCE_BLOCK" | grep -q '^!\['; then
  has_graphic="1"
fi
if printf '%s\n' "$EVIDENCE_BLOCK" | grep -q '^Graphic unavailable:'; then
  has_graphic="1"
fi

if [ "$has_graphic" = "0" ]; then
  EVIDENCE_BLOCK="$(printf '%s\nGraphic unavailable: not provided in report.\n' "$EVIDENCE_BLOCK")"
fi

TMP_OUTPUT="$(mktemp)"

{
  echo "## Gist"
  echo
  echo "Claim: $CLAIM_LINE"
  echo
  echo "Evidence:"
  printf '%s\n' "$EVIDENCE_BLOCK"
  echo
  echo "How Human Can Run This:"
  printf '%s\n' "$HUMAN_RUN_BLOCK"
} > "$TMP_OUTPUT"

if [ -n "$OUTPUT_GIST_MD" ]; then
  mkdir -p "$(dirname -- "$OUTPUT_GIST_MD")"
  cp "$TMP_OUTPUT" "$OUTPUT_GIST_MD"
  echo "rendered: $OUTPUT_GIST_MD"
else
  cat "$TMP_OUTPUT"
fi

rm -f "$TMP_OUTPUT"
