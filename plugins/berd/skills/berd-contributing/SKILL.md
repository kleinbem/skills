---
name: berd-contributing
description: Use when preparing an issue for block/berd (Block's Tauri + React desktop for AI agents on the Goose ACP backend), when a Berd fix is needed but no PR is possible, or when building and diagnosing Berd on NixOS; covers the issues-only policy, the bug and feature forms, the repo's architecture rules, and what Berd's PR and issue history shows.
---

# block/berd Contribution Workflow

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (also `CLAUDE.md`), `LAWS/`, `DESIGN.md`,
`.github/ISSUE_TEMPLATE/{bug-report,feature-request}.yml`, `.github/PULL_REQUEST_TEMPLATE.md`,
`.github/workflows/{ci,close-external-prs,close-needs-info}.yml`, `docs/release-and-updates.md`. Read them before
acting; this skill summarises them as of 2026-10-19 and adds what applies to our setup.

Berd is Apache-2.0, built by a small Block team, Tauri 2 + React 19, talking to a `goose serve` sidecar over ACP
(`goose-backend.lock.json` pins a goose **main commit**, not a release). Latest release v0.6.4 (2026-09-10); `main`
moves daily and is well ahead of it.

## 0. The one rule: no outside pull requests

- **Berd does not accept PRs from anyone without write access.** `close-external-prs.yml` (since 2026-08-14, #31)
  closes them on `opened`/`reopened` with a pointer to `CONTRIBUTING.md`; it checks real collaborator permission, so a
  private org membership doesn't help and a public one isn't needed. Branch protection makes an outside merge
  impossible anyway. Don't prepare a patch for upstream; don't open a PR "to show the fix".
- **The contribution is the issue.** Upstream says a clean bug report is worth more to them than a patch, because
  it is the part they can't do themselves. A fix we need lives in our package (`nix-packages/pkgs/berd`, later
  nixpkgs) as a patch with a comment linking the issue, until upstream ships it.
- "If this changes, it'll change here first" (`CONTRIBUTING.md`). Re-read it before assuming the policy still holds.
- Security problems: never a public issue; Block's policy is in `block/.github/SECURITY.md`.

## 1. Filing an issue

Only the two forms exist (`https://github.com/block/berd/issues/new/choose`); blank issues are off, and issues
created around the forms (API, `gh issue create`) are held to the same fields and may be sent back. Write the body
in the form's field order so a maintainer can paste it into the form, or file it through the web form.

Three bars every issue must clear (the forms ask to confirm each):
1. **Search first**, open and closed: `gh search issues --repo block/berd <terms>`. Link the closest one or write
   "none found". A second data point on an existing bug goes into that thread, not a new issue.
2. **Reproduce on the current release** (`gh release view --repo block/berd`). Reports against older builds can't
   be acted on. Our Nix build from a tag is "the current release" when the tag matches; a build from `main` is not,
   say which commit it was.
3. **One issue per issue.** An "and also" is a second issue.

**Bug report fields:** closest existing issue · what's broken · numbered steps from a freshly launched Berd (what
was clicked and typed, model and provider, whether the chat had history) · expected · actual, as two separate
statements · frequency (every time / intermittent / once) · Berd version (Settings → About) · OS · model and provider ·
relevant log excerpt · screenshots or recording for anything visual.
- Logs: Linux `~/.local/share/xyz.block.berd/logs/berd.log` (rotated `berd_<timestamp>.log`); the agent backend logs
  under `~/.local/state/Block/goose/logs/`, usually the `server/` subtree. Paste the lines around the event in a
  fenced block, **scrubbed** (paths, prompts, project names). Write "no relevant log output" if there is none.
- **Feature request fields:** closest existing issue · new or improvement · the problem in your terms (lead with it,
  not with the solution) · what you do today (the workaround, or "nothing, I gave up") · what you'd like to see · why
  it belongs in Berd itself rather than a skill, agent, extension or automation (`.agents/skills/`, `distro/`) ·
  **non-goals** (upstream calls this the most useful and least written line) · alternatives considered · mockups.

Agent use is encouraged for gathering versions, trimming logs and writing repro steps, with two rules upstream
enforces by closing: **the human is the author** and must be able to answer any question about the issue; **never
invent details**, write "unknown" instead of a guessed version or a paraphrased error. In our setup Martin files
the issue himself; the agent drafts in Obsidian (`Projects/Buzz nixpkgs/Drafts/`), with "I", never "we".

What happens next (best effort, no timeline): a label and a place in the queue; `needs-info` (23 days quiet →
`closing-soon`, 7 more → closed; a comment reopens); closed as duplicate with a link; closed as out of scope with a
reason. Closed is not unwelcome.

### The nixpkgs angle

