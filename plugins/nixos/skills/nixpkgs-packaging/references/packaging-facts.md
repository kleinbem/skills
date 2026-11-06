# Packaging facts sheet (template)

One per application, kept in the repository skill's `references/packaging.md` when the app has a
contribution skill (Mesh-LLM's is the model), else in the Obsidian project note. Each fact names
the upstream commit it was checked at and how (source read / built binary). Mark the rest
"unverified" and verify before it decides anything.

```markdown
# <app>: facts a distribution package depends on

Verified at upstream <ref> <sha> (<date>). Paths move; recheck on every bump.

## Products
- Binaries, libraries, sidecars, plugins; which are independently useful (→ separate packages).
- Variants upstream ships (CPU/GPU backends, editions) and how one is chosen at run time.

## Build
- Build system, toolchain pins (rust-toolchain.toml, packageManager, Node version).
- Vendored or downloaded tools (protoc, node, sidecars), git fetches in build scripts.
- Feature flags upstream's release uses (release workflow, Dockerfile) — copy them.
- Compiled-in defaults the release workflow sets (URLs, keys) and which must stay unset.

## Run time
- Files it reads and writes (config, cache, state, $HOME), and how it finds its own resources.
- Everything it contacts at start and in use (measured with a logging HTTPS_PROXY): updates,
  catalogs, telemetry, model or runtime downloads; the switches that turn each off.
- External commands it runs (`hostname`, `bash`, `git`) and FHS paths it assumes.
- What it writes about itself (service units, desktop files, scheme handlers, autostart).
- Updater: how it is compiled in or out.

## Tests
- Upstream CI: commands, profile (dev/release), platforms and scope per platform (--lib only?).
- Tests that need network, a terminal, root, devices, timing, FHS paths.

## Releases
- Tag scheme, release cadence, what the version in the build files says, changelog location.
- Roadmap: new repos, rewrites, deprecations announced.

## Upstream
- Merge time for outside PRs, CI approval for forks, contribution rules (→ repository skill).
- Other packaging: other distros, project flakes, Docker images, their maintainers.
```
