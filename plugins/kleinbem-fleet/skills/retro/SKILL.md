---
name: retro
description: >-
  Post-session or post-PR retrospective in the kleinbem fleet: turn human
  corrections, CodeRabbit catches, and CI surprises into minimal updates to
  AGENTS.md, docs/adr/, docs/glossary.md, skills, or automated checks so the
  same mistake is not repeated. Load when asked to run a retro or after a PR
  needed heavy steering.
---
# Post-PR and post-session retro

Goal: fix the agent's environment so you never have to leave the same review comment twice.

## 1. Gather what went wrong

- **From the current session:** list every place Martin corrected direction, naming, scope, or tooling.
- **From a PR:** inspect review threads and CI failures:
  ```bash
  gh pr view <n> --json title,body,comments,reviews
  gh api repos/<owner>/<repo>/pulls/<n>/comments --jq '.[] | {path, line, body}'
  ```
- **From recent changes:** `jj log -r 'ancestors(@, 10)' --no-graph` and `jj diff -r <rev> --stat`.

## 2. Route each fix to the lowest-maintenance layer

Prefer deterministic enforcement over prose:

| Friction type | Where it belongs | Rule |
| --- | --- | --- |
| Deterministic rule (formatting, lint, structural check) | CI / `just check` / lint script | Automate it; don't rely on prose |
| Repo-specific gotcha, build/test command, or convention | Repo `AGENTS.md` | 1–3 lines, present-tense why/how |
| Hard-to-reverse choice or rejected alternative | Repo `docs/adr/NNN-<slug>.md` | Short: context, decision, rejected options |
| Domain term drift across DB / API / UI / prompts | Repo `docs/glossary.md` | Canonical term + where it maps |
| Fleet-wide workflow or upstream repo pattern | `kleinbem/skills` (`plugins/*/skills/*/SKILL.md`) | Update existing skill; keep it concise |

## 3. Keep edits tight

- Propose the exact diffs before applying unless asked to land them directly.
- Never add debugging stories, dates, or "was X, now Y" history to code comments.
- If updating `kleinbem/skills` or a repo doc, work in your own `jj` workspace (`just jj::ws-new <repo> <name>`) and run the repo's check (`just check` in `skills`).
