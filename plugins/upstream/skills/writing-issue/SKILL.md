---
name: writing-issue
description: Pure input-to-output GitHub issue writer for bug reports and feature requests. Takes facts (symptom or problem, repro steps, versions/environment, logs, workaround, form/template) or a draft issue and writes a concise, human-sounding issue title and body from that input alone. Does not read code, other skills, or other issues.
---

# Writing an issue

Read `~/.agents/skills/writing/SKILL.md` first for the shared input-only boundary, human voice, link hygiene, and `Missing from input:` rules.

## Input to expect

- **Issue type:** bug report, feature request / proposal, or general issue.
- **Bug report facts:** observable symptom, exact versions (OS, app/package version, release vs `main`/commit, last good version if a regression), numbered steps from a clean state, expected vs actual behaviour, scrubbed exact log/error excerpt, frequency, and any suspected root cause (explicitly marked unverified unless proven).
- **Feature request facts:** the problem in plain terms, current workaround (or `"none"`), proposed behaviour, explicit non-goals, and alternatives considered.
- **Constraints:** issue form/template fields in order, title format, related/closest existing issue (or `"none found"`), and any AI disclosure line if requested.
- **Optional draft:** existing notes or draft issue to rewrite.

## Issue rules

- **One issue per issue:** Never bundle unrelated problems into one issue. If the input mixes separate issues, flag it below the output.
- **Bug report:**
  1. **What's broken:** Observable symptom first (and frequency if intermittent). Never paraphrase an error message; put scrubbed exact lines in a fenced code block.
  2. **Reproduction:** Numbered, copy-pasteable steps starting from a clean state.
  3. **Expected vs actual:** Two clear, separate statements.
  4. **Environment & versions:** Exact OS, version/commit, and last good version if known. Write `"unknown"` only if the input says it is unknown.
- **Feature request:**
  1. **Problem first:** Lead with the problem today, not the implementation you want.
  2. **Current workaround:** What you do today (or `"none"`).
  3. **Proposal & non-goals:** What you would like to see, why it belongs here, and what is explicitly out of scope (e.g. out-of-scope environments or workflows).
- **Forms and templates:** Match a provided issue form's field order and headings so it pastes cleanly. Without a form, use plain short paragraphs or minimal factual labels (`Steps to reproduce`, `Expected`, `Actual`, `Environment`).

## Output format

**Title:** `<title>`

```markdown
<issue body>
```

If anything needed for a complete issue was missing (e.g. **Version / release check**, **Reproduction**, **Expected vs actual**, or **Form/template**), list it below the code block under `**Missing from input:**`.
