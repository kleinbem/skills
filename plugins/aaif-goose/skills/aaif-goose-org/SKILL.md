---
name: aaif-goose-org
description: Organization skill for the aaif-goose GitHub organization (aaif-goose/goose, goose-mobile, vscode-goose, goosetown): goose's move from Block to the Agentic AI Foundation, governance, security reports, channels, and the repo table. Read after upstream-contributing, before the repository skill.
disable-model-invocation: true
---

# The aaif-goose organization

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Sources: `aaif-goose/goose` `GOVERNANCE.md`, `MAINTAINERS.md`,
`SECURITY.md`, `README.md` (the org has no `.github` repo). As of 2026-10-21.

## 0. Not Block anymore, but still in transition

- goose moved from `block/goose` to `aaif-goose/goose` and is part of the **Agentic AI Foundation
  (AAIF) at the Linux Foundation**. Old `block/goose` links redirect. `block-org` does not apply:
  no Block DCO check, no Block governance.
- The move isn't finished everywhere: `vscode-goose`'s `GOVERNANCE.md` still links Block's
  governance page, and goose's `SECURITY.md` escalation address is still
  `open-source-governance@block.xyz` under the AAIF name. Treat the goose repo's own files as
  current and don't cite Block policy for aaif-goose repos.

## 1. Org-wide facts

- **Governance** (`GOVERNANCE.md`): contributors; maintainers own components and review;
  core maintainers set direction and resolve escalations (listed in `MAINTAINERS.md`, e.g.
  baxen, DOsinga, jamadeo, jh-block, lifeizhou-ap, michaelneale). Work is planned in the open on
  the Goose Issues project board; nothing is built without an issue that reached "Ready"
  (details in `goose-contributing`).
- **Security:** private report via the repo's Security tab → "Report a vulnerability"; never a
  public issue. Martin files it.
- **Channels:** the goose Discord (`discord.gg/n8R5VaWDAn`, shared with Mesh-LLM's `#mesh-llm`)
  and GitHub Discussions; decisions belong in the issue.
- **No DCO sign-off;** AI use needs no disclosure; Conventional Commits PR titles (goose).

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| aaif-goose/goose | `goose-contributing` | issues first, Ready before a PR |
| aaif-goose/vscode-goose | none yet | governance file still points to Block |
| aaif-goose/goose-mobile | none yet | |

A repo with "none yet" gets its repository skill before our first contribution
(`upstream-contributing`, "First contact").
