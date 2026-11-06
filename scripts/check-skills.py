#!/usr/bin/env python3
"""Structural checks for the skills marketplace (run by CI and `just check`).

- every SKILL.md has YAML frontmatter with `name` (= its directory) and a
  `description`
- organization and repository skills (`*-org`, `*-contributing`, except the
  always-loaded `upstream-contributing`) are manual:
  `disable-model-invocation: true`
- every plugin directory is listed in .claude-plugin/marketplace.json and
  every listed source exists
- every skill has a row in the README table
- skills named in backticks as `<x>-org` / `<x>-contributing` exist, and
  `~/.agents/skills/<skill>/<file>` references point at a file in this repo
"""

import json
import re
import sys
from pathlib import Path

import yaml

root = Path(__file__).resolve().parent.parent
errors: list[str] = []


def err(path: Path, msg: str) -> None:
    errors.append(f"{path.relative_to(root)}: {msg}")


skills: dict[str, Path] = {}
for md in sorted(root.glob("plugins/*/skills/*/SKILL.md")):
    text = md.read_text()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        err(md, "no YAML frontmatter")
        continue
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError as e:
        err(md, f"invalid frontmatter: {e}")
        continue
    name = fm.get("name")
    if name != md.parent.name:
        err(md, f"name {name!r} does not match directory {md.parent.name!r}")
    if not str(fm.get("description", "")).strip():
        err(md, "missing description")
    manual = name and re.search(r"-(org|contributing)$", name) and name != "upstream-contributing"
    if manual and fm.get("disable-model-invocation") is not True:
        err(md, "organization/repository skill needs disable-model-invocation: true")
    if name:
        skills[name] = md.parent

market = json.loads((root / ".claude-plugin/marketplace.json").read_text())
listed = {Path(p["source"]).name for p in market["plugins"]}
for p in market["plugins"]:
    if not (root / p["source"] / ".claude-plugin/plugin.json").is_file():
        err(root / ".claude-plugin/marketplace.json", f"{p['name']}: no plugin.json under {p['source']}")
for d in sorted((root / "plugins").iterdir()):
    if d.is_dir() and d.name not in listed:
        err(d, "plugin not listed in .claude-plugin/marketplace.json")

readme = (root / "README.md").read_text()
for name, d in skills.items():
    if f"`{name}`" not in readme:
        err(d / "SKILL.md", "no row in the README table")

for md in sorted(root.glob("plugins/*/skills/*/*.md")):
    text = md.read_text()
    for ref in sorted(set(re.findall(r"`([a-z0-9-]+-(?:org|contributing))`", text))):
        if ref not in skills:
            err(md, f"names skill `{ref}`, which does not exist")
    for skill, f in sorted(set(re.findall(r"~/\.agents/skills/([a-z0-9-]+)/([A-Za-z0-9_.-]+)", text))):
        if not (skills.get(skill) and (skills[skill] / f).is_file()):
            err(md, f"~/.agents/skills/{skill}/{f} does not exist in this repo")

for e in errors:
    print(f"::error::{e}" if "GITHUB_ACTIONS" in __import__("os").environ else e)
print(f"{len(skills)} skills, {len(errors)} problems")
sys.exit(1 if errors else 0)
