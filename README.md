# skills

Agent skills from the kleinbem workspace, as a Claude Code plugin marketplace.

| Plugin | Skill | What it covers |
| --- | --- | --- |
| `upstream` | `upstream-contributing` | **Always loaded.** Router to the organization and repository skills, first-contact procedure, the workflow every upstream contribution shares, the switches table, the review-before-ready handoff template |
| `upstream` | `contribution-skill-authoring` | Writing and refreshing organization and repository skills (before the first contribution and before every PR) |
| `nixos` | `nixos-org` | NixOS organization: the nixpkgs and nix AI policies, security, RFCs, repo table |
| `nixos` | `nixpkgs-contributing` | Nixpkgs contributions: base branch, commit and `meta` conventions, pre-push checks, review patterns |
| `nixos` | `nixpkgs-maintaining` | Nixpkgs maintainer work: update PRs, merge bot, teams |
| `nixos` | `nixpkgs-packaging` | Bringing an app into nixpkgs end to end: shape, workaround-free loop with upstream, tests, platforms and hardware, fleet use before merge, after merge |
| `nixos` | `nixpkgs-reviewing` | Reviewing Nixpkgs pull requests: triage, mechanical verification, derivation and module auditing, and drafting concise GitHub suggestions with AI disclosure |
| `block` | `block-org` | Block organization (block/*): DCO and org checks, security, governance, repo table |
| `block` | `buzz-contributing` | Pull requests to block/buzz: title, DCO, PR template, tests and checks |
| `block` | `buzz-app-contributing` | Pull requests to block/buzz-app (Buzz 1.0): DCO, Co-authored-by, scope checkpoint, ready checklist, reviewers |
| `block` | `berd-contributing` | Issues for block/berd (no outside PRs): the forms, building on NixOS, what the history shows |
| `block` | `catch-contributing` | block/catch (Berd's macOS sidecar): issue first, the bug template, building with nixpkgs' Swift |
| `ggml-org` | `ggml-org` | ggml-org organization: AI usage policies (Martin writes every text), where ggml changes go, repo table |
| `ggml-org` | `llama-cpp-contributing` | ggml-org/llama.cpp: issues before features, regression tests, module-prefixed titles, NixOS builds |
| `aaif-goose` | `aaif-goose-org` | aaif-goose organization (Agentic AI Foundation): governance, security, the move from Block |
| `aaif-goose` | `goose-contributing` | aaif-goose/goose: issues first, Ready before a PR, NixOS build without Hermit |
| `mesh-llm` | `mesh-llm-org` | Mesh-LLM organization: attribution, security, how the repos relate |
| `mesh-llm` | `mesh-llm-contributing` | Mesh-LLM/mesh-llm: builds, validation, commit and PR rules, pre-flight CI |
| `archlinux` | `archlinux-org` | Arch Linux: no AI policy (our rule instead), governance, channels, 0BSD package sources, repo table |
| `archlinux` | `aur-contributing` | The AUR: submission rules, PKGBUILD and Rust guidelines, split packages, clean-container builds in kleinbem/aur-packages |
| `noooste` | `noooste-org` | Noooste (personal account): security reports, repo table |
| `noooste` | `garage-ui-contributing` | Noooste/garage-ui: Conventional Commits PR titles, coverage gate, maintainer's review style, nixpkgs angle |
| `kleinbem-fleet` | `kleinbem-fleet` | Orientation for the kleinbem NixOS + OpenWrt fleet workspace |
| `kleinbem-fleet` | `agent-ops` | Long-running work: watching builds and CI, polling without rate limits or YubiKey popups, waiting productively |
| `kleinbem-fleet` | `jj-workflow` | jj in the fleet: workspaces for concurrent agents, pushing, bookmarks, rebasing PRs with bot commits, signing |
| `matepad-pro` | `matepad-pro` | Operations, diagnostics, headless APK management, and reverse tunnels for Huawei MatePad Pro |

Contribution skills have three layers: `upstream-contributing` (always loaded) routes to the
organization skill (`<org>-org`) and the repository skill (`<repo>-contributing`). Those two are
manual skills (`disable-model-invocation: true`): out of every session's context, run with
`/<name>` or read by the agent as files. One plugin per GitHub organization.

## Install in Claude Code

```
/plugin marketplace add kleinbem/skills
/plugin install upstream@kleinbem
/plugin install nixos@kleinbem
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

Check changes with `just check` (`scripts/check-skills.py` and `claude plugin validate .`), the
same checks CI runs on every PR.

## Monthly refresh

`prompts/refresh-skills.md` is the refresh job for the organization and repository skills.
`just refresh-skills [scope]` runs it with a local agent in a throwaway clone that is deleted afterwards
(`AGENT=claude`, the default, or `AGENT=goose`). It opens at most one PR, which merges by itself once CI is green. Until it runs on our own stack (#30), a Claude Code cloud routine runs the same prompt on
the 1st of each month.
