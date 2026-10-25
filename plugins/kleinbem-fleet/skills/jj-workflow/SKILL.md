---
name: jj-workflow
description: >-
  jj (Jujutsu) in the kleinbem fleet: workspaces for concurrent agents, pushing
  without the oauth hang, bookmarks, rebasing PR branches with bot commits,
  signing. Load before any jj describe, new, rebase, bookmark or push in a
  kleinbem repo, or before rebasing a kleinbem PR.
---
# jj in the kleinbem fleet

Every repo is jj colocated with git. Use jj, raw git only to rescue.

## Workspaces

- Another session may use the same primary checkout at any time. Never commit there, not even a
  one-file lock bump: claim a workspace first, `cd ~/Develop/github.com/kleinbem/nix && just jj::ws-new <repo> <name>`,
  then work in `<repo>.ws/<name>/`. `jj::ws-list` shows them, `jj::ws-gc` reaps empty ones.
- Added workspaces have no `.git`: raw git and `gh pr create --fill` don't work there (pass
  `--title`/`--body`); `jj git push` does. "Working copy is stale": `jj workspace update-stale`.
- Parallel Bash calls share one cwd. Never send a VCS-mutating call (describe, new, bookmark,
  push) together with other calls that `cd` elsewhere; chain it in one call that starts with an
  absolute `cd`, and check `jj log -r @` shows the expected parent.

## Editing

- `jj new <base>` with edits in `@` leaves them behind in the old commit. To move pending work onto
  a new base: `jj rebase -s @ -d main@origin`. Run `jj diff --stat` after any new or rebase.
- Splitting with `jj new <parent>` + `jj restore --from X --to @ <paths>` can pick up another
  session's concurrent edits: check `jj diff --summary` before describing.
- Pushing `@` to a branch with raw git (a pre-flight branch) makes it immutable, and jj quietly
  starts a new empty `@`. Keep an empty `@` on top (`jj new <change>`), rebase by change id, never
  `-r @`.
- Recovery: `jj op log`, then `jj undo` or `jj op restore <op>`.

## Pushing

- `jj git push` can hang on the `oauth` credential helper. Stay in jj and inject the gh helper:
  ```
  GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false SSH_ASKPASS=/bin/false \
  GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=credential.helper GIT_CONFIG_VALUE_0= \
  GIT_CONFIG_KEY_1=credential.helper GIT_CONFIG_VALUE_1='!gh auth git-credential' \
  timeout 120 jj git push -b <bookmark>
  ```
  (the empty first value resets the oauth/cache helpers; ASKPASS stops the desktop popup).
- Plain `jj git push` after `jj describe` says "Nothing changed" while `main` hasn't moved. From a
  conductor (`nix/`, `openwrt/`, `kleinbem/`) `just jj::push-all <repo>` advances `main` and
  pushes; finish with `jj new`, so the dashboard shows the repo `(empty)`. If push-all reports
  "up to date" after a real change, check `jj log -r 'main..@'`: a commit on a stale base can't
  move `main` forward and the error is swallowed.
- Bookmarks:
  - Check `jj bookmark create X -r @` succeeded before `jj-push --bookmark X`: with no `X`,
    jj-push advances the nearest bookmark, which can be `main` (fix:
    `jj bookmark set main -r main@origin --allow-backwards`).
  - After a deleted branch, `create` fails; use `jj bookmark set X -r @`, or jj-push pushes the
    deletion and GitHub closes the PR.
  - Never `jj abandon` the commit a bookmark points at, for the same reason.
  - Stacked PRs close when the base PR merges and its branch is deleted: rebase onto main, open
    a new PR.

## Rebasing kleinbem PR branches

- The sync-docs bot pushes "docs: sync generated reference docs" commits onto nix-config PR
  branches. To rebase: `jj bookmark set <b> -r <my change> --allow-backwards`, then
  `jj rebase -r <my change> -d main@origin` and push. Never `jj rebase -b <b>` (rewrites the bot
  commits unsigned) and never derive the commit from the remote bookmark. Check
  `gh pr view --json files` after the push.
- `gh pr update-branch --rebase` leaves commits unsigned, and kleinbem rulesets require
  signatures: the PR stays BLOCKED with green checks. Rebase locally (signed), or use
  `update-branch` without `--rebase`. Check `gh api repos/<r>/commits/<sha> -q .commit.verification.verified`.
- `gh pr checks` is empty for a fresh head: wait for the full check count before trusting
  "nothing pending".

## Signing

jj signs its own commits with the YubiKey's no-touch key. With the key present, `jj describe` and
pushes work unattended from the Bash tool. Without it, every jj command that snapshots fails, so
check `fido2-token -L` and `jj config get signing.backend`; if signing can't work, leave changes as
uncommitted git edits and tell Martin.
