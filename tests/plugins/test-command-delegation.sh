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
# Each entry maps a command file to the skill whose body it must load. Listed
# explicitly rather than globbed: markdown-to-html is a real multi-step command
# and plan-to-html is a deprecation shim that forwards to a DIFFERENTLY-named
# skill with an injected flag, so neither fits this shape. Add a command here
# when it is collapsed to a delegator.
#
# The delegation is a `Read` of the skill file BY PATH, never
# `Skill(skill: "<plugin>:<same-name>")`. A command shadows a skill of the same
# name in the Skill namespace, so that call returns the command file itself and
# the skill body never loads — measured: 0 section headings that way, all of
# them when read by path. Check 1b below enforces the same rule repo-wide.
MAX_LINES = 20
DELEGATORS = {
    "plan-agent/commands/deep-grill.md": "deep-grill",
    "plan-agent/commands/plan-status.md": "plan-status",
    "plan-agent/commands/documenting-plans.md": "documenting-plans",
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

    if f"skills/{skill}/SKILL.md" not in text:
        failures.append(
            f"{rel}: never names `skills/{skill}/SKILL.md` — a delegator that does "
            f"not load its skill body by path loads nothing at all"
        )

    # Frontmatter fields the collapse had to preserve.
    for key in ("description", "argument-hint"):
        if not re.search(rf"^{key}:\s*\S", text, re.M):
            failures.append(f"{rel}: lost its `{key}:` frontmatter in the collapse")

# --- Check 1b: no command self-delegates ----------------------------------
#
# Repo-wide, not just the three above: any commands/<name>.md that instructs
# Skill(skill: "<plugin>:<name>") is instructing a call to itself. A literal
# mention inside an explicit "do not call" warning is the documented fix, not
# the defect, so a self-reference is allowed only when negated just before it.
FLAT = re.compile(r"\s+")
SELF_CALL = re.compile(r"Skill\(\s*skill:\s*[\"']([^\"']+)[\"']")

for plugin in sorted(os.listdir(plugin_dir)):
    cdir = os.path.join(plugin_dir, plugin, "commands")
    if not os.path.isdir(cdir):
        continue
    for fname in sorted(os.listdir(cdir)):
        if not fname.endswith(".md"):
            continue
        rel = os.path.join(plugin, "commands", fname)
        with open(os.path.join(cdir, fname), encoding="utf-8") as fh:
            flat = FLAT.sub(" ", fh.read())
        own = f"{plugin}:{fname[:-3]}"
        for m in SELF_CALL.finditer(flat):
            if m.group(1) != own:
                continue
            preceding = flat[max(0, m.start() - 60):m.start()].lower()
            if "not** call" in preceding or "not call" in preceding:
                continue  # the documented warning, not an instruction
            failures.append(
                f"{rel}: instructs `Skill(skill: \"{own}\")` — the command shadows "
                f"the skill of that name, so this returns the command file itself "
                f"and the skill body never loads; Read it by path instead"
            )

# --- Check 1c: markdown-to-html's async subagent runs the whole workflow --
#
# The async dispatch hands a FRESH subagent the skill path to Read, since it
# shares none of this run's state. An earlier draft of this fix told it to
# start partway through (Step 4) — skipping Step 2, the only step that parses
# the source's frontmatter/sections/steps — so synthesis had nothing to render.
# Caught in review before merge; guarded here so it cannot silently regress.
MTH_SKILL = os.path.join(plugin_dir, "plan-agent/skills/markdown-to-html/SKILL.md")
if os.path.isfile(MTH_SKILL):
    with open(MTH_SKILL, encoding="utf-8") as fh:
        mth_flat = FLAT.sub(" ", fh.read())
    dispatch = re.search(r"Async dispatch.*?(?=### Step 4)", mth_flat, re.S)
    if not dispatch:
        failures.append("plan-agent/skills/markdown-to-html/SKILL.md: async dispatch section not found")
    else:
        d = dispatch.group(0)
        # Isolate the `prompt` field's own quoted value — the text actually
        # handed to the subagent — rather than the surrounding explanatory
        # prose, which can (and should) go on saying "Step 1" regardless of
        # what the prompt template itself says.
        prompt_field = re.search(r"`prompt`:\s*`\"(.*?)\"`", d, re.S)
        if not prompt_field:
            failures.append(
                "plan-agent/skills/markdown-to-html/SKILL.md: async dispatch has no "
                "recognizable `prompt` field to check"
            )
        else:
            p = prompt_field.group(1)
            if re.search(r"step 4", p, re.I):
                failures.append(
                    "plan-agent/skills/markdown-to-html/SKILL.md: the subagent prompt "
                    "tells it to resume at Step 4, skipping Step 2's content parsing"
                )
            if not re.search(r"step 1|in full|end to end|from the (start|beginning)", p, re.I):
                failures.append(
                    "plan-agent/skills/markdown-to-html/SKILL.md: the subagent prompt "
                    "does not say to run the workflow from Step 1 / in full"
                )
            if "Skill(skill:" in p:
                failures.append(
                    "plan-agent/skills/markdown-to-html/SKILL.md: the subagent prompt "
                    "hands it a Skill() call rather than a path to Read"
                )

# --- Check 1d: allowed-tools grants only what a wrapper's target uses -----
#
# markdown-to-html's SKILL.md mentions `Skill(...)` exactly once — inside its
# own warning against calling it — so the tool is never genuinely invoked.
# Declaring it in the command's allowed-tools widens the boundary for nothing.
MTH_CMD = os.path.join(plugin_dir, "plan-agent/commands/markdown-to-html.md")
if os.path.isfile(MTH_CMD):
    with open(MTH_CMD, encoding="utf-8") as fh:
        cmd_text = fh.read()
    at_line = re.search(r"^allowed-tools:.*$", cmd_text, re.M)
    if at_line and re.search(r"\bSkill\b", at_line.group(0)):
        failures.append(
            "plan-agent/commands/markdown-to-html.md: allowed-tools grants Skill, but "
            "the skill it loads never invokes it outside a warning string"
        )

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

print(f"PASS: {len(DELEGATORS)} commands load their skill body by path "
      f"(<={MAX_LINES} lines each); no command self-delegates; "
      f"markdown-to-html's async dispatch runs the full workflow and its "
      f"allowed-tools grants nothing unused; {checked} slash references all resolve")
PY
