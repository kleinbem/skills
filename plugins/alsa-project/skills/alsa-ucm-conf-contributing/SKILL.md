---
name: alsa-ucm-conf-contributing
description: Contributing to alsa-project/alsa-ucm-conf; covers UCM2 syntax, Qualcomm x1e80100 audio profiles, DMI matching, validation, and PR drafting.
disable-model-invocation: true
---

# alsa-project/alsa-ucm-conf Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `alsa-project-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `alsa-ucm-conf` and wins
where they differ.

Sources of truth: `README.md`, `ucm2/README.md`, recent PRs #900, #905, #906. As of 2026-11-13.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Standard workflow. Agent drafts, Martin reviews and approves. One disclosure line in the PR.
- **Commits:** One logical machine/profile per commit: `ucm2: Qualcomm: x1e80100: add <Model> profile`.
  Sign-off (`Signed-off-by: Martin Kleinberger <martin.kleinberger@gmail.com>`) included.
- **PR Titles:** Clear imperative summary: `ucm2: Qualcomm: x1e80100: add Acer Aspire 16 AI, ASUS ProArt PZ13 and Surface Laptop 13 profiles`.

## 1. Before starting

- Check existing tree under `ucm2/Qualcomm/x1e80100/` for conflicting DMI matches or existing profiles.
- Verify DMI regex match strings against actual `/sys/class/dmi/id/` attributes.

## 2. Profile Structure for Qualcomm Snapdragon X Elite (x1e80100)

- Dispatcher: `ucm2/Qualcomm/x1e80100/x1e80100.conf`
  - Evaluates `If.<DeviceName>` using `RegexMatch` against `${var:DMI_info}`.
  - Includes top-level device config: `True.Include.<device>.File "/Qualcomm/x1e80100/<Device>.conf"`.
- Top-level device conf (`<Device>.conf`):
  - Defines SectionUseCase `HiFi` and includes `<Device>-HiFi.conf`.
- HiFi conf (`<Device>-HiFi.conf`):
  - Defines `SectionVerb` (boot/shutdown sequence, mixer controls).
  - Defines `SectionDevice` for Speaker, Mic, Headset, DisplayPort.

## 3. Validation

- Validate syntax with `alsaucm`:
  ```bash
  alsaucm -c x1e80100 reload
  ```
- Or run the repository syntax check workflow locally.
