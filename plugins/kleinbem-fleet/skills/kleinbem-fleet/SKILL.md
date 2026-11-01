---
name: kleinbem-fleet
description: >-
  Orientation for the kleinbem NixOS + OpenWrt fleet: the workspace root is
  not a repo, the three conductors, fleet-wide `just` fan-out, jj-first VCS,
  the master inventory, and the standalone-container model. Load before
  working anywhere under ~/Develop/github.com/kleinbem.
---
# kleinbem fleet

## The workspace root is not a repo

`~/Develop/github.com/kleinbem/` is a flat directory of ~15 independent
sibling git+jj repos (no submodules). `cd` into the specific repo before
doing real work — each has its own `AGENTS.md`/`CLAUDE.md` with the detail
that matters. The root is only for orientation and fleet-wide fan-out.

## The three conductors

Tooling-only orchestrators, no `flake.nix` of their own (except `kleinbem/`):

- **`kleinbem/`** — fleet hub. Owns `repos.nix` (every repo + its GitHub
  URL), the canonical `.just/common.just` + `.just/jj.just`, and
  `tools/jj-fleet.sh` (dashboard).
- **`nix/`** — conductor for the Nix side. Real work: `nix-config` (hosts,
  modules, inventory — start here for NixOS questions), `nix-presets`
  (shared service/desktop bundles), `nix-hardware`, `nix-devshells`,
  `nix-packages`, `nix-templates`.
- **`openwrt/`** — conductor for the router side. Real work:
  `openwrt-builder` (firmware images, profile `bpi-r4`) and
  `openwrt-config` (Ansible runtime config).

Other repos: `github-config` (Terraform-managed GitHub org settings),
`kleinbem-secrets` (current sops+age secrets store — replaces the legacy
`nix-secrets`/`openwrt-secrets`), `kleinbem-site` (kleinbem.dev).

## Work in your own jj workspace, always

Every agent session that edits a repo claims its own jj workspace first;
the primary checkout (`<repo>/`) is Martin's. Sessions sharing one working
copy destroy each other's edits (jj snapshots `@` on every command), and
sessions that finish in the primary checkout leave commits, bookmarks and
half-edits behind — a clean-up on 2026-10-24 found 71 of those.

```
just jj::ws-new <repo> [name]              # <repo>.ws/<name>/ on main — cd there, then work
just jj::ws-new <repo> <name> -r <change>  # start on an existing change (move work out of the primary)
just jj::ws-list [filter]                  # open workspaces and their @ state
just jj::ws-gc [filter]                    # reap empty/undescribed ones older than 4h
```

Inside a workspace use `jj`, never raw `git` (no `.git` there); `jj git
push` and `gh pr create` work from it. Finish from the workspace: describe,
push, open the PR. After the merge, `ws-gc` reaps the workspace and
`just pull-all` / `just abandon-merged` drops the local copy of the merged
change. If "working copy is stale" appears, `jj workspace update-stale`.

## Fleet-wide commands

Run from anywhere in the workspace; `filter` substring-matches repo names:

```
just status-all [filter]        # repo state + ahead-of-origin counts
just clean [filter]             # all-clean check: dirty / not in main / conflicts / workspaces / PRs / branches
just abandon-merged [--dry-run] # drop local copies of changes already on main (proven only)
just diff-all [filter]          # uncommitted changes fleet-wide
just remote-status [filter]     # CI / PRs / issues (hits gh API)
just ship-all "msg" [filter]    # save-all + sign-unsigned + push-all
just in <repo> <recipe>         # pass through to one repo's justfile
                                #   e.g. just in nix-config nixos::switch
```

## VCS is jj-first

Jujutsu is the primary interface (colocated with git). Use raw `git` only
for rescue / destructive resets not wrapped by the `jj::*` recipes. A bare
`jj git push` no-ops here — push via `just jj::push-all <filter>` from a
conductor. When no YubiKey is attached, avoid `jj` entirely: it
auto-snapshots the working copy into a *signed* commit on nearly every
command. Use plain `git` edits instead.

## Code comments

A comment says why the code is this way, in 1–3 lines. History ("was X,
replaced with Y"), dates, debugging stories and alternatives tried go in
the commit message or PR body, not the file. Keep real gotchas, short.
When you edit near a long comment, shorten it too.

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
- Check: `nix-check-workarounds --base main@origin` before a PR (CodeRabbit flags it too);
  `nix-check-workarounds --states <repo>` lists linked fixes that are merged or closed, so the
  workaround can go. Run it when a flake or package update comes in.

## nix-config specifics

- Auto-generated ground-truth, refreshed by `just maintenance::sync-agent`:
  `docs/OPTIONS.md` (every `my.*`/`modules.*` option + declaration site +
  opted-in hosts), `docs/IMPORTS.md` (per-host import map),
  `docs/SYSTEM_REFERENCE.md` (nixpkgs revs, hosts, services). Grep these
  first to see blast radius.
- Every option lives under `my.*` (system) or `modules.*` (home-manager).
  Hosts default to `enable = false` and must explicitly opt in.
- `inventory.nix` is the master source for **both** NixOS and OpenWrt;
  `openwrt-config/ansible/inventory.ini` is generated from it — never
  hand-edited.

## Standalone containers (ADR-002)

No host evals its own container closures. `container-factory` builds them
centrally; hosts pull to `/var/lib/machines/<name>/current`. Adding a
deployed container = 3 edits: preset in `nix-presets`, host
`containers.nix` opt-in, `container-factory` import + catalogue entry.

## Secrets

`kleinbem-secrets` = sops + age, per-path scoped recipients. Never assume a
plaintext file in a `*-secrets` repo is safe to read/edit/reference just
because the repo is "the encrypted one" — verify first.

## Environment

Each repo's `.envrc` loads a Nix devshell via direnv, ultimately
`nix-devshells#workspace` (or `#openwrt`), providing `just`, `jj`, `gh`,
`gum`, `sops`, `age`. If a tool seems missing from PATH, the devshell
probably isn't loaded — check `direnv status` / `direnv allow`.

## Device skills

Device guides are manual skills, out of the context until needed. When a task is about one of
these devices, read its file (`~/.agents/skills/<name>/SKILL.md`); Martin can also run `/<name>`.

| Device | Skill |
|---|---|
| Huawei MatePad Pro (MRX-W09) tablet | `matepad-pro` |
