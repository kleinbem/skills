---
name: garage-ui-contributing
description: Use when preparing an issue or PR for Noooste/garage-ui (web UI for Garage object storage clusters; Go backend + React/Vite frontend), or when building it with Nix; covers CONTRIBUTING.md (Conventional Commits PR titles, squash merge), the CI and coverage gate, the maintainer's review style, and the nixpkgs packaging angle.
disable-model-invocation: true
---

# Noooste/garage-ui Contribution Workflow

Layer 3 of 3: read `upstream-contributing` and `noooste-org` first (as files,
`~/.agents/skills/<name>/SKILL.md`). This skill holds only what is specific to garage-ui and wins
where they differ.

Sources of truth in the repo: `CONTRIBUTING.md`, `README.md`, `docs/{access-control,garage-setup}.md`,
`config.example.yaml`, `.github/workflows/{test,frontend-test,pr-title,build,release-please,chart-release}.yml`,
`scripts/coverage-gate.sh`, `Makefile`, `Dockerfile`. No `AGENTS.md`, no PR or issue templates, no
`CODEOWNERS`, no `SECURITY.md`. Summary as of 2026-11-01.

MIT, about 330 stars, one maintainer (`@Noooste`) who merges everything; Dependabot and a
release-please bot open the rest. Releases are frequent (0.11.x to 0.14.0 within October 2026) and
ship as a Docker image (docker.io) and a Helm chart; there are no release binaries.

## 0. Hard rules that decide the agent's role

- **No AI policy.** Nothing in the repo addresses AI use or agent attribution, and no merged PR
  mentions it. So: the agent drafts, Martin reviews and posts. Commit trailers don't matter
  (squash merge, below); disclose AI help in the PR text in one line.
- **Legal notice** (`CONTRIBUTING.md`): "you must agree that you have authored 100% of the content,
  that you have the necessary rights to the content and that the content you contribute may be
  provided under the project licence." No CLA or sign-off check enforces it.
