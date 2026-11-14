---
name: omacom-org
description: >-
  Organization skill for the omacom GitHub organization (Omarchy Linux by DHH, formerly basecamp/omarchy): AI stance, bots, security reporting, channels and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The omacom organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. omacom is the organization for Omarchy Linux (Quattro generation):
the distribution (omacom/omarchy), its package repo, ISO, Apple Silicon port and a few dozen
Omarchy apps. Omarchy moved here from basecamp/omarchy; old basecamp URLs redirect.
No org `.github` repo. Sources: each repo's files and recent PRs via `gh api`. As of 2026-11-14.

## 0. Org-wide hard rules

- **AI:** no written policy in any repo; AI-assisted PRs are reviewed normally and the
  maintainers run AI agents themselves. Add one disclosure line at the end of the body.
- **Bots on every PR:** Greptile Review (omarchy, omarchy-pkgs, omasnap). On omacom/omarchy the
  maintainers' triage agent **omarchybot** reproduces, labels, picks between duplicate PRs and
  closes on the maintainer's behalf; answer it like a maintainer.
- **No DCO, no CLA.** MIT unless a repo vendors an upstream component (kernel, mesa, m1n1).

## 1. Org-wide facts

- **Security:** privately to security@omarchy.org (omacom/omarchy `.github/SECURITY.md`), never
  in issues, Discord or social media.
- **Channels:** Discord (https://omarchy.org/discord) for support. Issue rules differ per repo:
  omacom/omarchy takes verified bugs only and sends ideas to its Discussions; check each repo's
  own templates and docs before filing.
- **Governance:** DHH decides and merges most of omacom/omarchy; regular contributors own areas
  (birkskyum: ARM hardware). Packages build on `pkgs.omarchy.org` from omacom/omarchy-pkgs.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| omacom/omarchy | `omarchy-contributing` | The distribution: shell, configs, `bin/`, migrations; default branch `quattro` |
| omacom/omarchy-pkgs | `omarchy-pkgs-contributing` | Arch PKGBUILD recipes, builder CI, package tooling |
| omacom/omasnap | none yet | Screenshot editor; Martin's omacom/omasnap#232 open (first contact skipped the skill) |
| omacom/omarchy-iso | none yet | Installation image |
