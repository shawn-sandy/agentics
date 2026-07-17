#!/usr/bin/env python3
"""
PostToolUse hook: enforce plan-agent `/plan-agent:implementation-plan` (Step 4) verb-target kebab-case filenames.

Invoked by hooks/dispatch.py, which is registered on Write/Edit/MultiEdit and
only calls this script for paths under the plans directory. (MultiEdit used to
bypass this gate: this script was registered directly on `Write|Edit` only.)
Still safe to run standalone — it re-applies its own filter below.

Ignores anything outside the configured plans
directory (reads `plansDirectory` from the project's .claude/settings.json
first, then falls back to ~/.claude/settings.json, then to `docs/plans`) and
plans whose frontmatter carries `status: completed`.
On a violation: writes a rename message to stderr and exits 2 so Claude
receives it as actionable feedback (PostToolUse exit-2 contract).
On a pass: exits 0 silently.

Project-level customisation (planAgent key in .claude/settings.json or
~/.claude/settings.json, first-match-wins):
  planAgent.additionalVerbs        list[str]  — merged with IMPERATIVE_VERBS
  planAgent.additionalStopWords    list[str]  — merged with STOP_WORDS_2ND
  planAgent.additionalPlaceholders list[str]  — merged with GENERIC_NAMES
"""

import json
import os
import re
import sys

_FALLBACK_PLANS_DIR = "docs/plans"

IMPERATIVE_VERBS = {
    "add", "fix", "update", "refactor", "create", "remove", "delete",
    "implement", "migrate", "rename", "move", "document", "enforce",
    "validate", "build", "setup", "set", "configure", "wire", "port",
    "extract", "split", "merge", "replace", "introduce", "support",
    "enable", "disable", "improve", "optimize", "harden", "scaffold",
    "generate", "convert",
    # common imperative verbs not in original seed
    "install", "switch", "require", "extend", "restrict", "register",
    "deprecate", "deploy", "release", "test", "run", "sync", "patch",
    "upgrade", "downgrade", "wrap", "expose", "load", "bootstrap",
}

GENERIC_NAMES = {"plan", "untitled", "draft", "temp", "notes", "todo", "new-plan"}

# Second-token stop-words signal prompt-echo phrasing (e.g. "update-the-...")
STOP_WORDS_2ND = {"the", "a", "an", "this", "that", "my", "some", "please", "to", "of", "for", "want"}

_KEBAB_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
_HEX_AGENT_RE = re.compile(r"-agent-[0-9a-f]{6,}$")
_HEX_SUFFIX_RE = re.compile(r"-[0-9a-f]{6,}$")
_DATE_SUFFIX_RE = re.compile(r"-\d{4}-\d{2}-\d{2}$")


def classify_filename(stem, verbs=None, stop_words=None, placeholders=None):
    """
    Return (ok: bool, reason: str).
    ok=True  → filename is valid verb-target kebab-case.
    ok=False → reason describes the first failing check.

    verbs, stop_words, placeholders default to the module-level constants,
    allowing callers to inject extended sets without mutating global state.
    """
    if verbs is None:
        verbs = IMPERATIVE_VERBS
    if stop_words is None:
        stop_words = STOP_WORDS_2ND
    if placeholders is None:
        placeholders = GENERIC_NAMES

    if not _KEBAB_RE.fullmatch(stem):
        return False, "not strict kebab-case (only lowercase letters, digits, hyphens allowed)"
    if _HEX_AGENT_RE.search(stem) or _HEX_SUFFIX_RE.search(stem):
        return False, "contains a harness-generated hex suffix — strip it"
    if _DATE_SUFFIX_RE.search(stem):
        return False, "trailing date belongs in frontmatter `created:`, not the filename"
    if stem in placeholders:
        return False, f"'{stem}' is a generic placeholder name"
    tokens = stem.split("-")
    if tokens[0] not in verbs:
        return False, (
            f"first word '{tokens[0]}' is not an imperative verb "
            f"— start with e.g. add-, fix-, refactor-"
        )
    if len(tokens) >= 2 and tokens[1] in stop_words:
        return False, (
            f"second word '{tokens[1]}' is a stop-word "
            f"— looks like a prompt-echo (e.g. 'update-the-...' → 'update-plan-mode')"
        )
    return True, ""


