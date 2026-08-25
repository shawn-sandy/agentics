#!/usr/bin/env python3
"""
PostToolUse hook: re-render a plan's sibling HTML after its Markdown spec is
written.

Invoked by hooks/dispatch.py (registered on Write/Edit/MultiEdit), which only
calls this script for paths under the plans directory. Triggers only when the
written file is a Markdown plan spec (first heading is "# Plan:") inside the
configured plans directory AND <stem>.html already exists beside it. That
existence check is the file-published signal: a plan delivered as a claude.ai
artifact has no sibling, and rendering one would resurrect the file its author
chose not to publish. Such a write still rebuilds the gallery index, since the
card reads its title, status and step markers from the spec. Otherwise renders
<stem>.html next to the spec via build-plan-html.mjs —
preferring the copy bundled with this plugin ($CLAUDE_PLUGIN_ROOT/scripts/),
falling back to the consumer project's scripts/build-plan-html.mjs; when
neither exists the hook silently skips. After a successful render it rebuilds
the plans gallery index (best-effort): the index hook that fired on the .md
write skipped it as non-HTML, and the sibling .html written here is a
subprocess write, not a tool event, so no other hook run would catch it.

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
    # Skip a leading YAML frontmatter block first — a frontmatter comment
    # such as "# schema: v2" must not be mistaken for the title heading.
    lines = head.splitlines()
    in_frontmatter = lines[:1] == ["---"]
    for line in lines[1:] if in_frontmatter else lines:
        if in_frontmatter:
            if line.strip() == "---":
                in_frontmatter = False
            continue
        if line.startswith("# "):
            return line.startswith("# Plan:")
    return False


def _find_renderer(project):
    """Bundled renderer first (normal plugin installs), project copy second."""
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    candidates = []
    if plugin_root:
        candidates.append(os.path.join(plugin_root, "scripts", "build-plan-html.mjs"))
    candidates.append(os.path.join(project, "scripts", "build-plan-html.mjs"))
    for candidate in candidates:
        if os.path.isfile(candidate):
            return candidate
    return None


def _rebuild_index(project, plans_dir):
    """Best-effort gallery index rebuild — same resolution as
    rebuild-plans-index.py, which cannot see the sibling .html this hook just
    wrote (a subprocess write is not a PostToolUse event)."""
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    bundled = os.path.join(plugin_root, "hooks", "build-index.sh") if plugin_root else ""
    plans_script = os.path.join(plans_dir, "build-index.sh")
    if bundled and os.path.isfile(bundled):
        cmd = ["bash", bundled, project]
    elif os.path.isfile(plans_script):
        cmd = ["bash", plans_script]
    else:
        return
    try:
        subprocess.run(cmd, cwd=project, capture_output=True, timeout=25)
    except Exception:  # noqa: BLE001 — index staleness must never fail the render
        pass


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

    spec = os.path.abspath(path)
    sibling = os.path.splitext(spec)[0] + ".html"

    # A sibling's existence IS the file-published signal. A plan delivered as a
    # claude.ai artifact deliberately has none, so rendering one here would
    # resurrect the very file its author chose not to publish — and would do it
    # again on every later spec edit. The index rebuild still runs: an
    # artifact-mode edit changes title, status and step markers, all of which
    # the gallery card reads straight out of the spec.
    if not os.path.isfile(sibling):
        _rebuild_index(project, plans_dir)
        sys.exit(0)

    renderer = _find_renderer(project)
    if renderer is None:
        sys.exit(0)

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

    _rebuild_index(project, plans_dir)
    sys.exit(0)


if __name__ == "__main__":
    main()
