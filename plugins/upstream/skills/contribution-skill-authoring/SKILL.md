---
name: contribution-skill-authoring
description: Procedure for writing or refreshing the organization skill (<org>-org) and repository skill (<repo>-contributing) for an upstream project in kleinbem/skills, before the first contribution and before every PR; sources to read, facts to measure, layout, plugin plumbing, refresh.
disable-model-invocation: true
---

# Writing and refreshing contribution skills

Contribution skills come in three layers; each fact goes into the highest layer where it is true:
1. `upstream-contributing`: shared workflow, router, switches table. Always loaded.
2. `<org>-org`: one per GitHub organization, **always**, even when we touch one of its repos:
   org policies, org-wide checks, security reporting, governance, channels, a repo table.
3. `<repo>-contributing`: one per repository we contribute to: its rules, bots, reviewers,
   history, how to build it here.

Layers 2 and 3 are manual skills (`disable-model-invocation: true`): out of every session's
context, run by Martin as `/<name>` or read by an agent as files through the router.

**When:** on first contact, **before** the first issue, PR or comment, in this order:
1. **Organization** (section 1, org part): read the org skill, or write it if the org has none.
2. **Repository** (section 1, repo part): the repo's own contribution files.
3. **History** (section 3): scan its PRs and reviews for the lessons.
4. **Write the repository skill** (sections 2, 4, 5), merge it, then start contributing.

Refresh the repository skill before every PR (section 6); a monthly routine refreshes all of them.

Principles:
- **Facts, dated.** Every rule comes from a file in the repo or from observed PRs; say "as of
  <date>" once near the top and cite PR or issue numbers as examples. Never write a rule you
  haven't verified in the repo or its history.
- **Repo rules win over habits.** Where the project's policy limits the agent (AI disclosure,
  no agent trailers, no automated submissions, humans write texts), quote the policy lines and
  translate them into what the agent does and doesn't do for Martin. That section comes first.
- **Short and plain**, like everything else we write (the `feedback-short-natural-comments`
  memory): result first, no filler, no claims about the project's intentions.
- **Numbers are examples**, not laws: merge times, counts and samples change; show the command
  that produced them so the next refresh can rerun it.

## 1. Read the sources of truth (all of them, fully)

**Organization** (for the org skill, or to check the existing one is current):
- `gh api repos/<org>/.github/contents` (`CONTRIBUTING.md`, `SECURITY.md`, `GOVERNANCE.md`,
  `CODE_OF_CONDUCT.md`, `profile/README.md`, workflow templates); many orgs have none.
- What every PR in the org gets: check runs on a recent PR of a small repo in the org
  (`gh api repos/<org>/<repo>/commits/<sha>/check-runs --jq '.check_runs[] | "\(.name) \(.app.slug)"'`);
  a check that appears across repos (Block's `block-dco-check`) is org-wide.
- Policies shared across repos (AI usage, sign-off): compare the `CONTRIBUTING.md` of two or three
  of the org's repos; note where they differ (NixOS: nixpkgs vs nix; ggml-org: llama.cpp vs
  whisper.cpp).

