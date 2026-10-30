# buzz-app: facts a distribution package depends on

Verified at `desktop-v0.7.0` (7da6101c, 2026-10-28; README still says "Buzz 1.0 is in beta") from the source and the nixpkgs build
(NixOS/nixpkgs#577918 at a7a63fbb, review-gha run 40631445370) unless marked "unverified".
Paths move; recheck on every bump.

## Products
- One Tauri app, Cargo package and binary `Buzz` (`src-tauri`), identifier
  `xyz.block.buzz.desktop`, the same as Buzz 0.X: an existing 0.X profile is picked up.
- Bundled resources in `src-tauri/resources/bin/` → `bin/` (`tauri.conf.json`): `goose-acp`
  (Goose agent over ACP) and `buzz-agent-command` (starts agents that get MCP servers).
- `buzzodz` (crate `buzzodz-plugins`): plugin manager CLI on the app's plugin format; ships with
  the app.
- Plugins download Claude Code and Codex at run time (curl + sha256sum), run git, ffmpeg, node from
  `PATH`.

## Build
- Toolchains via Hermit (`bin/`): Rust 1.98.1, Node 24, pnpm 11 (`packageManager`), just,
  Lefthook 2.2.2. nixpkgs' versions work.
- `beforeBuildCommand`: `node scripts/build-goose-acp.mjs && node scripts/build-agent-command.mjs
  && pnpm build`. build-goose-acp clones goose at the commit in `runtime/goose-acp.json` and
  builds it (network): replaced downstream; block/buzz-app#1781 adds `BUZZ_GOOSE_ACP_BINARY`.
  build-agent-command runs `cargo build --locked` and works offline.
- Per-OS overlays: `tauri.linux.conf.json` sets `productName` "Buzz Foundation" → resources in
  `lib/Buzz Foundation`, desktop file "Buzz Foundation.desktop"; also `tauri.windows.conf.json`,
  `tauri.native-mcp.conf.json`.
- Release workflow sets `BUZZ_BUILDERLAB_URL=https://app.builderlab.xyz` (copied) and the updater
  endpoint and key (left unset).
- Cargo and pnpm hashes only change with dependency changes (beta.1 → beta.2: frontend only).

## Run time
- Updater: compiled in only with endpoint and key (`build.rs`, `cfg(buzz_updater_enabled)`);
  the package asserts it's absent.
- Linux deep links: `tauri-plugin-deep-link` `register_all()` writes
  `~/.local/share/applications/<binary>-handler.desktop` on every start
  (`src-tauri/src/deep_links.rs`); patched out, scheme declared in the packaged `.desktop`.
  Issue text for a build-time switch drafted (Martin files).
- Media: WebKitGTK MediaRecorder needs GStreamer base/good/bad/libav.
- Startup network contacts: unverified (no logging-proxy measurement yet).

## Tests
- Upstream CI (`ci.yml`): `cargo test --workspace --locked` and `cargo test -p Buzz
  -p buzz-agent-controller -p buzz-credential-store`, dev profile. nixpkgs runs release.
- In the sandbox (0.7.0, whole workspace: Linux 860 passed / 10 skipped, darwin 867 / 16; beta.2 had 9 and 13):
  - one test expects the debug-only wipe refusal → #1778;
  - fixtures use `/bin/cp`, `/bin/kill`, `/usr/bin/head`; terminal tests give the shell
    `PATH=/usr/local/bin:/usr/bin:/bin` (EPERM on darwin) → #1779;
  - macOS git shim test points at `/usr/bin/git` → #1780;
  - Nix-only: `/usr/bin/env`, `/etc/profile`, `/bin/chmod` (macOS ACL test), the macOS login-shell
    probe's `/usr/bin` tools; `build_resources` expects no `build` parent of TMPDIR (upstream test
    bug, fix prepared locally as `test-build-ancestor`);
  - Nix-side fixes: dbus `--config-file` from the store; darwin `sandboxProfile` for trustd.
- With #1778–#1781 applied: green on x86_64-linux, aarch64-linux, aarch64-darwin
  (runs 40612213130, 40613244514).

## Releases
- Tags: `desktop-v*` (desktop releases, no GitHub releases), `mobile-v*`, and
  `v0.7.0-preview.N.N` per main build (these have GitHub releases, so nix-update alone picks
  them). updateScript: `gitUpdater { rev-prefix = "desktop-v"; ignoredVersions = "-"; }` then
  `nix-update --version=skip`.
- Goose: upstream builds goose-acp from goose main (`runtime/goose-acp.json`, 12283408 at 0.7.0,
  47 commits past v1.55.0, fully contained in v1.57.0). nixpkgs bundles `goose acp` from
  goose-cli instead (same `goose::acp::server::run`); the app calls nine `_goose/unstable/*`
  methods, all present in 1.55.0.
- keyring uses `crypto-rust`: openssl-sys is in Cargo.lock but never compiled; libdbus is vendored.
- Canary: nix-packages `canary/buzz-app` builds the package against main nightly.

## Upstream
- Outside PRs: rare merges (SKILL.md section 7); drafts #1778–#1781 open since 2026-10-28.
- Other packaging: none found besides ours (unverified beyond nixpkgs and GitHub search).
