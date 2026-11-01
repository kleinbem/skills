---
name: gimp3-mcp-contributing
description: Use when preparing an issue or PR for tifyr/gimp3-mcp (MCP server and GIMP 3 plugin, Python, published on PyPI and the MCP Registry), or when building or testing it on NixOS; covers CLAUDE.md as the repo's guide, the ruff-only CI, CodeRabbit, the GIMP-bound test suite and the mcp version cap.
disable-model-invocation: true
---

# tifyr/gimp3-mcp Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `tifyr-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to gimp3-mcp and wins
where they differ.

Sources of truth in the repo: `CLAUDE.md` (the contributor guide: architecture, commands, CI,
release), `README.md` (also the PyPI page), `CHANGELOG.md`, `pyproject.toml`, `uv.lock`,
`server.json`, `.coderabbit.yaml`, `.pre-commit-config.yaml`,
`.github/workflows/{lint,release,issue-labeler}.yml`, `.github/labeler.yml`. No `CONTRIBUTING.md`,
no `AGENTS.md`, no PR or issue templates, no `CODEOWNERS`. Summary as of 2026-11-01.

GPL-3.0, no stars yet, one maintainer (`@kajborjeson`, Kaj) who commits to `main` and merges his
own branches. It continues maorcc/gimp-mcp, whose history it keeps. Active 2026-09-14 to 09-16
(0.2.0), quiet since; the one outside PR (#1, 2026-10-28) has no answer yet.

## 0. Hard rules that decide the agent's role

- **No AI policy.** The maintainer works with Claude himself: 30 of the last 100 commits carry
  `Co-Authored-By: Claude <model> <noreply@anthropic.com>`. So the agent drafts, Martin reviews and
  posts; that trailer on agent-written commits matches the repo's own practice. Say in the PR text
  in one line that it was written with an AI assistant.
- No issue-first rule, no CLA, no sign-off.

## 1. Before starting

- Search issues and PRs: `gh search issues --repo tifyr/gimp3-mcp --include-prs <terms>`. Few
  exist; check the open PRs' files for overlap (`gh pr view <N> --json files`): #1 (`GIMP_MCP_PORT`)
  touches both `gimp_mcp_server.py` and `gimp-mcp-plugin.py`.
- `CLAUDE.md` records decisions; a change that moves one has to update it in the same PR (for
  example "`mcp` is capped below 2, whose FastMCP API differs. Tested against 1.10.1 and 1.30.0.").

## 2. Designing the change

- Two programs: `gimp-mcp-plugin.py` runs inside GIMP 3.2 as a socket server (localhost:9877);
  `gimp_mcp_server.py` is the MCP server (mcp's FastMCP) that talks to it. The wheel maps both,
  plus `docs/best_practices.md` and `docs/iterative_workflow.md`, into the `gimp3_mcp` package
  (`[tool.hatch.build.targets.wheel.force-include]`); the server reads the docs relative to
  `__file__`.
- Every tool runs in a worker thread, one at a time, through the wrapper around `mcp.tool` in
  `gimp_mcp_server.py` (GIMP runs commands serially). Changes to how tools run go there.
- Tools are checked on what they did, not on the status they report ("Assert on results, not
  status", `CLAUDE.md`): they once returned success while doing nothing.
- Dependency range changes: `pyproject.toml`, `uv.lock` (`uv lock`) and the `CLAUDE.md` line move
  together.
- `README.md` is the PyPI page: links must be absolute. Keep the
  `<!-- mcp-name: io.github.tifyr/gimp3-mcp -->` marker (MCP Registry ownership).
- `CHANGELOG.md`: one section per version with `### Added`, `### Fixed`, `### Changed`; the
  maintainer dates it at release. A contribution adds its line under `## Unreleased` (create it
  above the newest version). Versions in `pyproject.toml` and `server.json` are the maintainer's
  release step, not part of a PR.

## 3. Building and validating on NixOS

- Lint, as CI: `uvx ruff@0.15.11 check .` (from `nix shell nixpkgs#uv`); CI pins that ruff version
  in `lint.yml` and `.pre-commit-config.yaml`, and newer ruff fails on unchanged code.
- Tests need a running GIMP 3.2 with the plugin started (Tools > MCP > Start MCP Server):
  `python run_tests.py` (85 checks) plus the narrower `tests/*.py`. They can't run in CI. They
  change GIMP's colours and open or close images, so run them in a GIMP session without work worth
  keeping. Martin runs them on his desktop when a change touches tool behaviour.
- Without GIMP, an MCP stdio smoke test covers the server layer: `initialize`, `tools/list`,
  `tools/call check_server` (reports `connected: false` and the reason), and a tool that needs
  GIMP (the error text must name the cause).
- The nixpkgs-style package lives in kleinbem/nix-packages (`pkgs/gimp3-mcp/package.nix`); build
  and test a change there against both mcp majors when the range is involved.

## 4. Commits

- Titles are plain sentences that say what changed, capitalised, no prefix ("Stop the MCP server
  losing replies and blocking on slow GIMP calls", "Pin setup-uv to a tag that exists in the
  release workflow"). Bodies explain why.

## 5. Pull request

- No template. Follow #1's shape: `## Summary` (what and why, with a short example), then how it
  was tested. Short, "I", one line of AI disclosure.

## 6. CI and bots

- **Lint** (`lint.yml`): ruff 0.15.11 via `astral-sh/ruff-action`, on pull requests and pushes to
  `main`. The only CI job.
- **CodeRabbit** (`.coderabbit.yaml`, profile "chill"): reviews non-draft PRs only
  (`auto_review.drafts: false`), so a draft gets its review when marked ready. Path instructions
  ask for socket safety and exec injection in the plugin, error handling and MCP compliance in
  the server. Answer every thread.
- **Issue labeler**: labels issues from title words (`bug`, `enhancement`, `question`,
  `documentation`).
- **Release** (`release.yml`): on `v*` tags, the maintainer's step (PyPI trusted publishing, MCP
  Registry).

## 7. What the history shows

As of 2026-11-01 (`gh pr list -R tifyr/gimp3-mcp --state all`): one PR ever, #1 from kv055, open
four days without a reply or review. No merged outside contribution yet, so no review patterns.
The maintainer lands work as merge commits of his own branches (11 of the last 100 commits).

## 8. Our setup and current threads

- Fork `kleinbem/gimp3-mcp`, clone `~/Develop/github.com/tifyr/gimp3-mcp` (jj colocated,
  `origin` upstream, `fork` ours).
- Downstream: kleinbem/nix-packages carries `pkgs/gimp3-mcp/mcp-2.patch` (mcp 2: `FastMCP` is
  `MCPServer`, tool errors re-raised as `ToolError` so their messages reach the client),
  kleinbem/nix-packages#232. no-link: upstream support for mcp 2 next to mcp 1 is prepared
  (2026-11-01) but no issue or PR exists yet; replace this with the PR once it is open.

## Review checklist

- `CLAUDE.md`, `pyproject.toml` and `uv.lock` agree on any dependency change (section 2).
- `CHANGELOG.md` has the change under `## Unreleased`, in the existing section names (section 2).
- `uvx ruff@0.15.11 check .` passes (section 3).
- Server changes keep tools in the worker-thread wrapper, and errors reach the client with their
  cause (section 2).
- Claims of GIMP behaviour come from a run with GIMP; otherwise the PR says what was tested
  without it (section 3).
- No version bump in `pyproject.toml` or `server.json` (the maintainer's release step).
