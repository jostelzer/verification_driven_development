#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-vdd-report.sh <verification_report_md>

Description:
  Validates that a verification report follows the VDD standardized format and
  agrees with the referenced verification manifest.
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

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$(cd -- "$(dirname -- "$REPORT_MD")" && pwd)"

LOCAL_MANIFEST_VALIDATOR="$PWD/scripts/validate-vdd-manifest.sh"
CANONICAL_MANIFEST_VALIDATOR="$SCRIPT_DIR/validate-vdd-manifest.sh"
if [ -x "$LOCAL_MANIFEST_VALIDATOR" ]; then
  MANIFEST_VALIDATOR="$LOCAL_MANIFEST_VALIDATOR"
elif [ -f "$LOCAL_MANIFEST_VALIDATOR" ]; then
  MANIFEST_VALIDATOR="$LOCAL_MANIFEST_VALIDATOR"
elif [ -x "$CANONICAL_MANIFEST_VALIDATOR" ]; then
  MANIFEST_VALIDATOR="$CANONICAL_MANIFEST_VALIDATOR"
elif [ -f "$CANONICAL_MANIFEST_VALIDATOR" ]; then
  MANIFEST_VALIDATOR="$CANONICAL_MANIFEST_VALIDATOR"
else
  echo "error: manifest validator not found" >&2
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

