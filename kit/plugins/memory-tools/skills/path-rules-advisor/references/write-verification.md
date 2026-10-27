# Verify the write

Run the verify command immediately after every file write (Mode A Step 7, Mode B Steps 6 and 7),
substituting the path just written for the placeholder. The runnable command is the
`verify_write.py` invocation given in the skill body's "Verify the write" section — this
reference is not placeholder-substituted, so take the command from there, not from here. The
script shows the resulting diff, then asserts the file still parses with valid frontmatter and a
non-empty body.

Rule files must always clear this check — a rule file with no `paths:` frontmatter or no bullets
loads as dead weight in every future session.

If the command exits non-zero, **STOP**. Report the failure with the file path and the printed
reason, tell the user to restore from their backup (`git checkout -- <path>` where the file is
tracked), and do not attempt a second write.

## Verification gate (before the write)

Run the same check (the skill body's `verify_write.py` command) on the *input* before any write. If the CLAUDE.md resolved in Mode B
Step 1, or an existing rule file being overwritten, opens with a `---` block that is unterminated
or contains a non key/value line, REPORT rather than write.
