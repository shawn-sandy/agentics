#!/usr/bin/env python3
"""
PostToolUse dispatcher: the plugin's single entry point for Write/Edit/MultiEdit.

Why this exists
---------------
plan-agent ships seven PostToolUse hooks (filename validation, plans-index
rebuild, plan HTML render, prototypes-index rebuild, prototype drift, and the
designs-index rebuild and design drift pair). Registering each one
directly in hooks.json spawned seven interpreters on *every* file edit in
*every* session, purely so each could discover the file was not a plan and
exit. The hooks `matcher` field is a tool-NAME regex only — it cannot express
a path condition — so the gate cannot live in hooks.json. It lives here.

This script reads the hook payload once, does one cheap path check, and for
the overwhelmingly common case (an edit outside the plans, prototypes, and
designs trees)
exits without spawning anything. Only when the path is plausibly relevant does
it fan out to the child hooks, which re-apply their own precise filters.

The gate has three independent arms — plans, prototypes, designs — because a
write can be relevant to one without being relevant to the others, and each arm
fans out only to its own children.

Contract
--------
- The gate here is deliberately a SUPERSET of every child's own gate: it may
  let through a path a child then skips, but it must never drop a path a child
  would have acted on. Children remain independently runnable and testable.
- Child stderr is forwarded; if any child exits 2 (the PostToolUse "actionable
  feedback" contract, used by validate-plan-filename.py to block a badly-named
  plan) this dispatcher also exits 2.
- Any dispatcher-internal failure exits 0 — the gate must never block a write.
"""

import json
import os
import subprocess
import sys
import time

_FALLBACK_PLANS_DIR = "docs/plans"
_PROTOTYPES_MARKER = "docs/prototypes/"
_DESIGNS_MARKER = "docs/designs/"
_PLAN_EXTENSIONS = (".md", ".html")

# Children run sequentially, so their timeouts must fit inside the dispatcher's
# own hooks.json budget (60s) with headroom — otherwise the harness kills this
# process mid-fan-out and whichever child had not run yet is silently skipped.
# Previously each hook was registered separately and had an independent budget;
# collapsing them into one process means they now share one.
_TOTAL_BUDGET_SECONDS = 55.0
_MIN_CHILD_SECONDS = 5.0

_HOOKS_DIR = os.path.dirname(os.path.abspath(__file__))

# Order mirrors the previous hooks.json registration order. validate runs first
# so its rename message is the first thing on stderr.
_PLAN_CHILDREN = (
    ["python3", os.path.join(_HOOKS_DIR, "validate-plan-filename.py")],
    ["python3", os.path.join(_HOOKS_DIR, "rebuild-plans-index.py")],
    ["python3", os.path.join(_HOOKS_DIR, "render-plan-html.py")],
)


def _load_settings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _project_dir():
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def _plans_dir_candidates():
    """
    Every directory any child might consider "the plans directory".

    The children disagree slightly on precedence: validate/rebuild resolve
    against cwd and skip settings.local.json, while render honours
    settings.local.json and resolves against CLAUDE_PROJECT_DIR. Rather than
    pick a winner (and risk gating out a path some child would have handled),
    collect the union of every layer's value plus the docs/plans fallback under
    both roots.
    """
    roots = {os.getcwd(), _project_dir()}
    settings_paths = []
    for root in roots:
        settings_paths.append(os.path.join(root, ".claude", "settings.local.json"))
        settings_paths.append(os.path.join(root, ".claude", "settings.json"))
    settings_paths.append(os.path.join(os.path.expanduser("~"), ".claude", "settings.json"))

    candidates = set()
    for settings_path in settings_paths:
        val = (_load_settings(settings_path).get("plansDirectory") or "").strip()
        if not val:
            continue
        if os.path.isabs(val):
            candidates.add(val.rstrip("/"))
            continue
        if val.startswith("./"):
            val = val[2:]
        val = val.rstrip("/") or _FALLBACK_PLANS_DIR
        for root in roots:
            candidates.add(os.path.join(root, val))

    # Always include the hardcoded fallback — it is what the children use when
    # no settings file names a plansDirectory.
    for root in roots:
        candidates.add(os.path.join(root, _FALLBACK_PLANS_DIR))

    return {os.path.abspath(c).replace(os.sep, "/").rstrip("/") for c in candidates}


