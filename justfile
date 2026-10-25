# kleinbem/skills

default:
    @just --list

# Refresh the contribution skills with a local agent (AGENT=claude|goose); scope = part of a skill name
refresh-skills scope="":
    scripts/refresh-skills.sh {{ quote(scope) }}

# Check the marketplace and every plugin
validate:
    claude plugin validate .
