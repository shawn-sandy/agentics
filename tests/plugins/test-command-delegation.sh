#!/usr/bin/env bash
# Asserts that commands delegate to their skills rather than restating them,
# and that every slash reference in the marketplace resolves to something real.
#
# Check 1 — delegation. deep-grill, plan-status, and documenting-plans each
# duplicated their same-named skill's entire workflow. The copies had already
# drifted 20, 153, and 383 lines apart, so the same name produced different
# behaviour depending on whether the user typed the command or triggered the
# skill. A thin delegator has one behaviour by construction. (These commands
# now live under plan-agent after plan-interview was merged into it in 4.0.0.)
#
# Check 2 — reference resolution. An instruction naming a slash command that
# does not exist is a dead end at the exact moment a workflow hands off.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_DIR="$ROOT/kit/plugins"
[ -d "$PLUGIN_DIR" ] || { echo "FAIL: kit/plugins missing at $PLUGIN_DIR" >&2; exit 1; }

echo "=== Command Delegation Test ==="

python3 - "$PLUGIN_DIR" <<'PY'
import os, re, sys

plugin_dir = sys.argv[1]
repo_root = os.path.dirname(os.path.dirname(plugin_dir.rstrip("/")))
failures = []

# --- Check 1: the collapsed delegators ------------------------------------
#
# Each entry maps a command file to the skill it must delegate to. Listed
# explicitly rather than globbed: markdown-to-html is a real multi-step command
# and plan-to-html is a deprecation shim that forwards to a DIFFERENTLY-named
# skill with an injected flag, so neither fits this shape. Add a command here
# when it is collapsed to a delegator.
MAX_LINES = 15
DELEGATORS = {
    "plan-agent/commands/deep-grill.md": "plan-agent:deep-grill",
    "plan-agent/commands/plan-status.md": "plan-agent:plan-status",
    "plan-agent/commands/documenting-plans.md": "plan-agent:documenting-plans",
}

for rel, skill in DELEGATORS.items():
    path = os.path.join(plugin_dir, rel)
    if not os.path.isfile(path):
        failures.append(f"{rel}: missing")
        continue
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    lines = text.count("\n") + (0 if text.endswith("\n") else 1)

    if lines > MAX_LINES:
        failures.append(
            f"{rel}: {lines} lines (max {MAX_LINES}) — a delegator restating its "
            f"skill's workflow will drift from it"
        )

    calls = re.findall(r"Skill\(\s*skill:\s*[\"']([^\"']+)[\"']", text)
    if len(calls) != 1:
        failures.append(f"{rel}: found {len(calls)} `Skill(` call(s), expected exactly 1")
    elif calls[0] != skill:
        failures.append(f"{rel}: delegates to `{calls[0]}`, expected `{skill}`")

    # Frontmatter fields the collapse had to preserve.
    for key in ("description", "argument-hint"):
        if not re.search(rf"^{key}:\s*\S", text, re.M):
            failures.append(f"{rel}: lost its `{key}:` frontmatter in the collapse")

# --- Check 2: every slash reference resolves ------------------------------
#
# A `/plugin:name` reference resolves against BOTH commands/<name>.md and
# skills/<name>/SKILL.md, because plugin skills are slash-invocable by name —
# they are not commands-only. Resolving against commands/ alone would flag 27
# in-tree references to `/plan-agent:implementation-plan` (skill-only, and the
# documented way to invoke it) as broken.
#
# CHANGELOG.md is excluded: it is a historical record, so it necessarily names
# commands that were later renamed or removed. Rewriting history to satisfy a
# test would defeat the point of keeping one.
SKIP_FILES = {"CHANGELOG.md"}
REF = re.compile(r"/([a-z0-9][a-z0-9-]*):([a-z0-9][a-z0-9-]*)")

plugins = {
    d for d in os.listdir(plugin_dir)
    if os.path.isdir(os.path.join(plugin_dir, d))
}

def targets(plugin):
    """Every name `/plugin:<name>` can legally resolve to."""
    names = set()
    cdir = os.path.join(plugin_dir, plugin, "commands")
    if os.path.isdir(cdir):
        names |= {f[:-3] for f in os.listdir(cdir) if f.endswith(".md")}
    sdir = os.path.join(plugin_dir, plugin, "skills")
    if os.path.isdir(sdir):
        names |= {
            s for s in os.listdir(sdir)
            if os.path.isfile(os.path.join(sdir, s, "SKILL.md"))
        }
    return names

resolvable = {p: targets(p) for p in plugins}
checked = 0

for dirpath, _, filenames in os.walk(plugin_dir):
    for fname in filenames:
        if not fname.endswith(".md") or fname in SKIP_FILES:
            continue
        path = os.path.join(dirpath, fname)
        rel = os.path.relpath(path, repo_root)
        with open(path, encoding="utf-8", errors="ignore") as fh:
            for lineno, line in enumerate(fh, 1):
                for m in REF.finditer(line):
                    plugin, name = m.group(1), m.group(2)
                    # Only judge references to plugins that exist here. Anything
                    # else is prose, a URL fragment, or a placeholder.
                    if plugin not in plugins:
                        continue
                    checked += 1
                    if name not in resolvable[plugin]:
                        failures.append(
                            f"{rel}:{lineno}: `/{plugin}:{name}` resolves to no "
                            f"file under {plugin}/commands/ or {plugin}/skills/"
                        )

if failures:
    print(f"FAIL: {len(failures)} problem(s):")
    for f in failures:
        print(f"  - {f}")
    sys.exit(1)

print(f"PASS: {len(DELEGATORS)} commands delegate via a single Skill() call "
      f"(<={MAX_LINES} lines each); {checked} slash references all resolve")
PY
