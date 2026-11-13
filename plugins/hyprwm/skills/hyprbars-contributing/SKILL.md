---
name: hyprbars-contributing
description: Contributing to hyprwm/hyprland-plugins/hyprbars (official Hyprland window titlebar plugin); covers titlebar rendering, window state, inactive coloring, workspace scoping, and lessons from Omarchy fork.
disable-model-invocation: true
---

# hyprwm/hyprland-plugins (hyprbars) Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `hyprwm-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `hyprbars` and wins
where they differ.

Sources of truth: `hyprwm/hyprland-plugins/hyprbars/README.md`, `omacom/omarchy-hyprland-titlebars`.
As of 2026-11-13.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Strict `hyprwm` org policy applies. No agent submissions or automated text. Martin writes
  every PR description, issue comment, and review response in his own voice, and commits/pushes from his own
  environment. Detailed AI disclosure required in PR description.
- **Vouch requirement:** Author must be vouched before opening PRs on `hyprwm` repositories.
- **Commits:** Conventional title: `hyprbars: <imperative summary>`.

## 1. Upstream gaps and lessons from Omarchy fork

The Omarchy project maintained an independent fork (`omacom/omarchy-hyprland-titlebars`) adding several
key features that belong upstream in `hyprbars`:

1. **Inactive titlebar color (`bar_color_inactive`):** Upstream hyprbars only had one titlebar color for
   all windows. Adding an inactive color distinguishes focused and unfocused windows.
2. **Workspace scoping (`workspace_tag`):** Enabling titlebars only for floating workspaces or specifically
   tagged windows, rather than all windows globally.
3. **Application name resolution:** Parsing desktop entries from `$XDG_DATA_DIRS` to match `StartupWMClass`
   or executable name so titlebars show friendly app names (e.g. "WhatsApp" instead of "web.whatsapp.com").
4. **Button hover highlights and drag-to-restore:** Polished interactive behaviors.
