---
name: archlinux-org
description: >-
  Organization skill for Arch Linux (the AUR, the official repositories, the ArchWiki, RFCs): the missing AI policy and what we do instead, governance, channels, licensing of package sources, and the repo table. Read after upstream-contributing, before aur-contributing.
disable-model-invocation: true
---

# Arch Linux

Layer 2 of 3: read after `upstream-contributing`, before the repository skill; the repository
skill wins where they differ. Arch Linux isn't a GitHub organization: its rules live in the
ArchWiki (wiki.archlinux.org), the developer manual (manual.archlinux.page), the RFCs
(rfc.archlinux.page) and the service agreements (terms.archlinux.org); code and official
packaging are on gitlab.archlinux.org. As of 2026-10-22.

## 0. AI use: no policy, so our own rule

- **No project-wide AI policy.** An Arch admin (gromit) on the forum, 2026-06-29: "currently there
  is no policy on this topic for the overall project", some subprojects (buildbtw) have their own,
  and "a few people currently are working towards an RFC". An ArchWiki talk page proposes an
  "AI-assisted packaging tools" section; not adopted. Recheck before every contribution: the RFC
  list (rfc.archlinux.page, open MRs on gitlab.archlinux.org/archlinux/rfcs) and the forum.
- **The community is wary:** forum threads (March 2026) mention AUR mass deletions and distrust of
  PKGBUILDs "verified" by AI. A package that looks generated and unreviewed is easy to delete.
- **Our rule until a policy exists:** the agent drafts and builds PKGBUILDs; Martin reviews every
  line, is the git author and pushes himself. Comments, emails, forum and mailing-list posts are
  written by Martin. No AI disclosure is required anywhere; Martin decides per change whether to
  mention it. No agent trailers in AUR commits (AUR history can't be rewritten after a push).

## 1. Org-wide facts

- **Code of conduct:** terms.archlinux.org/docs/code-of-conduct/ applies to the forums, mailing
  lists, IRC, the wiki and the AUR.
- **Governance:** Developers maintain `core`; **Package Maintainers** (formerly Trusted Users)
  maintain `extra`, review AUR requests and can delete AUR packages. Larger changes go through
  RFCs (rfc.archlinux.page); e.g. 0040 (license package sources under 0BSD), 0046 (prefer
  transparent, verifiable upstream sources), 0016 (SPDX license identifiers).
- **Package sources are 0BSD** (RFC 0040). AUR packages without a license file (or with another
  license) aren't eligible for promotion to `extra`.
- **Channels:** the aur-general mailing list (also security warnings; worth following), the
  "Creating & Modifying Packages" forum, IRC `#archlinux-aur` on Libera Chat. aur-requests is the
  list where deletion, merge and orphan requests land.
- **Security:** AUR packages carry no vetting ("use at your own risk"); malicious AUR packages are
  announced on aur-general and archlinux.org/news. Official packages: the security tracker
  (security.archlinux.org).
- **From the AUR to `extra`:** a Package Maintainer adopts a package; votes, a compatible license
  and clean packaging count. Precedent for our area: `extra/ollama` (split package by svenstaro).

## 2. Repositories

| Where | Repository skill | Notes |
|---|---|---|
| AUR (aur.archlinux.org, one git repo per pkgbase) | `aur-contributing` | where we contribute; our PKGBUILDs live in kleinbem/aur-packages |
| Official packaging (gitlab.archlinux.org/archlinux/packaging/packages) | none yet | only Package Maintainers push; we'd go through issues there |
| ArchWiki | none yet | has its own contribution rules (ArchWiki:Contributing) |
