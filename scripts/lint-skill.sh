#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
README_MD="$REPO_ROOT/README.md"
SKILL_MD="$REPO_ROOT/verification-driven-development/SKILL.md"
OPENAI_YAML="$REPO_ROOT/verification-driven-development/agents/openai.yaml"
CURSOR_MDC="$REPO_ROOT/verification-driven-development/agents/cursor.mdc"

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

require_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Eqi "$pattern" "$path"; then
    add_error "missing required concept in $(basename "$path"): $label"
  fi
}

require_file "$README_MD"
require_file "$SKILL_MD"
require_file "$OPENAI_YAML"
require_file "$CURSOR_MDC"

for path in \
  "$REPO_ROOT/scripts/init-vdd-run.sh" \
  "$REPO_ROOT/scripts/ensure-agent-ignore.sh" \
  "$REPO_ROOT/scripts/render-verification-brief.sh" \
  "$REPO_ROOT/scripts/render-human-verification-card.sh" \
  "$REPO_ROOT/scripts/validate-vdd-report.sh" \
  "$REPO_ROOT/scripts/validate-vdd-manifest.sh" \
  "$REPO_ROOT/scripts/render-vdd-failover-issue.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/init-vdd-run.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/ensure-agent-ignore.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/render-verification-brief.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/render-human-verification-card.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/validate-vdd-report.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/validate-vdd-manifest.sh" \
  "$REPO_ROOT/verification-driven-development/scripts/render-vdd-failover-issue.sh"
do
  require_file "$path"
done

for ref in \
  "$REPO_ROOT/verification-driven-development/references/report-template.md" \
  "$REPO_ROOT/verification-driven-development/references/certificate-template.md" \
  "$REPO_ROOT/verification-driven-development/references/verification-manifest-template.json" \
  "$REPO_ROOT/verification-driven-development/references/closeout-policy.md" \
  "$REPO_ROOT/verification-driven-development/references/closeout-ux-guide.md" \
  "$REPO_ROOT/verification-driven-development/references/evidence-tiers.md" \
  "$REPO_ROOT/verification-driven-development/references/ground-truth-ladder.md" \
  "$REPO_ROOT/verification-driven-development/references/anti-patterns.md" \
  "$REPO_ROOT/verification-driven-development/references/ui-automation-protocol.md" \
  "$REPO_ROOT/verification-driven-development/references/examples.md"
do
  require_file "$ref"
done

if [ "${#ERRORS[@]}" -gt 0 ]; then
  printf 'skill lint failed:\n' >&2
  for e in "${ERRORS[@]}"; do
    printf '  - %s\n' "$e" >&2
  done
  exit 1
fi

if grep -Eq '^##[[:space:]]+README FOR AGENTS([[:space:]]|$)' "$README_MD"; then
  add_error "README.md must be human-only: remove 'README FOR AGENTS' section"
fi
if grep -Eqi '^Dear agentic colleague' "$README_MD"; then
  add_error "README.md contains agent-facing language"
fi
if ! grep -Eq 'Agent behavior is defined in `verification-driven-development/SKILL.md` and `verification-driven-development/agents/openai.yaml`\.' "$README_MD"; then
  add_error "README.md must include a pointer to SKILL.md and agents/openai.yaml"
fi

if [ "$(wc -l < "$SKILL_MD")" -gt 500 ]; then
  add_error "SKILL.md should stay under 500 lines"
fi

require_heading "$SKILL_MD" '^#[[:space:]]+Verification-Driven Development \(VDD\)' '# Verification-Driven Development (VDD)'
require_heading "$SKILL_MD" '^##[[:space:]]+Runtime Surface \(Mandatory\)' '## Runtime Surface (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Command Execution Ownership \(Mandatory\)' '## Command Execution Ownership (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Ground-Truth Ladder \(Mandatory\)' '## Ground-Truth Ladder (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Verification Manifest \(Mandatory\)' '## Verification Manifest (Mandatory)'
require_heading "$SKILL_MD" '^##[[:space:]]+Operating Loop \(Mandatory\)' '## Operating Loop (Mandatory)'
require_heading "$SKILL_MD" '^### Phase P1: Joint Plan' '### Phase P1: Joint Plan'
require_heading "$SKILL_MD" '^### Phase P2: Implement -> Run -> Inspect -> Fix' '### Phase P2: Implement -> Run -> Inspect -> Fix'
require_heading "$SKILL_MD" '^### Phase P3: Closeout' '### Phase P3: Closeout'
require_heading "$SKILL_MD" '^##[[:space:]]+Verification Policy' '## Verification Policy'
require_heading "$SKILL_MD" '^##[[:space:]]+Static-Only Exception \(Strict\)' '## Static-Only Exception (Strict)'
require_heading "$SKILL_MD" '^##[[:space:]]+Required Reference Files' '## Required Reference Files'