def _under_any(abs_path, directories):
    return any(abs_path.startswith(d + "/") for d in directories)


def _run(cmd, payload, deadline):
    """Run a child hook with the payload on stdin. Returns its exit code.

    `deadline` is a monotonic timestamp shared by every child in this dispatch,
    so a slow child spends its own budget rather than the next child's.
    """
    remaining = deadline - time.monotonic()
    if remaining < _MIN_CHILD_SECONDS:
        # Out of budget. Skipping beats being killed mid-run by the harness:
        # this way the remaining children still get their turn on the next write.
        sys.stderr.write(
            f"[plan-agent] skipped {os.path.basename(cmd[-1])}: dispatch budget exhausted\n"
        )
        return 0
    try:
        result = subprocess.run(
            cmd,
            input=payload,
            capture_output=True,
            text=True,
            timeout=remaining,
        )
    except Exception:  # noqa: BLE001 — a child that will not spawn must not block the write
        return 0
    if result.stderr:
        sys.stderr.write(result.stderr)
    return result.returncode


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
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

    # ── The gate ────────────────────────────────────────────────────────────
    abs_path = os.path.abspath(path).replace(os.sep, "/")

    # build-prototypes-index.sh gates on the path alone (`*/docs/prototypes/*`),
    # with no extension filter — so neither can this, or we would drop a write
    # it would have acted on and break the superset contract above.
    is_prototype = _PROTOTYPES_MARKER in abs_path

    # Same rule for designs, and for the same reason: build-designs-index.sh
    # gates on `*/docs/designs/*` alone. Artboards are `.dc.html`, but an
    # extension filter here would drop any other file the canvas directory
    # grows and break the superset contract.
    is_design = _DESIGNS_MARKER in abs_path

    # Only a .md or .html can be a plan. Test the extension first: it is free,
    # while _plans_dir_candidates() reads settings files off disk.
    is_plan = abs_path.endswith(_PLAN_EXTENSIONS) and _under_any(
        abs_path, _plans_dir_candidates()
    )

    if not (is_plan or is_prototype or is_design):
        sys.exit(0)  # the common case — no child process is ever spawned

    # ── Fan out ─────────────────────────────────────────────────────────────
    # One shared deadline across every child: they run sequentially inside a
    # single hooks.json timeout, so they cannot each assume a full budget.
    deadline = time.monotonic() + _TOTAL_BUDGET_SECONDS
    codes = []
    if is_plan:
        for cmd in _PLAN_CHILDREN:
            codes.append(_run(cmd, raw, deadline))
    if is_prototype:
        codes.append(
            _run(
                [
                    "bash",
                    os.path.join(_HOOKS_DIR, "build-prototypes-index.sh"),
                    _project_dir(),
                ],
                raw,
                deadline,
            )
        )
        # Goes last, and must stay cheap: every child shares one 55s budget,
        # and a child that runs out of it is skipped by the fail-open path —
        # which would silently stop drift from being detected at all.
        codes.append(
            _run(
                ["python3", os.path.join(_HOOKS_DIR, "check-prototype-drift.py")],
                raw,
                deadline,
            )
        )
    if is_design:
        codes.append(
            _run(
                [
                    "bash",
                    os.path.join(_HOOKS_DIR, "build-designs-index.sh"),
                    _project_dir(),
                ],
                raw,
                deadline,
            )
        )
        # Same placement and same reason as the prototype drift check above: it
        # goes last and must stay cheap, because every child shares one 55s
        # budget and a child that runs out of it is skipped by the fail-open
        # path — which would silently stop drift from being detected at all.
        codes.append(
            _run(
                ["python3", os.path.join(_HOOKS_DIR, "check-design-drift.py")],
                raw,
                deadline,
            )
        )

    # Propagate the blocking contract: any child asking for actionable feedback
    # makes the whole dispatch actionable.
    sys.exit(2 if 2 in codes else 0)


if __name__ == "__main__":
    main()
