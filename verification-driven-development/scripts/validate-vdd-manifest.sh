#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verification-driven-development/scripts/validate-vdd-manifest.sh <verification_manifest_json> [--expected-final-state <state>] [--expected-status-badge <badge>]

Description:
  Validates that a verification manifest contains the semantic evidence needed
  to support a VDD closeout without forcing every optional planning field.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ]; then
  usage
  exit 2
fi

MANIFEST_JSON="$1"
shift

EXPECTED_FINAL_STATE=""
EXPECTED_STATUS_BADGE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --expected-final-state)
      EXPECTED_FINAL_STATE="${2:-}"
      shift 2
      ;;
    --expected-status-badge)
      EXPECTED_STATUS_BADGE="${2:-}"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ! -f "$MANIFEST_JSON" ]; then
  echo "error: manifest file does not exist: $MANIFEST_JSON" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: required command not found: python3" >&2
  exit 1
fi

python3 - "$MANIFEST_JSON" "$EXPECTED_FINAL_STATE" "$EXPECTED_STATUS_BADGE" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
expected_final_state = sys.argv[2]
expected_status_badge = sys.argv[3]

allowed_states = {
    "VERIFIED ✅": "🟩 VERIFIED ✅",
    "READY FOR HUMAN VERIFICATION 🧑‍🔬": "🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬",
    "BLOCKED ⛔": "🟥 BLOCKED ⛔",
}
allowed_locations = {"local", "docker", "ssh"}
allowed_cleanup = {"COMPLETE", "INCOMPLETE"}
allowed_verdicts = {"PASS", "FAIL", "INFO"}
allowed_results = {"PASS", "FAIL", "INCONCLUSIVE"}
graphic_kinds = {"image", "screenshot", "chart", "video", "trace"}


def err(msg):
    errors.append(msg)


def require_string(obj, key, ctx):
    value = obj.get(key)
    if not isinstance(value, str) or not value.strip():
        err(f"{ctx} missing non-empty string field '{key}'")
        return ""
    return value.strip()


def require_list(obj, key, ctx):
    value = obj.get(key)
    if not isinstance(value, list) or not value:
        err(f"{ctx} missing non-empty list field '{key}'")
        return []
    return value


def resolve_path(raw):
    if raw.startswith("http://") or raw.startswith("https://"):
        return None
    candidate = Path(raw)
    if candidate.is_absolute():
        return candidate
    manifest_relative = (manifest_path.parent / candidate).resolve()
    if manifest_relative.exists():
        return manifest_relative
    return (Path.cwd() / candidate).resolve()


errors = []

try:
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    err(f"invalid JSON: {exc}")
    data = None

if not isinstance(data, dict):
    if not errors:
      err("manifest root must be a JSON object")
