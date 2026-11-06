#!/usr/bin/env bash
# Run the skills refresh (prompts/refresh-skills.md) with a local agent.
#
#   scripts/refresh-skills.sh [scope]     scope = substring of skill directory names
#   AGENT=goose scripts/refresh-skills.sh
#
# The agent works in a throwaway clone of main (deleted afterwards), never in
# this checkout, and opens its own auto-merging PR as the prompt says.
#
# It reads untrusted upstream text, so it gets a fine-grained token for
# kleinbem/skills only (contents + pull requests write), never the gh login.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
scope=${1:-}
agent=${AGENT:-claude}

prompt=$(cat "$here/prompts/refresh-skills.md")
if [ -n "$scope" ]; then
  prompt+=$'\n\nSCOPE: '"$scope"
fi

token_file=${SKILLS_REFRESH_TOKEN_FILE:-/run/secrets/skills_refresh_token}
token=$( { tr -d '[:space:]' <"$token_file"; } 2>/dev/null || true)
if [ -z "$token" ]; then
  echo "refresh-skills: no token at $token_file (fine-grained PAT for kleinbem/skills," >&2
  echo "contents + pull requests write). Not falling back to the gh login." >&2
  exit 1
fi
# gh prefers GH_TOKEN, then falls back to GITHUB_TOKEN: drop any inherited one.
unset GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
export GH_TOKEN=$token

tmp=$(mktemp -d -t skills-refresh.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
# gh and git see only the scoped token: an empty gh config, and git's own
# helpers (oauth, cache) replaced by gh's, which answers with GH_TOKEN.
export GH_CONFIG_DIR=$tmp/gh
mkdir -p "$GH_CONFIG_DIR"
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false SSH_ASKPASS=/bin/false
export GIT_CONFIG_COUNT=2 \
  GIT_CONFIG_KEY_0=credential.helper GIT_CONFIG_VALUE_0='' \
  GIT_CONFIG_KEY_1=credential.helper GIT_CONFIG_VALUE_1='!gh auth git-credential'
work=$tmp/skills
git clone --quiet https://github.com/kleinbem/skills.git "$work"
cd "$work"
echo "refresh-skills: agent=$agent scope=${scope:-all} in $work" >&2

case "$agent" in
claude)
  claude -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Bash(gh:*)" "Bash(git:*)" "Bash(jq:*)" \
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
