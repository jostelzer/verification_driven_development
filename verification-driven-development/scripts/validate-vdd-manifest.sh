#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verification-driven-development/scripts/validate-vdd-manifest.sh <verification_manifest_json> [--expected-final-state <state>] [--expected-status-badge <badge>] [--expected-profile <profile>]

Description:
  Validates that a verification manifest contains the semantic evidence needed
  to support a VDD closeout.
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
EXPECTED_PROFILE=""

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
    --expected-profile)
      EXPECTED_PROFILE="${2:-}"
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

python3 - "$MANIFEST_JSON" "$EXPECTED_FINAL_STATE" "$EXPECTED_STATUS_BADGE" "$EXPECTED_PROFILE" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
expected_final_state = sys.argv[2]
expected_status_badge = sys.argv[3]
expected_profile = sys.argv[4]

allowed_states = {
    "VERIFIED ✅": "🟩 VERIFIED ✅",
    "READY FOR HUMAN VERIFICATION 🧑‍🔬": "🟨 READY FOR HUMAN VERIFICATION 🧑‍🔬",
    "BLOCKED ⛔": "🟥 BLOCKED ⛔",
}
allowed_profiles = {
    "api-service",
    "ui-browser",
    "data-pipeline",
    "ml-model",
    "deploy-infra",
    "library-refactor",
    "remote-ssh",
}
allowed_locations = {"local", "docker", "ssh"}
allowed_tiers = {"Gold", "Silver", "Bronze"}
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
    profile = require_string(data, "profile", "manifest")
    final_state = require_string(data, "final_state", "manifest")
    status_badge = require_string(data, "status_badge", "manifest")
    blocked_by = data.get("blocked_by", "none")

    if profile and profile not in allowed_profiles:
        err(f"manifest profile must be one of: {', '.join(sorted(allowed_profiles))}")

    if final_state and final_state not in allowed_states:
        err("manifest final_state must be VERIFIED ✅, READY FOR HUMAN VERIFICATION 🧑‍🔬, or BLOCKED ⛔")

    if final_state in allowed_states and status_badge and status_badge != allowed_states[final_state]:
        err("status_badge does not match final_state")

    if expected_final_state and final_state != expected_final_state:
        err(f"final_state mismatch: expected '{expected_final_state}' but manifest recorded '{final_state}'")

    if expected_status_badge and status_badge != expected_status_badge:
        err(f"status_badge mismatch: expected '{expected_status_badge}' but manifest recorded '{status_badge}'")

    if expected_profile and profile != expected_profile:
        err(f"profile mismatch: expected '{expected_profile}' but manifest recorded '{profile}'")

    target_tier = require_string(data, "target_evidence_tier", "manifest")
    achieved_tier = require_string(data, "achieved_evidence_tier", "manifest")
    gate = require_string(data, "gold_decision_gate", "manifest")
    user_choice = require_string(data, "user_tier_choice_when_gold_gt_10m", "manifest")

    for label, value in (("target_evidence_tier", target_tier), ("achieved_evidence_tier", achieved_tier)):
        if value and value not in allowed_tiers:
            err(f"{label} must be Gold, Silver, or Bronze")

    if gate not in {"<=10m (auto-Gold)", ">10m (user choice required)"}:
        err("gold_decision_gate must be '<=10m (auto-Gold)' or '>10m (user choice required)'")

    if gate == "<=10m (auto-Gold)" and target_tier and target_tier != "Gold":
        err("target_evidence_tier must be Gold when gold_decision_gate is <=10m (auto-Gold)")

    if gate == ">10m (user choice required)":
        choice_tier = ""
        for tier in allowed_tiers:
            if tier in user_choice:
                choice_tier = tier
                break
        if not choice_tier:
            err("user_tier_choice_when_gold_gt_10m must name Bronze, Silver, or Gold")
        elif target_tier and target_tier != choice_tier:
            err("target_evidence_tier must match user_tier_choice_when_gold_gt_10m")

    ground_truth = data.get("ground_truth")
    if not isinstance(ground_truth, dict):
        err("manifest missing ground_truth object")
        ground_truth = {}

    for field in (
        "source",
        "acquisition",
        "sample_size",
        "metrics_and_thresholds",
        "artifact_location",
        "h1",
        "h0",
        "decision_rule",
    ):
        require_string(ground_truth, field, "ground_truth")

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

    artifacts = require_list(data, "artifacts", "manifest")
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
    require_string(cleanup, "resources_started", "cleanup")
    teardown_commands = require_list(cleanup, "teardown_commands", "cleanup")
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
    human_required_reason = require_string(command_ownership, "human_required_reason", "command_ownership")

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

    if profile == "remote-ssh" and not saw_ssh_command:
        err("remote-ssh profile requires at least one command with location 'ssh'")

    if profile == "ui-browser" and final_state == "VERIFIED ✅" and not saw_browser_signal:
        err("ui-browser profile requires at least one browser-path artifact or command signal before VERIFIED")

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
