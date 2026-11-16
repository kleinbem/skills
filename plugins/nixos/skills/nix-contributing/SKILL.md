---
name: nix-contributing
description: Use when preparing a bug report, issue, PR or comment for NixOS/nix (the Nix package manager, C++), or when building and testing it on NixOS; covers its Automation/AI policy (Martin writes every text, the agent prepares facts and code), the issue templates and what a good bug report needs (version, master, regression), the PR template, release notes, CI and the merge queue, the Nix team's triage and review, and our setup.
disable-model-invocation: true
---

# NixOS/nix Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `nixos-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to NixOS/nix and wins
where they differ.

Sources of truth in the repo: `CONTRIBUTING.md` (with the "Automation/AI policy"),
`.github/ISSUE_TEMPLATE/{bug_report,feature_request,installer,missing_documentation}.md`,
`.github/PULL_REQUEST_TEMPLATE.md`, `.github/STALE-BOT.md`, `.github/stale.yml`,
`.github/labeler.yml`, `.github/CODEOWNERS`, `.github/workflows/{ci,labels,backport}.yml`,
`.coderabbit.yaml`, `HACKING.md`, `maintainers/{README,backporting,release-process,security-reports}.md`,
and the manual's `doc/manual/source/development/{contributing,testing,cxx,cli-guideline}.md`.
Rulesets: `gh api repos/NixOS/nix/rulesets`. No `AGENTS.md`, no issue-template `config.yml`
(blank issues allowed), no own `SECURITY.md` (the org's applies). Summary as of 2026-11-16.

LGPL-2.1, about 18,000 stars, about 3,000 open issues, default branch `master` (version 2.36 in
development; latest release 2.35.6, branch `2.35-maintenance`). The Nix team
(`@NixOS/nix-team`, nixos.org/community/teams/nix) triages on a project board in two weekly
meetings. Sergei Zimmerman (`xokdvium`) answers most issues and reviews or merges most PRs; John
Ericson (`Ericson2314`, libstore) and Eelco Dolstra (`edolstra`, default code owner) merge too;
Robert Hensing (`roberth`) owns `primops.cc` docs. Fast for focused fixes (section 7).

## 0. Hard rules that decide the agent's role

**Human-written texts only.** `CONTRIBUTING.md`, "Automation/AI policy":

> Human communication must remain human. Pull request / issue descriptions and comments,
> documentation, commit messages, and code comments must be human-authored.

> Contributions include code and documentation in commits, commit messages, pull request
> summaries and reviews, issue and vulnerability reports, GitHub comments, Matrix messages, and
> Discourse posts.

> Contributors are expected to be able to answer questions about their contribution and respond
> to feedback appropriately, **without simply forwarding messages back and forth to automated
> tools**.

What that means for us:
- **Martin writes every text**: issue bodies and titles, PR titles and bodies, comments, review
  replies, commit messages, code comments, manual pages and release notes (`rl-next` entries are
  documentation). Also Matrix and Discourse posts about Nix.
- **The agent prepares facts and code**, never prose to paste: a facts file
  (`~/.cache/nix-<topic>-facts.md`) with the version matrix, exact commands and output,
  reproducer, suspected cause marked "unverified", links to related issues and PRs, and the
  template's section names as headings so he can see what each needs. Tables and bullet facts,
  not sentences in his voice. The same for review replies: what the reviewer asked, what the code
  does, what changed.
- Code: the agent may write code and tests; Martin reviews and understands all of it before it is
  submitted ("Accountability"). Comments in the code are his: leave a `TODO(martin): comment on
  why …` marker instead of writing one, and remove the marker when he has written it.
- Commit messages: he writes them; the agent may run `jj describe` with his text verbatim. Agent-
  written code needs `Assisted-by: <tool> (<model + version>)` in the commit ("Transparency";
  `Co-authored-by` doesn't count). Merged examples: `Assisted-by: Claude Code (Claude Opus 5.5)`
  (64ee1277a5, a485b47d15).
- Issues and PRs: "Any adequate form of disclosure" for non-commit contributions. Research and
  debugging help is exempt only when "no substantial amount of their output is included"; a
  reproducer or root cause the agent found counts as "significant technical influence", so the
  issue or PR body gets one disclosure line in his words. Precedent: #16710 ("Disclosure: I used an
  AI assistant to help dig through the code and test combinations."), #15819. This is the repo's
  exception to the shared "no footers" rule: it holds for bodies, not for every comment.
- Draft PRs are exempt from full self-review only; every other requirement stays ("Exemptions").
- No agent posts anything: issues, PRs, comments, reactions and review requests go through Martin.
- No issue-first rule, no CLA, no DCO sign-off.

## 1. Before starting (and before filing a bug)

- **Right repo.** Package or NixOS module problems go to NixOS/nixpkgs (the bug template's own
  comment); NixOS installer problems too (#16808). A report from Lix (`nix --version` says
  "Lix, like Nix") belongs to Lix (#16821, closed as wrong repo). Check `nix --version` says
  `nix (Nix) …`.
- Search open and closed issues and PRs (`gh search issues --include-prs --repo NixOS/nix
  <terms>`), with the command name (`path-info`), the error text, and the subsystem
  (`narinfo`, `binary cache`). Check `is:open label:bug` for duplicates, as the checklist asks.
- Read the latest manual for the command (nix.dev/manual/nix/development): maintainers close
  reports of documented or intended behaviour (#16822: read-only mode not copying is "a bugfix";
  #16819: the github fetcher never supported `lfs`).
- **Reproduce on the latest release and on master**, and find the last good version. Not
  required by the template, but maintainers' own reports state it ("(Also on master)", #16824),
  and triage puts `regression` before `bug` (`maintainers/README.md`). Commands in section 3.
- Security problems never go in a public issue: private advisory on the repo ("Report a
  vulnerability", enabled) or email the NixOS Security Team (`nixos-org`).
- PRs: "first-time contributors not to propose new features but rather fix tightly-scoped
  problems". Issues labelled `idea approved` or `RFC` get prioritised review; far-reaching
  changes are coordinated with the team first. Open PRs often already cover a fix: check them.

## 2. Designing the change

- Read `doc/manual/source/development/cxx.md` (C++ style, the `*-impl.hh` pattern) and, for
  CLI changes, `cli-guideline.md`.
- Use the project's own wrappers and helpers: xokdvium asks for `isTTY`,
  `getStandardInput/Output` (#16711), the chmod wrapper and a clang-tidy disallow entry for the
  raw call (#16770), `openFileReadonly` over bare `open` (#16770).
- No unfounded defensive code: a global mutex nobody contends, a race that can't happen, a
  pointless `stat` (#16744, #16734) all get questioned. Fix the cause, keep the diff small.
- Tests with the fix (`CONTRIBUTING.md` checklist): functional `tests/functional/*.sh`, unit
  `src/*/tests` (GoogleTest), integration `tests/nixos/*`. A regression test fails on the old code.
  Reviewers ask to split tests into their own file (#16760).
- **Release note** for user-visible or incompatible changes: a file in `doc/manual/rl-next/`
  with `synopsis:`, `issues:`, `prs:` frontmatter and a paragraph (format in
  `development/contributing.md`, "Add a release note"). Reviewers ask for one when behaviour
  changes (#16760, #16728). Martin writes it.
- User docs in `doc/manual/source`, API docs in headers; semantic line breaks in Markdown.

## 3. Building and validating on NixOS

- Versions without building: `nix shell nixpkgs#nixVersions.latest` (release),
  `nixpkgs#nixVersions.git` (a master snapshot, `2.36pre20261109_16fa212a` as of this date),
  `nixpkgs#nixVersions.nix_2_34` etc. for older series. Current master exactly:
  `nix shell github:NixOS/nix` (builds from source when Hydra's `nix:master` output isn't
  substitutable; heavy, so a GitHub runner or the Orin, not the PC).
- A local-store command from `nix shell` still talks to the host's daemon (2.35.6 on the
  fleet); #16822's report hinged on the daemon's version. Say which Nix ran the client and which
  the daemon, or take the daemon out (`--store https://…` talks to a binary cache directly).
- Version line for the report: `nix-env --version` (what the template asks; prints
  `nix-env (Nix) 2.35.6`); `nix --version` is the same binary. Add the system (`x86_64-linux`)
  and the nixpkgs revision the versions came from.
- Build in the clone: `nix develop`, then `configurePhase`, `buildPhase`, `checkPhase`
  (`HACKING.md`); `meson test nix-store-tests`, `meson test --suite ca`, `meson test <name>` for
  one functional test; `GTEST_FILTER=…` for unit tests (`testing.md`). Full package:
  `nix build`. Formatting: `./maintainers/format.sh` (pre-commit hooks:
  `pre-commit-hooks-install`).
- CI parity: `nix build --file ci/gha/tests/wrapper.nix componentTests -L`, then `vmTests` on
  Linux; `nix build .#hydraJobs.tests.functional_user` runs the functional suite in a VM.
  clang-tidy: `nix build .#hydraJobs.clangTidy.x86_64-linux -L`. These are heavy: one at a time,
  on a runner or the Orin.
- Integration tests (`hydraJobs.tests.*`) mostly run only on Hydra after merge.

## 4. Commits

- Martin writes the messages (section 0). Subjects usually name the component:
  `libstore: …`, `libexpr: …`, `libutil-tests: …`, `packaging/scripted-installer: …`; plain
  sentences also land ("Use posix_spawn in spawnProgram implementation"). The body says **why**
  (checklist: "Commit message explains **why** the change was made").
- **Merge commits** through the merge queue: every commit lands on `master` as written, and the
  merge commit is the PR title plus `(#N)`. Keep a clean history by rebasing; each commit stands
  alone.
- Credit reused work in the message (`This is based on the work of @user in <url>`,
  `Co-authored-by:`); cherry-picks from other repos use `-x` with the hash turned into a URL.

## 5. Pull request

- Template sections: `## Motivation` (why; link issues) and `## Implementation` (approach;
  alternatives for invasive changes; reading order for large ones). Keep them; Martin fills them.
- `Closes: #<number>` for issues it fixes (`CONTRIBUTING.md`'s form).
- Draft until done (`CONTRIBUTING.md`), and draft until Martin says ready (shared rule).
- The checklist in `CONTRIBUTING.md` (idea approved, tests, manual, API docs, why in commit,
  release note) is guidance, not part of the template: cover each that applies.
- Stuck PRs: the template points to the two open team meetings (calendar link in it); otherwise
  "PRs in distress" on Discourse or `#nix-dev:nixos.org` on Matrix, sent by Martin.

## 6. CI and bots

- `ci.yml` on `pull_request`, `merge_group`, push: `eval`, `pre-commit checks`, then `tests on
  ubuntu`, `tests on macos`, `tests on ubuntu (with sanitizers / coverage)`, `windows unit
  tests`, `installer test …`, `clang-tidy`, `flake_regressions`.
- Required (ruleset "master"): `tests on ubuntu`, `tests on macos`, `installer test on ubuntu`,
  `installer test on macos`, `flake_regressions`; one approval; "extra approval for unattributed
  changes"; merge method `merge` via merge queue (ALLGREEN, up to 5). Approvals are not dismissed
  on push.
- `labels.yml` (actions/labeler) adds area labels from paths (`store`, `fetching`, `repl`,
  `new-cli`, `with-tests`, `documentation`, `c api`). Issue templates add `bug`, `feature`,
  `installer` or `documentation`. Other labels (`regression`, `idea approved`, `backport 2.35-maintenance`)
  are maintainers' to set: say "regression since 2.35" in the text instead.
- Backports: maintainers add `backport <branch>`; `backport.yml` opens the PR.
- Stale bot: `stale` after 180 days, never closes; a new comment removes it.
- CodeRabbit is configured but auto-review is off (`.coderabbit.yaml`); no AI review to answer.

## 7. What the history shows

Measured 2026-11-16 (commands in `contribution-skill-authoring`, section 3):
- Merged PRs are mostly from team branches: 10 of the last 40 came from forks. Fork PRs in the
  last 200 merged (77, back to 2026-08-31): median about 16 hours, 0 to 1284.
  `gh pr list -R NixOS/nix --state merged --limit 200 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
- Mergers of the last 40: xokdvium 25, Ericson2314 9, the merge queue app 5, edolstra 1.
- Closed fork PRs: superseded by a maintainer's own fix (#16617 → #16619, #16625), moved to a
  team branch (#16771), fixed upstream instead (#16614: boost). Search open PRs before starting.
- Bug issues get a maintainer answer within a day or two, usually xokdvium: a workaround
  (#16737), "intended" with the reason (#16822, #16819), or confirmation with the bisected first
  bad version (#16644). Well-sourced reports with a reproducer and a root cause get fixed fast
  (#16613 → release 2.35.5).
- Review style: short questions and GitHub suggestions ("Can you reuse isTTY …?", "This seems
  unnecessary"); authors answer each point in one line and push (#16744, #16711).
- `Assisted-by:` trailers are common in merged commits, from team members too (64ee1277a5,
  f566910ee8, 9c7f0b8469).

## 8. Our setup and current threads

- No clone yet. Clone to `~/Develop/github.com/NixOS/nix` with jj colocated, `origin` upstream.
  `kleinbem/nix` is taken by a fleet repo (not a fork): fork as `gh repo fork NixOS/nix
  --fork-name nix-upstream` (remote `fork`) when the first PR opens.
- The fleet runs Nix 2.35.6 from nixpkgs (`nix --version` on nixos-nvme).
- Current thread: `nix path-info --json --store <binary cache>` errors on a missing path since
  2.35 (2.34.9 printed `null`); master the same. Facts in
  `~/.cache/nix-path-info-json-binary-cache-facts.md`; worked around in kleinbem-dev/nix-gantry#52.
  No issue filed yet; Martin writes it. Searches on 2026-11-16 (`path-info json`,
  `path-info is not valid`, `narinfo concurrent`) found no duplicate; #13413 (closed) is an
  older path-info JSON change.

## Review checklist

- No text in the change was written by the agent: commit messages, code comments, docs, release
  note, PR body are Martin's; no leftover `TODO(martin)` markers (section 0).
- Agent-written code has `Assisted-by: <tool> (<model + version>)` in its commits, and the PR
  body has his disclosure line (section 0).
- Bug reports name the release and master results, the last good version, and the exact
  commands with output (sections 1, 3).
- Tests cover the fix and fail on the old code; a user-visible change has an `rl-next` entry
  (section 2).
- Uses Nix's own helpers and wrappers; no defensive code for states that can't happen
  (section 2, #16711, #16744).
- `./maintainers/format.sh` is clean and `componentTests` passed on the head (section 3).
- Each commit stands alone (merge commits) and says why (section 4).
- No open PR or maintainer branch already covers the fix (sections 1, 7).
