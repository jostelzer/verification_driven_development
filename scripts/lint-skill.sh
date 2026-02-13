#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
README_MD="$REPO_ROOT/README.md"
SKILL_MD="$REPO_ROOT/verification-driven-development/SKILL.md"
OPENAI_YAML="$REPO_ROOT/verification-driven-development/agents/openai.yaml"

declare -a ERRORS=()

add_error() {
  ERRORS+=("$1")
}

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    add_error "missing required file: $path"
  fi
}

require_heading() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Eq "$pattern" "$path"; then
    add_error "missing required heading in $(basename "$path"): $label"
  fi
}

require_file "$README_MD"
require_file "$SKILL_MD"
require_file "$OPENAI_YAML"

if [ "${#ERRORS[@]}" -gt 0 ]; then
  printf 'skill lint failed:\n' >&2
  for e in "${ERRORS[@]}"; do
    printf '  - %s\n' "$e" >&2
  done
  exit 1
fi

# README must be human-only.
if grep -Eq '^##[[:space:]]+README FOR AGENTS([[:space:]]|$)' "$README_MD"; then
  add_error "README.md must be human-only: remove 'README FOR AGENTS' section"
fi
if grep -Eqi '^Dear agentic colleague' "$README_MD"; then
  add_error "README.md contains agent-facing language"
fi
if ! grep -Eq 'Agent behavior is defined in `verification-driven-development/SKILL.md` and `verification-driven-development/agents/openai.yaml`\.' "$README_MD"; then
  add_error "README.md must include a pointer to SKILL.md and agents/openai.yaml"
fi

# SKILL core structure and required references.
require_heading "$SKILL_MD" '^#[[:space:]]+Verification-Driven Development \(VDD\)' '# Verification-Driven Development (VDD)'
require_heading "$SKILL_MD" '^##[[:space:]]+Command Execution Ownership \(Mandatory\)' '## Command Execution Ownership (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Inputs Required Before Claiming `VERIFIED`' '## Inputs Required Before Claiming `VERIFIED`'
require_heading "$SKILL_MD" '^##[[:space:]]+Ground-Truth Requirement \(Mandatory\)' '## Ground-Truth Requirement (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Operating Loop \(Mandatory\)' '## Operating Loop (Mandatory)'
require_heading "$SKILL_MD" '^### Phase P1: Joint Plan' '### Phase P1: Joint Plan'
require_heading "$SKILL_MD" '^### Phase P2: Implement -> Run -> Inspect -> Fix' '### Phase P2: Implement -> Run -> Inspect -> Fix'
require_heading "$SKILL_MD" '^### Phase P3: Closeout' '### Phase P3: Closeout'
require_heading "$SKILL_MD" '^##[[:space:]]+Verification Policy' '## Verification Policy'
require_heading "$SKILL_MD" '^##[[:space:]]+Static-Only Exception \(Strict\)' '## Static-Only Exception (Strict)'
require_heading "$SKILL_MD" '^##[[:space:]]+Required Reference Files' '## Required Reference Files'

for ref in \
  'references/report-template.md' \
  'references/certificate-template.md' \
  'references/verification-brief-template.md' \
  'references/closeout-policy.md' \
  'references/evidence-tiers.md' \
  'references/ui-automation-protocol.md'
do
  if ! grep -Fq "$ref" "$SKILL_MD"; then
    add_error "SKILL.md missing required reference link: $ref"
  fi
done

if ! grep -Fq 'target evidence tier (`Bronze` | `Silver` | `Gold`)' "$SKILL_MD"; then
  add_error "SKILL.md must require selecting a target evidence tier in Phase P1"
fi

# openai.yaml sync checks against SKILL frontmatter/name and core behavior cues.
skill_name="$(awk -F': *' '/^name:/ {print $2; exit}' "$SKILL_MD" | tr -d '"')"
if [ -z "$skill_name" ]; then
  add_error "could not parse skill name from SKILL.md frontmatter"
fi

if ! grep -Fq 'display_name: "Verification-Driven Development (VDD)"' "$OPENAI_YAML"; then
  add_error "openai.yaml display_name drift: expected Verification-Driven Development (VDD)"
fi

if [ -n "$skill_name" ] && ! grep -Fq "\$$skill_name (VDD)" "$OPENAI_YAML"; then
  add_error "openai.yaml default_prompt drift: missing invocation token for \$$skill_name"
fi

if ! grep -Eiq 'short_description:.*verification' "$OPENAI_YAML"; then
  add_error "openai.yaml short_description must mention verification-first behavior"
fi

for token in \
  'joint implementation and verification plan' \
  'target evidence tier' \
  'executable checks' \
  'evidence artifacts' \
  'certificate' \
  'Verification Brief' \
  'validate report format'
do
  if ! grep -Fqi "$token" "$OPENAI_YAML"; then
    add_error "openai.yaml default_prompt drift: missing token '$token'"
  fi
done

if [ "${#ERRORS[@]}" -gt 0 ]; then
  printf 'skill lint failed:\n' >&2
  for e in "${ERRORS[@]}"; do
    printf '  - %s\n' "$e" >&2
  done
  exit 1
fi

echo "skill lint passed"
