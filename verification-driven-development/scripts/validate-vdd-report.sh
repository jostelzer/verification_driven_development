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
require_section 'Verification Brief Claim' 'Verification Brief Claim'
require_section 'Verification Brief Evidence' 'Verification Brief Evidence'
require_section 'Verification Brief How YOU Can Run This' 'Verification Brief How YOU Can Run This'
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
require_section 'Cleanup' 'Cleanup'
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

verification_certificate_line="$(grep -Enm1 '^##[[:space:]]+Verification Certificate([[:space:]]|$)' "$REPORT_MD" | cut -d: -f1 || true)"
human_run_section_line="$(grep -Enm1 '^##[[:space:]]+Verification Brief How YOU Can Run This([[:space:]]|$)' "$REPORT_MD" | cut -d: -f1 || true)"
if [ -n "$verification_certificate_line" ] && [ -n "$human_run_section_line" ] && [ "$human_run_section_line" -le "$verification_certificate_line" ]; then
  add_error "Verification Brief How YOU Can Run This must appear below Verification Certificate"
fi

certificate_block="$(extract_section '^##[[:space:]]+Verification Certificate' | trim_block)"
if [ -n "$certificate_block" ]; then
  if printf '%s\n' "$certificate_block" | grep -q '^Green Flags:'; then
    add_error "Verification Certificate must not use 'Green Flags:'; use standalone ✅ lines"
  fi
fi

if grep -Eq '^Status Badge:[[:space:]]*(🟩 VERIFIED ✅|\[VERIFIED\])$' "$REPORT_MD"; then
  verified_status_line_count="$(printf '%s\n' "$certificate_block" | awk '/^Status:[[:space:]]+VERIFIED$/ { c++ } END { print c+0 }')"
  if [ "$verified_status_line_count" -ne 1 ]; then
    add_error "VERIFIED certificate must include exactly one 'Status: VERIFIED' line"
  fi
  verified_check_count="$(printf '%s\n' "$certificate_block" | awk '/^✅[[:space:]]+/ { c++ } END { print c+0 }')"
  if [ "$verified_check_count" -ne 2 ]; then
    add_error "VERIFIED certificate must include exactly 2 ✅ lines (proof checks only; found $verified_check_count)"
  fi
  if printf '%s\n' "$certificate_block" | grep -Eq '^✅ VERIFIED$'; then
    add_error "VERIFIED certificate must not use '✅ VERIFIED'; use 'Status: VERIFIED'"
  fi
fi

closeout_block="$(extract_section '^##[[:space:]]+Closeout Artifacts' | trim_block)"
if [ -z "$closeout_block" ]; then
  add_error "Closeout Artifacts section is empty"
else
  report_md_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Report Markdown:' || true)"

  [ -n "$report_md_line" ] || add_error "Closeout Artifacts missing '- Report Markdown:'"
  if printf '%s\n' "$closeout_block" | grep -Eq '^- Verification Brief Markdown:'; then
    add_error "Closeout Artifacts must not include '- Verification Brief Markdown:'; Verification Brief is chat-only"
  fi
fi

brief_evidence_block="$(extract_section '^##[[:space:]]+Verification Brief Evidence' | trim_block)"
if [ -z "$brief_evidence_block" ]; then
  add_error "Verification Brief Evidence section is empty"
else
  evidence_bullets="$(printf '%s\n' "$brief_evidence_block" | awk '/^- / { c++ } END { print c+0 }')"
  if [ "$evidence_bullets" -ne 2 ]; then
    add_error "Verification Brief Evidence must contain exactly 2 bullets (found $evidence_bullets)"
  fi
  if ! printf '%s\n' "$brief_evidence_block" | grep -Eq '^!\[|^Graphic unavailable:'; then
    add_error "Verification Brief Evidence must include a graphic line or 'Graphic unavailable:'"
  fi
fi

ground_truth_block="$(extract_section '^##[[:space:]]+Ground-Truth Plan and Data' | trim_block)"
if [ -z "$ground_truth_block" ]; then
  add_error "Ground-Truth Plan and Data section is empty"
else
  if ! printf '%s\n' "$ground_truth_block" | grep -Eq '^- Target evidence tier:[[:space:]]*(Gold|Silver|Bronze)([[:space:][:punct:]].*)?$'; then
    add_error "Ground-Truth Plan and Data must include '- Target evidence tier: Gold|Silver|Bronze'"
  fi
  if ! printf '%s\n' "$ground_truth_block" | grep -Eq '^- Achieved evidence tier:[[:space:]]*(Gold|Silver|Bronze)([[:space:][:punct:]].*)?$'; then
    add_error "Ground-Truth Plan and Data must include '- Achieved evidence tier: Gold|Silver|Bronze'"
  fi
  if ! printf '%s\n' "$ground_truth_block" | grep -Eq '^- Gold runtime estimate:[[:space:]]*[^[:space:]].*'; then
    add_error "Ground-Truth Plan and Data must include '- Gold runtime estimate:'"
  fi
  if ! printf '%s\n' "$ground_truth_block" | grep -Eq '^- Gold decision gate:[[:space:]]*(<=10m \(auto-Gold\)|>10m \(user choice required\))([[:space:][:punct:]].*)?$'; then
    add_error "Ground-Truth Plan and Data must include '- Gold decision gate: <=10m (auto-Gold) | >10m (user choice required)'"
  fi
  if ! printf '%s\n' "$ground_truth_block" | grep -Eq '^- User tier choice when Gold >10m:[[:space:]]*[^[:space:]].*'; then
    add_error "Ground-Truth Plan and Data must include '- User tier choice when Gold >10m:'"
  fi

  target_tier="$(printf '%s\n' "$ground_truth_block" | sed -nE 's/^- Target evidence tier:[[:space:]]*(Gold|Silver|Bronze).*/\1/p' | head -n1)"
  gate_value="$(printf '%s\n' "$ground_truth_block" | sed -nE 's/^- Gold decision gate:[[:space:]]*(<=10m \(auto-Gold\)|>10m \(user choice required\)).*/\1/p' | head -n1)"
  user_choice="$(printf '%s\n' "$ground_truth_block" | sed -nE 's/^- User tier choice when Gold >10m:[[:space:]]*(.*)$/\1/p' | head -n1)"
  user_choice_tier="$(printf '%s\n' "$user_choice" | sed -nE 's/.*\b(Gold|Silver|Bronze)\b.*/\1/p' | head -n1)"

  if [ "$gate_value" = "<=10m (auto-Gold)" ] && [ -n "$target_tier" ] && [ "$target_tier" != "Gold" ]; then
    add_error "Target evidence tier must be Gold when Gold decision gate is <=10m (auto-Gold)"
  fi

  if [ "$gate_value" = ">10m (user choice required)" ]; then
    if [ -z "$user_choice_tier" ]; then
      add_error "User tier choice when Gold >10m must name Bronze, Silver, or Gold"
    elif [ -n "$target_tier" ] && [ "$user_choice_tier" != "$target_tier" ]; then
      add_error "Target evidence tier must match user tier choice when Gold >10m"
    fi
  fi
