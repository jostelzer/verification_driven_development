#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-vdd-report.sh <verification_report_md>

Description:
  Validates that a verification report follows the VDD standardized format.
  Exits non-zero when required sections/fields are missing or invalid.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

REPORT_MD="$1"
if [ ! -f "$REPORT_MD" ]; then
  echo "error: report file does not exist: $REPORT_MD" >&2
  exit 1
fi

declare -a ERRORS=()
declare -a WARNINGS=()

add_error() {
  ERRORS+=("$1")
}

add_warning() {
  WARNINGS+=("$1")
}

require_section() {
  local pattern="$1"
  local label="$2"
  if ! grep -Eq "^##[[:space:]]+$pattern([[:space:]]|$)" "$REPORT_MD"; then
    add_error "missing section: ## $label"
  fi
}

extract_section() {
  local header_pattern="$1"
  awk -v pat="$header_pattern" '
    BEGIN { in_section=0 }
    $0 ~ pat { in_section=1; next }
    in_section && /^##[[:space:]]+/ { exit }
    in_section { print }
  ' "$REPORT_MD"
}

trim_block() {
  awk '
    BEGIN { started=0; n=0 }
    {
      if (!started && $0 ~ /^[[:space:]]*$/) next
      started=1
      lines[++n]=$0
    }
    END {
      while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
      for (i=1; i<=n; i++) print lines[i]
    }
  '
}

require_section 'Verification Outcome' 'Verification Outcome'
require_section 'Closeout Artifacts' 'Closeout Artifacts'
require_section 'Gist Claim' 'Gist Claim'
require_section 'Gist Evidence' 'Gist Evidence'
require_section 'Gist Human Run' 'Gist Human Run'
require_section 'Goal' 'Goal'
require_section 'Acceptance Criteria' 'Acceptance Criteria'
require_section 'What Changed' 'What Changed'
require_section 'Runtime' 'Runtime'
require_section 'Ground-Truth Plan and Data' 'Ground-Truth Plan and Data'
require_section 'Commands Run' 'Commands Run'
require_section 'Results by Criterion' 'Results by Criterion'
require_section 'Standard Certificate' 'Standard Certificate'
require_section 'Evidence and Inspection' 'Evidence and Inspection'
require_section 'Timing' 'Timing'
require_section 'Known Limits' 'Known Limits'
require_section 'Final State' 'Final State'

if ! grep -Eq '^Status Badge:[[:space:]]*(🟩 VERIFIED ✅|🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬|🟥 BLOCKED ⛔|\[VERIFIED\]|\[READY FOR HUMAN VERIFICATION\]|\[BLOCKED\])$' "$REPORT_MD"; then
  add_error "missing or invalid 'Status Badge:' line"
fi

if ! grep -Eq '^Final State:[[:space:]]*(VERIFIED ✅|READY FOR HUMAN VERIFICATION 🧑‍🔬|BLOCKED ⛔|\[VERIFIED\]|\[READY FOR HUMAN VERIFICATION\]|\[BLOCKED\])$' "$REPORT_MD"; then
  add_error "missing or invalid 'Final State:' line"
fi

if ! grep -Eq '^##[[:space:]]+Verification Certificate([[:space:]]|$)' "$REPORT_MD"; then
  add_error "missing certificate block header: ## Verification Certificate"
fi

closeout_block="$(extract_section '^##[[:space:]]+Closeout Artifacts' | trim_block)"
if [ -z "$closeout_block" ]; then
  add_error "Closeout Artifacts section is empty"
