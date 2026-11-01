---
name: buzz-contributing
description: Use when preparing, updating, or reviewing a pull request to block/buzz (Buzz relay, desktop, CLI, agent crates) to follow its title, DCO, PR template, testing, and code-style rules and to run the checks before pushing.
disable-model-invocation: true
---

# block/buzz Contribution & PR Workflow

Layer 3 of 3: read `upstream-contributing` and `block-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to block/buzz and wins where they differ.

Source of truth: `CONTRIBUTING.md`, `AGENTS.md` and `.github/PULL_REQUEST_TEMPLATE.md` in the
repo, summarised here as of 2026-11-01. Read them before acting on a rule from memory; they change. `AGENTS.md` holds the product
contract, the ready-for-review checklist and upstream's own "Review-Proven Rules".

## 0. Before writing code
- Search open PRs and issues for duplicates. The PR must link the closest one, or say "none found".
- Anything beyond a small fix: open an issue first and get the approach acknowledged.
  Large refactors, dependency swaps and style-only churn without one are usually closed.
- One logical change per PR. A bug fix plus a refactor is two PRs.
- Non-trivial changes: read `VISION.md`, the `VISION_*.md` docs for the affected surface and
  `TESTING.md` (plus any package-local one) first; the design must not work against them
  (`AGENTS.md`, "Product Contract").
- Changes to `migrations/`, `schema/` or schema-dependent `buzz-db` queries: read
  `docs/database.md` first. No new triggers, functions or foreign keys, no data backfills in
  migrations, update every schema location, and stay compatible with the deployed relay (#8273).
  Run `./bin/pgschema apply` from the repo root, or a re-apply drops runtime partitions (#8487).
- Apply `AGENTS.md`'s **Review-Proven Rules** before writing code; upstream mined them from its
  own review threads, and authors fix 70–100% of these findings once flagged:
  1. every caught failure leaves a durable retry record or propagates (no catch-log-succeed);
  2. fence async results by generation, clear derived metadata on every removal path;
  3. regression tests bind the production seam and are falsifiable (`TESTING.md`);
  4. bound every resource, loop and process tree;
  5. one user action = one atomic persist;
  6. a guard must not hide the only recovery affordance;
  7. new UI: audit assistive semantics (one owner per label, no duplicate screen-reader stops);
  8. every input modality (keyboard, pointer, hotkey) is a first-class seam.
- `desktop/` is legacy, being replaced by block/buzz-app: never use it as a reference for
  `mobile/`, but keep mobile's event payloads wire-compatible with the other clients (#8868).
- Architecture conventions (`AGENTS.md`, "Key Patterns"): prefer a new Nostr event kind
  (`buzz-core/src/kind.rs`, handler in `buzz-relay`) over a new HTTP endpoint; channels scope by
  `h` tag; agent-facing operations go into `buzz-cli` first.

## 1. Commits and title
- Squash-merged: the PR title becomes the commit subject. Conventional Commits, type required
  (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`), scope encouraged: `fix(relay): …`.
- Every commit needs a DCO sign-off (`Signed-off-by: Name <email>`, `git commit -s`); the DCO
  Check blocks the PR without it. `git rebase` and `git cherry-pick` need `--signoff` too. With jj, put the trailer in the description; when rewriting a pushed PR, keep it.
  The sign-off certifies the human owner wrote the change: only add it once they have reviewed it.
- AI-assisted PRs are welcome and need no disclosure, but the human owns and must have reviewed
  the final code. Clearly unreviewed submissions get closed.

## 2. What a mergeable PR contains
- **Tests:** new behaviour has tests; a bug fix has a regression test that fails without the fix.
  Prove it by running the test on `main` (fails) and on the branch (passes). If a test is
  impractical, say why in the description.
- **Docs:** new config variables documented. Desktop/agent env vars go in `README.md`
  (e.g. `BUZZ_SHELL`); relay settings in `.env.example`. New event kinds, MCP tools, APIs per
  the CONTRIBUTING how-tos.
- **UI changes:** before/after screenshots or a short recording.
- **Description** follows the template: `## Summary`, `### Related issue` (link or "none found"),
  `### Testing` (exactly what was run). Also the key decisions/trade-offs and any deferred
  follow-up.

## 3. Code style
- `cargo fmt --all` (default rustfmt). `cargo clippy --all-targets --all-features -- -D warnings`.
- `#![deny(unsafe_code)]` everywhere; `thiserror` for libraries, `anyhow` in binaries;
  no `unwrap()`/`expect()` outside tests; `tracing` with structured fields.

## 4. Pre-push gate
1. `cargo fmt -p <crate> -- --check` for every touched crate. Run it on the crate, not on single
   files: standalone `rustfmt` fails on files with `mod …;` and reports false alarms.
