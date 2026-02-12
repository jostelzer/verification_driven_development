#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/render-report-pdf.sh <input_md> <output_pdf>

Description:
  Renders a Markdown verification report to PDF using Pandoc + XeLaTeX.
  For deterministic PDF output, status badges and known badge emojis are
  normalized to plain text in a temporary preprocessed file.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

INPUT_MD="$1"
OUTPUT_PDF="$2"

if [ ! -f "$INPUT_MD" ]; then
  echo "error: input markdown file does not exist: $INPUT_MD" >&2
  exit 1
fi

for cmd in pandoc xelatex perl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DEFAULTS_FILE="$REPO_ROOT/verification-driven-development/references/pandoc-pdf.yaml"

if [ ! -f "$DEFAULTS_FILE" ]; then
  echo "error: Pandoc defaults file not found: $DEFAULTS_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname -- "$OUTPUT_PDF")"

TMP_DIR="$(mktemp -d)"
TMP_MD="$TMP_DIR/report.normalized.md"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Normalize status badges and known badge emojis for reliable cross-host rendering.
perl -CSDA -Mopen=':std,:encoding(UTF-8)' -pe '
  s/\x{1F7E9}\s*VERIFIED\s*\x{2705}/[VERIFIED]/g;
  s/\x{1F7E8}\s*READY FOR HUMAN VERIFICATION\s*\x{1F9D1}\x{200D}\x{1F52C}/[READY FOR HUMAN VERIFICATION]/g;
  s/\x{1F7E5}\s*BLOCKED\s*\x{26D4}/[BLOCKED]/g;
  s/VERIFIED\s*\x{2705}/[VERIFIED]/g;
  s/READY FOR HUMAN VERIFICATION\s*\x{1F9D1}\x{200D}\x{1F52C}/[READY FOR HUMAN VERIFICATION]/g;
  s/BLOCKED\s*\x{26D4}/[BLOCKED]/g;
  s/\x{2705}/[PASS]/g;
  s/\x{26D4}/[BLOCKED]/g;
  s/\x{1F9D1}\x{200D}\x{1F52C}/[HUMAN VERIFICATION]/g;
  s/\x{1F7E9}/[GREEN]/g;
  s/\x{1F7E8}/[YELLOW]/g;
  s/\x{1F7E5}/[RED]/g;
' "$INPUT_MD" > "$TMP_MD"

if [ -n "${NORMALIZED_MD_OUT:-}" ]; then
  mkdir -p "$(dirname -- "$NORMALIZED_MD_OUT")"
  cp "$TMP_MD" "$NORMALIZED_MD_OUT"
fi

# Promote reproducible output unless caller overrides with SOURCE_DATE_EPOCH.
if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
  INPUT_MTIME=""
  if INPUT_MTIME="$(stat -f %m "$INPUT_MD" 2>/dev/null)"; then
    export SOURCE_DATE_EPOCH="$INPUT_MTIME"
  elif INPUT_MTIME="$(stat -c %Y "$INPUT_MD" 2>/dev/null)"; then
    export SOURCE_DATE_EPOCH="$INPUT_MTIME"
  fi
fi

INPUT_DIR="$(cd -- "$(dirname -- "$INPUT_MD")" && pwd)"
RESOURCE_PATH="$INPUT_DIR:$REPO_ROOT"

if pandoc --help 2>/dev/null | grep -q -- '--defaults'; then
  pandoc "$TMP_MD" \
    --defaults "$DEFAULTS_FILE" \
    --pdf-engine=xelatex \
    --resource-path "$RESOURCE_PATH" \
    --output "$OUTPUT_PDF"
else
  TMP_HEADER="$TMP_DIR/pandoc-header.tex"
  cat > "$TMP_HEADER" <<'EOF'
\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\lhead{Verification Report}
\rhead{\nouppercase{\leftmark}}
\cfoot{\thepage}
\setlength{\headheight}{14pt}
EOF

  pandoc "$TMP_MD" \
    --standalone \
    --toc \
    --toc-depth=2 \
    --number-sections \
    --highlight-style=tango \
    --metadata "title=Verification Report" \
    --metadata "author=Verification-Driven Development" \
    --variable "papersize=letter" \
    --variable "geometry:margin=1in" \
    --variable "fontsize=11pt" \
    --variable "linestretch=1.15" \
    --variable "colorlinks=true" \
    --variable "linkcolor=blue" \
    --variable "urlcolor=blue" \
    --include-in-header "$TMP_HEADER" \
    --pdf-engine=xelatex \
    --resource-path "$RESOURCE_PATH" \
    --output "$OUTPUT_PDF"
fi

echo "rendered: $OUTPUT_PDF"
