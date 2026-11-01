# The kleinbem machinery around a nixpkgs package

Where each step runs, what it catches, how long it takes, and its known gaps (2026-10-28).
nixos-nvme (the workstation) is for builds and behaviour tests that need a built binary or local
hardware; checks and full builds go to GitHub runners.

## 1. Branches

- `kleinbem/nixpkgs`: the PR branch (e.g. `mesh-llm-init` for #571722) and a prep branch per app
  (`<app>-next`, adapted to upstream main for the next release). Worktrees in
  `~/Develop/github.com/NixOS/nixpkgs.wt-<name>`; the main clone is git-only, `git fetch upstream
  master` from a worktree is fine.
- Pre-push: `nix fmt`, `./ci/nixpkgs-vet.sh master`,
  `~/Develop/github.com/kleinbem/nix-toolbox/bin/nix-check-nixpkgs-pr --drvs-against <old head>`
  (deadnix, variant `meta.position`, workaround links, which derivations changed),
  `nix-build -A <attr>` and its `passthru.tests`.

## 2. nixpkgs-review-gha (kleinbem fork of Defelo's)

- `build.yml`: `-f packages="github:kleinbem/nixpkgs/<sha>#attr …"` tests a fork commit before the
  PR branch moves; platform inputs `x86_64-linux`, `aarch64-linux` (bool), `x86_64-darwin`,
  `aarch64-darwin` (`no | yes_sandbox_false | yes_sandbox_relaxed | yes_sandbox_true`; the
  workflow defaults both darwins to `yes_sandbox_relaxed`, pass `x86_64-darwin=no` unless needed).
- `review.yml`: nixpkgs-review on a PR number; always `-f post-result=false` (posting is a public
  step), `on-success=nothing`.
- darwin: tests with `__darwinAllowLocalNetworking` need `yes_sandbox_relaxed` (as Hydra). Run
  darwin whenever it helps; GitHub only limits parallel macOS jobs (5 on Free), waiting for a
  runner is capacity, not an error.
- Get Linux green first, then run darwin once. Darwin jobs start right away; what costs time is a
  failed try (mesh-llm on 2026-10-28: three darwin runs failed after up to an hour each on
  commits that still had other problems).
- `x86_64-darwin=no` by default: nixpkgs drops x86_64-darwin after 26.05, and it runs under
  Rosetta on the same arm64 runner. Only when a change is specific to it.
- Nobody here has a Mac: a darwin failure is understood from what the run brings back. A failed
  `build.yml` job uploads `evidence-<system>` (7 days, usually < 5 MB), and `review-result`
  downloads it to `~/.cache/review-gha/<run>/` and lists it:
  - `logs/<drv>.log`: full `nix log` of each failed derivation (the console log is interleaved)
  - `builddirs/*.tar.gz`: text files the build wrote in its kept build directory (test output,
    `config.log`, build-script output; no unpacked sources, Cargo `deps`, binaries)
  - `crashes/`: macOS crash reports (`.ips`) with backtraces: read them before guessing a crash
  - `sandbox-denials.txt`: every path or service the darwin sandbox refused (EPERM, TLS/trustd,
    ICU, `/bin/chmod`: all were sandbox denials). Most lines are macOS's own services; the count
    per process on top shows the build's (bash, coreutils, clang, the package's binaries)
  - `hang/`: process list and macOS `sample` stacks when the build printed nothing for 15 min
    (a background daemon holding the log open shows up here); the build step times out at
    340 min so a hang is still collected
  - `platform.txt`: macOS, SDK, Xcode, Nix versions and sandbox mode
  Fix from the evidence in one round instead of one guess per hour-long run.