else
  report_md_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Report Markdown:' || true)"
  report_pdf_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Report PDF:' || true)"
  gist_md_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Gist Markdown:' || true)"
  pdf_cmd_line="$(printf '%s\n' "$closeout_block" | grep -E '^- PDF render command attempted:' || true)"
  pdf_result_line="$(printf '%s\n' "$closeout_block" | grep -E '^- PDF render result:' || true)"

  [ -n "$report_md_line" ] || add_error "Closeout Artifacts missing '- Report Markdown:'"
  [ -n "$report_pdf_line" ] || add_error "Closeout Artifacts missing '- Report PDF:'"
  [ -n "$gist_md_line" ] || add_error "Closeout Artifacts missing '- Gist Markdown:'"
  [ -n "$pdf_cmd_line" ] || add_error "Closeout Artifacts missing '- PDF render command attempted:'"
  [ -n "$pdf_result_line" ] || add_error "Closeout Artifacts missing '- PDF render result:'"

  if [ -n "$report_pdf_line" ] && [ -n "$pdf_result_line" ]; then
    if printf '%s\n' "$report_pdf_line" | grep -q 'NOT GENERATED'; then
      if ! printf '%s\n' "$pdf_result_line" | grep -Eq 'failed'; then
        add_error "Report PDF marked NOT GENERATED but PDF render result is not failed"
      fi
    else
      if ! printf '%s\n' "$pdf_result_line" | grep -Eq 'success|failed'; then
        add_error "PDF render result must be success or failed(...)"
      fi
    fi
  fi
fi

gist_evidence_block="$(extract_section '^##[[:space:]]+Gist Evidence' | trim_block)"
if [ -z "$gist_evidence_block" ]; then
  add_error "Gist Evidence section is empty"
else
  evidence_bullets="$(printf '%s\n' "$gist_evidence_block" | awk '/^- / { c++ } END { print c+0 }')"
  if [ "$evidence_bullets" -ne 2 ]; then
    add_error "Gist Evidence must contain exactly 2 bullets (found $evidence_bullets)"
  fi
  if ! printf '%s\n' "$gist_evidence_block" | grep -Eq '^!\[|^Graphic unavailable:'; then
    add_error "Gist Evidence must include a graphic line or 'Graphic unavailable:'"
  fi
fi

human_run_block="$(extract_section '^##[[:space:]]+Gist Human Run' | trim_block)"
if [ -z "$human_run_block" ]; then
  add_error "Gist Human Run section is empty"
else
  human_run_commands="$(printf '%s\n' "$human_run_block" | awk '
    BEGIN { in_code=0 }
    /^```bash[[:space:]]*$/ { in_code=1; next }
    in_code && /^```[[:space:]]*$/ { in_code=0; exit }
    in_code { print }
  ')"
  if [ -z "$human_run_commands" ]; then
    add_error "Gist Human Run must include a non-empty bash code block"
  fi
  if ! printf '%s\n' "$human_run_block" | grep -q '^Pass signal:'; then
    add_error "Gist Human Run is missing 'Pass signal:'"
  fi
  if ! printf '%s\n' "$human_run_block" | grep -q '^Fail signal:'; then
    add_error "Gist Human Run is missing 'Fail signal:'"
  fi

  forbidden_human_run_pattern='(\.agent/runs/|/tmp/|playwright_[^[:space:]]*\.js|[[:alnum:]_/-]*_check\.js|[^[:space:]]*\.spec\.js)'
  if [ -n "${human_run_commands:-}" ] && printf '%s\n' "$human_run_commands" | grep -Eqi "$forbidden_human_run_pattern"; then
    add_error "Gist Human Run contains ad-hoc probe/test script commands; use real operator entrypoints"
  fi
fi

if grep -Eqi '<(command|copy/paste|path|criterion|exact|short|one-line|reason|signal|task|artifact|repo|input|output)[^>]*>' "$REPORT_MD"; then
  add_error "report contains unresolved placeholder tokens (<...>)"
fi

if ! grep -Eq '^##[[:space:]]+Commands Run([[:space:]]|$)' "$REPORT_MD"; then
  add_warning "Commands Run section not found exactly; check section title spelling"
fi

if [ "${#WARNINGS[@]}" -gt 0 ]; then
  printf '%s\n' "validation warnings:"
  for w in "${WARNINGS[@]}"; do
    printf '  - %s\n' "$w"
  done
fi

if [ "${#ERRORS[@]}" -gt 0 ]; then
  printf '%s\n' "validation failed for $REPORT_MD:"
  for e in "${ERRORS[@]}"; do
    printf '  - %s\n' "$e"
  done
  exit 1
fi

echo "validation passed: $REPORT_MD"
