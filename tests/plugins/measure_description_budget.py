#!/usr/bin/env python3
"""Measure a SKILL.md description against the budget rule.

The rule (kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md):
  - total description <= 200 chars
  - first sentence <= 80 chars, so a truncated listing still reads as a label

Usage:
  measure_description_budget.py <SKILL.md>    prints "<total> <first_sentence>"
  measure_description_budget.py --sweep <dir> prints one line per violation; silent when clean
Exit 0 unless --sweep found violations.
"""
import glob
import os
import re
import sys

LIMIT_TOTAL = 200
LIMIT_FIRST = 80


def description(path):
    fm = re.search(r"^---\n(.*?)\n---", open(path).read(), re.S)
    if not fm:
        return None
    d = re.search(r"^description:\s*(.+?)(?=\n[a-z-]+:|\Z)", fm.group(1), re.S | re.M)
    if not d:
        return None
    return " ".join(d.group(1).split()).strip("\"'")


def measure(desc):
    """Return (total, first_sentence_len). The sentence excludes its trailing space."""
    m = re.search(r"(?<=[.!?])\s", desc)
    return len(desc), len(desc[: m.start()] if m else desc)


def main():
    if sys.argv[1] == "--sweep":
        root = sys.argv[2]
        bad = []
        for f in sorted(glob.glob(os.path.join(root, "kit/plugins/**/SKILL.md"), recursive=True)):
            desc = description(f)
            if not desc:
                continue
            total, first = measure(desc)
            rel = os.path.relpath(f, root)
            if total > LIMIT_TOTAL:
                bad.append(f"{rel}: {total} chars total (>{LIMIT_TOTAL})")
            if first > LIMIT_FIRST:
                bad.append(f"{rel}: first sentence {first} chars (>{LIMIT_FIRST})")
        print("\n".join(bad))
        return 1 if bad else 0

    desc = description(sys.argv[1])
    if desc is None:
        print("no description", file=sys.stderr)
        return 2
    print("%d %d" % measure(desc))
    return 0


if __name__ == "__main__":
    sys.exit(main())
