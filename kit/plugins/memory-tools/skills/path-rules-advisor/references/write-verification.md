# Verify the write

Run this immediately after every file write (Mode A Step 7, Mode B Steps 6 and 7). Show the
resulting diff, then assert the file still parses with valid frontmatter and a non-empty body.

```bash
TARGET=<substitute the path just written — not a literal>
if git ls-files --error-unmatch "$TARGET" >/dev/null 2>&1; then
  git --no-pager diff -- "$TARGET"
else
  git --no-pager diff --no-index -- /dev/null "$TARGET" || true
fi
python3 - "$TARGET" <<'EOF'
import sys
path = sys.argv[1]
text = open(path, encoding='utf-8').read()
body = text
if text.startswith('---\n'):
    end = text.find('\n---', 3)
    if end == -1:
        sys.exit(f"MALFORMED: {path} opens a frontmatter block that is never closed")
    for n, line in enumerate(text[4:end].splitlines(), 2):
        # Indented lines are nested values or block-scalar continuations, which
        # carry no colon of their own. Only top-level keys are checked.
        if not line.strip() or line[:1] in (' ', '\t'):
            continue
        s = line.strip()
        if not s.startswith(('#', '- ')) and ':' not in s:
            sys.exit(f"MALFORMED: {path} line {n}: expected a YAML key/value, got {s!r}")
    body = text[end + 4:]
if not body.strip():
    sys.exit(f"EMPTY: {path} has no body content")
print(f"OK: {path} parses, {len(body.strip().splitlines())} body lines")
EOF
```

Rule files must always clear this check — a rule file with no `paths:` frontmatter or no bullets
loads as dead weight in every future session.

If the command exits non-zero, **STOP**. Report the failure with the file path and the printed
reason, tell the user to restore from their backup (`git checkout -- <path>` where the file is
tracked), and do not attempt a second write.

## Verification gate (before the write)

Run the same parse check on the *input* before any write. If the CLAUDE.md resolved in Mode B
Step 1, or an existing rule file being overwritten, opens with a `---` block that is unterminated
or contains a non key/value line, REPORT rather than write.
