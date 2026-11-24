---
name: comin-contributing
description: Use when preparing an issue or PR for nlewo/comin (GitOps deployment for NixOS and nix-darwin, written in Go), or when building and testing it with Nix; covers the maintainer's stance on SSH signature code and go-git bumps, CI (go test, nix flake check), vendorHash, commit and PR style, and how fork PRs fare.
disable-model-invocation: true
---

# nlewo/comin Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `nlewo-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to comin and wins
where they differ.

Sources of truth in the repo: `readme.md`, `docs/contribute.md` (only how to run comin locally),
`docs/{design,howtos,features,release-notes}.md`, `.github/workflows/{go,nix}.yml`, `flake.nix`,
`nix/{package,go-test,lint}.nix`. No `CONTRIBUTING.md`, no `AGENTS.md`, no PR or issue
templates, no `CODEOWNERS`, no Dependabot or Renovate. As of 2026-11-24 (main `ccce0c58`, latest
release v0.14.0).

MIT, about 1200 stars, one maintainer (`@nlewo`, Antoine Eiche) who reviews and merges
everything, with limited bandwidth: he closes stale PRs to clean his backlog (#221) and says so
when he can't review (#216).

## 0. Hard rules that decide the agent's role

- **No AI policy.** Nothing in the repo addresses AI use or attribution. A Claude-generated PR
  (#147, "Claude/add system manager guide") got a friendly "looks like claude took some unwanted
  initiatives": keep agent output tight and in scope. The agent drafts, Martin reviews and posts;
  one disclosure line in the PR.
- **No issue-first rule.** Outside contributors open PRs directly; most merged fixes had no issue.
- **SSH signature code:** the maintainer doesn't want to maintain SSH signature verification in
  comin. He waits for go-git's verifier plugins (go-git/x#13, built on go-git/go-git#2235) to
  replace comin's own code, and left #216 (jj `change-id` fix in comin's code) unreviewed for
  that reason. He said: "Once supported by go-git, i will however have no issue at all in bumping
  our go-git version". So signature fixes go through go-git, and a go-git bump is welcome.

## 1. Before starting

- Search open PRs too: about 20 are open, many old (#35, #41 from 2023). An existing PR for the
  same fix exists more often than not (#216 for jj signatures).
  `gh search issues --repo nlewo/comin --include-prs <terms>`.
- Check the maintainer's own open branches (`gh pr list -R nlewo/comin --author nlewo`): he
  refactors core parts (fetcher, builder, deployer) in long-running PRs.

## 2. Designing the change

- Go code in `internal/` (`repository`, `builder`, `deployer`, `manager`, `fetcher`, ...),
  public API in `pkg/` (protobuf, client, tui), CLI in `cmd/`, Nix module in `nix/module.nix`.
- A Nix module option change needs the generated docs: run
  `nix run .#generate-module-options` (CI's `module-options-doc` check compares
  `docs/generated-module-options.md`; commits "Regenerate options doc").
- User-visible features get a line in `docs/release-notes.md` (Keep a Changelog format) at
  release time; the maintainer writes it, contributors don't need to.
- Changing `go.mod`/`go.sum` changes `vendorHash` in `nix/package.nix`: update it in the same
  commit, or `nix flake check` fails.

## 3. Building and validating on NixOS

- `nix develop` has go, gopls, golangci-lint, protobuf. CI runs:
  - `go.yml`: `go build -v ./...` and `go test -race -v ./...` (Go 1.22 setup on ubuntu-latest).
  - `nix.yml`: `nix flake check` (package build, `golangci-lint` via `nix/lint.nix`, nixfmt via
    treefmt, module options doc).
- Run both locally before a PR: `go test -race ./...` in `nix develop`, then `nix flake check`.
- `nix/go-test.nix` runs the Go tests in the Nix sandbox (`doCheck`); it is not in `checks`.
- Test against our hosts: point nix-config's `comin` input at the branch
  (`--override-input comin path:../../nlewo/comin`) and build a host's toplevel.

## 4. Commits and 5. Pull request

- Merge commits ("Merge pull request #N from ..."), so each commit lands as written.
- Subject: `<component>: <lowercase imperative>` (`builder: report failed builds as failed to
  the post-build command`, `nix: write ...`, `repository: fix ...`); plain sentences also appear
  (`Add default NixOS module`). No Conventional Commits types needed.
- No template. Bodies that merged fast: Problem (how it happens, expected vs actual), Cause,
  Fix, how it was tested (#233, merged in 4 h).

## 6. CI and bots

- Checks on PRs: `build` (go.yml) and `tests` (nix.yml), both GitHub Actions; fork runs may need
  the maintainer's approval. No branch protection rules visible, no AI reviewer, no stale bot.

## 7. What the history shows

- Merge times of fork PRs (last 40 merged, 2026-11-24), hours: 4, 4, 10, 15, 24, 25, 40, 57,
  57, 67, 68, 100, 137, 141, 142, 202, 210, 217, 418, 748.
  `gh pr list -R nlewo/comin --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
- Closed unmerged fork PRs are rare: #221 (backlog cleanup, reopen offered), #147 (agent PR).
- Review comments are few and concrete: races, shared helpers, "could be moved out of this PR to
  not block it" (#199).
- Dependency bumps are rare and manual (go.mod history: Go 1.24 in 2025-11, go-git unchanged at
  v5.11.0 since 2023).

## 8. Our setup and current threads

- Fleet: comin deploys nasbook, mac-mini, hass-pi, core-pi and orin-nano from nix-config's
  `production` branch; signature check via `sshAllowedSignersPath`.
- Known bug (2026-11-24): comin rejects commits made by jj, because go-git v5.11.0 drops the
  `change-id` header when re-encoding the commit for verification. go-git v5.16+ keeps extra
  headers (go-git/go-git#1578). Affects our `testing-<host>` canaries; production commits are
  GitHub squashes without `change-id`. Open fix in comin's own code: #216 (stalled, see section 0).
- No clone or fork yet: clone to `~/Develop/github.com/nlewo/comin` with jj, remotes `origin`
  and `fork` (`kleinbem/comin`).

## Review checklist

- Search found #216 and any other open PR for the same thing; the PR text links them (section 1).
- `vendorHash` in `nix/package.nix` matches the new `go.sum` (section 2).
- `go test -race ./...` and `nix flake check` pass on the head (section 3).
- Module option changes come with regenerated `docs/generated-module-options.md` (section 2).
- Subject `<component>: ...`, body with problem, cause, fix and tests (section 4).
- The change doesn't add SSH-signature code to comin (section 0).
