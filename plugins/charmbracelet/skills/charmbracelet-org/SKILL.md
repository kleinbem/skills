---
name: charmbracelet-org
description: >-
  Organization skill for Charm (charmbracelet/* on GitHub: gum, bubbletea, lipgloss, crush, ...): the org-wide CONTRIBUTING (features start as a Discussion, Conventional Commits), shared issue forms and PR template, the reusable CI in charmbracelet/meta, security reports, channels, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The Charm organization (charmbracelet)

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Sources: charmbracelet/.github (`CONTRIBUTING.md`, `SECURITY.md`,
`SUPPORT.md`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`), charmbracelet/meta
(the shared workflows), and crush's `CLA.md`. As of 2026-11-14.

Charm Inc. (charm.land, formerly charm.sh) builds Go terminal tools and libraries. Small team;
public members on GitHub: `andreynering`, `andrinoff`, `meowgorithm`, `Amolith`, `sam0uly`,
`taciturnaxolotl` (others such as `caarlos0` and `aymanbagabas` merge too).

## 0. Org-wide hard rules

- **Features start as a Discussion.** `CONTRIBUTING.md`: "For new features, please **open a
  Discussion** prior to creating a pull request." Maintainers pick from the "Ideas" category when
  they take features. The org PR template asks for it: "I have created a discussion that was
  approved by a maintainer (for new features)." A feature *request* may still be an issue: the
  org's issue forms include "Feature Request".
- **Bug reports and fixes:** "you must include clear steps to showcase the issue before and
  after". PRs need tests or a minimal reproducible example, and must pass all CI. Mark ready only
  when complete.
- **Conventional Commits** for commit messages (release notes are generated from them).
- **Licence statement** (`CONTRIBUTING.md`): contributors agree they authored the content or have
  the rights to it, under the project's MIT licence. No DCO sign-off. No CLA, except crush
  (FSL-licensed, `CLA.md` plus a `cla.yml` workflow).
- **No AI policy** anywhere in the org (`gh search code --owner charmbracelet "AI-generated"`
  finds nothing policy-like); the org ships AI tools itself (crush, mods). Batches of unsolicited
  agent PRs get closed without comment (charmbracelet/gum#1044 to #1053, ten PRs from one author
  on 2026-04-01, closed by `andreynering` the same day).
- "If you know this feature exists in another Charm project, please reference that project's
  implementation and messaging in your design for consistency across the org."

## 1. Org-wide facts

- **Issue forms** (org default, used by repos without their own `.github/ISSUE_TEMPLATE/`):
  "Bug Report" (`type: bug`; Description required, Version, Environment) and "Feature Request"
  (`type: feature`; one Description field). Blank issues allowed.
- **PR template** (org default): two checkboxes (read `CONTRIBUTING.md`; approved Discussion for
  features). Repos may override it (gum does).
- **CI:** repos call reusable workflows from charmbracelet/meta (`build.yml`: `go mod tidy` with a
  clean diff, `go build ./...`, `go test ./...` on Linux, macOS and Windows, plus `govulncheck`;
  `lint.yml`: golangci-lint on the three OSes with the config synced from meta weekly by
  `lint-sync`). Workflows on fork PRs wait for approval (no checks on charmbracelet/gum#1174 two
  weeks after opening).
- **Security:** email `vt100@charm.sh` (`SECURITY.md`; the org profile and `CLA.md` say
  `vt100@charm.land`). Private vulnerability reporting is off on gum. Martin sends the email;
  never details in a public issue.
- **Channels** (`SUPPORT.md`, issue `config.yml`): Discord (charm.land/discord), Slack
  (charm.land/slack), Matrix. Maintainers may convert question issues to Discussions.
- **Response times:** "We're a small team with varied priorities"; many issues and outside PRs
  get no maintainer reply for months (see the repository skill's numbers).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| charmbracelet/gum | `gum-contributing` | shell-script UI CLI; we use `gum table` in kleinbem/kleinbem `tools/jj-fleet.sh` |
| charmbracelet/crush | none yet | AI coding agent; FSL licence, CLA required, `AGENTS.md` |
| charmbracelet/bubbletea, lipgloss, bubbles | none yet | the TUI libraries gum is built on |
