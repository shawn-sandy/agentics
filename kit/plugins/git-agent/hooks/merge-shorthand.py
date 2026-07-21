#!/usr/bin/env python3
"""UserPromptSubmit hook: route the literal prompt `merge?` to git-agent:merge.

Anchored match only — any prompt that merely contains "merge" is left alone.
"""
import json
import re
import sys

PATTERN = re.compile(r"^\s*merge\?\s*$", re.IGNORECASE)

try:
    # `prompt` may be absent, null, or a non-string on a malformed payload —
    # this hook runs on every prompt, so any surprise must be a silent no-op.
    prompt = json.load(sys.stdin).get("prompt") or ""
    matched = isinstance(prompt, str) and PATTERN.match(prompt) is not None
except Exception:
    sys.exit(0)

if matched:
    print(
        "The user typed the `merge?` shorthand. Run the `git-agent:merge` skill: "
        "check the current branch's PR for merge readiness and merge it only when "
        "green and explicitly approved; otherwise report status and ask."
    )
sys.exit(0)
