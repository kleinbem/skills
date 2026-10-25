#!/usr/bin/env bash
# Run the skills refresh (prompts/refresh-skills.md) with a local agent.
#
#   scripts/refresh-skills.sh [scope]     scope = substring of skill directory names
#   AGENT=goose scripts/refresh-skills.sh
#
# The agent works in a throwaway clone of main, never in this checkout, and
# only gets this repo plus read access to GitHub through gh. It merges its
# own PR (see the prompt); the clone is deleted when the run ends.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
scope=${1:-}
agent=${AGENT:-claude}

prompt=$(cat "$here/prompts/refresh-skills.md")
[ -n "$scope" ] && prompt+=$'\n\nSCOPE: '"$scope"

tmp=$(mktemp -d -t skills-refresh.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
work=$tmp/skills
gh repo clone kleinbem/skills "$work" -- --quiet
cd "$work"
echo "refresh-skills: agent=$agent scope=${scope:-all} in $work" >&2

case "$agent" in
claude)
  claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Bash(gh:*)" "Bash(git:*)" "Bash(curl:*)" "Bash(jq:*)" \
    "Bash(claude plugin validate:*)" Read Edit Write Glob Grep WebFetch
  ;;
goose)
  printf '%s\n' "$prompt" >"$tmp/prompt.md"
  goose run --no-session -i "$tmp/prompt.md"
  ;;
*)
  echo "refresh-skills: unknown AGENT '$agent' (claude, goose)" >&2
  exit 2
  ;;
esac
