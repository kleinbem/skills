# Case: MeshLLM (NixOS/nixpkgs#571722)

Packages: `skippy-native-runtime` (+`-vulkan`), `mesh-llm` (+`-cuda`, `-rocm`), `skippy`, module
`services.mesh-llm`, VM test. Opened 2026-10-08 as a draft, ready 2026-10-25, no human review yet
on 2026-10-28. 17 Mesh-LLM PRs merged. Left: `cacert` in tests (Mesh-LLM#2577), vendored
llama.cpp#26103 patches, test skips waiting on #2605, #2629 and issue #2630, and Nix-only
adaptations with stated reasons (CUDA toolkit override, cargo config, archive removal).

## What worked

- **Fix upstream, fast.** Median 2.5 days from opening to merge over 17 PRs; the first six took
  3 hours to 3 days. Shape: opt-in flag or env var, default unchanged, failing test first,
  before/after numbers (request counts through a logging proxy, startup seconds).
- **Track main as `0.78.0-unstable-<date>`** instead of waiting for 0.79: merged fixes reached the
  package in days. The earlier "freeze on 0.78.1 until 0.79" decision was reversed after a week.
- **Fix classes, not instances:** one local-client helper without TLS roots (Mesh-LLM#2492) reused
  for the CLI (#2577) instead of four separate CA workarounds.
- **The runtime as its own derivation**, packaged by upstream's own script, run last in
  `postFixupHooks` so `autoAddDriverRunpath` has run before the manifest checksums.
- **Variants by override** (`-vulkan`, `-cuda`, `-rocm`), `nixpkgs-update: no auto update`, one
  update script for the family (`mesh-llm/update.sh` → `skippy-native-runtime/update-release.sh`).
- **Tests at every level:** offline serve test, VM test (serves a 1 MB model, checks host name,
  owner attestation, firewall, that the Nix runtimes are found), client-ready (upstream's QA),
  build-only ROCm/CUDA runtime tests, and finally upstream's whole workspace suite: 10,894 tests
  on x86_64 and aarch64, in the debug profile without debug info.
- **Real hardware early:** the Orin found five problems no CI could (PTX-only benchmark, runtime
  bundling, read-only libcudart, SME vs GCC 13, DeviceAllow causing a silent CPU fallback).
- **Pre-flight on GitHub's runners** (kleinbem/mesh-llm-ci) after a maintainer had to fix Bash 3.2
  and Windows gaps: since then PRs arrive green on Linux, macOS and Windows.
- **Module choices tested:** hardening set verified on the Orin and the iGPU (MemoryDenyWriteExecute
  works; `DeviceAllow` silently breaks Jetson, so none), runtime downloads off by default,
  secrets via `environmentFiles` and `LoadCredential`.

## Workarounds and their fate

| Workaround | Cause class | Removed by |
|---|---|---|
| 3× `--replace-fail` in the packaging script | release tooling | Mesh-LLM#2392 flags |
| `NVCC_APPEND_FLAGS` | toolchain (PTX) | #2303 |
| `MESH_LLM_GLIBC_VERSION` | system fact from the wrong place | #2438 |
| protoc `substituteInPlace` | vendored tool | #2448 |
| `hostname` on the service path | FHS command | #2444 |
| writable libcudart copy | read-only store regression | #2456 |
| `jq` id/rank edit | artifact identity | #2526 + existing rank variable |
| `cacert` in tests (skippy, mesh-llm) | CA bundle | #2491, #2498 / #2492, #2577 (open) |
| clef `<algorithm>` patch | GCC 14 | #2524, llama.cpp#30981 |
| ggml SME patches | GCC 13 + CPU variants | llama.cpp#26103 (open, vendored) |
| test skips: gauge width, runtime loading, discovery env | sandbox-hostile tests | #2605, #2629 (open), issue #2630 |

## Mistakes and what they taught

- Marked ready without Martin's go, back to draft 24 minutes later → drafts stay drafts until he
  says so.
- 18 force-pushes, three title changes, version policy reversed → decide the policy first.
- A hook-order theory restructured the build and was reverted → reproduce the failing step alone.
- A clef patch broke the build because the canary used a newer llama.cpp pin than the package →
  canary and package test the same pin, or the difference is stated.
- An SME patch written by hand while an approved upstream PR existed → search PRs, not only issues.
- Two wrong darwin crash theories, a third (Metal) pushed as a fix → lldb or a platform-parity
  check before a fix; skip what upstream's CI doesn't run either.
- An issue filed for concerns upstream code already handled (#2321), a PR closed the same day
  (#2564) → read the code before filing.
- A push dismissed two approvals (#2446) → push complete changes; don't push from a stale bookmark
  onto a branch a maintainer committed to (#2444).
- The full test suite died on GitHub twice (memory) before `checkType = "debug"` and no debug info.
