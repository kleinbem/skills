---
name: wimpysworld-org
description: >-
  Organization skill for Wimpy's World (wimpysworld/*: nothing-but-nix, deb-get, nix-config, sidra, tailor): security reports, how the repos are run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The wimpysworld organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. `wimpysworld` is a GitHub organization run by one maintainer
(`@flexiondotorg`). Its `.github` repo holds only a README, a licence and `dependabot.yml`: no
org-wide `CONTRIBUTING.md`, templates or workflows. Sources: each repo's own files. As of 2026-11-19.

## 0. Org-wide hard rules

- No org-wide CLA, DCO or check. Policies live per repo; nothing-but-nix's `CONTRIBUTING.md`
  holds the AI rules (see its skill).
- Repo settings come from the maintainer's own tool `wimpysworld/tailor` (`.tailor.yml` in each
  repo): rulesets named `Tailor`, required checks set there.

## 1. Org-wide facts

- **Security:** private vulnerability reporting (Security tab, "Report a vulnerability"), per
  each repo's `SECURITY.md`. Martin files security reports.
- **Channels:** GitHub issues. Discussions are off on nothing-but-nix.
- One maintainer writes and merges almost everything (nothing-but-nix: 35 of the last 46 merged
  PRs); outside PRs get reviewed in detail and can take days to weeks.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| wimpysworld/nothing-but-nix | `nothing-but-nix-contributing` | GitHub Action that frees runner disk for a btrfs `/nix`; kleinbem/nix-config's nvme cache build uses it |
| wimpysworld/deb-get | none yet | apt-get for third-party .debs |
| wimpysworld/nix-config | none yet | the maintainer's own NixOS config |
| wimpysworld/tailor | none yet | repo-settings tool behind the `Tailor` rulesets |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
