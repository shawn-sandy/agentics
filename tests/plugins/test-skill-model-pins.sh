#!/usr/bin/env bash
# Regression test: plugin skills must not pin a model.
#
# Invariant: no kit/plugins/*/skills/*/SKILL.md declares `model:` in its
# frontmatter, and every kit/plugins/git-agent/agents/*.md still does.
#
# Why this matters: a skill runs inside the calling conversation, so a pinned
# model moves that whole conversation to another model for the turn. A prompt
# cache belongs to one model, so the switch saves the entire conversation again,
# and switching back can do it a second time. The pins were added to save money;
# on a long conversation they cost more than they saved. An agent runs in its own
# small context, so its pin causes no rewrite. That is why agents keep theirs.
#
# A pin also does not unwind when the skill ends, so one pinned skill in a chain
# sets the model for every skill after it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS="$ROOT/kit/plugins"
[ -d "$PLUGINS/git-agent" ] || { echo "FAIL: git-agent plugin missing under $PLUGINS" >&2; exit 1; }

echo "=== Skill Model Pin Test ==="

python3 - "$PLUGINS" <<'PY'
import glob, os, re, sys

plugins = sys.argv[1]


def frontmatter(path):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else ""


def pinned(path):
    return re.search(r"^model:[ \t]*\S+", frontmatter(path), re.M) is not None


skills = sorted(glob.glob(f"{plugins}/*/skills/*/SKILL.md"))
agents = sorted(glob.glob(f"{plugins}/git-agent/agents/*.md"))

# Guard against a passing run that checked nothing, such as a moved directory
# or frontmatter the regex no longer reads.
if not skills or not agents:
    sys.exit(f"FAIL: found {len(skills)} skills and {len(agents)} agents")
unread = [p for p in skills + agents if not frontmatter(p)]
if unread:
    sys.exit("FAIL: no frontmatter parsed in: " + ", ".join(unread))

errors = []
for path in skills:
    if pinned(path):
        errors.append(f"skill pins a model: {os.path.relpath(path, plugins)}")
for path in agents:
    if not pinned(path):
        errors.append(f"agent lost its model pin: {os.path.relpath(path, plugins)}")

if errors:
    print("\n".join(f"FAIL: {e}" for e in errors))
    sys.exit(1)

print(f"PASS: {len(skills)} skills unpinned, {len(agents)} agents pinned")
PY
