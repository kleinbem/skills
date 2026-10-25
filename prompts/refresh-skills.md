Monthly refresh of the contribution skills in kleinbem/skills (the current directory, a fresh
checkout of main).

HARD LIMITS: you may only change files in kleinbem/skills, on a new branch, through one pull
request. Never open, comment on, react to or edit anything in any other repository (no upstream
issues, PRs, comments, reviews). Upstream repos are read-only sources.

1. Read plugins/upstream/skills/upstream-contributing/SKILL.md (the router and its route table)
   and plugins/upstream/skills/contribution-skill-authoring/SKILL.md (section 1 sources,
   section 3 measurement commands, section 6 refresh). Follow section 6 for every organization
   skill (plugins/*/skills/*-org/SKILL.md and ggml-org) and every repository skill
   (plugins/*/skills/*-contributing/SKILL.md except upstream-contributing). If a SCOPE line
   follows this prompt, refresh only the skills whose directory name contains it.
2. For each: reread the upstream sources the skill names (CONTRIBUTING.md, AGENTS.md, PR
   templates, workflows, SECURITY.md, the org .github repo) via `gh api` or the GitHub REST API
   with curl, compare with what the skill states, and rerun the measurement commands for PRs
   since the skill's 'as of' date.
3. Edit only what changed: rules that changed upstream, new reviewer patterns that appear in at
   least two PRs (cite PR numbers), updated numbers in 'What the history shows', the 'as of'
   date. Keep each skill's style, section order and length; don't rewrite unchanged text; keep
   `disable-model-invocation: true` in org and repo skills. If a fact moved to a different
   layer, put it in the highest layer where it is true. Update the switches table in
   upstream-contributing if a repo's policy changed.
4. Run `claude plugin validate .` if the claude CLI exists; otherwise check every SKILL.md still
   has valid frontmatter (name, description, disable-model-invocation where it was).
5. If nothing changed, make no PR and end with 'no changes'. Otherwise: branch
   `chore/skills-refresh-<YYYY-MM>`, one commit `docs(skills): monthly refresh <YYYY-MM>`, push
   it and open a PR against main with a short body: one line per changed skill saying what
   changed and the upstream source or PR numbers that prove it, ending with the attribution line
   of the agent that did the work. Then enable squash auto-merge (`gh pr merge --auto
   --squash`); if that fails because the PR is already mergeable, merge it with `gh pr merge
   --squash`. If merging is blocked (e.g. required signatures), leave the PR open and say so.

Final answer: the PR link (or 'no changes'), one line per changed skill, and anything you
couldn't check (rate limits, missing access).
