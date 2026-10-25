#!/usr/bin/env bash
# Run the skills refresh (prompts/refresh-skills.md) with a local agent.
#
#   scripts/refresh-skills.sh [scope]     scope = substring of skill directory names
#   AGENT=goose scripts/refresh-skills.sh
#
# The agent works in a fresh clone of main under ~/.cache, never in this
# checkout, and only gets this repo plus read access to GitHub through gh.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
scope=${1:-}
agent=${AGENT:-claude}

prompt=$(cat "$here/prompts/refresh-skills.md")
[ -n "$scope" ] && prompt+=$'\n\nSCOPE: '"$scope"

work=${XDG_CACHE_HOME:-$HOME/.cache}/skills-refresh/$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$(dirname "$work")"
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
  printf '%s\n' "$prompt" >"$work.prompt.md"
  goose run --no-session -i "$work.prompt.md"
  ;;
*)
  echo "refresh-skills: unknown AGENT '$agent' (claude, goose)" >&2
  exit 2
  ;;
esac
