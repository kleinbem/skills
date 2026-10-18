# Config lifecycle in mesh-llm

Verified at upstream `main` d9c6e5a2ff31 (2026-10-18), while answering the review of #2446.
Paths move often: grep the symbol names before trusting a path.

## The flow

1. **Load.** `mesh-llm-host-runtime/src/plugin/config.rs::load_config` reads `config.toml`
   (`mesh-llm-config` parses and validates it) and then calls
   `mesh_llm_config::apply_env_overrides`, so the in-memory `MeshConfig` holds env values too.
2. **Hold.** `runtime/config_state.rs::ConfigState::load` keeps that `MeshConfig`, plus a revision
   (sidecar file) and a hash of `mesh_config_to_proto(&config)`.
3. **Share.** Owners fetch the config as a snapshot (`protocol/convert.rs::mesh_config_to_proto`).
   The snapshot carries the whole config as TOML (`config_toml`), serialised with serde.
4. **Apply.** An owner (console API in `api/routes/runtime.rs`, or a peer over owner control)
   sends a config back. `ConfigState::prepare_apply` validates it, and
   `PendingConfigApply::persist` writes it to `config.toml` with `ConfigStore::save`.

## What follows from it

- Whatever is in the in-memory `MeshConfig` and serialised by serde can end up in `config.toml`
  through steps 3 and 4. An env override must therefore not overwrite the persisted field. Put it
  in a `#[serde(skip)]` field and let the getter prefer it (`UpdatesConfig::check_override`,
  #2446). `runtime.lifecycle_log_parser` (`MESH_LLM_LIFECYCLE_LOG_PARSER`) still writes into the
  persisted field; only its `_source` is skipped.
- `#[serde(skip)]` fields also stay out of the config hash, so the hash matches the file.
- Values read once at startup (the release checks, logging limits that need a restart) don't
  change on apply. Schema metadata says so with the restart scope (`setting_schema.rs`).
- A test for a new setting: a save/reload round trip in `mesh-llm-config`, and a
  `mesh_config_to_proto` → `proto_config_to_mesh` round trip in
  `mesh-llm-host-runtime/src/protocol/config_tests.rs`. For an override, also assert that it does
  *not* survive the snapshot.

## Upstream design docs

Read these before designing in their area: `mesh/docs/design/CRATE_DECOMPOSITION.md` (which
crate owns what), `mesh/docs/design/TESTING.md`, and `mesh/docs/design/message_protocol.md`.
