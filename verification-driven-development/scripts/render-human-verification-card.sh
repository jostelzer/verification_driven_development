#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  verification-driven-development/scripts/render-human-verification-card.sh <verification_manifest_json>

Description:
  Renders the compact Human Verification Card from a verification manifest.
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

MANIFEST_JSON="$1"
if [ ! -f "$MANIFEST_JSON" ]; then
  echo "error: manifest file does not exist: $MANIFEST_JSON" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: required command not found: python3" >&2
  exit 1
fi

python3 - "$MANIFEST_JSON" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
data = json.loads(manifest_path.read_text(encoding="utf-8"))
human = data.get("human_verification")

if not isinstance(human, dict):
    sys.stderr.write("error: manifest missing human_verification block\n")
    sys.exit(1)

preconditions = human.get("preconditions") or []
steps = human.get("steps") or []
operator_notes = human.get("operator_notes") or []
pass_signals = human.get("pass_signals")
fail_signals = human.get("fail_signals")
return_condition = human.get("return_condition")

if not steps or not pass_signals or not fail_signals or not return_condition:
    sys.stderr.write("error: human_verification block is incomplete\n")
    sys.exit(1)

print("## Human Verification Card")
print()
print("Preconditions:")
if preconditions:
    for item in preconditions:
        print(f"- {item}")
else:
    print("- none")

print("Steps:")
for idx, item in enumerate(steps, start=1):
    print(f"{idx}. {item}")

def emit_signal(label, value):
    if isinstance(value, list):
        joined = "; ".join(str(item) for item in value if str(item).strip())
    else:
        joined = str(value).strip()
    print(f"{label}: {joined}")

emit_signal("Pass signal(s)", pass_signals)
emit_signal("Fail signal(s)", fail_signals)
emit_signal("Return condition", return_condition)

if operator_notes:
    print("Operator Notes:")
    for item in operator_notes:
        print(f"- {item}")
PY
