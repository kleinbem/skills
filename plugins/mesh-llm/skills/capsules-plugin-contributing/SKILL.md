---
name: capsules-plugin-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/capsules-plugin (the capsules plugin for MeshLLM, with signed exchange records and the Evidence page) to follow its DCO, CI, changelog, commit and PR rules.
disable-model-invocation: true
---

# Mesh-LLM/capsules-plugin contribution workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/capsules-plugin and wins where they differ.

Sources of truth: `CONTRIBUTING.md`, `SECURITY.md`, `INSTALL.md`, `CHANGELOG.md`,
`.github/CODEOWNERS`, `.github/workflows/` (`ci`, `dco`, `e2e`, `neutrality`, `release`),
`docs/REAL-HOST-VERIFICATION.md`. No PR or issue templates, no `AGENTS.md`. The repo was
`Mesh-LLM/capsules` (and `capsule-emit-mesh` before 0.1.3); old links redirect. As of 2026-11-18:
one Rust crate (`crates/evidence-plugin`, binary `capsules`) plus a pnpm web UI (`web-ui/`),
a release every one to three days (v0.1.12 on 11-01 to v0.1.19 on 11-16).

## 0. Hard rules

- **DCO sign-off on every commit**, unlike the rest of the org: the `dco` workflow fails a PR
  with any non-merge commit lacking `Signed-off-by: Name <email>`. The sign-off is Martin's
  certification, so it goes on only after he reviewed the change (`jj describe` adding the
  trailer), never by the agent on its own.
- No agent trailers (org rule). The maintainers' agent marks its issue comments
  "(Ethan's agent)"; commits carry only the sign-off.
- "`main` is protected; every change needs a green CI run and one approving review"
  (`CONTRIBUTING.md`). CODEOWNERS: `@StevenMih @michaelneale @i386 @ndizazzo`.
- No key, token, ledger or data directory in the tree: `scripts/no-keys.sh` fails CI. The
  plugin id stays `capsules`.
- `vectors/` holds pinned external vectors: never edit them here (regenerate at the source,
  update `vectors/SOURCES.md` and `SHA256SUMS`).

## 1. Before starting

- Work is coordinated through issues: Ethan Zhang's agent posts "Started: …" / "Released: …"
  claims and a "How ack" plan; Steven Mih writes requirements and gates tags. Read the issue's
  last comments for a live claim before working on it, and name the issue in the PR.
- Related trackers worth knowing: #52 (depend on mesh-llm-plugin by published version, not git
  rev; open until mesh-llm publishes a crate with `announce_plugin_key`), #281 (host version and
  plugin catalog), #291 (the org's plugin CI standard, deliberately not applied here).
- Outside PRs are rare: #290 (Windows `.zip`, issue #288 first) merged by Steven in 14 h;
  #285 (Steven) closed in favour of Ethan's #286.

## 2. Designing the change

- Every change gets a `CHANGELOG.md` entry under `## Unreleased` (`### Changed`/`### Added`):
  one bullet with a bold first sentence saying what changed, issue and spec references in
  parentheses, then why. The release prep PR (`chore(release): prepare 0.1.N`) moves them.
