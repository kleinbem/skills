---
name: brendonovich-org
description: >-
  Owner skill for the Brendonovich GitHub account (Brendan Allan's personal account, not an organization; Brendonovich/swift-rs): security reports, how the repos are run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The Brendonovich account

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Brendonovich is the **personal GitHub account** of Brendan Allan
(owner type `User`, about 120 public repos), so there is no `.github` repo, no org-wide checks and
no governance file. Sources: each repo's own files and its settings via `gh api`. As of 2026-11-25.

## 0. Org-wide hard rules

None. Each repo sets its own rules; the owner merges everything. No CLA, no DCO check, no AI policy.

## 1. Account-wide facts

- **Security:** private vulnerability reporting is off for swift-rs
  (`gh api repos/Brendonovich/<repo>/private-vulnerability-reporting --jq .enabled`) and there is
  no `SECURITY.md`. Martin decides how to report anything sensitive.
- **Channels:** GitHub issues and PRs only (no Discussions).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| Brendonovich/swift-rs | `swift-rs-contributing` | Rust build helper for Swift packages; Berd (block/berd) builds its Swift bridge with it |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
