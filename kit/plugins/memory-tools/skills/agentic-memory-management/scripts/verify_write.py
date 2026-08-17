#!/usr/bin/env python3
"""Post-write verification for memory-tools file writes.

Invoked through the plugin's bin/memory-verify-write wrapper as:

    memory-verify-write <path-to-file-just-written>

Shows the resulting diff (git diff for tracked files, git diff --no-index
against /dev/null for untracked ones), then asserts the file still parses
with valid frontmatter and a non-empty body. Exits non-zero with a
MALFORMED/EMPTY/MISSING report when the check fails — the calling skill
treats any non-zero exit as STOP: report, tell the user to restore from
backup, and do not attempt a second write.

Shared by agentic-memory-management (Step 7) and path-rules-advisor
(references/write-verification.md). One copy on disk replaces the two
inline heredoc copies that used to drift.
"""

import os
import subprocess
import sys


def show_diff(path):
    tracked = (
        subprocess.run(
            ["git", "ls-files", "--error-unmatch", path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )
    if tracked:
        subprocess.run(["git", "--no-pager", "diff", "--", path])
    else:
        # diff --no-index exits 1 when the files differ; for a fresh file
        # that is the expected outcome, not an error, so the status is
        # deliberately ignored.
        subprocess.run(
            ["git", "--no-pager", "diff", "--no-index", "--", "/dev/null", path]
        )


def check(path):
    text = open(path, encoding="utf-8").read()
    body = text
    if text.startswith("---\n"):
        end = text.find("\n---", 3)
        if end == -1:
            sys.exit(f"MALFORMED: {path} opens a frontmatter block that is never closed")
        for n, line in enumerate(text[4:end].splitlines(), 2):
            # Indented lines are nested values or block-scalar continuations,
            # which carry no colon of their own. Only top-level keys are
            # checked.
            if not line.strip() or line[:1] in (" ", "\t"):
                continue
            s = line.strip()
            if not s.startswith(("#", "- ")) and ":" not in s:
                sys.exit(
                    f"MALFORMED: {path} line {n}: expected a YAML key/value, got {s!r}"
                )
        body = text[end + 4 :]
    if not body.strip():
        sys.exit(f"EMPTY: {path} has no body content")
    print(f"OK: {path} parses, {len(body.strip().splitlines())} body lines")


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: memory-verify-write <path-to-file-just-written>")
    path = sys.argv[1]
    if not os.path.isfile(path):
        sys.exit(f"MISSING: {path} does not exist — the write never landed")
    show_diff(path)
    check(path)


if __name__ == "__main__":
    main()
