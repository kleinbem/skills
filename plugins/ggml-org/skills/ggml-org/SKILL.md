---
name: ggml-org
description: >-
  Organization skill for the ggml-org GitHub organization (ggml-org/llama.cpp, ggml-org/ggml, ggml-org/whisper.cpp, llama.vim, llama.vscode, ...): the AI usage policies that limit what an agent may do (Martin writes every text), where ggml changes go, security reports, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The ggml-org organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Sources: each repo's `CONTRIBUTING.md` and `AGENTS.md` (the org's
`.github` repo holds only its profile). As of 2026-10-21.

## 0. AI usage: the strictest org we contribute to

Every ggml-org repo we looked at restricts AI, and breaking the rules can mean a permanent ban.
The shared core (llama.cpp and whisper.cpp `CONTRIBUTING.md`, "AI Usage Policy"):
- **AI must not write posts:** bug reports, feature requests, PR descriptions, discussions,
  replies to humans; `AGENTS.md` adds commit messages and review replies. **Martin writes every
  text** that goes to GitHub; the agent gives him facts as notes, never paste-ready prose.
- **No automated commits, pushes or PR submissions.** The agent prepares the change and the
  checks; Martin commits, pushes and opens the PR.
- AI use in code must be disclosed (PR template line), reviewed manually, and Martin must be able
  to explain every line.
- **The policies differ in how much AI code is allowed:** llama.cpp allows AI-generated code that
  Martin fully reviews and owns; **whisper.cpp does not accept PRs that are "fully or
  predominantly AI-generated"** (AI only for corrections or repetitive expansions of what he
  already wrote; AI-generated then edited still counts as AI-generated). Check the repo's own
  section before writing any code for it.
- Fully autonomous agents must not contribute at all (llama.cpp `AGENTS.md`).

## 1. Org-wide facts

- **ggml changes go to llama.cpp:** `ggml-org/ggml` follows llama.cpp's contribution guidelines
  and asks for changes to the core ggml library (including its CMake build) as PRs to
  `ggml-org/llama.cpp`, where they are better tested and reviewed. ggml is synced from there.
- **Contributor levels** (whisper.cpp, same in practice for llama.cpp): contributors,
  collaborators (triage, own parts of the code via `CODEOWNERS`), maintainers (merge after code
  owner approval).
- **Security:** private advisory via the repo's Security tab where enabled; llama.cpp's
  `SECURITY.md` says its private program was disabled (2026-10-21) and fixes go in as public PRs.
  Read the repo's `SECURITY.md` before reporting anything.
- **Channels:** issues, PRs and GitHub Discussions; no chat channel is linked.
- **No DCO or CLA.**

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| ggml-org/llama.cpp | `llama-cpp-contributing` | AI code allowed with disclosure; texts by Martin; also the place for ggml changes |
| ggml-org/ggml | none (use llama.cpp's) | send core changes to llama.cpp |
| ggml-org/whisper.cpp | none yet | **no predominantly AI-generated PRs** |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
