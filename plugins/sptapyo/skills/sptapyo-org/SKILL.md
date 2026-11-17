---
name: sptapyo-org
description: >-
  Owner skill for the SPTApyo GitHub account (a personal account, not an organization; SPTApyo/nix-app-center): security reports, how the repos are run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The SPTApyo account

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. SPTApyo is a **personal GitHub account** (owner type `User`), so
there is no `.github` repo, no org-wide checks and no governance file. Sources: each repo's own
files and its settings via `gh api`. As of 2026-11-17.

## 0. Org-wide hard rules

None. Each repo sets its own rules; one person (`@SPTApyo`) owns and merges everything. No CLA and
no DCO check.

## 1. Account-wide facts

- **Security:** private advisories on the repo (Security tab → "Report a vulnerability"); on for
  nix-app-center (`gh api repos/SPTApyo/<repo>/private-vulnerability-reporting --jq .enabled`),
  and its `SECURITY.md` asks for exactly that. Martin files security reports.
- **Channels:** GitHub issues and PRs only (no Discussions, no chat).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| SPTApyo/nix-app-center | `nix-app-center-contributing` | GTK4/libadwaita app store for nixpkgs: try with `nix run`, keep in a generated module |

The account's other own repos (Classmate, NetNebula, shadowtype, stratos-cli) have none yet. A
repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
