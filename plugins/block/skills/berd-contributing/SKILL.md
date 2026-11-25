---
name: berd-contributing
description: Use when preparing an issue for block/berd (Block's Tauri + React desktop for AI agents on the Goose ACP backend), when a Berd fix is needed but no PR is possible, or when building and diagnosing Berd on NixOS; covers the issues-only policy, the bug and feature forms, the repo's architecture rules, and what Berd's PR and issue history shows.
disable-model-invocation: true
---

# block/berd Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `block-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to block/berd and wins where they differ.

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (also `CLAUDE.md`), `LAWS/` (`README.md`, `AGENTS.md`,
`CHAT.md`), `DESIGN.md`, `.github/ISSUE_TEMPLATE/{bug-report,feature-request,config}.yml`,
`.github/PULL_REQUEST_TEMPLATE.md`, `.github/workflows/{ci,close-external-prs,close-needs-info,release,public-npm-install,unsigned-desktop-build}.yml`,
`docs/release-and-updates.md`. Read them before acting; this skill summarises them as of 2026-11-25 and adds what
applies to our setup. None of these files changed between 2026-11-01 and 2026-11-25 except `ci.yml` (#439, 11-04).

Berd is Apache-2.0, built by a small Block team, Tauri 2 + React 19, talking to a `goose serve` sidecar over ACP
(`goose-backend.lock.json` pins a goose **main commit**, not a release; v0.6.5 pins aaif-goose `361003ea`). Latest
release v0.6.5 (2026-11-04). Its release run failed in the macOS job, so the tag has only Linux (AppImage, .deb) and
Windows assets and the updater feed was not promoted (checked 2026-11-25). `main` is quiet since: two commits after
the tag (#475 on 11-06, #431 on 11-12), after 65 commits in the last week of October.

## 0. The one rule: no outside pull requests

- **Berd does not accept PRs from anyone without write access.** `close-external-prs.yml` (since 2026-08-14, #31)
  closes them on `opened`/`reopened` with a pointer to `CONTRIBUTING.md`; it checks real collaborator permission, so a
  private org membership doesn't help and a public one isn't needed. Branch protection makes an outside merge
  impossible anyway. Don't prepare a patch for upstream; don't open a PR "to show the fix".
- **The contribution is the issue.** Upstream says a clean bug report is worth more to them than a patch, because
  it is the part they can't do themselves. A fix we need lives in our nixpkgs package (section 6) as a patch or
  `substituteInPlace` with a comment linking the issue, until upstream ships it.
- "If this changes, it'll change here first" (`CONTRIBUTING.md`). Re-read it before assuming the policy still holds.
- Security problems: never a public issue (`block-org`).
- **AI use:** `CONTRIBUTING.md` encourages it ("You're welcome — encouraged, really — to have a coding agent help you
  write the issue") and requires **no disclosure**. Its two rules: "You are the author, not the agent" (read it
  before posting; "If you can't answer a question about your own issue, it isn't ready") and "Do not let it invent
  details" (write "unknown"). "We can tell the difference between an agent that helped you investigate and an agent
  that padded a thin report into something that looks thorough. The second kind gets closed." So: no disclosure line,
  Martin files and owns every issue, the agent drafts facts only.

## 1. Filing an issue

Only the two forms exist (`https://github.com/block/berd/issues/new/choose`); blank issues are off, and issues
created around the forms (API, `gh issue create`) are held to the same fields and may be closed or sent back. Write
the body in the form's field order so a maintainer can paste it into the form, or file it through the web form. The
forms add the label themselves (`bug`, `enhancement`); an issue filed around them has no label.

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

In our setup Martin files the issue himself; the agent drafts in Obsidian (`Projects/Buzz nixpkgs/Drafts/`), with
"I", never "we".

What happens next (best effort, no timeline): a label and a place in the queue; `needs-info` (`close-needs-info.yml`:
23 quiet days → `closing-soon`, 7 more → closed as not planned; a comment resets the countdown, a maintainer removes
`needs-info`); closed as duplicate with a link; closed as out of scope with a reason. Closed is not unwelcome. In
practice (section 5) most issues get none of these.

### The nixpkgs angle

Say when the problem blocks packaging and why a distribution hits it: the goose pin on a main commit (our package
uses nixpkgs' `goose-cli` instead; #456 got the goose commit named in release notes), the managed ACP bridges installed
with `npm ci` from `acp-tools.lock.json` using a Node runtime downloaded per `node-runtime.lock.json` (a package needs
system Node and an off switch), telemetry and updater defaults for third-party builds (`TELEMETRY.md`,
`docs/release-and-updates.md`), the `catch` sidecar (`block/catch`, macOS-only Swift; Linux builds get a stub). Frame
it as the problem and today's workaround, and name the non-goal (we don't ask upstream to maintain a Nix package).

## 2. Building and diagnosing on NixOS

- Toolchain: `rust-toolchain.toml` 1.94.1 (unchanged since 2026-08-12; nixpkgs' `rustc` is fine), pnpm 10.33.0
  (`packageManager`), Node 24.10.0, `just`, Tauri 2 prerequisites (webkitgtk 4.1, gtk3, libayatana-appindicator,
  librsvg; CI's apt list). Upstream pins all of these through Hermit (`bin/hermit.hcl`, there since 2026-08-12:
  just 1.48.0, node 24.10.0, pnpm 10.33.0, rustup, cmake 4.2.3, lefthook 2.1.6); CI and the release activate it on
  macOS and Linux. On NixOS use the nixpkgs package's inputs instead.
- `just setup` installs pnpm deps, builds the vendored `@aaif/goose-sdk` and builds the pinned goose into the
  platform cache; `just dev` fails if the cache doesn't match the lock. `GOOSE_BIN=/path/to/goose just dev` is the
  explicit override: with nixpkgs' `goose-cli` (a release) it tells whether Berd works without the pinned commit.
- Validation by change type (`AGENTS.md`): frontend → `just check` (design-system, berdctl contract, format, lint,
  i18n, typecheck); Vitest-covered behaviour → `just test`; `src-tauri/`, sidecars, Rust → `just tauri-check` (and
  `just clippy`, warnings denied); berdctl → `pnpm generate:berdctl-contract`, `pnpm vitest run src/features/berdctl`,
  `cargo test -p berdctl`; packaging → `just ci`.
- CI (`ci.yml`, PRs and `main`): frontend checks, unit and release-script tests, transcript virtualization
  (Playwright) and the frontend build on macOS only; Rust fmt/check/test/clippy on macOS and Linux; Windows Rust and
  PowerShell 5.1 script tests. `public-npm-install.yml` (every PR) does a clean `pnpm install --frozen-lockfile` with
  pnpm 10.33.0 and fails if `pnpm-lock.yaml` references `block-artifacts.com` (Block's Artifactory).
  `unsigned-desktop-build.yml` (manual only) builds an ad-hoc-signed macOS DMG and an unsigned Windows installer.
- Bundles: `just bundle` stages `src-tauri/binaries/goosed-<host triple>` (Tauri `externalBin`) and runs
  `pnpm tauri build`; Linux release assets are AppImage and .deb, built with `BERD_RELEASE_CHANNEL=disabled` and
  `--features "$(scripts/block-feature-gates.sh berdctl)"`. #336 shows the AppImage setting `PYTHONHOME`/`PYTHONPATH`
  to missing paths, a hint of what a packager must check. How a Nix build compares with the release workflow and
  the release .deb (measured at 0.6.4) is in [references/packaging.md](references/packaging.md#build).
- Upstream's cargo features `no-managed-acp-tools` and `no-bb-cli-install` turn off the runtime Node/npm downloads.
  Berd 0.6.4 worked with nixpkgs' `goose-cli` as the `goosed` sidecar (tested 2026-10-19 with the bundled pin, 1.49.0
  and 1.55.0: same `goose serve` interface). Reproduce bugs in the package build before reporting.
- The voice crate is `berd-call` since #338 (in 0.6.5). Its default `static` feature downloads prebuilt sherpa-onnx;
  `static` and `shared` can't be combined, so a package swaps the dependency line (#449). Each release is meant to
  attach `berd-call_X.Y.Z_darwin-aarch64.tar.gz` (#435); 0.6.5 has none because its macOS job failed.
- The goose pin moved to a personal fork in #446 and back to upstream aaif-goose in #459; check the lock's `repo`
  before building `main`.

## 3. Reading the codebase (for a precise report)

- `AGENTS.md` layout: `src/` React, `src-tauri/` the shell that starts or resolves `goose serve`, `sdk/` vendored
  `@aaif/goose-sdk` and generated ACP types, `distro/` bundled defaults, `scripts/ensure-local-goose.sh`,
  `scripts/prepare-goose-sidecar.sh`, `scripts/update-goose-backend-lock.sh`, `scripts/update-acp-tools-lock.mjs`.
- `LAWS/` (RFC 2119 MUST/MUST NOT) is the source of truth for product behaviour and wins over code and tests. A
  report that shows code violating a law is the strongest bug report there is; a feature request that contradicts
  a law needs to argue for a law change.
- ACP is the main interface for the agent loop (sessions, models, configuration); the UI handles only what ACP
  doesn't have yet. Reports about a hung turn or a tool that never returns usually belong to the backend logs.
- berdctl (CLI → broker → renderer registry; `docs/berdctl-architecture.md`) has six invariants, three gated by
  tests; the contract JSONs are generated, never hand-edited.
- `ProjectInfo.id` stays stable across renames (#341); a report about lost sessions after a rename is a bug.
- Experiments are opt-in user-local switches (`.agents/skills/experimental-features/SKILL.md`), no one-off
  localStorage keys or distro flags.

## 4. How the team itself works (useful for reading their PRs and predicting fixes)

- PR titles are lowercase imperative, often Conventional Commits (`fix:`, `feat(search):`, `chore: bump goose
  backend to <sha>`); the team's `create-pr` skill writes bodies with Category / User Impact / Problem / Solution and
  a collapsed file list, and resolves an issue (`Closes #N`) before pushing. Their `code-review` skill runs a
  pre-PR review in two passes (safety, maintainability) against the repo's own patterns.
- `lefthook.yml`: pre-commit Biome format and check plus `just check`; pre-push `just fmt-check`, `clippy`, `check`,
  `tauri-check`. Dependencies by Renovate.
- Releases: `just release-prepare X.Y.Z` opens a release PR (#467 for 0.6.5); release notes name the goose backend
  since #458. A fix that needs newer goose comes through a goose-lock bump, not through Berd code.

## 5. What the history shows (2026-08-12 to 2026-11-25, 114 issues)

Staff = anyone who authored a merged PR (26 people; most read as `CONTRIBUTOR` or `NONE` because membership is
private, and `collaborators/<login>/permission` needs push access).
- **PRs:** zero outside PRs merged, none attempted after the policy except Renovate's (as of 2026-10-19; unchanged).
- **Issues:** 10 from staff (#256–#259, #302, #303, #320, #321, #367, #473), 104 from outside. 90 outside issues are
  open. The only labels ever used are the forms' own `bug` and `enhancement`; `needs-info` and `closing-soon` have
  never been applied. Staff have commented on 5 issues in total (#100, #138, #303, #316, #456).
- **Closures:** 14 outside issues closed as completed (#100, #116, #129, #138, #154, #168, #225–#228, #240, #316,
  #452, #456; #452 closed by us), none closed as not planned or duplicate. The two not-planned closures (#302, #303)
  were staff closing their own ideas.
- **Since 2026-11-01:** 15 new issues (one reporter filed 11 dictation items, #480–#490, in one day), 2 closed (both
  ours), no triage labels, one staff reply: #456 closed 11-19 with "Starting with v0.6.5, the release notes say which
  goose each release was built with".
- **What got acted on:** single-topic reports with a concrete ask in an area the team was working on anyway, fixed
  by a PR that references the issue, often closed only after the release. #456 (name the goose commit) was fixed by
  #458 the day it was filed and closed three weeks later; #225–#228 (four berdctl bugs, one reporter) fixed within a
  week; #138 (local STT/TTS) landed with the voice work; #154, #129, #240 were precise reproducible bugs.
- **What stalls:** everything else, silently. Our #449–#451, #455, #457, #462 (2026-10-29..31) have no label and no
  staff reply; large outside feature ideas (#298, #319, #383) sit with zero comments.
- **Lesson for us:** one packaging blocker per issue, reproduced on the release tag, with the Nix build as the repro,
  logs scrubbed and our workaround stated. Expect a fix only when it is a clear bug or a small ask; don't nudge.

Rerun:
```bash
gh api --paginate --slurp 'repos/block/berd/issues?state=all&per_page=100' | jq 'add' > issues.json
gh pr list -R block/berd --state merged --limit 500 --json author --jq '[.[].author.login]|unique' > staff.json
gh api --paginate 'repos/block/berd/issues/events?per_page=100' \
  --jq '.[]|select(.issue.pull_request|not)|select(.event|test("labeled|closed"))|"#\(.issue.number) \(.event) \(.actor.login) \(.created_at[0:10]) \(.label.name // "")"'
gh api --paginate 'repos/block/berd/issues/comments?since=<date>T00:00:00Z&per_page=100' \
  --jq '.[]|"\(.html_url|split("/")|last) \(.user.login) \(.created_at[0:10])"'
```

## 6. Our setup and current threads (2026-11-25)

- Package: nixpkgs `pkgs/by-name/be/berd`, NixOS/nixpkgs#580616 (`berd: init at 0.6.5`, branch `berd` on
  kleinbem/nixpkgs), with block-catch in #580909 (`block-catch: init at 0.5.1`, Catch 0.5.1 is what 0.6.5's
  `prepare-catch-sidecar.sh` expects). Both rebased onto master with Swift 6.4.2 on 2026-11-25, both reviewed by
  reckenrode. `kleinbem/nix-packages` has no berd package anymore.
- The package uses nixpkgs' `goose-cli` as `goosed`, shared sherpa-onnx (#449), and skips the move-to-Applications
  prompt (#457). On Darwin it carries `add-plugin-path-for-swift-macros.patch` (reckenrode's, 2026-11-19) because
  swift-rs can't pass Swift macro plugin paths; tracked in Brendonovich/swift-rs#87 (`swift-rs-contributing`) and
  NixOS/nixpkgs#590363 (closed).
- Our issues: #449 shared sherpa-onnx, #450 empty `Categories=`, #451 deep links and no single instance on Linux,
  #455 notification-listener rejection, #457 move-to-Applications build switch, #462 `goose serve` survives SIGTERM:
  open, no reply. #456 closed completed by johnmatthewtennant (2026-11-19); #452 (release with #272) closed by us
  after 0.6.5 shipped it (2026-11-25). Also block/catch#6, #7 (`catch-contributing`).
- Possible next issue (not filed, check first): v0.6.5 has no macOS assets and no updater promotion (release run
  41919286617, macOS job failed).

## Review checklist
Berd takes no PRs; the review before Martin files an issue (`upstream-contributing`, section 6)
checks the draft notes against sections 0 and 1:
- Searched open and closed issues; the closest one linked or "none found".
- Reproduced on the current release, version stated (a `main` build named by commit).
- One issue per issue; every form field in order; expected and actual as separate statements.
- Logs scrubbed; "unknown" instead of guessed details; nothing padded (CONTRIBUTING closes padded reports).
- No AI disclosure line (none required); Martin can answer every question in it.
- Feature requests: the problem first, non-goals present, why it can't be a skill or extension.
- Packaging issues: the problem, our workaround and the non-goal (no upstream Nix package) stated.
