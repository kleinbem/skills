---
name: anduril-org
description: >-
  Organization skill for the anduril GitHub organization (Anduril Industries; we touch only anduril/jetpack-nixos): org-wide rules, security reports and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The anduril organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Anduril Industries publishes jetpack-nixos (about 490 stars) and its
Lattice SDKs and sample apps here. The org has no `.github` repo, so no org-wide CONTRIBUTING,
SECURITY or templates. Sources: `gh api orgs/anduril`, `gh api orgs/anduril/repos`, the
jetpack-nixos clone. As of 2026-11-07.

## 0. Org-wide hard rules

None found: no CLA, no DCO check, no AI policy, no org-wide check runs. Each repo sets its own.

## 1. Org-wide facts

- **Security:** no `SECURITY.md`, and private vulnerability reporting is off on jetpack-nixos
  (`gh api repos/anduril/jetpack-nixos/private-vulnerability-reporting --jq .enabled` → `false`).
  For a real vulnerability, ask in a public issue for a private contact without details.
- **Channels:** GitHub issues and PRs only (no Discussions).
- Employees (`*-anduril` logins, `@anduril.com` addresses) and outside contributors (Ghaf/TII,
  hobbyists) both work on jetpack-nixos.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| anduril/jetpack-nixos | `jetpack-nixos-contributing` | NixOS module + packages for NVIDIA Jetson (JetPack 5/6/7); kleinbem/nix-hardware uses it for orin-nano |
