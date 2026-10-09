---
name: nixpkgs-contributing
description: Use when preparing, committing, or reviewing a Nixpkgs contribution (new package, version bump, NixOS module change, backport) to pick the base branch, follow commit and meta conventions, and run the pre-push checks.
---

# Nixpkgs Contribution & PR Workflow

Sources of truth, in the Nixpkgs checkout: `CONTRIBUTING.md`, `pkgs/README.md`,
`pkgs/by-name/README.md`, `maintainers/README.md`. Read the relevant section
before acting on a rule from memory.

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
- Variants that are just an `override` (`foo-cuda`, `foo-vulkan`) get their own by-name package and
  a `# nixpkgs-update: no auto update` comment, like `llama-cpp-vulkan`. So does any package whose
  version must not be bumped on its own; update it from the script of the package that pins it.
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
   `nixos/doc/manual/release-notes/rl-<YYMM>.section.md`.
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
- **Process:** read the whole review before pushing, apply every suggestion or answer it, and
  don't make reviewers repeat themselves.

Practical notes:
- Run heavy builds one at a time; parallel Rust/CUDA/VM builds fail on memory.
- Check `substituteInPlace`/`--replace-fail` patterns against the source *after* `patches`
  (`nix-shell -A <attr>`, then `unpackPhase` and `patchPhase`), not the raw `src`: a patch may
  already have changed the line.
- A test suite that fails fast hides the next failure. Find them all in one pass with a
  `nix-shell -A <attr>` replay of the build and `cargo test --no-fail-fast` (or the equivalent).
