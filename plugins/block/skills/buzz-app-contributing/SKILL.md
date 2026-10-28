---
name: buzz-app-contributing
description: Use when preparing, updating, or reviewing a pull request or issue for block/buzz-app (Buzz 1.0, the new Tauri + React desktop/web client) to follow its AGENTS.md engineering standard, DCO and Co-authored-by rules, ready-for-review checklist, hooks and CI, and to know who reviews and how outside PRs fare.
disable-model-invocation: true
---

# block/buzz-app Contribution & PR Workflow

Summary as of 2026-10-28 (main `fea9f6ab`); five PRs prepared, none opened yet (section 9).

Layer 3 of 3: read `upstream-contributing` and `block-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to block/buzz-app and wins where they differ.

Sources of truth: `AGENTS.md` (root, the main policy), `docs/contributing.md` (commands, hooks,
CI, test layers), `src/shared/design-system/AGENTS.md` (UI work), `CODEOWNERS`, `.github/workflows/`,
the `main` rulesets. There is **no** `CONTRIBUTING.md`, **no** PR template, and `GOVERNANCE.md` only
links Block's org governance. Read them before acting on a rule from memory; they change daily.

Shape: Buzz 1.0 beta ("Buzz 0.X is still available and supported in block/buzz"). Created
2026-09-10; about 1,780 PRs and issues in seven weeks, a dozen Block engineers merging many PRs a
day, most PRs written and reviewed by agents. The app and Cargo package are now named `Buzz`
(#789), identifier `xyz.block.buzz.desktop` (#1656), version 0.7.0 (#1643). It is a client of
block/buzz's relay; only `buzz-audio-client` is shared code. Not the same repo as block/buzz:
different files, rules, toolchain and reviewers.

## 0. Hard rules that decide the agent's role
- **Outside PRs are accepted** (no close-external-prs gate), but outside merges are rare (section 7).
  The realistic contribution is a small, well-evidenced fix, or a precise issue.
- **AI use is expected.** `AGENTS.md` addresses agents directly. Agent attribution is a
  **`Co-authored-by` trailer**, not "none needed" as in block/buzz:
  > Credit the other party with a `Co-authored-by` trailer: an agent committing as its human
  > credits itself, and an agent committing as itself credits its human.

  So a commit that goes out as Martin carries `Co-authored-by: <agent> <noreply address>` for the
  agent that wrote it (per change, as always).
- **DCO sign-off on every commit** ("the hosted **DCO Check** fails without one, and hooks do not
  add it"). `DCO Check` is a required status check. Only after Martin reviewed the change.
- **`FOUNDATION` files** (source comment `FOUNDATION: <responsibility>`, ~15 of them): "require
  explicit human guidance before editing". From outside: don't touch them in a PR; raise it in
  an issue.
- **Human testing is Martin's** (ready checklist, section 5). Never mark it done for him.
- Texts: agent drafts, Martin reviews (repo has no rule against agent-written texts).
  Observed convention: comments an agent writes through a human account start with `🤖`
  (e.g. "🤖 Fixed in <sha>: …", #1325, #1498). Martin decides whether his replies follow it.

## 1. Before starting
- Search PRs and issues; many internal PRs are open at any time (183 open on 2026-10-28), and
  the area may already be in flight on a staff branch. Don't compete with an open PR.
- No issue-first rule. Issues are barely used (19 ever; outside issues #1037, #1090, #1569,
  #1600, #1613 have no reply). For anything beyond a small fix, the PR itself must carry the
  scope checkpoint below; expect a maintainer to rescope or take it over.
- `AGENTS.md` "Engineering standard": state outcome and **non-goals** first; for non-trivial work
  publish a **scope checkpoint** (required behaviour, non-goals, existing owners to reuse,
  expected files, rough production diff budget). Put it in the PR description.
- **9/10 bar for minimalness, elegance, correctness.** "No opportunistic refactors, speculative
  abstractions, or new features disguised as fixes." Reviewers score PRs against it.
- UI changes: read `src/shared/design-system/DESIGN.md` (decision table, whole-surface recipes)
  first and name the shared component/recipe you reuse. Icons only via
  `src/shared/design-system/icons` (Tabler); "icon and weight choices belong to the designer".
- Cross-host changes (browser vs desktop): read `docs/contributing.md`, "Shared logic and host
  boundaries". Policy goes into its `src/features/*` owner; keys, signing and I/O stay in the Rust
  host; don't add feature logic to `browser-host/`.
- Agent selection consumes `session.agentChoices` (`docs/agents.md#shared-agent-selection`).

## 2. Commits and title
- **Squash-only** (ruleset), so the PR title is the commit subject. No title validation.
  Conventional Commits are common but not required (674 of 1,154 merged titles); plain
  imperative sentences are equally normal ("Let plugin pages declare their own icon"). Use
  `type(scope): …` to stay consistent with block-org.
- Every commit: `Signed-off-by: Martin Kleinberger <email>` plus the agent's `Co-authored-by:`.
  Keep both when rewriting.
- Force-push: `AGENTS.md` says never rewrite others' commits; authorised rewrites use
  `--force-with-lease`. No "no force-push during review" rule (unlike block/buzz), but reviewers
  review exact heads (they cite SHAs), so push complete revisions.

## 3. What a mergeable PR contains
- **Regression coverage at the cheapest layer that observes the failure** (`docs/contributing.md`,
  "Choosing a test layer"): Vitest in Node for logic; RTL + jsdom for components (real React, no
  hook mocks); Playwright only for layout/scroll/native editing, in **both** Chromium and WebKit.
  A new browser journey needs a stated browser-only justification in the PR.
- **Deterministic tests** (`AGENTS.md`): gates/deferred promises instead of sleeps, no
  `waitForTimeout` (lint rejects it), no retries or relaxed tolerances, browser tests import
  `test` from `tests/browser/playwright-test.mjs`.
- **Fail-then-pass evidence**: reviewers and authors state that the test fails on the old code
  (#844, #1325).
- **Description** (no template): the merged PRs use free headings (`## Summary`/`## Details`,
  `## Why`/`## What`/`## Testing`, …). Include: problem with a reproduction on `main` (commit),
  fix, scope checkpoint/non-goals, exact validation with host and mode (see section 4), deferred
  checks, screenshots for UI in both themes. #1247 is a good outside example.
- UI: checked in both themes, narrow and wide, enlarged text, keyboard and pointer.

## 4. Pre-push gate
Upstream's gate is its Lefthook hooks plus CI; `just scan` is explicitly **not** a routine gate.
- Pre-commit hook: staged-name check, icon policy, Biome (`--error-on-warnings`), rustfmt.
- Pre-push hook: `tsc --noEmit` + related Vitest tests, `design:typecheck` + `design:check`,
  `cargo clippy --workspace --locked --all-targets -- -D warnings` (for Rust changes).
- **jj doesn't run git hooks.** Run them by hand before pushing: `bin/lefthook run pre-commit
  --all-files` and the push checks (`bin/pnpm exec tsc --noEmit`, `bin/pnpm exec vitest run
  <paths>`, `bin/pnpm design:typecheck && bin/pnpm design:check`, `bin/cargo fmt --all -- --check`,
  the clippy line above). On NixOS drop the `bin/` prefix and use the nix shells below.
- jj: `jj squash` into a described commit opens an editor; pass `--use-destination-message`.
- Manual testing of shipped behaviour uses `BUZZ_DEV_VIEWER= just desktop` (native path);
  broker-backed `just web` runs "do not count as acceptance". Report host and mode exercised.
- Before delivery, compare against the fetched `main`: "GitHub PR checks run the merged tree".

NixOS notes (as of 2026-10-28):
- Hermit pins just 1.58.0, Node 24.18.0, pnpm 11.8.0, Rust 1.98.1, stock Lefthook 2.2.2
  (the patched `2.2.3-buzz.1` is gone since #1644), CMake. We use nixpkgs instead of Hermit.
- Verified: `nix shell nixpkgs#nodejs_24 nixpkgs#pnpm_11 -c pnpm install --frozen-lockfile
  --ignore-scripts`; in that shell `node --test tests/integration/<file>` and
  `pnpm exec biome check --error-on-warnings <files>` run.
- Verified: `nix shell nixpkgs#cargo nixpkgs#rustfmt -c cargo fmt --all -- --check`.
- Rust desktop tests: run through the nixpkgs `buzz-app` package build (nixpkgs-review-gha
  runs), not locally.
- nixpkgs has rustc 1.99, pnpm_11 11.27, lefthook 2.1.15. nixpkgs' lefthook is still below
  `min_version` (2.2.2) and is rejected, so run the hook commands directly. Newer clippy may flag
  existing code: compare with `main`.
- Desktop (Tauri) needs WebKitGTK/GTK, libsecret, dbus (native notification tests), ffmpeg ≥ 8
  for media tests; borrow from a Nix build env of a Tauri package. Playwright browsers:
  nixpkgs' `playwright-driver.browsers` must match `@playwright/test` 1.63.0.
- Heavy suites belong on GitHub runners: the fork's own CI (`ci.yml` runs on `pull_request` and
  `workflow_dispatch`) or a pre-flight repo, not the workstation.

## 5. Ready for review
`AGENTS.md`, "Before opening a PR": open as **draft**; mark ready only when, scaled to the change
(docs-only: content, link and diff checks plus human confirmation):
1. an agent review ran under `AGENTS.md` "Reviewing" and its blockers were fixed or explicitly
   declined by the human;
2. an agent exercised the changed behaviour (native app where needed; relay changes against a
   local relay; CLI/tooling the command);
3. **the human tested it themselves**; the agent gives exact steps and expected results, waits
   for explicit confirmation, never ticks this itself;
4. then `buzz-review-completed` goes into the PR description; remove it and go back to draft if
   later edits change behaviour. (Rarely seen in practice: 5 of the last 100 merged PRs, but it
   is the written rule; follow it.)

Marking ready also triggers the Codex review (section 6).

## 6. CI, bots and reviewers
- Required to merge (`main-2` ruleset): `CI required` (aggregate of JS ×3, Rust and tool
  integration, browser measurements, 21 browser-journey shards, native fixture), `DCO Check`,
  **1 approving review from a code owner** (`@block/buzz-oss-team`; Builderlab plugin also
  `@block/buzz-builderlab-oss-team`). `require_extra_approval_for_unattributed_changes` is set
  (meaning unverified). Stale approvals are not dismissed on push. Unchanged on 2026-10-28.
- Fork PRs: only `DCO Check`, `Semgrep OSS`, `zizmor` run at first; `CI` sits in
  `action_required` until a maintainer approves the run (#1556, #1571, #1576 on 2026-10-23).
  Normal, not a failure. An approval alone doesn't unblock it: #1556 and #881 were approved
  (10-25, 10-26) and still had no `CI` run on 10-28. Windows validation is manual dispatch only;
  Linux CI is not Windows evidence (#1247 fixed tests that failed there).
- Advisory flake check reruns changed tests 10× per engine; a flaky new test shows up there.
- **Reviewers are mostly agents** run through maintainers' accounts:
  `chatgpt-codex-connector[bot]` (on open, ready, or `@codex review`; P1–P3 badges; reviews
  outside PRs too), wesbillman's "Star Lord" (Rocket/Mantis/Groot lanes, 9/10 score, cites
  reviewed head and base) and "Carl", kalvinnchau's, salman1993's and morgmart's agents
  (`🤖 [P2] …`), plus direct human comments (loganj, wesbillman). Per `AGENTS.md` they comment,
  rarely Request Changes; "recommend blocking" / unresolved P1/P2 is a blocker either way.
  Approvers on the last 150 merged (2026-10-28): kalvinnchau 38, wesbillman 32, loganj 32,
  baxen 18, salman1993 11, wpfleger96 7, ngoodger-block 5. Triage/merge of outside PRs seen from
  wesbillman, ngthuydiem (#1247), loganj (#1528).
- Recurring findings (sample of 60 merged PRs, 2026-10-23):
  - **Async/lifecycle ordering**: stale results after cancel/replace, state lost across
    remount or tab close, deferred visibility (#1527, #1521, #1325, #844, #1556).
  - **Bounded work**: unbounded accumulation or polling of terminal states (#1395, #1325).
  - **Necessity/scope**: unexplained incidental edits ("why change 60 to 40 in this PR? … move
    it to a separate PR", #1481); dead code after the change (#1475, #1405).
  - **Tests that can fail**: fixtures too uniform to catch the bug (#1481), coverage gaps proven
    by mutation (#1498).
  - **Accessibility**: accessible names, focus on disabled controls, contrast, `lang` (#1506,
    #1556, #1479, #35).
  - **Stale base**: conflicting heads are "not ready to merge into current main" (#35).
- Answer every finding in its thread: "Fixed in `<sha>`: <what>; <test> fails before, passes
  after" (#1556, #1527), or one line why not.

## 7. What the history shows (2026-10-28)
- 1,298 merged PRs since 2026-09-10; 43 from forks, almost all by Block/Square/Cash staff
  (company field, own-branch PRs, self-merges; the new ones since 10-23 are staff too, e.g. #1524
  merged by the author's `-square` account). At most three merged fork PRs from accounts
  without such signs: #93 (54 h), #1247 (109 h), #1528 (19 h). Internal PRs: median 11 h,
  p90 71 h to merge. GitHub's `CONTRIBUTOR` label means nothing here (staff keep membership
  private).
- Outside PRs still open on 2026-10-28: #35 (since 09-12, changes requested), #881 and #1556
  (approved, CI never run), #1571, #1576 (awaiting CI approval), #1051, #1052, drafts #448,
  #553, #1053, #1064, #1156.
- Closures without merge are mostly self-closures (retargeted, cherry-picked into a bigger PR:
  #946 into #941 with authorship kept, #1063).
- Releases: `Desktop previews` builds `main` every 6 h (00:17/06:17/12:17/18:17 UTC) into
  prereleases `v0.7.0-preview.<run>.<attempt>` (`v0.0.0-…` before #1643; 37 kept on 10-28, old
  ones and their tags pruned). Release tags `desktop-vX.Y.Z[-beta.N]` come from the
  "Desktop release tag" workflow (dispatched from `main`, annotated tag on a given `main` SHA):
  `desktop-v0.7.0-beta.1` (`d2f80496`) and `-beta.2` (`b0c92eae`), both 2026-10-27 by Kalvin
  Chau. They are tags only, no GitHub release. README still says "Builds come straight from
  `main`; there's no stable release channel yet."

Measurement commands (rerun on refresh):
```bash
gh api --paginate 'repos/block/buzz-app/pulls?state=all&per_page=100' --jq '.[] | {number, user: .user.login, assoc: .author_association, created: .created_at, merged: .merged_at, state, fork: (.head.repo.full_name != "block/buzz-app")}' | jq -s . > pulls.json
jq -r '.[]|select(.merged and .fork)|"\(.number) \(.user) \((((.merged|fromdate)-(.created|fromdate))/3600)|floor)h"' pulls.json
gh api repos/block/buzz-app/rules/branches/main
gh pr list -R block/buzz-app --state merged --limit 150 --json reviews --jq '[.[]|.reviews[]|select(.state=="APPROVED")|.author.login]|group_by(.)|map("\(.[0])=\(length)")|join(" ")'
```

## 8. After opening
- Expect silence until a maintainer approves CI; don't ping. If nothing moves for a week or
  two, one short message in the Buzz feedback community (invite in `README.md`, "Project
  resources"), sent by Martin. The bug template's Discord link is Block's dead invite.
- Keep the PR rebased on `main`; reviewers check integration with current main.
- Issues: `.github/ISSUE_TEMPLATE/bug-report.md` (Block boilerplate, title `[Bug] …`; fill
  reproduce/expected/environment). Martin files them in the browser.

## 9. Our setup and current threads
- Fork `kleinbem/buzz-app` not created yet. Clone `~/Develop/github.com/block/buzz-app` (jj
  colocated, cloned 2026-10-28), workspaces in `~/Develop/github.com/block/buzz-app.ws/`.
- Prepared, not opened (2026-10-28): five PRs: test tools on `PATH`; wipe refusal only in debug
  builds; `/bin/chmod` in the macOS ACL test; git shim fixture; `BUZZ_GOOSE_ACP_BINARY` for a
  prebuilt goose-acp. Plus an issue draft: build-time opt-out of Linux `buzz://`
  self-registration. The nixpkgs package carries a workaround for each, linked to its PR/issue.
- Downstream: nixpkgs draft NixOS/nixpkgs#577918 (`buzz-app`, built from a pinned `main`
  commit); it was waiting for the first `desktop-v*` tag, which now exists (section 7). Our
  block/buzz relay package serves 1.0 clients too (1.0 needs a relay from 2026-09-23 or later
  for `consistency: "strong"` reads).
- Thread: the Mesh-LLM SDK change (Mesh-LLM/mesh-llm#2241) also hits #941 (out of draft since;
  it uses `client::start`/`serve::start` and `disable_iroh_relays` on 0.78.1); the relay-switch
  draft Mesh-LLM/mesh-llm#2564 was closed. block/buzz#8557 is the 0.X side.

## Review checklist
For the review before ready (`upstream-contributing`, section 6; `AGENTS.md` "Reviewing"
requires it, and its findings are step 1 of section 5):
- Run the review as `AGENTS.md` "Reviewing" describes, on the merged tree against fetched `main`.
- Tests at the cheapest layer that observes the failure, deterministic (no sleeps,
  `waitForTimeout`, retries), fail-then-pass evidence (section 3).
- The pre-push gate ran by hand, since jj skips Lefthook (section 4), with host and mode stated.
- UI: both themes, narrow and wide, enlarged text, keyboard and pointer, screenshots.
- Commits: DCO sign-off only after Martin's review, `Co-authored-by:` for the agent (section 0).
- Body: problem with a reproduction on `main`, scope checkpoint and non-goals, exact validation;
  `buzz-review-completed` only after Martin tested it himself.
