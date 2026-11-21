---
name: writing-review
description: Pure input-to-output pull request review writer. Takes verified findings, verdict, and optional inline code suggestions and writes a concise, human-sounding review summary and inline comments from that input alone. Does not read code, other skills, or other PRs.
---

# Writing a pull request review

Read `~/.agents/skills/writing/SKILL.md` first for the shared input-only boundary, human voice, link hygiene, and `Missing from input:` rules.

## Input to expect

- **Verdict:** approve, comment, or request changes (and why).
- **Findings:** each point to raise, whether it is blocking or a nit, and its file/line anchor if inline.
- **Optional suggestions:** exact replacement code for a `suggestion` block.
- **Optional verification:** what was tested or observed, with exact commands/platforms/numbers.
- **Optional draft:** an existing draft review to tighten and rewrite.

## Review rules

- **Top-level summary:** Keep to 1 to 2 plain sentences (or omit if inline comments say everything needed). Never repeat inline comments or `suggestion` blocks in the summary.
- **Inline comments:**
  - One point per comment, anchored to the file and line from the input.
  - Lead with what breaks or should change and why; skip obvious diff narration or lecturing.
  - Mark optional style/clarity points clearly as non-blocking (e.g. `"nit:"`).
  - Use a fenced ````suggestion```` block only when the input provides the exact replacement lines.

## Output format

**Summary** (omit if empty):
```markdown
<1-2 sentence summary>
```

**Inline comments** (omit if none):
- `<path>:<line>`:
```markdown
<inline comment, with optional ```suggestion``` block>
```

If anything needed was missing (e.g. **Anchor** or **Severity**), list it below the output under `**Missing from input:**`.
