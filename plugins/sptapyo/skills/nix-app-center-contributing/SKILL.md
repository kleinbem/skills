---
name: nix-app-center-contributing
description: Use when preparing an issue or PR for SPTApyo/nix-app-center (Nix App Center, a GTK4/libadwaita app store for NixOS and Home Manager; Rust workspace core/gui/cli), or when building or testing it; covers CONTRIBUTING.md (size guide, Conventional Commits, squash), the AI rule, the PR checklist, CI and the coverage gate, the safety rules for agents, and how to test against a config copy.
disable-model-invocation: true
---

# SPTApyo/nix-app-center Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `sptapyo-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to nix-app-center and
wins where they differ.

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (`CLAUDE.md` loads it), `SECURITY.md`,
`docs/{README,design,testing,repo-layout,packaging}.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
`.github/ISSUE_TEMPLATE/*.yml`, `.github/workflows/{ci,flake-lock}.yml`, `justfile`,
`scripts/check-commit-msg.sh`, `.claude/skills/e2e-step`. Summary as of 2026-11-17.

GPL-3.0, created 2026-10-08, at v0.3.0, one maintainer (`@SPTApyo`, sole CODEOWNER) who wrote all
non-bot commits. The repo name on GitHub is `Nix-App-Center`; URLs in its own files use
`nix-app-center` and both resolve.

## 0. Hard rules that decide the agent's role

- **AI use is allowed, undisclosed, but owned** (`CONTRIBUTING.md`): "you are the author, and you
  understand every line you submit. You have run it, read the diff, and can explain why it is
  written that way." and "Large generated pull requests nobody has read get closed without a
  detailed review." So: the agent drafts, Martin reads the whole diff before the PR opens, and
  only then is the first checklist box ("I have read and understand every line of this diff")
  ticked. No trailer or disclosure line is asked for.
- **Size guide:** one topic per PR, under 400 changed lines and 10 files (lockfiles and generated
  files aside). "Bigger than that: open an issue first and agree on the approach." The same holds
  for "anything bigger than a small fix".
- **Agent safety rules** (`AGENTS.md`): never write to `/etc/nixos`, the user's own configuration
  or the real `~/.local/share/nix-app-center`; never run `nixos-rebuild`, `home-manager switch`,
  `pkexec`, `sudo` or `nix-collect-garbage`; don't kill a running `nix-app-center` you didn't
  start. "Do not commit, push or open a pull request unless asked."
- **Blank issues are off:** issues go through the forms (bug report needs the version and the
  output of `nix-app-center-cli layout --verify` plus `nixos-version`). Security goes to a
  private advisory, never a public issue.

## 1. Before starting

- Search issues and PRs; as of 2026-11-17 there are no issues at all and no PR from outside.
- A bug fix within the size guide goes straight to a PR (`CONTRIBUTING.md`: an issue first only
  for "anything bigger than a small fix"). A feature gets an issue first.
- Plans and to-do lists don't go into the repo ("plans live in issues").

## 2. Designing the change

- Logic lives in `crates/core` with unit tests next to the code; "the GUI stays thin".
  `docs/repo-layout.md` maps the files, `docs/design.md` says why things work as they do.
- Follow the split the code uses: a pure function plus a thin wrapper that runs commands; test
  the pure one (`docs/testing.md` names the models).
- Comments follow rustdoc, kept short: `//!` one to three lines per module, `///` first line says
  what it does and returns, `//` inside a function "only the non-obvious why, eight words at
  most". No history in comments.
- No new dependency "for what a few lines can do"; new ones must pass `just deny`. No lint
  suppressions: "never add `#[allow(...)]`".
- User-facing strings are English, wrapped in `t()` (`n_()` for static tables, `plural()` for
  counts); run `just pot` after changing any and commit `po/`.
- Behaviour changes update `README.md`, `docs/design.md` or `docs/user-guide.md` in the same PR.
  Docs are plain: short sentences, no em dashes, no backticks around names in prose.

## 3. Building and validating on NixOS

- Everything runs in the dev shell: `nix develop -c just check` (format, clippy with
  `-D warnings`, tests, translations, `cargo deny`). One test:
  `nix develop -c cargo test -p nix-app-center-core NAME`.
- `nix develop -c just cov` fails under 70 % line coverage of the core; never lower the threshold.
- `just check` does not run the end-to-end suite. `just e2e` (needs network, GTK Broadway plus
  Playwright) is for UI changes; say which suites ran.
- `nix build .#checks.x86_64-linux.apply` runs a real `nixos-rebuild` in a VM (minutes, several
  GB): only for changes to applying or going back.
- "A bug fix comes with a test that fails without the fix." Code that writes files, runs commands
  as root or deletes store paths needs tests for its error cases too.
- Tests never touch the real system. Tests that read the environment or the data directory take
  `crate::env_lock()` first and work in their own temporary directory.
- Trying it against a real config without risk: copy the config, and either set
  `NIX_APP_CENTER_CONFIG_DIR=<copy>` or point `XDG_CONFIG_HOME`/`XDG_DATA_HOME` at throwaway
  directories with a `nix-app-center/settings.json` holding `config_dir` and `host`. With
  `NIX_APP_CENTER_CONFIG_DIR` set, the `host` and `apply_command` settings are ignored.
- A plain `nix build path:<clone>` takes a few minutes on nixos-nvme and runs the core tests.

## 4. Commits

- Conventional Commits, checked on every commit of a PR by the `commit messages` job:
  `type(scope)?: summary`, types `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`,
  scope lower case (`core`, `gui`, `cli`, `e2e`, `i18n`, `nix`, `deps`), summary imperative and
  lower case, no final period, 72 characters for the whole line.
- "One commit, one intent." Branch names follow the type: `fix/...`, `feat/...`.
- Squash merge only: the PR title becomes the commit on main and follows the same rules.

## 5. Pull request

- Keep the template's sections: "What and why", "How it was tested", "Screenshots" (delete for
  non-UI changes), "Checklist". Tick only what is true for the head commit; the first box needs
  Martin's own read of the diff.
- "How it was tested" names the commands and the setups tried (NixOS flake, channels, Home
  Manager).

## 6. CI and bots

- Required on main: `format, clippy, tests, translations`, `nix build`, `core coverage`,
  `advisories and licenses`. Also run: `commit messages` (PRs only), `nix build (aarch64-linux)`,
  `NixOS module test`. Check with
  `gh api repos/SPTApyo/nix-app-center/rules/branches/main`.
- No required approvals, no review-thread gate, no AI reviewer. Dependabot and a weekly
  `flake-lock.yml` open the bot PRs.
- A new push cancels the previous CI run of the branch.
- CI on a fork PR waits for the maintainer's approval (`action_required`, seen on
  SPTApyo/nix-app-center#37), so run `just check` and `just cov` locally before opening.
  `just translations` needs git: in a jj workspace run `./po/update-pot.sh` and check
  `jj diff po/` shows only the `POT-Creation-Date` line, then `jj restore po/`.

## 7. What the history shows

As of 2026-11-17: 36 PRs, all by the maintainer or bots, none from a fork, no review comments, no
issues. So there are no merge times or reviewer patterns for outside PRs yet; rerun to see:

```bash
gh pr list -R SPTApyo/nix-app-center --state all --limit 60 \
  --json number,state,author,isCrossRepository,title \
  --jq '.[] | "#\(.number) \(.state) \(.author.login) fork=\(.isCrossRepository) \(.title[0:60])"'
```

The maintainer's own PRs show the house style: one topic each, a body that lists each fix in one
sentence with the user-visible effect (SPTApyo/nix-app-center#31).

## 8. Our setup and current threads

- Clone: `~/Develop/github.com/SPTApyo/nix-app-center`, remotes `origin` = upstream, `fork` =
  `kleinbem/Nix-App-Center`.
- First outside PR: SPTApyo/nix-app-center#37 (attach kept out of a flake's own imports list),
  opened 2026-11-17.
- Downstream angle: the fleet's `nix-config` is a flake-parts flake with `nixosConfigurations`
  defined outside `flake.nix`. Found 2026-11-17 on v0.3.0: host detection needs the `host`
  setting there, and `attach` splices its NixOS modules into the flake-parts `imports` list,
  after which the flake no longer evaluates (`attribute 'pkgs' missing`).
- Not in nixpkgs yet; the repo carries the recipe it plans to submit (`nix/package.nix`,
  `docs/packaging.md`).

## Review checklist

- Diff within 400 lines and 10 files, one topic (`CONTRIBUTING.md`, Workflow 3).
- Every commit subject and the PR title pass `scripts/check-commit-msg.sh`.
- The fix has a unit test in `crates/core` that fails without it; error cases covered where
  files are written or commands run as root.
- No `#[allow(...)]`, no new dependency without need, comments within the length rules.
- New strings wrapped in `t()` and `po/` regenerated with `just pot`.
- Docs changed with the behaviour (`README.md`, `docs/design.md`, `docs/user-guide.md`).
- `nix develop -c just check` and `just cov` ran on the head; e2e named if the UI changed.
- No test or manual step touched the real configuration or ran a privileged command.
