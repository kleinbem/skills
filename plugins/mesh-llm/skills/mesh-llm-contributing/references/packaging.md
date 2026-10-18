# Packaging mesh-llm and Skippy

Facts a distribution package (nixpkgs) depends on. Verified at upstream `main` d9c6e5a2ff31
(2026-10-17, between v0.78.1 and 0.79.0). Paths move often: grep the names before trusting a path.

## Products

- One repository, one Cargo workspace, one version and release tag: `mesh/` (MeshLLM) and `skippy/`
  (Skippy). Mesh depends on Skippy (`mesh-llm-host-runtime` uses Skippy crates), never the reverse.
- Release binaries: `mesh-llm` (crate `mesh-llm`, default features `web-ui`, `dynamic-native-runtime`,
  `payments`, the same set `mesh/scripts/build-host.sh` uses) and `skippy` (crate `skippy-cli`,
  built with `--features dynamic-native-runtime`, which is not a default feature).
- `BUILD_VERSION` (`mesh-llm-build-info`) falls back to the Cargo version when
  `MESH_LLM_BUILD_VERSION` is unset.
- Release builds compile in a PostHog key (`MESH_LLM_POSTHOG_KEY` at build time); a build without
  it sends no analytics unless the variable is set at runtime.

## Native runtime

- Owned by Skippy: crate `skippy-native-runtime`, design in `skippy/docs/design/NATIVE_RUNTIMES.md`.
  Both `mesh-llm` and `skippy` load it.
- Manifests need `schema_version: 2`; `runtime.release_version` comes from
  `skippy/crates/skippy-native-runtime/RUNTIME_VERSION` (own version, not the product version), and
  loading needs an exact `skippy_abi` match.
- Bundle search: explicit dirs, `MESH_LLM_NATIVE_RUNTIME_BUNDLE_DIR` (path list), next to the
  executable, `<prefix>/lib/mesh-llm/<version>/native-runtimes`, Homebrew, user cache
  (`MESH_LLM_NATIVE_RUNTIME_CACHE_DIR`, default `~/.cache/mesh-llm/native-runtimes`), download.
  `skippy` uses the same discovery (`skippy-runtime-install/src/discovery.rs`).
- The design doc says environment names, the default cache root and tool identities "have not yet
  migrated" to Skippy: expect renames in a later release.
- Startup install options always allow downloads, and bundles no longer suppress the release
  catalog. Whether a start with a matching bundle still fetches `native-runtimes.json` from GitHub
  is not yet verified with a built binary: test behind a logging `HTTPS_PROXY` before claiming it.

## Plugins

- Default plugins are offered on a fresh node's first start (`runtime/default_plugins.rs`); the list
  (`mesh-llm-plugin-manager/src/defaults.rs`, `DEFAULT_PLUGINS`) is empty today.
  `MESH_LLM_NO_DEFAULT_PLUGINS=1` or `--no-default-plugins` opts out.
- Plugins install as prebuilt binaries from GitHub releases (`x86_64-unknown-linux-gnu`, macOS,
  Windows; no `aarch64-linux`), which don't run on NixOS without nix-ld.

## Paths

`~/.mesh-llm` (config, data) and `~/.cache/mesh-llm` for both products; Skippy also uses
`~/.skippy`. Overrides: `MESH_LLM_HOME`, `MESH_LLM_DATA_DIR`, `MESH_LLM_CONFIG`,
`MESH_LLM_PLUGIN_DIR`, `MESH_LLM_NATIVE_RUNTIME_CACHE_DIR`.
