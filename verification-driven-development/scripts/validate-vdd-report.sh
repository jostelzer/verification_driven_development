#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-vdd-report.sh <verification_report_md>

Description:
  Validates that a verification report contains runnable proof, cleanup
  evidence, and a matching verification manifest without forcing a single
  verbose report shape.
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

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: required command not found: python3" >&2
  exit 1
fi

python3 - "$REPORT_MD" "$MANIFEST_VALIDATOR" <<'PY'
import re
import subprocess
import sys
from pathlib import Path

report_path = Path(sys.argv[1]).resolve()
manifest_validator = Path(sys.argv[2]).resolve()

allowed_states = {
    "VERIFIED ✅": "🟩 VERIFIED ✅",
    "READY FOR HUMAN VERIFICATION 🧑‍🔬": "🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬",
    "BLOCKED ⛔": "🟥 BLOCKED ⛔",
}
visual_kinds = {"image", "chart", "screenshot"}
errors = []
warnings = []


def add_error(message: str) -> None:
    errors.append(message)


def add_warning(message: str) -> None:
    warnings.append(message)


text = report_path.read_text(encoding="utf-8")

if re.search(r"<(command|copy/paste|path|criterion|exact|reason|signal|task|artifact|repo|input|output)[^>]*>", text, re.IGNORECASE):
    add_error("report contains unresolved placeholder tokens (<...>)")
if "PLACEHOLDER" in text:
    add_error("report contains unresolved *_PLACEHOLDER tokens")

header_re = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)
headers = list(header_re.finditer(text))
sections = {}
for index, match in enumerate(headers):
    name = match.group(1).strip()
    start = match.end()
    end = headers[index + 1].start() if index + 1 < len(headers) else len(text)
    sections[name] = text[start:end].strip()


def get_section(*names: str):
    for name in names:
        if name in sections:
            return sections[name], name
    return "", None


def first_match(pattern: str, block: str):
    match = re.search(pattern, block, re.MULTILINE)
    return match.group(1).strip() if match else ""


def extract_bash_block(block: str) -> str:
    match = re.search(r"```bash\s*\n(.*?)\n```", block, re.DOTALL)
    return match.group(1).strip() if match else ""


required_sections = [
    "Verification Outcome",
    "Closeout Artifacts",
    "Goal",
    "Commands Run",
    "Results by Criterion",
    "Evidence and Inspection",
    "Artifact Index",
    "Command Ownership",
    "Cleanup",
    "Final State",
]

for name in required_sections:
    block, _ = get_section(name)
    if not block:
        add_error(f"missing section: ## {name}")

status_badge = first_match(r"^Status Badge:\s*(.+)$", text)
final_state_block, _ = get_section("Final State")
final_state = first_match(r"^Final State:\s*(.+)$", final_state_block)

if status_badge not in allowed_states.values():
    add_error("missing or invalid 'Status Badge:' line")
if final_state not in allowed_states:
    add_error("missing or invalid 'Final State:' line")
if final_state in allowed_states and status_badge and status_badge != allowed_states[final_state]:
    add_error("Status Badge and Final State do not agree")

closeout_block, _ = get_section("Closeout Artifacts")
manifest_raw = first_match(r"^- Verification Manifest:\s*`?([^`]+)`?\s*$", closeout_block)
if not manifest_raw:
    add_error("Closeout Artifacts missing '- Verification Manifest:'")
    manifest_path = None
else:
    candidate = Path(manifest_raw)
    if candidate.is_absolute():
        manifest_path = candidate
    else:
        manifest_path = (report_path.parent / candidate).resolve()
        if not manifest_path.exists():
            manifest_path = (Path.cwd() / candidate).resolve()
    if not manifest_path.exists():
        add_error(f"Verification Manifest path does not exist: {manifest_raw}")

commands_block, _ = get_section("Commands Run")
commands_code = extract_bash_block(commands_block)
if not commands_code:
    add_error("Commands Run must include a non-empty bash code block")

