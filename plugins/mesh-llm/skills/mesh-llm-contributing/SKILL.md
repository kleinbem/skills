---
name: mesh-llm-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/mesh-llm (MeshLLM host, Skippy, native runtimes, packaging scripts) to follow its build, validation, commit, attribution and PR-template rules.
---

# Mesh-LLM/mesh-llm Contribution & PR Workflow

Sources of truth in the repo: `AGENTS.md` (root), `skippy/AGENTS.md`, `mesh/AGENTS.md`,
`CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/instructions/pr.instructions.md`,
and the repo-local skills in `.agents/skills/` (e.g. `release-notes`, `manage-ci`). Read the ones
for the touched area before acting; the project moves fast (several merges a day).
Mesh-LLM is its own organisation (not block/buzz); discussion happens on the Goose Discord
`#mesh-llm` channel (https://discord.gg/goose-oss).

## 0. Before the first edit (do these, in order)
1. Read root `AGENTS.md`, the owning product's `AGENTS.md` (Skippy `skippy/`, MeshLLM `mesh/`;
   Mesh depends on Skippy, never the reverse; both for integration changes) and
   `.github/instructions/pr.instructions.md`.
2. Search open/closed issues and PRs for the problem (`gh search issues|prs --repo Mesh-LLM/mesh-llm`).
3. Check open PRs that touch the same files (`gh pr view <N> --json files`): the project merges
   several PRs a day and is moving scripts into Rust automation.
4. Branch from current `main`; packaged releases (e.g. in nixpkgs) lag behind, and paths move
   (e.g. `scripts/` → `skippy/scripts/`).

Keep the change minimal: every new flag or option is an interface upstream has to maintain. Leave
to the downstream what it can do robustly itself (an `rm`, a `jq` line); propose upstream only what
replaces fragile patching.

Verify the downstream premise before designing an upstream change: inspect the built artifact
(manifest, `patchelf --print-needed`, bundle layout) instead of reasoning from the package
expression. A planned CUDA toolkit change was dropped once the bundle showed the backend library
lives outside it.

## 1. Building and validating
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
    Python, not even temporary helpers.
  - **Shell-only:** a syntax check (`bash -n`) plus the nearest contract test.
  - **CI:** read `.agents/skills/manage-ci/SKILL.md` completely first, then run `just ci-validate`.
- Script tests call `/bin/bash` and `/usr/bin/true`. On NixOS, run a local copy with the paths
  substituted (`type -P bash`, `type -P true`; `command -v true` returns the shell builtin), and
  compare against unmodified `main` to separate host failures from your own (e.g. some CUDA
  toolkit tests error on hosts without the toolkit, with or without a change).
- Local toolchain (NixOS, kleinbem fleet): no Cargo on `PATH`, so use
  `nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#clippy nixpkgs#rustfmt nixpkgs#gcc` (add
  `nixpkgs#protobuf nixpkgs#cmake nixpkgs#pkg-config` for `mesh-llm`). `.cargo/config.toml` routes
  rustc through `sccache`; without it, run with `CARGO_BUILD_RUSTC_WRAPPER=` (empty). "mold is
  unavailable" linker-probe warnings are harmless.
- Code rules for new code: no new warnings or `#[allow]`; functions under the Clippy line and
  cognitive-complexity limits; files under 2,000 lines; no generic `utils`/`common` modules.
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

## 2. Commits
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
- Squash-merged: the **PR title** becomes the commit subject and must be conventional too.

## 3. Pull request
- Title: conventional and user-focused (the visible change or fix, not the implementation).
- Description (root `AGENTS.md`): start with what the user can now do; CLI or script-flag changes
  show an example command and representative output.
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
- The human submitter reviews the change before it is opened. Never claim review or testing in
  their name that they did not do.

## 4. CI on the pull request
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
  the reason; don't leave them unanswered.
