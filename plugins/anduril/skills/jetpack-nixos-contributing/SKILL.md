---
name: jetpack-nixos-contributing
description: Use when preparing an issue or PR for anduril/jetpack-nixos (NixOS on NVIDIA Jetson, with kernels, firmware, flashing and CUDA), or when building it on NixOS; covers the missing contribution docs, the PR template, CI (eval plus checks), commit prefixes and who merges.
disable-model-invocation: true
---

# anduril/jetpack-nixos Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `anduril-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to jetpack-nixos and
wins where they differ.

Sources of truth in the repo: `README.md`, `UPGRADE_CHECKLIST.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, `.github/workflows/{ci,ci-25.11,ci-unstable}.yaml`,
`.github/nix-flake-check-ci.sh`, `treefmt.nix`. No `CONTRIBUTING.md`, `AGENTS.md`, `CODEOWNERS`,
issue templates or `SECURITY.md`. Summary as of 2026-11-07.

Apache-2.0, about 490 stars, default branch `master`. Elliot Berman (`elliotberman`) merged 57 of
the last 60 PRs; Daniel Fullmer (`danielfullmer`), the original author, still files issues and
reviews.

## 0. Hard rules that decide the agent's role

- **No AI policy.** Merged commits carry `Co-Authored-By: Claude …` and "Generated with Claude
  Code" (in the last 300 commits: 5 such trailers, from both employees and outside contributors).
  The agent drafts, Martin reviews and posts; that trailer is fine on agent-written commits. One
  line in the PR text that it was written with an AI assistant. Issues get no trailer.
- No issue-first rule: small fixes go straight to a PR. Earlier kernel-config reports went issue →
  PR (#25 → #28, IPv6 rpfilter options); either works.
- No CLA, no DCO check (a few commits carry `Signed-off-by:` voluntarily).

## 1. Before starting

- Search: `gh search issues --include-prs --repo anduril/jetpack-nixos <terms>`. Search the
  Kconfig names and the component (`kernel`, `optee`, `flash`), not only the symptom.
- Kernel config lives per L4T release: `pkgs/kernels/r35/default.nix` (JetPack 5),
  `r36/` (JetPack 6), `r39/` (JetPack 7), plus `pkgs/kernels/common-arch.nix`. A config change
  usually belongs in all three; say which ones you tested.
- Duplicates get closed quickly with a pointer (#509 → #502); check open PRs' files
  (`gh pr view <N> --json files`).

## 2. Designing the change

- Kernel options go into the `structuredExtraConfig` block next to the related ones, with a short
  comment why (see the "So nat.service and firewall work" block). `ignoreConfigErrors = true`
  hides options that don't apply, so prove an option took effect in the built `.config`.
- Keep personal tooling out of the diff (#574: "Use `.git/info/exclude`").
- Reviewers suggest exact replacements with GitHub suggestions (#574, #577); apply them as given.

## 3. Building and validating on NixOS

- CI (`ci.yaml`, plus `ci-25.11` and nightly `ci-unstable`, x86_64 runners) evaluates every
  `nixosConfigurations.*.toplevel` and `packages.x86_64-linux` through `nix-eval-jobs`, then
  builds `checks.x86_64-linux` (`.github/nix-flake-check-ci.sh`). `packages.aarch64-linux` is
  neither evaluated nor built, so check those yourself. Run it locally:
  `nix shell nixpkgs#nix-eval-jobs nixpkgs#jq --command ./.github/nix-flake-check-ci.sh`.
- Builds are aarch64. Build on the Orin (or another aarch64 builder), not under emulation on the
  workstation, and test on hardware: the PR template asks which SoM and carrier board.
- For a kernel option: build the kernel's `configfile` and grep `CONFIG_<X>`, then check
  `/proc/config.gz` on the device after the reboot.
- Formatting: `nix fmt` (treefmt).

## 4. Commits

- Subject `<component>: <what>` (`kernels:`, `optee:`, `uefi-firmware:`, `flash-script:`,
  `modules:`, `r36:`); Conventional Commits (`fix(optee): …`) appear too. Merge commits, not
  squash: each commit message stays in history, so keep them clean.

## 5. Pull request

- Keep the template's two sections, `Description of changes` and `Testing`; Testing names the
  SoM and carrier board (for Martin: Orin Nano Super devkit, JetPack 6).

## 6. CI and bots

- No AI reviewers, no stale bot, no labels in use. Fork PR workflows may need approval.

## 7. What the history shows

Measured 2026-11-07 (commands in `contribution-skill-authoring`, section 3):
- Fork PR merge times, last 40 merged, hours: median about 45, from 0 to 764.
- Closed unmerged fork PRs: superseded or duplicate (#496 → #521, #509 → #502), or withdrawn by the
  author (#525).
- Many reported issues stay open without an answer (#503, #482, #465): an issue alone may sit; a
  PR with the fix moves faster.

## 8. Our setup and current threads

- No fork yet; clone at `~/Develop/github.com/anduril/jetpack-nixos`. kleinbem/nix-hardware pins
  it (`orin-nano.nix`, an Orin Nano Super on JetPack 6).
- nix-hardware carries the `nftables-fleet` kernel patch (NFT_CT, NFT_FIB_*, NFT_REDIR …) for the
  NixOS nftables firewall; tracking: kleinbem/nix-hardware#107.

## Review checklist

- The change covers r35, r36 and r39 where it applies, or says why not (section 1).
- Kernel options were proven in the built `.config`, not only set (section 2).
- The local eval script passes (section 3).
- The PR body keeps both template sections and names the tested board (section 5).
