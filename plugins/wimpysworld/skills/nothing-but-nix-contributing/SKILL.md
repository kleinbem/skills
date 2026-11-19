---
name: nothing-but-nix-contributing
description: Use when preparing an issue or PR for wimpysworld/nothing-but-nix (GitHub Action that purges runner bloat into a compressed btrfs /nix); covers CONTRIBUTING.md (AI policy, Conventional Commits), AGENTS.md (code and docs rules, lint script, dispatch-only tests), the issue templates, and how we use the action in kleinbem/nix-config.
disable-model-invocation: true
---

# wimpysworld/nothing-but-nix Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `wimpysworld-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to nothing-but-nix and
wins where they differ.

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (long and exact: it documents every
step, input and test job), `SECURITY.md`, `SUPPORT.md`, `.github/ISSUE_TEMPLATE/{bug_report,feature_request,config}.yml`,
`.github/workflows/{test,debug}.yaml`, `.github/scripts/`, `.tailor.yml`. No PR template, no
`CODEOWNERS`. Summary as of 2026-11-19.

MIT, about 260 stars, one maintainer (`@flexiondotorg`) who writes most changes himself. Releases
are major tags (`v11`, `v12`), pinned by SHA in our workflows.

## 0. Hard rules that decide the agent's role

`CONTRIBUTING.md`, "AI-assisted contributions" (quoted where it binds us):
- AI help is allowed for code, docs "and GitHub communication", with "a responsible person in the
  loop who reviews and understands it before submission and remains accountable for it". So the
  agent drafts, Martin reviews and posts.
- "Answer questions about your contribution and respond to feedback yourself, without relaying
  messages between reviewers and AI tools." Martin answers review comments himself; the agent can
  give him facts, not paste-ready replies to relay.
- "Do not add an AI identity to `Signed-off-by` or `Co-authored-by` trailers." No
  `Co-Authored-By: Claude` on commits here.
- Disclosure is optional: "You may disclose material AI assistance with an `Assisted-by:`
  trailer, for example `Assisted-by: tool:model`." Use `Assisted-by: Claude Code:<model>` on
  commits the agent wrote.
- Commits follow Conventional Commits; merged PRs are squashed with the PR title (`feat: … (#66)`).

## 1. Before starting

- Issues: blank issues are off. Bugs use `bug_report.yml` (required: steps to reproduce,
  expected, actual, version; checkboxes "searched existing issues" and "provided all the
  requested information"). Features use `feature_request.yml`.
- Scope is narrow on purpose: one btrfs path, no other filesystems (#55 bcachefs closed: "outside
  the scope"). Keep a proposal to the existing protocols and inputs.
- Security bugs go to private reporting, never an issue.

## 2. Designing the change

- `AGENTS.md` is the spec and must change with the code: it describes every step, input, output,
  test job and floor in prose. A change to `action.yml` updates `AGENTS.md` and, for inputs or
  behaviour, `README.md` (including the protocol table).
- Bash in `action.yml`: lowercase variables, quote every path, `rmz` (not `rm`) for large trees,
  Bash 3.2 only in the macOS purge and The Post (rampage removes Homebrew's Bash 5).
- `TMPDIR` must stay outside `/nix` (#24, #57).
- Protocols: holster (0), carve (1), cleave (2), rampage (3); cleave moves `/usr/local` to
  `/usr/local.purge` and recreates only `bin doc include lib man sbin share src` (#9, #53).

## 3. Building and validating

- Lint before pushing: `nix develop --command .github/scripts/lint.sh` (actionlint, shellcheck on
  the scripts and on every Bash body in `action.yml`).
- The action can't run locally. Test on runners with `gh workflow run test.yaml` on the fork
  (every protocol, Ubuntu 24.04/26.04 x64 and arm64, macOS); `debug.yaml` for space reports. The
  `👁️ Sentinel` job sums up the matrix and is the required check.

## 4. Commits and pull requests

- Conventional Commits title, a short body saying what and why, measured numbers where space or
  time changes (#53: "cleave takes about 1s with this pr vs 70s before").
- `Assisted-by:` trailer on agent-written commits, nothing else (see 0).

## 5. What the history shows

Measured 2026-11-19 (`gh pr list -R wimpysworld/nothing-but-nix --state merged --limit 60 …`):
- Outside PRs merged after 3 h to 62 days (#46 3 h, #30 69 h, #34 95 h, #53 541 h, #52 1495 h).
- Closed unmerged: #55 (out of scope), #54 (withdrawn).
- Bug issues get a maintainer fix and a closing comment that states what changed (#57).

## 6. Our setup and current threads

- Used in kleinbem/nix-config `build-nvme.yaml` (`hatchet-protocol: carve`, `root-safe-haven:
  '16384'`) since nix-config#892. Cleave broke our CA install because it deletes
  `/usr/local/share/ca-certificates`, which Ubuntu's `ca-certificates` package ships and
  `update-ca-certificates` reads; our side is fixed in kleinbem/actions#33.
- No fork or clone yet.

## Review checklist

- `AGENTS.md` and `README.md` updated in the same PR as any `action.yml` change (section 2).
- `.github/scripts/lint.sh` clean; `test.yaml` green on the fork for every protocol (section 3).
- No AI identity in `Co-authored-by`/`Signed-off-by`; `Assisted-by:` only (section 0).
- Bash 3.2 compatibility in macOS steps; paths quoted; `rmz` for big deletes (section 2).
- Issue uses the template fields, including version (section 1).
