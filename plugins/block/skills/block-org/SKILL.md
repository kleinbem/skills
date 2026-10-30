---
name: block-org
description: >-
  Organization skill for the block GitHub organization (block/buzz, block/berd, block/buzz-app, block/aittributor, block/ai-rules, block/lhm, block/catch and other block/* repos): Block's org-wide rules (block/.github), the checks every block/* PR gets (DCO, Semgrep, zizmor), security reporting, governance, how outside contributions fare per repo, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# Contributing to Block's open source (block/*)

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ.

Sources of truth: `block/.github` (`CONTRIBUTING.md`, `GOVERNANCE.md`, `SECURITY.md`,
`CODE_OF_CONDUCT.md`) and each repo's own `CONTRIBUTING.md`/`AGENTS.md`. The org guide itself
says projects may add to or supersede it. Summary as of 2026-10-21.

**Not Block (anymore):** goose moved to `aaif-goose/goose` (Agentic AI Foundation), so this skill
doesn't apply to it; see `aaif-goose-org`. Mesh-LLM is its own organization. Block's other
public organizations (square, cashapp, tidal-music, bitcoindevkit, lightningdevkit,
proto-at-block, ...) are listed in `block/.github/profile/README.md`; this skill covers only
`github.com/block/*`.

## 0. Hard rules for every block/* PR

- **DCO sign-off on every commit.** The org guide requires it for Apache-licensed projects, and
  every block/* repo we touch is Apache-2.0. The `DCO Check` (Block's own `block-dco-check` app)
  runs on every PR in the org, including repos whose docs don't mention it (aittributor, ai-rules,
  lhm, catch); buzz-app's `AGENTS.md` requires it too. Use `Signed-off-by: Martin Kleinberger <email>` in the jj description, or
  `--signoff` on `git commit`/`rebase`/`cherry-pick`. The sign-off certifies Martin wrote or may
  submit the change: add it only after he has reviewed it.
- **CLA:** the org guide says a one-time CLA "may" be needed and asks first-time contributors to
  say they completed it, but publishes no CLA link and no check enforces one (as of 2026-10-21).
  Don't claim a CLA was signed. If a maintainer asks for it, ask them for the link and let Martin
  sign it.
- **Conventional Commits** (`type(scope): description`) for commits, and for the PR title on
  squash-merged repos. Some repos validate the title in CI ("Validate PR title": aittributor, lhm).
- **Security problems never go into a public issue, PR or Discord message.** Report privately via
  the repo's Security tab → "Report a vulnerability" (`block/.github/SECURITY.md`); escalation to
  `open-source-governance@block.xyz`. Block doesn't disclose by default and asks for no disclosure
  until a fix is approved. Martin files these himself.
- **AI use:** the org guide has no AI policy. Repos with an `AGENTS.md` address agents directly
  (buzz, berd, buzz-app, aittributor, ai-rules, lhm, codecrucible, review, catch); read it, and
  follow the repository skill's switches row in `upstream-contributing`.

## 1. Checks every block/* PR gets

Besides the repo's own CI, outside PRs get org-level checks:
- `DCO Check` (`block-dco-check` app): fails on any commit without a sign-off.
- `Semgrep OSS` and `zizmor` (GitHub Advanced Security): static analysis and GitHub Actions
  security. A workflow change must pass zizmor (pinned actions, no template injection, least
  permissions).

Fork PRs often wait for a maintainer to authorise CI before the repo's own jobs run; until then
only these org checks show. That is normal, not a failure (buzz: maintainers close and reopen).

## 2. Before starting

- Search issues and PRs first (`upstream-contributing`). The org guide adds: discuss substantial
  changes in an issue or on Block's open source Discord and wait
  for alignment before writing code; break large changes into small PRs.
  The Discord invite all Block docs give (`discord.gg/block-opensource`) is dead (Discord:
  "Unknown Invite", checked 2026-10-22); use the repo's own channel instead (buzz: see
  `buzz-contributing`).
- **Check the repo actually takes outside PRs.** berd closes them automatically
  (`close-external-prs.yml`); its contribution is an issue. Look for a `close-external-prs` or
  similar workflow and the repo's `CONTRIBUTING.md` before preparing a patch.
- Use the repo's issue forms (`.github/ISSUE_TEMPLATE/`); most block/* repos have them, and
  `gh issue create` doesn't apply forms, so Martin files them in the browser or the body follows
  the form's field order.
- Smaller repos (aittributor, lhm, ai-rules, agent-task-queue, braindump, codecrucible, review,
  trailblaze, catch) have no contribution guide beyond the README and `AGENTS.md`: the org guide is
  the baseline there, and the repo's CI (`.github/workflows/`) tells what must pass.

## 3. Governance and how outside work fares

- Maintainers have write access and merge; **one maintainer's opposition blocks a change** unless
  the Governance Committee overrides it (`GOVERNANCE.md`). Convince the maintainer in the issue,
  not by escalating.
- **Most Block staff keep their org membership private**, so GitHub labels them `CONTRIBUTOR`.
  When measuring "outside" PRs, check profiles and PR counts, not only `author_association`.
- Outside merges are rare (newest ≤300 merged PRs per repo, 2026-10-19, upper bounds): aittributor
  54% (13 of 24, two people), buzz-app about 0.3% (at most 3 of 1,154 merged PRs since 2026-09-10 from non-staff forks, 2026-10-23), buzz 6% (about four real outsiders), ai-rules 3%, berd
  none (every merged author has write access; it now closes outside PRs). Internal PRs often merge within hours; outside ones in weeks
  (buzz median about 8 weeks). Prefer a precise issue when a PR is unlikely to land.
- Recurring cross-repo issues worth one issue each (seen while packaging, 2026-10-20): Rust CLIs
  whose release never bumps `Cargo.toml` (aittributor 0.8.1 reports 0.4.0, lhm 0.14.1 reports
  0.1.0); repos without release tags (review, braindump, codecrucible). Drafts live in Obsidian
  (`Projects/Buzz nixpkgs/Drafts/`).

## 4. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| block/buzz | `buzz-contributing` | PRs accepted; DCO, agent reviewers, `buzz-review-completed` |
| block/berd | `berd-contributing` | **issues only**, outside PRs auto-closed |
| block/catch | `catch-contributing` | macOS Swift app, Berd's `catch` sidecar; idle since 2026-07, issue first |
| block/buzz-app | `buzz-app-contributing` | Buzz 1.0 beta; PRs accepted but outside merges rare; DCO, `Co-authored-by` for agents, code-owner approval, `buzz-review-completed` |
| block/aittributor, ai-rules, lhm, agent-task-queue, braindump, codecrucible, review, trailblaze | none yet | write the repository skill before our first contribution (`upstream-contributing`, "First contact") |

When a repository skill is added, update its row here and add its rows in `upstream-contributing`
(route and switches tables).