is_absolute_fs_path() {
  local path="$1"
  case "$path" in
    /*) return 0 ;;
    [A-Za-z]:\\*|[A-Za-z]:/*) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_artifact_path() {
  local raw="$1"
  if [ -z "$raw" ]; then
    return 1
  fi
  if [[ "$raw" = /* ]]; then
    printf '%s\n' "$raw"
    return 0
  fi
  if [ -f "$REPORT_DIR/$raw" ]; then
    printf '%s\n' "$REPORT_DIR/$raw"
    return 0
  fi
  if [ -f "$PWD/$raw" ]; then
    printf '%s\n' "$PWD/$raw"
    return 0
  fi
  printf '%s\n' "$REPORT_DIR/$raw"
}

require_section 'Verification Outcome' 'Verification Outcome'
require_section 'Verification Snapshot' 'Verification Snapshot'
require_section 'Verification Profile' 'Verification Profile'
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
require_section 'Artifact Index' 'Artifact Index'
require_section 'Inline Visual Evidence' 'Inline Visual Evidence'
require_section 'Command Ownership' 'Command Ownership'
require_section 'Timing' 'Timing'
require_section 'Cleanup' 'Cleanup'
require_section 'Known Limits' 'Known Limits'
require_section 'Final State' 'Final State'

status_badge_value="$(sed -nE 's/^Status Badge:[[:space:]]*(.*)$/\1/p' "$REPORT_MD" | head -n1)"
final_state_value="$(sed -nE 's/^Final State:[[:space:]]*(.*)$/\1/p' "$REPORT_MD" | head -n1)"

case "$status_badge_value" in
  '🟩 VERIFIED ✅'|'🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬'|'🟥 BLOCKED ⛔') ;;
  *) add_error "missing or invalid 'Status Badge:' line" ;;
esac

case "$final_state_value" in
  'VERIFIED ✅'|'READY FOR HUMAN VERIFICATION 🧑‍🔬'|'BLOCKED ⛔') ;;
  *) add_error "missing or invalid 'Final State:' line" ;;
esac

case "$status_badge_value|$final_state_value" in
  '🟩 VERIFIED ✅|VERIFIED ✅'|'🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬|READY FOR HUMAN VERIFICATION 🧑‍🔬'|'🟥 BLOCKED ⛔|BLOCKED ⛔') ;;
  *) add_error "Status Badge and Final State do not agree" ;;
esac

snapshot_block="$(extract_section '^##[[:space:]]+Verification Snapshot' | trim_block)"
if [ -z "$snapshot_block" ]; then
  add_error "Verification Snapshot section is empty"
else
  for pattern in \
    '^- Status Chip:[[:space:]]*(🟩 VERIFIED ✅|🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬|🟥 BLOCKED ⛔)$' \
    '^- Tier Chip:[[:space:]]*(🥇 Gold|🥈 Silver|🥉 Bronze)$' \
    '^- Ground-Truth Rung:[[:space:]]*R[1-5]$' \
    '^- Cleanup Chip:[[:space:]]*🧹[[:space:]]*(COMPLETE|INCOMPLETE)$' \
    '^- Human Step Chip:[[:space:]]*(🤖 none|🧑‍🔬 required)$'
  do
    if ! printf '%s\n' "$snapshot_block" | grep -Eq "$pattern"; then
      add_error "Verification Snapshot is missing or has an invalid badge line"
      break
    fi
  done

  snapshot_status="$(printf '%s\n' "$snapshot_block" | sed -nE 's/^- Status Chip:[[:space:]]*(.*)$/\1/p' | head -n1)"
  snapshot_tier="$(printf '%s\n' "$snapshot_block" | sed -nE 's/^- Tier Chip:[[:space:]]*(.*)$/\1/p' | head -n1)"
  snapshot_cleanup="$(printf '%s\n' "$snapshot_block" | sed -nE 's/^- Cleanup Chip:[[:space:]]*🧹[[:space:]]*(COMPLETE|INCOMPLETE)$/\1/p' | head -n1)"
  snapshot_human="$(printf '%s\n' "$snapshot_block" | sed -nE 's/^- Human Step Chip:[[:space:]]*(.*)$/\1/p' | head -n1)"

  if [ -n "$snapshot_status" ] && [ "$snapshot_status" != "$status_badge_value" ]; then
    add_error "Verification Snapshot status chip must match Status Badge"
  fi
fi

if ! grep -Eq '^##[[:space:]]+🏅[[:space:]]+Verification Certificate([[:space:]]|$)' "$REPORT_MD"; then
  add_error "missing certificate block header: ## 🏅 Verification Certificate"
fi

verification_certificate_line="$(grep -Enm1 '^##[[:space:]]+🏅[[:space:]]+Verification Certificate([[:space:]]|$)' "$REPORT_MD" | cut -d: -f1 || true)"
human_run_section_line="$(grep -Enm1 '^##[[:space:]]+Verification Brief How YOU Can Run This([[:space:]]|$)' "$REPORT_MD" | cut -d: -f1 || true)"
if [ -n "$verification_certificate_line" ] && [ -n "$human_run_section_line" ] && [ "$human_run_section_line" -le "$verification_certificate_line" ]; then
  add_error "Verification Brief How YOU Can Run This must appear below Verification Certificate"
fi

certificate_block="$(extract_section '^##[[:space:]]+🏅[[:space:]]+Verification Certificate' | trim_block)"
if printf '%s\n' "$certificate_block" | grep -q '^Green Flags:'; then
  add_error "Verification Certificate must not use 'Green Flags:'"
fi

if [ "$final_state_value" = 'VERIFIED ✅' ]; then
  verified_status_line_count="$(printf '%s\n' "$certificate_block" | awk '/^Status:[[:space:]]+VERIFIED$/ { c++ } END { print c+0 }')"
  verified_check_count="$(printf '%s\n' "$certificate_block" | awk '/^✅[[:space:]]+/ { c++ } END { print c+0 }')"
  if [ "$verified_status_line_count" -ne 1 ]; then
    add_error "VERIFIED certificate must include exactly one 'Status: VERIFIED' line"
  fi
  if [ "$verified_check_count" -ne 2 ]; then
    add_error "VERIFIED certificate must include exactly 2 ✅ proof lines"
  fi
fi

profile_block="$(extract_section '^##[[:space:]]+Verification Profile' | trim_block)"
if [ -z "$profile_block" ]; then
  add_error "Verification Profile section is empty"
fi
profile_value="$(printf '%s\n' "$profile_block" | sed -nE 's/^- Profile:[[:space:]]*`?([^`]+)`?$/\1/p' | head -n1)"
if ! printf '%s\n' "$profile_block" | grep -Eq '^- Why this profile:[[:space:]]*[^[:space:]].*'; then
  add_error "Verification Profile must include '- Why this profile:'"
fi
case "$profile_value" in
  api-service|ui-browser|data-pipeline|ml-model|deploy-infra|library-refactor|remote-ssh) ;;
  *) add_error "Verification Profile must set '- Profile:' to a known profile" ;;
esac

closeout_block="$(extract_section '^##[[:space:]]+Closeout Artifacts' | trim_block)"
if [ -z "$closeout_block" ]; then
  add_error "Closeout Artifacts section is empty"
else
  report_md_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Report Markdown:' || true)"
  manifest_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Verification Manifest:' || true)"
  evidence_root_line="$(printf '%s\n' "$closeout_block" | grep -E '^- Evidence Root:' || true)"
  [ -n "$report_md_line" ] || add_error "Closeout Artifacts missing '- Report Markdown:'"
  [ -n "$manifest_line" ] || add_error "Closeout Artifacts missing '- Verification Manifest:'"
  [ -n "$evidence_root_line" ] || add_error "Closeout Artifacts missing '- Evidence Root:'"
  if printf '%s\n' "$closeout_block" | grep -Eq '^- Verification Brief Markdown:'; then
    add_error "Closeout Artifacts must not include '- Verification Brief Markdown:'; Verification Brief is chat-only"
  fi
fi

manifest_raw="$(printf '%s\n' "$closeout_block" | sed -nE 's/^- Verification Manifest:[[:space:]]*`?([^`]+)`?$/\1/p' | head -n1)"
manifest_path="$(resolve_artifact_path "$manifest_raw")"
if [ -n "$manifest_raw" ] && [ ! -f "$manifest_path" ]; then
  add_error "Verification Manifest path does not exist: $manifest_raw"
fi

if [ -f "$manifest_path" ]; then
  manifest_validation_output="$("$MANIFEST_VALIDATOR" "$manifest_path" \
    --expected-final-state "$final_state_value" \
    --expected-status-badge "$status_badge_value" \
    --expected-profile "$profile_value" 2>&1)" || add_error "$manifest_validation_output"
fi

brief_evidence_block="$(extract_section '^##[[:space:]]+Verification Brief Evidence' | trim_block)"
if [ -z "$brief_evidence_block" ]; then
  add_error "Verification Brief Evidence section is empty"
else
  evidence_bullets="$(printf '%s\n' "$brief_evidence_block" | awk '/^- / { c++ } END { print c+0 }')"
  if [ "$evidence_bullets" -lt 1 ] || [ "$evidence_bullets" -gt 3 ]; then
    add_error "Verification Brief Evidence must contain 1 to 3 bullets (found $evidence_bullets)"
  fi
  if ! printf '%s\n' "$brief_evidence_block" | grep -Eq '^!\[|^Graphic unavailable:'; then
    add_error "Verification Brief Evidence must include a graphic line or 'Graphic unavailable:'"
  fi
fi

ground_truth_block="$(extract_section '^##[[:space:]]+Ground-Truth Plan and Data' | trim_block)"
if [ -z "$ground_truth_block" ]; then
  add_error "Ground-Truth Plan and Data section is empty"
else
  for pattern in \
    '^- Target evidence tier:[[:space:]]*(Gold|Silver|Bronze)' \
    '^- Achieved evidence tier:[[:space:]]*(Gold|Silver|Bronze)' \
    '^- Gold runtime estimate:[[:space:]]*[^[:space:]].*' \
    '^- Gold decision gate:[[:space:]]*(<=10m \(auto-Gold\)|>10m \(user choice required\))' \
    '^- User tier choice when Gold >10m:[[:space:]]*[^[:space:]].*' \
    '^- Discrimination:[[:space:]]*[^[:space:]].*'
  do
    if ! printf '%s\n' "$ground_truth_block" | grep -Eq "$pattern"; then
      add_error "Ground-Truth Plan and Data is missing a required field"
      break
    fi
  done
fi

achieved_tier_value="$(printf '%s\n' "$ground_truth_block" | sed -nE 's/^- Achieved evidence tier:[[:space:]]*(Gold|Silver|Bronze).*/\1/p' | head -n1)"
case "$achieved_tier_value" in
  Gold) expected_tier_chip='🥇 Gold' ;;
  Silver) expected_tier_chip='🥈 Silver' ;;
  Bronze) expected_tier_chip='🥉 Bronze' ;;
  *) expected_tier_chip='' ;;
