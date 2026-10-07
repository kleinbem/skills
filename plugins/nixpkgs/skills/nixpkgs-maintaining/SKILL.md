---
name: nixpkgs-maintaining
description: Use when acting as a maintainer of Nixpkgs packages (listed in meta.maintainers) — handling r-ryantm update PRs, using the merge bot, build failures, security backports, sharing maintenance with co-maintainers or a team, and deciding where packaging lives (nixpkgs vs. personal or project flakes).
---

# Maintaining Nixpkgs packages

Sources of truth, in the Nixpkgs checkout: `maintainers/README.md` (role, teams, tools)
and `ci/README.md` ("Nixpkgs merge bot"). Read them before acting on a rule from memory.
For writing the changes themselves, use the `nixpkgs-contributing` skill.

## Where packaging lives
- Nixpkgs is the canonical home. Co-maintainers are listed together in `meta.maintainers`;
  no separate repo per package.
- A personal flake or overlay (e.g. `kleinbem/nix-packages`) is for staging before a merge,
  unreleased versions, and personal packages. Drop a package from it once it is in Nixpkgs.
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

## Routine work
- **Updates:** r-ryantm opens update PRs, driven by `passthru.updateScript`, so keep update scripts
  working. Test the PR (e.g. nixpkgs-review or nixpkgs-review-gha), then approve or merge.
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

## Shared binary caches
- Push only from CI with a cache-scoped token. A personal token in several people's hands means
  everyone who trusts the cache trusts all of their machines.
- Each maintainer may run their own cache. A shared team cache belongs with a team, pushed by CI.