def _load_settings(path):
    """Load and return settings dict from a JSON file, or {} on any error."""
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _get_plan_agent_settings():
    """
    Return the planAgent config dict from .claude/settings.json (project first,
    then global ~/.claude/settings.json). First-match-wins — does not merge both
    files. Returns {} if neither file exists or neither has a planAgent key.
    """
    project_settings_path = os.path.join(os.getcwd(), ".claude", "settings.json")
    global_settings_path = os.path.join(os.path.expanduser("~"), ".claude", "settings.json")
    for settings_path in (project_settings_path, global_settings_path):
        settings = _load_settings(settings_path)
        cfg = settings.get("planAgent")
        if isinstance(cfg, dict):
            return cfg
    return {}


def _get_plans_dir():
    """
    Resolve plansDirectory in priority order:
    1. Project .claude/settings.json (cwd-relative)
    2. ~/.claude/settings.json (global fallback)
    3. 'docs/plans' (hardcoded fallback)
    """
    project_settings_path = os.path.join(os.getcwd(), ".claude", "settings.json")
    global_settings_path = os.path.join(os.path.expanduser("~"), ".claude", "settings.json")

    for settings_path in (project_settings_path, global_settings_path):
        settings = _load_settings(settings_path)
        val = (settings.get("plansDirectory") or "").strip()
        if val:
            if os.path.isabs(val):
                return val.rstrip("/")
            # Relative path: strip leading ./ prefix (lstrip would strip chars, not the literal prefix)
            if val.startswith("./"):
                val = val[2:]
            return val.rstrip("/") or _FALLBACK_PLANS_DIR

    return _FALLBACK_PLANS_DIR


_PLAN_EXTENSIONS = (".html", ".md")


def _is_plan_path(path, plans_dir):
    """Return True if path is a plan file (.html or .md) inside plans_dir."""
    # Resolve both to absolute paths so the comparison is an exact prefix check,
    # not a substring scan that can match unrelated directories.
    abs_plans = plans_dir if os.path.isabs(plans_dir) else os.path.abspath(plans_dir)
    abs_path = os.path.abspath(path)
    # Normalize separators for cross-platform consistency.
    abs_plans = abs_plans.replace(os.sep, "/").rstrip("/")
    abs_path = abs_path.replace(os.sep, "/")
    return abs_path.startswith(abs_plans + "/")


def _is_completed(path):
    """Return True if the plan file marks status as completed (HTML meta or YAML frontmatter)."""
    try:
        with open(path, encoding="utf-8") as fh:
            content = fh.read()
    except OSError:
        return False
    if path.endswith(".html"):
        return bool(re.search(r'<meta\s+name=["\']plan-status["\']\s+content=["\']completed["\']', content, re.IGNORECASE))
    # YAML frontmatter for legacy .md plans
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if re.match(r"^\s*status:\s*completed\s*$", line):
            return True
    return False


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    path = (data.get("tool_input") or {}).get("file_path", "")
    if not path or not any(path.endswith(ext) for ext in _PLAN_EXTENSIONS):
        sys.exit(0)

    plans_dir = _get_plans_dir()
    if not _is_plan_path(path, plans_dir):
        sys.exit(0)

    if _is_completed(path):
        sys.exit(0)

    cfg = _get_plan_agent_settings()
    effective_verbs = IMPERATIVE_VERBS | set(v.lower() for v in cfg.get("additionalVerbs", []))
    effective_stop = STOP_WORDS_2ND | set(w.lower() for w in cfg.get("additionalStopWords", []))
    effective_ph = GENERIC_NAMES | set(n.lower() for n in cfg.get("additionalPlaceholders", []))

    ext = next(ext for ext in _PLAN_EXTENSIONS if path.endswith(ext))
    stem = os.path.basename(path)[: -len(ext)]
    ok, reason = classify_filename(stem, verbs=effective_verbs, stop_words=effective_stop, placeholders=effective_ph)
    if ok:
        sys.exit(0)

    msg = (
        f"\n[plan-filename] '{os.path.basename(path)}' violates plan-agent `/plan-agent:implementation-plan` (Step 4) "
        f"(verb-target kebab-case).\n"
        f"Reason: {reason}.\n"
        f"Rename to an imperative verb-target name before committing, "
        f"e.g. 'add-dark-mode-toggle.html', 'fix-login-redirect.html'.\n"
        f"Derive the name from the plan title and Objective section.\n"
    )
    sys.stderr.write(msg)
    sys.exit(2)


if __name__ == "__main__":
    main()
