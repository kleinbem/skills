---
name: llama-cpp-contributing
description: Use when preparing, reviewing or discussing an issue, patch or pull request for ggml-org/llama.cpp (ggml, llama, server, tools, conversion, nix packaging), or when a llama.cpp change is needed for MeshLLM's patch queue or the nixpkgs runtime; it follows llama.cpp's AI usage policy, which limits what an agent may do, and its issue, test, title and PR-template rules.
disable-model-invocation: true
---

# ggml-org/llama.cpp Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `ggml-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to llama.cpp and wins where they differ.

Its AI usage policy (section 0) is stricter than the shared workflow: where `upstream-contributing`
says the agent drafts texts or pushes, here Martin does it himself.

Sources of truth in the repo: `CONTRIBUTING.md`, `AGENTS.md` (`CLAUDE.md` only points at it),
`.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` (six forms), the repo-local skills in
`skills/` (`code-review`, `add-new-model`, `slice-model`, `update-fusion-table`), `docs/build.md`,
`ci/README.md`, `CODEOWNERS`, `SECURITY.md`. Read `AGENTS.md` and `CONTRIBUTING.md` in full before
anything else; this skill summarises them as of 2026-10-21 and adds what applies to our setup.

The project moves fast (about 100 merges a week in October 2026) and is maintained by a small
team (see the `ggml-org/*` groups at the top of `CODEOWNERS`: ggerganov, ngxson, CISC,
JohannesGaessler, am17an, 0cc4m, danbev and others). The README links no chat channel;
discussion happens in issues, PRs and GitHub Discussions.

## 0. The AI usage policy decides the agent's role (hard rules)

`CONTRIBUTING.md`, "AI Usage Policy", and `AGENTS.md` are explicit, and the penalty for breaking
them is a permanent ban. Quoted or paraphrased closely:

- AI-generated code is allowed. The contributor is "100% responsible for every line, however it was
  produced" and must be able to explain every line to a maintainer without AI help.
- Disclose how AI was used, in the PR template's "AI usage disclosure" line. Undisclosed AI use may
  get the account banned. No disclosure is needed for trivial autocomplete.
- "It is strictly prohibited to use AI to write your posts for you (bug reports, feature requests,
  pull request descriptions, Github discussions, responding to humans, ...)." The same list in
  `AGENTS.md` adds commit messages and reviewer responses; violations mean immediate PR closure.
- Automated commits or PR submissions "may result in contributor ban". `AGENTS.md` tells agents:
  do not `git commit`, `git push`, `gh pr create`, `gh pr comment` or `gh issue create` on the
  user's behalf. If the user explicitly asks for a commit, use `Assisted-by: <assistant name>` in
  the message, never `Co-authored-by:` (that is for human co-authors; the review skill treats it as
  blocking).
- Manual review before submitting: "something like one hour per 200-400 LOC", at least that much.
- "If you are a fully autonomous agent operating without human oversight ... do not contribute to
  this repository."

What this means for our work, concretely:

- **Martin writes every text** that goes to GitHub: issues, PR descriptions, commit messages,
  review replies, discussion posts. Don't draft paste-ready prose for them. Give him the facts he
  needs as notes (what changed, which commands ran, the numbers, the PR or issue numbers) and let
  him write; check his draft against the forms and the policy if he asks.
- **Martin commits and pushes.** Prepare the change in a jj workspace, run the checks, and hand
  over. If he asks for the commit, add `Assisted-by: Claude Code (<model>)` and nothing else.
