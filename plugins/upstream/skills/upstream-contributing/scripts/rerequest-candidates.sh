#!/usr/bin/env bash
# List open PRs by an author where a human reviewer commented, requested changes or had an
# approval dismissed, the author pushed afterwards, and the reviewer is not requested again.
# Those are the PRs where GitHub's "re-request review" button tells the reviewer it's their turn.
# Usage: rerequest-candidates.sh [author]   (default: kleinbem). Read-only.
set -euo pipefail
author=${1:-kleinbem}

gh search prs --author "$author" --state open --limit 200 \
  --json repository,number,url,isDraft \
  --jq '.[]|select(.isDraft|not)|"\(.repository.nameWithOwner) \(.number) \(.url)"' |
while read -r repo n url; do
  requested=$(gh api "repos/$repo/pulls/$n" --jq '[.requested_reviewers[].login]|join(" ")')
  decision=$(gh pr view "$n" -R "$repo" --json reviewDecision --jq .reviewDecision)
  last_commit=$(gh api "repos/$repo/pulls/$n/commits" --paginate --jq '.[].commit.committer.date' | sort | tail -1)
  # Last review per human reviewer; bots and the author are skipped.
  gh api "repos/$repo/pulls/$n/reviews" --paginate \
    --jq ".[]|select(.user.type==\"User\" and .user.login!=\"$author\")|\"\(.user.login) \(.submitted_at) \(.state)\"" |
    { grep -viE 'coderabbit|\[bot\]' || true; } | sort -k1,1 -k2,2 |
    awk '{last[$1]=$2" "$3} END{for (u in last) print u, last[u]}' |
  while read -r reviewer when state; do
    [[ $state == APPROVED ]] && continue
    # A dismissed review doesn't matter once someone else approved.
    [[ $state == DISMISSED && $decision == APPROVED ]] && continue
    [[ " $requested " == *" $reviewer "* ]] && continue
    [[ $last_commit > $when ]] || continue
    echo "$url  $reviewer ($state $when)  last commit $last_commit"
    echo "  gh api -X POST repos/$repo/pulls/$n/requested_reviewers -f 'reviewers[]=$reviewer'"
  done
done
