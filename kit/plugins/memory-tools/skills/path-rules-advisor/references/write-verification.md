# Verify the write

Run this immediately after every file write (Mode A Step 7, Mode B Steps 6 and 7), substituting
the path just written for the placeholder. `memory-verify-write` is a bundled `bin/` wrapper on
the Bash tool's PATH; it shows the resulting diff, then asserts the file still parses with valid
frontmatter and a non-empty body.

```bash
memory-verify-write <absolute-path-to-file-just-written>
```

Rule files must always clear this check — a rule file with no `paths:` frontmatter or no bullets
loads as dead weight in every future session.

If the command exits non-zero, **STOP**. Report the failure with the file path and the printed
reason, tell the user to restore from their backup (`git checkout -- <path>` where the file is
tracked), and do not attempt a second write.

## Verification gate (before the write)

Run the same check (`memory-verify-write <path>`) on the *input* before any write. If the CLAUDE.md resolved in Mode B
Step 1, or an existing rule file being overwritten, opens with a `---` block that is unterminated
or contains a non key/value line, REPORT rather than write.
