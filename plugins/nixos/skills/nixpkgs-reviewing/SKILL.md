---
name: nixpkgs-reviewing
description: Use when reviewing a Nixpkgs pull request (package additions, version updates, NixOS modules) — triage, mechanical verification, detecting derivation and module anti-patterns, active build and test verification, and drafting concise GitHub review suggestions compliant with the Nixpkgs AI policy.
disable-model-invocation: true
---

# Reviewing Nixpkgs Pull Requests

Layer 3 of 3: read `upstream-contributing` and `nixos-org` first (as files, `~/.agents/skills/<name>/SKILL.md`).
This skill defines the end-to-end review protocol for Nixpkgs PRs, distilled from committer reviews and empirical testing on real package PRs.

Sources of truth: `CONTRIBUTING.md`, `pkgs/README.md`, `pkgs/by-name/README.md`, and `nixos/README.md`.

## 0. The Review Persona & AI Policy

Nixpkgs maintainers actively object to verbose, generic LLM comments ("LLM comments are usually way too long and verbose", #571214). Reviewers appreciate concrete, actionable feedback that can be merged with minimal roundtrips.

Rules for AI-assisted review drafting:
1. **Zero conversational fluff:** No opening praise ("Thanks for this great PR!"), no restating what the PR does, no closing cheerleading.
2. **Actionable suggestions:** Format code changes as direct GitHub ````suggestion ... ```` blocks whenever possible.
3. **Factual rationale:** Keep explanations to 1–2 sentences explaining the *why* (link RFC, manual, or upstream issue).
4. **Human in the loop:** Martin reviews, verifies, and endorses every comment before posting.
5. **AI disclosure:** Every review comment must end with the trailer:
   ```markdown
   ---
   *Assisted-by: <tool> (<model>)*
   ```

---

## 1. Phase 1: Intake & Triage

Inspect the PR metadata before reading code:
```bash
gh pr view <PR> --json number,title,author,baseRefName,labels,files,body
```

### 1.1 Base branch & mass rebuilds
* Rebuild count < 500 → `master`
* Rebuild count 500–999 → `master`, but consider `staging`
* Rebuild count ≥ 1000 → must target `staging`
* Kernel or `10.rebuild-nixos-tests` → `staging-nixos`
* Backports → `release-YY.MM` (mass rebuilds → `staging-YY.MM`)

### 1.2 Commit structure
* Package commits: `<attr>: init at <version>` | `<attr>: <old> -> <new>` | `<attr>: fix ...`
* Maintainer additions: must be a separate commit, before the package commit (`maintainers: add <handle>`).
* Module commits: `nixos/<module>: ...`
* No trailing period in titles; lowercase attribute name; fixup commits must be squashed.

### 1.3 PR template checklist
Verify the author filled out the checklist truthfully (e.g. tested on x86_64-linux, sandboxing enabled).

---

## 2. Phase 2: Derivation & Standards Audit

### 2.1 Placement & `pkgs/by-name`
* New top-level `callPackage` packages must live in `pkgs/by-name/<2-letter-prefix>/<attr>/package.nix`.
* Nested packages (e.g., `python3Packages.foo`) stay in their respective language directories.
* Variants created by `.override` (e.g. `foo-cuda`, `foo-vulkan`):
  * Must have their own `pkgs/by-name` directory.
  * Must re-anchor `meta.position`:
    ```nix
    (foo.override { cudaSupport = true; }).overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // {
        inherit (oldAttrs.meta) description;
      };
    })
    ```
  * Must include `# nixpkgs-update: no auto update` at the top of the file.

### 2.2 Derivation shape & conventions
* **`finalAttrs` over `rec`:** Use `finalAttrs: { ... }` with `pname`, `version`, and `tag = "v${finalAttrs.version}";` or `finalAttrs.version`.
* **Strict attributes:** Every new package must evaluate with `strictDeps = true;` and `__structuredAttrs = true;` (`nixpkgs-vet` requirement).
* **Fetchers:**
  * Use `tag = "v${finalAttrs.version}";` rather than `rev` for GitHub tags.
  * Use full commit hash if untagged (`version = "<last-release>-unstable-YYYY-MM-DD"`).
  * Use `fetchpatch2` with descriptive `name` for patches, not `fetchpatch`.
* **Language builders:**
  * **Python:** Use `pyproject = true;` with `build-system = [ ... ]` and `dependencies = [ ... ]`. Flag legacy `format = "setuptools"` or `format = "pyproject"`. Check upstream `setup.py` / `pyproject.toml` to ensure packages like `setuptools-scm` are not blindly added when versioning is static.
  * **Rust:** `buildRustPackage` with `cargoHash` (or `cargoLock`).
  * **Go:** `buildGoModule` with `vendorHash`.
* **Dependency categories:**
  * Build-time tools (compilers, `pkg-config`, `cmake`, hooks) → `nativeBuildInputs`.
  * Libraries linked into the output → `buildInputs`.
  * Wrap with `makeBinaryWrapper` rather than `makeWrapper` when no complex shell logic is needed.

### 2.3 Metadata (`meta = { ... }`)
* **`description`:** One capitalized sentence, no leading article ("A tool for..."), does not repeat the package name, no trailing period.
* **`license`:** `lib.licenses.<id>` matching upstream. Verify against upstream repository's `LICENSE` file.
* **`maintainers`:** `maintainers = with lib.maintainers; [ <handle> ];`.
  * If a new maintainer was added in `maintainers/maintainer-list.nix`, verify `email` is a valid email or omitted (not just a GitHub username).
* **`mainProgram`:** Hardcoded string of the primary executable, if applicable.
* **`platforms`:** Set appropriately (`lib.platforms.all`, `lib.platforms.unix`, etc.).

### 2.4 Workaround & patch discipline
* **No unlinked workarounds:** Every patch, `substituteInPlace`, or skipped test must have a comment with an upstream issue/PR link or an explicit reason why it is Nix-specific.
* **Check upstream status:** Query `gh pr view <url>` or `gh issue view <url>`:
  * If merged upstream: note that the workaround can be dropped with the next release.
  * If open upstream: vendored patch or skip is justified.
* **Build from source:** Reject vendored prebuilt binaries for FOSS software.

---

## 3. Phase 3: Active Sandbox & Runtime Verification

Never guess whether tests fail or if attributes evaluate—verify in a sandbox.

### 3.1 Evaluation & attribute check
```bash
nix-instantiate --eval -E 'with import ./. {}; { inherit (<attr>) strictDeps __structuredAttrs; }'
```

### 3.2 Test verification (Don't let tests be skipped silently)
* If `doCheck = false;` is set:
  * Inspect upstream repository for test frameworks (`tests/`, `pytest`, `cargo test`).
  * Test building with checks enabled (e.g. adding `nativeCheckInputs = [ pyyaml pytestCheckHook ];`).
  * If tests pass: suggest removing `doCheck = false;`.
  * If tests genuinely fail in a sandbox (need network, hardware): require a comment explaining the reason.

### 3.3 Install checks & smoke testing
* Build the package: `nix-build -A <attr>`.
* Test the binary in `./result/bin`:
  ```bash
  ./result/bin/<prog> --version || ./result/bin/<prog> -V
  ```
* If it outputs the expected version, suggest adding `versionCheckHook`:
  ```nix
  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgramArg = "-V"; # if needed
  doInstallCheck = true;
  ```
* Suggest `passthru.updateScript = nix-update-script { };` for automated update tracking by `r-ryantm`.

---

## 4. Phase 4: NixOS Module Review

When reviewing a PR that adds or alters a NixOS module:

1. **RFC 42 Settings Pattern:**
   * Uses `settingsFormat = pkgs.formats.<format> { };`.
   * Option `settings = lib.mkOption { inherit (settingsFormat) type; default = { }; ... }`.
2. **Secrets Hygiene:**
   * Secrets must **never** be placed in `settings` (they end up world-readable in the Nix store).
   * Provide an `environmentFiles` option (`type = lib.types.listOf lib.types.externalPath; default = [ ];`) for systemd `EnvironmentFile=`.
   * Use systemd `LoadCredential` for secret files.
3. **Systemd Hardening:**
   * Use `DynamicUser = true;` with `StateDirectory` wherever possible.
   * Standard hardening directives: `ProtectSystem = "strict";`, `ProtectHome = true;`, `CapabilityBoundingSet = "";`, `RestrictNamespaces = true;`, `NoNewPrivileges = true;`.
   * Document hardware exceptions in comments (e.g. why `PrivateDevices` is off for GPU access).
4. **Documentation & Release Notes:**
   * `meta.doc = ./<module>.md;` and `meta.maintainers` must be declared.
   * New modules must have an entry under "New Modules" in `nixos/doc/manual/release-notes/rl-<YYMM>.section.md`.
   * Cross-references must use `[](#opt-...)` links, and matching anchors must be mapped in `redirects.json`.
5. **Automated VM Test:**
   * New modules should include a NixOS test in `nixos/tests/<module>.nix`.
   * Wired into `passthru.tests = { inherit (nixosTests) <module>; };`.

---

## 5. Phase 5: Drafting the Review

Synthesize findings into clean, concise GitHub review comments:

### Review Template
````markdown
Thanks for packaging `<attr>`! A few suggestions to align with current Nixpkgs standards:

### 1. Maintainer entry
In `maintainers/maintainer-list.nix`:
```suggestion
  <handle> = {
    github = "<handle>";
    githubId = <id>;
    name = "<name>";
  };
```
*(The `email` field should either be a valid email address or omitted).*

### 2. Derivation improvements
In `pkgs/by-name/...`:

1. **Tag fetcher:** Modern convention prefers `tag = "v${finalAttrs.version}";` over `rev`.
2. **Builder:** Switch `format = "setuptools";` to `pyproject = true;`.
3. **Enable tests:** Upstream tests pass with `nativeCheckInputs = [ ... pytestCheckHook ];`.
4. **Version check:** Enable `versionCheckHook` to verify the CLI binary at build time.

```suggestion
... [replacement block] ...
```

---
*Assisted-by: Antigravity (<model>)*
````
