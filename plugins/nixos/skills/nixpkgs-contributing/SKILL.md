---
name: nixpkgs-contributing
description: Use when preparing, committing, or reviewing a Nixpkgs contribution (new package, version bump, NixOS module change, backport) to pick the base branch, follow commit and meta conventions, and run the pre-push checks.
disable-model-invocation: true
---

# Nixpkgs Contribution & PR Workflow

Layer 3 of 3: read `upstream-contributing` and `nixos-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Nixpkgs and wins where they differ.

Sources of truth, in the Nixpkgs checkout: `CONTRIBUTING.md`, `pkgs/README.md`,
`pkgs/by-name/README.md`, `maintainers/README.md` (summarised here as of 2026-10-21). Read the
relevant section before acting on a rule from memory.

## 0. Before starting
- Search open and closed PRs (and issues) for the package first:
  `gh search prs --repo NixOS/nixpkgs "<attr>"`. Build on or credit existing work instead of duplicating it.

### Decide the base branch first
- Check rebuild count (CI `rebuild` labels; estimate locally beforehand).
  - < 500 → `master`
  - 500–999 → `master`, but consider `staging`
  - ≥ 1000 (mass rebuild) → `staging`
  - Kernel changes or `10.rebuild-nixos-tests` → `staging-nixos`
- Never target `staging-next` except to fix Hydra failures on it (ask #staging:nixos.org first).
- Release fixes: land on `master`, then backport (`backport release-YY.MM` label if maintainer,
  else `git cherry-pick -x` onto `release-YY.MM`, PR title prefixed `[YY.MM]`).
  Separate PR to `release-YY.MM` only if the change can't be identical. Mass rebuilds → `staging-YY.MM`.

## 1. Commits
- `<attr>: init at <version>` | `<attr>: <old> -> <new>` | `<attr>: fix build` | `nixos/<module>: <summary>`
- `maintainers: add <handle>` as a separate commit, before the package commit.
- No trailing period; one commit per logical unit; squash fixups.
- Version bumps: body links the changelog/release notes.
- Use unversioned set names (`python3Packages.foo`, not `python313Packages.foo`).
- LLM-assisted work: `Assisted-by: <tool> (<model + version>)` trailer. `Co-authored-by` does not count.
  Disclose in the PR description too. Every line must be reviewed and understood by the human submitter.
- The trailer is free-form but needs at least the tool name and the model name with version
  (e.g. `Assisted-by: Claude Code (claude-opus-5-5)`). Attributions in another format can get a
  PR closed (`CONTRIBUTING.md`, "Enforcement").
- Draft PRs are exempt from the full self-review requirement, as long as some review was done and
  the full review happens before marking ready. Useful to run CI or nixpkgs-review-gha early.
- Running `nix-update` or other standard community automation is exempt; an LLM writing the
  change or its commit message is not.
- The disclosure also applies to PR comments and reviews, and to any tooling used to verify
  the output (`CONTRIBUTING.md`, "Automation/AI policy").

## 2. Derivation rules
- New top-level `callPackage` packages: `pkgs/by-name/<2-letter-prefix>/<attr>/package.nix`.
  Not for nested sets (python3Packages etc.). No references outside the package dir.
- `version` starts with a digit; untagged commits use `<last-release>-unstable-YYYY-MM-DD` (or `0-unstable-…`).
- Fetch with the most specific fetcher (`fetchFromGitHub`, full commit hash or `tag = version;`).
  Patches via `fetchpatch2` with a descriptive `name`; vendor only Nixpkgs-specific/unstable patches.
- No IFD; no new in-tree `overrideAttrs`; overridden phases wrap with `runHook pre…`/`post…`.
  Instead of `overrideAttrs` (`pkgs/README.md`, "`overrideAttrs` and `overridePythonAttrs`"):
  - Use the main version of the dependency if at all possible.
  - Need another version: factor out a function that builds multiple versions, including the main one.
  - Need an option: add an explicit argument to the package and use `override`.
  - Need a patch in a dependency: ask its maintainers whether it can go into the main version.
- `strictDeps = true` and `__structuredAttrs = true`: nixpkgs-vet fails new top-level packages
  that don't evaluate with both (NPV-164 to 167, v0.3.x; `buildRustPackage` already sets
  `strictDeps`). Check with `nix-instantiate --eval -E 'with import ./. {}; { inherit (<attr>)
  strictDeps __structuredAttrs; }'`.
- Variants that are just an `override` (`foo-cuda`, `foo-vulkan`) get their own by-name package and
  a `# nixpkgs-update: no auto update` comment, like `llama-cpp-vulkan`. So does any package whose
  version must not be bumped on its own; update it from the script of the package that pins it.