esac
if [ -n "${snapshot_tier:-}" ] && [ -n "$expected_tier_chip" ] && [ "$snapshot_tier" != "$expected_tier_chip" ]; then
  add_error "Verification Snapshot tier chip must match achieved evidence tier"
fi

commands_block="$(extract_section '^##[[:space:]]+Commands Run' | trim_block)"
commands_code="$(printf '%s\n' "$commands_block" | awk '
  BEGIN { in_code=0 }
  /^```bash[[:space:]]*$/ { in_code=1; next }
  in_code && /^```[[:space:]]*$/ { in_code=0; exit }
  in_code { print }
')"
if [ -z "$commands_code" ]; then
  add_error "Commands Run must include a non-empty bash code block"
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

artifact_index_block="$(extract_section '^##[[:space:]]+Artifact Index' | trim_block)"
if [ -z "$artifact_index_block" ]; then
  add_error "Artifact Index section is empty"
else
  if ! printf '%s\n' "$artifact_index_block" | grep -Eq '^\|[[:space:]]*Path[[:space:]]*\|[[:space:]]*Kind[[:space:]]*\|[[:space:]]*Proves[[:space:]]*\|$'; then
    add_error "Artifact Index must include a markdown table header with Path, Kind, and Proves columns"
  fi
  if ! printf '%s\n' "$artifact_index_block" | grep -Eq '^\|[[:space:]]*---[[:space:]]*\|[[:space:]]*---[[:space:]]*\|[[:space:]]*---[[:space:]]*\|$'; then
    add_error "Artifact Index must include a markdown table separator row"
  fi
  artifact_rows="$(printf '%s\n' "$artifact_index_block" | awk '/^\|/ { c++ } END { print c+0 }')"
  if [ "$artifact_rows" -lt 3 ]; then
    add_error "Artifact Index must include at least one artifact table row"
  fi
