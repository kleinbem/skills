---
name: omacom-org
description: >-
  Organization skill for the omacom GitHub organization (Omarchy Linux, omacom/omarchy-pkgs, omacom/omarchy): security, channels, PR checks, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The omacom organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. omacom is the GitHub organization for Omarchy Linux (Quattro generation),
maintaining the desktop environment, applications, package repository and system installer.
Sources: org repos and workflow configurations via `gh api`. As of 2026-11-12.

## 0. Org-wide hard rules

- **AI Policy:** No ban on AI assistance; contributions welcome when accompanied by clear explanations,
  verifiable reproducers and proper testing. PR disclosures permitted.
- **Licensing:** Repositories are MIT licensed unless vendoring an upstream component (e.g. Linux kernel forks).
- **PR CI:** Workflows run `Approve PR workflows`, `Auto-merge approved package PRs`, and automated review via `Greptile Review`.

## 1. Org-wide facts

- **Security:** Report vulnerabilities privately, not in public GitHub Issues. For Omarchy
  (`omacom/omarchy`), use security@omarchy.org or the HackerOne program at hackerone.com/omarchy.
  See https://github.com/omacom/omarchy/security.
- **Channels:** GitHub Issues and Pull Requests. Upstream CI triggers notify Basecamp chatbot channels (`BASECAMP_CHATBOT_URL`).
- **Packaging:** Arch Linux PKGBUILD recipes hosted in `omacom/omarchy-pkgs` powering `pkgs.omarchy.org`.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| omacom/omarchy-pkgs | `omarchy-pkgs-contributing` | Arch Linux PKGBUILD recipes, builder CI, and package tooling |
| omacom/omarchy | (pending) | Core Quattro desktop shell, Hyprland configs, theme engine |
| omacom/omarchy-iso | (pending) | Arch Linux live installation image |
