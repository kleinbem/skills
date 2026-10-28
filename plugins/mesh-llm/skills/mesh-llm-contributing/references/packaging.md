# Packaging mesh-llm and Skippy

Facts a distribution package (nixpkgs) depends on. Verified at upstream `main` 3c8fb75a45fd
(2026-10-27, between v0.78.1 and 0.79.0), from the source and with the nixpkgs build of that commit
(NixOS/nixpkgs#571722's bump). Paths move often: grep the names before trusting a path.

## Products

- One repository, one Cargo workspace, one version and release tag: `mesh/` (MeshLLM) and `skippy/`
  (Skippy). Mesh depends on Skippy (`mesh-llm-host-runtime` uses Skippy crates), never the reverse.
- Release binaries: `mesh-llm` (crate `mesh-llm`, default features `web-ui`, `dynamic-native-runtime`,
  `payments`, the same set `mesh/scripts/build-host.sh` uses) and `skippy` (crate `skippy-cli`,
  built with `--features dynamic-native-runtime`, which is not a default feature).
- Version: v0.78.1 was tagged on a release branch; main's `Cargo.toml` says 0.78.0. `BUILD_VERSION`
  (`mesh-llm-build-info`) falls back to the Cargo version when `MESH_LLM_BUILD_VERSION` is unset.
- Release builds compile in a PostHog key (`MESH_LLM_POSTHOG_KEY` at build time); a build without
  it sends no analytics unless the variable is set at runtime.

## Build

- The llama.cpp pin is in `skippy/llama_cpp/upstream.txt` (was `third_party/llama.cpp/` until 0.78)
  plus a patch queue applied with `git am`; nixpkgs resolves the `bNNNNN` tag for the pin.
- `skippy/scripts/package-native-runtime.sh` builds a bundle; for distributions:
  `--keep-runpath`, `--no-model-package-tool` (#2392), `--id-suffix` (#2526);
  `MESH_LLM_NATIVE_RUNTIME_RANK` sets the bundle's rank. It always also writes a release archive
  (no flag to skip it).
- The packaging and CI tooling is Rust (`tools/xtask`, `cargo xtool …`), no Python.
- Build scripts honour `PROTOC` (#2448). The repo's `.cargo/config.toml` routes builds through
  sccache and its own linker drivers: remove it in a sandboxed build.

## Native runtime

- Owned by Skippy: crate `skippy-native-runtime`, design in `skippy/docs/design/NATIVE_RUNTIMES.md`.
  Both `mesh-llm` and `skippy` load it.
- Manifests need `schema_version: 2`; `runtime.release_version` comes from
  `skippy/crates/skippy-native-runtime/RUNTIME_VERSION` (own version, not the product version), and
  loading needs an exact `skippy_abi` match.
- Bundle search: explicit dirs, `MESH_LLM_NATIVE_RUNTIME_BUNDLE_DIR` (path list), next to the
  executable, `<prefix>/lib/mesh-llm/<version>/native-runtimes`, Homebrew, user cache
  (`MESH_LLM_NATIVE_RUNTIME_CACHE_DIR`, default `~/.cache/mesh-llm/native-runtimes`), download.
  `skippy` uses the same discovery (`skippy-runtime-install/src/discovery.rs`, which reads the env
  variable itself — tests that set it leak into others, issue #2630).
- Downloads at start: `runtime.native_runtime.download` / `MESH_LLM_NO_RUNTIME_DOWNLOAD=1` (#2496)
  turn them off; a local GGUF no longer fetches the model catalog (#2494).
- CUDA bundles are accepted only when a CUDA toolkit is detected on the host (ldconfig,
  `LD_LIBRARY_PATH`, `/usr/local/cuda*`, `resolver.rs` `CudaToolkitNotDetected`). A bundle that
  reaches CUDA through its runpath needs `MESH_LLM_CUDA_TOOLKIT_MAJOR` (documented override in
  `skippy/crates/skippy-native-runtime/README.md`).
- glibc is read from the running process (`gnu_get_libc_version`, #2438).

## Logs and state (checked with the built binary)

- Native llama.cpp logs (device, `offloaded N/N layers to GPU`, model buffers) go to
  `<runtime root>/<pid>/logs/skippy-native.log`, not to stdout or the JSON output. Runtime root:
  `MESH_LLM_RUNTIME_ROOT`, else `$XDG_RUNTIME_DIR/mesh-llm/runtime`, else `~/.mesh-llm/runtime`.
  The `<pid>` directory (`lock`, `owner.json`, `logs/`) is removed on a clean exit: read it while
  the process runs. `--debug` with `MESH_LLM_DEBUG_NATIVE_VERBOSE=1` adds verbose native output;
  the lines above appear without it.
- Request ledger: `~/.mesh-llm/logging/store/log_store.db` (SQLite, metadata only, 36 h
  retention; `logging.enabled`, under `MESH_LLM_DATA_DIR/logging` when set).
- Identity and mesh state: `~/.mesh-llm/{key,mesh-id,last-mesh}`; caches
  `~/.cache/mesh-llm/{weights-digest,blobstore}`, `~/.cache/huggingface/{hub,xet}`.
- **Writes another tool's config:** every startup model load writes `$HOME/.pi/agent/models.json`
  (Pi agent provider entry; `startup_loop.rs` → `serving_surface.rs` `update_pi_models_json`),
  even when Pi isn't installed. Undocumented, no opt-out; an unparseable existing file is replaced.
  The explicit launchers (`mesh-llm goose|pi|opencode|claude`, `skills install`) write those
  tools' configs on request only.

## Network

- Update checks: `[updates] check` / `MESH_LLM_NO_UPDATE_CHECK=1` (#2446).
- iroh 1.4 (#2558) sends its relay and net-report traffic past `HTTPS_PROXY`. When the system DNS
  fails or has no nameservers (a build sandbox, offline, broken DNS), iroh's resolver falls back to
  public resolvers (1.1.1.1, 8.8.8.8, 9.9.9.9; UDP and DNS-over-HTTPS, `n0-dns-resolver`). mesh-llm
  configures no resolver, so there is no opt-out (iroh has `with_fallback_mode(Never)`).
- Local clients (serve, client, runtime/doctor commands) work without a CA bundle once #2491,
  #2492, #2498 and #2577 are in (#2577 open on 2026-10-28).

## Plugins

- `DEFAULT_PLUGINS` (`mesh-llm-plugin-manager/src/defaults.rs`) lists `capsules` (Mesh-LLM/capsules,
  incl. aarch64-linux). Default plugins install only from a bundled directory
  (`MESH_LLM_BUNDLED_PLUGINS_DIR`, #2337), never downloaded; a package that bundles none gets
  none. `MESH_LLM_NO_DEFAULT_PLUGINS=1` or `--no-default-plugins` opts out.
- Other plugins install as prebuilt binaries from GitHub releases, which don't run on NixOS
  without nix-ld.

## Service setup

`mesh-llm setup --service` writes a systemd user unit (launchd on macOS) whose `ExecStart` is
`current_exe()`; behind a wrapper that is the versioned wrapped binary (#2648 open). Distributions
with a module (NixOS `services.mesh-llm`) don't need it.

## Tests

- Upstream CI runs `cargo test` in the dev profile; the macOS lane runs `--lib` only, Linux the
  affected crates in full. In a sandbox: terminal width (#2605), runtime loading in tests (#2629),
  the bundle-dir env leak (#2630), timing tests; on darwin, iroh needs ICU
  (`sandboxProfile` allowing `/usr/share/icu`) and Metal can't create a command queue
  (`GGML_METAL_DEVICES=0`).

## Paths

`~/.mesh-llm` (config, data) and `~/.cache/mesh-llm` for both products; Skippy also uses
`~/.skippy`. Overrides: `MESH_LLM_HOME`, `MESH_LLM_DATA_DIR`, `MESH_LLM_CONFIG`,
`MESH_LLM_PLUGIN_DIR`, `MESH_LLM_NATIVE_RUNTIME_CACHE_DIR`, `MESH_LLM_RUNTIME_ROOT`.

## Installer (verified 2026-10-21)

`install.sh` on main (~880 lines; `install.ps1` for Windows, `install.md` as the agent runbook,
spec in `mesh/docs/specs/mesh-setup-installer.md`) is the README's one-liner. It detects Linux
x86_64/aarch64 (with Jetson probing) and macOS arm64, picks cuda/rocm/vulkan/cpu/metal, checks
sha256 sidecars (a missing sidecar only warns unless `MESH_LLM_REQUIRE_CHECKSUM=1`), installs into
`~/.local/bin` and runs `mesh-llm setup` (runtime install, service, a GitHub-star prompt). It has
no distribution awareness. Useful for comparing a distribution build with the official release:
`curl -fsSL …/install.sh | bash -s -- --install-dir "$(mktemp -d)" --no-setup`.
