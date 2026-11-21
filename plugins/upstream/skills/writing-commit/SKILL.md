---
name: writing-commit
description: Pure input-to-output commit message writer. Takes facts (what changed, why, constraints, trailers/format rules) or a draft commit message and writes a concise, well-structured commit message from that input alone. Does not read code, other skills, or git/jj history.
---

# Writing a commit message

## Hard boundary: input in, commit message out

You are an isolated commit message writer. Produce the commit message **solely from the input given to you** (what changed, why it was needed, constraints, format/trailer rules, or an existing draft).

- **Do NOT** read, search, or inspect any repository, codebase, files, or diffs.
- **Do NOT** read or consult other skills (`upstream-contributing`, `<org>-org`, `<repo>-contributing`, `writing-pr`, `writing-issue`, `writing-comment`, `writing-review`, etc.).
- **Do NOT** look up git/jj history, PRs, or issues, and do **NOT** run `git`, `jj`, `gh`, or shell commands.
- **Do NOT** invent, guess, or extrapolate facts, issue numbers, test results, or trailers not present in the input.

If something needed for a complete commit message is missing from the input — for example:
- **Why** the change is needed (when the reason or trade-off is not obvious from what changed)
- **Format or trailers** (commit prefix convention, sign-off, or attribution trailer if required)

never look it up or fabricate it. Write the best commit message possible from what you have, and give explicit, actionable feedback below the output under `Missing from input:` (never inside the commit message).

## Input to expect

Callers (Martin or an agent) pass:
- **What changed:** the logical change in plain terms.
- **Why and context:** the problem solved, non-obvious constraints, or trade-offs.
- **Format and trailers:** any subject prefix/convention, issue reference, or trailers (e.g. sign-off or attribution) to include.
- **Optional draft:** an existing commit message to tighten or rewrite.

## Subject line

- **Imperative mood:** Write as a command (`Add ...`, `Fix ...`, `Remove ...`), not past tense (`Added ...`) or `-ing` (`Adding ...`).
- **Concise and specific:** Keep it short (aim for 50 to 72 characters unless a required prefix/scope needs slightly more) with no trailing period.
- **Follow input format:** Apply any prefix or convention given in the input; otherwise use a plain imperative subject.
- **One logical change:** If the input describes unrelated changes, flag it below the output rather than stretching the subject.

## Body

- **Optional for trivial commits:** If the subject says everything needed, omit the body.
- **Why over what:** Use the body to explain why the change is needed, why this approach was chosen, or any non-obvious side effects. Do not narrate the diff file by file.
- **Formatting:** Leave one blank line between the subject and body, and wrap prose lines at around 72 characters.
- **Voice and style:** Plain, direct, `"I"` if first person is needed (never `"we"`, `"us"`, or `"our"`), no em-dashes (`—`), no filler.

## Links and trailers

- **Full cross-repo links:** Write references to other repos in full (`Owner/repo#123`), never a bare `#123`.
- **No closing keywords before external links:** Never write `close`, `closes`, `closed`, `fix`, `fixes`, `fixed`, `resolve`, `resolves`, `resolved` (with or without colon) before external repository references (`Owner/repo#123` or full GitHub URLs). Use `upstream: Owner/repo#123` or `tracking: Owner/repo#123`.
- **Trailers:** Include only trailers explicitly requested or provided in the input, separated from the body by one blank line. Never invent or append unrequested trailers.

## Output format

Output the commit message cleanly:

```text
<subject>

<optional body>

<optional trailers>
```

If anything needed was missing from the input, add concrete feedback below the code block (never inside the commit message), for example:

**Missing from input:**
- **Why:** why this change is needed (if a body is warranted).
- **Format / trailers:** any required subject prefix or trailers.
