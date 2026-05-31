#!/usr/bin/env python3
"""
PostToolUse hook: auto-rebuild docs/plans/index.html after any plan HTML write.

Fires on every Write/Edit/MultiEdit. Triggers only when the written file is a
.html file inside the configured plans directory that is NOT index.html.
Prefers hooks/build-index.sh bundled with the plugin (via $CLAUDE_PLUGIN_ROOT);
falls back to build-index.sh in the project's plans directory.
Always exits 0 — index-rebuild failures must never block plan writes.
"""

import hashlib
import json
import os
import stat
import subprocess
import sys
import time

_FALLBACK_PLANS_DIR = "docs/plans"
_DEBOUNCE_SECS = 2.0


def _stamp_path():
    """Per-user per-project stamp in ~/.cache — avoids /tmp symlink attacks."""
    base = os.environ.get("XDG_CACHE_HOME") or os.path.join(
        os.path.expanduser("~"), ".cache"
    )
    d = os.path.join(base, "claude-plan-agent")
    os.makedirs(d, mode=0o700, exist_ok=True)
    cwd_hash = hashlib.md5(os.getcwd().encode()).hexdigest()[:8]
    return os.path.join(d, f"rebuild-plans-index-{cwd_hash}.stamp")


def _debounced(stamp):
    """Return True if a rebuild completed within _DEBOUNCE_SECS seconds."""
    try:
        st = os.lstat(stamp)
        if not stat.S_ISREG(st.st_mode):
            return False
        return (time.time() - st.st_mtime) < _DEBOUNCE_SECS
    except OSError:
        return False


def _touch(stamp):
    try:
        fd = os.open(stamp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        os.close(fd)
    except OSError:
        pass


def _unlink(stamp):
    try:
        os.unlink(stamp)
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
    return abs_path.startswith(abs_plans.rstrip("/") + "/")


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

    if not path:
        sys.exit(0)

    # cheap check before any I/O — skips settings reads for non-HTML writes
    if not path.endswith(".html") or os.path.basename(path) == "index.html":
        sys.exit(0)

    plans_dir = _get_plans_dir()
    if not _is_plan_html(path, plans_dir):
        sys.exit(0)

    # Prefer bundled script shipped with the plugin; fall back to one in the
    # consumer's plans dir (present in projects that adopted the earlier layout).
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    bundled = os.path.join(plugin_root, "hooks", "build-index.sh") if plugin_root else ""
    plans_script = os.path.join(os.getcwd(), plans_dir, "build-index.sh")

    if bundled and os.path.isfile(bundled):
        build_cmd = ["bash", bundled, os.getcwd()]
    elif os.path.isfile(plans_script):
        build_cmd = ["bash", plans_script]
    else:
        sys.exit(0)

    stamp = _stamp_path()
    if _debounced(stamp):
        sys.exit(0)
    _touch(stamp)  # written early to prevent concurrent runs

    success = False
    for delay in (0, 1, 2, 4):
        if delay:
            time.sleep(delay)
        try:
            result = subprocess.run(
                build_cmd,
                timeout=25,
                capture_output=True,
            )
            if result.returncode == 0:
                success = True
                break
        except Exception:
            pass

    if not success:
        _unlink(stamp)  # allow immediate retry after a failed rebuild

    sys.exit(0)


if __name__ == "__main__":
    main()
