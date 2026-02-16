#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPO="jostelzer/verification_driven_development"
DEFAULT_STACK_LINES="120"
DEFAULT_MAX_URL_BODY_CHARS="6000"

usage() {
  cat <<'EOF'
Usage:
  scripts/render-vdd-failover-issue.sh [options]

Description:
  Builds a prefilled GitHub issue URL and copy/paste markdown body for
  VDD tooling failures (validator/render/template/internal workflow errors).

Options:
  --summary <text>           Short failure summary. Default: "VDD tooling failure"
  --title <text>             GitHub issue title. Default: "VDD failover: <summary>"
  --repo <owner/name>        GitHub repo slug. Auto-detected from git origin when possible.
                             Fallback: jostelzer/verification_driven_development
  --failed-command <text>    Exact command that failed (optional)
  --exit-code <code>         Exit code from failed command (optional)
  --stacktrace <text>        Stack trace content (optional)
  --stacktrace-file <path>   File containing stack trace content (optional)
  --max-stack-lines <n>      Max stack-trace lines in output body. Default: 120
  --max-url-body-chars <n>   Max body chars included in URL prefill. Default: 6000
  -h, --help                 Show this help

Input:
  If --stacktrace / --stacktrace-file is not set and stdin is piped, stdin is used.
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_REPO_ROOT="$(cd -- "$SKILL_ROOT/.." && pwd)"

SUMMARY="VDD tooling failure"
TITLE=""
REPO=""
FAILED_COMMAND=""
EXIT_CODE=""
STACKTRACE=""
STACKTRACE_FILE=""
MAX_STACK_LINES="$DEFAULT_STACK_LINES"
MAX_URL_BODY_CHARS="$DEFAULT_MAX_URL_BODY_CHARS"

detect_repo_slug() {
  local root="$1"
  local remote_url=""
  if ! remote_url="$(git -C "$root" remote get-url origin 2>/dev/null)"; then
    return 1
  fi

  case "$remote_url" in
    git@github.com:*)
      remote_url="${remote_url#git@github.com:}"
      remote_url="${remote_url%.git}"
      printf '%s\n' "$remote_url"
      return 0
      ;;
    https://github.com/*)
      remote_url="${remote_url#https://github.com/}"
      remote_url="${remote_url%.git}"
      printf '%s\n' "$remote_url"
      return 0
      ;;
    ssh://git@github.com/*)
      remote_url="${remote_url#ssh://git@github.com/}"
      remote_url="${remote_url%.git}"
      printf '%s\n' "$remote_url"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

urlencode() {
  local input="$1"
  local out=""
  local i
  local ch
  local hex
  local LC_ALL=C

  for ((i=0; i<${#input}; i++)); do
    ch="${input:i:1}"
    case "$ch" in
      [a-zA-Z0-9.~_-])
        out+="$ch"
        ;;
      " ")
        out+='%20'
        ;;
      $'\n')
        out+='%0A'
        ;;
      *)
        hex="$(printf '%s' "$ch" | od -An -tx1 | tr -d ' \n' | tr '[:lower:]' '[:upper:]')"
        if [ -n "$hex" ]; then
          out+="%$hex"
        fi
        ;;
    esac
  done

  printf '%s' "$out"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --summary)
      SUMMARY="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --failed-command)
      FAILED_COMMAND="${2:-}"
      shift 2
      ;;
    --exit-code)
      EXIT_CODE="${2:-}"
      shift 2
      ;;
    --stacktrace)
      STACKTRACE="${2:-}"
      shift 2
      ;;
    --stacktrace-file)
      STACKTRACE_FILE="${2:-}"
      shift 2
      ;;
    --max-stack-lines)
      MAX_STACK_LINES="${2:-}"
      shift 2
      ;;
    --max-url-body-chars)
      MAX_URL_BODY_CHARS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -n "$STACKTRACE" ] && [ -n "$STACKTRACE_FILE" ]; then
  echo "error: use either --stacktrace or --stacktrace-file, not both" >&2
  exit 2
fi