- Build with the default `stdenv` compiler. A build error from a newer GCC (a missing `#include`,
  a stricter warning) gets a patch with the upstream issue or PR linked, not `gcc14Stdenv` or
  `overrideCC`. Only about 15 packages pin an older GCC, mostly unmaintained code (procmail,
  cuneiform); the others document why and when the pin can go (`libpqxx`: "solved when 8.x is
  released"); old GCCs get removed (gcc9/gcc10 in 2025), which breaks their pins. CUDA's
  `backendStdenv` picks its own GCC for nvcc (GCC 14 with CUDA 12.9), so a CUDA build can fail
  where the CPU build passes, and the other way round: build every backend.
- Don't run prebuilt tools during the build either: e.g. replace `protoc-bin-vendored` with
  nixpkgs' `protobuf` (`PROTOC`), as `gitlab` does. Vendored Rust crates live under `$cargoDepsCopy`.
- `meta` last:
  - `description`: one capitalised sentence, no leading article, doesn't name the package, no trailing punctuation.
  - `license`: `lib.licenses.<id>` matching upstream (`unfree` if none).
  - `maintainers`: set for new packages, e.g. `[ lib.maintainers.<handle> ]`.
  - `mainProgram`: hardcoded string, only if one main executable exists.
  - `platforms`: set. `sourceProvenance`: set if not built from source.
- Add `passthru.updateScript = nix-update-script { };` where it works; link `passthru.tests` / `nixosTests`.

## 3. Pre-push gate
1. `nix fmt` (or `nix-shell --run treefmt`)
2. `./ci/nixpkgs-vet.sh master`
3. `nix-build -A <attr>` (sandbox enabled)
4. `nix-build -A <attr>.passthru.tests` and any relevant `nixosTests.<name>`
5. Run the binaries in `./result/bin` with a meaningful invocation (not just `--help`)
6. `nixpkgs-review wip` (pre-commit) or `nixpkgs-review pr <N>` (after push) to build dependents.
   In a shallow clone, nixpkgs-review's fetch of the base fails ("unrelated histories"): create a
   local base branch and pass `--remote file://<clone> --branch <base>`.
   Read results with `--print-result`; posting them (`--post-result`, or a nixpkgs-review-gha
   run that comments) is a public action that needs the submitter's explicit OK.
   A nixpkgs-review-gha run shows "success" even when packages failed to build; judge it with
   `scripts/review-result <run-id>` (per-system built/failed from the report, non-zero exit on
   any failure, `--wait` to block until done), never by the run status.
7. A new NixOS module gets an entry under "New Modules" in
   `nixos/doc/manual/release-notes/rl-<YYMM>.section.md`. A major or breaking package change
   gets a Nixpkgs release note in `doc/release-notes`; a package removal gets a throwing alias
   instead of a note (`CONTRIBUTING.md`, "Release notes").
8. Fill in the PR template checkboxes honestly (platforms tested, sandboxing, review run).
   Tick a box only once it is true for the exact commits being pushed.

## 4. What reviewers commonly ask for
Recurring themes from committer reviews of comparable PRs (Tauri/Rust apps, services with
modules: #549345, #398998, #265771, #507754, #442904, #302495, #324127, #416148, #287923, #278454).
- **Explain every non-obvious choice in a Nix comment**, including why a test is skipped or
  `doCheck = false` (e.g. "no tests", "skipped in upstream CI too" with a link).
- **Patches:** turn non-trivial inline `substituteInPlace` into patch files. For each hunk ask
  "does it need Nix-specific knowledge?"; if not, it belongs upstream (link the upstream PR).
  The reviewer checklist (`pkgs/README.md`, "Reviewing contributions") requires every patch to
  have a comment with either the upstream URL or the reason it wasn't upstreamed; an upstream
  PR is a plus, not a condition. Patches available remotely are fetched (`fetchpatch2`), not vendored.
- **Build FOSS from source**; prebuilt binaries are for unfree software. When compiling from
  source, don't `patchelf` rpaths: `buildInputs` already end up in the rpath.
- `fetchFromGitHub` with `tag = "v${version}"` rather than `rev`; `lib.getExe pkg` rather than
  `${pkg}/bin/pkg`; build tools (`pkg-config`, `cmake`) in `nativeBuildInputs`.
- **Tests:** link `passthru.tests` to `nixosTests`; new-style NixOS tests (no `handleTest`).
- **NixOS modules:**
  - configuration as RFC 42 `settings` (freeform, via `pkgs.formats.*`, with sensible defaults);
  - secrets never in `settings` or the store, only loaded from files (`EnvironmentFile=` or
    systemd credentials);
  - a full systemd hardening set (e.g. generated with `shh`), `systemd.tmpfiles.settings` for dirs.
- **Derivation shape** (from review feedback collected by others): `strictDeps = true`;
  `finalAttrs` instead of `rec`; `makeBinaryWrapper` when the wrapper needs no shell logic;
  no top-level `with lib;`; keep build-only tools out of the runtime closure; `--set-default`
  rather than `--set` for env vars users may want to override; install shell completions,
  desktop files and icons when upstream ships them.
- **Scan of 299 merged `init at` and `nixos/` PRs (2026-10-19, about 2000 reviewer comments),
  by number of PRs where reviewers raised it.** Most are one-line `suggestion` blocks, so get
  them right before review:
  - `finalAttrs` instead of `rec` (58 PRs), with `tag = "v${finalAttrs.version}"` (28) and
    `changelog = ".../releases/tag/${finalAttrs.src.tag}"`;
  - maintainers (39): one set for every new package, added in its own first commit
    `maintainers: add <handle>`; `maintainers = with lib.maintainers; [ … ]` is fine, `meta = with
    lib;` is not (20, an ongoing removal effort);
  - `meta.description` (34): short, no article, no package name; the rest goes in
    `longDescription`;
  - commits (23): squash fixups, lowercase `<attr>: init at <version>`, PR title matching;
  - `versionCheckHook` (`doInstallCheck = true; nativeInstallCheckInputs = [ versionCheckHook ];`)
    and `passthru.updateScript = nix-update-script { };` are common suggestions (14 PRs each);
  - `doCheck = false` set explicitly with the reason, even though it's the default for some
    builders (#569767);
  - `makeBinaryWrapper` over `makeWrapper`; build-time tools and hooks in `nativeBuildInputs`;
  - build from source instead of downloading a release binary, also for plugins (#546167);
  - usual attribute order: `pname`, `version`, `src`, `nativeBuildInputs`, `buildInputs`, phases,
    `passthru`, `meta` (#383450).
  - Reviewers object to LLM-style text: "LLM comments are usually way too long and verbose"
    (#571214), and some only review PRs whose template checkboxes, incl. the AI policy, are
    filled in (#556686).
- **NixOS modules, official checklist** (`nixos/README.md`, "Reviewing contributions"): every
  option has a type, a default, an example and a description; module `meta.maintainers` and
  `meta.doc` set; module tests added to the package's `passthru.tests`; nothing unneeded in
  `environment.systemPackages`; the module works with other modules. Reviewers also ask for
  `environmentFiles` (a list) over a single file and for documented `settings` keys the module
  reads itself, so `cfg.settings.x or default` isn't needed (#519655, #552984).
- **Process:** read the whole review before pushing, apply every suggestion or answer it, and
  don't make reviewers repeat themselves.

Practical notes:
- Check `substituteInPlace`/`--replace-fail` patterns against the source *after* `patches`
  (`nix-shell -A <attr>`, then `unpackPhase` and `patchPhase`), not the raw `src`: a patch may
  already have changed the line.
- A test suite that fails fast hides the next failure. Find them all in one pass with a
  `nix-shell -A <attr>` replay of the build and `cargo test --no-fail-fast` (or the equivalent).
- A fresh nixpkgs worktree has its tracked symlinks as plain files (`/etc/gitconfig` sets
  `core.symlinks = false`), and treefmt's editorconfig check fails on them. Restore them:
  `git ls-files -s | awk '$1==120000{print $4}' | while read f; do rm "$f"; git -c core.symlinks=true checkout -- "$f"; done`.
- Before dropping a workaround because "the upstream fix merged", grep the source at the new pin
  for every path that still needs it, or build once without it. A fix covers the path its PR
  names, not every path with the same symptom (#571722: #2492 fixed `serve`, two
  `scan-refresh` tests still needed `cacert`).
- Eval isn't verification. Build the narrow derivation that runs the check: the NixOS manual
  for module docs, the package's tests, the VM test.

## Building and testing in the kleinbem setup
The workstation (nixos-nvme) is for builds and behaviour tests that need a built binary or local
hardware; checks and full builds go to GitHub runners.
- **kleinbem/nixpkgs-review-gha** (fork of Defelo's):
  - `build.yml` takes flake refs (`-f packages="github:kleinbem/nixpkgs/<sha>#attr …"`), so it
    tests a fork branch before the PR is switched. `review.yml` runs nixpkgs-review on a PR number.
  - Defaults: x86_64 + aarch64-linux, aarch64-darwin, x86_64-darwin `no`, `post-result=false`
    (posting needs Martin's OK), `on-success=nothing`.
  - darwin: tests with `__darwinAllowLocalNetworking` need `yes_sandbox_relaxed` (as Hydra);
    `yes_sandbox_true` refuses them. At most 2–3 darwin runs a day, never two at once; collect
    everything one run can tell. "Not acquired by runner" means stop for the day.
  - A job ends at GitHub's 6 h limit. Big multi-variant PRs (CPU+Vulkan+CUDA+ROCm runtimes) don't
    fit on x86_64: run nixpkgs-review for that platform on nixos-nvme, whose store already holds
    earlier test builds.
  - A green run doesn't mean everything built: read the per-package report (`scripts/review-result`).
    aarch64 never runs VM tests (no KVM on GitHub's ARM runners).
  - Never `gh workflow disable` these workflows; cancel a run instead. They have been disabled from
    outside several times (no entry in Martin's security log): re-enable only the one you need and
    say so; if it keeps happening, GitHub Support with workflow ids and times.
  - Estimate run times from the last comparable run. GitHub times are UTC.
- **Caches:** public Cachix `kleinbem-nixpkgs-review` (review runs push) is for sharing builds with
  testers; Attic (cache.kleinbem.dev) is Martin's private buffer, never point others at it.
- **Shadow packages** in kleinbem/nix-packages that will move to nixpkgs follow this skill from day
  one (by-name shape, `finalAttrs`, tests, `meta`), so the nixpkgs PR is a copy. A NixOS module
  re-exported from a nixpkgs branch must drop `meta.doc`: every host builds the manual and rejects
  chapters missing from nixpkgs' `redirects.json`. Export `{ config, lib, pkgs, ... }:` that
  imports the file with exactly those args (deadnix strips unused `@args`) and removes
  `meta.doc`; test with `nix build .#nixosConfigurations.<host>.config.system.build.manual.manualHTML`.

## Review checklist
For the review before ready (`upstream-contributing`, section 6):
- Commits: `<attr>: init at …` / `<old> -> <new>` / `nixos/<module>: …`, one per logical unit,
  `maintainers: add` first, `Assisted-by: <tool> (<model + version>)` on each commit the agent
  touched (section 1); PR title matches.
- Base branch fits the rebuild count (section 0).
- Derivation shape (section 2 and the 2026-10-19 scan in section 4): `finalAttrs`, `tag =`,
  `strictDeps`/`__structuredAttrs`, attribute order, `meta` complete (description style, license,
  maintainers, `mainProgram`, platforms), updateScript, version check.
- Every patch, `substituteInPlace`, skipped test and `doCheck = false` has a comment with the
  upstream link or the reason; patches available remotely are fetched.
- Variants and pinned packages carry `# nixpkgs-update: no auto update`.
- Modules: `nixos/README.md`'s checklist (type, default, example, description per option;
  `meta.maintainers`, `meta.doc`), RFC 42 `settings`, secrets only from files, hardening,
  `passthru.tests` linking the NixOS test, release note, `redirects.json` entries.
- NixOS tests: new style, falsifiable, no `! cmd` no-ops under errexit.
- PR body: template kept, boxes true for the exact head (nixpkgs-review-gha judged by its report,
  not the run status), AI disclosure, short, "I".

Mechanical consistency checks, run them (don't eyeball) before ready. `nix-check-nixpkgs-pr` in
kleinbem/nix-toolbox does the first four (the option check only notes unlinked `{option}`) (`--log` for warnings, `--drvs-against <rev>` for the
derivation comparison); run it in the PR worktree. Builds and tests don't catch
these; an outside review of #571722 found two after a week of green runs:
- Every variant's `meta.position` points into its own file (`nix-instantiate --eval -A
  <variant>.meta.position`). A bare `.override` keeps the base file's position, so nixpkgs-update
  never sees the variant's opt-out; re-anchor it like `llama-cpp-vulkan` does
  (`overrideAttrs` that re-inherits `meta.description`).
- Each variant file matches its model (`pkgs/by-name/ll/llama-cpp-vulkan/package.nix`); diff the
  variant files against each other.
- Option references in module docs that should link use `[](#opt-…)`: nixos-render-docs renders
  `{option}\`…\`` as plain code without a link (`html.py`); both forms are allowed. Check the
  built manual, not the source, before claiming a link renders.
- Every workaround comment names its upstream PR or the reason (`grep -n -i 'workaround\|fixed
  upstream\|drop with' …`), and the link matches the PR's current state (merged, open).
- Re-check that unchanged derivations stay unchanged after a fix (`nix-instantiate` before and
  after), so you know whether tests must rerun.
- Read the warnings of the green runs, not only the failures: group them (`grep -i warning log |
  sed` away numbers and store hashes `| sort | uniq -c`) and sort them into ours, harmless and
  upstream. Fix ours (e.g. a NixOS test passing `timeout=120` instead of
  `dt.timedelta(...)`, a test-driver deprecation), explain the harmless ones (cmake `unused-cli`
  for options the build never reads), and note upstream ones as a possible PR.
- Judge outside review findings yourself before applying them: severities are often wrong, and a
  suggestion can contradict nixpkgs practice (e.g. marking a wrapper unfree when only its
  dependency is).
