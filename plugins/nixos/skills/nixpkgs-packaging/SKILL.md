---
name: nixpkgs-packaging
description: Use when bringing an application (CLI, daemon with a NixOS module, desktop app, GPU runtimes) into nixpkgs end to end — deciding the shape, fixing upstream until the package needs no workarounds, testing on every platform and on real hardware, running it in the fleet before the merge, and keeping it current afterwards.
disable-model-invocation: true
---

# Bringing an application into nixpkgs

The lifecycle, phase by phase, distilled from MeshLLM (NixOS/nixpkgs#571722: 17 upstream fixes,
a few linked workarounds left) and the Block packages (buzz-cli merged, buzz-relay and buzz-app open, a
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
  six-package suite PR both stalled). A PR a reviewer can read in one sitting. For an app with a
  runtime, variants and a module, from the first PR on: PR 1 has the app, its runtime and the thin
  variants; extra products and the module follow in separate PRs (`nixpkgs-contributing` §0;
  #571722 is being split after three weeks without review).
- **Responsiveness of upstream** (measure merge times of outside PRs, `contribution-skill-authoring`
  §3) sets the strategy: responsive (Mesh-LLM, median 2.5 days) → fix everything upstream and track
  main; slow or closed (block/buzz: no outside PR merged) → carry linked patches, keep them few.
- **Pick the next app by what it adds and what blocks it.** Ask what it gives Martin that the
  fleet doesn't already have, and whether it can start today. ai-rules writes per-repo agent files
  that nix-config's `ai-agents.nix` already fans out fleet-wide (aittributor and lhm: jj runs no
  git hooks): worth packaging for others, not next. buzz-acp looked central, but its package left
  with the closed 0.X suite and its module waits on the relay; check it still belongs to Buzz 1.0
  first. Berd (unblocked, on goose) went next. Check `ListAgents` and ask the sessions on
  neighbouring products before starting; ownership is in the handover.

## Phase 1: learn the application before packaging it

Fill in [references/packaging-facts.md](references/packaging-facts.md) from the source **and a
built binary** (`upstream-contributing` §1: verify on the artifact): products and binaries, build
system and vendored tools, what it downloads or contacts at build, test and run time, FHS paths it
assumes, how it finds its own files, updaters and telemetry, service and config layout. Measure,
don't guess: a logging `HTTPS_PROXY`, an empty `SSL_CERT_FILE`, `bwrap` with a bare environment,
`strace -f -e execve`, `patchelf --print-needed`. Every surprise here becomes either an upstream
PR or a documented package decision.

Also read the per-platform config overlays (`tauri.linux.conf.json`, …): buzz-app's Linux overlay
renames `productName` to "Buzz Foundation", which moves the resource dir to `lib/Buzz Foundation`.
And note when an app reuses a predecessor's app id (`xyz.block.buzz.desktop` from Buzz 0.X): a
behaviour test then starts on the old profile, not on a first run.

Make sure the upstream org and repo have skills before the first contact (`upstream-contributing`
"First contact").

**The hermetic audit, before the first upstream PR.** Run upstream's whole test suite once in a
sandbox-like environment (Phase 2 step 2, or `bwrap` with no network, no `/usr/bin`, no CA bundle)
and also with every relevant variable set to an empty string, not only unset. List every failure,
grouped by cause. MeshLLM found them one at a time over three weeks (`/usr/bin/true`, `/bin/bash`,
`ps`, `sysctl`, CA bundle, an empty bundle variable, tight timings, an HTTP client that can't be
built without CA roots); one list up front turns that into one plan.
Then, before any PR: file **one tracking issue** upstream with the grouped list and the proposed
approach per group, and have Martin introduce himself as a downstream packager in the project's
channel. Distribution concerns (runtime downloads, pins, discovery) become a known topic instead of
a surprise in each PR.

**Infrastructure on day one:** the upstream pre-flight repo, review-gha for darwin, the hardware
the package claims (fleet.md). MeshLLM got these gradually, after avoidable red CI runs.

## Phase 2: first package, and the workaround loop

1. Write it in nixpkgs form from day one on a branch of `kleinbem/nixpkgs` (`<app>-next`;
   `nixpkgs-contributing` §2). No copies elsewhere: the fleet re-exports the branch (fleet.md).
2. Build in the sandbox and **run upstream's whole test suite** once with `--no-fail-fast` to see
   every failure in one pass (`nixpkgs-contributing` §4 practical notes).