**Repository:**
Fetch with `gh api repos/<owner>/<repo>/contents/<path> --jq .content | base64 -d`, or read the
clone. Typical list; note which exist:
- `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, repo-local
  skills (`skills/`, `.agents/skills/`, `.claude/`): the policy and the rules for agents.
- `.github/pull_request_template.md` (or `PULL_REQUEST_TEMPLATE.md`), `.github/ISSUE_TEMPLATE/`
  (forms and their required fields), `.github/instructions/`.
- `.github/workflows/` (names and triggers: required checks, fork-approval, bots, stale, labeler,
  draft label, AI reviewers), `ci/` docs, `CODEOWNERS`, `SECURITY.md`, `README.md` build sections,
  `docs/build*.md`, release notes conventions (`RELEASE.md`, changelog tooling).
- Coding conventions: `.editorconfig`, `.clang-format`, `rustfmt.toml`, `.pre-commit-config.yaml`,
  lint configs, `justfile`/`Makefile` recipes the project expects contributors to run.
- Governance: who merges (CODEOWNERS groups, recent mergers), where discussion happens (Discord,
  Discussions, mailing list), release cadence.

## 2. Establish these facts

Each gets a short, sourced statement in the skill. Mark "none" explicitly when the project has no
rule, so the next reader doesn't search again.

1. **What the agent may do.** AI policy: allowed, disclosed, restricted or forbidden; the exact
   disclosure form (PR line, commit trailer such as `Assisted-by:`, none); forbidden actions
   (`gh pr create`, comments, commit messages); attribution trailers accepted or rejected
   (Mesh-LLM rejects `Co-Authored-By: Claude`; nixpkgs requires `Assisted-by:`; llama.cpp forbids
   AI-written texts entirely). This decides whether Martin writes texts himself or reviews drafts.
2. **Issues first?** Whether features or fixes need an issue, who writes it, which template, what
   state it must reach (goose: "Ready"), and what closes a PR without review.
3. **Scope rules.** One change per PR, first PR limits, backend-at-a-time rules, size limits, what
   the automated PR checker or triage bot enforces, what is out of scope by design.
4. **Tests and validation.** What a fix must prove (regression test failing before), what CI runs
   locally (commands), heavy checks and where to run them (GitHub runners, pre-flight repos,
   workstation), platform rows that must stay green.
5. **Code conventions** reviewers cite: style, naming, comments, file size rules, dependency
   policy, docs that must change with code.
6. **Commits and titles.** Conventional Commits or module prefixes, squash merge (then the PR
   title is the commit), DCO/sign-off, allowed types, release-notes consequences.
7. **The PR template** and which sections must stay; what to tick only when true.
8. **CI and bots.** Required checks, fork runs needing approval, approvals dismissed on push,
   AI reviewers to answer, stale and draft automation, labels that mean something.
9. **Reviewers and timing.** Who reviews what (CODEOWNERS), their timezone if it matters, merge
   times, how to nudge (rebase, official channel), what to never do (ping, repeat).
10. **Building and testing on NixOS**: the nix shell inputs (take them from the project's nixpkgs
    package), toolchain pins, tests that need paths like `/usr/bin/true` or network, how to
    separate host failures from the change (compare against unmodified main).
11. **Our setup**: fork name, clone path, jj remotes (`origin` upstream, `fork` ours), workspaces,
    pre-flight CI, related nixpkgs packaging and the downstream angle to mention upstream.
12. **What reviews show**: patterns from real PRs with numbers.

## 3. Measure, don't guess

Run these and put the results in "What the history shows" with the date:

```bash
# merge times of fork PRs, in hours (last 40 merged)
gh pr list -R <owner>/<repo> --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository \
  --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'

# why fork PRs get closed: title plus the last comment
gh pr list -R <owner>/<repo> --state closed --limit 80 --json number,title,mergedAt,isCrossRepository,comments,author \
  --jq '[.[] | select(.mergedAt == null and .isCrossRepository)] | .[:30][] | "#\(.number) \(.author.login): \(.title[0:60]) || \((.comments | last | ((.author.login // "?") + ": " + ((.body // "") | gsub("[\\n\\r]+"; " ") | .[0:150]))) // "no comment")"'

# what reviewers ask for: review comments on recently merged PRs
gh pr list -R <owner>/<repo> --state merged --limit 30 --json number --jq '.[].number' |
  xargs -I{} gh api repos/<owner>/<repo>/pulls/{}/comments --jq '.[] | "#{} \(.user.login): \(.body | gsub("[\\n\\r]+"; " ") | .[0:160])"'
