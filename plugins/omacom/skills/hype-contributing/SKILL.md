---
name: hype-contributing
description: Use when preparing an issue or PR for omacom/hype (Omarchy's Qt 6 Markdown presentation app with a headless CLI), or carrying a hype fix downstream in nixpkgs; covers CI, title style, how outside PRs fare and running the tests.
disable-model-invocation: true
---

# omacom/hype Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `omacom-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to hype and wins
where they differ.

Sources: `README.md`, `.github/workflows/test.yml`, merged and closed PRs (`gh pr list -R
omacom/hype --state all`). No `CONTRIBUTING.md`, `AGENTS.md` or PR template. As of 2026-11-15.

## 0. Before starting
- Default branch `master`. Search issues and PRs first; small fixes go straight to a PR.
- Packaging lives in omacom/omarchy-pkgs (#54): a packaging change goes there, not here. The
  version comes from the release (#56); CMake reads it from a source directory named
  `hype-<version>`, else it reports `dev`.

## 1. PRs
- **Title:** a plain imperative sentence, no Conventional Commits prefix ("Quit with Ctrl+Q",
  "Keep hype render from overwriting its presentation").
- **Body:** prose: the problem, what changed, how it was tested (outside PRs like #29 give
  measurements). One AI disclosure line at the end (org rule). No DCO.
- dhh merges; most changes come from him and from omarchybot, the maintainers' agent. Outside
  PRs do land (mikkovedru 10 of 13, ssandys 3 of 3 as of 2026-11-15), usually without review
  comments. Larger features from outside were closed (#36 macOS port, #39, #33).

## 2. Testing
- CI (`test.yml`): an `archlinux:latest` container installs the `depends`, `makedepends` and
  `checkdepends` of the PKGBUILD in omarchy-pkgs, then runs `bin/build` and
  `dbus-run-session -- bin/test` as a non-root user with `LANG=en_US.UTF-8`.
- Locally on NixOS: the nixpkgs package (`nix-build -A hype`, `hype.tests.full` for the C++
  tests that need Qt Pdf) runs the same ctest suite in the sandbox.
- Tests that hardcode `/usr/bin/<tool>` fail in the Nix sandbox and on stock NixOS but pass on
  the fleet hosts (envfs) and on Arch. Prove such a bug with the nixpkgs build.

## Review checklist
- Title is a plain imperative sentence; body explains problem, change and test, plus the
  disclosure line.
- `bin/test` passes (or the nixpkgs build when the change is about portability).
- Nothing packaging-only that belongs in omarchy-pkgs.
