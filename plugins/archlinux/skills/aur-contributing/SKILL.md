---
name: aur-contributing
description: Use when writing, building, adopting or updating a PKGBUILD for the Arch User Repository (AUR), co-maintaining someone else's AUR package, or filing AUR requests; covers the submission rules, PKGBUILD and Rust guidelines, split packages, .SRCINFO, building in clean containers with kleinbem/aur-packages, and our mesh-llm plans.
disable-model-invocation: true
---

# The Arch User Repository (AUR)

Layer 3 of 3: read `upstream-contributing` and `archlinux-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to the AUR.

Sources of truth (read the relevant ones fully before acting): ArchWiki "AUR submission
guidelines", "Arch package guidelines", "PKGBUILD", "Creating packages", ".SRCINFO", "namcap",
"Arch User Repository"; the developer manual's package guidelines (manual.archlinux.page:
`package-guidelines/rust`, `/nodejs`, `/security`, `/vcs`); `man PKGBUILD`, `man makepkg`.
As of 2026-10-22.

The AUR has no pull requests, reviews or CI. Every pkgbase is its own git repo
(`ssh://aur@aur.archlinux.org/<pkgbase>.git`, `master` only); whoever maintains it pushes
directly, and "packages that violate the rules may be deleted without warning".

## 0. Hard rules

- Our AI rule from `archlinux-org`: the agent drafts and builds, Martin reviews every line, is the
  commit author and pushes; Martin writes comments, emails and requests.
- **Every push, comment, vote, request and email to a maintainer is a public step** that needs
  Martin's explicit OK. Commits are authored with the global git identity and are "very difficult
  to change after pushing": set `user.name`/`user.email` per repo before the first commit.
- Martin's AUR account: a dedicated SSH key (not the YubiKey sk key, not an existing key), in
  `~/.ssh/config` as `Host aur.archlinux.org`, `User aur`, `IdentityFile ~/.ssh/aur`.

## 1. Before starting

- **Is it in the official repos?** (archlinux.org/packages). Then it may not go to the AUR, except
  a variant with extra features or patches under another name with `conflicts=`.
- **Does it exist in the AUR?** (`curl -s "https://aur.archlinux.org/rpc/v5/info?arg[]=<pkg>"`).
  Maintained: suggest changes in a comment or to the maintainer; co-maintainers are added by the
  maintainer in the AUR web interface. Unmaintained: flag out of date; an
  orphan request is granted after two weeks without a reaction (automatically after 180 days
  flagged). Never upload a duplicate.
