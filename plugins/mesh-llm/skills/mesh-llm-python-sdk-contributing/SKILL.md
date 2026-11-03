---
name: mesh-llm-python-sdk-contributing
description: Use when preparing, updating, or reviewing a pull request to Mesh-LLM/mesh-llm-python-sdk (the Python SDK, its generated UniFFI bindings and the locked compatibility clients) to follow its checksum manifest, test, commit and PR rules.
disable-model-invocation: true
---

# Mesh-LLM/mesh-llm-python-sdk contribution workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/mesh-llm-python-sdk and wins where they differ.

Sources of truth: the repo has no `CONTRIBUTING.md`, `AGENTS.md`, PR or issue templates and no
`.github/` at all. What exists: `README.md`, `sdk/README.md` (test and binding commands),
`docs/python.md`, `sdk-inputs.json`, and on the mesh-llm side its root `AGENTS.md` ("SDK"
sections), `tools/xtask/src/automation/python_sdk_source.rs` and
`.agents/skills/manage-ci/references/current-inventory.md` ("External Python SDK source
preparation"). As of 2026-11-03: repo created 2026-10-08, 5 PRs, all from org members
(`i386`, `ndizazzo`), no outside PR yet.

## 0. Hard rules

- **Every other tracked file is pinned in `sdk-inputs.json`** (`files`: path → plain SHA-256 of
  the bytes; the manifest doesn't list itself). A PR that changes, adds or removes a tracked
  file updates its entry in the same commit; #3 and #5 did. mesh-llm's admission
  (`python_sdk_source.rs`) refuses changed bytes, unexpected tracked files and symlinks, so a
  stale manifest breaks mesh-llm CI the day it bumps its pin. Check: `sha256sum <file>` against
  the entry, for every other touched file.
- The manifest itself is pinned on the mesh-llm side (`manifest_sha256` in
  `ci/required-sdk-python/sdk-source.json`, with the revision). Moving that pin is a separate
  mesh-llm PR, not part of an SDK PR.
- `mesh_source` and `generator` in `sdk-inputs.json` record which mesh-llm commit the generated
  bindings came from. Don't touch them unless you regenerate bindings; never hand-edit
  `sdk/src/meshllm/_generated/` (mesh-llm `AGENTS.md`: generate from the exact native library
  metadata with UniFFI 0.32.0).
- Attribution follows `mesh-llm-org`: no agent trailers. No policy file of its own.
- `.gitattributes` forces `eol=lf`: the checksums are of LF bytes.

## 1. Before starting

- Search here and in Mesh-LLM/mesh-llm: `pyproject.toml` points `Issues` at mesh-llm, though this
  repo has its own issues too (#4).
- Check open PRs for the same files: #2 (thinking efforts) has been open since 2026-10-29 and
  touches `client.py`, `types.py`, `test_client.py` and `sdk-inputs.json`, so any PR here will
  conflict with it on `sdk-inputs.json`. Rebase and rehash whichever lands second.
- A public API change starts in mesh-llm: its `AGENTS.md` wants all five SDK surfaces to pass
  against the same native revision, with Python as a companion PR here (mesh-llm#2703 and #1
  here). Fixes inside the Python layer (asyncio glue, wrappers, docs, tests) stand alone.

## 2. Designing the change

- The Python layer wraps blocking FFI calls in `asyncio.to_thread` and delivers native callbacks
  with `loop.call_soon_threadsafe` (`client.py` `_EventSink`, `native_runtime.py`
  `install_native_runtime`). Ordering between those callbacks and the awaited result differs by
  Python version: since 3.13, `asyncio.futures._chain_future` resolves the future directly when
  the worker has already finished, so `await` can return before earlier queued callbacks ran.
- `requires-python = ">=3.10"`; pyright targets 3.10. Keep syntax 3.10-compatible.
- Docs follow code: `docs/python.md` and `sdk/README.md` (and their manifest entries).

## 3. Building and validating on NixOS

- Component tests, as `sdk/README.md` gives them (stdlib only, mock native handles):
  `python3 -I sdk/tests/test_client.py` from the repo root. mesh-llm runs the same file with
  `-I -B`.
- Run them on every supported minor that nixpkgs has: `nix shell nixpkgs#python311 -c ...`, up
  to `python314` (nixpkgs has no 3.10 any more). Version-dependent asyncio behaviour shows up
  only on some (see section 2).
- `sdk/tests/test_binding.py` needs the real native bridge built from a matching mesh-llm
  revision; on an older bridge it fails on schema drift, which isn't ours to fix here.
- There is no CI in this repo. CodeRabbit is the only automated check; the local runs are the
  evidence, so put them in the PR body.

## 4. Commits

- Conventional Commits with `(sdk)` scope: `fix(sdk): …`, `docs(sdk): …`, `feat(sdk): …`.
- Squash merges (#3, #5; #1 was a merge commit), so the PR title is the commit.

## 5. Pull request

- No template. Free text in Martin's voice: result first, the cause in a couple of lines, the
  test runs per Python version with the proof run on main.

## 6. CI and bots

- CodeRabbit reviews every PR (#1, #3, #5) and expects answers like in mesh-llm.
- No branch protection or rulesets visible; maintainers merge their own PRs.

## 7. What the history shows

```bash
gh pr list -R Mesh-LLM/mesh-llm-python-sdk --state all --limit 40 \
  --json number,author,isCrossRepository,mergedAt,mergedBy \
  --jq '.[] | "#\(.number) \(.author.login) cross=\(.isCrossRepository) merged=\(.mergedAt) by=\(.mergedBy.login // "-")"'
```

- 2026-11-03: #1, #3, #5 merged within hours by their authors; #2 open; no fork PR yet, so
  there is no merge-time data for outside PRs.
- mesh-llm consumes a fixed SDK commit (`ci/required-sdk-python/sdk-source.json`, the
  `prepare-python-sdk-source` action and `ci/python-tooling-policy.json`, updated together). A
  merge here reaches mesh-llm only when they bump that pin.

## 8. Our setup

- Clone `~/Develop/github.com/Mesh-LLM/mesh-llm-python-sdk`, remotes `origin` (upstream) and
  `fork` (`kleinbem/mesh-llm-python-sdk`, created when the first PR is ready); one jj workspace
  per branch in `mesh-llm-python-sdk.ws/`.

## Review checklist

- `sdk-inputs.json` has the new SHA-256 of every other touched file, nothing else changed (section 0).
- No hand edits under `sdk/src/meshllm/_generated/`; `mesh_source`/`generator` untouched unless
  bindings were regenerated.
- `python3 -I sdk/tests/test_client.py` passes on 3.11 to 3.14 at the head, and a regression test
  fails on main where the bug is version-specific (section 3).
- Syntax stays 3.10-compatible.
- Overlap with open PRs (#2) checked; a public API change has its mesh-llm side.
