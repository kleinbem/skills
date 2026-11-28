---
name: mesh-llm-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/mesh-llm (MeshLLM host, console, SDKs, packaging scripts; Skippy is in Mesh-LLM/skippy) to follow its build, validation, commit, attribution and PR-template rules.
disable-model-invocation: true
---

# Mesh-LLM/mesh-llm Contribution & PR Workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/mesh-llm and wins where they differ.
PR and issue numbers (`#2577`) refer to Mesh-LLM/mesh-llm unless another repository is named:
open them as `https://github.com/Mesh-LLM/mesh-llm/issues/<N>` (GitHub redirects a PR number to the
PR), or with `gh pr view <N> -R Mesh-LLM/mesh-llm` for a PR and `gh issue view <N> -R Mesh-LLM/mesh-llm` for an issue.

Sources of truth in the repo: `AGENTS.md` (root), `mesh/AGENTS.md`, `.github/AGENTS.md` (CI),
`CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/instructions/pr.instructions.md`,
`mesh/docs/design/TESTING.md`, and the repo-local skills in `.agents/skills/` (e.g.
`release-notes`, `manage-ci`). Read the ones for the touched area before acting; the project moves
fast (several merges a day, about 60 from 2026-11-14 to 11-28). Summary as of 2026-11-28 (upstream
main `74c8765c`, right after #3193 moved Skippy out and replaced the CI).

## 0. Before the first edit (do these, in order)
1. Read root `AGENTS.md`, `mesh/AGENTS.md` and `.github/instructions/pr.instructions.md`.
   Skippy (runtime, CLI, llama.cpp patches) lives in `Mesh-LLM/skippy` since #3193
   (`skippy-contributing`); mesh-llm uses its crates.io release pinned exactly in the root
   `Cargo.toml` (`=0.80.4` on 11-28) and loads its packaged runtime. Don't add Skippy source,
   llama.cpp patches, GPU runtime builds or Skippy tests here (root `AGENTS.md`).
2. Search open/closed issues and PRs for the problem (`gh search issues|prs --repo Mesh-LLM/mesh-llm`).
3. Check open PRs that touch the same files (`gh pr view <N> --json files`): the project merges
   several PRs a day.
4. Branch from current `main`; packaged releases (e.g. in nixpkgs) lag behind, and whole trees
   move (`skippy/` left the repo in #3193; a branch from before it needs a rebase). The PR
   branch lives in Mesh-LLM/mesh-llm itself as `kleinbem/<topic>`, not on the fork: Martin has
   write access (section 5), so CI runs and can be rerun without a maintainer.
5. Read the design docs for the area (`mesh/docs/design/`: crate ownership, testing, message
   protocol) and the notes in `references/` (e.g. `references/config-lifecycle.md` for anything
   in `MeshConfig`). Trace where a value you add goes (load, snapshot, apply, save) before
   designing: #2446 put an env override into a field that an owner's config apply would have
   written to `config.toml`.

Keep the change minimal: every new flag or option is an interface upstream has to maintain. Leave
to the downstream what it can do robustly itself (an `rm`, a `jq` line); propose upstream only what
replaces fragile patching.

Verify the downstream premise before designing an upstream change: inspect the built artifact
(manifest, `patchelf --print-needed`, bundle layout) instead of reasoning from the package
expression. A planned CUDA toolkit change was dropped once the bundle showed the backend library
lives outside it.
For what a package depends on (products, runtime discovery, network calls, paths), start from
`references/packaging.md`; it says which facts are still unverified.

## 1. Designing the change: follow the repository's patterns
Before designing, find the closest existing feature and mirror its shape: grep for an analogous
setting, flag or type, and read the commit that introduced it (`git log -S '<symbol>'`); its file
list is the checklist of touchpoints. Read the comments next to lists, tripwires and registries you extend:
they often say what else has to change with them. Maintainers review against these patterns (from reviews on
merged PRs; numbers are examples):
- **Settings:** a user-facing option is a config setting in `mesh-llm-config`, not only an
  environment variable (#2446: an env-only opt-out was sent back for a TOML setting with the
  variable as override). Template: `analytics.enabled` (#1993). Touchpoints: the field in
  `MeshConfig` and `RawMeshConfig` (a small type in its own `model/` module), the schema
  declaration (`built_in_schema/declarations.rs`, `setting_schema.rs`), its presentation, the
  wiring manifest, `mesh/website/src/docs/pages/config-reference.md` (canonical and checked by the
  docs parity tests) and `mesh/docs/CONFIGURATION_PR8_CLOSEOUT_AUDIT.md`; struct literals of
  `MeshConfig` in tests need the new field.
  - An environment variable only overrides a setting: apply it in
    `env_overrides.rs::apply_env_overrides` and add it to `CONFIG_OVERRIDE_ENV_NAMES` (two
    tripwire tests pin that list); don't read a `MESH_LLM_*` override with `std::env::var`
    elsewhere. An invalid value is a hard error, never a silent default. Each override also gets
    a test through host-runtime's production `load_config` wrapper (`plugin/config/tests.rs`
    asks for it in the comment above its tripwire). Keep the override out of the persisted field
    (a `#[serde(skip)]` field the getter prefers), or a config apply saves it
    (`references/config-lifecycle.md`).
  - Schema metadata (apply mode, restart scope) and the docs row match what the host really does
    (#2142); reject invalid values in typed validation instead of clamping them (#2113); add a
    save/reload round-trip test, plus the protocol conversion if the setting syncs (#2133).
  - Prefer a default-off setting over removing a capability users may rely on (#2307).
- **File size:** when touching a file over 1,000 lines, put a separable new responsibility into
  its own module (root `AGENTS.md`, "1k LoC refactoring rule"; #2300 asked to move a type out of a
  1,681-line file); never let a file pass 2,000 lines. Reviewers (and CodeRabbit) also object to
  a few added lines of new logic in a file already over 2,000 lines (`run_auto.rs`, #2446): put
  the logic in a small module named for it and leave one call in the big file.
- **Persisted state:** write atomically (temporary file, rename, directory sync) and treat only
  `NotFound` as "no record"; other read errors must not reset state (#2057, #2102, #2142).
  Replacing a user's file keeps its access: its mode on Unix, and on Windows its DACL, which a
  temporary file renamed over it doesn't carry (it inherits the directory's ACL); set and verify
  it through the temporary file's handle before writing, or leave the file alone (#2684).
- **Protocol and wire changes:** keep them additive (new fields, subprotocol feature strings),
  test a mixed mesh with an older release, and say whether a protocol version bump is needed
  (#2285, #2299, #2316).
- **Skippy changes** (native patches, ABI, runtime) go to `Mesh-LLM/skippy`. To test a
  mesh-llm change against an unreleased Skippy, build locally with `scripts/skippy-source.sh
  <checkout>` or `--ref <branch|pull/N>` (back with `--pinned`; never commit the `Cargo.toml` /
  `Cargo.lock` it changes), and in the PR put a line `Skippy-Ref: pull/<N>` in the body: the
  smoke job then builds the runtime and MeshLLM from that source (lint and tests stay on the pin).
- **Tests:** an extracted test file keeps its env-mutation audit registration (#2291); tests
  pass in the bare Linux lane without extra environment (#2364); every PR of a stack is green at
  its own merge point (#2359, #2374). A gate (a setting that turns something off) needs a test
  that the gated work really doesn't happen, not only that the value parses: pass the request
  in as a closure so the test can make it panic (#2446).
- **Clean build environments:** root `AGENTS.md` ("Tests in clean build environments") now holds
  the list our PRs established; check every new or changed test against it. Examples for PR
  bodies: no CA bundle (#2492), fixed tool paths `/bin/bash` (#2604), `/usr/bin/true` (#2699),
  `sysctl`/`ps` (#2672, #2673), the builder's `MESH_LLM_*` (#2630/#2707), no terminal (#2605),
  machine speed (#2700/#2705, #2670/#2696, #2716/#2720), the dynamic runtime (#2629), reading
  the own executable (#2751). A test that really needs network or hardware is feature-gated or
  `#[ignore]`d with the reason. The product side is in `references/packaging.md`.
- **When a maintainer fixes the same thing differently**, close the own PR and the issue with a
  short comment linking theirs, rather than rebasing on top (#2725 after i386's #2704). Verify
  first where the failure reproduces (the Orin for timing flakes; GitHub runners often don't).
- **Stack:** test threads have 2 MiB, and since #3193 no CI job sets `RUST_MIN_STACK` (the old
  Linux job set 8 MiB, which hid an overflow on 1.98.1 and led to a false #3074). Match
  upstream's environment (toolchain, variables) before filing. Don't propose raising the limit
  (or `opt-level` tricks as the fix); shrink the frame that grew (#1976 boxed route futures,
  #2690 split the CLI into flattened `Args` groups). Measure before and after (section 2).
- **CLI types (`mesh-llm-cli`):** clap derive defines every option of a struct in one function,
  and debug frames add up (clap-rs/clap#5134), so big option sets go into `#[derive(Args)]`
  structs (`Cli`'s groups in `parser/top_level_options.rs`, #2690). `#[command(flatten)]` keeps
  the `--help` order only when a group is a contiguous run of the old fields, flattened where the
  run was. Re-export new public types at the crate root next to `Cli` (`lib.rs`). Flatten empties
  the parent's implicit `ArgGroup`; nothing uses group ids today.
- **Docs follow the code:** doc comments that state a contract, README examples and the API
  reference for new API objects change with it (#2291, #2300); a UI change needs a screenshot and
  documented behaviour (#2315). A doc comment that explains a mechanism must match what the code
  really does (#2690's review: clap_derive defines fields in declaration order, so "returns
  before the subcommands are defined" was false for most groups).
- **SDK parity** (`AGENTS.md`, since #2703): a public SDK API change is complete only when the
  native bridge, Rust, Node.js, Python, Swift and Kotlin, their tests, product docs and the website
  examples under `mesh/website/src/docs/` change together. All five are in this repository now;
  Python is `mesh/sdk/python` (`"$SDK_PYTHON" -I -B mesh/sdk/python/tests/test_client.py`; CI
  doesn't run it, so run it yourself). Never hand-edit generated bindings.
- **Claims:** title and body claim no more than the code does (#2298: "phase 1" instead of
  enforcement; #2377: "one body claim is false"). Reviewers reproduce stated test counts at the
  head commit, so give exact commands and counts.

## 2. Building and validating
- Build with `just` only (bare `just` = `just build`: downloads the pinned Skippy release's
  runtime into `target/debug/native-runtimes`, then builds host and console; `just mesh` host
  only, `just runtime` runtime only). `cargo build/check` alone is not a complete product build.
- Run Cargo commands one at a time (lock conflicts otherwise).
- Validate by changed surface (root `AGENTS.md`, "Minimum validation by change type"):
  - **Rust:** `cargo check -p <crate>`, `cargo clippy -p <crate> --all-targets -- -D warnings`,
    `cargo test -p <crate> --lib` while iterating, and before the PR the full `cargo test -p`
    for the changed crates and the workspace crates that depend on them (`--lib` skips
    integration and doc tests, which CI runs). Code reachable from the `mesh-llm` binary also
    needs `cargo check -p mesh-llm` and `cargo clippy -p mesh-llm --all-targets -- -D warnings`.
    Format with `cargo fmt -p <crate> -- <file>` (never `cargo fmt --all -- <file>`: it loses the
    crate's edition) and run `cargo fmt --all --check` before committing.
  - **Broad change, or a `just` recipe or CI script changed:** `just test-all` (= `just lint`,
    `just test-rust`, `just test-ui`).
  - **Automation** is plain `just` recipes and scripts under `scripts/`, tests under
    `scripts/tests/` wired into `just lint` (ShellCheck plus the script tests). `tools/xtask`,
    `cargo xtool`, `ci/` and the planner were removed in #3193; don't call or restore them.
  - **CI:** read `.github/AGENTS.md` and `.agents/skills/manage-ci/SKILL.md` first (both short),
    run `actionlint` and `just lint`, and update `references/current-inventory.md` with a workflow.
  - **Env mutation:** any `std::env::set_var`/`remove_var` follows the contract in
    `mesh/docs/design/TESTING.md` (`#[serial]`, a restoring guard, a `// SAFETY:` comment). The
    `just check-env-mutation-contract` it names has no recipe at `74c8765c`: check by hand.
  - `mesh-llm-cli` parser files changed: `just cli-inventory-check` (needs npm).
- Script tests may call `/bin/bash` and `/usr/bin/true`. On NixOS, run a local copy with the paths
  substituted (`type -P bash`, `type -P true`; `command -v true` returns the shell builtin), or
  under `bwrap --dev-bind / / --ro-bind <dir with bash,sh> /bin --ro-bind <dir with true,env> /usr/bin`.
  The reverse also holds: envfs serves `/usr/bin/<tool>` from `PATH`, so a hardcoded path that
  fails in the Nix sandbox passes on the workstation; reproduce with
  `bwrap --dev-bind / / --tmpfs /usr/bin -- <test binary> <filter>`. Compare against unmodified
  `main` to separate host failures from your own.
- Local toolchain (NixOS, kleinbem fleet): no Cargo on `PATH`, so use
  `nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#clippy nixpkgs#rustfmt nixpkgs#gcc` (add
  `nixpkgs#protobuf nixpkgs#cmake nixpkgs#pkg-config` for `mesh-llm`). Upstream CI uses current
  stable (no `rust-toolchain.toml`; rustc 1.100.1 on 2026-11-28); nixpkgs' rustc can lag, so
  confirm a toolchain-dependent finding on stable. `.cargo/config.toml` routes rustc through
  `sccache`; without it, run with `CARGO_BUILD_RUSTC_WRAPPER=` (empty). `just` recipes still
  require `sccache` on `PATH` (`with-lld` checks it), so add `nixpkgs#sccache nixpkgs#lld
  nixpkgs#mold`, and `nixpkgs#nodejs nixpkgs#pnpm` for the console (pnpm 10+). For the runtime,
  `scripts/fetch-skippy-runtime.sh <dir> cpu` downloads the pinned release's CPU package; point
  the host at it with `MESH_LLM_NATIVE_RUNTIME_BUNDLE_DIR=<dir>` (and a fresh
  `MESH_LLM_NATIVE_RUNTIME_CACHE_DIR`), or run `just smoke <dir> <model.gguf>` and
  `just test-with-runtime <dir>` as CI does.
- Code rules for new code: no new warnings or `#[allow]`; functions under the Clippy line and
  cognitive-complexity limits; the file-size rule from section 1; no generic `utils`/`common`
  modules.
- Docs: authored docs live in `mesh/docs/`; the website pages in `mesh/website/src/docs/pages/`
  (`config-reference.md`, `analytics.md`, the SDK examples) are maintained source too. Only root
  `docs/`, the Eleventy output of `just website-build`, is generated: never edit it. A page in
  both places (`CLI.md`) may need the change twice. Some tests read docs (`include_str!`, e.g.
  `CLI.md` in the host-runtime `plugin/config/tests.rs`): grep for the touched file and run those.
- Tests for a fix must fail on the old code: run them once against the code before the fix. Don't
  change process-wide state such as `PATH` inside a test (tests run in parallel, and `set_var` is
  `unsafe` in Rust 2024); re-run the test binary as a child with `--exact <test>` and the
  environment set on the child.
- **Timing tests** (#2670, #2696): hold a slow callback on a `CallbackGate` (`test_support.rs`)
  instead of sleeping and checking milliseconds. A deadline the worker must reach the plugin
  within needs room for a busy machine (500 ms there), and a wait whose result comes from the
  callback gets a generous bound (10 s): neither slows a passing test. Declare a gate's release
  guard after the `Arc` of the driver, or a failing assertion aborts the binary through the gate's
  timeout instead of failing cleanly. Fixing one flaky test, sweep the file for the same pattern
  and run the whole suite repeatedly under load (`timeout 120 sh -c 'while :; do :; done' &` times
  4 × cores): CI found a fifth test the issue hadn't named. Before raising a bound, check the
  fixture's own waits: a fake server that holds its connection 5 s ends the probe by EOF, so a
  shutdown bound above that would pass even with the cancel broken.
- A proof probe must break every place that enforces the property: the proposal deadline is held
  both in `propose`'s reply wait and in the passive fence, and a probe that broke only one let a
  test pass (#2696).
- Claims about runtime behaviour need a built binary, not only reading the code. Grep for every
  caller of what you gate (the startup update check had a second caller in the console API). To
  check outgoing requests, run it behind a logging `HTTPS_PROXY` (reqwest honours it) and compare
  with and without the change.
- **Live proxy, routing, timeout, hook and plugin repros:** use `kleinbem/mesh-dev-plugin`
  (`mesh-dev`, also packaged in `kleinbem/nix-packages` and runnable via `mesh-dev test-suite`)
  instead of real GGUFs or hand-rolled mock HTTP servers. It provides deterministic zero-GPU
  `dev/*` models (`dev/echo`, `dev/slow-ttft-{15,45,75}s`, `dev/slow-sse-1tps`,
  `dev/mid-stream-drop`, `dev/http-{429,503}`, `dev/malformed-sse`, `dev/tool-call-edge`,
  `dev/mem-probe[-hold-5s]`, `dev/env-probe`, `dev/virtual-echo`), fault injection ops
  (`inject_health`, `inject_crash`, `inject_http_fault`, `set_model_override`), a bounded
  HTTP/observation/exchange inspector, and 5 declarative live E2E suites covering the full v3
  plugin contract (MCP, stapled HTTP, hooks, backpressure, security boundaries). Every upstream
  `Mesh-LLM/mesh-llm` issue or PR uncovered or reproduced with `mesh-dev` must be pinned
  immediately in `kleinbem/mesh-dev-plugin` (`docs/CAPABILITY_AUDIT.md` plus matching
  `suites/*.toml` / `tests/*.rs`) and in any downstream `WORKAROUND` (e.g. `kleinbem/nix-packages`)
  using `upstream: Mesh-LLM/mesh-llm#N` or `tracking: Mesh-LLM/mesh-llm#N`.
- When a change replaces a mechanism (a command → a system call), grep for comments, doc comments,
  docs and error messages that describe the old one (a maintainer had to fix `parse_hostname`'s doc
  on #2444). Also compare the old mechanism's behaviour in edge cases: `ps -o comm=` kept the name
  from exec time, `proc_pidpath` follows a renamed or deleted file (#2673); an in-place write kept
  the file's Windows DACL, a renamed temporary file doesn't (#2684). For a mechanical rename of fields, drive the rewrite from rustc's E0609 spans
  (`cargo check --message-format json`), then grep docs and design docs for the old names
  (#2690 missed `mesh/docs/design/VIRTUAL_LLM.md`).
- A CLI refactor that should not change the surface: compare against main with
  `cargo run -p mesh-llm-cli --bin mesh-llm-cli-inventory -- --check <main's inventory.json>` and
  a throwaway test that dumps `render_help`/`render_long_help` of every command, all options
  unhidden; both byte-identical (#2690).
- Stack use: a throwaway test that re-runs the overflowing test as a child on a thread of a given
  size (binary search, 16 KiB steps; run it on all three platforms). Frame sizes: `objdump -d -C`
  of the debug test binary; frames over a page allocate through a probe loop (`sub $N,%r11`), so
  add that to the final `sub $M,%rsp`, or every large frame reads as 4 KiB.
- **Pre-flight on GitHub's runners** (kleinbem/mesh-llm-ci, local clone
  `~/Develop/github.com/kleinbem/mesh-llm-ci`), before opening the PR and before every push to
  its branch, so upstream's CI isn't spent on a failing head. Push the head to a `preflight-*`
  branch on the fork, then mirror upstream's Test job (and Lint on Linux) with `run.yml`:
  ```bash
  script="$(cat "$HOME/.agents/skills/mesh-llm-contributing/references/upstream-ci-mirror.sh")"
  for p in linux macos windows; do
    gh workflow run run.yml -R kleinbem/mesh-llm-ci -f ref=<full sha> -f platform=$p \
      -f toolchain=stable -f script="$script"
  done
  ```
  The script (`references/upstream-ci-mirror.sh`) runs `cargo fmt --check` and workspace Clippy
  on Linux and `cargo test --workspace --locked --no-fail-fast` everywhere, like `just lint` /
  `just test-rust`; run `just lint`'s ShellCheck and script tests locally when scripts change.
  `check.yml` is stale since #3193: it still runs the removed planner (`xtask ci plan`), so don't
  use it on current main. Pass `toolchain=stable` (the input defaults to 1.98.1, older than
  upstream's). Take the full SHA from git or the API (`gh pr view <N> --json headRefOid`), never
  type or complete it. `run.yml`'s Windows runner is `windows-2025`, upstream's `windows-2022`.
  The script passed on Linux on 2026-11-28; check the first macOS and Windows runs before
  trusting a green row there.
  What stays local: the console (`just test-ui`), the inference smoke, behaviour of a built
  binary and distribution-specific tests.
- Upstream lints Clippy on Linux only, so main can carry Windows- or macOS-only findings. For a
  change to code that compiles there, also run
  `gh workflow run clippy-diff.yml -R kleinbem/mesh-llm-ci -f repo=kleinbem/mesh-llm
  -f base=<merge-base SHA> -f head=<head SHA> -f platform=windows -f packages='<changed crates, space-separated>'
  -f features=mesh-llm-system/dynamic-native-runtime,mesh-llm-skippy-adapter/dynamic-native-runtime
  -f toolchain=stable`: it fails only on findings the change adds (#2969: base 1, head 1, 0 new).
  Pass each feature only when its crate is selected or a selected package names it as a direct
  dependency (Cargo's rule). `packages=` is space-separated; a comma list fails "Validate
  inputs" (#3134).
- macOS code that spawns `ps` or `sysctl` passes on runners and fails in the Nix darwin sandbox;
  prefer `libc` calls. For a process's identity use what the kernel recorded at exec
  (`proc_pidinfo` `PROC_PIDT_SHORTBSDINFO` `pbsi_comm`, any account; `sysctl` `KERN_PROCARGS2`'s
  exec path, same account), not `proc_pidpath`, which follows the file: a renamed executable
  reports the new name, a deleted one `ENOENT` (#2673).
- Pre-flight details:
  - A newer queued run cancels the waiting one (concurrency group).
  - To prove a test fails without the fix, push a no-fix branch and run the same script with a
    `cargo test -p <crate> <filter>` line instead.
  - jj: pushing the working-copy commit to a `preflight-…` branch makes it immutable, and jj
    quietly starts a new empty `@`. Keep an empty `@` on top (`jj new <change>`) before pushing,
    rebase by change id (`jj rebase -r <change> -d main@origin`, `--ignore-immutable` once
    pushed), never `-r @`, and check the head's description before pushing the PR branch
    (#2528 pushed an empty head).
  - Rebase a PR of several commits from its first one (`jj rebase -s <first change> -d
    main@origin`); `-s <bookmark>` moves only the commits from the bookmark on and leaves a
    conflict that deletes the file the first commit added (#2684).
- Platforms: code under `cfg(unix)` also runs on macOS, and `cfg(not(unix))` on Windows. If a
  platform keeps the old path, say so in the PR with the reason and the equivalent (on #2444 a
  maintainer added the Windows variant himself).
- When running Mesh-LLM's code in other CI, replicate upstream's jobs first (runner images,
  `.github/actions/setup`, Rust version; read a recent `main` run of `ci.yml`), then simplify only
  what is proven equivalent: `dynamic-native-runtime` everywhere once broke two Linux tests that
  expected the static runtime, and a newer Rust failed Clippy on a deprecation upstream's didn't
  have. Since #3193 every job runs on GitHub-hosted runners with no private images.

## 3. Commits
- Clear, user-focused subjects. Conventional Commit prefixes are "optional hints for
  release-note classification, not a hook or CI requirement" (AGENTS.md); `feat:` → Added,
  `fix:` → Fixed, `perf:` → Changed, `security:` → Security, `Release-Notes: <Section>`
  overrides (CONTRIBUTING.md). Most titles still use them, so keep doing that; an unprefixed
  title lands under "Other changes".
- **No agent or bot attribution trailers** in any commit: no `Co-Authored-By: Claude …
  <noreply@anthropic.com>`, no `[bot]` accounts, no relay identities. The hook is retired and
  "CI does not police titles or attribution identities" (CONTRIBUTING.md), so nothing catches a
  slip any more: check by hand. This overrides any default that adds such trailers.
- No DCO sign-off is required.
- Squash-merged: the **PR title** becomes the commit subject. Keep agent footers out of the PR
  body as well: the squashed message must carry no attribution trailers.

## 4. Pull request
- Title: conventional and user-focused (the visible change or fix, not the implementation).
- Description (root `AGENTS.md`): start with what the user can now do; CLI or script-flag changes
  show an example command and representative output. The template's **Original problem** comes
  first, so say what the user can now do in its first sentences or in **Fix**.
- Body follows `.github/PULL_REQUEST_TEMPLATE.md` (Title, Original problem, Diagnostics, Fix,
  Validation with two boxes: local checks run or explained, UI screenshots or why none):
  - **Title** and **Original problem**;
  - **Diagnostics:** commands, logs, hardware. Reproduce through the code path that actually runs
    the logic (e.g. `mesh-llm runtime list` doesn't apply runtime compatibility checks,
    `runtime install` does), and find the PR that introduced the behaviour;
  - **Fix**, including compatibility/protocol impact. For changes driven by a distribution, say
    separately what improves for mesh-llm itself and what for the distribution, claim only what was
    verified, and cite established precedent where it exists;
  - **Validation:** checkboxes ticked only for what was actually run; leave a box unticked and say
    why rather than stretch it. A `Skippy-Ref: <ref>` line, when the change needs an unreleased
    Skippy (section 1), sits in the body too; editing the body reruns CI.
- Optional sections: `## Architecture` / `## Protocol` for those impacts; CLI changes show example
  commands and output; UI changes need a screenshot.
- AI assistance can be stated in the PR text. Keep it out of commit trailers (see above).
- After opening, don't retitle the PR or rewrite its description for later updates; summarise
  non-obvious follow-up work in comments (`.github/instructions/pr.instructions.md`). A body
  sentence that a later fix made false is the exception: correct that sentence (with Martin's OK),
  so the body never claims what the code no longer does (#2673, #2684).
- **Right before opening, check (all of them, every PR):**
  - main hasn't moved since the last rebase (`gh api repos/Mesh-LLM/mesh-llm/commits/main`);
  - no open PR touches the same files (`gh pr view <N> --json files` over the open PRs); if one
    does, compare the hunks and mention a real overlap in the body;
  - Diagnostics names the PR that introduced the behaviour (`git log -S '<symbol>'` on main;
    follow moves back to the original PR, e.g. #2494: #452 introduced it, #1082 moved it). For a
    test, search its name: a test "from the Skippy split (#2099)" came with #1718;
  - the pre-flight ran on the exact head commit, also after a message-only amend (an identical
    tree can be shown with `git rev-parse <old>^{tree} <new>^{tree}`, but run it anyway);
  - the body has no `TODO` left and all PR cross-links are filled in;
  - the head branch is `kleinbem/<topic>` in Mesh-LLM/mesh-llm, not on the fork (#3017 and #3018
    went out from the fork on 2026-11-11 although write access existed; their CI then needed a
    maintainer's approval).
- **Checks from review history** (2026-11-09 review of all our PRs; each line is a miss a
  reviewer or bot had to point out):
  - **Sibling sites:** grep the whole repo for the construct you replace (e.g. `Client::builder()`)
    and for every producer and consumer of a changed format; list the sites and their count in
    Fix, and why any stay (#2577 missed two local clients, #2755 the validator, #2303 three Bash
    sites).
  - **Platforms:** code behind `cfg` is gated exactly like its callers, and Clippy `-D warnings`
    runs for the macOS and Windows targets of the touched crates, not only Linux (#2939:
    `dead_code` on Windows; upstream's Lint is Linux only). Shell arrays expand as `${a[@]+"${a[@]}"}`, and a changed script's
    tests run under macOS `/bin/bash` 3.2 (#2303).
  - **Loopback HTTP clients** trust no CA roots, follow no redirects and ignore proxies, with a
    test for each property (#2491, #2492, #2577). Get one from
    `mesh_llm_system::local_http::local_http_client_builder()`.
  - **No vacuous passes:** assert that the path under test ran, so a fallback (`None`, a skip,
    an early return) fails the test instead of satisfying it (#2720).
  - **Path and environment predicates:** before opening, write down the directory, symlink,
    empty, relative, non-executable and non-UTF-8 cases (#2494, #2648, #2712, #2863, #2939).
    A value passed on to another program follows that program's rules (`upstream-contributing`,
    section 2).
  - **Invariants hold in tests:** a fixture doesn't loosen what the code guarantees (a child's
    cleared environment, no silent defaults) to make itself pass (#2939).
  - **Repo-wide rules** (AGENTS.md, docs): grep for code that legitimately breaks the rule and
    write the exception into it (#2754).
  - **"This API is gone"** only after checking every SDK entry point and its known consumers
    (#2564).
  - **Distribution-driven changes** are tested in the build environment of the distribution that
    drove them, with the patch applied; for our Nix-driven changes that is nixpkgs' package in the
    sandbox on x86_64-linux, aarch64-linux and aarch64-darwin (#2939: the darwin sandbox refused
    `/bin/sleep`, which runners never show). When more runs make a result more
    certain (repeats under load, more platforms), run them.
- The human submitter reviews the change before it is opened. Never claim review or testing in
  their name that they did not do.
- PRs here open non-draft, so the independent review (`upstream-contributing`, section 6) runs
  before opening, not before ready: on #2690 it found two wrong numbers and a false doc claim.

## 5. CI on the pull request
Source: `.github/workflows/ci.yml`, `.github/AGENTS.md`, `.agents/skills/manage-ci/SKILL.md`.
- Since #3193 one workflow, `ci.yml`, on GitHub-hosted runners (no Depot, no planner, no slices),
  on `pull_request` (also `edited`, for `Skippy-Ref`), push to `main` and `workflow_dispatch`
  (input `skippy_ref`). Every job runs on every PR:
  - **Lint** (ubuntu-24.04): `just lint` = `cargo fmt --all -- --check`, `cargo clippy
    --workspace --all-targets -- -D warnings`, ShellCheck and the `scripts/tests/` scripts
    (`just/ci.just`);
  - **Test** on ubuntu-24.04, macos-15 and windows-2022: `just test-rust --locked
    --no-fail-fast` (`cargo test --workspace`, integration and doc tests included);
  - **Console**: `just test-ui`; **Public website**: `scripts/ci-website.sh`;
  - **Inference smoke (CPU)**, Linux: fetches the pinned Skippy CPU runtime
    (`scripts/fetch-skippy-runtime.sh skippy-runtime cpu`, or builds the `Skippy-Ref` source),
    `just mesh`, `just smoke`, a two-node mesh routing smoke with
    `MESH_LLM_NATIVE_RUNTIME_BUNDLE_DIR`, `just test-with-runtime`;
  - **CPU host smoke** on macos-15 and windows-2022 (`scripts/ci-cpu-host-smoke.py`).
  Toolchain: current stable through `.github/actions/setup` (rustc 1.100.1 on 2026-11-28), no
  `rust-toolchain.toml`, no `RUST_MIN_STACK`.
- Required checks are still the five names `PR / Quality`, `Linux`, `macOS`, `Windows`,
  `Website`; in `ci.yml` they are one aggregator job, and each passes only when every job above
  passed. A red job anywhere turns all five red; read the failing job itself.
- PR runs share a concurrency group per PR with `cancel-in-progress`: a new push cancels the old
  run, which is not a failure of its own. Before diagnosing, confirm the run belongs to the
  current head and really failed (root `AGENTS.md`, "Testing").
- **Write access since 2026-11-01** (i386 gave Martin write access to Mesh-LLM/mesh-llm, so CI runs
  without approval; #2751):
  - New PR branches go to the upstream repository, named `kleinbem/<topic>` (others use their own
    prefix: `brody/`, `astrid/`); CI then starts on every push without an approval.
  - The fork (`fork` remote, kleinbem/mesh-llm) stays for the PRs opened from it until they merge,
    and for scratch work nobody upstream should see: `preflight-*`, stress tests, probes. Never push
    scratch branches upstream: they clutter the branch list and can start CI.
  - Write access is trust, not a shortcut: never push to `main` or to someone else's branch, never
    merge (maintainers do), no force-push on a PR under review beyond the usual rebase.
  - A red job that the change doesn't cause (a known flaky test): rerun only the failed jobs,
    `gh run rerun <run-id> -R Mesh-LLM/mesh-llm --failed`, after checking the failure. A
    recurring flake gets an issue with the cause and the affected runs (#3028).
  - The repository deletes merged head branches (`delete_branch_on_merge`); delete a
    `kleinbem/<topic>` branch yourself only when its PR is closed without merging.
- Fork PRs (the ones opened before write access) wait in `action_required` until a maintainer
  approves the run, and each new push can need approval again: push once the change is complete.
  Runs left unapproved are closed as "failed" (zero jobs) when the PR merges; harmless.
- An open PR from before #3193 still carries `skippy/`, `ci/` and `tools/xtask`: rebase it onto
  current main before expecting the new CI to pass.
- No self-imposed open-PR queue cap: open ready fixes upstream as soon as they pass pre-flight and
  review rather than holding them locally where they get lost when sessions close. Still group
  fixes by cause (one PR for a class of sandbox failures) rather than one PR per test
  (`nixpkgs-packaging` Phase 2).
- CodeRabbit reviews every PR within minutes. Read its comments: fix what is sound, or reply with
  the reason; don't leave them unanswered. It tends to ask for backward compatibility with
  features that were never released; a maintainer said to take that with a grain of salt (#2132).
  Its "Docstring Coverage" pre-merge warning counts every function a diff touches; maintainers
  merge with 0% (#2629, #2662, #2677), so don't add doc comments to untouched logic for it.
  Some findings exist only in its review body ("Nitpick comments: N", "Outside diff range"), not
  as threads: read every CodeRabbit review body after a push (#2696).
- A maintainer (ndizazzo) reviews with ranked findings (`[P2]`, `[P3]`), each reproduced at the
  head (#2511, #2513, #2565); a P2 can come with "changes requested" (#2422, #2565), P3s are
  usually marked non-blocking. Answer each like a CodeRabbit comment: fix, or one line why not.
  He checks what CodeRabbit raises and the PR declines, and platform edge cases: Windows ACLs
  (#2684), a running executable renamed or deleted (#2673). CODEOWNERS: `@i386 @ndizazzo
  @michaelneale` by default, `/.github/` i386 and ndizazzo, `/mesh/` michaelneale and ndizazzo.
- A push keeps earlier approvals: main's ruleset has `dismiss_stale_reviews_on_push: false`,
  `require_last_push_approval: false` and `required_approving_review_count: 0` (checked
  2026-11-28 with `gh api repos/Mesh-LLM/mesh-llm/rules/branches/main`). Each push still runs CI
  (and on a fork PR needs approval again), so push only complete changes, and don't touch a PR
  that is approved and green just to rebase it.
- Keep "Allow edits by maintainers" on: maintainers fix PRs themselves, and on #2156 they had to
  ask for a cherry-pick because it was off.
- `main` moves several times a day, so the rebase before every push (`upstream-contributing`)
  matters here more than anywhere.
- Maintainers push commits to PR branches (#2444). Fetch the branch's remote (`origin` for an
  upstream branch, `fork` for an old fork PR) before any further push and build on its head;
  pushing a stale local bookmark would overwrite their work.

## Review checklist
For the review before ready (`upstream-contributing`, section 6):
- **No agent attribution anywhere**: no trailers in commits, no agent footer in the PR body
  (section 3); no CI catches it now.
- Title and commits are clear and user-focused; a conventional prefix is optional (AGENTS.md).
- The repository's patterns (section 1): settings vs env overrides and their tripwires, file size
  rule, atomic persisted state, additive protocol changes, gate tests that prove the gated work
  doesn't happen, docs following code (`mesh/docs/` and the website pages), SDK parity.
- Nothing Skippy-side added here (source, patches, runtime builds, Skippy tests; root
  `AGENTS.md`); a needed Skippy change is its own PR in Mesh-LLM/skippy, tested via `Skippy-Ref`.
- Claims: test counts and behaviour in the body reproduce at the head commit.
- Template sections filled (Original problem, Diagnostics naming the introducing PR, Fix,
  Validation with only run boxes ticked); no `TODO` left.
- The "right before opening" list in section 4, and the pre-flight (`run.yml`, not the stale
  `check.yml`) on the exact head.
- The independent reviewer's brief asks about sibling sites, `cfg` gating per platform, the
  code's invariants, the repo's own rules and the rules of any program a value is passed on to,
  not only whether the change works.
- New or changed tests pass the clean-build-environment list (root `AGENTS.md`, section 1) and
  the full `cargo test -p` of the touched crates, not only `--lib`.
