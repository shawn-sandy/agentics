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

# Frontmatter sits at the top of the file; anything past this is not it.
_FRONTMATTER_READ_BYTES = 64 * 1024


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
    The two independent field lists the prototype actually renders: the table's
    `<th data-field>` keys, and the form's control names.

    Kept SEPARATE on purpose. Merging them into one deduplicated list hides the
    exact edit this hook exists to catch: rename only the form control and the
    untouched `<th>` still supplies every model field, so the union matches and
    nothing is reported.

    Comments are stripped first. The skeleton's own authoring comment carries a
    literal `data-field="key"` example and survives into every generated
    prototype, so scanning raw text reports a phantom `key` field on a file
    that has not drifted at all.

    Form controls are read from inside `<form>` only, so an unrelated control
    elsewhere on the page is not mistaken for a model field.

    A surface that does not exist maps to None; one that exists but binds no
    fields maps to []. The two are NOT the same: a table whose every
    `data-field` was stripped is drift, while a prototype that simply has no
    table is not, and collapsing both to "falsy" silently accepts the first.
    """
    content = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL)

    table_present = re.search(r"<th\b", content) is not None
    table = list(re.findall(r'<th[^>]*\bdata-field="([^"]+)"', content))

    form_present = re.search(r"<form\b", content) is not None
    form = []
    seen = set()
    for form_m in re.finditer(r"<form\b[^>]*>(.*?)</form>", content, re.DOTALL):
        for m in re.finditer(r"<(?:input|select|textarea)\b[^>]*>", form_m.group(1)):
            tag = m.group(0)
            attr = re.search(r'\bname="([^"]+)"', tag) or re.search(r'\bid="([^"]+)"', tag)
            if attr and attr.group(1) not in seen:
                seen.add(attr.group(1))
                form.append(attr.group(1))

    return {
        "table headers": table if table_present else None,
        "form fields": form if form_present else None,
    }


def _plan_proto_model(plan_path):
    """
    Read `proto-model:` out of a Markdown plan's frontmatter with a single-line
    regex — the same shape as validate-plan-filename.py's _is_completed, and
    deliberately not a general YAML parser: a second Python frontmatter reader
    would silently diverge from the JS one in plan-spec.mjs over time.
    """
    # Bounded read: frontmatter is by definition the top of the file, and this
    # hook shares one 55s dispatch budget with the gallery rebuild — slurping an
    # arbitrarily large file would spend a budget the whole fan-out depends on.
    try:
        with open(plan_path, encoding="utf-8", errors="replace") as fh:
            content = fh.read(_FRONTMATTER_READ_BYTES)
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
    """
    Name one diverging field, preferring an addition/removal over a reorder.

    Order counts as drift: the field order in the model drives the prototype's
    column order, and the skill requires the two to match exactly. A pure
    reorder passes both membership checks, so it needs its own comparison —
    without it, swapping two columns is silently accepted.
    """
    missing = [n for n in left if n not in right]
    extra = [n for n in right if n not in left]
    if missing:
        return missing[0], "missing"
    if extra:
        return extra[0], "unexpected"
    for l, r in zip(left, right):
        if l != r:
            return l, "reordered"
    return None, None


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

    # (A) model vs. the prototype's own rendered columns and form fields —
    # each compared on its own, so an edit to only one of them still reports.
    # One warning either way: a field renamed in both is one mistake, not two.
    parts = []
    for label, rendered in _dom_fields(content).items():
        if rendered is None:
            continue  # surface absent — nothing to compare, not drift
        field, kind = _first_difference(model_fields, rendered)
        if field is not None:
            parts.append(f"{field!r} is {kind} in its {label}")
    if parts:
        warnings.append(
            f"[plan-agent] prototype drift: {rel_proto} — {'; '.join(parts)}, "
            f"compared with its #proto-model block. "
            f"Re-run /plan-agent:prototype to regenerate it from the plan."
        )

    # (B) model vs. the source plan's copy.
    source = _get_meta(content, "proto-source")
    if not source or not source.endswith(".md"):
        return warnings
    # realpath, not abspath: abspath is pure string arithmetic, so a symlink
    # sitting inside the plans directory and pointing anywhere on disk passed
    # the guard and was then read by open(), which follows links. Resolve both
    # sides so the boundary check tests the file actually opened.
    plans_dir = os.path.realpath(_plans_dir())
    plan_path = os.path.realpath(os.path.join(_project_dir(), source))
    if not (plan_path + os.sep).startswith(plans_dir + os.sep):
        return warnings  # out-of-tree proto-source — refuse to read it
    if not os.path.isfile(plan_path):
        return warnings

    plan_fields = _model_fields(_plan_proto_model(plan_path))
    if plan_fields is None:
        return warnings  # plan carries no usable proto-model yet

    field, kind = _first_difference(model_fields, plan_fields)
    if field is not None:
        # Point at the .html, not the .md we just read: the skill treats a
        # first token ending in .html as a plan path and ANY other string as a
        # raw idea, so naming the spec here would generate a prototype from the
        # path itself.
        plan_arg = source[: -len(".md")] + ".html"
        warnings.append(
            f"[plan-agent] prototype drift: {rel_proto} — {field!r} is {kind} relative to the "
            f"proto-model in {source}. Re-run /plan-agent:prototype {plan_arg} to regenerate "
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
    except Exception as exc:  # noqa: BLE001 — a drift report must never block a write
        # Stay fail-open, but say so. A hook that exists to catch silent
        # divergence should not itself fail silently: without this line a
        # regression in check() disables drift detection permanently with no
        # signal that it ever stopped working.
        sys.stderr.write(f"[plan-agent] drift check skipped: {type(exc).__name__}: {exc}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
