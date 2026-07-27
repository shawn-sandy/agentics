#!/usr/bin/env python3
"""
PostToolUse: report when a prototype has drifted from its own data model.

A prototype carries two machine-readable claims about its shape:

  1. `<script type="application/json" id="proto-model">` — the model
     /plan-agent:prototype derived in its Step 3.
  2. The rendered DOM — `<th data-field>` headers and form field name/id
     attributes, which is what a human actually edits.

And the plan named in its `<meta name="proto-source">` carries a third: a
`proto-model:` line in its Markdown frontmatter, written back by the same skill.

This hook compares (A) the model against the prototype's own DOM and (B) the
model against the plan's copy, and prints a warning naming both files and the
diverging field when they disagree.

Deliberately narrow:
- Structure only. Copy, styling, and seed-value edits are not drift.
- One direction only — prototype HTML against plan frontmatter. A hand-edited
  plan desyncs with no signal; plans are user-owned prose, not generated output.
- Silent whenever there is nothing to compare: no model block, no plan, no
  `proto-model:` line, unparseable JSON, or a `proto-source` that resolves
  outside the plans directory.
- ALWAYS exits 0. Every other hook in this plugin does, and a drift report
  about some other plan must never interrupt whatever the user is doing.
"""

import json
import os
import re
import sys

_FALLBACK_PLANS_DIR = "docs/plans"
_PROTOTYPES_MARKER = "docs/prototypes/"


def _project_dir():
    return os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()


def _load_settings(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, json.JSONDecodeError, ValueError):
        return {}


def _plans_dir():
    """Resolve plansDirectory the way render-plan-html.py does: local → project → global."""
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


def _get_meta(content, name):
    m = re.search(r'<meta\s+name="' + re.escape(name) + r'"\s+content="([^"]*)"', content)
    return m.group(1).strip() if m else ""


def _get_json_block(content, block_id):
    """Parse an inline `<script type="application/json" id="...">` block."""
    m = re.search(
        r'<script[^>]*\bid="' + re.escape(block_id) + r'"[^>]*>(.*?)</script>',
        content,
        re.DOTALL,
    )
    if not m:
        return None
    try:
        return json.loads(m.group(1).strip())
    except (json.JSONDecodeError, ValueError):
        return None


def _model_fields(model):
    """Field names from a proto-model blob, or None when it is not one."""
    if not isinstance(model, dict):
        return None
    fields = model.get("fields")
    if not isinstance(fields, list):
        return None
    names = []
    for f in fields:
        if isinstance(f, dict) and isinstance(f.get("name"), str):
            names.append(f["name"])
        elif isinstance(f, str):
            names.append(f)
    return names


def _dom_fields(content):
    """
    Field keys the prototype actually renders: <th data-field> plus form name/id.

    Comments are stripped first. The skeleton's own authoring comment carries a
    literal `data-field="key"` example and survives into every generated
    prototype, so scanning raw text reports a phantom `key` field on a file
    that has not drifted at all.
    """
    content = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL)
    names = list(re.findall(r'<th[^>]*\bdata-field="([^"]+)"', content))
    seen = set(names)
    for m in re.finditer(r"<(?:input|select|textarea)\b[^>]*>", content):
        tag = m.group(0)
        attr = re.search(r'\bname="([^"]+)"', tag) or re.search(r'\bid="([^"]+)"', tag)
        if attr and attr.group(1) not in seen:
            seen.add(attr.group(1))
            names.append(attr.group(1))
    return names


def _plan_proto_model(plan_path):
    """
    Read `proto-model:` out of a Markdown plan's frontmatter with a single-line
    regex — the same shape as validate-plan-filename.py's _is_completed, and
    deliberately not a general YAML parser: a second Python frontmatter reader
    would silently diverge from the JS one in plan-spec.mjs over time.
    """
    try:
        with open(plan_path, encoding="utf-8") as fh:
            content = fh.read()
    except OSError:
        return None
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^proto-model:\s*(.*)$", line)
        if m:
            try:
                return json.loads(m.group(1).strip())
            except (json.JSONDecodeError, ValueError):
                return None
    return None


def _first_difference(left, right):
    """Name one diverging field, preferring an addition/removal over reordering."""
    missing = [n for n in left if n not in right]
    extra = [n for n in right if n not in left]
    if missing:
        return missing[0]
    if extra:
        return extra[0]
    return None


def check(proto_path):
    """Emit drift warnings for one prototype file. Returns the warning list."""
    warnings = []
    try:
        with open(proto_path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return warnings

    model_fields = _model_fields(_get_json_block(content, "proto-model"))
    if model_fields is None:
        return warnings  # no durable model — nothing to compare

    rel_proto = os.path.relpath(proto_path, _project_dir())

    # (A) model vs. the prototype's own rendered columns / form fields.
    dom = _dom_fields(content)
    if dom:
        diff = _first_difference(model_fields, dom)
        if diff is not None:
            warnings.append(
                f"[plan-agent] prototype drift: {rel_proto} — field '{diff}' differs between "
                f"its #proto-model block and its own table headers / form fields. "
                f"Re-run /plan-agent:prototype to regenerate it from the plan."
            )

    # (B) model vs. the source plan's copy.
    source = _get_meta(content, "proto-source")
    if not source or not source.endswith(".md"):
        return warnings
    plans_dir = _plans_dir()
    plan_path = os.path.abspath(os.path.join(_project_dir(), source))
    if not (plan_path + os.sep).startswith(plans_dir + os.sep):
        return warnings  # out-of-tree proto-source — refuse to read it
    if not os.path.isfile(plan_path):
        return warnings

    plan_fields = _model_fields(_plan_proto_model(plan_path))
    if plan_fields is None:
        return warnings  # plan carries no usable proto-model yet

    diff = _first_difference(model_fields, plan_fields)
    if diff is not None:
        warnings.append(
            f"[plan-agent] prototype drift: {rel_proto} — field '{diff}' differs from the "
            f"proto-model in {source}. Re-run /plan-agent:prototype {source} to regenerate "
            f"the prototype from the plan."
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
    if _PROTOTYPES_MARKER not in abs_path or not abs_path.endswith(".html"):
        sys.exit(0)
    if os.path.basename(abs_path) == "index.html":
        sys.exit(0)

    try:
        for warning in check(os.path.abspath(path)):
            sys.stderr.write(warning + "\n")
    except Exception:  # noqa: BLE001 — a drift report must never block a write
        pass
    sys.exit(0)


if __name__ == "__main__":
    main()
