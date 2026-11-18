---
name: openai-endpoint-plugin-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/openai-endpoint-plugin (the MeshLLM plugin that attaches an external OpenAI-compatible server) to follow its CI, compatibility-doc, commit and PR rules.
disable-model-invocation: true
---

# Mesh-LLM/openai-endpoint-plugin contribution workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/openai-endpoint-plugin and wins where they differ.

Sources of truth: `README.md` (Compatibility, Development checks, Release Archives),
`.github/workflows/ci.yml` and `release.yml`. No `CONTRIBUTING.md`, `AGENTS.md`, templates,
CODEOWNERS or DCO. The repo was `Mesh-LLM/openai-endpoint` (#4). As of 2026-11-18: one small
crate (`src/lib.rs`, `src/main.rs`, `tests/host_protocol.rs`), 5 PRs in total; maintainers
i386 and michaelneale.

## 0. Hard rules

- No agent trailers (org rule). No sign-off.
- The plugin id stays `openai-endpoint`: configs and package lookups use it (README).
- Plugin protocol must match the host: 0.1.2 was protocol 2 and fails on Mesh 0.76 (#3). A
  mesh-llm-plugin move that changes `PROTOCOL_VERSION` is a breaking release.

## 1. Before starting

- Two old open PRs touch the same files: #1 (i386, multiple endpoint URLs, draft) and #2
  (MahdiHedhli, bearer auth, `Cargo.toml` and `Cargo.lock`). Expect lock conflicts with #2.
- Plugin repos across the org share the `Mesh-LLM/example-plugin` workflow standard (#5,
  branch `standardize-ci-workflows`); CI changes follow it rather than diverge.

## 2. Designing the change

- mesh-llm-plugin is a git dependency on a mesh-llm **release commit** (`rev` of a `vX.Y.Z`
  tag; README: "using the SDK pinned to that Mesh release commit"). crates.io stops at 0.78.1.
- Moving it can need more lock moves than `cargo update -p mesh-llm-plugin` makes: v0.80.0's
  mesh-llm-plugin uses `rmcp::model::ServerConfig` but still says `rmcp = "3"`, and this lock
  had rmcp 3.3.0, which lacks it. Align such crates with mesh-llm's own `Cargo.lock` at that tag.
- Docs follow code: README's Compatibility section names the Mesh host version and protocol
  per adapter release; update it when the release that ships the change is prepared.

## 3. Building and validating on NixOS

- CI uses `dtolnay/rust-toolchain@stable`, unpinned: test with current stable
  (`nix shell nixpkgs#rustup`, `cargo +stable`).
- README's checks: `cargo build --release --locked`, `cargo test --locked`,
  `cargo clippy --all-targets --locked -- -D warnings`, plus `cargo fmt --all -- --check`.
- `ci.yml` runs on `pull_request` and pushes to `main` only (no `workflow_dispatch`). For the
  exact CI on all five runners, enable Actions on `kleinbem/openai-endpoint-plugin` (keep
  `Release` disabled there) and open a draft PR inside the fork; close it after.
- The `E2E openai-endpoint` job starts llama.cpp's `llama-server` (pinned tag) with SmolLM2-135M
  and runs `e2e_llama_server_answers_openai_requests`; it is Linux x86_64 only.

## 4. Commits

- Conventional Commits: `fix: …`, `ci: …`, `chore: …`, `build(deps): …`.
- Both merge styles were used: #3 squashed, #5 a merge commit. Write every commit message
  as if it lands on `main`.

## 5. Pull request

- No template. Free text in Martin's voice. #3 is the maintainers' own style: a `## Summary`
  with bullets, then the user workflow and validation.

## 6. CI and bots

- Checks: `Rust (ubuntu-latest | ubuntu-24.04-arm | macos-15 | windows-latest |
  windows-11-arm)` (fmt, clippy, test, build each) and `E2E openai-endpoint`.
- CodeRabbit reviews ready PRs (skips drafts); the Codex connector was installed on #2 but out
  of quota. Answer every finding (#2's author listed each one with a ✅).
- Releases: a maintainer pushes `vX.Y.Z` (older tags lack the `v`); `release.yml` builds and
  tests five targets and publishes the archives. No changelog file; the version lives in
  `Cargo.toml` and `plugin.toml` (#3 bumped both in "chore: prepare … release 0.2.0").

## 7. What the history shows

```bash
gh pr list -R Mesh-LLM/openai-endpoint-plugin --state all --limit 40 \
  --json number,author,state,mergedBy,createdAt,mergedAt \
  --jq '.[] | "#\(.number) \(.author.login) \(.state) by=\(.mergedBy.login // "-")"'
```

- 2026-11-18: #3 and #5 merged by their maintainer authors within 5 h; the two outside or
  draft PRs (#1, #2) have been open since July and August without a review. Expect a slow
  answer to outside PRs; the org's Discord is the channel to ask in.

## 8. Our setup and current threads

- Clone `~/Develop/github.com/Mesh-LLM/openai-endpoint-plugin`, remotes `origin` (upstream)
  and `fork` (`kleinbem/openai-endpoint-plugin`).
- nixpkgs: `mesh-llmPlugins.openai-endpoint` (Martin maintains). Its `postPatch` lets
  mesh-llm-plugin's `build.rs` honour `PROTOC`; drop it with the first release pinning mesh-llm
  >= v0.79.0 (Mesh-LLM/mesh-llm#2448). Prepared 11-18: branch `preflight-protoc` on the fork.

## Review checklist

- The mesh-llm-plugin `rev` is a release tag's commit, and `PROTOCOL_VERSION` didn't change, or
  the PR says it's breaking (sections 0, 2).
- Lock moves beyond the target crate are only those the new SDK needs (section 2).
- Fork CI green on all five Rust rows and the e2e (section 3).
- README's Compatibility section still true, or the PR says the release prep updates it.