criterion_block, _ = get_section("Results by Criterion")
criterion_count = len(re.findall(r"^- Criterion:\s+", criterion_block, re.MULTILINE))
result_count = len(re.findall(r"^- Result:\s+(PASS|FAIL|INCONCLUSIVE)\b", criterion_block, re.MULTILINE))
evidence_count = len(re.findall(r"^- Evidence:\s+", criterion_block, re.MULTILINE))
if criterion_count == 0 or result_count == 0 or evidence_count == 0:
    add_error("Results by Criterion must include at least one Criterion/Result/Evidence mapping")
elif not (criterion_count == result_count == evidence_count):
    add_error("Results by Criterion must keep Criterion/Result/Evidence entries aligned")

evidence_block, _ = get_section("Evidence and Inspection")
if not evidence_block.strip():
    add_error("Evidence and Inspection section is empty")

artifact_block, _ = get_section("Artifact Index")
artifact_block = artifact_block.strip()
if not artifact_block:
    add_error("Artifact Index section is empty")

artifact_rows = []
if artifact_block:
    table_lines = [line.strip() for line in artifact_block.splitlines() if line.strip().startswith("|")]
    if table_lines:
        if len(table_lines) < 3:
            add_error("Artifact Index table must include at least one artifact row")
        else:
            for line in table_lines[2:]:
                parts = [part.strip().strip("`") for part in line.strip().strip("|").split("|")]
                if len(parts) >= 3:
                    artifact_rows.append((parts[0], parts[1], parts[2]))
    elif re.search(r"^No standalone artifacts\.", artifact_block, re.MULTILINE):
        artifact_rows = []
    else:
        bullet_lines = [line for line in artifact_block.splitlines() if line.strip().startswith("- ")]
        if not bullet_lines:
            add_error("Artifact Index must contain a table, bullet list, or 'No standalone artifacts.'")
        for line in bullet_lines:
            content = line.strip()[2:]
            parts = [part.strip().strip("`") for part in content.split("|")]
            if len(parts) < 3:
                add_error("Artifact Index bullet entries must use '- <path> | <kind> | <proves>'")
                continue
            artifact_rows.append((parts[0], parts[1], parts[2]))

inline_visual_block, inline_visual_name = get_section("Inline Visual Evidence")
visual_paths = []
for path_value, kind_value, _ in artifact_rows:
    if kind_value in visual_kinds:
        visual_paths.append(path_value)

if visual_paths:
    if not inline_visual_block:
        add_error("Inline Visual Evidence is required when Artifact Index lists images, charts, or screenshots")
    for visual_path in visual_paths:
        if not Path(visual_path).is_absolute():
            add_error(f"Visual artifacts must use absolute filesystem paths: {visual_path}")
        if inline_visual_block and f"]({visual_path})" not in inline_visual_block:
            add_error(f"Inline Visual Evidence must embed visual artifact path with markdown image syntax: {visual_path}")
else:
    if inline_visual_name and inline_visual_block and inline_visual_block.strip() != "No inline visuals were produced.":
        add_warning("Inline Visual Evidence section is present without visual artifacts; use it only when it helps clarity")

ownership_block, _ = get_section("Command Ownership")
if not ownership_block.strip():
    add_error("Command Ownership section is empty")
elif not re.search(r"agent|human", ownership_block, re.IGNORECASE):
    add_error("Command Ownership must explain what the agent ran and whether any human step remained")

cleanup_block, _ = get_section("Cleanup")
cleanup_status = first_match(r"^-\s*(?:Cleanup status|Status):\s*(COMPLETE|INCOMPLETE)\b", cleanup_block)
if cleanup_status not in {"COMPLETE", "INCOMPLETE"}:
    add_error("Cleanup section must include '- Cleanup status: COMPLETE|INCOMPLETE'")
if "post-cleanup" not in cleanup_block.lower() and "no resources were started" not in cleanup_block.lower():
    add_error("Cleanup section must mention a post-cleanup check or explicitly state that no resources were started")
if cleanup_status == "INCOMPLETE" and final_state != "BLOCKED ⛔":
    add_error("Cleanup status INCOMPLETE is only allowed with BLOCKED final state")

