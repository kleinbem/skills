---
name: skippy-contributing
description: Use when preparing, updating, or reviewing a pull request or issue for Mesh-LLM/skippy (Skippy inference runtime, CLI, llama.cpp patches, skippy-api) to follow its build, validation, acceptance-criteria gate, and PR rules.
disable-model-invocation: true
---

# Mesh-LLM/skippy Contribution & PR Workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to `Mesh-LLM/skippy` and wins where they differ.
PR and issue numbers (`#108`) refer to `Mesh-LLM/skippy` unless another repository is named.

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md`, `.github/PULL_REQUEST_TEMPLATE.md`,
`.github/workflows/pr-checks.yml`, `.github/workflows/ci-pr.yml`, `.github/scripts/pr-checks.cjs`,
`clippy.toml`, `rust-toolchain.toml`, `Justfile`, and `.agents/skills/` (`strong-types`, `manage-ci`).
Summary as of 2026-11-22. The repository was transferred from `general-inference/skippy` to
`Mesh-LLM/skippy` and made public in #108; active maintainers are `i386` (James Dumay), `jaredwy`,
and `michaelneale`.

## 0. Hard rules that decide the agent's role

- **AI attribution:** org rule (`mesh-llm-org`): no agent or bot attribution trailers
  (`Co-Authored-By: Claude …`, `[bot]` accounts) in commits or the squashed PR message. AI help may
  be stated in the PR text. Agent drafts, Martin reviews.
- **No DCO sign-off**, but the PR template's **Acceptance criteria** checkbox includes an explicit
  Apache-2.0 contribution license agreement (`- [x] I agree to license my contributions under the Apache License, Version 2.0.`). Martin generally agrees to this license grant (2026-11-22), so it may be ticked on draft PRs prepared for him.
- **No issue required:** `AGENTS.md` and the PR template explicitly state "An issue is not required."
  Search open/closed issues and PRs first as usual (`upstream-contributing`, section 1).
- **External fork PRs:** Martin does not have write access to `Mesh-LLM/skippy` (unlike
  `Mesh-LLM/mesh-llm`). External fork PRs require workflow approval from a `Mesh-LLM` member with
  write access and run on GitHub-hosted / Depot runners rather than persistent native lab hardware (#108).

## 1. Before starting

1. Read `AGENTS.md` and `CONTRIBUTING.md`, plus `.agents/skills/strong-types/SKILL.md` before adding
   domain types in `crates/` (or `skippy_api/AGENTS.md` and `skippy_api/TYPE-RULES.md` for C++).
2. Search `Mesh-LLM/skippy` AND `Mesh-LLM/mesh-llm` for existing issues/PRs: Skippy was split out of
   `Mesh-LLM/mesh-llm` (consumed externally in `Mesh-LLM/mesh-llm#3193`), so older discussions or
   open PRs may still live in `Mesh-LLM/mesh-llm`.
3. Note active consolidations before touching CLI crates (e.g. #111 plans to fold `skippy-quantize`
   into `skippy-cli`).

## 2. Designing the change

- **Layout:** root Cargo workspace owns `crates/*` and `tools/process-supervision`. `skippy-api-rs/`
  is a separate Rust facade workspace checked independently; `skippy_api/` is the C++ facade.
  Native `llama.cpp` source is pinned in `llama_cpp/upstream.txt` with ordered patch queues under
  `llama_cpp/patches/`.
- **Clippy limits (`clippy.toml`):** `cognitive-complexity-threshold = 20`,
  `too-many-lines-threshold = 200`, both warned in `[workspace.lints.clippy]` and denied in CI.
  Extract separable responsibilities rather than silencing warnings.
- **Offline default tests (`CONTRIBUTING.md`, `AGENTS.md`):** default tests must run offline with
  isolated temporary state—no network, no writable `HOME`, no undeclared system tools, and no
  missing-fixture/device skips pretending to pass hardware qualification.
- **Native ABI & patches (`AGENTS.md`):** keep `llama_cpp/upstream.txt`, patch queues, ABI
  declarations, Rust bindings/version constants, and generated docs in lockstep. Model-specific
  behavior belongs in model builders, not family-name branches in shared stage machinery.
- **Build scripts (`AGENTS.md`):** prefer shell for simple orchestration and Python for structured
  manifest parsing / verification under `scripts/`. Honor supplied native source inputs without
  downloading replacements.

## 3. Building and validating on NixOS

- **Toolchain (`rust-toolchain.toml`):** Rust `1.99.1` (`clippy`, `rustfmt`). Use `Just` (`just build`,
  `just test`, `just lint`) or run Cargo serially in each checkout (`AGENTS.md`: never run concurrent
  Cargo commands in one checkout).
- **Changed Rust crates (`AGENTS.md`):** run `cargo fmt --check`, focused `cargo check`,
  warning-denying all-target Clippy (`cargo clippy --all-targets -- -D warnings`), and full tests
  including integration and doc tests (`cargo test`).
- **Standalone CLI / dynamic runtime:** `just skippy-cli-build` builds `skippy-cli` with
  `--features dynamic-native-runtime`; runtime discovery reads `SKIPPY_NATIVE_RUNTIME_BUNDLE_DIR`
  (not `MESH_LLM_NATIVE_RUNTIME_BUNDLE_DIR`).