- **Naming:** a pinned release builds from source without suffix; VCS builds get `-git` (and
  don't commit mere `pkgver` bumps); prebuilt deliverables get `-bin`. Package names lower case;
  for Rust usually the binary's name.
- `x86_64` must be supported; other arches may be added.
- **Usefulness:** "if more than a few people would find this package useful".

## 2. Writing the PKGBUILD

- Header: `# Maintainer: Name <address at domain dot tld>`; previous maintainers and the original
  submitter become `# Contributor:` lines; co-maintainers list all current maintainers.
- A `LICENSE` file with 0BSD (the AUR default, needed for promotion to `extra`).
- Never install to `/usr/local`; no new variables or functions in the PKGBUILD unless needed
  (prefix own ones with `_`); `license=()` with SPDX identifiers.
- **Sources:** transparent upstream sources (RFC 0046): a release tarball or `git+https://…#tag=`;
  checksums for everything (`b2sums`/`sha256sums`), signatures where upstream signs.
- **Keep `build()`, `check()` and `package()` offline:** fetch in `prepare()` (or `source=`), as the
  Rust and Node.js guidelines show, so builds are reproducible and work in a clean chroot.
  Rust: `cargo fetch --locked --target host-tuple` in `prepare()`, then
  `cargo build --frozen --release` and `cargo test --frozen` (no `--release` in tests; add
  `--workspace` for workspaces). Set `RUSTUP_TOOLCHAIN=stable` and `CARGO_TARGET_DIR=target` for
  users building outside a chroot. Mixed Rust/C/C++ projects: `options=('!lto')`. Unbundle `-sys`
  crates where possible (`OPENSSL_NO_VENDOR=1`, `ZSTD_SYS_USE_PKG_CONFIG=1`, ...).
- `depends` lists runtime libraries only (`glibc`, `gcc-libs`, the GPU runtime libraries, not a
  whole SDK); build tools go to `makedepends`; tests' tools to `checkdepends`.
- **Split packages:** one `pkgbase`, `pkgname=(a a-cuda ...)`, a `package_<name>()` per package
  with its own `depends`/`provides`/`conflicts`. Model for GPU variants: `extra/ollama`
  (`pkgname=(ollama ollama-rocm ollama-cuda ollama-vulkan ollama-docs)`, `options=('!lto')`;
  gitlab.archlinux.org/archlinux/packaging/packages/ollama). Renaming an existing package: keep
  the old names working with `provides`/`conflicts`; `replaces` only for a real rename.
- `namcap` on the PKGBUILD and the built package; fix what it reports or know why not.

## 3. Building and validating

- Our repo **kleinbem/aur-packages**: one directory per pkgbase, mirroring its AUR repo.
  `just build <pkg>` builds in a fresh `archlinux:base-devel` podman container as an unprivileged
  user with `makepkg --syncdeps --cleanbuild`, then runs namcap; packages land in `out/<pkg>/`.
  `just srcinfo <pkg>` regenerates `.SRCINFO`. A fresh container catches missing `makedepends`.
- Heavy or repeated builds go to GitHub's runners (free for public repos): the same container in a
  workflow, so the workstation stays free. Run what can run there; keep GPU and hardware tests
  local.
- Run the result, not only the build: install it in an Arch distrobox (`os dx::create-arch` in
  nix-config) and exercise it (for mesh-llm: `client-ready`, a short serve).

## 4. Commits

- Push only to `master`. Each commit must contain an up-to-date `.SRCINFO`
  (`makepkg --printsrcinfo > .SRCINFO`), or the AUR rejects the push.
- Bump `pkgver` (and reset `pkgrel=1`) for new upstream versions; bump `pkgrel` for packaging
  changes users need to rebuild for; don't bump for typo fixes.
- Commit messages are free-form; meaningful and short (`update: 0.79.0`, `ship the native
  runtimes`). Don't post a comment for every version update.

## 5. Changes to someone else's package; requests

- No PRs: describe the change in an AUR comment or email the maintainer, with a diff or a link to
  our tested PKGBUILD in kleinbem/aur-packages. Martin writes and sends it.
- Requests (package page, "Submit Request"): **deletion** needs a reason and supporting details;
  **merge** names the target pkgbase; **orphan** usually after two weeks flagged out of date. They
  go to the maintainer and the aur-requests list, where Package Maintainers decide.
- Review before upload: aur-general, the "Creating & Modifying Packages" forum or IRC
  `#archlinux-aur` on Libera Chat.

## 6. CI and bots

- None on the AUR side; the only server checks are `.SRCINFO` present and branch `master`.
- Automated updates are allowed at your own risk; they don't replace manual checks
  (license, dependencies), and malfunctioning accounts and their packages may be removed.

## 7. What the history shows (2026-10-22)

- AUR `mesh-llm`, `mesh-llm-vulkan`, `mesh-llm-cuda`, `mesh-llm-rocm`: maintainer luciddream
  (George Sofianos), no co-maintainers, 0 votes, no comments; commits like `update: 0.78.1`
  within days of each release since 2026-08 (`git log` of the AUR repos).
- The packages build `target/debug` (CPU), drop the GPU runtimes the build produces, use the
  network in `build()`, and ship 4 conflicting packages, `x86_64` only.
- Rerun: `curl -s "https://aur.archlinux.org/rpc/v5/info?arg[]=mesh-llm&arg[]=mesh-llm-cuda"`,
  `git clone https://aur.archlinux.org/<pkg>.git` (read-only clones need no account).

## 8. Our setup and current threads

- kleinbem/aur-packages (public, 0BSD) holds our PKGBUILDs; the AUR stays where users install.
- Martin's AUR account: not created yet (key and account first, see section 0).
- **mesh-llm:** goal is co-maintaining the four packages with luciddream, restructured as one
  `pkgbase=mesh-llm` split package like `extra/ollama`, runtimes built from source and installed
  to `/usr/lib/mesh-llm/native-runtimes/`. Build it on the 0.79 release; lessons from the nixpkgs
  packaging apply (`skippy-native-runtime`). Survey and the draft message to George: Obsidian
  `Projects/Buzz nixpkgs/Drafts/mesh-llm-arch-aur-plan.md`.
