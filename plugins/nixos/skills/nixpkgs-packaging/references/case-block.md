# Case: Block's Buzz (buzz-cli, buzz-relay, buzz-app)

Merged: buzz-cli co-maintainer (#569636, 2.4 days), buzz-cli 0.5.28 (#577535, 3.3 days). Open:
buzz-relay + module (#574877), buzz-app (#577918, draft, 0.7.0-beta.2; upstream test fixes
block/buzz-app#1778–#1781, drafts). Closed: seven single-package drafts
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
- **A GUI test read as an app bug** ("Community discovery failed") was the fleet: the reused app id
  loaded the old profile, and a container egress rule dropped the relay's replies (nix-gantry#5). →
  Check existing state and the backend before blaming the package.
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
- Tests: 17 Linux skips at beta.2, sorted by cause into four upstream PRs (BA#1778 per-profile
  assertion, #1779 tools and `PATH` from the environment, #1780 tempdir fixtures, #1781 prebuilt
  goose-acp) and two Nix-side fixes (dbus `--config-file`, a darwin `sandboxProfile` for trustd).
  With them applied (TEST-ONLY branches, review-gha 40612213130 Linux, 40613244514 darwin) two
  skips remain on Linux (`/usr/bin/env`, `/etc/profile`) and one more on darwin (`chmod +a`).
  Offline smoke tests in `passthru.tests`.
- Linux `productName` comes from `tauri.linux.conf.json` ("Buzz Foundation"): resource dir and
  desktop file follow it, the binary is `Buzz`.
- Deep-link self-registration: a build-time switch upstream would replace the Nix-only patch
  (issue text drafted, Martin files it).

## Daemon + module (buzz-relay)

Version from the desktop release date when the component's own tags are stale; crate version
guarded in `postPatch`; `doCheck = false` with the reason when tests need Postgres/Redis/S3; VM
test on x86_64 and aarch64; IPv6 bind strings bracketed; darwin test daemons with a `trap`.

## Merging

Every merge needs a committer. What worked: ask one who touched the package (booxter had fixed
buzz-cli's darwin build). Init PRs: median 2.5 days, p90 ~22 days.

## Berd (block/berd)

nixpkgs draft `berd: init at 0.6.4` (branch kleinbem/nixpkgs:berd-init, 2026-10-28). Upstream
takes no outside PRs: fixes are issues Martin files (`berd-contributing`).
- **The shadow was a near copy.** nix-packages' Berd, written in nixpkgs form, needed two changes
  on master: pnpm `fetcherVersion` 4 → 5, pnpm on `nodejs-slim_24` (master's convention, not
  `nodejs_24`). Before copying a shadow, read the fetcher's deprecation throws on master
  (`pkgs/build-support/node/fetch-pnpm-deps`). The copy goes away for a registry entry once the
  PR exists (nix-packages README).
- **Release, not main.** 0.6.4 is the newest tag and runs on nixpkgs' goose-cli as the `goosed`
  sidecar; main pins a goose commit. Track the tag until upstream releases.
- **Tauri resource dir:** `libexec/berd/{bin,lib}` with the wrapper in `bin/` (case above);
  `no-managed-acp-tools` and `no-bb-cli-install` features stop runtime downloads; the updater
  stays out (no release overlay key).
- **Behaviour test** (SKILL.md Phase 3): headless chat through `bin/berd`, the packaged `goosed`
  and `berdctl` against llama-server answered `PONG`; harness in `~/.cache/berd-test/scripts`
  (to move into the canary template).
- **Platforms:** Linux only so far; darwin needs the Catch sidecar (macOS Swift, block/catch)
  and the bundle layout.
