---
name: contribution-skill-authoring
description: Use when writing a new contribution skill for an upstream project (an issue and pull request workflow the agent follows for that repo) or when refreshing an existing one in kleinbem/skills; it lists the sources to read, the facts to establish and measure, the section layout, the plugin plumbing and the update loop. Project skills build on the shared upstream-contributing skill and hold only what is specific to their project.
---

# Writing a contribution skill

A contribution skill (`<project>-contributing`) is the agent's memory of how one upstream project
accepts changes: its rules, its bots, its reviewers' habits, how to build it on our machines, and
what the project allows an agent to do. Existing examples in `plugins/`: `nixpkgs-contributing`,
`mesh-llm-contributing`, `goose-contributing`, `buzz-contributing`, `berd-contributing`,
`llama-cpp-contributing`. Write a new one before the first PR to a project, or as soon as a
second interaction with it is likely.

**Build on `upstream-contributing`.** The workflow every contribution shares (search first,
rebase before every push, draft until Martin says ready, voice and short texts, bot comments,
comparing against unmodified `main` on NixOS, carrying fixes downstream) lives there, together with
the per-project switches table. A project skill opens with a pointer to it and contains only what
is specific to its project, or where the project deviates (say so explicitly: llama.cpp's AI
policy overrides the shared "agent drafts texts"). Don't copy shared rules into a project skill; a
lesson that holds for every project goes into `upstream-contributing` instead.

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

Frontmatter: `name: <project>-contributing`; `description:` starts with "Use when ..." and names
the repo, the kinds of work (issue, PR, review, packaging) and the rules it enforces, so the agent
loads it at the right moment.

Section order (keep the numbering; drop a section only when the project has nothing for it):
- Intro: sources of truth, "as of <date>", the project's shape (org, speed, channels), and the
  line "Load `upstream-contributing` too ... this skill adds only what is specific to <project> and
  wins where the two differ" (copy it from an existing skill).
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
- Leave out what `upstream-contributing` already says (voice, rebase, search, checkboxes, bot
  comments, built-binary claims); repeat a shared rule only to state the project's exception.
- ASCII only if the target project demands it in its own files; the skill itself may use normal
  punctuation.

## 5. Plug it in

```
plugins/<plugin>/.claude-plugin/plugin.json      # name, one-line description, author
plugins/<plugin>/skills/<project>-contributing/SKILL.md
.claude-plugin/marketplace.json                  # add the plugin entry
README.md                                        # add the table row
plugins/upstream/skills/upstream-contributing/SKILL.md   # add the project's row to the switches table
```

The switches row answers facts 1, 2 and 6 in one line each: PRs from us, issue first, who writes
texts, AI attribution, sign-off, title format.

- Plugin name = the project's short name (`goose`, `mesh-llm`, `llama-cpp`); one plugin may hold
  several skills (`nixpkgs` has contributing and maintaining).
- Validate: `claude plugin validate .` from the repo root.
- Commit: `feat(<plugin>): add the <project>-contributing skill`; PR to kleinbem/skills; Martin
  merges (`feedback-merge-own-repos-on-request`).
- Installed copies come from nix-config's `kleinbem-skills` flake input (`ai-agents.nix` links them
  into every agent's skills directory). After the merge the Maintain workflow bumps the lock; until
  then the running agents still see the old version. Verify with the lock's `rev`.

## 6. Keep it alive

- After every review round or merge, add what the reviewers taught (one bullet with the PR
  number), as `mesh-llm-contributing` got the CI catalog rule in kleinbem/skills#22. Corrections
  go in the same place as the rule they correct; don't append contradictions.
- When a rule in the skill turns out wrong, fix it in the skill the same day and say in the PR
  what changed and which upstream file or PR proves it.
- Refresh dated facts (merge times, bots, templates, toolchain pins) when they are older than a
  quarter or when a PR behaves differently from what the skill predicted.
- Keep the measurement commands in the skill so a refresh is a rerun, not a redesign.
- Cross-project lessons go into `upstream-contributing` (every agent sees the skills, not only
  Claude's memory); when a project's switch changes, update its row in the table too. Martin's
  project state goes to Obsidian, not into a skill: a skill holds what is true for everyone
  contributing to that project.
