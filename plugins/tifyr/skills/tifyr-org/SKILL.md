---
name: tifyr-org
description: >-
  Organization skill for the tifyr GitHub organization (tifyr/gimp3-mcp, its only repo): security reports, how it is run, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The tifyr organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. tifyr was created on 2026-09-14 to publish gimp3-mcp; it has one
public repo, no `.github` repo, no public members and no org-wide checks. Sources: the repo's own
files and its settings via `gh api`. As of 2026-11-01.

## 0. Org-wide hard rules

None. No CLA, no DCO check, no AI policy. One maintainer (`@kajborjeson`) commits and merges
everything.

## 1. Org-wide facts

- **Security:** no `SECURITY.md`, and private vulnerability reporting is off
  (`gh api repos/tifyr/gimp3-mcp/private-vulnerability-reporting --jq .enabled` → `false`).
  Don't open a public issue for a security bug; Martin contacts the maintainer first.
- **Channels:** GitHub issues only (no Discussions, no wiki, no chat).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| tifyr/gimp3-mcp | `gimp3-mcp-contributing` | MCP server + GIMP 3 plugin; we package it in kleinbem/nix-packages |