snapshot_block, _ = get_section("Verification Snapshot")
if snapshot_block:
    snapshot_status = first_match(r"^-\s*Status Chip:\s*(.+)$", snapshot_block)
    snapshot_cleanup = first_match(r"^-\s*Cleanup Chip:\s*🧹\s*(COMPLETE|INCOMPLETE)$", snapshot_block)
    snapshot_human = first_match(r"^-\s*Human Step Chip:\s*(.+)$", snapshot_block)
    snapshot_tier = first_match(r"^-\s*Tier Chip:\s*(.+)$", snapshot_block)
    if snapshot_status and snapshot_status != status_badge:
        add_error("Verification Snapshot status chip must match Status Badge")
    if snapshot_cleanup and cleanup_status and snapshot_cleanup != cleanup_status:
        add_error("Verification Snapshot cleanup chip must match Cleanup status")
    expected_human = "🧑‍🔬 required" if final_state == "READY FOR HUMAN VERIFICATION 🧑‍🔬" else "🤖 none"
    if snapshot_human and snapshot_human != expected_human:
        add_error("Verification Snapshot human-step chip must match the final state")
else:
    snapshot_tier = ""

ground_truth_block, _ = get_section("Ground-Truth Plan and Data")
achieved_tier = first_match(r"^-\s*Achieved evidence tier:\s*(Gold|Silver|Bronze)\b", ground_truth_block)
if snapshot_tier and achieved_tier:
    expected_tier_chip = {
        "Gold": "🥇 Gold",
        "Silver": "🥈 Silver",
        "Bronze": "🥉 Bronze",
    }[achieved_tier]
    if snapshot_tier != expected_tier_chip:
        add_error("Verification Snapshot tier chip must match achieved evidence tier")

human_run_block, human_run_name = get_section(
    "Verification Brief How YOU Can Run This",
    "How YOU Can Run This",
)
if not human_run_block:
    add_error("missing section: ## How YOU Can Run This")
else:
    human_run_commands = extract_bash_block(human_run_block)
    if not human_run_commands:
        add_error(f"{human_run_name} must include a non-empty bash code block")
    if not re.search(r"^Pass signal:\s+", human_run_block, re.MULTILINE):
        add_error(f"{human_run_name} is missing 'Pass signal:'")
    if not re.search(r"^Fail signal:\s+", human_run_block, re.MULTILINE):
        add_error(f"{human_run_name} is missing 'Fail signal:'")
    forbidden_pattern = re.compile(r"(\.agent/runs/|/tmp/|playwright_[^\s]*\.js|[\w./-]*_check\.js|[^\s]*\.spec\.js)", re.IGNORECASE)
    if human_run_commands and forbidden_pattern.search(human_run_commands):
        add_error(f"{human_run_name} contains ad-hoc probe/test script commands; use real operator entrypoints")

legacy_certificate_block, _ = get_section("🏅 Verification Certificate")
certificate_heading_map = {
    "VERIFIED ✅": "✅ Verified Report",
    "READY FOR HUMAN VERIFICATION 🧑‍🔬": "🧑‍🔬 Human Check Report",
    "BLOCKED ⛔": "🚫 Blocked Report",
}
certificate_heading = certificate_heading_map.get(final_state, "")
certificate_block, certificate_name = get_section(
    "✅ Verified Report",
    "🧑‍🔬 Human Check Report",
    "🚫 Blocked Report",
)
if certificate_block and "Green Flags:" in certificate_block:
    add_error("Certificate block must not use 'Green Flags:'")
if legacy_certificate_block:
    add_error("legacy certificate heading '## 🏅 Verification Certificate' is no longer allowed")
if certificate_name and certificate_heading and certificate_name != certificate_heading:
    add_error(f"certificate heading must match the final state ({certificate_heading})")

if manifest_raw and 'manifest_path' in locals() and manifest_path and manifest_path.exists():
    command = [
        str(manifest_validator),
        str(manifest_path),
        "--expected-final-state",
        final_state,
        "--expected-status-badge",
        status_badge,
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        add_error(result.stderr.strip() or result.stdout.strip() or "manifest validation failed")

if warnings:
    print("validation warnings:")
    for warning in warnings:
        print(f"  - {warning}")

if errors:
    print(f"validation failed for {report_path}:")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print(f"validation passed: {report_path}")
PY
