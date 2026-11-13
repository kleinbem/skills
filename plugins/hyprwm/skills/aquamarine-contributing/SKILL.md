---
name: aquamarine-contributing
description: Contributing to hyprwm/aquamarine (rendering backend for Hyprland); covers DRM/Wayland backend guidelines, vouch workflow, strict AI disclosure, building on NixOS, and lessons.
disable-model-invocation: true
---

# hyprwm/aquamarine Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `hyprwm-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `aquamarine` and wins
where they differ.

Sources of truth: `README.md`, `.github/workflows/{nix.yml,vouch-prs.yml}`, issues #426, #440, #477, #478.
As of 2026-11-13.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Strict `hyprwm` org policy applies. No agent submissions or automated text. Martin writes
  every PR description, issue comment, and review response in his own voice, and commits/pushes from his own
  environment. Detailed AI disclosure required in PR description.
- **Vouch requirement:** Do NOT open PRs without author being on `hyprwm/.github/vouch/VOUCHED.td`, or the
  PR is closed immediately by bot. Discuss patches on related GitHub issues first (e.g., #426) or request
  vouching before opening PR.
- **PR Titles & Commits:** `<component>: <imperative summary>` (e.g. `drm: re-read possible CRTCs when rescanning connectors`).
  Squash merge is default.
- **Code style:** Modern C++23, strict formatting matching existing backend code (`clang-format`), no tabs.

## 1. Before starting

- Search open and closed issues and PRs: `gh search issues --repo hyprwm/aquamarine --include-prs <terms>`.
- Check open issues touching DRM / backend state: #426 covers dynamic CRTC reassignment; verify current branch head before proposing diffs.

## 2. Designing the change

- `src/backend/drm/`:
  - `DRM.cpp`: Connector and CRTC management.
  - Dynamic CRTC mask: Drivers like Apple DCP or Type-C DP-alt-mode controllers can alter `possible_crtcs`
    on hotplug when internal pipelines re-route. `scanConnectors()` must refresh `possibleCrtcs` via
    `drmModeConnectorGetPossibleCrtcs()`.
  - Mode acquisition on wake: Displays behind Type-C / USB4 docks may connect before reading EDID/modes.
    When a connector reports modes on subsequent hotplug, reconnect the output to prevent black screens.

## 3. Building and validating on NixOS

```bash
nix shell nixpkgs#cmake nixpkgs#pkg-config nixpkgs#wayland nixpkgs#wayland-protocols \
  nixpkgs#libdrm nixpkgs#libgbm nixpkgs#libinput nixpkgs#pixman nixpkgs#libdisplay-info \
  nixpkgs#hwdata nixpkgs#seatd --command bash -c 'cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$(nproc)'
```

## 4. Prepared contributions

1. **`drm: re-read possible CRTCs when rescanning connectors`**
   - Resolves: `hyprwm/aquamarine#426`.
   - Touchpoint: `src/backend/drm/DRM.cpp` inside `CDRMBackend::scanConnectors()`.
   - Effect: Updates `conn->possibleCrtcs` when non-zero and changed, allowing re-routed Type-C outputs to find available CRTCs without compositor restart.

2. **`drm: reconnect an output whose connector gained modes`**
   - Touchpoint: `src/backend/drm/DRM.cpp` inside `CDRMBackend::recheckOutputs()`.
   - Effect: Reconnects output when `conn->status == DRM_MODE_CONNECTED && conn->output && conn->output->modes.empty() && conn->maxMode.x > 0`.
