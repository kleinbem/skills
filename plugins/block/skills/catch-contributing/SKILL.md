---
name: catch-contributing
description: Use when preparing an issue or PR for block/catch (Block's macOS SwiftUI shortcut for finding and starting Goose agent sessions, embedded in Berd as its `catch` sidecar), or when building Catch with nixpkgs' Swift; covers the repo's small rule set (AGENTS.md, the old bug template, CI on macos-26), what its history shows, and the nixpkgs sandbox facts.
disable-model-invocation: true
---

# block/catch Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `block-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to block/catch and wins where they differ.

Sources of truth in the repo: `AGENTS.md`, `README.md`, `docs/focus-hiding.md` (a spec), `GOVERNANCE.md` (a link to
Block's), `CODEOWNERS`, `.github/ISSUE_TEMPLATE/{bug-report.md,config.yml}`, `.github/workflows/{build,release}.yml`,
`script/{build_and_run,package_release}.sh`. No `CONTRIBUTING.md` and no PR template: the org guide (`block-org`) is the
baseline. Summary as of 2026-10-30.

Catch is Apache-2.0, a SwiftPM package (`swift-tools-version: 6.2`, `.macOS(.v26)`, no outside dependencies, about
4,000 lines): the library `CatchKit` and the executable `Catch`. It runs standalone (starts `goose serve` itself) or
embedded in a host that passes `GOOSE_SERVE_URL` (Berd, for its global shortcut; Berd's
`scripts/prepare-catch-sidecar.sh` pins `CATCH_VERSION=0.5.1`). Lead: `@square-tomb` (`CODEOWNERS`); commits come from
Tom Brow and Kalvin Chau. Latest tag v0.5.1 (2026-07-08) is also `main`: the repo has been idle since.

## 0. Hard rules that decide the agent's role

- **No AI policy and no contribution guide in the repo.** `AGENTS.md` speaks to agents about how to change the code
  (specs, SwiftUI first, test builds), not about who may contribute. So: the agent drafts, Martin reviews and files;
  no attribution rule exists (state it in the PR text if a PR ever goes there).
- **PRs aren't auto-closed** (no `close-external-prs` workflow, unlike Berd), but no outside PR or issue exists yet and
  the repo is idle with one lead. **Issue first**, a PR only after the lead responds (the org guide asks to align on
  substantial changes first).
- DCO sign-off on PR commits (`block-org`); the `DCO Check` runs on Catch's PRs (#4, #5).

## 1. Filing an issue

- Only one template: `bug-report.md`, Block's old Markdown template (title `[Bug] <title>`, label `bug`, sections
  "Describe the bug", "To Reproduce", "Expected behavior", "Supporting Material", "Environment", "Additional context").
  Keep those headings in that order. Blank issues are allowed (`config.yml` doesn't disable them); use one for
  requests that aren't bugs, with the same plain structure.
- `config.yml` points questions at Block's Discord; that invite is dead (`block-org`).
- Search first: `gh search issues --repo block/catch --include-prs <terms>`. As of 2026-10-30 the only issue is
  Renovate's dashboard (#1).
- Name the version (`v0.5.1`, = `main`) and how it was built (Xcode, or nixpkgs' open-source toolchain). Catch
  is mostly used embedded in Berd; say which mode the bug is in.

## 2. Designing a change (AGENTS.md)

- "Honor checked-in project specs": read `docs/focus-hiding.md` before touching panel focus or hiding, keep it updated,
  and call out an intentional spec change.
- Idiomatic modern SwiftUI (`Observable`); AppKit only where SwiftUI lacks the behaviour, with a short comment why.
- UI changes get a test build (`./script/build_and_run.sh --test`, or `--test-manual` with a `CATCH_GLOBAL_HOTKEY`
  for a person to try). We have no Mac: an autonomous `--test` launch can run on a GitHub macOS runner, but nobody can
  try a `--test-manual` build, so a UI change from us can't get the manual check `AGENTS.md` asks for; say so.

## 3. Building and validating

- macOS only; nothing builds on Linux. Upstream CI (`build.yml`): `swift build` and `swift test` on `macos-26`
  with Xcode 26. We build on GitHub's macOS runners (nixpkgs-review-gha, `aarch64-darwin`).
- nixpkgs package `block-catch` (the attribute `catch` is a removal alias). With nixpkgs' Swift 6.3.3 and
  `apple-sdk_26` it builds and all 73 tests pass, with these Nix-side settings (2026-10-30):
  - `#Preview` needs Xcode's `PreviewsMacros` plugin; the open-source toolchain has none, so the build fails
    (`MainView.swift`). The package's `postPatch` turns the `#Preview("Main View") {` line into a plain
    `private func`. Upstream-able: it breaks any build without Xcode.
  - In the build sandbox `URLComponents.host` is nil for every URL unless `/usr/share/icu` is readable
    (`sandboxProfile`); the embedded-server tests fail otherwise. Unsandboxed it parses fine: not a Catch bug.
  - `FloatingPanelTests` create an `NSPanel`: AppKit needs
    `/System/Library/CoreServices/SystemAppearance.bundle` readable, or it throws "required built-in appearance
    SystemAppearance not found".
  - `BuildScriptTests` compare the script's `$HOME` with `NSHomeDirectory()`, which follows `CFFIXED_USER_HOME`.
  - `swift test` in debug signs with the get-task-allow entitlement through `codesign`:
    `--disable-get-task-allow-entitlement`.
- Standalone Catch looks for goose only in `GOOSE_BINARY` and Homebrew paths, and starts it with a fixed Homebrew
  `PATH` (`GooseServeClient.swift`, `startServer`); the nixpkgs package sets `GOOSE_BINARY`.

## 4. Commits and PRs

- Conventional Commits in the history (`fix: update catch for berd sessions`, `ci: bump runs-on to mac-26`);
  merge commits, no squash rule. No PR template.

## 5. CI and bots

- `Swift build and test` (github-actions) plus the org checks `DCO Check`, `Semgrep OSS`, `zizmor` (#4, #5).
- `release.yml` builds an unsigned universal release (DMG and the `catch-v<version>-macos-universal.tar.gz` sidecar
  tarball Berd downloads) on a tag or dispatch.
- Renovate keeps the dependency dashboard (#1).

## 6. What the history shows

As of 2026-10-30: 4 PRs, all from Block staff (#2 initial import, #3 build check, #4 Berd session deep links, #5
`macos-26`), merged within a day; no outside PR or issue, so no measured response time. Rerun:

```bash
gh pr list -R block/catch --state all -L 50 --json number,author,isCrossRepository,createdAt,mergedAt
gh issue list -R block/catch --state all -L 50 --json number,author,comments,createdAt
```

## 7. Our setup

- Clone `~/Develop/github.com/block/catch` (read-only so far, no fork).
- nixpkgs: `block-catch` on `kleinbem/nixpkgs` branch `block-catch-init`, the base of the Berd stack
  (NixOS/nixpkgs#580616 uses it for Berd on macOS). Berd's own skill: `berd-contributing`.

## Review checklist

- An issue names the mode (standalone or embedded in Berd) and the toolchain (Xcode or open source).
- The bug template's headings are kept, in order, with `[Bug]` in the title.
- A change to panel focus or hiding checks and updates `docs/focus-hiding.md` (`AGENTS.md`).
- No PR before the lead has answered the issue (section 0).