2. `cargo clippy -p <crate> --all-targets --no-deps -- -D warnings`. The repo pins Rust in
   `rust-toolchain.toml` (1.98.1 as of 2026-11-01, #8598); a newer clippy flags existing code. Before
   blaming the change, check whether the warning is in files the PR touches, and say so in the PR.
3. The touched crates' tests, including the regression test (see 2).
4. `just ci` is the full gate ("PRs that fail `just ci` will not be merged"). If it can't run
   locally, state precisely which parts did run.

Environment notes (NixOS):
- Hermit's `bin/cargo` doesn't run on NixOS; use nixpkgs' toolchain
  (`nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#gcc nixpkgs#rustfmt nixpkgs#clippy`,
  plus `pkg-config openssl` for crates that need them).
- The desktop crate needs GTK/WebKitGTK and the built frontend (`desktop/dist`); test it in the
  environment of a Tauri app's Nix build (`nix-shell -A goose-desktop` in nixpkgs, then `pnpm build`).

## 5. Ready for review
`AGENTS.md`: open work as a **draft** and mark it ready only when, scaled to the change:
1. an agent review ran and its blockers were fixed or explicitly declined by the human;
2. an agent exercised the changed behaviour (app flow, local relay, or the changed command);
3. **the human tested it themselves**. The agent gives exact steps and what working looks like,
   then waits for explicit confirmation; never mark this step done for them;
4. then `buzz-review-completed` goes into the PR description. Automated reviewers may skip a PR
   because of it, so it is an attestation: remove it (and go back to draft) if later edits
   change behaviour.

## 6. What the reviewers check
Most reviews are automated agents run by the maintainers: `chatgpt-codex-connector`, "Jude's
code review agent" (jedwards27), "Carl"/"Star Lord" (wesbillman) and wpfleger96's 🤖 reviews.
They review the exact head commit, rate findings P0–P3, block on P1/P2, and re-review after
every push. Per `AGENTS.md` they post findings as comments, never as Request Changes, so a
comment saying "Blocking" or "recommend blocking" is a blocker without a formal review state.
Recurring findings (#7991, #7121, #4741, #6583, #7261, #7756, #2633, #2968):
- **Edge-case correctness:** races, lifecycle (work outliving teardown), two processes or turns
  overwriting each other's state, recovery paths that delete newer data.
- **Falsifiable tests:** a regression test must fail without the fix and exercise the real
  path; "can pass without exercising repair" is a blocker.
- **Error classification:** each failure maps to the right user-facing category (a storage
  failure must not surface as "sign in again"); don't lose the underlying message.
- **Subprocesses:** check exit status and stderr, not only stdout.
- **Required CI on every platform** (incl. Windows) green; the PR's own new tests failing blocks.
- **`unsafe`:** needs explicit maintainer authorization, and SECURITY.md/CONTRIBUTING must match.
- **Big PRs** get "structurally blocked" (e.g. migration-number collisions with `main`); keep
  them focused and rebased.

Etiquette among contributors: don't open a competing PR. If someone already has one, build on
it (a PR against their branch, or a review comment), keep their authorship, and credit them.
Downstream (nixpkgs) can carry their commits with `fetchpatch2` meanwhile.

## 7. After opening
- Advisory `Flake check (…)` lanes rerun the tests a PR changed ten times with retries off
  (`CONTRIBUTING.md`, #8613). Not required to merge, but a failing repetition is usually a race
  worth fixing before review.
- Outside PRs only get the DCO, Semgrep, zizmor and security-authorisation checks. The main CI
  (builds, tests, desktop E2E) starts when a maintainer authorises it, often by closing and
  reopening the PR (#5997, #7216). That is normal, not a failure.
- Expect weeks to months. Of the last 300 merged PRs, 12 came from outside contributors (not bots or Block staff); they
  took 6 days to 75 days to merge (median about 8 weeks), while internal PRs often merge within
  hours. The maintainer triaging outside PRs (ngthuydiem) validates the fix before and after
  with concrete commands (#7998, #2669, #7619), so put copy-paste reproduction steps and the
  expected before/after output in `### Testing`.
- Independent confirmation helps: a linked issue where others reproduced the bug on their
  platform (#3700, #5600).
- Don't ping individuals or teams. If nothing moves for a couple of weeks, open one issue
  that lists the related PRs and asks for triage.
- Official channel: the **Buzz feedback community** (a Buzz community, not Discord; invite link
  in `README.md`, section "Community"), for questions and feedback. Block's Discord invite is
  dead (2026-10-22). One short message there, sent by Martin, after the triage issue.
- Keep the PR mergeable: rebase when it conflicts with `main` (triagers resolve conflicts
  otherwise, #2255). Before any review, force-pushing is fine; **once a review started, push new
  commits instead** (`CONTRIBUTING.md`: "don't force-push during review").

## Review checklist
For the review before ready (`upstream-contributing`, section 6; `AGENTS.md` requires it):
- `AGENTS.md`'s Review-Proven Rules (section 0), one by one against the diff.
- Regression test fails on `main` and passes on the branch, through the production seam
  (section 2); `TESTING.md` followed.
- Docs: new config variables in `README.md` or `.env.example`; event kinds, MCP tools, APIs per
  the CONTRIBUTING how-tos.
- Migrations and schema: `docs/database.md` rules, every schema location updated.
- Style (section 3): no `unwrap()`/`expect()` outside tests, `#![deny(unsafe_code)]`, `thiserror`
  vs `anyhow`, `tracing` fields; fmt and clippy per touched crate.
- Commits: Conventional Commits, DCO sign-off only after Martin's review.
- Body: Summary, Related issue ("none found" if so), Testing with copy-paste steps and expected
  before/after output; `buzz-review-completed` only after Martin tested it himself (section 5).
