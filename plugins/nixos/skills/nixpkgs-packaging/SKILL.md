---
name: nixpkgs-packaging
description: Use when bringing an application (CLI, daemon with a NixOS module, desktop app, GPU runtimes) into nixpkgs end to end — deciding the shape, fixing upstream until the package needs no workarounds, testing on every platform and on real hardware, running it in the fleet before the merge, and keeping it current afterwards.
disable-model-invocation: true
---

# Bringing an application into nixpkgs

The lifecycle, phase by phase, distilled from MeshLLM (NixOS/nixpkgs#571722: 17 upstream fixes,
one workaround left) and the Block packages (buzz-cli merged, buzz-relay and buzz-app open, a
0.X suite abandoned). Rules that already live elsewhere are only pointed to:
`nixpkgs-contributing` (derivation, commit and review rules), `upstream-contributing` (shared
upstream workflow, public steps), `agent-ops` (watchers, builds), `aur-contributing` (the Arch
mirror). Read those too.

References in this skill:
- [references/workarounds.md](references/workarounds.md) — catalog of the problems a sandboxed
  build finds, how to detect each, the upstream fix that removes it.
- [references/fleet.md](references/fleet.md) — the kleinbem machinery: review-gha, hardware,
  registry, gate, holds, canaries, AUR, caches.
- [references/packaging-facts.md](references/packaging-facts.md) — template for the facts sheet.
- [references/case-mesh-llm.md](references/case-mesh-llm.md),
  [references/case-block.md](references/case-block.md) — what happened and what it taught.

## The goal: a package without workarounds

A nixpkgs package should build upstream's code as upstream ships it. Every deviation (patch,
`substituteInPlace`, env var the wrapper sets for a bug, test skip) is a **workaround**, and each
one is debt: it breaks on the next release, reviewers question it, and other distributions hit the
same bug. So:
- Every workaround carries a comment with the upstream PR or issue that removes it, or the reason
  it can't be upstreamed (Nix-only knowledge). No unlinked workaround survives to "ready".
- Fix the cause upstream, not the symptom downstream (`upstream-contributing`: upstream first, in
  parallel; never block the package on it).
- Count them. The PR body says "N fixes merged upstream; the remaining workaround waits on X".
  MeshLLM went from 6 workarounds on 0.78.1 to one in three weeks.
- Permanent Nix-only adaptations are not workarounds (removing an upstream cargo config that routes
  through sccache, a darwin sandbox profile); they still get a one-line reason.

## Phase 0: decide the shape before writing code

- **Search first** (`nixpkgs-maintaining` "Where packaging lives"; `upstream-contributing` §1):
  nixpkgs PRs (open and closed), nix-community, project flakes, other distros (repology). Credit or
  build on what exists; don't open a competing PR (goose 1.56: ours lost to a maintainer's).
- **Check the roadmap and the org's repos.** Three weeks went into Buzz 0.X packages that upstream
  replaced with a new repo (block/buzz-app). Look for announcements, new repos, release cadence.
- **License and source:** FOSS is built from source; prebuilt binaries only for unfree software.
- **Version policy, decided once:** a release tag (`tag = "v${version}"`), or upstream main as
  `<last-release>-unstable-YYYY-MM-DD` when upstream merges fixes fast and releases slowly (lets
  upstream fixes land in days instead of waiting for a release; MeshLLM). Watch for repos whose
  tags or crate versions don't mean what they say (Block: `Cargo.toml` never bumped; `mobile-v*`
  and `desktop-v*` tags in one repo → `nix-update --version-regex`). Changing the policy later
  costs force-pushes on a reviewed PR (#571722 had 18).
- **Split:** one package per independently useful thing (runtime, CLI, daemon), variants by
  override (`-cuda`, `-rocm`, `-vulkan`, `nixpkgs-contributing` §2). **One PR per concern, the
  shared base first** (buzz-cli bump merged in 3 days; seven one-package PRs in two days and a
  six-package suite PR both stalled). A PR a reviewer can read in one sitting.
- **Responsiveness of upstream** (measure merge times of outside PRs, `contribution-skill-authoring`
  §3) sets the strategy: responsive (Mesh-LLM, median 2.5 days) → fix everything upstream and track
  main; slow or closed (block/buzz: no outside PR merged) → carry linked patches, keep them few.

## Phase 1: learn the application before packaging it

Fill in [references/packaging-facts.md](references/packaging-facts.md) from the source **and a
built binary** (`upstream-contributing` §1: verify on the artifact): products and binaries, build
system and vendored tools, what it downloads or contacts at build, test and run time, FHS paths it
assumes, how it finds its own files, updaters and telemetry, service and config layout. Measure,
don't guess: a logging `HTTPS_PROXY`, an empty `SSL_CERT_FILE`, `bwrap` with a bare environment,
`strace -f -e execve`, `patchelf --print-needed`. Every surprise here becomes either an upstream
PR or a documented package decision.

Make sure the upstream org and repo have skills before the first contact (`upstream-contributing`
"First contact").

## Phase 2: first package, and the workaround loop

1. Write it in nixpkgs form from day one on a branch of `kleinbem/nixpkgs` (`<app>-next`;
   `nixpkgs-contributing` §2). No copies elsewhere: the fleet re-exports the branch (fleet.md).
2. Build in the sandbox and **run upstream's whole test suite** once with `--no-fail-fast` to see
   every failure in one pass (`nixpkgs-contributing` §4 practical notes).
3. For each failure or patch, classify it with [references/workarounds.md](references/workarounds.md):
   is the cause upstream's (FHS path, network at test time, ignored env var, regression) or the
   sandbox's (darwin Metal, timing)? Upstream causes get an upstream PR (pre-flight first,
   fleet.md); sandbox causes get a skip or setting with the reason.