- **Issues first for features.** Enhancements are "tracked as GitHub issues"; describe current vs.
  expected behaviour and "why this enhancement would be useful to most Garage UI users".
  Small fixes go straight to a PR without an issue (#112, #116).

## 1. Before starting

- Search issues and PRs, open and closed: `gh search issues --repo Noooste/garage-ui --include-prs <terms>`.
  The maintainer often fixes a reported bug on `main` within a day and closes duplicate PRs
  (#131 closed: "7da65bc on main already fixes #127").
- Read the maintainer's earlier decisions on the topic:
  - #127: a `-frontendpath` CLI flag was declined because "`GARAGE_UI_SERVER_FRONTEND_PATH`
    already covers the same result". A request that looks like it needs a new option should first
    explain why the env var or config key doesn't cover it.
  - #107: "I agree for the runtime over build time": one published image must work for every
    deployment, so settings are runtime config, not build flags.
- For anything beyond a small fix, sketch the design in the issue and offer the PR; the
  maintainer answers with concrete design notes and "Happy to see your PR" (#107, #33). Then
  build exactly that shape.
- No issue template: plain issue with current behaviour, expected behaviour, reproduction, and the
  version and deploy mode (Docker, Helm, or built from source / Nix).

## 2. Designing the change

- Backend: Go, `backend/` (Fiber, viper config in `internal/config/config.go`; every key has a
  `GARAGE_UI_*` env var, and env vars override the config file). Frontend: React + Vite,
  `frontend/`.
- New config keys follow the existing pattern: struct field with `mapstructure` tag, default in
  `config.go`, `viper.BindEnv`, an entry in `config.example.yaml`, and, "all updated together",
  `helm/garage-ui/values.yaml` and `templates/configmap.yaml` (#107). Normalize values in config
  validation (#107: base path slashes).
- The Swagger `docs` package is generated (`swag init` in `backend/`), not checked in.
- Expect a security-minded review: the maintainer reproduces edge cases and posts them as
  `input -> output` with a suggested fix (#114: six findings incl. HTML injection, cookie path,
  route shadowing; #133: sort order vs. Garage's byte-order paging; #68: validate the prefix of an
  irreversible recursive delete).

## 3. Building and validating on NixOS

- nixpkgs package `garage-ui` (NixOS/nixpkgs#580190, ours) builds the frontend with
  `buildNpmPackage` and the backend with `buildGoModule` (`modRoot = "backend"`, `swag init` in
  `postConfigure`). For a dev shell: `nix shell nixpkgs#go nixpkgs#go-swag nixpkgs#nodejs_22`.
- Backend CI (`test.yml`): `cd backend && swag init && go test -race -count=1 -coverprofile=../coverage.out -coverpkg=./... ./...`,
  then `bash scripts/coverage-gate.sh coverage.out`: total coverage >= 70% and >= 70% each for
  `internal/{auth,config,handlers,services}`. A backend change needs tests that keep those floors.
- Frontend CI (`frontend-test.yml`, Node 22): `npm run lint`, `npm run build`, `npm run coverage`.
- `tests/smoke` (build tag `smoke`) needs Docker Compose and a live Garage; not run here.
- Run a built binary for runtime claims: `/health` returns the version; a fake or local
  single-node Garage v2 (`garage_2`) is enough for the admin API.

## 4. Commits

- **PRs are squash-merged; only the PR title must follow Conventional Commits**, checked by the
  `pr-title` workflow. Branch commits are free-form.
- Types: `feat`, `fix`, `feat!`, `perf`, `docs`, `refactor`, `chore`, `test`, `ci`, `build`.
  Scopes (optional, they route the version bump): `backend`, `frontend`, `helm`, `ci`, `deps`.
  Example: `feat(backend): add bucket quota enforcement`.

## 5. Pull request

- No template. Outside PRs that merged had: a summary of the change, `Closes #N`, and a test list
  with what was run (#133: "`npm run lint`, `npm run build` and `npm run coverage` pass on Node 22").
- Answer each review finding with the fix commit and how it was reproduced (#114, #133 did; both
  merged).

## 6. CI and bots

- Workflows on PRs: `test.yml` (backend tests + coverage gate, Codecov upload), `frontend-test.yml`,
  `pr-title.yml`. No branch protection on `main`; the maintainer merges by hand.
- Codecov posts a comment on fork PRs; it needs no answer.
- Dependabot (npm, Go) and `garage-ui-release-bot` (release-please) produce most PRs.

## 7. What the history shows

Measured 2026-11-01 (`upstream-contributing` / `contribution-skill-authoring` section 3 commands):
- Fork PR merge times, hours, among the last 40 merged PRs: 5, 16, 86, 95, 146, 258, 795. About
  half merge within four days. Command:
  `gh pr list -R Noooste/garage-ui --state merged --limit 40 --json createdAt,mergedAt,isCrossRepository --jq '[.[] | select(.isCrossRepository) | (((.mergedAt|fromdate) - (.createdAt|fromdate))/3600|floor)] | sort | join(",")'`
- Closed fork PRs: duplicates of a fix already on `main` (#131), or superseded by the maintainer's
  own PR (#138 → #139).
- All 45 issues: 38 closed as completed, 1 `wontfix` (#44, a misunderstanding), 6 open. Nearly
  every feature request was built, mostly by the maintainer within days to weeks, and announced
  with the release that has it (#56, #60, #88, #117). The maintainer answers within a day or two
  and asks reporters to confirm and close.
- 14 outside PRs: 12 merged, 2 closed (#131 duplicate, #138 superseded by #139). Review rounds
  are concrete and get merged once addressed (#68, #114, #119).

## 8. Our setup and current threads

- Downstream: nixpkgs `garage-ui` (NixOS/nixpkgs#580190, draft); the fleet runs it as a container
  on nixos-nvme (nix-presets `containers/garage-ui.nix`).
- No fork or clone yet; when needed: fork `Noooste/garage-ui` to `kleinbem/garage-ui`, clone to
  `~/Develop/github.com/Noooste/garage-ui` (jj, `origin` upstream, `fork` ours).
- Workarounds in the nixpkgs package that want upstream changes (2026-11-01):
  - The wrapper sets `GARAGE_UI_SERVER_FRONTEND_PATH`, because the frontend default is the
    CWD-relative `./frontend/dist` (`internal/routes/routes.go`), and that env var outranks a
    config file's `server.frontend_path`. Asked for a runtime fallback to
    `<exe dir>/../share/garage-ui`: Noooste/garage-ui#145.
  - No `versionCheckHook`, because the binary has no `--version` flag: Noooste/garage-ui#146.

## Review checklist

- PR title is Conventional Commits with an allowed type and, if any, an allowed scope (section 4); it becomes the
  squash commit and the changelog line.
- Backend change: `go test -race` passes and `scripts/coverage-gate.sh` floors still hold
  (section 3); new code has tests in the touched package.
- Config change: struct tag, default, `BindEnv`, `config.example.yaml`, Helm values (section 2).
- Search showed no fix on `main` and no earlier maintainer decision against it (section 1, #127).
- Edge cases a security-minded reviewer would try (escaping, cookie paths, route collisions) are
  handled or ruled out (#114).
- PR text lists what was run, with versions (section 5).