fi

inline_visual_block="$(extract_section '^##[[:space:]]+Inline Visual Evidence' | trim_block)"
if [ -z "$inline_visual_block" ]; then
  add_error "Inline Visual Evidence section is empty"
fi

visual_artifacts="$(
  printf '%s\n' "$artifact_index_block" | awk -F'|' '
    NR > 2 && /^\|/ {
      path=$2
      kind=$3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", path)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", kind)
      gsub(/^`|`$/, "", path)
      if (kind == "`image`" || kind == "`chart`" || kind == "`screenshot`") {
        gsub(/^`|`$/, "", kind)
      }
      if (kind == "image" || kind == "chart" || kind == "screenshot") {
        print path
      }
    }
  '
)"

if [ -n "$visual_artifacts" ]; then
  if ! printf '%s\n' "$inline_visual_block" | grep -Eq '^!\[[^]]*\]\([^)]+\)$'; then
    add_error "Inline Visual Evidence must include markdown image embeds when visual artifacts are present"
  fi
  while IFS= read -r visual_path; do
    [ -n "$visual_path" ] || continue
    if ! is_absolute_fs_path "$visual_path"; then
      add_error "Visual artifacts in Artifact Index must use absolute filesystem paths: $visual_path"
    fi
    if ! printf '%s\n' "$inline_visual_block" | grep -Fq "]($visual_path)"; then
      add_error "Inline Visual Evidence must embed visual artifact path with markdown image syntax: $visual_path"
    fi
  done <<< "$visual_artifacts"
