# Workaround catalog

What a sandboxed Nix build finds in an application, how to detect it, which upstream change
removes it, and what to carry downstream meanwhile. Examples are Mesh-LLM/mesh-llm (`M#`),
block/buzz-app (`BA#`), NixOS/nixpkgs (`N#`) and ggml-org/llama.cpp (`L#`) PRs; days are from
opening to merge.

The upstream PR shape that merged fastest everywhere: **opt-in, default unchanged, one flag or one
env var honoured, a test that fails on the old code, a before/after measurement in the body.**

## Build system assumptions

| Symptom | Detect | Upstream fix | Example |
|---|---|---|---|
| Build script runs a vendored prebuilt binary (protoc) | `nix build` fails on NixOS, or a binary from `$cargoDepsCopy` runs | honour the standard env var (`PROTOC`) when set | M#2448 (0.6 d) |
| Repo's own cargo config (sccache, custom linkers) | `.cargo/config.toml` | none needed: `rm` it in `postPatch` with a reason (permanent, Nix-only) | #571722 |
| Release tooling rewrites runpaths, builds extra tools | packaging script hard-codes `$ORIGIN`, builds with cargo | opt-in flags (`--keep-runpath`, `--no-model-package-tool`) | M#2392 (3 h) |
| Artifact identity can't be set (id, rank) | `jq` edits of a manifest | flag (`--id-suffix`); find existing env vars first | M#2526 |
| Upstream's build fetches or builds a sidecar itself (git clone in `beforeBuildCommand`) | Tauri config, npm scripts | ask upstream for an env var naming a prebuilt binary; meanwhile override only the step that fetches. Run every other step of upstream's command offline first: buzz-app's `build-agent-command.mjs` worked in the sandbox and replaced a hand-written `preBuild` | BA#1781 (`BUZZ_GOOSE_ACP_BINARY`) |
| Upstream downloads a toolchain at runtime (Node) | strace/proxy at startup | env var pointing at a provided binary | block/buzz#7153 |

## Toolchain and compiler matrix

Upstream CI pins one compiler; Nix is newer (GCC 14+), CUDA uses an older host compiler (GCC 13),
Jetson an older driver.

| Symptom | Example | Fix where |
|---|---|---|
| Missing `#include` that unity builds hid | clef.cpp `<algorithm>`: issue M#2495 → M#2524, L#30981 | the project that owns the file |
| CPU variants the host compiler can't build (`+sme`) | L#26103 (existing, approved) — search first, carry it vendored with the link | upstream |
| PTX-only CUDA build the driver can't JIT | M#2303: pass the target architectures through | upstream |
| CUDA major mismatch with the device's driver | build with `cudaPackages_12` and the device's capability for Jetson (agent-ops) | package config, not a workaround |

## Read-only store and non-root builds

Upstream CI runs as root on writable files; Nix builds as a build user on 0444/0555 store files.
Example: a Rust copy that reopened the destination for writing (EACCES on libcudart; M#2456, a
regression of a Python→Rust port). Reproduce with a unit test that copies a 0444 file.

## System facts read from the wrong place

