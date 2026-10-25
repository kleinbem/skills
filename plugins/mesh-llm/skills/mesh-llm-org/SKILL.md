---
name: mesh-llm-org
description: >-
  Organization skill for the Mesh-LLM GitHub organization (Mesh-LLM/mesh-llm, mesh-packaging, homebrew-tap, mesh-app, the llama.cpp fork, ...): security reports, channels, attribution rules, how the repos relate, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The Mesh-LLM organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Sources: `Mesh-LLM/mesh-llm` (`CONTRIBUTING.md`, `AGENTS.md`,
`SECURITY.md`), `Mesh-LLM/mesh-packaging` (`AGENTS.md`); the org's `.github` repo holds only its
profile. As of 2026-10-25.

## 0. Attribution

**No agent or bot attribution trailers** in commits or the squashed PR message (mesh-llm's hook
and CI reject `Co-Authored-By: Claude …`, `[bot]` accounts and relay identities). AI help may be
stated in the PR text. Assume the same for every Mesh-LLM repo until a repo says otherwise.

## 1. Org-wide facts

- Mesh-LLM is its own organization, not Block and not goose, though people overlap with both.
- **Security:** GitHub private vulnerability reporting (the repo's Security tab, or
  `/security/advisories/new`); no public issues or details before a fix is released.
- **Channels:** the goose Discord, `#mesh-llm` channel (`discord.gg/n8R5VaWDAn`); the `goose-oss`
  invite in the mesh-llm repo is dead.
- **Office hours:** the core team's weekly notes are a public Google Doc
  (`https://docs.google.com/document/d/101iitJTVFba6wpcBFXfdwYQngPV5gEliYOy-Hq4NbVo`, readable via
  `/export?format=txt`), with an async "Suggested/requested items" section. Read-only:
  it's their document, and Martin doesn't add items there (2026-10-22).
- **How the repos relate:** `mesh-llm` is the product (MeshLLM host + Skippy runtime) and moves
  several times a day. Skippy pins an upstream `ggml-org/llama.cpp` commit in
  `skippy/llama_cpp/upstream.txt` and applies its own patch queue; the `Mesh-LLM/llama.cpp` fork
  holds experiment branches (last pushed 2026-08-30) and is not where fixes go. `mesh-packaging`
  owns distribution (Docker images, native packages, Homebrew via `homebrew-tap`); its scripts are
  TypeScript/Node. Distribution-specific changes (Nix, Arch/AUR) belong downstream unless they
  replace fragile patching. Default plugins live in their own repos (capsules:
  `Mesh-LLM/capsules`); the mesh-llm release bundles each one's pinned release archive under
  `plugins/` (#2546, #2520).
- **No DCO sign-off;** Conventional Commits; CodeRabbit reviews mesh-llm PRs and expects answers.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| Mesh-LLM/mesh-llm | `mesh-llm-contributing` | pre-flight CI in kleinbem/mesh-llm-ci |
| Mesh-LLM/mesh-packaging | none yet | install paths, distro packages; our nixpkgs/AUR work touches it |
| Mesh-LLM/homebrew-tap, mesh-app, the llama.cpp fork | none yet | |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
