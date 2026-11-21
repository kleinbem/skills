---
name: writing-pr
description: Pure input-to-output pull request writer. Takes facts (what changed, why, test results, constraints/template) or a draft PR and writes a concise, human-sounding PR title and body from that input alone. Does not read code, other skills, or other PRs.
---

# Writing a pull request

Read `~/.agents/skills/writing/SKILL.md` first for the shared input-only boundary, human voice, link hygiene, and `Missing from input:` rules.

## Input to expect

- **What changed and why:** visible behaviour/fix, problem solved, trade-offs, dependencies (`Depends on #N`), non-obvious choices, and upstream links for workarounds.
- **Verification:** exact commands, platforms, numbers, and proof runs (e.g. failed on old code, passed on fix).
- **Constraints:** title format, PR template, and any AI disclosure line if requested.
- **Optional draft:** an existing draft PR or notes to rewrite.

## PR rules

- **Title:** Follow any title format given in the input (or use a clear, concise imperative title if none is given). Describe the visible change or fix, not the implementation.
- **Body:**
  1. **What and why:** What the change adds or fixes and why it's needed. State trade-offs (e.g. size or performance impact) up front in the first paragraph.
  2. **Dependencies and overlaps:** `Depends on #N` if stacked, or overlapping open PRs if given in the input.
  3. **Non-obvious choices and workarounds:** Brief reason for each non-obvious choice, and an upstream link for every workaround.
  4. **Verification:** Exact commands, platforms, and numbers from the input, plus the proof run when provided.
  5. **Template and checkboxes:** Keep a provided PR template's headings intact. Tick `- [x]` **only** when the input confirms it is true for the exact head commit; otherwise leave `- [ ]`. Leave no `TODO`s or placeholders.
  6. **Rewriting a draft:** Drop unverified claims, keep only what the facts support, and rewrite in Martin's voice. Do not repeat what the title or commit messages already say.

## Output format

**Title:** `<title>`

```markdown
<PR body>
```

If anything needed for a complete PR was missing (e.g. **Why**, **Verification**, **Workaround links**, or **Constraints**), list it below the code block under `**Missing from input:**`.
