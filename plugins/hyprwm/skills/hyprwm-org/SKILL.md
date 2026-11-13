---
name: hyprwm-org
description: >-
  Organization skill for hyprwm (Hyprland Wayland compositor ecosystem, Aquamarine rendering library, hyprland-plugins): vouch gating, strict AI usage policy, CI, and the repository table. Read after upstream-contributing, before repository skills.
disable-model-invocation: true
---

# The hyprwm organization

Layer 2 of 3: read after `upstream-contributing`, before repository skills (`aquamarine-contributing`,
`hyprland-contributing`). The repository skill wins where they differ.

Sources of truth: `hyprwm/.github` (`policies/AI_USAGE.md`, `vouch/VOUCHED.td`, `policies/CODE_OF_CONDUCT.md`),
repository workflows via `gh api`. As of 2026-11-13.

## 0. Org-wide hard rules

- **AI Policy is strictly enforced:** `hyprwm/.github/policies/AI_USAGE.md` forbids autonomous agent
  submissions or AI-written PR descriptions/comments. An AI model must not submit, write the
  description of, or interact with PRs or Issues. Martin writes every text, reviews every patch line,
  and submits PRs himself. Every PR with AI assistance must include an explicit, detailed disclosure
  explaining what AI was used for. Undisclosed or autonomous AI submissions result in permanent bans.
- **Vouch requirement:** All core repos (`Hyprland`, `aquamarine`) run a central vouch check workflow
  (`.github/workflows/vouch-prs.yml`) that validates the author against `hyprwm/.github/vouch/VOUCHED.td`.
  PRs from unvouched authors are **automatically closed by a bot** without human review.
  Contributors must be vouched through community interaction (Discord/Discussions) or establish contact
  on existing GitHub Issues before opening PRs.
- **Licensing:** Core ecosystem projects are licensed under BSD-3-Clause.

## 1. Org-wide facts

- **Channels:** GitHub Issues and Pull Requests. Real-time development and vouch requests happen on
  the Hyprland Discord server and GitHub Discussions.
- **CI:** GitHub Actions run Linux builds (GCC and Clang), Nix flake checks (`nix.yml`), and static
  analysis.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| hyprwm/aquamarine | `aquamarine-contributing` | Light C++ rendering backend library for Wayland and DRM sessions |
| hyprwm/Hyprland | `hyprland-contributing` | Dynamic tiling Wayland compositor |
| hyprwm/hyprland-plugins | `hyprbars-contributing` | Official plugins repository (including hyprbars titlebar plugin) |
| hyprwm/hyprutils | (org skill only) | Shared C++ utilities library |
| hyprwm/hyprlang | (org skill only) | Official configuration language parser |