- `upterm=true` opens an SSH shell on the runner after the build (review-gha#3), but only a
  person with the actor's GitHub key can join it; agents use the evidence bundle.
- Judge a run with `../nixpkgs-contributing/scripts/review-result <run-id> [--wait]`, never by
  its status. It reads `review.yml`'s reports and, for `build.yml` runs (no report; `nix build
  --keep-going` fails the job), each job's conclusion and the derivations that failed. aarch64 runs no VM tests (no KVM on GitHub's ARM runners).
- A job ends at GitHub's 6 h limit; multi-variant packages (CPU+Vulkan+CUDA+ROCm) don't fit on
  x86_64 — run that platform's nixpkgs-review on nixos-nvme. Typical runs: 25 min – 2.5 h; a
  full workspace test suite on x86_64 about 1 h in the debug profile.
- An HTTPS push to the nixpkgs fork can fail with HTTP 408 ("remote end hung up") even for one
  commit. Then create the commit through the API: blobs for the changed files, a tree on the
  parent's tree, a commit, a fast-forward of the ref (`gh api repos/<fork>/git/{blobs,trees,commits,refs}`);
  compare the resulting tree with `git rev-parse HEAD^{tree}`.
- `gh run view --json jobs` can show running jobs without `started_at`; ask
  `gh api repos/<r>/actions/runs/<id>/jobs` before concluding a job hasn't started. Logs of
  running jobs aren't available.
- Never `gh workflow disable` these workflows; cancel a run instead. They have been disabled from
  outside several times (not in Martin's security log): a guard loop re-enables `build` and logs
  each time to `~/.cache/review-gha-disables.log`.
- Caches: public Cachix `kleinbem-nixpkgs-review` (runs push) is for testers; Attic
  (cache.kleinbem.dev) is Martin's private buffer, never point others at it.

## 3. Upstream pre-flight

For code PRs to an upstream that runs heavy CI (Mesh-LLM): `kleinbem/mesh-llm-ci` `check.yml`
(`-f ref=<full sha> -f title=…`) runs upstream's own planner, Clippy, tests, fmt and repo checks
on GitHub's runners before a maintainer approves CI. `-f packages="<crates>"` adds macOS and
Windows rows — but those run `--lib` only, like upstream's macOS lane. About 7–47 min. Other
upstreams: copy the pattern when their CI needs approval for forks.

## 4. Real hardware

- **Orin Nano (aarch64, JetPack 6, sm_87):** CUDA 12 builds with `cudaPackages_12` and
  `cudaCapabilities = [ "8.7" ]` (nixpkgs master defaults to CUDA 13, which JetPack 6 can't run).
  Ask Martin for a no-touch SSH grant (`just access::grant-notouch orin-nano`) and the go to stop
  its services (Frigate, mesh-llm, the GPU runner); remind him to start them afterwards. 8 GB RAM:
  `cores 2, max-jobs 1` for big Rust builds. Proof of GPU use: `tegrastats` GR3D load and the
  backend library mapped in the process, not log lines. Start remote jobs from a script piped to
  `ssh … 'bash -s'`; never `pkill -f` with the pattern on the command line.
- **Nightly GPU check:** private `kleinbem/mesh-llm-gpu` `gpu.yaml` on a self-hosted runner on the
  Orin (nix-config `my.services.meshLlmGpuRunner`). **Gap:** no issue or alert on failure; it was
  red for over a week unnoticed.
- **nixos-nvme Intel iGPU (Vulkan):** manual, `systemd-run --user`; proof via
  `/proc/<pid>/fdinfo` i915 render engine time.
- **ROCm, CUDA on x86_64:** build-only tests; no hardware in the fleet. Say so in the PR.

## 5. Running it in the fleet before the merge (nix-packages registry)

- `nix-packages/nixpkgs-prs.json` pins each open nixpkgs PR (owner, repo, rev, narHash, attrs,
  scope, modules); nix-holds' `mkPrs` (kleinbem-dev/nix-holds, `prs.nix`) builds the PR's own
  `package.nix` files against the flake's nixpkgs (one scope per entry) and exports its modules
  without `meta.doc` (every host builds the manual, which rejects chapters missing from nixpkgs'
  `redirects.json`; test with
  `nix build .#nixosConfigurations.<host>.config.system.build.manual.manualHTML`).
- **Add:** `nix run github:kleinbem-dev/nix-holds -- pr add NAME --pr N --repo kleinbem/nixpkgs
  --attrs a,b --rev <full sha> [--scope c,d] [--module name=path]...` in nix-packages, always pinned (an
  unpinned entry doesn't evaluate; `pr list`, `pr merged` too).
  **Pin** (move to a newer commit): the *Pin nixpkgs PR* workflow (`pr-pin` action; name + full sha)
  opens an auto-merging PR; pin only a commit that is green on review-gha (not checked by the workflow).
  The daily lock update never moves a pin. **Remove:** the weekly *nixpkgs PRs merged* workflow
  (`pr-merged` action) opens a PR once nixpkgs has every attr in the same or a newer version (a draft when the entry
  has modules: switch nix-config to nixpkgs' module first).
- **Gate:** nix-config `checks.<system>.nixpkgs-prs` builds every registry attr a CI-built host
  installs, from that host's own pkgs (the exact derivation it fetches). build-all runs it on
  every PR and on main; promote only follows a green build-all on main. **Gap:** only `check`
  (evaluation) is a required check in nix-config, so a broken pin merges and then blocks promote
  for the whole fleet; wait for the builds before merging big changes by hand.
- Shadow packages (real derivations in nix-packages) only for software no nixpkgs PR exists for
  yet; they follow `nixpkgs-contributing` from day one so the later PR is a copy.

## 6. Holds (kleinbem/nix-holds)

When a package breaks in nixos-unstable, `held-packages.json` keeps it on the last nixpkgs where
it works (or stable) instead of freezing the fleet's whole nixpkgs. Consumed by nix-devshells,
nix-config (hosts, container-factory) and nix-presets' `mkContainer` (every container). Weekly
release workflow opens a removal PR once the cause (`releaseWhen`) builds again; ntfy alert after
14 days. Its `check` only evaluates (consumers may adjust a held package). Holds are proposed by
hand today; the lock bot should propose them from "Refusing to evaluate package X … broken".

## 7. Canaries against upstream main

`nix-packages/canary/<app>/` + `.github/workflows/canary-<app>.yaml`: builds nixpkgs' package
(from the `<app>-next` branch) with only the sources swapped to upstream main, learns new hashes
from an empty-hash build, runs the package's tests plus checks a release can't show (startup
network hosts through a logging proxy, integration with a neighbour app, the NixOS test with KVM),
and opens or comments one issue when red. Cron runs start hours late (GitHub). **Act on red:**
mesh-llm's canary sat red from 10-23 (startup now contacts public DNS resolvers). Writing one is
~150–250 lines of mostly copy; a shared template is still missing. The canary and the GPU check
build a prep branch (`<app>-next`): move it with the package, or they test an old state (mesh-llm's
sat at 2026-10-24 while the package moved on).

The Berd behaviour test (`~/.cache/berd-test/scripts/e2e-nix.sh`: Xvfb, `NO_AT_BRIDGE=1`, a chat
through `berdctl`, llama-server with a 0.5B model) is a candidate step for that template: any
agent app with a CLI can reuse it.

## 8. Watching upstream

`nix-packages/watch/upstream-prs/prs.txt` (weekly, one issue): conflicts, merges, new human
comments. Add every upstream PR a workaround waits on. The session's own PR watchers cover the
active ones.

## 9. Other distributions

AUR mirror in `kleinbem/aur-packages` (`aur-contributing`): nixpkgs first, AUR follows; record the
nixpkgs commit synced in `nixpkgs-sync.md`. Martin authors and pushes AUR changes.

## 10. Applying to the fleet

Martin runs `just dev::apply` only when everything is merged and main's build is in Attic; hosts
with `requireCache` never build themselves. Say "ready to apply" only then.
