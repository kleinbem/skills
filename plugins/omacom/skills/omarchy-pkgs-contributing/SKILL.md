---
name: omarchy-pkgs-contributing
description: Use when preparing an issue or PR for omacom/omarchy-pkgs (Omarchy Arch Linux package repository and PKGBUILD recipes), or updating Quickshell and Omarchy desktop packages; covers PKGBUILD guidelines, patch maintenance, Greptile AI review, and verification.
disable-model-invocation: true
---

# omacom/omarchy-pkgs Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `omacom-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `omarchy-pkgs` and wins
where they differ.

Sources of truth in the repo: `README.md`, `docs/builds.md`, `docs/upstream-sources.md`,
`docs/rebuild-triggers.md`, `tests/pinned-sources.sh`, `tests/pgp-keys-vendored.sh`,
`.github/workflows/{build-pr.yml,test.yml,approve-pr.yml,auto-merge-pr.yml}`. Summary as of 2026-11-12.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Contributions prepared with AI assistance are accepted. Add the standard disclosure
  footer at the bottom of the PR description (e.g. `Filed by <agent> on behalf of @kleinbem, who reviewed it.`).
- **PR Titles:** Clear free-form description prefixed with the package name: `<package>: <summary>`
  (e.g., `quickshell: drop synchronous scanDir to avoid Qt 6.11 plugin reload deadlock`).
- **Commits:** Conventional git commit messages; signed commits encouraged.
- **Reviewers & Bots:** `Greptile Review` runs automatically on PRs. Maintainers review and approve.

## 1. Before starting

- Search open and closed issues and PRs: `gh search issues --repo omacom/omarchy-pkgs --include-prs <terms>`.
- Check open PRs touching the same package directory: `gh pr list --repo omacom/omarchy-pkgs --search "quickshell"`.
- Ensure changes maintain strict patch cleanliness: patches must apply with `--fuzz=0`.

## 2. Designing the change for PKGBUILDs

- Each package lives in `pkgbuilds/<package>/`:
  - `PKGBUILD`: Arch Linux package recipe.
  - `.omarchy/package.json`: Source tracking and automation metadata.
  - Any associated patches (`*.patch`) or system hooks (`*.hook`).
- Patches:
  - Keep patches minimal and well-documented with a clean patch header explaining the problem, the upstream
    context, and the fix.
  - Test that `git apply --check` or `patch -p1 --fuzz=0` applies cleanly without fuzz.
- PKGBUILD updates:
  - If a patch is modified or added, update the `sha256sums` or `b2sums` array in `PKGBUILD`.
  - Increment `pkgrel` by 1 when bumping packaging changes for the same upstream version.

## 3. Verification & CI

- GitHub Actions (`build-pr.yml`) builds changed packages on `x86_64` and `aarch64` runner containers.
  Builds from new/unvouched contributors (those not listed in `.github/VOUCHED.td`) wait for maintainer
  approval (adding the `build-approved` label) before runner jobs trigger.
- Local verification can be done with Podman/Docker or directly via Nix derivations in `nix-omarchy`.
