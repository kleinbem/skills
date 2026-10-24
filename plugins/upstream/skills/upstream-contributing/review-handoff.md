# Review handoff: template

Used by `upstream-contributing`, section 6. The author session copies this to
`~/.cache/<repo>-<N>-review-handoff.md` (e.g. `nixpkgs-574877-review-handoff.md`), fills in every
field, and gives Martin the prompt at the end. Write "none" or "not done" rather than leaving a
field out, so the reviewer doesn't go looking.

---

# <owner>/<repo> #<N> (<short name>): review before ready

Review only: don't edit, commit, push or comment anywhere. Read `upstream-contributing`,
`<org>-org` and `<repo>-contributing` first (`~/.agents/skills/<name>/SKILL.md`).

**What to review**
- PR: <URL>, <draft / ready since <date>, no human review yet / reviewed by …>
- Branch `<branch>`, head `<full or 12-char SHA from git>`, worktree `<path>`
  (or: not pushed yet, fork branch `<branch>`, compare URL)
- Title: `<title>`
- Body: `<path to the posted or planned body>`
- Commits (`<sha> <subject>` each, and why any commit belongs to another PR as well)
- Files touched

**History**
- Earlier review rounds: where the findings are, and which ones were fixed (the reviewer verifies
  each one is really fixed)
- Decisions on purpose, so the reviewer doesn't re-litigate them (pins, scope cuts, deferred work,
  with the reason)

**Done, with evidence**
- Checks and CI runs (run IDs, per platform, at which head; a different head counts only if the
  tree is identical)
- Builds and runtime tests (host, hardware, what was exercised, numbers)
- Formatting and linters
- Attribution as committed (trailers per commit)

**Not done**
- What wasn't run or tested, and why

**Worth checking**
- The repo skill's "Review checklist", plus anything specific to this change

**Output**
Findings ranked by severity (blocker, should fix, nit), each with file:line, the rule or source it
breaks, and a suggested fix. Then what was checked and found fine. Then open questions for Martin.

---

Prompt for the review session (fill in the two paths):

```
Read <handoff path> and review <owner>/<repo> #<N> as it describes. Load the
upstream-contributing skill, then read the org and repository skills it routes to,
and check against the sources of truth in the checkout. Also review the PR body
<body path>, and verify every fix from earlier review rounds.

Review only: don't edit, commit, push or comment anywhere. Report your findings
ranked by severity, each with file:line and a suggested fix, and say clearly what
you checked and found fine.
```
