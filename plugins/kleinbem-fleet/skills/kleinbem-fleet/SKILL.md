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
`nix-secrets`/`openwrt-secrets`), `kleinbem-site` (kleinbem.dev),
`kleinbem-auth` (visitor login service).

## Fleet-wide commands

Run from anywhere in the workspace; `filter` substring-matches repo names:

```
just status-all [filter]        # repo state + ahead-of-origin counts
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
