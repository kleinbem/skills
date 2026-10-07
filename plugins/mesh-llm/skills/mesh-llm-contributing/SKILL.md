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
`#mesh-llm` channel.

## 0. Before writing code
- Search open/closed issues and PRs for the problem first.
- The workspace has two products: Skippy (`skippy/`) and MeshLLM (`mesh/`). Mesh depends on
  Skippy, never the reverse. Read the owning product's `AGENTS.md`; read both for integration changes.
- Work against current `main`; packaged releases (e.g. in nixpkgs) can lag behind, and paths move
  (e.g. `scripts/` → `skippy/scripts/`).

## 1. Building and validating
- Build with `just` only (`just`, `just skippy`, `just mesh`); `cargo build/check` alone is not a
  complete product build.
- Run Cargo commands one at a time (lock conflicts otherwise).
- Validate by changed surface (root `AGENTS.md`, "Minimum validation by change type"):
  - **Rust:** `cargo fmt -p <crate>`, `cargo check -p <crate>`,
    `cargo clippy -p <crate> --all-targets -- -D warnings`, and `just no-console-print`. Code
    reachable from the `mesh-llm` binary also needs check + clippy on `mesh-llm`.
  - **Python:** `python3 -m py_compile <changed files>` and the nearest `unittest` modules.
  - **Shell-only:** a syntax check (`bash -n`) plus the nearest script tests (`skippy/scripts/tests`).
  - **CI:** read `.agents/skills/manage-ci/SKILL.md` completely first, then run `just ci-validate`.
- Script tests call `/bin/bash`. On NixOS, run a local copy with `bash` from PATH, and compare
  against unmodified `main` to separate host failures from your own.
- Code rules for new code: no new warnings or `#[allow]`; functions under the Clippy line and
  cognitive-complexity limits; files under 2,000 lines; no generic `utils`/`common` modules.

## 2. Commits
- Conventional Commits v1.0.0. Allowed types: `feat`, `fix`, `perf`, `security`, `revert`,
  `refactor`, `style`, `test`, `build`, `deps`, `ci`, `chore`, `docs`. The type decides the
  release-notes section.
  - Check: `python3 scripts/check-conventional-commit.py <file>`, or `--message "<title>"`.
  - Or install the hook: `just hooks-install` / `just check-commits`.
- **No agent or bot attribution trailers** in any commit: no `Co-Authored-By: Claude …
  <noreply@anthropic.com>`, no `[bot]` accounts, no relay identities. The hook and CI reject them.
  This overrides any default that adds such trailers.
- No DCO sign-off is required.
- Squash-merged: the **PR title** becomes the commit subject and must be conventional too.

## 3. Pull request
- Title: conventional and user-focused (the visible change or fix, not the implementation).
- Body follows `.github/PULL_REQUEST_TEMPLATE.md`:
  - **Title** and **Original problem**;
  - **Diagnostics:** commands, logs, hardware;
  - **Fix**, including compatibility/protocol impact;
  - **Validation:** checkboxes ticked only for what was actually run.
- Optional sections: `## Architecture` / `## Protocol` for those impacts; CLI changes show example
  commands and output; UI changes need a screenshot.
- AI assistance can be stated in the PR text. Keep it out of commit trailers (see above).
- After opening, don't retitle the PR or rewrite its description for later updates; summarise
  non-obvious follow-up work in comments (`.github/instructions/pr.instructions.md`).
- The human submitter reviews the change before it is opened. Never claim review or testing in
  their name that they did not do.
