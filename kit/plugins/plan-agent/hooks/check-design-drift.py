#!/usr/bin/env python3
"""
PostToolUse: report a plan step that no design artboard covers.

/plan-agent:design derives ONE artboard per user-facing plan step and writes
them under the directory the plan's `design-dir:` frontmatter key names. This
hook re-derives that mapping from the plan on every artboard write and reports
any user-facing step left with no artboard.

What drift means here, and what it deliberately does not
--------------------------------------------------------
Drift is ARTBOARD NAMES against the plan's user-facing steps. It is NOT a
comparison of the local artboards against the published canvas: people editing
the canvas in the GUI is the feature working, and a check that fires on that is
noise. So the reverse direction is silent too — an extra artboard nobody
planned is somebody designing, not a defect.

"User-facing" is load-bearing in two places — the skill's derivation rule and
this check — and they MUST agree. A step with no user-facing surface (a version
bump, a test file, a README edit) gets no artboard by design; if this check
applied a different filter, every housekeeping step would read as permanent
drift. The filter is the UI-signal keyword list already canonical in
skills/review-plan/SKILL.md Step 3b, reused rather than redefined.

Deliberately narrow:
- Filenames and headings only. No network, no parse of the published canvas.
  Every dispatch.py child shares one 55s deadline.
- Silent whenever there is nothing to compare: no plan claims the directory, the
  plan carries no `design-dir:`, the plan has no `## Steps` section, or the
  `design-dir:` resolves outside the designs tree.
- ALWAYS exits 0. Every other hook in this plugin does, and a drift report about
  some other plan must never interrupt whatever the user is doing.
"""

import json
import os
import re
import sys

_FALLBACK_PLANS_DIR = "docs/plans"
_DESIGNS_MARKER = "docs/designs/"
_ARTBOARD_SUFFIX = ".dc.html"

# Unlike check-prototype-drift.py, which reads ONE plan, this hook scans every
# plan in the directory looking for the one that claims this canvas. Frontmatter
# is by definition the top of the file, so cap the per-file read hard — a full
# slurp of a hundred plans would spend a budget the whole fan-out depends on.
_FRONTMATTER_READ_BYTES = 8 * 1024

# The canonical UI-signal list from skills/review-plan/SKILL.md Step 3b. Kept as
# one list with two match modes: the alphabetic signals match on a LEADING word
# boundary only, so "forms" and "buttons" count while "information" and
# "performance" do not; the dotted ones are file extensions and match anywhere.
_UI_WORD_SIGNALS = (
    "react", "vue", "svelte", "angular", "classname", "style", "tailwind",
    "button", "modal", "form", "dialog", "dropdown", "page", "component",
)
_UI_LITERAL_SIGNALS = (".tsx", ".jsx", ".css", ".html")
_UI_WORD_RE = re.compile(r"\b(?:%s)" % "|".join(_UI_WORD_SIGNALS), re.IGNORECASE)

# How many hyphen-separated words a step slug keeps. Six is enough to stay
# readable and distinct without turning a long step title into a long filename.
_SLUG_WORDS = 6


def _project_dir():
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def _load_settings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _plans_dir():
    """Resolve plansDirectory the way render-plan-html.py does: local -> project -> global."""
    root = _project_dir()
    for settings_path in (
        os.path.join(root, ".claude", "settings.local.json"),
        os.path.join(root, ".claude", "settings.json"),
        os.path.join(os.path.expanduser("~"), ".claude", "settings.json"),
    ):
        val = (_load_settings(settings_path).get("plansDirectory") or "").strip()
        if not val:
            continue
        if os.path.isabs(val):
            return os.path.abspath(val.rstrip("/"))
        if val.startswith("./"):
            val = val[2:]
        return os.path.abspath(os.path.join(root, val.rstrip("/") or _FALLBACK_PLANS_DIR))
    return os.path.abspath(os.path.join(root, _FALLBACK_PLANS_DIR))


def slug(action, words=_SLUG_WORDS):
    """
    The artboard slug for a step's action text.

    This function IS the naming contract: skills/design/SKILL.md Step 2 states
    the same rule in prose, and an artboard is named `<slug>.dc.html`. Changing
    it here without changing it there makes every existing canvas read as drift.
    """
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", action)  # [label](url) -> label
    text = text.replace("`", " ")
    text = re.sub(r"[^A-Za-z0-9]+", "-", text.lower())
    parts = [p for p in text.split("-") if p]
    return "-".join(parts[:words])


def is_user_facing(action):
    """Whether a step names a UI surface worth an artboard. See _UI_WORD_SIGNALS."""
    lowered = action.lower()
    if any(sig in lowered for sig in _UI_LITERAL_SIGNALS):
        return True
    return _UI_WORD_RE.search(action) is not None


def _frontmatter_value(path, key):
    """
    Read one frontmatter key with a single-line regex — the same shape
    validate-plan-filename.py uses, and deliberately not a general YAML parser:
    a second Python frontmatter reader would silently diverge from the JS one in
    plan-spec.mjs over time.
    """
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            content = fh.read(_FRONTMATTER_READ_BYTES)
    except OSError:
        return ""
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return ""
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^%s:\s*(.*)$" % re.escape(key), line)
        if m:
            return m.group(1).strip()
    return ""


