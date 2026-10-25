---
name: nixos-org
description: >-
  Organization skill for the NixOS GitHub organization (NixOS/nixpkgs, NixOS/nix, NixOS/nixos-hardware, NixOS/nixfmt, NixOS/nixpkgs-vet, ...): the two AI policies and which repos follow which, security reports, RFCs, the code of conduct, channels, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The NixOS organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Sources: `NixOS/.github` (`CODE_OF_CONDUCT.md`, `SECURITY.md`,
`SUPPORT.md`), each repo's `CONTRIBUTING.md`, nixos.org/community. As of 2026-10-21.

## 0. Two AI policies: check which one the repo follows

The org has no single policy file; the policies live in the repos, and they differ:

- **Nixpkgs and related projects** (`NixOS/nixpkgs` `CONTRIBUTING.md`, "Automation/AI policy";
  it covers "related projects under the jurisdiction of the Nixpkgs core team" and Nixpkgs
  development on Matrix and Discourse): a responsible human in the loop who reviews everything;
  non-trivial automation disclosed; for commits an `Assisted-by: <tool> (<model + version>)`
  trailer (`Co-authored-by` does not count); PR texts and review comments disclosed separately.
  Here the agent may draft texts that Martin reviews.
- **Nix** (`NixOS/nix` `CONTRIBUTING.md`, same policy plus one line): "Human communication must
  remain human. Pull request / issue descriptions and comments, documentation, commit messages,
  and code comments must be human-authored." **Martin writes every text there**, including code
  comments and commit messages; the agent researches, writes code and gives him facts as notes.
- Any other NixOS repo: look for an "Automation/AI policy" section; without one, apply the
  Nixpkgs policy (strictest common ground) and ask Martin.

## 1. Org-wide rules

- **Security:** never in a public issue. Email a member of the NixOS Security Team (addresses on
  nixos.org/community/teams/security.html; responses are GPG-signed). Martin sends it.
- **Large changes go through an RFC** (`NixOS/rfcs`): new subsystems, policy, anything
  cross-cutting. Nix asks first-time contributors to fix tightly scoped problems and to coordinate
  far-reaching changes with maintainers first; `idea approved` and `RFC` labels get priority.
- **Code of conduct:** Contributor Covenant, enforced by the moderation team.
- **Channels:** Discourse (discourse.nixos.org) for design discussion, Matrix rooms per area
  (`#nixos-hardware:nixos.org`, `#nix-formatting:nixos.org`, `#staging:nixos.org`, ...); decisions
  are recorded on GitHub. The Steering Committee (`NixOS/steering-committee`) sits above the teams.
- **Formatting:** `nixfmt` (RFC 166) is the official style in every Nix repo; `nix fmt` or the
  repo's treefmt.
- **No DCO sign-off** in nixpkgs or nix (their contributing guides have none).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| NixOS/nixpkgs | `nixpkgs-contributing`; `nixpkgs-maintaining` for maintainer work | Nixpkgs AI policy |
| NixOS/nix | none yet | **human-authored texts only**; C++; first PRs tightly scoped |
| NixOS/nixos-hardware | none yet | Matrix `#nixos-hardware:nixos.org`; relevant for our Jetson and Pi hardware modules |
| NixOS/nixfmt | none yet | ask on Matrix before touching `Predoc.hs` |
| NixOS/nixpkgs-vet | none yet | Rust; checks nixpkgs PRs (NPV codes) |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
