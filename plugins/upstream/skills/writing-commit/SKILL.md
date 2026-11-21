---
name: writing-commit
description: Pure input-to-output commit message writer. Takes facts (what changed, why, constraints, trailers/format rules) or a draft commit message and writes a concise, well-structured commit message from that input alone. Does not read code, other skills, or git/jj history.
---

# Writing a commit message

Read `~/.agents/skills/writing/SKILL.md` first for the shared input-only boundary, human voice, link hygiene, and `Missing from input:` rules.

## Input to expect

- **What changed:** the logical change in plain terms.
- **Why and context:** the problem solved, non-obvious constraints, or trade-offs.
- **Format and trailers:** any subject prefix/convention, issue reference, or trailers (e.g. sign-off or attribution) to include.
- **Optional draft:** an existing commit message to tighten or rewrite.

## Commit message rules

- **Subject line:**
  - Imperative mood (`Add ...`, `Fix ...`, `Remove ...`), not past tense or `-ing`.
  - Concise (aim for 50 to 72 characters unless a required prefix needs slightly more) with no trailing period.
  - Apply any prefix/convention from the input; otherwise use a plain imperative subject.
  - If the input describes unrelated changes, flag it below the output rather than stretching the subject.
- **Body:**
  - Omit the body for trivial commits where the subject says everything needed.
  - Explain **why** the change is needed and any non-obvious trade-offs, not a file-by-file diff narration.
  - Leave one blank line after the subject and wrap prose lines at around 72 characters.
- **Trailers:** Include only trailers explicitly requested or provided in the input, separated from the body by one blank line.

## Output format

```text
<subject>

<optional body>

<optional trailers>
```

If anything needed was missing (e.g. **Why** or **Format / trailers**), list it below the code block under `**Missing from input:**`.
