---
name: goose-contributing
description: Use when preparing, updating, or reviewing an issue or pull request to aaif-goose/goose (the goose AI agent: Rust crates, CLI, ACP server, Electron desktop) to follow its issues-first workflow, PR template, Conventional Commits titles and AI-review rules, and to build and test it on NixOS without Hermit.
---

# aaif-goose/goose Contribution Workflow

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (also `CLAUDE.md`), `.github/pull_request_template.md`,
`.github/ISSUE_TEMPLATE/` (bug report, feature request) and `.github/workflows/ci.yml`. Read them before acting; this
skill summarises them as of 2026-10-18 and adds what applies to our setup.

goose moved from `block/goose` to **`aaif-goose/goose`**; old links redirect. Discussion: the goose Discord
(https://discord.gg/n8R5VaWDAn, the same server as Mesh-LLM's `#mesh-llm`) and GitHub Discussions, but decisions
belong in the issue.

Local setup (kleinbem): clone `~/Develop/github.com/aaif-goose/goose` (jj, colocated), remotes `origin` = upstream and
`fork` = `kleinbem/goose`. Branches go to `fork`; PRs go from the fork to `aaif-goose/goose:main`.

## 0. Issues first (this decides everything else)

- Every piece of work starts as an issue on the [Goose Issues board](https://github.com/orgs/aaif-goose/projects/1):
  Inbox → Needs info → Accepted / design → **Ready** → In progress → Verification → Done.
- **No implementation and no PR until the issue is Ready.** PRs without a Ready issue are closed ("no correct issue").
  Exempt: dependency and release automation, urgent security fixes, work the core team asked for.
- **The human writes the issue.** CONTRIBUTING asks the reporter to write it themselves and understand it; an agent
  may research and draft notes, but Martin writes and posts it. Suggest a direction, not a detailed solution or code.
- Use the matching template (`bug_report.md` or `feature_request.md`) and set the issue type; `gh issue create` doesn't
  apply templates. Bugs: reproduction steps and a diagnostics report.
- The most valuable contribution is the design discussion between Accepted / design and Ready: context, constraints,
  trade-offs, and an agreed **verification plan**. Co-authorship is recognised for that work too.
- Feature requests describe a broadly useful problem; features that add complexity for little general benefit get
  declined.
- In October only, commenting `.take` on an issue assigns it to you (`take.yml`).
- Before searching for a fix, search issues and PRs: `gh search issues --repo aaif-goose/goose <terms>`.

## 1. Designing the change

Follow `AGENTS.md`; reviewers and the AI reviewer check against it:
- Stay inside the issue's agreed scope; a material design change goes back to the issue first.
- `anyhow::Result` for errors; no error context that only repeats the error.
- No comments that restate the code; comment only the why of non-obvious logic.
- Don't make things optional that don't need to be; booleans default to false instead of `Option<bool>`; no overly
  defensive code.
- Providers implement the `Provider` trait (`providers/base.rs`); MCP extensions live in `crates/goose-mcp/`.
- Desktop UI (`ui/desktop`): use ACP SDK types or local `src/types/*`, never the generated OpenAPI client in
  `ui/desktop/src/api`. `ui/text` is deprecated.
- GDK crates (the `release = true`, `version_group = "gdk"` set in `release-plz.toml`) are published APIs; `goose` and
  `goose-cli` have no stable public API.
- Don't add third-party servers to `documentation/static/servers.json` (retired in favour of the MCP Registry).
  LLM services publish a custom-provider JSON file instead of a built-in provider.
- Tests go into `tests/` folders (e.g. `crates/goose/tests/`). New features also update `goose-self-test.yaml` and run
  `goose run --recipe goose-self-test.yaml`.
- Watch for the agent failure modes CONTRIBUTING lists: trivial tests, widened or optional types, swallowed errors,
  bloat, redundant logging.

## 2. Building and testing on NixOS

Upstream uses Hermit (`source bin/activate-hermit`), which downloads prebuilt tools that usually don't run on NixOS.
Use Nix instead:
- Rust: the repo pins a toolchain in `rust-toolchain.toml` (1.99.0 on 2026-10-18), newer than nixpkgs' `rustc`. Use
  `nix shell nixpkgs#rustup` (nixpkgs' rustup patches the toolchains it downloads), which follows the pin.
- Build inputs, as nixpkgs' `goose-cli` package uses them: `cmake pkg-config protobuf` and libclang for bindgen
  (`LIBCLANG_PATH`), plus `dbus openssl` and on Linux `libxcb`. The V8 dependency downloads a prebuilt archive at
  build time unless `RUSTY_V8_ARCHIVE` points at one (nixpkgs: `librusty_v8`).
- Tests need `GOOSE_DISABLE_KEYRING=1` (no keyring prompts) and, for isolation, `GOOSE_PATH_ROOT=$(mktemp -d)`.
  nixpkgs' `goose-cli` `checkFlags` lists tests that need a keyring, the network or race on process-global state;
  compare against unmodified `main` before blaming a change.
- Checks CI runs (`ci.yml`): `cargo fmt --check`, build and tests, `cargo clippy --all-targets -- -D warnings`, a lean
  ACP binary size budget, the GDK crates on `wasm32`, and the ACP npm packages. Run per changed crate:
  `cargo fmt`, `cargo clippy -p <crate> --all-targets -- -D warnings`, `GOOSE_DISABLE_KEYRING=1 cargo test -p <crate>`.
- UI: `cd ui/desktop && pnpm run typecheck && pnpm test` (nixpkgs' `nodejs` and `pnpm`).
- Claims about behaviour need a built binary (`cargo run -p goose-cli -- …`), not only reading the code.

## 3. Commits and PR title

- Conventional Commits for the **PR title** (squash merges use it), e.g. `fix(acp): …`, `feat(desktop): …`.
- No DCO or sign-off.
- AI use needs no disclosure ("you are contributing to an agent"); `Co-Authored-By: Claude …` trailers are accepted
  (seen on merged fork PRs). Martin reviews every change before it is opened: he is responsible for the code.

## 4. Pull request

- Template: `Fixes: #<Ready issue>`, `## Summary`, `### Testing` (how the issue's **verification plan** was carried
  out), `### Related Issues`, screenshots for UX changes.
- Write for humans: lead with the conclusion, short, no work log, one summary instead of many incremental comments.
- **Voice:** the submitter contributes alone. Issues, PR bodies and comments posted in their
  name say "I", never "we", "us" or "our"; check drafts for these words before showing them.
- Don't open many PRs at once: submit in order of preference and wait for them to land.
- An AI reviewer (Codex) comments on PRs. **Answer every comment**: fix it, or reply in one line why it isn't an
  issue. Unanswered AI review comments can get the PR closed.
- Rebase onto current `main` before opening and before every push; keep "Allow edits by maintainers" on.
- Merge times for fork PRs vary from hours to about a week.

## 5. For nixpkgs

nixpkgs packages goose as `goose-cli` (maintainers asiantuntija, cloudripper, thardin). A packaging problem fixed
upstream helps them; mention the nixpkgs angle in the issue when it applies.
