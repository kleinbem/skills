---
name: swift-rs-contributing
description: Use when preparing an issue or PR for Brendonovich/swift-rs (call Swift from Rust; `SwiftLinker` builds a Swift package from build.rs with `swift build`), or when packaging a Rust app that uses it with Nix; covers the repo's (absent) contribution files, CI, the maintainer's merge pattern, the Xcode 27 PR backlog and the nixpkgs Swift-macros angle.
disable-model-invocation: true
---

# Brendonovich/swift-rs Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `brendonovich-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to swift-rs and wins
where they differ.

Sources of truth in the repo: `README.md` (setup, `SwiftLinker`, limitations, the dual-license
contribution clause), `.github/workflows/main.yaml`, `src-rs/build.rs`. No `CONTRIBUTING.md`, no
`AGENTS.md`, no PR or issue templates, no `CODEOWNERS`, no `SECURITY.md`. As of 2026-11-25 (main
`207e4bf`, crate 1.0.9 on 2026-10-10; GitHub releases stop at 1.0.7, later versions are only tags
and crates.io).

MIT OR Apache-2.0, about 340 stars, one maintainer (`@Brendonovich`, Brendan Allan) who merged
all of the last 20 PRs. Used through Tauri apps, so most traffic is macOS/iOS build breakage.

## 0. Hard rules that decide the agent's role

- **No AI policy.** Nothing in the repo addresses AI use or attribution. So: the agent drafts,
  Martin reviews and posts; no disclosure (not required).
- **No issue-first rule.** Outside fixes arrive as PRs directly (#76, #77, #85); feature-sized
  questions sit as issues, often without an answer (#62, #71).

## 1. Before starting

- Search issues and PRs, open and closed:
  `gh search issues --repo Brendonovich/swift-rs --include-prs <terms>`.
- Check the open PRs first: as of 2026-11-25 eleven are open, several for the same Xcode 27
  failures (#80, #82, #86) and one that adds a single `swift build` argument (#75, `-F` framework
  search path). A new request touching `SwiftLinker::link()` should reference the overlapping ones.

## 2. Designing the change

- All build logic is `src-rs/build.rs`: `SwiftLinker::link()` runs `swift build` with a fixed
  argument list (`--sdk`, `-c`, `--arch` or `--triple`, `--build-path`, `-Xswiftc -sdk/-target`).
  Consumers can't add arguments; the only environment knob is `SWIFT_RS_CLANG` (which clang to ask
  for the compiler-rt path).
- Behaviour changes for new Xcode versions are gated on `xcode_major_version()` so older
  toolchains keep the old path (#76, #77).
- PR bodies that merged quickly state the failure with exact error strings, the cause, and what
  stays unchanged (#85: "Nothing else changes").

## 3. Building and validating on NixOS

- Builds need a macOS host (`swift build`, `xcrun`); on NixOS only `cargo fmt --check` and
  `cargo clippy` of the non-`build` parts run. Real validation goes to a macOS GitHub runner,
  e.g. the nixpkgs package that uses it (`berd` on aarch64-darwin via nixpkgs-review-gha).
- CI (`main.yaml`): macos-latest, Rust stable and beta: `cargo run` in `example/`,
  `cargo test --features build` with `TEST_SWIFT_RS=true`, `cargo fmt --all -- --check`,
  `cargo clippy -- -D warnings`. Its `push` trigger names `master` while the branch is `main`.

## 4. Commits and 5. Pull request

- No title convention: free-form, some Conventional Commits (`fix(build): …`). Merge commits, not
  squash; releases are `chore: release x.y.z` commits by the maintainer.
- No template: problem with exact errors, change, what stays the same, how it was tested.

## 6. CI and bots

- One workflow (above). No bots, no AI reviewer, no stale bot.

## 7. What the history shows

Merge times of fork PRs (last 40 merged, 2026-11-25): half within 6 h, the rest from 1 day to
half a year (0,0,0,0,0,0,1,1,1,1,2,2,6,6,6,6,8,16,33,37,43,46,64,74,104,210,935,1270,1409,4596).
The maintainer reviews in bursts (2026-08-17, 2026-10-10) and merges what is ready then.
`gh pr list -R Brendonovich/swift-rs --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
Closed unmerged outside PRs are rare and were superseded or out of scope (#5, #22, #46, #65).
Issues: most get one or no reply.

## 8. Our setup and current threads

- No clone or fork yet; make a jj clone under `~/Develop/github.com/Brendonovich/swift-rs` with
  a `fork` remote before the first PR.
- nixpkgs: Berd (NixOS/nixpkgs#580616) vendors swift-rs 1.0.7 and patches `build.rs` on Darwin
  (`pkgs/by-name/be/berd/add-plugin-path-for-swift-macros.patch`, by `@reckenrode`): it adds
  `-Xswiftc -external-plugin-path <open-apple-macros>` and `--disable-sandbox` to `swift build`,
  because nixpkgs' Swift has no Xcode macro plugins (SwiftUI's `@State` etc.). The real fix is a
  way to pass such arguments through swift-rs.

## Review checklist

- The request or PR references the overlapping open PRs (#75 and the Xcode 27 ones) (section 1).
- New behaviour is opt-in or version-gated so existing users keep their build (section 2).
- Claims about macOS builds come from a macOS run, not from reading `build.rs` (section 3).
- The body names exact error strings and what stays unchanged (section 2).
