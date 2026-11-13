---
name: quickshell-contributing
description: Contributing to quickshell (outfoxxed/quickshell); covers QML URL interceptor, QmlScanner, Qt 6.12 singleton resolution, reload deadlock prevention, and NixOS build verification.
disable-model-invocation: true
---

# quickshell Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `outfoxxed-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to `quickshell` and wins
where they differ.

Sources of truth: `README.md`, issues #1295, #1104, #941 on `quickshell-mirror/quickshell`. As of 2026-11-13.

## 0. Hard rules that decide the agent's role

- **AI Policy:** Standard workflow. Agent drafts, Martin reviews and approves. One disclosure line in the PR.
- **Commits:** `<subsystem>: <imperative summary>` (e.g. `interceptor: avoid synchronous directory scan during URL interception`).
- **Code style:** Modern C++20/C++23 with Qt6, formatted according to project conventions.

## 1. Before starting

- Search open and closed issues on `quickshell-mirror/quickshell`.
- Issue #1295 documents that `qs.*` imports resolve singletons to their `QQmlType` object rather than
  instantiating the singleton instance under Qt 6.12.

## 2. Designing the change

- **URL Interceptor & Scanner (`src/core/qsintercept.cpp`, `src/core/scan.cpp`):**
  - Do NOT perform blocking or synchronous filesystem scans (`scanDir()`) inside `QsUrlInterceptor::intercept()`.
    Qt may invoke `intercept()` concurrently from both the GUI and QML loader threads; concurrent or recursive
    `scanDir()` calls cause data races, use-after-free crashes, and engine deadlocks during plugin reloads
    (`Local plugin changed, reloading`).
  - Singletons under Qt 6.12: When intercepting QML modules via `qs:@/...`, ensure singletons are properly
    registered with the QML engine's singleton provider mechanics rather than resolving only as type definitions.

## 3. Building and validating on NixOS

```bash
nix build .#quickshell
```
Or test via `checks.omarchy-ux` in `nix-omarchy`.
