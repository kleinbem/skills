---
name: kleinbem-fleet
description: >-
  Orientation for the kleinbem NixOS + OpenWrt fleet: the three conductors,
  what every repo is for, the fleet-wide `just` fan-out, where new IaC goes,
  the master inventory, and the standalone-container model. Load before
  working anywhere under ~/Develop/github.com/kleinbem.
---
# kleinbem fleet

The workspace root's `AGENTS.md` (always loaded) has the rules every session follows: own jj
workspace, auto-merging PRs, comments, secrets. This skill is the map.

## The three conductors

Orchestrators with no `flake.nix` of their own (except `kleinbem/`, which packages the
dashboard):

- **`kleinbem/`**: fleet hub. Owns `repos.nix` (every repo + its GitHub URL, the single source of
  truth), the canonical `.just/common.just` + `.just/jj.just` (symlinked into `nix/` and
  `openwrt/`), the workspace root's own files in `root/`, and `tools/jj-fleet.sh` (the
  dashboard, which fans out to `jj-toolbox` scripts instead of reimplementing them).
- **`nix/`**: conductor for the Nix side. Real work: `nix-config` (hosts, modules, inventory;
  start here for NixOS questions), `nix-presets` (shared service/desktop bundles),
  `nix-hardware`, `nix-devshells`, `nix-packages`, `nix-templates`. Also owns `nix/infra/`, the
  live OpenTofu for Cloudflare, GitHub secrets, Google, NetBird and Garage.
- **`openwrt/`**: conductor for the router side. Real work: `openwrt-builder` (firmware images,
  profile `bpi-r4`) and `openwrt-config` (Ansible runtime config).

## Other repos

The main ones; `kleinbem/repos.nix` lists every repo.

| Repo | What it is |
|---|---|
| `github-config` | Terraform for GitHub account/repo settings, rulesets, labels |
| `kleinbem-secrets` | sops + age secrets for the whole fleet, per-path recipients (see its README) |
| `jj-toolbox` | Single-repo jj helpers (`jj-save`, `jj-push`, `jj-pull`, `jj-abandon-merged`, `jj-sign-unsigned`, `jj-check-signatures`, `jj-sweep-merged`, `jj-ahead`, `jj-ws-*`); run in whatever repo you're in |
| `nix-toolbox` | Generic flake tools (`nix-check-versions`, `nix-audit-deps`, `nix-audit-locks`, `nix-verify-devshells`, `nix-check-lock`, `nix-check-workarounds`, `bash-test-lib.sh`) |
| `actions` | Shared composite GitHub Actions; `nix-setup` installs Determinate Nix and, with the secrets, joins NetBird for the mesh-only Attic cache. Pinned by sha, Dependabot bumps it |
| `skills` | These agent skills (Claude Code plugin marketplace) |
| `kleinbem-site` | kleinbem.dev |

`nix-secrets` and `openwrt-secrets` are retired (not in `repos.nix`, not on disk).

## Fleet-wide commands

Run from the workspace root, every recipe below works as written. `nix/` and `openwrt/` expose
only some at the top level (status-all, save-all, pull-all, push-all, ship-all, in);
use `just jj::<recipe>` there for the rest. `filter` substring-matches repo names fleet-wide
(`just status-all nix` hits every `nix*` repo). No filter = every repo.

```bash
just                              # interactive hub (fzf/gum)
just status-all [filter]          # repo state + ahead-of-origin counts
just clean [filter] [--local] [--strict]  # dirty / unpushed / conflicts / workspaces / PRs / issues / branches / Claude rule files
just abandon-merged [filter] [--dry-run]  # drop local copies of changes already on main
just diff-all [filter]            # uncommitted changes
just remote-status [filter]       # CI, PRs, issues (gh API, ~6s)
just remote-prs [filter]          # open PRs
just remote-ci [n] [filter]       # recent CI runs per repo
just check-signatures [filter]    # signatures ahead of origin
just save-all "msg" [filter]      # jj describe in every dirty repo
just push-all [filter]            # push every repo
just pull-all [filter]            # fetch + rebase every repo, then abandon-merged
just sign-unsigned [filter]       # sign unsigned commits ahead of origin (YubiKey)
just ship-all "msg" [filter]      # save-all + sign-unsigned + push-all (alias: ship)
just bootstrap [filter]           # clone missing repos from repos.nix, link the root files
just init-bookmarks [filter]      # point local main at main@origin (once per repo)
just in <repo> <recipe>           # run a repo's own recipe, e.g. just in nix-config nixos::switch
```

- Fresh machine: `just bootstrap`. From a fresh clone of only `nix/` or `openwrt/`, run
  `bash tools/bootstrap.sh` there first: `just` can't parse until `kleinbem/` exists.
