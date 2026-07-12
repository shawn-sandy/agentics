#!/usr/bin/env python3
"""
PostToolUse hook: re-render a plan's sibling HTML after its Markdown spec is
written.

Fires on every Write/Edit/MultiEdit. Triggers only when the written file is a
Markdown plan spec (first heading is "# Plan:") inside the configured plans
directory. Renders <stem>.html next to the spec via the project's
scripts/build-plan-html.mjs; projects without that renderer are silently
skipped.

Unlike rebuild-plans-index.py this hook is best-effort but NOT silent: a
renderer failure exits non-zero with the error on stderr, so a stale
spec/HTML pair is surfaced instead of hidden (PostToolUse is non-blocking
either way; the round-trip test suite is the parity backstop).

plansDirectory resolution follows the implementation-plan skill's full
precedence — project .claude/settings.local.json, then project
.claude/settings.json, then global ~/.claude/settings.json — falling back to
docs/plans/. (The older index hooks skip the settings.local.json layer; this
hook follows the skill.)
"""

import json
import os
import subprocess
import sys

_FALLBACK_PLANS_DIR = "docs/plans"


def _project_dir():
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def _load_settings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _get_plans_dir(project):
    candidates = (
        os.path.join(project, ".claude", "settings.local.json"),
        os.path.join(project, ".claude", "settings.json"),
        os.path.join(os.path.expanduser("~"), ".claude", "settings.json"),
    )
    for settings_path in candidates:
        val = (_load_settings(settings_path).get("plansDirectory") or "").strip()
        if val:
            if os.path.isabs(val):
                return val.rstrip("/")
            if val.startswith("./"):
                val = val[2:]
            return os.path.join(project, val.rstrip("/") or _FALLBACK_PLANS_DIR)
    return os.path.join(project, _FALLBACK_PLANS_DIR)


def _is_plan_spec(path, plans_dir):
    """True if path is a "# Plan:" markdown file inside plans_dir."""
    if not path.endswith(".md"):
        return False
    abs_path = os.path.abspath(path)
    if not abs_path.startswith(os.path.abspath(plans_dir).rstrip("/") + "/"):
        return False
    try:
        with open(abs_path, encoding="utf-8") as fh:
            head = fh.read(4096)
    except OSError:
        return False
    for line in head.splitlines():
        if line.startswith("# "):
            return line.startswith("# Plan:")
    return False


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)
    if not isinstance(data, dict):
        sys.exit(0)

    tool_input = data.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        sys.exit(0)
    path = tool_input.get("file_path", "")
    if not path or not path.endswith(".md"):
        sys.exit(0)

    project = _project_dir()
    plans_dir = _get_plans_dir(project)
    if not _is_plan_spec(path, plans_dir):
        sys.exit(0)

    renderer = os.path.join(project, "scripts", "build-plan-html.mjs")
    if not os.path.isfile(renderer):
        sys.exit(0)

    spec = os.path.abspath(path)
    sibling = os.path.splitext(spec)[0] + ".html"
    try:
        result = subprocess.run(
            ["node", renderer, spec, "-o", sibling],
            cwd=project,
            capture_output=True,
            text=True,
            timeout=25,
        )
    except Exception as err:  # noqa: BLE001 — any spawn failure is a render failure
        print(f"render-plan-html: failed to run renderer: {err}", file=sys.stderr)
        sys.exit(2)

    if result.returncode != 0:
        sys.stderr.write(result.stderr or f"render-plan-html: renderer exited {result.returncode}\n")
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
