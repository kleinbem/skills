---
name: tao12345666333-org
description: >-
  Owner skill for the tao12345666333 GitHub account (Jintao Zhang's personal account, not an organization; tao12345666333/amp-acp): security reports, how the repos are run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The tao12345666333 account

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. tao12345666333 is the **personal GitHub account** of Jintao Zhang
(owner type `User`, about 210 public repos), so there is no `.github` repo, no org-wide checks and
no governance file. Sources: each repo's own files and its settings via `gh api`. As of 2026-11-11.

## 0. Org-wide hard rules

None. Each repo sets its own rules; the owner merges everything. No CLA, no DCO check, no AI policy.

## 1. Account-wide facts

- **Security:** private vulnerability reporting is off for amp-acp
  (`gh api repos/tao12345666333/<repo>/private-vulnerability-reporting --jq .enabled`) and there
  is no `SECURITY.md`. Martin decides how to report anything sensitive.
- **Channels:** GitHub issues and PRs only (no Discussions).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| tao12345666333/amp-acp | `amp-acp-contributing` | ACP adapter for Amp; we package it in nixpkgs (NixOS/nixpkgs#584499) |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
