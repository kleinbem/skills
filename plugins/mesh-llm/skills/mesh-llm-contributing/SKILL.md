---
name: mesh-llm-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/mesh-llm (MeshLLM host, Skippy, native runtimes, packaging scripts) to follow its build, validation, commit, attribution and PR-template rules.
disable-model-invocation: true
---

# Mesh-LLM/mesh-llm Contribution & PR Workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/mesh-llm and wins where they differ.

Sources of truth in the repo: `AGENTS.md` (root), `skippy/AGENTS.md`, `mesh/AGENTS.md`,
`CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/instructions/pr.instructions.md`,
and the repo-local skills in `.agents/skills/` (e.g. `release-notes`, `manage-ci`). Read the ones
for the touched area before acting; the project moves fast (several merges a day; 42 from
2026-10-21 to 10-25, 23 of them from forks). Summary as of 2026-10-25.

## 0. Before the first edit (do these, in order)
1. Read root `AGENTS.md`, the owning product's `AGENTS.md` (Skippy `skippy/`, MeshLLM `mesh/`;
   Mesh depends on Skippy, never the reverse; both for integration changes) and
   `.github/instructions/pr.instructions.md`.
2. Search open/closed issues and PRs for the problem (`gh search issues|prs --repo Mesh-LLM/mesh-llm`).
3. Check open PRs that touch the same files (`gh pr view <N> --json files`): the project merges
   several PRs a day and is moving scripts into Rust automation.
