# Case: Block's Buzz (buzz-cli, buzz-relay, buzz-app)

Merged: buzz-cli co-maintainer (#569636, 2.4 days), buzz-cli 0.5.28 (#577535, 3.3 days). Open:
buzz-relay + module (#574877), buzz-app (#577918, draft). Closed: seven single-package drafts
(#569154–#569247), the six-package suite (#570552), buzz-desktop (#571723), goose 1.56 (#578469,
duplicate of a maintainer's #578652).

## What went wrong, and the rule it produced

- **Seven PRs in two days, then one PR with six packages.** Both stalled; a reviewer called the
  bundle "too many changes … hard to review" and worried about "many patches … coupled with fast
  changing upstream" (#571723). → One PR per concern, smallest and shared base first, the next
  once the first has traction.
- **Three weeks on the 0.X desktop line**, then upstream moved to a new repo (block/buzz-app). →
  Check roadmap, office-hours notes and new repos before a big desktop package.
- **Version churn** (0.1.0-unstable dates → tags → a renamed binary) → settle the scheme once;
  for repos with several tag families use `nix-update --version-regex '^desktop-v(.*)$'`.
- **Copies in nix-packages drifted from the PRs** → the registry re-exports the PR's own files.
- **block/buzz merged no outside PR** (security review needs a maintainer first; outside merge
  rate ≤6 %). → With slow upstreams, carry linked patches and keep them few; spend effort where it
  merges (the surrounding community: Mesh-LLM, mulatta's buzz.nix, sebfried).
- **Metadata errors** (wrong `githubId`, over-attribution forcing a push on an approved PR) →
  mechanical checks before pushing; attribution per change.

## Desktop (Tauri) packaging, as it works now (buzz-app)

- `cargo-tauri.hook`, `buildAndTestSubdir = "src-tauri"`, `doNotPostBuildInstallCargoBinaries`;
  `tauriBuildFlags = [ "--no-sign" "--config" (toJSON …) ]` overriding `beforeBuildCommand`
  (upstream's fetches and builds a sidecar with git) and darwin's `minimumSystemVersion`.
- `fetchPnpmDeps` with the pnpm major from `packageManager` and the `fetcherVersion` that pnpm
  needs (5 for pnpm 11; needs nixpkgs ≥ 2026-10-23).
- Resources: Tauri looks in `<exe>/../lib/<productName>` (Linux) or `Contents/Resources`; keep
  the binary in `bin/`; sidecars into `src-tauri/resources/bin` before the build.
- Sidecars built from nixpkgs sources in a `let` (goose-acp from goose-cli's src and cargoDeps,
  upstream's features, `buildType = "lean"`) or in `preBuild` (`cargo build --offline --frozen`).
- Linux wrapper: `dontWrapGApps`, one `wrapProgramShell` with the GApps args, `--suffix PATH` for
  fallback tools (the user's own win), `--set-default SSL_CERT_FILE`, `--run` for a per-user
  GStreamer registry; GStreamer base, good, bad (MediaRecorder) and libav.
- darwin: a binary wrapper inside the bundle as its executable (applies when started from
  Finder), one ad-hoc `rcodesign sign` of the bundle, no hardened runtime.
- Updater: compiled out without endpoint/key; `installCheckPhase` greps the binary for the plugin
  and the feed URL. Deep-link self-registration patched out (Nix-only), scheme declared in the
  packaged `.desktop`.
- Reproducibility: `--remap-path-prefix` / `-ffile-prefix-map`, `disallowedReferences = [ src ]`.
- `OPENSSL_NO_VENDOR = 1` (keyring vendors openssl), `AWS_LC_SYS_CMAKE_BUILDER = 1`,
  `dontUseCmakeConfigure` when only build scripts use cmake.
- Tests: release profile breaks debug-only helpers (upstreamed for 1.0: buzz-app#1778–#1780);
  17 Linux + 16 darwin skips, each with its reason; offline smoke tests in `passthru.tests`.

## Daemon + module (buzz-relay)

Version from the desktop release date when the component's own tags are stale; crate version
guarded in `postPatch`; `doCheck = false` with the reason when tests need Postgres/Redis/S3; VM
test on x86_64 and aarch64; IPv6 bind strings bracketed; darwin test daemons with a `trap`.

## Merging

Every merge needs a committer. What worked: ask one who touched the package (booxter had fixed
buzz-cli's darwin build). Init PRs: median 2.5 days, p90 ~22 days.
