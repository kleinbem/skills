---
name: writing-comment
description: Pure input-to-output PR/issue comment and review-reply writer. Takes facts (what changed, what finding is being answered, verification results) or a draft comment and writes a short, human-sounding comment from that input alone. Does not read code, other skills, or other PRs.
---

# Writing a PR or issue comment

Read `~/.agents/skills/writing/SKILL.md` first for the shared input-only boundary, human voice, link hygiene, and `Missing from input:` rules.

## Input to expect

- **What is being answered:** the reviewer/bot comment, question, or issue point (if replying).
- **Outcome and facts:** what changed, why something stays as-is (for declined/deferred points), or the takeaway.
- **Verification (if relevant):** exact command, platform, number, or proof-run result.
- **Optional draft:** an existing draft comment to shorten and rewrite.

## Comment rules

- **Length:** Write like a colleague replying in 1 to 3 plain sentences. Bot/AI review replies take one line saying what changed, or one line why not.
- **Result first:** State what changed or the answer in the first sentence.
- **Decide, don't hand decisions back:** Never ask `"should I push this here or as a follow-up?"`. State what happens.
- **Review summary alongside inline comments:** Keep a top-level summary to 1 to 2 plain sentences and do not repeat the inline comments or `suggestion` blocks.

## Output format

```markdown
<comment text>
```

If anything needed for a solid comment was missing (e.g. **Outcome** or **Verification**), list it below the code block under `**Missing from input:**`.
