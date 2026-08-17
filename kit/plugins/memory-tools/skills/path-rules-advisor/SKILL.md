---
name: path-rules-advisor
description: "Creates path-specific rule files in .claude/rules/. Analyzes project structure and generates scoped rules for file types or directories. Use when the user wants to add path-specific rules."
allowed-tools: AskUserQuestion, Bash(memory-verify-write *), Edit, Glob, Read, Write
---

Analyze the project and CLAUDE.md to recommend and create path-specific rule files in `.claude/rules/`. Follow the mode determined by the user's message.

## When not to use

Does not create or overwrite global memory entries — use agentic-memory-management for that.

## References

- `references/rule-modes.md` — the full Mode A and Mode B steps
- `references/rule-file-format.md` — the generated-file template, brace expansion, and notes
- `references/write-verification.md` — the diff-back, the frontmatter parse check, and the pre-write gate

## Select the mode

| The user's message | Mode | Read |
|---|---|---|
| carries an argument (`<glob-pattern> - <rule description>`) | **A** | `references/rule-modes.md`, Mode A |
| carries no argument | **B** (analysis) | `references/rule-modes.md`, Mode B |

Read that reference for the mode you selected, and follow its steps in order. Emit
generated rule files in the shape defined by `references/rule-file-format.md`.

## Two hard stops

Neither mode may write anything until the user has confirmed. These two
confirmations are the contract, and they hold whatever the reference says:

1. **Directory creation.** If `.claude/rules/` does not exist, say so and ask
   "Should I create it?" Do not write any file until the user confirms.
2. **Every file write.** Show the complete file in a code block first, then ask
   "Should I write this to `.claude/rules/<filename>`?" Wait for explicit
   confirmation. An existing file at that path is a third stop: show the path and
   ask whether to overwrite or pick a new filename.

Each write site ends the same way:

- Mode A Step 7 — after writing the rule file, run [Verify the write](#verify-the-write) on it.
- Mode B Step 6 — after each approved rule file, run [Verify the write](#verify-the-write) on it.
- Mode B Step 7 — editing CLAUDE.md is a write like any other, so run [Verify the write](#verify-the-write) on it too.

## Verify the write

Run this after **every** write, without exception:
`memory-verify-write <absolute-path-to-file-just-written>` — substitute the
path just written for the placeholder. The executable diff-back and the
frontmatter parse check live in `references/write-verification.md` — read and
run it there.

The rule it enforces stays here: the check must show the resulting diff and
confirm the written file still parses with valid frontmatter and a non-empty
body. Rule files must always clear it — a rule file with no `paths:` frontmatter
or no bullets loads as dead weight in every future session.

If the check exits non-zero, **STOP**. Report the failure with the file path and
the printed reason, tell the user to restore from their backup
(`git checkout -- <path>` where the file is tracked), and do not attempt a second
write.

### Verification gate

Run the same parse check on the *input* before any write. If the CLAUDE.md resolved in Mode B
Step 1, or an existing rule file being overwritten, opens with a `---` block that is unterminated
or contains a non key/value line, REPORT rather than write.