3. For each failure or patch, classify it with [references/workarounds.md](references/workarounds.md):
   is the cause upstream's (FHS path, network at test time, ignored env var, regression) or the
   sandbox's (darwin Metal, timing)? Upstream causes get an upstream PR (pre-flight first,
   fleet.md); sandbox causes get a skip or setting with the reason.
   For every skip, ask in this order: is it an upstream bug (→ upstream PR)? Is there a Nix-side
   setting that makes the test pass (a `sandboxProfile`, a config file from the store, a missing
   check input)? Only then skip, by name, with the link or the Nix-only reason. buzz-app's 17 Linux
   skips become 2 once BA#1778–#1781 ship.
   **Send themed PRs and cap the queue.** One PR per cause group from the audit, not per test.
   Keep about 3–4 of Martin's PRs waiting on a maintainer at a time and refill as they merge:
   where fork CI needs approval per push, a dozen open PRs saturate a small team (MeshLLM had 12
   open at once). Ready fixes wait locally with their pre-flight and body.
   A third-party upstream PR the package depends on that stalls (llama.cpp#26103, no activity for
   weeks) gets taken over under that repo's rules (a review, a comment, or Martin's own PR), not
   waited on.
4. Carry the fix downstream meanwhile, linked. Fix a *class* upstream when one cause shows up in
   several places (MeshLLM: one "local client without CA" helper fixed four crates).
   **Prove each upstream PR on the package before it merges:** a TEST-ONLY branch on
   `kleinbem/nixpkgs` (`<app>-test-<what>`) applies the PRs as patches and deletes the skips they
   cover, plus a control branch without the patches; build both on review-gha on every platform.
   The control must fail on exactly those tests (buzz-app: 17 failures without, green with
   BA#1778–#1781); link both runs in the upstream PR. Never push these branches to the PR.
5. Drop each workaround in the update that ships the fix — after grepping the source at the new
   pin; a fix covers only the path its PR names (`nixpkgs-contributing` §4).
6. Hypotheses about a failure stay hypotheses until a built artifact confirms them. Two darwin
   crash theories (configd, Metal) were wrong before an lldb backtrace showed ICU; a Metal fix was
   pushed for a crash it didn't cause. On darwin read the run's evidence bundle (crash reports,
   sandbox denials, hang samples: `references/fleet.md` §2) before forming a theory. Reproduce
   the failing step alone before restructuring.
   Test an upstream PR's premise in the sandbox it is meant for: a buzz-app PR switching a test to
   `/bin/chmod` was dropped because the darwin sandbox has no `/bin/chmod`.

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
- Agent apps get a behaviour test with a real turn: the app headless under Xvfb, a chat created
  through its own CLI, a tiny local model answering, the reply asserted in the app's store (Berd:
  `berdctl session create`, llama-server with Qwen2.5 0.5B, `PONG` read from goose's
  `sessions.db`). Give the model 8k+ context (goose's first prompt is ~4.2k tokens) and point
  goose at chat completions (workarounds.md, "Neighbours").

## Phase 4: platforms and hardware

Before "ready", the exact head is green on x86_64-linux, aarch64-linux, aarch64-darwin
(nixpkgs-review-gha, judged with `scripts/review-result`, not the run status), the VM test on
x86_64, and the hardware the package claims (GPU backends on real devices). fleet.md has the
machines, commands and durations. Run darwin whenever it helps; there is no budget.
Before each round, check the version under test: the tag is the newest one of its family
(`git ls-remote --tags`), and every branch and run builds that tag's hash. A transient failure
(cache.nixos.org HTTP 416, a one-off rustc SIGABRT) gets one rerun before anyone investigates it. Linux
derivations that a darwin-only change must not touch: compare `nix-instantiate` drvPaths before
and after, so earlier Linux results stay valid.
A review-gha build that produces the same store path as the local build proves both tested the
same derivation (Berd: `pam6whyq…` locally and on x86_64-linux); note it in the PR's evidence line.

## Phase 5: use it in the fleet before the merge

Pin the PR's commit in nix-packages' registry, let nix-config's gate build it with the fleet's
nixpkgs, install it where it is useful, and point a canary at upstream main (fleet.md). Daily use
finds what CI can't (a service that silently falls back to the CPU, a 19 GB download filling a
tmpfs). A package the fleet runs is also a package Martin can vouch for in the PR.

When a behaviour test fails against a fleet service, check the service directly (`curl`) before
blaming the package: buzz-app's "Community discovery failed" was a 502 from the relay, cut off by
a container egress rule (kleinbem-dev/nix-gantry#5).

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
  (`nixpkgs-contributing` §2). When r-ryantm stops proposing updates, read its log: lefthook sat at
  2.1.15 because 2.2 needs Go 1.27 (`buildGo127Module`).
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
