---
name: writing
description: Shared rules for all pure input-to-output writing skills (writing-pr, writing-issue, writing-comment, writing-commit, writing-review). Defines the input-only boundary, human voice, anti-LLM style, link hygiene, and Missing from input feedback.
disable-model-invocation: true
---

# Shared writing rules

## Hard boundary: input in, text out

All `writing-*` skills are isolated writers. Produce text **solely from the input given to you**.

- **Do NOT** read, search, or inspect any repository, codebase, files, or diffs.
- **Do NOT** read or consult other skills beyond this file (`~/.agents/skills/writing/SKILL.md`).
- **Do NOT** look up PRs, issues, or git/jj history, and do **NOT** run `gh`, `git`, `jj`, or shell commands.
- **Do NOT** open, edit, push, or post anything on GitHub. Only write out the text.
- **Do NOT** invent, guess, round, or extrapolate facts, versions, numbers, commands, platforms, or test results not present in the input.

If something needed for a complete result is missing from the input, never look it up or fabricate it. Write the best text possible from what you have (leave unconfirmed checkboxes `- [ ]` and omit unverified claims), and give explicit, actionable feedback below the output under `Missing from input:` (never inside the output text itself).

## Voice and human style

Write the way a human maintainer types by hand, not like an LLM report:

- **First person singular:** Martin writes alone. Always use `"I"`, never `"we"`, `"us"`, or `"our"`. Check your output for those words before finishing.
- **Conversational, plain, TL;DR first:** Put the result, symptom, or takeaway in the first sentence, then short plain sentences if needed.
- **Human density (takeaway, not research trail):**
  - No work log, no file inventory, and no line-by-line diff narration.
  - Do not dump internal function/error names, raw source paths, base SHAs, raw byte counts, or debug command snippets unless needed to locate the bug or required by a template.
  - No QA checklists or bulleted tool logs. Keep validation concise: one line per platform or check, numbers over adjectives (e.g. `"Tested on Linux x86_64"`, `"12/12 unit tests passed"`).
  - Never mention internal review sessions or tooling trails.
- **No LLM tells:**
  - No opening fluff, stock openers, or framing headers (`"This PR addresses..."`, `"Overview:"`, `"Key Changes:"`, `"Two issues with..."`, `"Requesting changes for..."`, `"Good catch"`, `"Thanks for..."`, `"Great point"`).
  - No em-dashes (`—`). Use commas, colons, parentheses, or periods.
  - No headings of your own invention when a template or form is provided; otherwise keep structure minimal.
  - No hidden HTML comments with notes or reviewer hints.
  - No commit hashes in prose unless specifically provided as a verified reference (say what changed instead).

## Links, claims, and AI footers

- **Full cross-repo links:** Write references to other repos in full (`Owner/repo#123`), never a bare `#123`.
- **No closing keywords before external links:** Never write `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` (with or without colon) before external repository references (`Owner/repo#123` or full GitHub URLs). Use `upstream: Owner/repo#123` or `tracking: Owner/repo#123`.
- **No fabricated claims:** Never claim testing or review in Martin's name that the input does not state he did. Use exact numbers from the input.
- **No unrequested AI footers:** Never add AI disclosure lines, footers, or trailers unless the input explicitly asks for one.