Say when the problem blocks packaging and why a distribution hits it, as with mesh-llm: the goose pin on a main
commit (only matters for `main`; the release runs on `goose-cli`), the managed ACP bridges installed with `npm ci` from
`acp-tools.lock.json` using a Node runtime downloaded per `node-runtime.lock.json` (a package needs system Node and
an off switch), telemetry and updater defaults for third-party builds (`TELEMETRY.md`, `docs/release-and-updates.md`),
the `catch` sidecar (`block/catch`, macOS-only Swift; Linux builds skip it). Frame it as the problem and today's
workaround, and name the non-goal (we don't ask upstream to maintain a Nix package).

## 2. Building and diagnosing on NixOS

- Toolchain: `rust-toolchain.toml` (1.94.1 on 2026-10-19; nixpkgs' `rustc` is fine), pnpm 10.33, Node, `just`,
  Tauri 2 prerequisites (webkitgtk, libsoup, openssl, glib-networking as nixpkgs' `goose-desktop`/`buzz-desktop`
  use them). No Hermit here, unlike goose and buzz.
- `just setup` installs pnpm deps, builds the vendored `@aaif/goose-sdk` and builds the pinned goose into the
  platform cache; `just dev` fails if the cache doesn't match the lock. `GOOSE_BIN=/path/to/goose just dev` is the
  explicit override: with nixpkgs' `goose-cli` (a release) it tells whether Berd works without the pinned commit.
- Validation by change type (`AGENTS.md`): frontend → `just check` (design-system, berdctl contract, format, lint,
  i18n, typecheck); Vitest-covered behaviour → `just test`; `src-tauri/`, sidecars, Rust → `just tauri-check` (and
  `just clippy`, warnings denied); berdctl → `pnpm generate:berdctl-contract`, `pnpm vitest run src/features/berdctl`,
  `cargo test -p berdctl`; packaging → `just ci`. CI (`ci.yml`) runs frontend/rust/windows/transcript-virtualization/
  build jobs, all on macOS, Windows and Linux runners.
- Bundles: `just bundle` stages `src-tauri/binaries/goosed-<host triple>` (Tauri `externalBin`) and runs
  `pnpm tauri build`; Linux release assets are AppImage and .deb. #336 shows the AppImage setting `PYTHONHOME`/
  `PYTHONPATH` to missing paths, a hint of what a packager must check.
- The reference build is `kleinbem/nix-packages` `pkgs/berd` (written under the nixpkgs-contributing skill).
  Berd 0.6.4 works with nixpkgs' `goose-cli` release as the `goosed` sidecar (tested 2026-10-19 with the bundled
  pin, 1.49.0 and 1.55.0: same `goose serve` interface, same answers), so the goose pin only matters when building
  Berd `main`. Upstream's cargo features `no-managed-acp-tools` and `no-bb-cli-install` turn off the runtime
  Node/npm downloads. Reproduce bugs in that build before reporting.

## 3. Reading the codebase (for a precise report)

- `AGENTS.md` layout: `src/` React, `src-tauri/` the shell that starts or resolves `goose serve`, `sdk/` vendored
  `@aaif/goose-sdk` and generated ACP types, `distro/` bundled defaults, `scripts/ensure-local-goose.sh`,
  `scripts/prepare-goose-sidecar.sh`, `scripts/update-goose-backend-lock.sh`, `scripts/update-acp-tools-lock.mjs`.
- `LAWS/` (RFC 2119 MUST/MUST NOT, `LAWS/README.md`, `LAWS/AGENTS.md`, `LAWS/CHAT.md`) is the source of truth for
  product behaviour and wins over code and tests. A report that shows code violating a law is the strongest bug
  report there is; a feature request that contradicts a law needs to argue for a law change.
- ACP is the main interface for the agent loop (sessions, models, configuration); the UI handles only what ACP
  doesn't have yet. Reports about a hung turn or a tool that never returns usually belong to the backend logs.
- berdctl (CLI → broker → renderer registry; `docs/berdctl-architecture.md`) has six invariants, three gated by
  tests; the contract JSONs are generated, never hand-edited.
- Experiments are opt-in user-local switches (`.agents/skills/experimental-features/SKILL.md`), no one-off
  localStorage keys or distro flags.

## 4. How the team itself works (useful for reading their PRs and predicting fixes)

- PR titles are lowercase imperative, often Conventional Commits (`fix:`, `feat(search):`, `chore: bump goose
  backend to <sha>`); the team's `create-pr` skill writes bodies with Category / User Impact / Problem / Solution and
  a collapsed file list, and resolves an issue (`Closes #N`) before pushing. Their `code-review` skill runs a
  pre-PR review in two passes (safety, maintainability) against the repo's own patterns.
- `lefthook.yml`: pre-commit Biome format and check plus `just check`; pre-push `just fmt-check`, `clippy`, `check`,
  `tauri-check`. Dependencies by Renovate.
- `goose-backend.lock.json` bumps arrive as their own `chore:` PRs several times a week; a fix that needs newer goose
  comes through such a bump, not through Berd code.

## 5. What the history shows (2026-08-12 to 2026-10-19, 289 PRs, 91 issues)

- **Zero outside PRs merged, and none even attempted after the policy** except Renovate's: every author of a
  merged PR has write access (148 of them read as `CONTRIBUTOR` only because their membership is private). The 33
  closed-unmerged PRs are the team's own abandoned branches and four Renovate PRs the bot closed within minutes.
  Internal PRs merge fast: median 1.3 h, 90th percentile about 3 days; two people wrote 69 of 93 member-authored
  merged PRs.
- **Issues are the real channel, and triage is thin:** 87 of 91 issues come from outside; 72 are open, 61 of those
  have no label and most no comment; 21 open outside issues have at least one reply. `needs-info` and `closing-soon`
  have never been applied. 13 outside issues were closed as completed (median 6.5 days), 2 as not planned.
- **What got fixed:** precise, reproducible, single-topic reports with the version and a clear expected/actual:
  #154 (cache overwritten by an empty refresh, fixed next day in #163), #129 (`just setup` fails on a clean checkout,
  two days, #162), #168 (consumer build exposed an internal flow, #262), #225–#228 (one reporter, four separate
  berdctl issues, all fixed in one week by four PRs), #240 (KaTeX duplicate text, #377), #320 (toast duration, #366).
- **What stalls:** large feature ideas without a problem statement (profiles #383, notification center #321,
  provider wish lists #298/#319) sit unlabeled with zero comments; architecture proposals from outside are closed
  as not planned (#302, #303).
- **Lesson for us:** report one packaging blocker per issue, reproduced on the release tag, with the Nix build as the
  repro, logs scrubbed, and our workaround stated. Expect a fix within days when it is a clear bug, nothing when it
  is a direction.
