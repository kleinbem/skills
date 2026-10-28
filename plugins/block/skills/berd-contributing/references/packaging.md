# Berd: facts a distribution package depends on

Verified at upstream tag v0.6.4 (tag object f9fd33ce, 2026-09-10) unless a line says main
(5b500297, 2026-10-27). "Source" = read in the tree, "built" = checked on the nixpkgs build
(`berd-0.6.4`, store paths `pam6whyq…` and, with the tests enabled, `mvxrhcr5…`, 2026-10-28). Recheck on every bump. Package:
kleinbem/nixpkgs branch `berd-init`, `pkgs/by-name/be/berd/package.nix`.

## Products
- One app: `Berd` (Tauri 2 + React 19) with sidecars from `bundle.externalBin`: `goosed`
  (goose's `goose serve`), `berdctl` (CLI controlling a running Berd), `berd-monitor`, `catch`
  (block/catch, macOS-only Swift; Linux gets upstream's stub from `scripts/prepare-catch-sidecar.sh`).
  Source.
- `berdctl` and `berd-monitor` are crates in the same workspace (`src-tauri/crates/`); nothing
  is useful without the app, so one package. Source.

## Build
- Toolchains: `rust-toolchain.toml` 1.94.1 (nixpkgs' rustc works), pnpm 10.33.0
  (`packageManager`), Node 24 in the release workflow. Source.
- Release features (Linux lane of `release.yml`): `--features "$(scripts/block-feature-gates.sh
  berdctl)"`, which is `berdctl` alone when every `VITE_*` Block gate is 0 (the public product
  contract at the top of `release.yml`). Source.
- Renderer gates (`src/shared/profile/buildProfile.ts`): every Block-service gate
  (`AGENT_TOOLS`, `AUTOMATIONS`, `BUILDERBOT`, `FEEDBACK`, `MANAGED_CONNECTIONS`,
  `SKILL_DISCOVERY`, `TELEMETRY_ENFORCED`, `VOICE_DICTATION`, `SECURITY_ML`) is on only when set to
  "1", so leaving them unset equals the release. `BYO_KEY_PROVIDERS` and `TELEMETRY` are on unless
  "0"; `UPDATER_ENABLED` unless "false" (the Linux release sets it to false). Source.
- `VITE_ENVIRONMENT`: the release sets `production`; unset means `development`, and
  `telemetryBuildEnabled()` (`src/shared/telemetry/client.ts`) is then false: no telemetry can be
  sent, even after opting in. Only the telemetry code reads it: `vite.config.ts` picks the OTLP
  endpoint from it (`otel.berd.xyz` for production, a dummy `.invalid` host otherwise). The nixpkgs
  package sets `production` like the release. Source.
- Downloads at build time that a sandbox must replace: goose built from `goose-backend.lock.json`
  (a goose main commit; v0.6.4 → 5e909259, main → 7debb275), sherpa-onnx prebuilt static libraries
  (the app depends on `berd-voice` with `features = ["static"]`; on main the crate is `berd-call`
  since block/berd#338, same feature setup), the Catch universal binary on macOS. Source.
- Distribution switches upstream provides: cargo features `no-managed-acp-tools` (no Node/npm
  download of ACP bridges at run time) and `no-bb-cli-install`. Source.
- macOS: `build.rs` compiles Berd's own Swift package (`swift/BerdAirPodsBridge`, swift-rs,
  SwiftPM, macOS 14) and adds `-rpath /usr/lib/swift`. Source; not built yet.

## Run time
- Resources (`distro/`, `runtime-config.json`, sounds) resolve at `<exe dir>/../lib/Berd`, else
  `/usr/lib/Berd` (Tauri on Linux). Built: "using bundled runtime config …/libexec/berd/lib/Berd/runtime-config.json".
- Data: `~/.local/share/xyz.block.berd/` (`berd.sqlite`, `berdctl/control-*.json`, avatars,
  `installation-cohort-v1.json` = `{"cohort":"fresh-with-landing-v1"}`), goose state under
  `~/.local/share/goose`, `~/.local/state/Block/goose`. Built.
- Network (strace `-f -e execve,connect,sendto…`, fresh home, production build, 2026-10-28;
  names from the nscd lookups, programs from the execve chain). Built:
  - Berd: avatar images from `dwwgwmfqqjotj.cloudfront.net` and a second CloudFront host
    (~90 assets, retried every 30 s on failure).
  - goose (`goosed`), at its start: `models.dev` (model catalog) and `169.254.169.254:80`
    (AWS instance metadata, suspected from its AWS/Bedrock provider setup).
  - Telemetry: without opt-in no lookup of or connection to `otel.berd.xyz`; with
    `telemetry-settings.json` = `{"schemaVersion":1,"enabled":true}` in the app-data dir it connects
    there. Consent is fail-closed: events wait in a buffer until consent loads, the native export
    gate checks it again.
  - `api.anthropic.com` came from the user's own `claude-agent-acp` → `claude`, which Berd started
    when the test asked every harness for its models (`berdctl info models` without
    `--harness-id`), not on its own.
- It ignores `HTTPS_PROXY`: the logging proxy saw no request while the connects went direct. Built.
- External commands: the user's login shell (`/bin/zsh` here) to capture the directory
  environment (times out after 10 s under strace); a doctor probe (`src-tauri/src/commands/doctor.rs`)
  of the user's tools on that `PATH`: `npm prefix -g`, `git --version`, `git lfs version`,
  `gh --version`, `gh auth status`, `goose acp --help`, `claude-agent-acp --cli auth status`, and
  `bash -l -c 'type -P -- <agent>'` per known ACP agent. Built.
- Writes about itself: nothing (no `.desktop` handler, autostart or service unit in the test home).
  The packaged `.desktop` declares `x-scheme-handler/berd`. Built.
- Updater: `tauri-plugin-updater` is compiled in, but `lib.rs` registers it only when the config
  has `plugins.updater.pubkey`, and release channels load from `release-channels.json` in the
  resource dir; both come only from upstream's release overlay (`pnpm tauri:release:config`).
  Built: no `release-channels.json` (asserted in `passthru.tests.sidecars`).
- Telemetry: off until the user opts in (`TELEMETRY.md`), also in the nixpkgs package; see above.
- Headless runs need `NO_AT_BRIDGE=1` (libatk-bridge segfault without an a11y bus). Built.

## Tests
- CI (`ci.yml`): `rust` job on macos-latest and ubuntu-latest runs `just tauri-fmt-check`,
  `tauri-check`, `tauri-test`, `clippy`; frontend `just check`/`just test` and Playwright on macOS
  only. Source.
- `just tauri-test` (dev profile, `TAURI_CONFIG='{"bundle":{"externalBin":[],"resources":[]}}'`):
  `-p tauri-plugin-berdctl --features server`, `-p berdctl`, `--lib telemetry`,
  `--lib --features block-telemetry-enforced telemetry`,
  `--lib --features block-skill-discovery skill_marketplace`. Source.
- In the Nix sandbox (the package's `checkPhase`, 2026-10-28): all five lanes pass, 28 + 52 + 46 +
  38 + 3 tests; one ignored upstream (`dump_rendered_help_for_pin_update`, a pin-update helper).
  The telemetry tests need CA certificates even against their local test gateway (reqwest's
  client builder fails without any: "No CA certificates were loaded from the system"). No network,
  display or goose needed. Built.

## Releases
- Tags `v<semver>`, roughly every 1–3 weeks until 0.6.4 (2026-09-10), none since; main 65 commits
  ahead on 2026-10-27. Changelog: `CHANGELOG.md` and GitHub releases. Source.

## Upstream
- No outside PRs (closed automatically); issues through the two forms only (this skill, §0–§1).
- Issue candidates from packaging (drafts in Obsidian `Projects/Buzz nixpkgs/Drafts/`, Martin files):
  goose release pin or minimum goose release; app-level switch for sherpa-onnx `shared`;
  empty `Categories=` in the Linux `.desktop` (Tauri `bundle.category` unset; the nixpkgs package
  sets `Development;Utility;`).
- Other packaging: none found in nixpkgs, nix-community, the AUR or Repology (2026-10-28).
