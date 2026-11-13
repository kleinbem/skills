---
name: hyprland-contributing
description: Contributing to hyprwm/Hyprland; covers compositor protocol lifecycle, monitor management, vouch gating, strict AI disclosure, building on NixOS, and lessons.
disable-model-invocation: true
---

# hyprwm/Hyprland Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `hyprwm-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `Hyprland` and wins
where they differ.

Sources of truth: `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`,
`.github/workflows/{nix.yml,vouch-prs.yml}`, issues #15635, #8545, #9230. As of 2026-11-13.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Strict `hyprwm` org policy applies. No agent submissions or automated text. Martin writes
  every PR description, issue comment, and review response in his own voice, and commits/pushes from his own
  environment. Detailed AI disclosure required in PR description.
- **Vouch requirement:** Do NOT open PRs without author being on `hyprwm/.github/vouch/VOUCHED.td`, or the
  PR is closed immediately by bot. Discuss patches on related GitHub issues first (e.g., #15635) or request
  vouching before opening PR.
- **PR Titles & Commits:** `<component>: <imperative summary>` (e.g. `output: keep removed wl_output global alive for in-flight binds`).
  Squash merge is default.
- **Code style:** Modern C++23, formatting via project `.clang-format`, no tabs.

## 1. Before starting

- Search open and closed issues and PRs: `gh search issues --repo hyprwm/Hyprland --include-prs <terms>`.
- Check open issues: #15635 tracks mass client crashes on monitor disconnect due to missing `wl_output` global grace period.

## 2. Designing changes in the compositor

- **Protocol lifecycle (`src/protocols/core/Output.cpp`, `src/managers/ProtocolManager.cpp`):**
  - When `wl_global_remove` is called for a removed output, in-flight `wl_registry.bind` requests from clients
    are still in transit. Destroying the global immediately causes a fatal protocol error:
    `global wl_output (N) is unavailable`, fatally killing Xwayland, portals, and client applications.
  - Fix: Do not destroy the global immediately. Keep defunct output globals alive for a 5-second grace
    timer (matching wlroots) so that in-flight binds succeed against an inert resource.
- **Monitor rules (`src/config/shared/monitor/`):**
  - `CMonitorRule::compare()` must include `m_vrr` so VRR adjustments count as a soft mismatch triggering
    re-application on config reload.
  - In `CMonitorRuleManager::ensureMonitorStatus()`, invoke `ensureVRR(m)` for refreshed monitors so the
    new VRR rule takes effect without requiring multiple reloads.
- **EGL Teardown (`src/render/OpenGL.cpp`):**
  - In `CHyprOpenGLImpl::~CHyprOpenGLImpl()`, release context with `eglMakeCurrent` and invoke `eglReleaseThread()`
    before `eglTerminate()` to avoid NVIDIA driver crash on shutdown.

## 3. Building and validating on NixOS

```bash
nix build .#hyprland
```
Or with development nix shell from the repo root.