for ref in \
  'references/verification-manifest-template.json' \
  'references/ground-truth-ladder.md' \
  'references/closeout-ux-guide.md' \
  'references/anti-patterns.md' \
  'references/examples.md'
do
  if ! grep -Fq "$ref" "$SKILL_MD"; then
    add_error "SKILL.md missing required reference link: $ref"
  fi
done

require_contains "$SKILL_MD" 'runtime surface' 'runtime-surface guidance'
require_contains "$SKILL_MD" 'explicit' 'explicit invocation guidance'
require_contains "$SKILL_MD" 'manifest' 'manifest-driven closeout'
require_contains "$SKILL_MD" 'SSH' 'ssh execution guidance'
require_contains "$SKILL_MD" 'time' 'runtime estimation guidance'
require_contains "$SKILL_MD" 'cleanup' 'cleanup gate semantics'
require_contains "$SKILL_MD" 'Human Verification Card' 'human handoff card'
require_contains "$SKILL_MD" 'anti-pattern' 'anti-pattern review'
require_contains "$SKILL_MD" 'closeout-ux-guide' 'closeout UX guide'
require_contains "$SKILL_MD" 'inline' 'inline visual evidence rule'
require_contains "$SKILL_MD" 'absolute filesystem path' 'absolute inline visual path rule'
require_contains "$SKILL_MD" 'failover' 'failover mode'

if ! python3 -m json.tool "$REPO_ROOT/verification-driven-development/references/verification-manifest-template.json" >/dev/null; then
  add_error "verification-manifest-template.json is not valid JSON"
fi

if ! grep -Fq 'display_name: "Verification-Driven Development (VDD)"' "$OPENAI_YAML"; then
  add_error "openai.yaml display_name drift: expected Verification-Driven Development (VDD)"
fi
require_contains "$OPENAI_YAML" '\$verification-driven-development' 'explicit invocation token'
require_contains "$OPENAI_YAML" 'explicit' 'explicit invocation guidance'
require_contains "$OPENAI_YAML" 'runtime surface' 'runtime-surface guidance'
require_contains "$OPENAI_YAML" 'manifest' 'manifest requirement'
require_contains "$OPENAI_YAML" 'SSH' 'ssh execution guidance'
require_contains "$OPENAI_YAML" 'runtime|cost' 'runtime tradeoff prompt'
require_contains "$OPENAI_YAML" 'cleanup' 'cleanup requirement'
require_contains "$OPENAI_YAML" 'criterion' 'criterion-oriented closeout'
require_contains "$OPENAI_YAML" 'embed' 'inline visual evidence prompt'
require_contains "$OPENAI_YAML" 'absolute filesystem paths?' 'absolute inline visual path prompt'
require_contains "$OPENAI_YAML" 'anti-pattern' 'anti-pattern review'
require_contains "$OPENAI_YAML" 'failover' 'failover mode'

require_contains "$CURSOR_MDC" 'runtime surface' 'runtime-surface guidance'
require_contains "$CURSOR_MDC" 'explicit' 'explicit invocation guidance'
require_contains "$CURSOR_MDC" 'manifest' 'manifest requirement'
require_contains "$CURSOR_MDC" 'SSH' 'ssh execution guidance'
require_contains "$CURSOR_MDC" 'runtime|cost' 'runtime tradeoff prompt'
require_contains "$CURSOR_MDC" 'cleanup' 'cleanup requirement'
require_contains "$CURSOR_MDC" 'criterion' 'criterion-oriented closeout'
require_contains "$CURSOR_MDC" 'embed' 'inline visual evidence prompt'
require_contains "$CURSOR_MDC" 'absolute filesystem paths?' 'absolute inline visual path prompt'
require_contains "$CURSOR_MDC" 'anti-pattern' 'anti-pattern review'
require_contains "$CURSOR_MDC" 'failover' 'failover mode'

if [ "${#ERRORS[@]}" -gt 0 ]; then
  printf 'skill lint failed:\n' >&2
  for e in "${ERRORS[@]}"; do
    printf '  - %s\n' "$e" >&2
  done
  exit 1
fi

echo "skill lint passed"