fi

human_run_block="$(extract_section '^##[[:space:]]+Verification Brief How YOU Can Run This' | trim_block)"
if [ -z "$human_run_block" ]; then
  add_error "Verification Brief How YOU Can Run This section is empty"
else
  human_run_commands="$(printf '%s\n' "$human_run_block" | awk '
    BEGIN { in_code=0 }
    /^```bash[[:space:]]*$/ { in_code=1; next }
    in_code && /^```[[:space:]]*$/ { in_code=0; exit }
    in_code { print }
  ')"
  if [ -z "$human_run_commands" ]; then
    add_error "Verification Brief How YOU Can Run This must include a non-empty bash code block"
  fi
  if ! printf '%s\n' "$human_run_block" | grep -q '^Pass signal:'; then
    add_error "Verification Brief How YOU Can Run This is missing 'Pass signal:'"
  fi
  if ! printf '%s\n' "$human_run_block" | grep -q '^Fail signal:'; then
    add_error "Verification Brief How YOU Can Run This is missing 'Fail signal:'"
  fi

  forbidden_human_run_pattern='(\.agent/runs/|/tmp/|playwright_[^[:space:]]*\.js|[[:alnum:]_/-]*_check\.js|[^[:space:]]*\.spec\.js)'
  if [ -n "${human_run_commands:-}" ] && printf '%s\n' "$human_run_commands" | grep -Eqi "$forbidden_human_run_pattern"; then
    add_error "Verification Brief How YOU Can Run This contains ad-hoc probe/test script commands; use real operator entrypoints"
  fi
fi

if grep -Eqi '<(command|copy/paste|path|criterion|exact|short|one-line|reason|signal|task|artifact|repo|input|output)[^>]*>' "$REPORT_MD"; then
  add_error "report contains unresolved placeholder tokens (<...>)"
fi

if grep -Eqi '^Validation notes:[[:space:]]+.*validate-vdd-report\.sh not present' "$REPORT_MD"; then
  add_error "report must not claim fallback validation when validate-vdd-report.sh is missing"
fi

timing_block="$(extract_section '^##[[:space:]]+Timing' | trim_block)"
if [ -n "$timing_block" ] && ! printf '%s\n' "$timing_block" | grep -q '^-[[:space:]]Tier gate outcome:'; then
  add_error "Timing section must include '- Tier gate outcome:'"
fi

cleanup_block="$(extract_section '^##[[:space:]]+Cleanup' | trim_block)"
if [ -z "$cleanup_block" ]; then
  add_error "Cleanup section is empty"
else
  if ! printf '%s\n' "$cleanup_block" | grep -Eq '^- Resources started by verification:[[:space:]]*[^[:space:]].*'; then
    add_error "Cleanup section must include '- Resources started by verification:'"
  fi
  if ! printf '%s\n' "$cleanup_block" | grep -Eq '^- Teardown commands run:[[:space:]]*[^[:space:]].*'; then
    add_error "Cleanup section must include '- Teardown commands run:'"
  fi
  if ! printf '%s\n' "$cleanup_block" | grep -Eq '^- Post-cleanup check:[[:space:]]*[^[:space:]].*'; then
    add_error "Cleanup section must include '- Post-cleanup check:'"
  fi
  if ! printf '%s\n' "$cleanup_block" | grep -Eq '^- Cleanup status:[[:space:]]*(COMPLETE|INCOMPLETE)([[:space:][:punct:]].*)?$'; then
    add_error "Cleanup section must include '- Cleanup status: COMPLETE | INCOMPLETE'"
  fi

  cleanup_status="$(printf '%s\n' "$cleanup_block" | sed -nE 's/^- Cleanup status:[[:space:]]*(COMPLETE|INCOMPLETE).*/\1/p' | head -n1)"
  if [ "$cleanup_status" = "INCOMPLETE" ] && ! grep -Eq '^Status Badge:[[:space:]]*(🟥 BLOCKED ⛔|\[BLOCKED\])$' "$REPORT_MD"; then
    add_error "Cleanup status INCOMPLETE is only allowed with BLOCKED status"
  fi
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
