#!/usr/bin/env python3
"""
PostToolUse hook: auto-rebuild docs/plans/index.html after any plan HTML write.

Fires on every Write/Edit. Triggers only when the written file is a .html file
inside the configured plans directory that is NOT index.html.
Calls docs/plans/build-index.sh (relative to the project root / cwd).
Always exits 0 — index-rebuild failures must never block plan writes.
"""

import hashlib
import json
import os
import subprocess
import sys
import time

_FALLBACK_PLANS_DIR = "docs/plans"
_DEBOUNCE_SECS = 2.0


def _stamp_path():
    """Per-project stamp file so concurrent sessions in different repos don't suppress each other."""
    cwd_hash = hashlib.md5(os.getcwd().encode()).hexdigest()[:8]
    return f"/tmp/rebuild-plans-index-{cwd_hash}.stamp"


def _debounced(stamp):
    """Return True if a rebuild completed within _DEBOUNCE_SECS seconds."""
    try:
        return (time.time() - os.path.getmtime(stamp)) < _DEBOUNCE_SECS
    except OSError:
        return False


def _touch(stamp):
    try:
        with open(stamp, "w") as fh:
            fh.write("")
    except OSError:
        pass


def _load_settings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _get_plans_dir():
    project_settings_path = os.path.join(os.getcwd(), ".claude", "settings.json")
    global_settings_path = os.path.join(os.path.expanduser("~"), ".claude", "settings.json")

    for settings_path in (project_settings_path, global_settings_path):
        settings = _load_settings(settings_path)
        val = (settings.get("plansDirectory") or "").strip()
        if val:
            if os.path.isabs(val):
                return val.rstrip("/")
            if val.startswith("./"):
                val = val[2:]
            return val.rstrip("/") or _FALLBACK_PLANS_DIR

    return _FALLBACK_PLANS_DIR


def _is_plan_html(path, plans_dir):
    """Return True if path is a non-index .html file inside plans_dir."""
    if not path.endswith(".html"):
        return False
    if os.path.basename(path) == "index.html":
        return False
    abs_plans = plans_dir if os.path.isabs(plans_dir) else os.path.abspath(plans_dir)
    abs_path = os.path.abspath(path)
    abs_plans = abs_plans.replace(os.sep, "/").rstrip("/")
    abs_path = abs_path.replace(os.sep, "/")
    return abs_path.startswith(abs_plans + "/")


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    path = (data.get("tool_input") or {}).get("file_path", "")
    if not path:
        sys.exit(0)

    plans_dir = _get_plans_dir()
    if not _is_plan_html(path, plans_dir):
        sys.exit(0)

    build_script = os.path.join(os.getcwd(), plans_dir, "build-index.sh")
    if not os.path.isfile(build_script):
        sys.exit(0)

    stamp = _stamp_path()
    if _debounced(stamp):
        sys.exit(0)
    _touch(stamp)

    try:
        subprocess.run(
            ["bash", build_script],
            cwd=os.getcwd(),
            timeout=25,
            capture_output=True,
        )
    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