4. Branch from current `main`; packaged releases (e.g. in nixpkgs) lag behind, and paths move
   (e.g. `scripts/` → `skippy/scripts/`).
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
- **Protocol and wire changes:** keep them additive (new fields, subprotocol feature strings),
  test a mixed mesh with an older release, and say whether a protocol version bump is needed
  (#2285, #2299, #2316).
- **Native patches (Skippy):** fold a fix into the patch that owns the code instead of adding a
  patch (#2258, #2259, #2280, `skippy/AGENTS.md`); bump the ABI in lockstep in the header and
  `skippy-ffi`, and list the ABI changes in the PR body (#2089, #2252).
- **Tests:** an extracted test file keeps its env-mutation audit registration (#2291); tests
  pass in the bare Linux lane without extra environment (#2364); every PR of a stack is green at
  its own merge point (#2359, #2374). A gate (a setting that turns something off) needs a test
  that the gated work really doesn't happen, not only that the value parses: pass the request
  in as a closure so the test can make it panic (#2446).
- **Docs follow the code:** doc comments that state a contract, README examples and the API
  reference for new API objects change with it (#2291, #2300); a UI change needs a screenshot and
  documented behaviour (#2315).
- **Claims:** title and body claim no more than the code does (#2298: "phase 1" instead of
  enforcement; #2377: "one body claim is false"). Reviewers reproduce stated test counts at the
  head commit, so give exact commands and counts.

## 2. Building and validating
- Build with `just` only (`just`, `just skippy`, `just mesh`); `cargo build/check` alone is not a
  complete product build.
- Run Cargo commands one at a time (lock conflicts otherwise).
- Validate by changed surface (root `AGENTS.md`, "Minimum validation by change type"):
  - **Rust:** `cargo check -p <crate>`, `cargo test -p <crate> --lib`,
    `cargo clippy -p <crate> --all-targets -- -D warnings`, and `just no-console-print`. Code
    reachable from the `mesh-llm` binary (Skippy crates included) also needs
    `cargo check -p mesh-llm` and `cargo clippy -p mesh-llm --all-targets -- -D warnings`.
    Format with `cargo fmt -p <crate> -- <file>` (never `cargo fmt --all -- <file>`: it loses the
    crate's edition) and run `cargo fmt --all --check` before committing.
  - **No Python:** the repository's Python tooling is gone and the generic Python gate is retired.
    Automation is Rust in `tools/xtask` (`cargo xtool …`) behind thin `just` recipes; don't add
    Python, not even temporary helpers. Since #2530 the Quality gate enforces it: `just
    ci-crate-lists` rejects Python sources, shebangs and direct interpreter calls not listed in
    `ci/python-tooling-policy.json`.
  - **Shell-only:** a syntax check (`bash -n`) plus the nearest contract test.
  - **CI:** read `.agents/skills/manage-ci/SKILL.md` completely first, then run `just ci-validate`.
- Script tests call `/bin/bash` and `/usr/bin/true`. On NixOS, run a local copy with the paths
  substituted (`type -P bash`, `type -P true`; `command -v true` returns the shell builtin), and
  compare against unmodified `main` to separate host failures from your own (e.g. some CUDA
  toolkit tests error on hosts without the toolkit, with or without a change).
- Local toolchain (NixOS, kleinbem fleet): no Cargo on `PATH`, so use
  `nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#clippy nixpkgs#rustfmt nixpkgs#gcc` (add
  `nixpkgs#protobuf nixpkgs#cmake nixpkgs#pkg-config` for `mesh-llm`). `.cargo/config.toml` routes
  rustc through `sccache`; without it, run with `CARGO_BUILD_RUSTC_WRAPPER=` (empty). `just`
  recipes still require `sccache` on `PATH` (`with-lld` checks it), so add `nixpkgs#sccache
  nixpkgs#lld`, and `nixpkgs#nodejs nixpkgs#pnpm` for `just mesh` (console UI). "mold is
  unavailable" linker-probe warnings are harmless.
- Code rules for new code: no new warnings or `#[allow]`; functions under the Clippy line and
  cognitive-complexity limits; the file-size rule from section 1; no generic `utils`/`common`
  modules.
- Run locally what the PR's Quality lane runs for the change (`ci-quality-slice.yml`), so the PR
  doesn't wait for an approval only to fail:
  - any `std::env::set_var`/`remove_var` added, moved or wrapped:
    `cargo xtool repository env-mutation-census` (a build script's mutation needs a `SAFETY:`
    comment that says "build script"; other files have stricter rules);
  - dependencies changed: `cargo machete`; crates or workspace members changed:
    `cargo xtool repo-consistency ci-crate-lists`;
  - `mesh-llm-cli` parser files changed: `just cli-inventory-check` (needs npm).
- Docs: authored docs live in `mesh/docs/` and `skippy/docs/`; the website copy
  (`mesh/website/src/docs/pages/`) is synced by the release commits, so edit only the authored file.
  Some tests read docs (`include_str!`, e.g. `mesh/docs/CLI.md` in the host-runtime plugin config
  tests): grep for the touched file and run those tests.
- Tests for a fix must fail on the old code: run them once against the code before the fix. Don't
  change process-wide state such as `PATH` inside a test (tests run in parallel, and `set_var` is
  `unsafe` in Rust 2024); re-run the test binary as a child with `--exact <test>` and the
  environment set on the child.
- Claims about runtime behaviour need a built binary, not only reading the code. Grep for every
  caller of what you gate (the startup update check had a second caller in the console API). To
  check outgoing requests, run it behind a logging `HTTPS_PROXY` (reqwest honours it) and compare
  with and without the change.
- When a change replaces a mechanism (a command → a system call), grep for comments, doc comments,
  docs and error messages that describe the old one (a maintainer had to fix `parse_hostname`'s doc
  on #2444).
- Pre-flight check on GitHub's runners instead of the workstation, before opening the PR and
  after every push: push the branch to the fork, then
  `gh workflow run check.yml -R kleinbem/mesh-llm-ci -f ref=<full sha> -f title="<PR title>"`.
  It runs upstream's own planner (`xtask ci plan`), so Clippy, tests and platform rows cover what
  upstream's PR lanes would, plus fmt, commit convention, `no-console-print`, the env census,
  `ci-crate-lists` and `cargo machete`; read its job summary. Take the full SHA from git or the API
  (`gh pr view <N> --json headRefOid`), never type or complete it. Keep its `toolchain` input at
  the Rust version of upstream's runner image (the `cargo` version in a recent Quality Clippy log).
  What stays local: behaviour of a built binary and distribution-specific tests.
  The macOS and Windows rows run `--lib` only, as upstream's do; for integration tests
  (`tests/`) on those platforms add `-f targets=all` (kleinbem/mesh-llm-ci#3, until merged
  dispatch with `--ref macos-all-targets`). macOS code that spawns `ps` or `sysctl` passes on
  runners and fails in the Nix darwin sandbox; prefer `libc` calls (`proc_pidpath`,
  `proc_pidinfo`).
  Not covered by the pre-flight: upstream's Quality step "Test CI, packaging, and SDK contracts"
  (`just ci-automation-contracts`, `just/ci.just`), which runs the `xtask` test binaries with
  `--features automation-contracts`, among them `--test migration_lifecycle` (the tests of
  `skippy/scripts/package-native-runtime.sh`). The planner's Linux batches don't include `xtask`.
  When a change touches `tools/xtask` or `skippy/scripts`, run the affected test yourself:
  `cargo test --locked -p xtask --features automation-contracts --test migration_lifecycle <filter> -- --test-threads=1`.
  Its fixture hardcodes `/bin/bash` and `/usr/bin/true`; on NixOS run it under
  `bwrap --dev-bind / / --ro-bind <dir with bash,sh> /bin --ro-bind <dir with true,env> /usr/bin`
  (envfs doesn't satisfy it).
- Pre-flight details (kleinbem/mesh-llm-ci, local clone `~/Develop/github.com/kleinbem/mesh-llm-ci`):
  - A newer queued run cancels the waiting one (concurrency group).
  - A `packages=` override sends those crates to the macOS and Windows rows too; crates that build
    skippy-ffi fail on Windows there because upstream never tests them on Windows. Ignore that
    row for such manual runs. `filter=` narrows the macOS/Windows test names.
  - The Ubuntu full xtask suite always shows 3 "requires just" failures and one rotating flaky
    process test: environment, not regressions.
  - To prove a test fails without the fix, push a no-fix branch and run the pre-flight with
    `packages=`/`filter=`.
  - jj: pushing the working-copy commit to a `preflight/…` branch makes it immutable, and jj
    quietly starts a new empty `@`. Keep an empty `@` on top (`jj new <change>`) before pushing,
    rebase by change id (`jj rebase -r <change> -d main@origin`, `--ignore-immutable` once
    pushed), never `-r @`, and check the head's description before pushing the PR branch
    (#2528: an empty head failed the commit-convention check).
- Platforms: code under `cfg(unix)` also runs on macOS, and `cfg(not(unix))` on Windows. If a
  platform keeps the old path, say so in the PR with the reason and the equivalent (on #2444 a
  maintainer added the Windows variant himself).
- When running Mesh-LLM's code in other CI, replicate upstream's platform rows first (runner
  images, the repository's own `.github/actions`, features per platform, Rust version; read a
  recent successful `main_*` run's job steps), then simplify only what is proven equivalent:
  `dynamic-native-runtime` everywhere broke two Linux tests that expect the static runtime, and
  Rust 1.99 failed Clippy on a deprecation upstream's 1.98 doesn't have. Upstream's Linux and
  Clippy jobs need the private `ghcr.io/mesh-llm/mesh-llm-cuda-runner` image, so upstream's own
  workflows can't run them on a fork.

## 3. Commits
- Conventional Commits v1.0.0. Allowed types: `feat`, `fix`, `perf`, `security`, `revert`,
  `refactor`, `style`, `test`, `build`, `deps`, `ci`, `chore`, `docs`. The type decides the
  release-notes section.
  - Check: `cargo xtool repository conventional-commits --message "<title>"`, or a range with
    `just check-commits` (default `origin/main..HEAD`).
  - `just hooks-install` sets `core.hooksPath` to `scripts/hooks`; its only hook, `commit-msg`,
    runs the same check. jj and jj workspaces don't run git hooks, so check by hand.
- **No agent or bot attribution trailers** in any commit: no `Co-Authored-By: Claude …
  <noreply@anthropic.com>`, no `[bot]` accounts, no relay identities. The hook and CI reject them.
  This overrides any default that adds such trailers.
- No DCO sign-off is required.
- Squash-merged: the **PR title** becomes the commit subject and must be conventional too. CI's
  commit-convention job checks the title like a commit subject (a fork PR titled `[CI experiment]
  feat(…)` failed it) and the attribution trailers of the squashed message; keep agent footers out
  of the PR body as well.

## 4. Pull request
- Title: conventional and user-focused (the visible change or fix, not the implementation).
- Description (root `AGENTS.md`): start with what the user can now do; CLI or script-flag changes
  show an example command and representative output. The template's **Original problem** comes
  first, so say what the user can now do in its first sentences or in **Fix**.
- Body follows `.github/PULL_REQUEST_TEMPLATE.md`:
  - **Title** and **Original problem**;
  - **Diagnostics:** commands, logs, hardware. Reproduce through the code path that actually runs
    the logic (e.g. `mesh-llm runtime list` doesn't apply runtime compatibility checks,
    `runtime install` does), and find the PR that introduced the behaviour;
  - **Fix**, including compatibility/protocol impact. For changes driven by a distribution, say
    separately what improves for mesh-llm itself and what for the distribution, claim only what was
    verified, and cite established precedent where it exists;
  - **Validation:** checkboxes ticked only for what was actually run; leave a box unticked and say
    why rather than stretch it.
- Optional sections: `## Architecture` / `## Protocol` for those impacts; CLI changes show example
  commands and output; UI changes need a screenshot.
- AI assistance can be stated in the PR text. Keep it out of commit trailers (see above).
- After opening, don't retitle the PR or rewrite its description for later updates; summarise
  non-obvious follow-up work in comments (`.github/instructions/pr.instructions.md`).
- **Right before opening, check (all of them, every PR):**
  - main hasn't moved since the last rebase (`gh api repos/Mesh-LLM/mesh-llm/commits/main`);
  - no open PR touches the same files (`gh pr view <N> --json files` over the open PRs); if one
    does, compare the hunks and mention a real overlap in the body;
  - Diagnostics names the PR that introduced the behaviour (`git log -S '<symbol>'` on main;
    follow moves back to the original PR, e.g. #2494: #452 introduced it, #1082 moved it);
  - the pre-flight ran on the exact head commit, also after a message-only amend (an identical
    tree can be shown with `git rev-parse <old>^{tree} <new>^{tree}`, but run it anyway);
  - the body has no `TODO` left and all PR cross-links are filled in.
- The human submitter reviews the change before it is opened. Never claim review or testing in
  their name that they did not do.

## 5. CI on the pull request
Source: `.agents/skills/manage-ci/SKILL.md` (read it completely before any CI work) and
`.github/workflows/`.
- Five required checks, one workflow each: Quality, Website, Linux, macOS, Windows. A planner
  selects the work from the changed paths and crates; unselected lanes succeed without running.
  Quality runs commit convention, `cargo fmt`, Clippy over the affected crates and their reverse
  dependencies, CI contracts and consistency (incl. `no-console-print`, the env-mutation census) and
  `cargo machete`; Linux runs the Rust tests of the affected crates and their reverse dependencies.
- Fork PRs wait in `action_required` until a maintainer approves the run, and each new push can need
  approval again: push once the change is complete, not in small steps. Runs left unapproved are
  closed as "failed" (zero jobs) when the PR merges; those notification emails are harmless.
- The first failing job cancels the other lanes of the same revision; a cancelled lane is not a
  failure of its own.
- The `ci:canary` label is only for PRs that change CI.
- CodeRabbit reviews every PR within minutes. Read its comments: fix what is sound, or reply with
  the reason; don't leave them unanswered. It tends to ask for backward compatibility with
  features that were never released; a maintainer said to take that with a grain of salt (#2132).
- A maintainer (ndizazzo) reviews with ranked findings (`[P2]`, `[P3]`), each reproduced at the
  head (#2511, #2513, #2565); a P2 can come with "changes requested" (#2422, #2565), P3s are
  usually marked non-blocking. Answer each like a CodeRabbit comment: fix, or one line why not.
- A push dismisses earlier approvals (repository ruleset; #2073, #2257), another reason to push
  only complete changes.
- Keep "Allow edits by maintainers" on: maintainers fix PRs themselves, and on #2156 they had to
  ask for a cherry-pick because it was off.
- `main` moves several times a day, so the rebase before every push (`upstream-contributing`)
  matters here more than anywhere.
- The planner (`.github/actions/plan-ci`) requires a PR head's `ci/slices.yml` and
  `ci/ownership.yml` to be byte-identical to main's. Every catalog change on main (e.g. #2449,
  #2474) makes Plan fail on all older PRs ("source slice catalog differs from the protected planner
  catalog"), even on approved ones, and only a rebase fixes it; check with
  `git diff <head> origin/main -- ci/slices.yml ci/ownership.yml` before expecting CI to pass.
  A push dismisses approvals, so rebase all affected PRs in one go, pre-flight first.
- Maintainers push commits to PR branches (#2444). Fetch the fork before any further push and
  build on its head; pushing a stale local bookmark would overwrite their work.

## Review checklist
For the review before ready (`upstream-contributing`, section 6):
- **No agent attribution anywhere**: no trailers in commits, no agent footer in the PR body
  (section 3).
- Title and every commit pass `cargo xtool repository conventional-commits`.
- The repository's patterns (section 1): settings vs env overrides and their tripwires, file size
  rule, atomic persisted state, additive protocol changes, Skippy patch ownership and ABI,
  gate tests that prove the gated work doesn't happen, docs following code.
- Claims: test counts and behaviour in the body reproduce at the head commit.
- Template sections filled (Original problem, Diagnostics naming the introducing PR, Fix,
  Validation with only run boxes ticked); no `TODO` left.
- The "right before opening" list in section 4, and the pre-flight on the exact head.
- `ci/slices.yml` and `ci/ownership.yml` identical to main's (section 5).
