---
name: arch-review
description: >-
  Strategic architecture and domain-alignment review for kleinbem app repos:
  check docs/glossary.md and docs/adr/, scan recent jj hotspots for shallow
  modules, duplicated logic, or implementation-coupled tests, and propose
  deep-module consolidations with merge-danger triage. Load before major
  refactors or when an app repo feels cluttered.
---
# Architecture and domain-alignment review

Strategic check against tactical "vibe-coded" drift in application repos (not needed for routine NixOS or single-package bumps).

## 1. Ground in domain docs first

- Check `AGENTS.md`, `docs/glossary.md`, and `docs/adr/` if present.
- If `docs/glossary.md` or `docs/adr/` doesn't exist yet in an active app repo, don't generate a whole-repo doc up front—mint terms and record hard-to-reverse decisions only for the hotspot you're touching.
- Flag places where UI, backend, database, and prompts use different names for the same entity.

## 2. Scan recent hotspots

Look at files touched most often recently:
```bash
jj log -r 'ancestors(@, 30)' --no-graph -T 'change_id.short() ++ " " ++ description.first_line() ++ "\n"'
```
Inspect high-churn modules for three smells:
1. **Shallow / pass-through modules:** wrappers that add indirection without hiding complexity.
2. **Duplicated business logic:** near-identical flows across handlers, commands, or components.
3. **Brittle implementation-coupled tests:** tests asserting internal helpers/constants rather than behavior at a narrow module boundary.

## 3. Propose deep-module consolidations

- Group related logic into **deep modules**: simple, narrow public entry points hiding substantial implementation.
- Write unit/integration tests against the module's public entry points so internals can be refactored without test churn.
- Size each proposed refactor as a single bounded task (~150k-token session) rather than one giant sweep.

## 4. Tag PRs with merge danger

When opening a PR from an architecture or feature pass, include a short **Merge Danger** block in the PR body:
- **Door:** `two-way` (easy to revert/fix forward) or `one-way` (schema drop, data migration, external side effects).
- **Blast radius:** `small` / `medium` / `large` and which hosts/users/modules it touches.
- **Evidence:** exact test/build/screenshot output observed after the final edit.