def step_actions(plan_path):
    """
    Every step's ACTION text, in document order, or None when the plan has no
    `## Steps` section.

    The action is the prose before the step's `Why:` clause. `### Phase:`
    subheadings inside the section are passed over — they carry no step number.
    """
    try:
        with open(plan_path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return None
    m = re.search(r"^## Steps\s*$(.*?)(?=^## |\Z)", content, re.MULTILINE | re.DOTALL)
    if not m:
        return None

    body = m.group(1)
    actions = []
    starts = list(re.finditer(r"^(\d+)\.\s+", body, re.MULTILINE))
    for i, start in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(body)
        chunk = body[start.end():end]
        chunk = re.split(r"\bWhy:", chunk, maxsplit=1)[0]
        action = " ".join(chunk.split())
        if action:
            actions.append((start.group(1), action))
    return actions


def _owning_plan(canvas_dir):
    """
    The plan spec whose `design-dir:` names this canvas directory.

    Scanned rather than derived from the slug: `design:` and `design-dir:` are
    two independent keys precisely so the pair survives a plan rename, and a
    slug-derived lookup would not. Sorted so a directory two plans both claim
    resolves the same way every run.
    """
    plans_dir = _plans_dir()
    designs_root = os.path.realpath(os.path.join(_project_dir(), _DESIGNS_MARKER.rstrip("/")))
    try:
        names = sorted(n for n in os.listdir(plans_dir) if n.endswith(".md"))
    except OSError:
        return None
    for name in names:
        plan_path = os.path.join(plans_dir, name)
        raw = _frontmatter_value(plan_path, "design-dir")
        if not raw:
            continue
        # realpath, not abspath: abspath is pure string arithmetic, so a symlink
        # sitting inside the designs tree and pointing anywhere on disk would
        # pass a string check and then be listed. Resolve both sides so the
        # boundary test covers the directory actually read.
        resolved = os.path.realpath(os.path.join(_project_dir(), raw.rstrip("/")))
        if not (resolved + os.sep).startswith(designs_root + os.sep):
            continue  # out-of-tree design-dir — refuse to follow it
        if resolved == os.path.realpath(canvas_dir):
            return plan_path
    return None


def _display_path(path, project):
    """
    A repo-relative path when one exists, the absolute path when it does not.

    relpath is string arithmetic, so mixing a realpath-resolved path with an
    unresolved project root — the macOS `/tmp` -> `/private/tmp` case, and any
    project reached through a symlink — produces a `../../../..` chain that is
    technically correct and useless in a warning. Try both frames before giving
    up on a readable path.
    """
    for root in (project, os.path.realpath(project)):
        rel = os.path.relpath(path, root)
        if not rel.startswith(".."):
            return rel
    rel = os.path.relpath(os.path.realpath(path), os.path.realpath(project))
    return rel if not rel.startswith("..") else path


def check(canvas_dir):
    """Drift warnings for one canvas directory. Returns the warning list."""
    plan_path = _owning_plan(canvas_dir)
    if plan_path is None:
        return []  # no plan claims this canvas — nothing to compare

    actions = step_actions(plan_path)
    if not actions:
        return []  # no Steps section, or no steps in it

    try:
        artboards = {
            n[: -len(_ARTBOARD_SUFFIX)]
            for n in os.listdir(canvas_dir)
            if n.endswith(_ARTBOARD_SUFFIX)
        }
    except OSError:
        return []

    project = _project_dir()
    rel_plan = _display_path(plan_path, project)
    rel_dir = _display_path(canvas_dir, project)
    plan_arg = rel_plan[: -len(".md")] + ".html" if rel_plan.endswith(".md") else rel_plan

    warnings = []
    for number, action in actions:
        if not is_user_facing(action):
            continue  # housekeeping — no artboard by design, never drift
        if slug(action) in artboards:
            continue
        warnings.append(
            "[plan-agent] design drift: step %s of %s has no artboard in %s — "
            'expected %s%s for "%s". Re-run /plan-agent:design %s to cover it.'
            % (number, rel_plan, rel_dir, slug(action), _ARTBOARD_SUFFIX, action, plan_arg)
        )
    return warnings


def main():
    try:
        data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)
    if not isinstance(data, dict):
        sys.exit(0)
    tool_input = data.get("tool_input") or {}
    if not isinstance(tool_input, dict):
        sys.exit(0)
    path = tool_input.get("file_path", "")
    if not path or not isinstance(path, str):
        sys.exit(0)

    abs_path = os.path.abspath(path).replace(os.sep, "/")
    marker = abs_path.find(_DESIGNS_MARKER)
    if marker == -1:
        sys.exit(0)

    # docs/designs/<canvas>/... — the segment right after the marker is the
    # canvas directory. A write directly inside docs/designs/ (the generated
    # index.html) has no canvas segment and is skipped.
    tail = abs_path[marker + len(_DESIGNS_MARKER):]
    if "/" not in tail:
        sys.exit(0)
    # Kept UNRESOLVED: _owning_plan realpaths it for the comparison, while the
    # warning needs a path a person recognises.
    canvas_dir = abs_path[: marker + len(_DESIGNS_MARKER)] + tail.split("/")[0]

    try:
        for warning in check(canvas_dir):
            sys.stderr.write(warning + "\n")
    except Exception as exc:  # noqa: BLE001 — a drift report must never block a write
        # Stay fail-open, but say so. A hook that exists to catch silent
        # divergence should not itself fail silently.
        sys.stderr.write(f"[plan-agent] design drift check skipped: {type(exc).__name__}: {exc}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
