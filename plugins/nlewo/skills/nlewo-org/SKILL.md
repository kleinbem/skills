---
name: nlewo-org
description: >-
  Owner skill for the nlewo GitHub account (Antoine Eiche's personal account, not an organization; nlewo/comin): security reports, channels, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The nlewo account

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. nlewo is the **personal GitHub account** of Antoine Eiche (owner
type `User`, about 90 public repos), so there is no `.github` repo, no org-wide checks and no
governance file. Sources: each repo's own files and its settings via `gh api`. As of 2026-11-24.

## 0. Org-wide hard rules

None. Each repo sets its own rules; the owner reviews and merges everything. No CLA, no DCO
check, no AI policy.

## 1. Account-wide facts

- **Security:** private vulnerability reporting is off for comin
  (`gh api repos/nlewo/<repo>/private-vulnerability-reporting --jq .enabled`) and there is no
  `SECURITY.md`. Martin decides how to report anything sensitive.
- **Channels:** GitHub issues and PRs; comin has a Matrix room (`#nixos-comin:matrix.org`,
  linked from its readme). No Discussions.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| nlewo/comin | `comin-contributing` | GitOps deployment for NixOS/nix-darwin; runs on nasbook, mac-mini, hass-pi, core-pi, orin-nano |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