else:
    run_id = require_string(data, "run_id", "manifest")
    task = require_string(data, "task", "manifest")
    profile = data.get("profile")
    if profile is not None and (not isinstance(profile, str) or not profile.strip()):
        err("manifest field 'profile' must be a non-empty string when provided")
        profile = None
    final_state = require_string(data, "final_state", "manifest")
    status_badge_raw = data.get("status_badge", "")
    if status_badge_raw is None:
        status_badge_raw = ""
    if not isinstance(status_badge_raw, str):
        err("manifest field 'status_badge' must be a string when provided")
        status_badge = ""
    else:
        status_badge = status_badge_raw.strip()
    blocked_by = data.get("blocked_by", "none")

    if final_state and final_state not in allowed_states:
        err("manifest final_state must be VERIFIED ✅, READY FOR HUMAN VERIFICATION 🧑‍🔬, or BLOCKED ⛔")

    if final_state in allowed_states and status_badge and status_badge != allowed_states[final_state]:
        err("status_badge does not match final_state")

    implied_status_badge = allowed_states.get(final_state, "")

    if expected_final_state and final_state != expected_final_state:
        err(f"final_state mismatch: expected '{expected_final_state}' but manifest recorded '{final_state}'")

    if expected_status_badge:
        compare_badge = status_badge or implied_status_badge
        if compare_badge != expected_status_badge:
            err(
                f"status_badge mismatch: expected '{expected_status_badge}' "
                f"but manifest recorded '{status_badge or implied_status_badge or 'missing'}'"
            )

    for label in ("target_evidence_tier", "achieved_evidence_tier"):
        value = data.get(label)
        if value is not None:
            if not isinstance(value, str) or value not in {"Gold", "Silver", "Bronze"}:
                err(f"{label} must be Gold, Silver, or Bronze when provided")

    for label in ("gold_decision_gate", "user_tier_choice_when_gold_gt_10m"):
        value = data.get(label)
        if value is not None and (not isinstance(value, str) or not value.strip()):
            err(f"{label} must be a non-empty string when provided")

    ground_truth = data.get("ground_truth")
    if ground_truth is not None:
        if not isinstance(ground_truth, dict):
            err("ground_truth must be an object when provided")
            ground_truth = {}
        else:
            for field in ("source", "waiver", "h1", "h0", "decision_rule"):
                value = ground_truth.get(field)
                if value is not None and (not isinstance(value, str) or not value.strip()):
                    err(f"ground_truth field '{field}' must be a non-empty string when provided")

    commands = require_list(data, "commands", "manifest")
    saw_ssh_command = False
    saw_browser_signal = False
    for idx, item in enumerate(commands, start=1):
        if not isinstance(item, dict):
            err(f"commands[{idx}] must be an object")
            continue
        command = require_string(item, "command", f"commands[{idx}]")
        location = require_string(item, "location", f"commands[{idx}]")
        require_string(item, "purpose", f"commands[{idx}]")
        require_string(item, "observed_signal", f"commands[{idx}]")
        verdict = require_string(item, "verdict", f"commands[{idx}]")
        if location and location not in allowed_locations:
            err(f"commands[{idx}].location must be one of: {', '.join(sorted(allowed_locations))}")
        if verdict and verdict not in allowed_verdicts:
            err(f"commands[{idx}].verdict must be PASS, FAIL, or INFO")
        if location == "ssh":
            saw_ssh_command = True
        if "browser" in command.lower() or "browser" in item.get("purpose", "").lower() or "playwright" in command.lower():
            saw_browser_signal = True

    artifacts = data.get("artifacts", [])
    if not isinstance(artifacts, list):
        err("manifest field 'artifacts' must be a list when provided")
        artifacts = []
    graphic_count = 0
    for idx, item in enumerate(artifacts, start=1):
        if not isinstance(item, dict):
            err(f"artifacts[{idx}] must be an object")
            continue
        raw_path = require_string(item, "path", f"artifacts[{idx}]")
        kind = require_string(item, "kind", f"artifacts[{idx}]")
        require_string(item, "proves", f"artifacts[{idx}]")
        if kind in graphic_kinds:
            graphic_count += 1
            saw_browser_signal = saw_browser_signal or kind in {"image", "screenshot", "video", "trace"}
        if raw_path:
            resolved = resolve_path(raw_path)
            if resolved is not None and not resolved.exists():
                err(f"artifacts[{idx}].path does not exist: {raw_path}")

    criteria_results = require_list(data, "criteria_results", "manifest")
    for idx, item in enumerate(criteria_results, start=1):
        if not isinstance(item, dict):
            err(f"criteria_results[{idx}] must be an object")
            continue
        require_string(item, "criterion", f"criteria_results[{idx}]")
        result = require_string(item, "result", f"criteria_results[{idx}]")
        require_string(item, "evidence", f"criteria_results[{idx}]")
        if result and result not in allowed_results:
            err(f"criteria_results[{idx}].result must be PASS, FAIL, or INCONCLUSIVE")

    cleanup = data.get("cleanup")
    if not isinstance(cleanup, dict):
        err("manifest missing cleanup object")
        cleanup = {}
    resources_started = cleanup.get("resources_started", "none")
    if not isinstance(resources_started, str) or not resources_started.strip():
        err("cleanup.resources_started must be a non-empty string when provided")
    teardown_commands = cleanup.get("teardown_commands", [])
    if not isinstance(teardown_commands, list):
        err("cleanup.teardown_commands must be a list")
        teardown_commands = []
    require_string(cleanup, "post_cleanup_check", "cleanup")
    cleanup_status = require_string(cleanup, "status", "cleanup")
    if cleanup_status and cleanup_status not in allowed_cleanup:
        err("cleanup.status must be COMPLETE or INCOMPLETE")

    command_ownership = data.get("command_ownership")
    if not isinstance(command_ownership, dict):
        err("manifest missing command_ownership object")
        command_ownership = {}
    agent_ran = require_list(command_ownership, "agent_ran", "command_ownership")
    agent_failed = command_ownership.get("agent_failed", [])
    if not isinstance(agent_failed, list):
        err("command_ownership.agent_failed must be a list")
    human_required_reason = command_ownership.get("human_required_reason", "none")
    if not isinstance(human_required_reason, str) or not human_required_reason.strip():
        err("command_ownership.human_required_reason must be a non-empty string when provided")
        human_required_reason = "none"

    human_verification = data.get("human_verification")
    if final_state == "READY FOR HUMAN VERIFICATION 🧑‍🔬":
        if not isinstance(human_verification, dict):
            err("READY FOR HUMAN VERIFICATION requires a human_verification object")
        else:
            preconditions = human_verification.get("preconditions", [])
            if preconditions and (not isinstance(preconditions, list) or len(preconditions) > 2):
                err("human_verification.preconditions must be a list with at most 2 items")
            steps = require_list(human_verification, "steps", "human_verification")
            if steps and not all(isinstance(item, str) and item.strip() for item in steps):
                err("human_verification.steps must contain only non-empty strings")
            pass_signals = human_verification.get("pass_signals")
            fail_signals = human_verification.get("fail_signals")
            return_condition = human_verification.get("return_condition")
            if not pass_signals:
                err("human_verification.pass_signals is required for READY FOR HUMAN VERIFICATION")
            if not fail_signals:
                err("human_verification.fail_signals is required for READY FOR HUMAN VERIFICATION")
            if not isinstance(return_condition, str) or not return_condition.strip():
                err("human_verification.return_condition is required for READY FOR HUMAN VERIFICATION")
    elif human_verification is not None and not isinstance(human_verification, dict):
        err("human_verification must be an object when provided")

    if cleanup_status == "INCOMPLETE" and final_state != "BLOCKED ⛔":
        err("cleanup.status INCOMPLETE is only allowed when final_state is BLOCKED ⛔")

    if final_state == "BLOCKED ⛔" and (not isinstance(blocked_by, str) or not blocked_by.strip() or blocked_by == "none"):
        err("BLOCKED manifests must explain blocked_by")

    if final_state == "VERIFIED ✅":
        if human_required_reason not in {"none", "n/a"}:
            err("VERIFIED manifests must not leave a human_required_reason outstanding")
        failing_results = [item for item in criteria_results if isinstance(item, dict) and item.get("result") != "PASS"]
        if failing_results:
            err("VERIFIED manifests require every criteria_results entry to be PASS")

if errors:
    print(f"validation failed for {manifest_path}:")
    for item in errors:
        print(f"  - {item}")
    sys.exit(1)

print(f"manifest validation passed: {manifest_path}")
PY
