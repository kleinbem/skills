---
name: nixos-hardware-contributing
description: Use when preparing an issue or PR for NixOS/nixos-hardware (NixOS hardware profiles; for us the Raspberry Pi kernel and firmware modules), or when evaluating it on NixOS; covers the Nixpkgs AI policy as it applies here, CONTRIBUTING.md, the PR template, CI (nixfmt plus run-tests) and the merge queue, the Pi code owner's review style, and our downstream in kleinbem/nix-hardware.
disable-model-invocation: true
---

# NixOS/nixos-hardware Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `nixos-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to nixos-hardware and
wins where they differ.

Sources of truth in the repo: `CONTRIBUTING.md`, `README.md` (setup, profile table, community
meetings), `raspberry-pi/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
`.github/workflows/test.yml`, `.github/dependabot.yml`, `CODEOWNERS`, `.mergify.yml`, `flake.nix`
(`checks`, `hydraJobs`), `tests/{run.py,run-tests.nix,nixos-tests.nix,treefmt.nix,flake.nix}`,
`.editorconfig`, and the `master` rulesets (`gh api repos/NixOS/nixos-hardware/rulesets`). No
`AGENTS.md`, issue templates or `SECURITY.md` (org rules apply). Summary as of 2026-11-12.

CC0-1.0, about 3,400 stars, default branch `master`, about 145 open PRs. Per-area owners merge:
Doron Behar (`doronbehar`, CODEOWNER for `raspberry-pi`) merges every Pi PR; Jörg Thalheim
(`Mic92`), Sandro (`SuperSandro2000`) and others merge the rest. Jamie Magee (`JamieMagee`) writes
most Pi changes and reviews Pi PRs, but can't merge. Slow: outside PRs take days to weeks
(section 7).

## 0. Hard rules that decide the agent's role

- **Nixpkgs AI policy.** The repo has no policy of its own; `nixos-org` says to apply the Nixpkgs
  one, and `CONTRIBUTING.md` ("Any nixpkgs committer can review and approve") puts it in the
  Nixpkgs orbit. (The `nixpkgs-core` team's repo list isn't public, so membership is unverified.)
  So: Martin reviews and understands everything before it's posted; agent-written commits carry
  `Assisted-by: <tool> (<model + version>)` (`Co-authored-by` doesn't count); the PR text and
  every review reply disclose AI help separately. The agent drafts, Martin reviews and posts.
- **The Pi owner spots and rejects LLM-style code.** doronbehar on #1894: "Useless LLM comment.",
  "Another LLM bad code.", "I don't like these LLM typical `2>/dev/null || true` endings", plus
  "the phrasing of the commit message and the PR description are pretty sloppy". No defensive
  guards for states that can't happen, no comments that restate the code, tight texts.
- Precedent: one `Assisted-by: Claude sonnet 5 high` trailer in the last 400 commits (#2044,
  merged); one PR body says "No AI was used" (#2091). Disclosure is rare but accepted.
- No issue-first rule, no CLA, no DCO.

## 1. Before starting

- Search: `gh search issues --include-prs --repo NixOS/nixos-hardware <terms>`; search the option
  or file name (`kernelPatches`, `configtxt`, `dtbSrc`), not only the symptom. Open PRs touching
  the same files: `gh pr list -R NixOS/nixos-hardware --state open --json number,title,files`.
- Credit earlier work: issues often carry the fix in a comment (#1745's second comment) or a
  workaround in another PR's thread (#1923).
- doronbehar declines changes that only wrap what users can already do: #1993 (gpio-fan overlay,
  "too trivial", `deviceTreeOverlays` covers it), #1991 (use `mkRemovedOptionModule` instead of
  maintaining a translation).
- Untested hardware support isn't merged: #2073 (Pi 1) waited until the author bought a board and
  tested it. Have the hardware or say exactly what was and wasn't tested.
- "Please don't open more PRs in parallel" (#2084): one Pi PR at a time.
- Same bug class elsewhere (e.g. #409, the Surface kernel ignoring `boot.kernelPatches`) is its own
  PR, not scope creep in a Pi PR.

## 2. Designing the change

- Profiles (`CONTRIBUTING.md`): `lib.mkDefault` unless the user must not override it or the value
  should merge (lists, sets); reuse `common/` modules; avoid "opinionated" settings; new profiles
  get a `README.md` table row and a `flake.nix` `nixosModules` entry; renames and removals get
  deprecation warnings for flake and channel users.
- Must work on NixOS unstable **and** the current stable (`CONTRIBUTING.md`, "Compatibility"); CI
  evaluates both (section 3). Gate on attributes newer nixpkgs has, as `kernel.nix` does with
  `pkgs.kernelPatches ? tools_128bit_types` and a comment saying when to drop it (#2106).
- Pi kernel: `raspberry-pi/common/kernel.nix` builds `linux-rpi` for every board (`rpiVersion`
  1-5) through `buildLinux (args // { ... })`. Things that come in via `args` must be merged, not
  replaced: see `features = { ... } // (args.features or { })`.
- Kernel config: `structuredExtraConfig`, `lib.mkForce` only for options nixpkgs'
  `common-config.nix` sets at normal priority (#1841); `inherit (lib.kernel) freeform yes no`.
- Nix style doronbehar asks for: no `with lib.types;` (#1947), no single-use helper variables or
  vaguely named functions (#1945, #1947), no `toJSON`/`fromJSON` round trips (#1947), short
  `TODO:` comments with a link instead of prose (#1860), docs that link instead of duplicating
  (#2012, #2019).
- Accurate history: one semantic change per commit; he splits or reorders commits himself when
  they don't read cleanly (#1841, #1947, #1991).

## 3. Building and validating on NixOS

- CI parity, both in the clone:
  - `nix build .#checks.x86_64-linux.formatting`: treefmt with `nixfmt` and `deadnix`
    (`tests/treefmt.nix`); `nix fmt` fixes it.
  - `nix run .#run-tests`: `nix-eval-jobs --no-instantiate` over `#checks` for aarch64, riscv64
    and x86_64. Every profile is evaluated (not built) against `nixos-unstable-small` and
    `nixos-26.05` from `tests/flake.nix`. Pi 3/4/5 are covered; Pi 1 and 2 are blacklisted
    (`tests/nixos-tests.nix`). Also `checks.*.raspberry-pi-config-txt`.
- CI never builds a Pi kernel; Hydra's `raspberry-pi-kernels` jobset does after merge
  (`flake.nix` `hydraJobs`). A kernel change should leave the kernel drvPath unchanged for users it
  doesn't concern (no mass rebuild), and the kernel should build: on the aarch64 Pis or a
  community aarch64 builder (#1894), not under emulation on the workstation.
- Prove a kernel change in an evaluated system: a small `nixosSystem` importing
  `raspberry-pi/<n>`, before vs. after, comparing `kernel.kernelPatches`, the config and the
  drvPath. Then deploy to a Pi and check `zcat /proc/config.gz`.
- doronbehar asks "How exactly do you test this?" (#1860) and "did you at least build the new
  kernel?" (#2035), and tests big changes on his own Pi 3/4 before merging (#1894). Say what was
  built, evaluated and booted, on which board.

## 4. Commits

- Subject `<path>: <summary>`, path as deep as useful: `raspberry-pi/common/kernel: 6.18.50-… ->
  6.18.60-…`, `raspberry-pi/firmware: …`, `raspberry-pi: …`, `dell/latitude/3530: init`. A few
  Conventional Commits slip through (`fix(gpd): …`); don't copy them.
- **Merge commits** (GitHub merge queue, `merge_method: MERGE`): every commit lands on `master`
  as written, so each message must stand alone. Body says why; trailer as in section 0.

## 5. Pull request

- Keep the template: `###### Description of changes` and `###### Things done` with two boxes,
  "Tested the changes in your own NixOS Configuration" and "Tested the changes end-to-end by using
  your fork of `nixos-hardware` and importing it via `<nixos-hardware>` or Flake input". The
  template says they're "not hard requirements", but reviewers ask; tick only what Martin did.
  The second needs the change on a fork branch used as his flake input.
- Reference the issue (`#1745`, or `This will close #2099` as on #2106) and credit who proposed the
  fix.
- Review requests from authors are common ("@doronbehar if you have some time, could you review
  this please?", #1945, #1991); the shared rule stands: no pings from us (section 7 for waiting).

## 6. CI and bots

- `test.yml` on `pull_request`, `push` to `master` and `merge_group`: job `nixfmt`, then `tests`
  (needs `nixfmt`). Only `tests` is required (ruleset "master protection"). Fork PR runs may need
  approval.
- Merge queue: GitHub's own (ruleset `merge_queue`, batches of up to 5, ALLGREEN). `.mergify.yml`
  (label `merge-queue` or `dependencies`) is stale: the label was last used on #1137
  (2024-09). Maintainers queue PRs; nothing for us to do.
- Rules: 0 required approvals, but "extra approval for unattributed changes", no force pushes on
  `master`. Dependabot bumps actions and the test inputs weekly.
- No AI review bots. `nixos-discourse` comments when a PR is posted in Discourse's "PRs ready for
  review" thread (#2057, #2067).

## 7. What the history shows

Measured 2026-11-12 (commands in `contribution-skill-authoring`, section 3):
- Fork PR merge times, last 40 merged, hours: median about 290 (12 days), from 1 to 1922. Pi PRs
  (`--search 'raspberry-pi in:title'`, last 40): median about 220 (9 days), 1 to 1699.
  `gh pr list -R NixOS/nixos-hardware --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
- Closed unmerged fork PRs: duplicates (#2096 of #1402), superseded (#2020 → #2064), declined as
  trivial (#1993), or abandoned without comment (#2011, #2004).
- Pi reviews come in several rounds of concrete questions and GitHub suggestions; authors who
  answer each point and apply suggestions get merged (#2012, #2019, #1894). Big Pi changes take
  weeks (#1894, #1947).
- #1745 (Pi kernel drops `boot.kernelPatches`, nwf, 2026-01-25): no maintainer reply; others hit
  it too (#1923 review by nekowinston, workaround by stv0g).

## 8. Our setup and current threads

- Clone at `~/Develop/github.com/NixOS/nixos-hardware` (plain git, `origin` upstream; Martin's
  uncommitted edits, don't touch). PR work in fresh jj clones under
  `~/Develop/github.com/NixOS/nixos-hardware.ws/<name>`. No fork yet: create `kleinbem/nixos-hardware`
  (remote `fork`) when the first PR opens.
- Downstream: kleinbem/nix-hardware `rpi5.nix` imports `raspberry-pi/5` and works around #1745
  with `argsOverride.kernelPatches` (the upstream defaults plus `config.boot.kernelPatches`), kept
  in sync by hand (tracking: kleinbem/nix-hardware#118, workaround merged in
  kleinbem/nix-hardware#121). Drop it when the fix reaches our lock. Hosts: core-pi, hass-pi.
- Current thread: the #1745 fix (`raspberry-pi/common/kernel: keep kernelPatches passed in via
  override`, appends `args.kernelPatches or [ ]`) prepared in
  `nixos-hardware.ws/kernelpatches`; draft text in `~/.cache/nixos-hardware-kernelpatches-draft.md`.
  Not pushed, no PR. Open PR #2034 also edits `kernel.nix` (another hunk).

## Review checklist

- Commit subject is `<path>: <summary>` and every commit message stands alone (merge commits,
  section 4).
- Agent-written commits carry `Assisted-by: <tool> (<model + version>)`, and the PR text
  discloses AI help in its own line (section 0).
- No LLM tells: defensive guards for impossible states, `|| true` endings, comments that restate
  code, padded prose (section 0, #1894).
- `nix build .#checks.x86_64-linux.formatting` and `nix run .#run-tests` pass on the head
  (section 3); the change works on unstable and stable.
- A kernel change keeps the drvPath for users it doesn't affect and was proven before/after on the
  board profiles it touches (section 3).
- Ticked boxes match what Martin did on his own Pi, and the PR text says what was built,
  evaluated and booted (sections 3, 5).
- The issue and whoever proposed the fix are credited; no open PR covers the same change
  (sections 1, 5).