- `Cargo.toml` explains each dependency in a comment (why it's here, why that version);
  keep that when you touch one. Dev-dependencies `rmcp` and `prost` must match what
  mesh-llm-plugin pins.
- mesh-llm-plugin comes from crates.io (`"0.80"`) with a `[patch.crates-io]` git rev on a
  mesh-llm release commit, because no published crate has `announce_plugin_key` (#52).
  Moving that rev pulls protocol changes: the stand-in hosts in `tests/*_interop.rs` build
  `InitializeRequest`/`RpcRequest`/`InvokeServiceRequest` literally and break on new fields.
- `plugin.toml` declares `min_host_version` (checked by `scripts/check-plugin-toml.sh`); the
  comment above it says which mesh-llm-plugin it builds on.
- `cargo update -p <crate>` can re-unify other crates: agent-action-capsule allows
  `evidence-request >=0.4,<0.8`, and an update dropped its locked 0.6.0 for 0.7.0. Keep the
  lock diff to the packages you meant and verify with `cargo metadata --locked`.
- Mutants (`gates/mutants.json`, `vectors/parity/referee/mutants.json`): a behaviour change in
  a checked path must keep each mutant failing its named tests.

## 3. Building and validating on NixOS

- Toolchain pinned in `ci.yml`/`release.yml` (`RUST_TOOLCHAIN`, 1.97.1 on 11-18); use it
  (`rustup` via `nix shell nixpkgs#rustup`, `cargo +1.97.1`), not nixpkgs' rustc.
- The full gate is heavy (mutants rebuild the crate once each; 25-45 min per platform): run it
  on GitHub, not the PC. `ci.yml` has `workflow_dispatch`, so the fork runs the exact CI:
  enable Actions on `kleinbem/capsules-plugin`, keep `release` and `neutrality` disabled
  there, push the branch, `gh workflow run ci.yml -R kleinbem/capsules-plugin --ref <branch>`.
  `e2e.yml` (two real nodes on a pinned mesh-llm release) dispatches the same way.
- `kleinbem/mesh-llm-ci` `run.yml` works here on `linux` only: its macOS and Windows setup
  calls mesh-llm's own composite actions, which this repo lacks.
- Local commands, from `CONTRIBUTING.md`: in `crates/evidence-plugin`, `cargo fmt --check`,
  `cargo clippy --locked --all-targets -- -D warnings`, `cargo test --locked --
  --test-threads=1` (interop tests share ports); `web-ui`: `pnpm typecheck && pnpm test &&
  pnpm build`.
- Compare a failure with an unmodified `main` run on the fork before blaming the change: on
  11-18 the e2e failed on main too (History page vs `history_card/2`, #303, fix in #304).
- Another host version for the e2e: a fork-only commit changing `MESH_LLM_VERSION`, `_ASSET`
  and `_SHA256` (the release asset's `digest`). On 0.78.1 main itself times out at the third
  node's corroboration, so run main beside the change.

## 4. Commits

- Conventional Commits with a scope: `feat(evidence-plugin): …`, `fix(web-ui): …`,
  `chore(release): …`, `test(e2e): …`, `chore(evidence-plugin): …` for dependency moves.
- Squash merges: the PR title becomes the commit, with `(#N)`; the squashed body lists each
  commit with its `Signed-off-by`.

## 5. Pull request

- No template. Ethan's bodies: `Closes #N`, then `## Original problem` and `## Fix` sections
  (#290). Martin's text stays in his voice: result first, why it's needed, test runs.
- Check runs on a PR: `ci` (plugin on linux-x86_64, linux-arm64, macos-arm64, a Windows
  subset; web UI on three; checks; reproducible package), `dco`, `neutrality`, CodeRabbit
  (skipped on recent PRs). The two-node e2e runs only with the `run-e2e` label (#305 asks to
  change that).

## 6. CI and bots

- `neutrality` runs on `pull_request_target` with a secret word list; on a fork PR a failure
  says only that it failed. A maintainer re-runs it to see the term.
- Releases: a maintainer pushes `vX.Y.Z`; `release.yml` builds four targets reproducibly,
  writes `SHA256SUMS` and attestations. Nothing reaches users until the catalog
  (`meshllm/plugin-catalog` on Hugging Face) pins the release (#281).

## 7. What the history shows

```bash
gh pr list -R Mesh-LLM/capsules-plugin --state merged --limit 40 --json author,mergedBy,createdAt,mergedAt \
  --jq '.[] | "\(.author.login)/\(.mergedBy.login): \((((.mergedAt|fromdate)-(.createdAt|fromdate))/3600|floor))h"'
```

- 2026-11-18: 39 of the last 40 merged PRs are Ethan's (his fork, mostly self-merged within
  2 h); #290 (Virgile-pct) merged by Steven after 14 h. No review comments in the API: the
  discussion happens in issues.

## 8. Our setup and current threads

- Clone `~/Develop/github.com/Mesh-LLM/capsules-plugin`, remotes `origin` (upstream) and `fork`
  (`kleinbem/capsules-plugin`).
- nixpkgs: `mesh-llmPlugins.capsules` (Martin maintains). Its `postPatch` lets mesh-llm-plugin's
  `build.rs` honour `PROTOC`; drop it with the first release pinning mesh-llm >= v0.79.0
  (Mesh-LLM/mesh-llm#2448). Prepared 11-18: branch `preflight-protoc` on the fork.

## Review checklist

- Every commit will carry Martin's `Signed-off-by` before the PR opens (section 0).
- `CHANGELOG.md` has an `Unreleased` bullet in the repo's style (section 2).
- Lock diff limited to the intended packages; `cargo metadata --locked` passes (section 2).
- Fork CI green on all four plugin rows and the web UI; failures compared with `main` (section 3).
- A mesh-llm-plugin move: the e2e's real-host run passes and `min_host_version` is still right.
- The PR names its issue and doesn't collide with a live "Started:" claim (section 1).
