---
name: mesh-packaging-contributing
description: Use when preparing, updating, or reviewing an issue or pull request to Mesh-LLM/mesh-packaging (native .deb and Arch packages, OCI images, the Homebrew formula and the npm SDK assembled from mesh-llm release archives) to follow its composition-only rules, matrix, tests, commit and PR conventions.
disable-model-invocation: true
---

# Mesh-LLM/mesh-packaging contribution workflow

Layer 3 of 3: read `upstream-contributing` and `mesh-llm-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill holds only what is specific to Mesh-LLM/mesh-packaging and wins where they differ.

Sources of truth: `AGENTS.md`, `README.md`, `TODO.md`, `docs/` (`native-packages.md`,
`matrix.md`, `publishing.md`, `package-signing.md`, `packaging-readiness-gaps.md`,
`release-checklist.md`), `packaging/images.json`, `.github/workflows/`, and the repo-local skill
`.skills/distribution-certification/`. There is no `CONTRIBUTING.md`, no PR or issue template
and no `CODEOWNERS`. As of 2026-11-17: 46 PRs, nearly all from `ndizazzo` (agent-driven
`codex/*` branches, merged by himself within the hour) and `i386`; 1 star, 4 forks.

## 0. Hard rules

- **Composition only.** The repo never compiles mesh-llm, llama.cpp or the UI. It verifies the
  published upstream release archives (product-v2 bundle: backend-neutral host plus exactly one
  native runtime) and repackages those bytes. Packaging Precheck greps workflows and Docker
  files for `git clone`, `cargo build`, `pnpm … build` and self-hosted runners and fails on a
  hit. A source-built channel (Nix, AUR source packages) doesn't belong here; a binary one
  (a `-bin` PKGBUILD, winget) can.
- **One flow** (`AGENTS.md`): host artifact + runtime artifact → product bundle → native
  package → runtime image. No second path that puts a binary into an image without the package.
- **A new distro, backend or format changes every layer in one PR:** `packaging/images.json`,
  `scripts/image-matrix.ts` and its tests, the `docker/install-*.sh` helpers, package metadata
  in `packaging/native/build-package.sh`, workflows and `docs/`.
- **TODO discipline** (`AGENTS.md`): a multi-step change adds `TODO.md` items with a concrete
  `QA:` clause and ticks them only after that check ran.
- New scripts are TypeScript/Node (`node --experimental-strip-types`), shell only for platform
  helpers.
- Attribution follows `mesh-llm-org`: no agent trailers. No policy file of its own; the recent
  squashed commits carry none (one older `Co-authored-by` on #35 is a human).
- Package repositories (apt, pacman, apk) are blocked on signing by decision
  (`docs/package-signing.md`, `packaging-readiness-gaps.md`): don't propose one before that
  exists. Alpine waits for upstream musl archives, Intel macOS for an x86_64 archive.

## 1. Before starting

- Search here and in Mesh-LLM/mesh-llm: bundle contents (file modes, duplicate libraries,
  licenses, the `tools/` binary, glibc floor) are produced by mesh-llm's
  `skippy/scripts/package-native-runtime.sh` and release workflow, and get fixed there. Only
  what this repo adds (layout, metadata, dependencies, QA, images, formula) is fixed here.
- The product-v2 schema exists twice (`schemas/product-v2.schema.json` here and in mesh-llm)
  and the release plan byte-compares them at the upstream commit. A contract change is a
  coordinated pair of PRs.
- Maintainers fold overlapping branches into one of their own: #30 to #33 and the outside #36
  were closed as "incorporated into merged #38". Expect that for anything touching code they
  are reworking; an issue with the evidence can be as useful as the PR.
- Open threads: #41 (winget channel, Virgile-pct), #42 (Windows guest runner image), #37
  (0.79 support, kept open for release evidence).

## 2. Designing the change

- Verify on the published artifact first: `gh release download packaging-v<ver> -R
  Mesh-LLM/mesh-packaging -p '<file>'`, then list it (`tar --zstd -tvf` for `.pkg.tar.zst`,
  `ar p <deb> data.tar.zst | tar --zstd -tv`) and compare with the upstream archive
  (`gh release download v<ver> -R Mesh-LLM/mesh-llm`). The build script alone misleads:
  `actions/download-artifact` writes every file back as `0644` (the uploaded zip still
  records the modes), so anything passed between jobs as a directory loses its executable bits.
- Packages are deliberately uniform: name `mesh-llm` for every variant, host in
  `/usr/local/bin`, product tree in `/usr/local/lib/mesh-llm/<version>/` with a
  `native-runtimes` symlink beside it. Filenames carry version, distro, arch, backend and
  backend version. A layout change touches `docker/qa-runtime-image.sh`,
  `scripts/native-package-qa.sh`, `scripts/runtime-discovery-smoke.sh` and the tests.
- Drivers and devices are never package dependencies; CUDA rows declare no toolkit dependency
  because the runtime bundles cudart/cuBLAS (`docs/native-packages.md`).
- QA must reach client readiness: `client --auto` without a GPU, JSON `Client ready` or the
  `passive_mode`/`status=ready`/`role=client` event, then bounded SIGINT shutdown.
  `--version` alone is not accepted as runtime QA.
- Builds are reproducible on purpose (`SOURCE_DATE_EPOCH` from the upstream commit, sorted
  tar, fixed owners). Keep a change deterministic; the Docker fixture tests compare SHA-256
  across two builds.

## 3. Building and validating on NixOS

From `README.md` ("Local validation"); Node 24 from nixpkgs is enough, no install step:

```bash
nix shell nixpkgs#nodejs_24 nixpkgs#shellcheck nixpkgs#actionlint -c bash -c '
  node --experimental-strip-types scripts/image-matrix.ts validate &&
  node --experimental-strip-types --test --experimental-test-coverage \
    --test-coverage-lines=100 --test-coverage-branches=100 --test-coverage-functions=100 \
    tests/image-matrix.test.ts &&
  node --experimental-strip-types --test --test-concurrency=1 tests/*.test.ts &&
  find docker packaging scripts -name "*.sh" -print0 | xargs -0 shellcheck && actionlint'
```

- `tests/image-matrix.test.ts` must keep 100% line, branch and function coverage.
- Docker fixture suite (real `dpkg-deb`/`pacman` installs, reproducibility, layer checks):
  `MESH_PACKAGING_DOCKER_TESTS=1 node --experimental-strip-types --test tests/package-build-efficiency.test.ts`.
  Without the variable those tests skip (2026-11-17 on nixos-nvme: 215 tests, 212 pass,
  3 skipped, 38 s). It calls `docker`; where only podman exists, run it on a GitHub runner.
- The release workflow runs on the fork as a manual dry run
  (`gh workflow run images-release.yml -R kleinbem/mesh-packaging --ref <branch> -f mesh_ref=v<ver>
  -f mesh_version=<ver> -f native_selector=all`), with two test-only changes on a throwaway
  branch: `depot/setup-action` and `depot/build-push-action` replaced by
  `docker/setup-buildx-action` and `docker/build-push-action` (drop `project:`, give the
  `build-id`/`project-id` outputs a literal), and `--repository "Mesh-LLM/mesh-packaging"` for
  `release-handoff.ts create`, which rejects any other name. A full run takes about 25 minutes.
  Add a control run that should fail, and say in the PR what the test branch changed (#47).
- A local build of one row: verify the archive with `scripts/upstream-archive.ts`, put the
  result in `artifacts/upstream`, then `podman build -f docker/Dockerfile.mesh-llm --target
  native-package-artifact --output type=local,dest=<dir>` with the row's build args. Built that
  way, the 0.80.0 Arch CPU package was byte-identical to the published asset.

## 4. Commits

- Conventional Commits, scopes in use: `fix(packaging)`, `docs(release)`, `feat(ci)`, `ci`,
  `docs`. Squash merge; the ruleset on `main` requires linear history, so the PR title is the
  commit.

## 5. Pull request

- No template. The house style in merged PRs: the bug or reason first (#25 opens with the
  failing command and its output), then the fix, then what ran. Keep our usual short form.

## 6. CI and bots

- One workflow for PRs, `Packaging Precheck` (job `validate`), triggered only by changes
  under `.github/workflows/`, `docker/`, `docs/`, `packaging/`, `scripts/`, `schemas/`,
  `tests/` and `README.md`. Fork runs wait for approval (`action_required` on #42).
- CodeRabbit skips its automatic review ("fewer than 10 stars"); a maintainer can trigger it
  by hand, and then expects answers per finding (#38).
- No required checks and no required reviews in the ruleset (deletion, force-push and linear
  history only).

## 7. What the history shows

```bash
gh pr list -R Mesh-LLM/mesh-packaging --state all --limit 60 \
  --json number,author,isCrossRepository,createdAt,mergedAt,state \
  --jq '.[] | "#\(.number) \(.author.login) cross=\(.isCrossRepository) \(.state) \(.createdAt[0:10])→\((.mergedAt // "-")[0:10])"'
```

2026-11-17:
- Three outside PRs so far. #25 (Homebrew runtime broken by keg relocation; a reproduced user
  bug with the failing output) merged after 10 days. #36 (keep bundled plugins) was folded
  into #38 after three weeks. #42 is open with one change requested by `i386`, who reviews
  against mesh-llm's current pins (sccache version from Mesh-LLM/mesh-llm#3047).
- Maintainer PRs merge in minutes to hours, usually without a human review.
- Demand is small: the 0.79.0 Arch and `.deb` assets have 1 to 6 downloads each
  (`gh api repos/Mesh-LLM/mesh-packaging/releases --jq '.[0:3][] | .tag_name as $t | .assets[] | "\($t) \(.name) \(.download_count)"'`).
  A fix is argued with correctness, not with user counts.

## 8. Our setup

- Clone `~/Develop/github.com/Mesh-LLM/mesh-packaging` (jj colocated), remotes `origin`
  (upstream) and `fork` (`kleinbem/mesh-packaging`, Actions enabled), one jj workspace per
  branch in `mesh-packaging.ws/`.
- Open: #47 (runtime tools lose their executable bit; draft since 2026-11-17).
- Downstream angle: our source-built packages (nixpkgs `mesh-llm` and `skippy-native-runtime`,
  `kleinbem/aur-packages`) install into `<prefix>/lib/mesh-llm/native-runtimes`, the same
  discovery path these packages use, so layout and dependency findings carry over in both
  directions.

## Review checklist

- No source build, clone or self-hosted runner introduced (section 0; the precheck greps).
- Every layer of a row change is in the PR: `images.json`, matrix script and tests, install
  helpers, package metadata, workflows, docs (`AGENTS.md`).
- `tests/image-matrix.test.ts` still at 100% coverage; the Docker fixture suite ran with
  `MESH_PACKAGING_DOCKER_TESTS=1`, not skipped (section 3).
- The claim was checked on a published or locally built package, not on the script (section 2).
- Package output stays byte-reproducible for the same inputs and `SOURCE_DATE_EPOCH`.
- `TODO.md` items have a `QA:` clause and are ticked only for checks that ran.
- A bundle-content problem went to Mesh-LLM/mesh-llm, not here (section 1).