if [ -n "$STACKTRACE_FILE" ]; then
  if [ ! -f "$STACKTRACE_FILE" ]; then
    echo "error: stacktrace file does not exist: $STACKTRACE_FILE" >&2
    exit 1
  fi
  STACKTRACE="$(cat "$STACKTRACE_FILE")"
fi

if [ -z "$STACKTRACE" ] && [ ! -t 0 ]; then
  STACKTRACE="$(cat)"
fi

if [ -z "$STACKTRACE" ]; then
  STACKTRACE="(no stack trace captured)"
fi

if ! [[ "$MAX_STACK_LINES" =~ ^[0-9]+$ ]] || [ "$MAX_STACK_LINES" -le 0 ]; then
  echo "error: --max-stack-lines must be a positive integer" >&2
  exit 2
fi

if ! [[ "$MAX_URL_BODY_CHARS" =~ ^[0-9]+$ ]] || [ "$MAX_URL_BODY_CHARS" -le 0 ]; then
  echo "error: --max-url-body-chars must be a positive integer" >&2
  exit 2
fi

if [ -z "$REPO" ]; then
  if REPO="$(detect_repo_slug "$SOURCE_REPO_ROOT" 2>/dev/null)"; then
    :
  elif REPO="$(detect_repo_slug "$SKILL_ROOT" 2>/dev/null)"; then
    :
  else
    REPO="$DEFAULT_REPO"
  fi
fi

if ! [[ "$REPO" =~ ^[[:alnum:]_.-]+/[[:alnum:]_.-]+$ ]]; then
  echo "error: --repo must be in owner/name format (received: $REPO)" >&2
  exit 2
fi

if [ -z "$TITLE" ]; then
  TITLE="VDD failover: $SUMMARY"
fi

STACKTRACE_TRIMMED="$(
  printf '%s\n' "$STACKTRACE" | awk -v max_lines="$MAX_STACK_LINES" '
    NR <= max_lines { print; next }
    END {
      if (NR > max_lines) {
        printf "... [truncated %d additional line(s)]\n", NR - max_lines
      }
    }
  '
)"

TIMESTAMP_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FAILED_COMMAND_DISPLAY="${FAILED_COMMAND:-not provided}"
EXIT_CODE_DISPLAY="${EXIT_CODE:-not provided}"

ISSUE_BODY="$(cat <<EOF
## VDD Failover Report

- Timestamp (UTC): $TIMESTAMP_UTC
- Summary: $SUMMARY
- Failed command: \`$FAILED_COMMAND_DISPLAY\`
- Exit code: \`$EXIT_CODE_DISPLAY\`
- Working directory: \`$PWD\`

## Stack Trace

\`\`\`text
$STACKTRACE_TRIMMED
\`\`\`

## Expected Behavior

VDD should keep verification guidance stable and return actionable output without internal tool failures.

## Additional Context

Attach run artifacts, commit SHA, and environment details if available.
EOF
)"

BODY_FOR_URL="$ISSUE_BODY"
URL_BODY_TRUNCATED="false"
if [ "${#BODY_FOR_URL}" -gt "$MAX_URL_BODY_CHARS" ]; then
  BODY_FOR_URL="$(printf '%s' "$BODY_FOR_URL" | cut -c1-"$MAX_URL_BODY_CHARS")"
  BODY_FOR_URL="${BODY_FOR_URL}"$'\n\n''[Body truncated for URL prefill. Copy full body from script output.]'
  URL_BODY_TRUNCATED="true"
fi

ISSUE_URL="https://github.com/${REPO}/issues/new?title=$(urlencode "$TITLE")&body=$(urlencode "$BODY_FOR_URL")"

echo "Issue Link:"
echo "$ISSUE_URL"
echo
echo "Issue Title:"
echo "$TITLE"
echo
echo "Issue Body (copy/paste):"
echo "$ISSUE_BODY"

if [ "$URL_BODY_TRUNCATED" = "true" ]; then
  echo
  echo "Note: URL body was truncated to ${MAX_URL_BODY_CHARS} characters. Use the full body above when filing."
fi