The process should ask itself, not the system: glibc via `gnu_get_libc_version`, not `getconf`
(M#2438: bundles were rejected and a 55 MB runtime downloaded). Same class: CUDA toolkit
detection, `/etc` lookups.

## FHS paths

| Symptom | Fix |
|---|---|
| Runs `hostname`, `/bin/bash`, `/usr/bin/env`, `/usr/bin/true` | syscalls instead of commands (M#2444 `gethostname`); tests take bash and `PATH` from the environment (M#2604) |
| Hard-coded `/bin/cp`, `/bin/kill`, `/usr/bin/head` in tests | one upstream PR for the class, tests call tools by name (BA#1779); `substituteInPlace` meanwhile |
| Tests spawn a shell with a fixed `PATH=/usr/local/bin:/usr/bin:/bin` | the test passes its own `PATH` to the child (BA#1779); on darwin this showed up as EPERM, not as "not found" |
| Test fixtures point at host files (`/usr/bin/git` as a shim target) | fixtures in a tempdir (BA#1780) |
| `#!/usr/bin/env` scripts, `/etc/profile` for a login shell | Nix-only: the sandbox has neither; skip by name with that reason |

## Network and CA bundle

| Symptom | Detect | Fix |
|---|---|---|
| Test or localhost client fails without a CA bundle (rustls loads system roots for plain HTTP) | run tests with empty `SSL_CERT_FILE`/`SSL_CERT_DIR` | a shared "local client" constructor without TLS roots, no redirects, no proxy; fix the class (M#2491, M#2492, M#2498, M#2577) |
| Phone-home at start: update checks, catalogs, model metadata | logging `HTTPS_PROXY`, count requests before/after | a config setting with an env override ("managed by a package manager"); the module or wrapper sets it (M#2446, M#2496, M#2494) |
| Tests hang instead of failing without network | a missing `cacert` made link-preview tests hang >1 h (Buzz) | add `cacert` to `nativeCheckInputs` while the upstream fix is pending, linked |

## Sandbox-hostile tests

| Cause | Handling |
|---|---|
| Terminal width 0 | upstream: tests set their width (M#2605); skip meanwhile |
| Timing assertions on a busy builder | skip by name: "timing assertion, fails on a busy builder" |
| Release profile breaks debug-only helpers | `checkType = "debug"` if upstream tests in dev, else upstream `cfg(any(debug_assertions, test))`, or the test asserts per profile with `cfg!(debug_assertions)` (BA#1778) |
| Tests start `dbus-daemon --session` (reads `/etc/dbus-1/session.conf`) | Nix-only, no skip: `--config-file=${dbus}/share/dbus-1/session.conf` and `dbus` in `nativeCheckInputs` (buzz-app) |
| Tests reach a dynamically loaded runtime without loading it | upstream test-support helper (M#2629) |
| An env var set in `preCheck` for some tests leaks into others | file an issue with options instead of guessing (M#2630); skip by name |
| darwin: `__darwinAllowLocalNetworking` for loopback; `yes_sandbox_relaxed` in review-gha | package setting |
| darwin: Metal can't create a command queue | `GGML_METAL_DEVICES=0` (llama-cpp precedent) |
| darwin: interface enumeration needs ICU data | `sandboxProfile` allowing `/usr/share/icu` (dumbpipe precedent) |
| darwin: Security-framework TLS fails (OSStatus -26276) | `sandboxProfile` with `(allow mach-lookup (global-name "com.apple.trustd") (global-name "com.apple.trustd.agent") (global-name "com.apple.SecurityServer"))` (buzz-app, review-gha run 40613244514) |
| darwin: `chmod +a` (macOS ACLs) | the sandbox has no `/bin/chmod`, coreutils' lacks `+a`: skip by name. An upstream PR calling `/bin/chmod` was dropped before opening |
| darwin: EPERM from a spawned shell | read its stderr first: in buzz-app it was the fixed `PATH` (row above), not the sandbox |
| darwin: a test that backgrounds a daemon hangs the build | `trap 'kill $(jobs -p) 2>/dev/null' EXIT`, redirect stdout and stderr, `timeout` |
| A platform where upstream's CI doesn't run that test kind | skip with "upstream's macOS CI runs --lib only" (#571722, control-plane SIGSEGV) |

## Wrapper side effects

`makeBinaryWrapper` puts the real binary behind a wrapper; `current_exe()` names the wrapped file
in a versioned store path. Check what the app writes about itself: service units, desktop files,
URL-scheme handlers.
- `mesh-llm setup --service` wrote `ExecStart=…/.mesh-llm-wrapped` (M#2648: use the invoked path).
- Tauri's deep-link plugin rewrote `~/.local/share/applications/*-handler.desktop` on every start
  with the unwrapped path: patched downstream (Nix-only), the packaged `.desktop` declares the
  scheme instead.

## Updaters and self-modification

Make sure a Nix build never ships an updater: check that upstream compiles it out without its
endpoint/key, and assert it in `installCheckPhase` (grep the binary for the plugin and the feed
URL; buzz-app). A patch that "disables" an updater can silently do nothing (seen on N#549345).

## Neighbours: when two packaged apps disagree

Not a package workaround but a fleet and test setting, until one side is fixed.

| Symptom | Cause | Meanwhile |
|---|---|---|
| goose fails a turn: `Failed to parse Responses stream event: missing field created_at` | goose's openai provider sends a stock base path to the Responses API; llama-server (nixpkgs llama-cpp 0.7.0, `tools/server/server-task.cpp`) sends `response.created` without `created_at`, which OpenAI's response object has | goose config `OPENAI_BASE_PATH: chat/completions`; still on llama.cpp master 2026-10-28, no report yet (the fix belongs in llama.cpp: the field is in the spec). MeshLLM's own translation sends `created_at`, so goose via the mesh works |

## The lifecycle of one workaround

1. Find it (test failure, review, measurement); write down the cause, not just the symptom.
2. Search upstream PRs *and* issues; build on existing work (L#26103 was approved already).
3. Carry it downstream with a comment: what, why, upstream link, "drop with a release that has it".
4. Upstream PR with pre-flight, before/after evidence; answer reviewers fast.
5. On the next bump: grep the new source for the fix, remove the workaround and its comment, rerun
   the tests that needed it.
6. A workaround without a possible upstream fix states why it is Nix-only.
