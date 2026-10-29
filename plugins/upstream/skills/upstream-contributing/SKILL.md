---
name: upstream-contributing
description: Load before any issue, pull request, review reply, comment or patch for a repository outside kleinbem/* (nixpkgs and other NixOS repos, block/*, aaif-goose/goose, Mesh-LLM, ggml-org/llama.cpp or any other project). It routes to the organization and repository skills (read them as files), runs the first-contact procedure for a new repo, and holds the shared workflow (search first, verify, rebase, draft until Martin says ready, an independent review before ready, his voice, bot reviews, refresh the repo skill before opening a PR, carry fixes downstream).
---

# Contributing upstream: the router and the shared workflow

Three layers; the more specific one wins where they differ:
1. **This skill:** what every upstream contribution shares. The only one always loaded.
2. **The organization skill** `<org>-org`: what holds for every repo of that GitHub organization
   (org policies, org-wide checks, security reporting, governance, channels, its repo table).
3. **The repository skill** `<repo>-contributing`: that repo's rules, reviewers and history.

Organization and repository skills are **manual skills** (`disable-model-invocation: true`): they
are not in the context until needed. Martin can run them as `/<name>`; an agent **reads them as
files** with its file-read tool: `~/.agents/skills/<name>/SKILL.md` (every agent; Claude Code also
has `~/.claude/skills/<name>/SKILL.md`). Don't call the Skill tool for them: Claude Code blocks
model invocation of manual skills.

## Route: which files to read

| Organization | Org skill | Repository skills |
|---|---|---|
| NixOS | `nixos-org` | `nixpkgs-contributing`, `nixpkgs-maintaining` (maintainer work), `nixpkgs-packaging` (a new app end to end) |
| block | `block-org` | `buzz-contributing`, `buzz-app-contributing`, `berd-contributing` |
| ggml-org | `ggml-org` | `llama-cpp-contributing` |
| aaif-goose | `aaif-goose-org` | `goose-contributing` |
| Mesh-LLM | `mesh-llm-org` | `mesh-llm-contributing` |
| Arch Linux (not on GitHub) | `archlinux-org` | `aur-contributing` |

Read this skill, then the org skill, then the repo skill, before the first edit. The org skill's
repo table says which repos have a skill.

## First contact: a repo or organization without a skill

**No issue, PR or comment goes to a repo before it has a repository skill.** Follow
`contribution-skill-authoring` (read `~/.agents/skills/contribution-skill-authoring/SKILL.md`):
1. **Organization:** read or write the org skill (the org's `.github` repo, org-wide checks on a
   recent PR, security and governance). An organization always gets an org skill, even when we
   touch only one of its repos.
2. **Repository:** its own `CONTRIBUTING.md`, `AGENTS.md`, templates and workflows.
3. **History:** scan its merged and closed PRs and review comments for the lessons.
4. **Write the repository skill**, add its rows (org repo table, the route table above, the
   switches table below), merge it into kleinbem/skills. Then start the contribution.

## 0. The switches: settle them before anything else

These differ per project, and getting one wrong costs a closed PR, a ban or a force-push on a
reviewed PR. Never carry an answer over from another project. As of 2026-10-22 (the repository skill
is authoritative; update this table when one changes):

| | PRs from us | Issue first | Who writes texts | AI attribution | Sign-off | Title |
|---|---|---|---|---|---|---|
| nixpkgs | yes | no | agent drafts, Martin reviews | `Assisted-by: <tool> (<model>)` trailer + PR disclosure | no | `<attr>: …` |
| block/buzz | yes | beyond small fixes | agent drafts, Martin reviews | none needed | DCO, only after Martin reviewed | Conventional Commits |
| block/buzz-app | yes, rarely merged; fork CI needs approval | no; scope checkpoint in the PR | agent drafts, Martin reviews | `Co-authored-by:` trailer for the agent | DCO, only after Martin reviewed | free-form (Conventional Commits common), squash |
| aaif-goose/goose | only for a **Ready** issue | always | Martin writes the issue | `Co-Authored-By` accepted, no disclosure needed | no | Conventional Commits |
| Mesh-LLM/mesh-llm | yes | search only | agent drafts, Martin reviews | **no agent trailers anywhere**; may be stated in PR text | no | Conventional Commits |
| ggml-org/llama.cpp | yes; features issue first | features | **Martin writes every text, commits and pushes** | template disclosure line; `Assisted-by:` only if he asks for a commit | no | `<module> : …` |
| block/berd | **no** (closed automatically) | issues only | Martin files | n/a | n/a | n/a |
| AUR | as (co-)maintainer; others' packages via comment | no | agent drafts PKGBUILDs; **Martin pushes** and writes comments/emails | no policy; no agent trailers (history is permanent) | no | free-form (`update: x.y.z`) |

A repo not in the table has no repository skill yet: run the first-contact procedure above, which
adds its row.

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
  Search for the component noun in titles (`sidecars in:title`) and for the fix's words, not only
  the symptom's: block/buzz#8540 was filed although #3069 ("prefer bundled sidecars in releases")
  already fixed it, because the searches used the symptom's terms ("sidecar placeholder",
  `CARGO_MANIFEST_DIR`).
- One logical change per PR. Anything beyond a small fix needs an issue and an acknowledged
  approach first, unless the repository skill says otherwise.
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
- Write references to other repos in full (`Owner/repo#123`): a bare `#123` links into the
  repo the text is posted in (a nixpkgs body's `#2492` pointed at nixpkgs, not Mesh-LLM).
- Keep the template's sections. Tick a checkbox only once it is true for the exact head commit.
- Never claim review or testing in Martin's name that he didn't do.
- Show the real test results, most of the time: the PR body's validation and replies to review
  findings get a short summary of what ran, where, and the numbers, plus the proof run (the test
  fails on the old or a deliberately broken version). Use the independent reviewer's test data
  too, but don't mention the review or the second session: it doesn't matter to maintainers. One
  line each, numbers over adjectives, short and natural. Mesh-LLM
  #2673 ("the old code gave `[Recorded, Other, Unknown]`"), #2684 and #2670.
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
- **Refresh the repository skill before opening a PR** (and before marking one ready, if the
  skill is older than a week): rerun its measurement commands and reread the repo's
  `CONTRIBUTING.md`, `AGENTS.md`, PR template and workflows for changes since the skill's date;
  fold new reviewer patterns and rule changes into the skill and merge that first
  (`contribution-skill-authoring`, section 6). A monthly routine refreshes all skills as well.

## 6. Independent review before ready

Before a PR goes ready (or, if it already is, before its first human review), a fresh session
reviews it, ideally on another model than the one that wrote it: the author session is blind to
its own choices. For buzz and buzz-app this is also upstream's rule (`AGENTS.md`: an agent review
ran and its blockers were fixed or declined).
- The author session writes a handoff from the template `review-handoff.md` next to this skill
  (`~/.agents/skills/upstream-contributing/review-handoff.md`) to
  `~/.cache/<repo>-<N>-review-handoff.md`, and gives Martin the prompt at its end. Martin starts
  the review session.
- The reviewer only reads: no edit, commit, push or comment. It checks against the sources of
  truth in the checkout, the repository skill's "Review checklist", the PR body, and every fix
  from earlier rounds.
- Findings come back to the author session; Martin decides which to take. Rerun the review after
  substantial changes.
- Not for issues-only repos (berd) or text Martin writes himself (llama.cpp's texts); there the
  review covers the code or the draft notes.

## 7. Public steps need Martin's explicit OK

Opening a PR or issue, marking ready, commenting, force-pushing a reviewed PR, closing, posting
review results: each is a separate confirmation, even inside a "continue" plan, and especially when
new open points came up after the go-ahead. **PRs stay draft until Martin says ready.** The project
skill may forbid even more (llama.cpp: the agent never commits, pushes or posts).

## 8. After opening

- Answer every bot or AI review comment (Codex, CodeRabbit, maintainers' 🤖 agents): fix it, or
  reply in one line why not. Unanswered ones can get a PR closed.
  After every push, list each open PR's unresolved threads (`gh api graphql` reviewThreads,
  `isResolved`): a CodeRabbit thread on Mesh-LLM#2494 went unanswered for three days and turned an
  approval into "changes requested".
- Don't ping maintainers. When a PR waits: check the project's usual merge times for outside PRs;
  file a legitimate bug report in an affected downstream project, linking the PR; only after about a
  day without movement, one short message in the official channel, sent by Martin.
- **Upstream first, in parallel:** our packages never wait for upstream. Carry the fix downstream
  (patch, `checkFlags` skip, `substituteInPlace`) with a comment linking the upstream PR or issue,
  and drop it in the update that ships the fix.
- Feed what reviewers taught back into the repository skill (one bullet with the PR number),
  what holds for the whole organization into the org skill, and cross-project lessons into this
  one: each fact at the highest layer where it is true.