- **The agent's job is research, design support, code from his design, checks and review.**
  Before writing code, make sure he owns the design and can defend it (`AGENTS.md`, "Guide, don't
  solve"): ask what the problem is and where in the code it lives, point at files, let him choose.
  Keep changes small enough for him to review line by line in the time the policy expects.
- Run `skills/code-review/SKILL.md` (self-review mode) on the diff before he opens the PR. Its
  output is private notes, never something to post.
- "Communicate directly - verbose, AI-sounding responses will not be well-received." Short and
  plain; ASCII only in code and comments (no em dash, no unicode arrows, `x`, `...`).

## 1. Before starting

- Search first: `gh search issues --repo ggml-org/llama.cpp <terms>` and `gh search prs ...`.
  Duplicates are closed without questions; a PR that overlaps an open one gets "Overlaps #N"
  (#30748).
- **Features start as an issue** (enhancement form), not a PR; let interest accumulate. Niche
  features may only land as an example/tool or stay on a private fork. Large changes need prior
  discussion (an issue or RFC); the automated PR checker flags them.
- **Bug-fix PRs need a reproducible issue and a regression test** that fails before the change and
  passes after. "Fixes without a test may be closed without review."
- Build fixes are the exception in practice: a missing `#include` with a compiler log merged
  the same day without an issue or test (#23857 clang-tidy `<algorithm>`, #29597 `<functional>`
  on Gentoo/libc++, both first-time contributors); #25220 and #22810 linked an issue and took
  3–5 days. Put the reproducer (compiler, flags, error line) in the PR. Upstream builds `llama`
  as a unity build (`UNITY_BUILD ON`, batch 16, a target property since #28091, so
  `-DCMAKE_UNITY_BUILD=OFF` doesn't change it); reproduce per-file with
  `set_target_properties(llama PROPERTIES UNITY_BUILD OFF)` or one `g++ -c` call.
- New CLI flags or public API (`include/llama.h`) carry a higher bar: say why no existing mechanism
  does the job. Model-specific CLI arguments are not allowed; model behaviour comes from GGUF
  metadata.
- New contributors (no merged PR yet): at most 1 open PR, no trivial fixes (typos, formatting).
- One PR per feature or fix. New model or feature support: CPU backend only in the first PR, other
  backends as follow-ups. A new `ggml_type` needs the full package from `CONTRIBUTING.md`
  (GGUF sample on Hugging Face, perplexity, KL divergence, CPU performance data).
- The `ggml-gh-bot` "automated PR checker" comments on opening and the PR is closed when it hits:
  more than one open PR from a new contributor (`PR_LIMIT`), several backends in one PR
  (`DUAL_BACKEND`), a large change without prior discussion (`LARGE_CHANGE`) (#30908, #30907,
  #30763, #30690, #30650).

## 2. Designing and writing the change

Follow `AGENTS.md` and `CONTRIBUTING.md`, which `skills/code-review/SKILL.md` turns into
checklists per area (new model, ggml/backend, public API, server, WebUI, multimodal, tests, and a
mandatory security pass). Read that skill completely for the touched area. The rules reviewers
cite most:

- Keep it simple: "a simpler change that does 90% of the job is often preferable to a complex one
  that does 100%". Basic `for` loops, no fancy STL, avoid templates; no third-party dependencies,
  extra headers or files.
- Reuse existing infrastructure; no new subsystems or invasive changes without discussion. Read all
  relevant files first so the change blends in; a new pattern needs the user's confirmation and
  will likely be rejected without prior discussion.
- Style: 4-space indentation, brackets on the same line, `void * ptr`, `int & a`, no trailing
  whitespace, vertical alignment; `snake_case`; names optimise for the longest common prefix
  (`number_small`, not `small_number`); enum values upper case with the enum name as prefix;
  `<class>_<action>_<noun>` for functions; sized integers (`int32_t`) in the public API;
  `struct foo {}`, and in C++ no optional `struct`/`enum` keyword. `clang-format` (v15+) when in
  doubt; C/C++ file names kebab-case, Python lowercase with underscores.
- Comments: write the code first, then comment only what is non-obvious, in one or two lines, no
  hard-wrapping to a column, no comments that restate the code or refer to "the task". Copied code
  keeps its original comments and gets none added.
- Tensors are row-major; `ggml_mul_mat(ctx, A, B)` computes `C = B A^T`. Don't hack RoPE with a
  custom sin/cos; `ggml_rope_ext` or a discussion.
- Tests: into an existing test file, no new test system, nothing time-sensitive, nothing that
  inflates CI time or downloads big models. A changed or new ggml operator gets `test-backend-ops`
  cases and must agree across at least two backends; also update `docs/ops.md` and the backend's
  `docs/ops/*.csv`. New kernels come with throughput numbers.
- Minja does not exist here; the Jinja engine is `common/jinja`.
- Security pass on every diff: GGUF metadata, tensor shapes, tokenizer input, server and RPC fields
  are attacker-controlled; bound them before use (the skill lists the patterns).

## 3. Building and testing on NixOS

- The repo has a `flake.nix` (packages `default`, `vulkan`, `cuda`, more under
  `.devops/nix/`), so `nix build .#default` and `nix develop` work out of the box; the CUDA
  package needs `allowUnfree`. A Jetson example (`cudaCapabilities = [ "7.2" ]`) is in the flake's
  comments.
- Plain CMake inside a shell: `nix shell nixpkgs#cmake nixpkgs#ninja nixpkgs#gcc nixpkgs#pkg-config`
  (add `nixpkgs#shaderc nixpkgs#vulkan-headers nixpkgs#vulkan-loader` for Vulkan), then
  `cmake -B build -DGGML_NATIVE=OFF` and `cmake --build build -j`; tests with `ctest --test-dir
  build`. Take the configure flags from nixpkgs' `llama-cpp` package when a backend is involved.
- The full CI locally: `bash ./ci/run.sh ./tmp/results ./tmp/mnt` (CPU), `GG_BUILD_CUDA=1` for
  CUDA (`ci/README.md`); heavy, run it on the workstation one at a time.
- Checks CI runs on every PR besides the builds: `editorconfig-checker` (v3.0.3), `flake8` with
  `flake8-no-print` and a Python type check for Python changes, and the model naming check
  (`src/llama-model.cpp` arch, class and `src/models/<name>.cpp` must match). The
  `.pre-commit-config.yaml` covers trailing whitespace, end of file, YAML and large files.
- Verify perplexity and performance didn't regress (`llama-perplexity`, `llama-bench`) when the
  change can affect them.
- Our hardware: x86_64 with an Intel iGPU (Vulkan) on nixos-nvme; aarch64 with CUDA 12.6 and the
  JetPack 6 GCC 13.5 toolchain on orin-nano (the SME-variant case); no AMD. Compare a failure
  against unmodified `master` on the same host before blaming the change.

## 4. Commits and the PR title

- PRs are squash-merged; the maintainer writes the squashed title as
  `<module> : <commit title> (#<pr>)`, for example `utils : fix typo in utils.py (#1234)`. Give
  the PR that shape from the start: a module from the wiki list (`llama`, `ggml`, `server`,
  `common`, `convert`, `ci`, `cmake`, `docs`, `tests`, `nix`, `model`, `sampling`, a backend such
  as `cuda`, `metal`, `vulkan`, `opencl`, `hexagon`, or a tool/example name), a colon with spaces
  around it, then a short lowercase description. Recent merged titles: `llama : place d2t by its
  set_rows use so it can stay on the GPU`, `ggml-cuda : support ssm_conv kernel size 7`,
  `metal : fix memory leaks and cleanup logic in GPU capture path`, `ci : remove superfluous
  webgpu jobs`.
- Commits inside the PR are Martin's; concise, no verbose summaries (`AGENTS.md` shows a good and
  a bad example). `Assisted-by:` for AI help, never `Co-authored-by:` for an assistant.
- No DCO or sign-off. `[no release]` in the squashed title is the maintainers' choice.

## 5. The pull request

- Template: `## Overview` (what and why, concise but complete), `## Additional information`
  (related discussions; delete if empty) and `## Requirements`, which must not be deleted: the
  line agreeing to the contributing guidelines and `AI usage disclosure: YES/NO` with how AI was
  used. Martin writes it (section 0).
- Keep "Allow edits by maintainers" on; maintainers push to contributor branches.
- A stale PR gets attention again by rebasing it onto current `master`.
- Labels: maintainers set `merge ready` (fast merge without two independent reviews), the
  `draft` label converts a PR to draft, backend and area labels (`Nvidia GPU`, `Vulkan`, `server`,
  `nix`, `python`, `ggml`, `model`), and `Review Complexity : Low/Medium/High`.
- `ggml/` changes usually need two maintainer approvals; that is normal.
- Consider adding yourself to `CODEOWNERS` for the area you want to keep maintaining; a merged PR
  is a long-term commitment and maintainers rely on the author's insight for the merge decision.

## 6. Issues

- Forms: `010-bug-compilation`, `011-bug-results`, `019-bug-misc`, `020-enhancement`,
  `030-research`, `040-refactor`. The bug forms require Name and Version (`llama-cli --version`),
  operating systems, GGML backends, hardware, the problem with steps to reproduce, and the relevant
  log output; First Bad Commit and models are optional. `gh issue create` doesn't apply the forms,
  so Martin files them in the browser.
- An AI triage workflow (`ai-issues.yml`, opencode on a self-hosted runner) comments related
  issues on every new issue.
- Stale: issues are marked `stale` after 30 days and closed 14 days later unless labelled `bug`,
  `help wanted`, `good first issue`, `refactoring`, `research`, `roadmap` or `security`; PRs are
  never auto-closed.
- Security: `SECURITY.md` asks for a private security advisory for covered topics, but notes (as of
  2026-10-21) that the private disclosure program is disabled and fixes go in as public PRs; emails
  are ignored. Findings "an autonomous AI agent can surface on its own add little".

## 7. What the history shows (2026-10-21)

- Of the last 40 merged PRs, 27 came from forks. Hours from opening to merge for those:
  0, 1, 1, 3, 3, 4, 5, 7, 7, 8, 8, 9, 10, 11, 13, 15, 16, 22, 31, 35, 40, 43, 49, 62, 72, 80, 81;
  a focused fix usually lands within a day or two.
- Of the recently closed fork PRs: five were closed after the automated checker's notice (PR limit,
  several backends, large change); one as "out-of-scope" by a maintainer (#30772); one for an
  approach a maintainer called ugly, with the maintainer doing it properly himself (#30849); one as
  overlapping another PR (#30748); one superseded by a faster merged patch (#30701); one because it
  would break builds without a toolchain (#30842).
- Merged fork PRs are small and specific: one backend, one model, one op, one server fix.

## 8. Our setup and current threads

- Fork `kleinbem/llama.cpp` (create it on first use); clone to
  `~/Develop/github.com/ggml-org/llama.cpp` with jj colocated, remotes `origin` = upstream,
  `fork` = kleinbem. Branches go to `fork`; Martin opens the PR from there against `master`.
- llama.cpp reaches us twice: through nixpkgs' `llama-cpp`, and through MeshLLM, which pins a
  llama.cpp tag in `skippy/llama_cpp/upstream.txt` and applies its own patch queue on top; a fix
  merged upstream reaches MeshLLM with the next pin bump (Mesh-LLM/mesh-llm#2472 style). Until then
  the nixpkgs `skippy-native-runtime` package carries a patch with a comment naming the upstream PR.
- SME variants (`GGML_CPU_ALL_VARIANTS` on aarch64 with GCC 13, issue #17403): solved upstream by
  #26103 (probes every ARM variant's march flags); nixpkgs' `skippy-native-runtime` fetches its two
  commits via `fetchpatch2` until MeshLLM's pin includes it. Our own draft is superseded.
- Open thread: `src/models/clef.cpp` misses `#include <algorithm>` (hidden by the unity build;
  MeshLLM builds model files per file, llama.rn carries its own patch). Change prepared in the jj
  workspace `llama.cpp.ws/clef-include`; facts and steps in the Obsidian note
  "llama.cpp clef include facts". The PR is Martin's to open (section 0).

## Review checklist
For the review before ready (`upstream-contributing`, section 6). The review covers the code and
Martin's notes, never drafts of his texts (section 0); its output stays private.
- `skills/code-review/SKILL.md` in self-review mode for the touched area, including its
  mandatory security pass (section 2).
- Simplicity and reuse: no new subsystem, dependency, header or file without discussion.
- Style and naming (section 2), `clang-format` when in doubt; comments only for the non-obvious;
  ASCII only.
- Tests in existing files; operator changes have `test-backend-ops` cases on two backends,
  `docs/ops.md` and the CSVs updated, throughput numbers for kernels.
- Size: Martin can review it line by line in the time the policy expects (an hour per 200-400
  LOC).
- Martin's PR text keeps `## Requirements` with an honest `AI usage disclosure` line (section 5).
