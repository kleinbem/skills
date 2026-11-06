# kleinbem/skills

default:
    @just --list

# Refresh the contribution skills with a local agent (AGENT=claude|goose); scope = part of a skill name
refresh-skills scope="":
    scripts/refresh-skills.sh {{ quote(scope) }}

# What CI runs: skill structure, then the marketplace and every plugin
check:
    nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages (p: [p.pyyaml])' -c python3 scripts/check-skills.py
    claude plugin validate .
