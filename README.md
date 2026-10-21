# skills

Agent skills from the kleinbem workspace, as a Claude Code plugin marketplace.

| Plugin | Skill | What it covers |
| --- | --- | --- |
| `nixpkgs` | `nixpkgs-contributing` | Nixpkgs contributions: base branch, commit and `meta` conventions, pre-push checks |
| `buzz` | `buzz-contributing` | Pull requests to block/buzz: title, DCO, PR template, tests and checks |
| `kleinbem-fleet` | `kleinbem-fleet` | Orientation for the kleinbem NixOS + OpenWrt fleet workspace |
| `mesh-llm` | `mesh-llm-contributing` | Pull requests to Mesh-LLM/mesh-llm: builds, validation, commit and PR rules |
| `goose` | `goose-contributing` | Issues and pull requests to aaif-goose/goose: issues first, Ready before a PR, NixOS build without Hermit |
| `berd` | `berd-contributing` | Issues for block/berd (no outside PRs): the forms, building on NixOS, what the history shows |
| `matepad-pro` | `matepad-pro` | Operations, diagnostics, headless APK management, and reverse tunnels for Huawei MatePad Pro |
| `llama-cpp` | `llama-cpp-contributing` | Issues, patches and pull requests to ggml-org/llama.cpp: the AI usage policy, issues before features, regression tests, module-prefixed titles, NixOS builds |
| `skill-authoring` | `contribution-skill-authoring` | How to write and refresh a contribution skill: sources, facts to measure, section layout, plugin plumbing |

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