4. Carry the fix downstream meanwhile, linked. Fix a *class* upstream when one cause shows up in
   several places (MeshLLM: one "local client without CA" helper fixed four crates).
5. Drop each workaround in the update that ships the fix — after grepping the source at the new
   pin; a fix covers only the path its PR names (`nixpkgs-contributing` §4).
6. Hypotheses about a failure stay hypotheses until a built artifact confirms them. Two darwin
   crash theories (configd, Metal) were wrong before an lldb backtrace showed ICU; a Metal fix was
   pushed for a crash it didn't cause. Reproduce the failing step alone before restructuring.

## Phase 3: tests that prove the package works

- `passthru.tests`: an offline smoke test that does the real job (serve a 1 MB model and complete
  a prompt; pair two clients over a local relay), a NixOS VM test for the module with falsifiable
  assertions (no `! cmd` under errexit), `versionCheckHook` where `--version` works.
- Upstream's tests in `checkPhase`, in **upstream CI's profile and scope**: `checkType = "debug"`
  when upstream tests in the dev profile (release + LTO links each test binary with one codegen
  unit and exhausted GitHub's 16 GB); `CARGO_PROFILE_DEV_DEBUG=0` in `preCheck` when linking many
  big test binaries; skip on a platform what upstream's CI doesn't run there either, and say so
  (Mesh-LLM's macOS CI runs `--lib` only).
- Skips by exact test name, grouped by cause, each group with its link or reason.
- Build-only tests for variants no builder can run (`runtime-rocm` gfx1100, `runtime-cuda`).
- darwin sandbox specifics (local networking, background daemons, ICU, Metal): workarounds.md.

## Phase 4: platforms and hardware

Before "ready", the exact head is green on x86_64-linux, aarch64-linux, aarch64-darwin
(nixpkgs-review-gha, judged with `scripts/review-result`, not the run status), the VM test on
x86_64, and the hardware the package claims (GPU backends on real devices). fleet.md has the
machines, commands and durations. Run darwin whenever it helps; there is no budget. Linux
derivations that a darwin-only change must not touch: compare `nix-instantiate` drvPaths before
and after, so earlier Linux results stay valid.

## Phase 5: use it in the fleet before the merge

Pin the PR's commit in nix-packages' registry, let nix-config's gate build it with the fleet's
nixpkgs, install it where it is useful, and point a canary at upstream main (fleet.md). Daily use
finds what CI can't (a service that silently falls back to the CPU, a 19 GB download filling a
tmpfs). A package the fleet runs is also a package Martin can vouch for in the PR.

## Phase 6: the PR

- `nixpkgs-contributing` §1, §3 and the review checklist; `upstream-contributing` §4–§6.
- One commit per package plus one for the module; `Assisted-by:` per change.
- Body: what it is, why these packages, "Tested" with the platform and hardware matrix of the exact
  head, the upstream fixes and the remaining linked workarounds, honest checkboxes.
- Draft until Martin says ready; an independent review (`upstream-contributing/review-handoff.md`)
  and `nix-check-nixpkgs-pr` before that.
- After opening: answer bots, don't ping; for merging, ask a committer who has touched related
  packages (buzz-cli: booxter, who had fixed its darwin build). Co-maintainers help; ask people
  who package the app elsewhere.

## Phase 7: after the merge

- The registry entry goes by itself (weekly "nixpkgs PRs merged" PR); switch modules in nix-config
  first when the entry has one (fleet.md).
- `passthru.updateScript` must keep working (r-ryantm); one script updates a package family
  (`nixpkgs-contributing` §2).
- Release bump: read the release notes, drop the workarounds whose fixes it contains (grep the new
  pin), rerun the full matrix including hardware, then the PR.
- Keep the canary against upstream main and act on red: it is the early warning for the next
  release (fleet.md lists canaries that sat red for days — that is the failure mode).
- Mirror changes to the AUR packages (`aur-contributing`): nixpkgs first, AUR follows.

## Working rules for the agent

- One background watcher per running job; report results unasked (`agent-ops`).
- Upstream PRs get a pre-flight on GitHub's runners before opening and after every push
  (fleet.md); rebase onto upstream main before every push.
- No self-imposed limits (darwin runs, CI runs): only real external ones count.
- Research across PRs, issues and history goes to parallel subagents; decisions stay here.
- Every claim in a PR or comment is verified on the exact head; say "suspected" until then.
