---
name: amp-acp-contributing
description: Use when preparing an issue or PR for tao12345666333/amp-acp (Agent Client Protocol adapter for the Amp coding agent; TypeScript built with Bun), or when building it with Nix; covers AGENTS.md (commands, docs update table), CI, the maintainer's style, the test suite's sandbox behaviour and the nixpkgs packaging angle.
disable-model-invocation: true
---

# tao12345666333/amp-acp Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `tao12345666333-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to amp-acp and wins
where they differ.

Sources of truth in the repo: `AGENTS.md` (commands, architecture, code style, "Update Protocol"),
`README.md`, `docs/`, `.github/workflows/{ci,release}.yml`, `.github/dependabot.yml`, `.agents/setup`.
No `CONTRIBUTING.md`, no PR or issue templates, no `CODEOWNERS`, no `SECURITY.md`. As of 2026-11-11
(main `f84bddf`, latest release v0.12.0 on 2026-11-01).

Apache-2.0, about 100 stars, one maintainer (`@tao12345666333`, Jintao Zhang) who merges
everything; much of main comes from Amp agent sessions (`ampagent` commits) and Dependabot.
Releases are frequent (v0.11.0 and v0.12.0 two days apart) and publish to npm.

## 0. Hard rules that decide the agent's role

- **No AI policy.** Nothing in the repo addresses AI use or attribution; the maintainer works with
  agents himself. So: the agent drafts, Martin reviews and posts; disclose AI help in one line.
- **No issue-first rule.** Outside contributors open fix PRs directly (#97–#100); issues with a
  precise problem/cause analysis get thanked and an invitation to open the PR (#61).

## 1. Before starting

- Search issues and PRs, open and closed:
  `gh search issues --repo tao12345666333/amp-acp --include-prs <terms>`.
- `AGENTS.md`'s "Update Protocol" table says which docs change with which kind of change
  (README for user-facing capability, the architecture list in `AGENTS.md`, `docs/mcp-passthrough.md`).

## 2. Designing the change

- Outside PRs that merged quickly share one shape: `## Problem`, then the change, with a
  deterministic fake-CLI test that reproduces the failure (#97: "A deterministic fake CLI
  reproduces this failure").
- Logging goes to `console.error` (stdout is the ACP stream); protocol errors throw
  `RequestError` from `@agentclientprotocol/sdk` (`AGENTS.md`, Code Style).

## 3. Building and validating on NixOS

- In `nix shell nixpkgs#bun`: `bun install --frozen-lockfile`, `bun run lint`, `bun test src/`,
  `bun run test:binary` (what `ci.yml` runs on ubuntu-latest). `test:e2e:live` needs an
  authenticated Amp CLI and spends Amp credits: only with Martin's OK.
- Timing: `src/amp-transport.test.ts` "delivers delayed initialization after steering an early
  cancellation" waits a fixed 50 ms for its fake CLI; under CPU load it fails (2026-11-11: idle
  0/10, with `stress-ng --cpu 24` 5/25 on v0.12.0 and 9/25 on `f84bddf`). The nixpkgs package
  skips it; report or fix upstream before relying on it.

## 4. Commits and 5. Pull request

- Conventional Commits titles (`fix:`, `feat:`, `deps:`, `chore:`); PRs land as one commit with
  `(#N)` in the title. No template: `## Problem`, `## Change`, tests run.
- Voice and disclosure as in `upstream-contributing`.

## 6. CI and bots

- `ci.yml`: Bun setup, `bun install --frozen-lockfile`, lint, unit tests, binary/ACP end-to-end
  tests. `release.yml` publishes to npm (OIDC trusted publishing, `docs/npm-oidc-trusted-publishing.md`).
- Dependabot opens dependency PRs. No AI reviewer, no stale bot.

## 7. What the history shows

Merge times of fork PRs (last 40 merged, 2026-11-11): 2, 2, 3, 8, 8, 8 h for a regular
contributor's fixes, 183–1086 h for older one-off PRs.
`gh pr list -R tao12345666333/amp-acp --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
Closed unmerged outside PRs are rare (#72, #103, both superseded by maintainer work).

## 8. Our setup and current threads

- Clone: `~/.cache/acp-bridges/amp-acp` (read-only reference; make a jj clone under
  `~/Develop/github.com/tao12345666333/amp-acp` with a `fork` remote before the first PR).
- nixpkgs: `amp-acp` (NixOS/nixpkgs#584499, Martin maintains): bundled `@ampcode/cli` binaries
  removed, `AMP_CLI_PATH` defaults to nixpkgs' `amp-cli`, one racy test skipped (section 3).
- Berd (block/berd) offers Amp through `amp-acp`; Berd's install recipe is `npm install -g amp-acp`.

## Review checklist

- The change follows the "Update Protocol" doc table (`AGENTS.md`).
- A fix comes with a deterministic fake-CLI test that fails without it (section 2).
- `bun run lint`, `bun test src/` and `bun run test:binary` pass locally (section 3).
- Conventional Commits title; body states Problem and Change (section 4).