```

Read a dozen of those comments and the closures; group them into three to eight patterns, each
with one or two PR numbers. Skip patterns you saw once.

## 4. Write the skill

Frontmatter for both layers: `name:` (`<org>-org` or `<repo>-contributing`), `description:` saying
what it covers and "Read after upstream-contributing" (org) or which repo (repo), and
`disable-model-invocation: true`. Only `upstream-contributing` stays model-invocable.

**Organization skill** (`<org>-org`), short is fine: intro ("Layer 2 of 3 ..." copied from an
existing org skill), sources and date; **0.** org-wide hard rules (AI policies and which repos
follow which, DCO/CLA, checks every PR gets); **1.** org-wide facts (security reporting,
governance, channels, how the repos relate); **2.** the repo table (repo, repository skill or
"none yet", one-line note).

**Repository skill** (`<repo>-contributing`), sections in this order:
Section order (keep the numbering; drop a section only when the project has nothing for it):
- Intro: the line "Layer 3 of 3: read `upstream-contributing` and `<org>-org` first ..." (copy it
  from an existing skill), sources of truth, "as of <date>", the repo's shape (speed, owners).
- **0. Hard rules that decide the agent's role** (policy, issues-first, bans). First, because they
  change everything after.
- **1. Before starting**: searches, issue rules, scope checks, what gets closed unread.
- **2. Designing the change**: repo patterns, "read the commit that introduced the analogous
  feature", code and comment rules, docs that follow code, claims no larger than the code.
- **3. Building and validating on NixOS**: commands that work here, CI parity, what stays local.
- **4. Commits** and **5. Pull request** (template, voice, what to tick).
- **6. CI and bots**.
- **7. What the history shows** (dated numbers, PR examples).
- **8. Our setup and current threads** (fork, paths, downstream packaging, open items).

Style rules for the text:
- Short sentences, bullets of one or two sentences, commands in code spans, no filler.
- Quote a policy line verbatim when breaking it has a penalty; paraphrase the rest.
- Say what to do, then why in half a sentence; reviewers' reasons beat our opinions.
- Keep it under about 250 lines. A rule that needs a page belongs in the repo's own docs; link it.
- Leave out what `upstream-contributing` or the org skill already says (voice, rebase, search,
  checkboxes, bot comments, built-binary claims, org security and DCO); repeat a shared rule only to
  state the repo's exception.
- ASCII only if the target project demands it in its own files; the skill itself may use normal
  punctuation.

## 5. Plug it in

One plugin per organization, holding its org skill and all its repository skills:

```
plugins/<org>/.claude-plugin/plugin.json                  # name = org slug, description, author
plugins/<org>/skills/<org>-org/SKILL.md                   # the org skill
plugins/<org>/skills/<repo>-contributing/SKILL.md         # one per repository
.claude-plugin/marketplace.json                           # one entry per plugin
README.md                                                 # one row per skill
plugins/upstream/skills/upstream-contributing/SKILL.md    # route table row + switches row
```

- Plugin name = the GitHub org in lower case (`nixos`, `block`, `ggml-org`, `aaif-goose`,
  `mesh-llm`); the org skill's name is the plugin name plus `-org`, except where the org name
  already ends in it (`ggml-org`).
- The switches row answers facts 1, 2 and 6 in one line each: PRs from us, issue first, who
  writes texts, AI attribution, sign-off, title format.
- Validate: `claude plugin validate .` from the repo root.
- Commit: `feat(<plugin>): add the <repo>-contributing skill`; PR to kleinbem/skills.
- Installed copies come from nix-config's `kleinbem-skills` flake input (`ai-agents.nix` links
  every `plugins/*/skills/*` into each agent's skills dir and `~/.agents/skills`). After the merge
  the lock has to move (nightly Maintain, or a `nix flake update kleinbem-skills` PR) and the host
  has to apply; until then agents see the old version. Check with the lock's `rev`.

## 6. Refresh

**Before every PR** (and before marking one ready when the skill is older than a week), and in the
monthly routine for all skills:
1. Reread the repo's and org's sources (section 1) and diff them against the skill's summary.
2. Rerun the measurement commands (section 3) for the PRs since the skill's date.
3. Fold new rules, reviewer patterns and changed numbers into the skill, update its date, and
   merge that before opening the PR.

Also:
- After every review round or merge, add what the reviewers taught (one bullet with the PR
  number), as `mesh-llm-contributing` got the CI catalog rule in kleinbem/skills#22. Corrections
  go in the same place as the rule they correct; don't append contradictions.
- When a rule in the skill turns out wrong, fix it in the skill the same day and say in the PR
  what changed and which upstream file or PR proves it.
- Refresh dated facts (merge times, bots, templates, toolchain pins) when they are older than a
  quarter or when a PR behaves differently from what the skill predicted.
- Keep the measurement commands in the skill so a refresh is a rerun, not a redesign.
- Each lesson goes into the highest layer where it is true: the repo skill, the org skill, or
  `upstream-contributing` (every agent sees the skills, not only Claude's memory); when a repo's
  switch changes, update its row in the table too. Martin's
  project state goes to Obsidian, not into a skill: a skill holds what is true for everyone
  contributing to that project.