else
  if ! printf '%s\n' "$inline_visual_block" | grep -Fxq 'No inline visuals were produced.'; then
    add_error "Inline Visual Evidence must say 'No inline visuals were produced.' when there are no pictures or graphs"
  fi
fi

command_ownership_block="$(extract_section '^##[[:space:]]+Command Ownership' | trim_block)"
if [ -z "$command_ownership_block" ]; then
  add_error "Command Ownership section is empty"
else
  if ! printf '%s\n' "$command_ownership_block" | grep -q '^- Agent-ran commands summary:'; then
    add_error "Command Ownership must include '- Agent-ran commands summary:'"
  fi
  if ! printf '%s\n' "$command_ownership_block" | grep -q '^- Agent-side failures:'; then
    add_error "Command Ownership must include '- Agent-side failures:'"
  fi
  if ! printf '%s\n' "$command_ownership_block" | grep -q '^- Why any human step was unavoidable:'; then
    add_error "Command Ownership must include '- Why any human step was unavoidable:'"
  fi
fi

if grep -Eqi '<(command|copy/paste|path|criterion|exact|reason|signal|task|artifact|repo|input|output)[^>]*>' "$REPORT_MD"; then
  add_error "report contains unresolved placeholder tokens (<...>)"
fi

if grep -Eq 'PLACEHOLDER' "$REPORT_MD"; then
  add_error "report contains unresolved *_PLACEHOLDER tokens"
fi

timing_block="$(extract_section '^##[[:space:]]+Timing' | trim_block)"
if [ -n "$timing_block" ] && ! printf '%s\n' "$timing_block" | grep -q '^-[[:space:]]Tier gate outcome:'; then
  add_error "Timing section must include '- Tier gate outcome:'"
fi

cleanup_block="$(extract_section '^##[[:space:]]+Cleanup' | trim_block)"
if [ -z "$cleanup_block" ]; then
  add_error "Cleanup section is empty"
else
  for pattern in \
    '^- Resources started by verification:[[:space:]]*[^[:space:]].*' \
    '^- Teardown commands run:[[:space:]]*[^[:space:]].*' \
    '^- Post-cleanup check:[[:space:]]*[^[:space:]].*' \
    '^- Cleanup status:[[:space:]]*(COMPLETE|INCOMPLETE)'
  do
    if ! printf '%s\n' "$cleanup_block" | grep -Eq "$pattern"; then
      add_error "Cleanup section is missing a required field"
      break
    fi
  done
  cleanup_status="$(printf '%s\n' "$cleanup_block" | sed -nE 's/^- Cleanup status:[[:space:]]*(COMPLETE|INCOMPLETE).*/\1/p' | head -n1)"
  if [ "$cleanup_status" = "INCOMPLETE" ] && [ "$final_state_value" != 'BLOCKED ⛔' ]; then
    add_error "Cleanup status INCOMPLETE is only allowed with BLOCKED final state"
  fi
  if [ -n "${snapshot_cleanup:-}" ] && [ "$snapshot_cleanup" != "$cleanup_status" ]; then
    add_error "Verification Snapshot cleanup chip must match Cleanup status"
  fi
fi

case "$final_state_value" in
  'READY FOR HUMAN VERIFICATION 🧑‍🔬') expected_human_chip='🧑‍🔬 required' ;;
  *) expected_human_chip='🤖 none' ;;
esac
if [ -n "${snapshot_human:-}" ] && [ "$snapshot_human" != "$expected_human_chip" ]; then
  add_error "Verification Snapshot human-step chip must match the final state"
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
