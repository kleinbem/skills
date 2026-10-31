---
name: nixpkgs-maintaining
description: Use when acting as a maintainer of Nixpkgs packages (listed in meta.maintainers) — handling r-ryantm update PRs, using the merge bot, build failures, security backports, sharing maintenance with co-maintainers or a team, and deciding where packaging lives (nixpkgs vs. personal or project flakes).
disable-model-invocation: true
---

# Maintaining Nixpkgs packages

Layer 3 of 3: read `upstream-contributing` and `nixos-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Nixpkgs maintenance and wins where they differ.

Sources of truth, in the Nixpkgs checkout: `maintainers/README.md` (role, teams, tools)
and `ci/README.md` ("Nixpkgs merge bot"). Read them before acting on a rule from memory.
For writing the changes themselves, use the `nixpkgs-contributing` skill.

## Where packaging lives
- Nixpkgs is the canonical home. Co-maintainers are listed together in `meta.maintainers`;
  no separate repo per package.
- A personal flake or overlay (e.g. `kleinbem/nix-packages`) is for staging before a merge,
  unreleased versions, and personal packages. Our own open nixpkgs PRs are re-exported from their
  branch, not copied, and leave it automatically once merged; a package broken in nixos-unstable
  is held through kleinbem/nix-holds (`nixpkgs-packaging`, `references/fleet.md`).
- Project flakes (e.g. `mulatta/buzz.nix`) can carry fast-moving parts and modules not yet upstream.
  For shared out-of-tree work, the neutral home is the nix-community org, not a personal repo.
- Before packaging something, search for existing work: open/closed Nixpkgs PRs, nix-community,
  and GitHub flakes for the project. Reach out to their authors instead of duplicating.

## Role (maintainers/README.md)
- Keep the packages working and up to date. Maintainers decide over their packages and may
  revert changes merged without them.
- Committers usually wait about a week for maintainer feedback before merging unendorsed changes;
  the security team may override that.
- Inactive maintainers (no reaction to package notifications for about 3 months) can be removed,
  via a PR that waits a week. Step down explicitly rather than go silent.
- After the first maintainer entry merges, GitHub sends an invite to `@NixOS/nixpkgs-maintainers`.
  It arrives by email and expires after a week. Membership is required for the merge bot.

## Teams
- Several people jointly responsible for a group of packages: add a team in
  `maintainers/team-list.nix`, or create a synced GitHub team under `@NixOS/nixpkgs-maintainers`.
- Organise teams around an area of maintenance (e.g. packaging software from one vendor),
  not around an employer or membership of another project.
- A team is worth it once several packages and people share the work, not on day one.

## What's waiting
`kleinbem/nix-packages`, workflow `watch-maintained.yaml` (daily, `watch/maintained/run.sh`):
lists the packages and modules with `kleinbem` in their maintainers from nixpkgs itself, and posts
into the issue "Watch: maintained nixpkgs packages" when something is new: PRs and issues by
others naming a package, review requests, failed Hydra builds (`nixpkgs/trunk`), failed
nixpkgs-update runs. Start there; run the script locally (`nix shell nixpkgs#brotli -c
watch/maintained/run.sh`, `SINCE=` for a longer window) for the current state.
Committers merge an unanswered PR after about a week, so answer each item within days.

## Routine work
- **Updates:** r-ryantm opens update PRs, driven by `passthru.updateScript`, so keep update scripts
  working. A failed bot run leaves its log at
  `https://nixpkgs-update-logs.nix-community.org/<attr>/` (the watcher reports `^error:` lines).
- **Merge bot:** comment `@NixOS/nixpkgs-merge-bot merge`. All conditions must hold
  (`ci/README.md`, "Merge bot constraints"):
  - the PR targets a development branch and only touches `pkgs/by-name/*`;
  - the PR is opened by r-ryantm or a committer, approved by a committer, or a label backport;
  - you are in `@NixOS/nixpkgs-maintainers` and maintain every package it touches;
  - no committer has an outstanding "changes requested" review.
- **Build failures:** watch zh.fail (failures on master by maintainer) and Hydra, especially in the
  Zero Hydra Failures phase before the May and November releases.
- **Security:** fix on master, then backport to the current stable branch (`backport release-YY.MM`
  label as a maintainer with rights, else cherry-pick `-x`). See `nixpkgs-contributing`, section 0.
- **Reviews:** CI requests reviews from maintainers of the packages a PR rebuilds; that mapping can
  miss, so PR authors should ping the maintainers too. Review other people's PRs to your packages promptly.
- Helpful tools: zh.fail, repology.org (outdated versions per maintainer),
  asymmetric/nixpkgs-update-notifier (failed r-ryantm runs), nixpk.gs/pr-tracker (which channel a PR reached).

## An update PR to one of our packages
For r-ryantm's PRs and other people's updates or fixes:
1. Read the diff and upstream's changelog between the two versions (breaking changes, new
   dependencies, licence change, a removed `updateScript` workaround that still matters).
2. Test it with `kleinbem/nixpkgs-review-gha` `review.yml` on the PR number, `-f post-result=false`
   (its `build`/`review` workflows get disabled by someone else now and then: check
   `gh workflow list --repo kleinbem/nixpkgs-review-gha --all`, enable before dispatch). Judge it with
   `../nixpkgs-contributing/scripts/review-result <run-id> --wait`, never by the run status.
   Run the binary (a real invocation, not `--help`); for a module, its NixOS test.
3. Draft one short comment with the result per system and anything found
   (`nixpkgs-contributing` voice, AI disclosure). Show it to Martin; posting is his call.
4. Merge only when Martin says so: post `@NixOS/nixpkgs-merge-bot merge` as a separate comment.
   The bot answers on the PR; when CI was red it does nothing, and a new comment is needed once
   CI is green. A PR it can't take (outside `pkgs/by-name`, a package we don't maintain, by a
   non-committer without a committer's approval) gets an approving review instead, so a committer
   can merge it.
5. A broken update: request changes with the reason, or open the fix yourself (a PR to the bot's
   branch isn't possible; open a new one and link it).

## Backports
`release-YY.MM` gets security fixes, version updates within the same major line, and new packages
(`CONTRIBUTING.md`, "Changes acceptable for releases"); not mass rebuilds or breaking changes.
- After a fix to one of our packages merges on master, decide per PR whether stable needs it. A
  security fix always does.
- As a member of `@NixOS/nixpkgs-maintainers` you can manage labels: add
  `backport release-YY.MM` to the merged (or still open) master PR; a workflow opens the backport PR
  a few minutes later. Watch it like our own PR: CI, review, then the merge bot (backports via
  label qualify).
- When the label's cherry-pick conflicts (the bot comments so), backport by hand: branch from
  `release-YY.MM` (never `nixos-YY.MM`), `git cherry-pick -x <master commit>` (`-xe` with a reason
  when it isn't obvious; for a squashed merge use the commit on master, not the PR's), title
  prefixed `[YY.MM]`, link the master PR in the body.
- When master and stable differ too much (another major version), write a separate fix for
  `release-YY.MM` and say why in the PR.

## Shared binary caches
- Push only from CI with a cache-scoped token. A personal token in several people's hands means
  everyone who trusts the cache trusts all of their machines.
- Each maintainer may run their own cache. A shared team cache belongs with a team, pushed by CI.
