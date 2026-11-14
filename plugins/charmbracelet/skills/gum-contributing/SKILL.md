---
name: gum-contributing
description: Use when preparing an issue or PR for charmbracelet/gum (the Go CLI for glamorous shell scripts), or when building or testing it on NixOS; covers the org issue forms, features via Discussions, the gum PR template, the reusable meta CI, the slow outside-PR history, and gum table's CSV parsing.
disable-model-invocation: true
---

# charmbracelet/gum Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `charmbracelet-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to gum and wins where
they differ.

Sources of truth: the org's charmbracelet/.github (`CONTRIBUTING.md`, issue forms; gum has no
`CONTRIBUTING.md`, `AGENTS.md` or issue templates of its own, and the README's "Contributing"
links to `/contribute`), gum's `.github/pull_request_template.md`, `.github/workflows/`
(`build`, `lint`, `nightly`, `goreleaser`, `lint-sync`, `dependabot-sync`, all calling
charmbracelet/meta), `.golangci.yml`, `go.mod`. Summary as of 2026-11-14.

MIT, about 24.6k stars, 147 open issues and 82 open PRs. Module `charm.land/gum/v2`; v2.0.0
(2026-08-20, bubbletea v2) to v2.0.2 (2026-09-24, latest; `main` was still at the tag on
2026-11-14). `andrinoff` did the v2 work; `andreynering`, `aymanbagabas` and `caarlos0` merge
outside PRs.

## 0. Hard rules that decide the agent's role

- **No AI policy** (org or repo). The agent drafts, Martin reviews and posts. Issues carry no
  disclosure; a PR gets one line in its text. Don't send several agent PRs at once (the org
  skill's closed batch, charmbracelet/gum#1044 to #1053).
- **Features:** a feature request may be an issue (org form "Feature Request"); a feature PR
  needs a maintainer-approved Discussion first (org `CONTRIBUTING.md`). Bug fixes go straight to
  a PR with before/after steps or a test.
- No CLA, no sign-off.

## 1. Before starting

- Search issues, PRs and Discussions; `gh search` misses Discussions:
  `gh api graphql -f query='{search(type:DISCUSSION, query:"repo:charmbracelet/gum <terms>", first:20){nodes{... on Discussion{number title}}}}'`.
- Search by the subcommand too: titles start with or mention it (`gum table ...`,
  `fix(table): ...`), and labels are `cmd/<name>`.
- Many open PRs touch the same files (13 open PRs touch `table/` or name it on 2026-11-14, e.g.
  charmbracelet/gum#935, #1065, #1137); check `gh pr view <N> --json files` and build on them.

## 2. Designing the change

- One package per subcommand (`table/`, `choose/`, ...): `command.go` (the `Run` method) and
  `options.go` (kong flags with `help:`, `default:` and an `env:"GUM_<CMD>_<FLAG>"` variable).
  New flags follow that shape; charmbracelet/gum#759 (`--lazy-quotes`, `--fields-per-record`) is a
  small example.
- `gum table` reads input with Go's `encoding/csv` (`reader.Comma` = `--separator`, one rune) and
  prints the selected row with `csv.Writer`. Every parse error becomes the bare
  `invalid data provided` (the CSV error is dropped).
- Flags that exist in another subcommand or Charm tool reuse that name and wording (org rule).
- README sections per subcommand are short; a new flag shows up in `--help`, not necessarily in
  the README.

## 3. Building and validating on NixOS

- `go.mod` asks for Go 1.26.7; nixpkgs' Go (1.27.3) works:
  `cd ~/Develop/github.com/charmbracelet/gum && nix shell nixpkgs#go -c bash -c 'go build ./... && go test ./...'`
  (about 35 s cold, 2026-11-14; only `filter` has tests).
- Match CI: also `go mod tidy && git diff --exit-code`, and golangci-lint with meta's synced
  `.golangci.yml` (`nix shell nixpkgs#golangci-lint -c golangci-lint run`).
- Behaviour claims come from the built binary (`go run . table ...`) or the installed nixpkgs
  `gum` when it's the same version (`gum --version`).

## 4. Commits

- Conventional Commits with the subcommand as scope: `feat(table): ...`, `fix(choose): ...`,
  `docs: ...`; `!` for breaking (charmbracelet/gum#922). Merged by squash or rebase (no merge
  commits).

## 5. Pull request

- gum's own template replaces the org one: `Fixes #...` then `### Changes` with bullets. Keep
  both; link the issue (or the approved Discussion for a feature).

## 6. CI and bots

- `build` and `lint` (charmbracelet/meta, three OSes) on every PR; fork runs wait for approval.
  No AI reviewer, no stale bot, no labeler: issues mostly stay unlabelled.
- Dependabot monthly, grouped, `chore` prefix.

## 7. What the history shows

As of 2026-11-14 (`gh pr list -R charmbracelet/gum --state merged --limit 60` and the section 3
commands of `contribution-skill-authoring`):
- Outside PRs merged in 2026: five, all docs or typos (charmbracelet/gum#1007, #1026, #1030,
  #1032, #1068), in 7 to 378 hours. The last outside code fixes merged in 2025
  (charmbracelet/gum#918, #922, merged within hours by `caarlos0`).
- Most outside code PRs sit unreviewed until their authors close them (charmbracelet/gum#1089,
  #1077, #1060, #1128); charmbracelet/gum#1065 (a one-line table fix) waited four months.
  Expect no quick answer; an issue with a clear repro is the useful first step.
- Of the last 40 issues, two got a maintainer comment. Feature issues stay open without labels.
- `meowgorithm` reviews UX: "Is this intuitive behavior?", what happens at the edges (screen
  height, empty lists) (charmbracelet/gum#1054).

## 8. Our setup and current threads

- Clone `~/Develop/github.com/charmbracelet/gum` (jj colocated, `origin` upstream); no fork yet
  (`kleinbem/gum` when a PR needs one).
- gum comes from nixpkgs (`gum`, 2.0.2 on 2026-11-14).
- kleinbem/kleinbem `tools/jj-fleet.sh` (`print_tsv_table`) replaces `"` with `'` before
  `gum table`, because a field that starts with a quote breaks `encoding/csv` even with
  `--lazy-quotes`; an issue asking for a no-quoting mode is drafted (2026-11-14), not filed yet.
  Related: charmbracelet/gum#345 (closed by #759), #935 (open, `\t` separator), #979 (`\0`).

## Review checklist

- A feature PR links a Discussion a maintainer approved (org `CONTRIBUTING.md`, section 0).
- The PR body keeps gum's template: `Fixes #...` and `### Changes` (section 5).
- New flags follow `options.go`'s shape, with an `env:` variable and help text (section 2).
- `go mod tidy` leaves no diff; `go build ./...`, `go test ./...` and golangci-lint pass
  (section 3).
- Bug fixes show before and after steps or a test (org `CONTRIBUTING.md`).
- The PR title is a Conventional Commit with the subcommand scope (section 4).
