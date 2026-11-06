---
name: noooste-org
description: >-
  Owner skill for the Noooste GitHub account (a personal account, not an organization; Noooste/garage-ui, azuretls-client): security reports, how the repos are run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The Noooste account

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Noooste is a **personal GitHub account** (owner type `User`), so
there is no `.github` repo, no org-wide checks and no governance file. Sources: each repo's own
files and its settings via `gh api`. As of 2026-11-01.

## 0. Org-wide hard rules

None. Each repo sets its own rules; one person (`@Noooste`) owns and merges everything. No CLA, no
DCO check, no AI policy anywhere.

## 1. Account-wide facts

- **Security:** use the repo's Security tab → "Report a vulnerability" (private vulnerability
  reporting is on for garage-ui:
  `gh api repos/Noooste/<repo>/private-vulnerability-reporting --jq .enabled`). garage-ui's
  `CONTRIBUTING.md` says to email security bugs, but its address is blank (template leftover).
  Martin files security reports.
- **Channels:** GitHub issues only (no Discussions, no chat).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| Noooste/garage-ui | `garage-ui-contributing` | Garage web UI; we package it in nixpkgs (NixOS/nixpkgs#580190) |
| Noooste/azuretls-client | none yet | Go HTTP client, ~470 stars |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
