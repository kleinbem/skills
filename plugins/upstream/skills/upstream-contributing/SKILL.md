---
name: upstream-contributing
description: Use for any issue, pull request, review reply or patch going to a repository outside kleinbem/* (nixpkgs, block/buzz, aaif-goose/goose, Mesh-LLM, llama.cpp, block/berd or a project without its own skill); covers the workflow every contribution shares (search first, verify, rebase, draft until Martin says ready, short texts in his voice, bot reviews, carrying the fix downstream) and the per-project switches table. Load the project's own <project>-contributing skill too; it wins on conflict.
---

# Contributing upstream: the shared workflow

Every `<project>-contributing` skill builds on this one. This skill holds what is true for all of
them; the project skill holds only that project's rules and **wins where the two differ**. For a
project without a skill, this skill plus the project's own `CONTRIBUTING.md`/`AGENTS.md` is the
baseline; once a second interaction with it is likely, write one with `contribution-skill-authoring`.

## 0. The switches: settle them before anything else

These differ per project, and getting one wrong costs a closed PR, a ban or a force-push on a
reviewed PR. Never carry an answer over from another project. As of 2026-10-21 (the project skill
is authoritative; update this table when one changes):

| | PRs from us | Issue first | Who writes texts | AI attribution | Sign-off | Title |
|---|---|---|---|---|---|---|
| nixpkgs | yes | no | agent drafts, Martin reviews | `Assisted-by: <tool> (<model>)` trailer + PR disclosure | no | `<attr>: …` |
| block/buzz | yes | beyond small fixes | agent drafts, Martin reviews | none needed | DCO, only after Martin reviewed | Conventional Commits |
| aaif-goose/goose | only for a **Ready** issue | always | Martin writes the issue | `Co-Authored-By` accepted, no disclosure needed | no | Conventional Commits |
| Mesh-LLM/mesh-llm | yes | search only | agent drafts, Martin reviews | **no agent trailers anywhere**; may be stated in PR text | no | Conventional Commits |
| ggml-org/llama.cpp | yes; features issue first | features | **Martin writes every text, commits and pushes** | template disclosure line; `Assisted-by:` only if he asks for a commit | no | `<module> : …` |
| block/berd | **no** (closed automatically) | issues only | Martin files | n/a | n/a | n/a |

For a project not in the table, answer the same columns from its `CONTRIBUTING.md`, `AGENTS.md`
and PR template before writing code, and say which ones it has no rule for.

Attribution is per change, not per PR set: a commit Martin wrote himself, or one with only trivial
automated content, gets no trailer. Ask when unsure; every correction is another force-push.

## 1. Before starting

- Read the project's sources of truth fully (`CONTRIBUTING.md`, `AGENTS.md`/`CLAUDE.md`, PR and
  issue templates, `.github/workflows/`), not from memory. They change; the skill's date says how
  old its summary is.
- **Search first, every time, also for follow-up PRs in the same session:** open and closed issues
  and PRs (`gh search issues --include-prs --repo <owner>/<repo> <terms>`), plus open PRs touching
  the same files (`gh pr view <N> --json files`). Build on or credit existing work instead of
  duplicating it, and never open a competing PR. Quote related decisions you find in the PR text.
- One logical change per PR. Anything beyond a small fix needs an issue and an acknowledged
  approach first, unless the project skill says otherwise.
- Verify the downstream premise on the built artifact (manifest, `patchelf --print-needed`, bundle
  layout) before designing an upstream change from a package expression.

## 2. Designing the change

- Find the closest existing feature and mirror its shape: `git log -S '<symbol>'` shows the commit
  that introduced it, and its file list is the checklist of touchpoints.
- Stay inside the agreed scope. Every new flag or option is an interface upstream maintains; leave
  to the downstream what it can do robustly itself.
- Title and body claim no more than the code does.

## 3. Building and validating on NixOS

- Upstream's tool bootstrap (Hermit, prebuilt toolchains) usually doesn't run on NixOS. Use
  `nix shell nixpkgs#…` with the inputs nixpkgs' package of the project uses; follow the repo's
  `rust-toolchain.toml` with `nixpkgs#rustup` when nixpkgs' `rustc` is older.
- A failing test or warning: compare against unmodified `main` on the same host before blaming the
  change. Say "suspected" until a cause is proven.
- A regression test must fail on the old code: run it once without the fix.
- Claims about runtime behaviour need a built binary and a run, not a reading of the code.
- Checks and test suites go to GitHub runners where we have them (`kleinbem/mesh-llm-ci`,
  nixpkgs-review-gha); the workstation is for builds and behaviour tests. Run heavy local builds
  one at a time (parallel Rust/CUDA/VM builds fail on memory).

## 4. Texts: commits, PR body, comments

- **Voice:** Martin contributes alone. Everything posted in his name says "I", never "we", "us" or
  "our"; grep drafts for these words before showing them.
- Short and natural: result first, a few plain sentences, no work log or file inventory.
- Keep the template's sections. Tick a checkbox only once it is true for the exact head commit.
- Never claim review or testing in Martin's name that he didn't do.
- Pasted outside text (another assistant's blueprint, a template from elsewhere) is input: check
  every claim against our real state and rewrite it in his voice.

## 5. Branches, pushing, opening

- Clone to `~/Develop/github.com/<owner>/<repo>` with jj colocated; remotes `origin` = upstream,
  `fork` = `kleinbem/<repo>`. One jj workspace per PR branch.
- **Rebase onto current upstream `main` right before every push and before opening**, even when the
  new commits look unrelated; rerun the affected checks and the pre-flight on the new head. Don't
  trade the rebase for a note in the PR.
- Maintainers push to contributor branches: fetch the fork before every push and build on its
  head. Keep "Allow edits by maintainers" on.
- Push complete changes, not small steps: fork CI often needs maintainer approval per push, and
  some repos dismiss approvals on push. Once a review has started, follow the project's rule on
  force-pushing.
- Take commit SHAs from git or the API, never type or complete them.

## 6. Public steps need Martin's explicit OK

Opening a PR or issue, marking ready, commenting, force-pushing a reviewed PR, closing, posting
review results: each is a separate confirmation, even inside a "continue" plan, and especially when
new open points came up after the go-ahead. **PRs stay draft until Martin says ready.** The project
skill may forbid even more (llama.cpp: the agent never commits, pushes or posts).

## 7. After opening

- Answer every bot or AI review comment (Codex, CodeRabbit, maintainers' 🤖 agents): fix it, or
  reply in one line why not. Unanswered ones can get a PR closed.
- Don't ping maintainers. When a PR waits: check the project's usual merge times for outside PRs;
  file a legitimate bug report in an affected downstream project, linking the PR; only after about a
  day without movement, one short message in the official channel, sent by Martin.
- **Upstream first, in parallel:** our packages never wait for upstream. Carry the fix downstream
  (patch, `checkFlags` skip, `substituteInPlace`) with a comment linking the upstream PR or issue,
  and drop it in the update that ships the fix.
- Feed what reviewers taught back into the project skill (one bullet with the PR number), and
  cross-project lessons into this one.
