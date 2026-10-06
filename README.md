# skills

Agent skills from the kleinbem workspace, as a Claude Code plugin marketplace.

| Plugin | Skill | What it covers |
| --- | --- | --- |
| `nixpkgs` | `nixpkgs-contributing` | Nixpkgs contributions: base branch, commit and `meta` conventions, pre-push checks |
| `kleinbem-fleet` | `kleinbem-fleet` | Orientation for the kleinbem NixOS + OpenWrt fleet workspace |

## Install in Claude Code

```
/plugin marketplace add kleinbem/skills
/plugin install nixpkgs@kleinbem
```

Plugins carry no `version`, so an update picks up the latest commit.

## Other agents

Each skill is a plain `SKILL.md` under `plugins/<plugin>/skills/<skill>/`. The kleinbem
fleet links them into every agent's skills directory (Claude Code, opencode, Gemini,
Codex) with home-manager; see `nix-config/modules/home-manager/ai-agents.nix`.

## Layout

```
.claude-plugin/marketplace.json
plugins/<plugin>/.claude-plugin/plugin.json
plugins/<plugin>/skills/<skill>/SKILL.md
```

Check changes with `claude plugin validate .`.
