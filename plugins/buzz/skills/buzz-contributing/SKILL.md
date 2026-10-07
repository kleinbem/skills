---
name: buzz-contributing
description: Use when preparing, updating, or reviewing a pull request to block/buzz (Buzz relay, desktop, CLI, agent crates) to follow its title, DCO, PR template, testing, and code-style rules and to run the checks before pushing.
---

# block/buzz Contribution & PR Workflow

Source of truth: `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md` in the repo.
Read them before acting on a rule from memory; they change.

## 0. Before writing code
- Search open PRs and issues for duplicates. The PR must link the closest one, or say "none found".
- Anything beyond a small fix: open an issue first and get the approach acknowledged.
  Large refactors, dependency swaps and style-only churn without one are usually closed.
- One logical change per PR. A bug fix plus a refactor is two PRs.

## 1. Commits and title
- Squash-merged: the PR title becomes the commit subject. Conventional Commits, type required
  (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`), scope encouraged: `fix(relay): …`.
- Every commit needs a DCO sign-off (`Signed-off-by: Name <email>`); the DCO Check blocks the PR
  without it. With jj, put the trailer in the description; when rewriting a pushed PR, keep it.
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
   `rust-toolchain.toml` (1.95 at the time of writing); a newer clippy flags existing code. Before
   blaming the change, check whether the warning is in files the PR touches, and say so in the PR.
3. The touched crates' tests, including the regression test (see 2).
4. `just ci` is the full gate ("PRs that fail `just ci` will not be merged"). If it can't run
   locally, state precisely which parts did run.

Environment notes (NixOS):
- Hermit's `bin/cargo` doesn't run on NixOS; use nixpkgs' toolchain
  (`nix shell nixpkgs#cargo nixpkgs#rustc nixpkgs#gcc nixpkgs#rustfmt nixpkgs#clippy`,
  plus `pkg-config openssl` for crates that need them).
- The desktop crate needs GTK/WebKitGTK and the built frontend (`desktop/dist`); test it in the
  environment of a Nix build (`nix-shell -A buzz-desktop`, unpack/patch/configure, `pnpm build`).
- Use one jj workspace per PR branch so the main checkout isn't disturbed.

## 5. What the reviewers check
Most reviews are automated agents run by the maintainers (`chatgpt-codex-connector`, "Jude's
code review agent" via jedwards27, "Carl" via wesbillman, wpfleger96's 🤖 reviews). They review
the exact head commit, rate findings P0–P3, block on P1/P2, and re-review after every push.
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

## 6. After opening
- Outside PRs wait until a maintainer authorises the Codex security review; until then the
  main CI is skipped. That is normal, not a failure.
- Don't ping individuals or teams. If nothing moves for a couple of weeks, open one issue
  that lists the related PRs and asks for triage.
- Updating a PR (force-push, editing the description) is fine and doesn't ping anyone.