- Tests for the fan-out tooling (`kleinbem/tools/resolve-targets.sh` and friends):
  `cd kleinbem && just test`.

## Pull request policy details

- Required checks are non-strict (github-config), so a PR that fell behind main still merges.
- Private repos (kleinbem-secrets, mesh-llm-gpu) auto-merge too but don't require CodeRabbit.
- `skills` requires its `check` job (skill structure + `claude plugin validate`; `just check`
  locally).
- jj pushing, bookmarks and rebasing PR branches: `jj-workflow`.

## Where new IaC goes

- **Self-contained** (no dependency on another repo's generated data): its own repo, like
  `github-config`.
- **Data-bridge-coupled** (consumes files generated from another repo's source of truth): next to
  that source, so the bridge is an in-repo path. `nix/infra/` is the example:
  `nix-config/iac/data.nix` generates `infra/personas.json` + `infra/inventory.json` from
  `inventory.nix`/`personas.nix`, and the `.tf` roots read them by path.

Don't give every IaC root its own repo by default: splitting a coupled root turns a same-repo
file dependency into a cross-repo one that drifts silently.

## Workarounds link their report

Same rule as in nixpkgs: every workaround or fix for someone else's bug (a patch, an override,
a pin, `doCheck = false`, a blacklisted module, a feature switched off) gets a comment with a
link to the upstream issue or PR it waits on: a URL or `owner/repo#123`. That link is how the
workaround gets dropped when the fix arrives.
- No report yet: draft one in the same session through `upstream-contributing` (a new project
  first gets its contribution skill; the skill decides issue, PR or both). Martin files or
  approves it. Until it exists, open an issue in our repo ("report upstream: …") and link that.
- Our own workarounds (waiting on another fleet change) link our own issue.
- A comment that only mentions a workaround says `no-link: <why>`.
- Check with `nix-check-workarounds` (kleinbem/nix-toolbox; the workspace devshell puts the
  checkout's `bin/` on PATH): `--base main@origin` before a PR (CodeRabbit flags it too);
  `nix-check-workarounds --states <repo>` lists linked fixes that are merged or closed, so the
  workaround can go. Run it when a flake or package update comes in.
- Never use closing keywords before external links: never write any closing keyword variant
  (`close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved`,
  with or without colon) before external repository references (`owner/repo#123` or full
  GitHub URLs) in code comments, commit messages, or PR bodies. GitHub closes the upstream
  issue/PR on merge. Write `upstream: owner/repo#123` or `tracking: owner/repo#123`.

## nix-config specifics

- Auto-generated ground truth, refreshed by `just dev::sync-agent` (in nix-config):
  `docs/INFRASTRUCTURE.yaml` (whole fleet, symlinked at the workspace root),
  `docs/OPTIONS.md` (every `my.*`/`modules.*` option, declaration site, opted-in hosts),
  `docs/IMPORTS.md` (per-host import map), `docs/SYSTEM_REFERENCE.md` (nixpkgs revs, hosts,
  services). Grep these first to see blast radius.
- Every option lives under `my.*` (system) or `modules.*` (home-manager). Hosts default to
  `enable = false` and must opt in.
- `inventory.nix` is the master source for **both** NixOS and OpenWrt;
  `openwrt-config/ansible/inventory.ini` is generated from it, never hand-edited.
- NixOS hosts only see a merged kleinbem-secrets change after nix-config's lock moves, and that is
  always a hand bump: Maintain Flake skips the input (private, CI has no token) and refuses it
  when asked. In a nix-config workspace run
  `NIX_CONFIG="access-tokens = github.com=$(gh auth token)" nix flake update kleinbem-secrets`,
  build `system.build.sops-nix-manifest` for the hosts it touches, then open the PR. Routers
  read the sibling `kleinbem-secrets/` checkout instead (`playbook_dir/../../`), which only
  resolves from the primary `openwrt-config/`, not a `.ws` workspace: run
  `just pull-all kleinbem-secrets` from the workspace root, then `just configure <target>` in
  `openwrt-config/`.

## Standalone containers (ADR-002)

No host evals its own container closures. `container-factory` builds them centrally; hosts pull
to `/var/lib/machines/<name>/current`. Adding a deployed container = 3 edits: preset in
`nix-presets`, host `containers.nix` opt-in, `container-factory` import + catalogue entry.

## Device skills

Device guides are manual skills, out of the context until needed. When a task is about one of
these devices, read its file (`~/.agents/skills/<name>/SKILL.md`); Martin can also run `/<name>`.

| Device | Skill |
|---|---|
| Huawei MatePad Pro (MRX-W09) tablet | `matepad-pro` |
