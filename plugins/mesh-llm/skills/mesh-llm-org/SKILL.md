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
profile. As of 2026-11-03; plugin repos 2026-11-18; mesh-llm/Skippy split and SDKs 2026-11-28.

## 0. Attribution

**No agent or bot attribution trailers** in commits or the squashed PR message: no
`Co-Authored-By: Claude …`, `[bot]` accounts or relay identities. mesh-llm's hook and CI check
are retired (its `CONTRIBUTING.md`: "CI does not police titles or attribution identities"), but
the rule stands, so check by hand. AI help may be stated in the PR text. Assume the same for
every Mesh-LLM repo until a repo says otherwise.

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
- **How the repos relate:** `mesh-llm` is the product host and moves several times a day. Skippy
  (the inference runtime, CLI, and `llama.cpp` patch queue) now lives in its own public repository
  `Mesh-LLM/skippy` (transferred in `Mesh-LLM/skippy#108`, consumed externally by `mesh-llm` in
  `Mesh-LLM/mesh-llm#3193`, merged 2026-11-28): mesh-llm pins Skippy's crates.io release exactly
  and downloads its published runtime, with no Skippy source left in the tree. Skippy pins an upstream `ggml-org/llama.cpp` commit in
  `llama_cpp/upstream.txt` and applies its own patch queue; the `Mesh-LLM/llama.cpp` fork
  holds experiment branches (last pushed 2026-08-30) and is not where fixes go. `mesh-packaging`
  owns distribution (Docker images, native packages, Homebrew via `homebrew-tap`); its scripts are
  TypeScript/Node. Distribution-specific changes (Nix, Arch/AUR) belong downstream unless they
  replace fragile patching. Plugins live in their own `*-plugin` repos (capsules:
  `Mesh-LLM/capsules-plugin`), most on the `Mesh-LLM/example-plugin` CI standard; they depend
  on `mesh-llm-plugin` by git rev, since crates.io stops at 0.78.1. Releases up to 0.78 bundled
  default plugins under `plugins/` (#2546, #2520); #2977 stopped that for 0.79, and users get
  them from the Hugging Face catalog `meshllm/plugin-catalog`. All five SDKs, Python included
  (`mesh/sdk/python`), are maintained inside mesh-llm (its `AGENTS.md`, "SDK parity invariant");
  `Mesh-LLM/mesh-llm-python-sdk` was last pushed 2026-11-13.
- **No DCO sign-off** except in capsules-plugin (`dco` check); Conventional Commits; CodeRabbit reviews mesh-llm PRs and expects answers.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| Mesh-LLM/mesh-llm | `mesh-llm-contributing` | Martin has write access since 2026-11-01 (PR branches upstream, `kleinbem/<topic>`); pre-flight CI in kleinbem/mesh-llm-ci |
| Mesh-LLM/skippy | `skippy-contributing` | Skippy inference runtime, CLI, `llama.cpp` patch queue; public fork PRs need workflow approval and must pass the `PR checks` acceptance-criteria gate |
| Mesh-LLM/mesh-packaging | `mesh-packaging-contributing` | repackages release archives only (deb, Arch, OCI, Homebrew, npm); bundle contents are fixed in mesh-llm |
| Mesh-LLM/mesh-llm-python-sdk | `mesh-llm-python-sdk-contributing` | Python SDK and compatibility clients; mesh-llm now keeps its Python SDK in-tree (`mesh/sdk/python`), so check this repo's role before a PR |
| Mesh-LLM/capsules-plugin | `capsules-plugin-contributing` | the capsules plugin; run by Ethan Zhang's agent through issue claims; DCO required |
| Mesh-LLM/openai-endpoint-plugin | `openai-endpoint-plugin-contributing` | attaches an external OpenAI-compatible server; small, few PRs |
| Mesh-LLM/homebrew-tap, mesh-app, the llama.cpp fork, the other `*-plugin` repos | none yet | |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
