---
name: alsa-project-org
description: >-
  Organization skill for alsa-project (Advanced Linux Sound Architecture: alsa-lib, alsa-utils, alsa-ucm-conf): security, PR workflow, licensing, and repository table.
disable-model-invocation: true
---

# The alsa-project organization

Layer 2 of 3: read after `upstream-contributing`, before repository skills (`alsa-ucm-conf-contributing`).
The repository skill wins where they differ.

Sources of truth: `alsa-project/alsa-ucm-conf` repository history and PR review threads. As of 2026-11-13.

## 0. Org-wide hard rules

- **AI Policy:** No explicit ban on AI assistance; contributions must be verified on hardware or against
  ALSA parser rules (`alsaucm -c ... reload`). Standard disclosure line acceptable.
- **Licensing:** BSD-3-Clause for `alsa-ucm-conf`.
- **Commits:** Conventional ALSA commit titles: `ucm2: <subsystem>: <device>: <imperative summary>`.
  Signed-off-by (DCO) is customary in ALSA kernel/userspace projects.

## 1. Org-wide facts

- **Channels:** GitHub Pull Requests and Issues, plus the `alsa-devel@alsa-project.org` mailing list.
- **Maintainers:** Jaroslav Kysela (`perexg`) reviews and merges PRs.

## 2. Repositories

| Repo | Repository skill | Notes |
|---|---|---|
| alsa-project/alsa-ucm-conf | `alsa-ucm-conf-contributing` | ALSA Use Case Manager configuration files (ucm2) |
| alsa-project/alsa-lib | (org skill only) | ALSA userspace library |
| alsa-project/alsa-utils | (org skill only) | Command-line audio utilities (alsamixer, aplay, amixer) |
