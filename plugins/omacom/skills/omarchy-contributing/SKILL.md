---
name: omarchy-contributing
description: Contribution rules for omacom/omarchy (formerly basecamp/omarchy), the Omarchy distribution's desktop, configs, bin/ commands and migrations; covers bugs-only issues, Discussions and Discord routing, the omarchybot triage agent, duplicate PRs, the PR template and screenshot check, tests, and our nix-omarchy threads. Not the desktop usage skill `omarchy`.
disable-model-invocation: true
---

# omacom/omarchy

Layer 3 of 3: read `upstream-contributing` and `omacom-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to omacom/omarchy and
wins where they differ. The skill `omarchy` (no suffix) is Omarchy's own usage skill for the
desktop, shipped by nix-omarchy; it is not about contributing.

Sources of truth in the repo: `AGENTS.md` (`CLAUDE.md` is `@AGENTS.md`), `agents/skills/*.md`,
`default/agents/skills/omarchy/contributing.md` (Omarchy's own guide for agents filing for a user),
`docs/testing.md`, `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/{bug.yml,config.yml}`,
`.github/SECURITY.md`, `.github/workflows/{test.yml,visual-evidence.yml,i18n-*.yml}`. There is no
`CONTRIBUTING.md`. As of 2026-11-14.

Shape: DHH's project, very busy. About 4000 open PRs, 6900 open issues and PRs together;
`quattro` gets dozens of commits a day. The repo moved from basecamp/omarchy (old links redirect).

## 0. Hard rules that decide the agent's role

- **Issues are for verified bugs only.** `config.yml`: blank issues off; "GitHub issues should be
  used for verified bugs only." The one form (`bug.yml`) asks for system details and "What's
  wrong?" plus `omarchy-debug` output. Feature ideas go to Discussions → Suggestions; support and
  "is this a bug?" go to Discord (https://omarchy.org/discord).
- **AI:** no ban. Omarchy's own agent guides tell agents to file with `gh`, and
  `diagnose-crash/reporting.md` asks an agent-filed issue or comment to end with "Filed by <model>
  via <harness>." Outside PRs with `🤖 Generated with [Claude Code]` get reviewed normally
  (omacom/omarchy#16260). So: agent drafts, Martin reviews and posts; one disclosure line at the end.
- **Branch:** PRs target `quattro` (default). `master` (Omarchy 3.x, last commit 2026-08-14) and
  `dev` (last 2026-09-28) are dead for contributions.
- **One problem per PR** (template comment, `AGENTS.md` "Git": atomic commits).

## 1. Before starting

- Duplicates are the main reason outside PRs get closed: "Closing as a duplicate of #18302, which
  … was opened first" (dhh on #18351); the earlier PR wins unless it has a defect. Search issues
  and PRs by symptom and fix words, then check the changed files of all open PRs (`--search`
  only reads titles, bodies and comments; ~4000 open PRs take about 5 minutes):
  `gh pr list -R omacom/omarchy --state open --limit 5000 --json number,title,files --jq '.[] | select(any(.files[].path; contains("<path>"))) | "#\(.number) \(.title)"'`
- If a fix PR already exists, don't open another; a 👍 on the PR going forward (omarchybot names
  it) is the useful signal. Comment only with something new: a case the PR misses, a reproduction
  on different hardware.
- Bugs in a program Omarchy only installs belong upstream of that program, unless Omarchy's config
  or packaging causes them (`diagnose-crash/reporting.md`). Packaging bugs go to omacom/omarchy-pkgs.

## 2. Designing the change

- Follow `AGENTS.md` and the `agents/skills/<area>.md` it names for the area (bin commands,
  install scripts, shell/QML, migrations, visual verification).
- Bash: `#!/bin/bash`, two-space indent, `[[ ]]` and `(( ))`, Omarchy helpers (`omarchy-pkg-add`,
  `omarchy-cmd-present`, `omarchy-notification-send`) instead of raw commands.
- A change to a shipped `config/` file also needs a migration under `migrations/` that fixes
  existing users' `~/.config` copies; edit symlinked configs through the link
  (`sed -i --follow-symlinks`, omarchybot's fix on #8055).
- Platform names are fixed (`x86`, `aarch64`, `aarch64-apple`, …); workarounds go upstream first.
- Tests only where they catch a regression (`AGENTS.md` "Tests": no tests for config values or
  migrations unless they hold logic; a fix with logic gets one test that fails on the base).

## 3. Building and validating on NixOS

- `./test/all` (CLI + shell tests) is what CI runs, inside the current release's VM image
  (`test.yml`). Run the area's file directly: `bash test/shell.d/<area>-test.sh >/tmp/x.log 2>&1`.
- Many tests read the live Hyprland/Quickshell session; on NixOS nix-omarchy's session is close
  but not identical. Compare a failing file against unmodified `quattro` before blaming the change.
- Visual changes need before/after screenshots (`agents/skills/visual-verification.md`).

## 4. Commits

- Atomic, "succinct and describe the change" (`AGENTS.md`). No prefix convention. Squash merge:
  the PR title becomes the commit.

## 5. Pull request

- Title: a plain imperative sentence describing the user-visible effect, no prefix ("Share the
  selected region relative to its monitor", "Keep the Yoga Slim 7x asleep in deep suspend with the
  lid open").
- Template sections stay: **What changes**, **Verification** ("'Tests pass' alone isn't
  enough"), **Screenshots**. With nothing visible, one line: `No visible change: <why>`.

## 6. CI and bots

- `Tests` (`test.yml`, VM image of the current release; forks run the same way), `i18n-check`,
  `Check visual evidence` (not required; fails when a PR touching shell/config/themes/packages has
  no screenshot or `No visible change:` line; editing the body reruns it).
- **Greptile Review** comments on every PR; Copilot review appears on some.
- **omarchybot** is the maintainers' triage agent (Claude Opus 5.5 with Codex Medium as second
  opinion). It reproduces bugs on disposable Omarchy workers, labels, pushes fixes to contributor
  branches, opens its own fix PRs, picks which duplicate goes forward, and closes others "at the
  maintainer's request". Treat its comments as maintainer-side review: answer them like a human's.
- Community AI reviewers (`llstrk`'s "Automated AI review") also comment; not maintainers.

## 7. What the history shows

As of 2026-11-14 (last 100 merged PRs):
`gh pr list -R omacom/omarchy --state merged --limit 100 --json isCrossRepository,author,mergedBy`
- 9 of 100 merged PRs came from forks, almost all from regular contributors (birkskyum, ARM
  hardware); merged in 0-17 h. Authors: dhh 51, omarchybot 34. Mergers: dhh 56, omarchybot 29.
- Since 2026-09-01: 893 PRs merged, 1414 closed unmerged; most closures are duplicates or
  superseded ("Closing in favour of #17340", #17793; #12501 closed for #8055).
- A verified outside fix can still wait months: #8055 (region share offset) was opened 2026-08-24,
  verified by omarchybot 2026-09-28, still open 2026-11-14 with three duplicates.
- dhh rejects per-device divergence: "system has to be consistent across all devices running
  omarchy" (#17931).

## 8. Our setup and current threads

- Downstream: kleinbem/nix-omarchy vendors `quattro` for NixOS. Fork `kleinbem/omarchy` (not
  created yet); clone `~/Develop/github.com/omacom/omarchy`, remotes `origin` upstream, `fork` ours.
- omacom/omarchy#12391: share-picker region command uses slurp's global `%x,%y` instead of
  output-relative `%X,%Y,%W,%H`; offset or black share on any monitor not at 0,0. Fix going
  forward: omacom/omarchy#8055 (duplicates #15120, #16260, #16417; issue duplicate #16255). This is
  the report kleinbem/nix-omarchy's `pkgs/hyprland-preview-share-picker.nix` pin comment links
  (kleinbem/nix-omarchy#6); the pin moves past the picker's v0.3.1 once #8055 lands.
- Martin has no issue or PR here yet (2026-11-14); org-level threads are in `omacom-org`.

## Review checklist

- Not a duplicate: open PRs' changed files checked for the touched paths (section 1).
- Base is `quattro`; one problem per PR.
- A shipped config change comes with a migration that follows symlinks (section 2).
- Template sections kept; Screenshots filled or `No visible change: <why>` (section 5).
- Verification lists what ran and what was seen, not "tests pass".
- Bash follows `AGENTS.md` style; tests only where they catch a regression.
- Disclosure line at the end of the issue or PR body (section 0).