- **Packaging sanity check:** `kleinbem/nix-packages` has `canary/skippy/run.sh` (nightly workflow
  `Canary: skippy`) building `skippy-native-runtime`, `skippy`, `skippy-tools`, and `serve` against
  `Mesh-LLM/skippy` `main`.

## 4. Commits

- **Titles:** plain imperative sentences, no Conventional Commits prefix (observed across 40 recent
  merged PRs, e.g. `Fix CUDA compiler image licenses and toolkit symlinks` #167,
  `Block PR merges until acceptance criteria are complete` #159).
- **No agent trailers** (`mesh-llm-org`); no DCO `Signed-off-by:`.

## 5. Pull request

- **Mandatory template:** always use `.github/PULL_REQUEST_TEMPLATE.md` verbatim as the base
  (`Original problem`, `Diagnostics`, `Fix`, optional `Usage`/`Architecture`/`Compatibility`,
  `Validation`, and `Acceptance criteria`).
- **Enforced gate (`PR checks` / `.github/scripts/pr-checks.cjs`, added in #159):** rejects missing
  or unchecked items in `## Acceptance criteria`. Retain both standard checkboxes:
  - `- [ ] I ran the relevant local checks, or explained why they do not apply.`
  - `- [ ] I agree to license my contributions under the Apache License, Version 2.0.`
  Check them only when satisfied; editing the PR description re-triggers `PR checks`.
- Keep `Validation` separate from `Original problem` and `Fix`; state exact commands, features,
  observed results, and any unrun checks with reasons.

## 6. CI and bots

- **Required gate:** `PR checks` (`.github/workflows/pr-checks.yml`, `Evaluate aggregate PR checks`)
  validates the PR body's acceptance criteria and aggregates every applicable workflow (`CI PR`,
  `Documentation PR`, `CI images PR`, etc.) plus external check runs and commit statuses.
- **Fork routing (`.github/workflows/ci-pr.yml`, #108):** external fork PRs run `ci-pr.yml`
  (reusing `ci.yml@main`) after a `Mesh-LLM` member approves the workflow run; protected native
  hardware runners are restricted to trusted same-repository PRs.
- **No CodeRabbit / GI bot:** GI code review agent config was removed in #148; `main` requires
  `PR checks` and one approving review (#108).

## 7. What the history shows

Measured 2026-11-22 (`gh pr list -R Mesh-LLM/skippy --state merged --limit 40 --json number,title,author,isCrossRepository`):

- **40 recent merged PRs:** `i386` (31), `jaredwy` (5), `michaelneale` (3), `danielwinterw` (1);
  only 1 cross-repository PR so far (repo went public in #108 with zero external forks at cutover).
- **PR quality bar raised in #157 and #159:** maintainers explicitly tightened PR description
  standards (problem/diagnostics/fix/validation separation) and added the automated acceptance
  criteria gate in `pr-checks.cjs`.
- **CI hygiene:** `i386` actively keeps automation/docs PRs off native builds (#168) and enforces
  strict offline/hermetic default tests (`CONTRIBUTING.md`).

## 8. Our setup and current threads

- **Fork & clone:** fork `kleinbem/skippy`, clone `/home/martin/Develop/github.com/Mesh-LLM/skippy`
  (`origin` upstream, `fork` ours), jj workspaces under `../skippy.ws/`.
- **Downstream packaging:** `kleinbem/nixpkgs` (`mesh-llm-dev`, `NixOS/nixpkgs#571722` stack) carries
  `skippy-native-runtime`, `skippy`, and `skippy-tools`; `kleinbem/nix-packages` watches `main`
  nightly via `canary/skippy/` (`Canary: skippy`).
- **Carryover PRs from `Mesh-LLM/mesh-llm`:** sibling binary lookup (#170, from
  `Mesh-LLM/mesh-llm#3134`/`#3025`) and CA-less HTTP tests in `skippy-analytics` and
  `skippy-correctness` (#171, from `Mesh-LLM/mesh-llm#3138`/`#2740`), both opened as drafts on
  2026-11-22 and tracked in `kleinbem/nix-packages` `watch/upstream-prs/prs.txt`.

## Review checklist

- Does the PR title use a plain imperative sentence (no Conventional Commits prefix) and match the
  final diff (`AGENTS.md`)?
- Does the PR body use `.github/PULL_REQUEST_TEMPLATE.md` with `Original problem`, `Diagnostics`,
  `Fix`, `Validation`, and both standard `## Acceptance criteria` checkboxes retained (section 5)?
- Are there zero agent/bot attribution trailers in commits or PR text (`mesh-llm-org`)?
- Do changed crates pass `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings` (within
  `clippy.toml`'s complexity 20 / 200-line thresholds), and offline `cargo test` without network,
  CA bundle, or writable `HOME` (`AGENTS.md`, section 2–3)?
- If touching `crates/`, were `.agents/skills/strong-types/SKILL.md` rules checked?
- If touching `llama_cpp/` or ABI, were `upstream.txt`, patch queues, ABI constants, and generated
  docs updated in lockstep (`AGENTS.md`)?
