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
# The first collapse delegated via `Skill(skill: "plan-agent:<same-name>")`,
# which turned out to be a no-op: a command shadows a skill of the same name, so
# the call returned the command file and the skill body never loaded. Check 1
# now requires the skill be loaded by path instead, check 1b makes that a
# repo-wide rule so it isn't re-broken in a plugin nobody thought to list here,
# and checks 1c/1d cover markdown-to-html, which never fit the thin-delegator
# shape (real usage docs, an async background dispatch) but shared the same
# shadowing bug in its own dispatch prompt.
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
# Each entry names a command file that must load its same-named skill BY PATH.
# Listed explicitly rather than globbed: markdown-to-html is a real multi-step
# command and plan-to-html is a deprecation shim that forwards to a
# DIFFERENTLY-named skill with an injected flag, so neither fits this shape.
# Add a command here when it is collapsed to a delegator.
#
# By path, not `Skill(skill: "plan-agent:<name>")`. A command SHADOWS a skill of
# the same name in the Skill namespace, so the self-named call returns the
# command file itself and the skill body never enters context. Measured: the
# Skill() form put 0 of deep-grill's 3 `## ` headings and 0 of
# documenting-plans' 10 in context; reading SKILL.md by path put all of them
# there. The command still has to stay thin — a delegator that restates its
# skill's workflow drifts from it, which is how these three earned this test in
# the first place (they had drifted 20, 153, and 383 lines apart).
#
# MAX_LINES is 16, matching the longest of the already-converted wrappers
# (write-prompt.md, not itself in this map since it predates it) — plan-status
# needs one line more than deep-grill/documenting-plans for its extra
# `--all`/`--force` argument-hint.
MAX_LINES = 16
DELEGATORS = {
    "plan-agent/commands/deep-grill.md": "deep-grill",
    "plan-agent/commands/documenting-plans.md": "documenting-plans",
    "plan-agent/commands/plan-status.md": "plan-status",
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
            f"{rel}: never names `skills/{skill}/SKILL.md` — the skill body has "
            f"to be loaded by path or it never enters context"
        )

    # The self-named Skill() call is the shadowed no-op this test exists to
    # keep out. Shadowing is per-plugin, so the match is exact on
    # `<this plugin>:<this name>` — a call to `other-plugin:{skill}` resolves to
    # a different file entirely and is nobody's business here. The plugin comes
    # off the path rather than being hardcoded, so a delegator in another plugin
    # can be added to DELEGATORS without editing this check.
    own_call = f"{rel.split('/')[0]}:{skill}"
    for call in re.findall(r"Skill\(\s*skill:\s*[\"']([^\"']+)[\"']", text):
        if call == own_call:
            failures.append(
                f"{rel}: calls `Skill(skill: \"{call}\")`, which this command "
                f"shadows — it returns this file, not the skill"
            )

    # Frontmatter fields the collapse had to preserve.
    for key in ("description", "argument-hint"):
        if not re.search(rf"^{key}:\s*\S", text, re.M):
            failures.append(f"{rel}: lost its `{key}:` frontmatter in the collapse")

    # The skill body now runs INLINE under the command's permissions, so the
    # command's allowed-tools must cover every tool the skill declares. Missing
    # one does not fail at load — it fails at the branch that needs it, which is
    # how `documenting-plans` shipped a wrapper without `Skill` and would have
    # died only on plans whose status was not already `completed`. Grepping the
    # skill body for `Skill(` misses this: it asks for the tool in prose.
    skill_md = os.path.join(plugin_dir, os.path.dirname(os.path.dirname(rel)),
                            "skills", skill, "SKILL.md")
    if os.path.isfile(skill_md):
        with open(skill_md, encoding="utf-8") as fh:
            skill_text = fh.read()
        def tools(src):
            m = re.search(r"^allowed-tools:\s*(.+?)\s*$", src, re.M | re.S)
            if not m:
                return set()
            # allowed-tools may wrap onto the next line as a bare indented
            # value (see write-prompt.md); stop at the next top-level key.
            block = m.group(1)
            block = re.split(r"\n[a-z][a-z-]*:", block, maxsplit=1)[0]
            return {t.strip() for t in block.replace("\n", " ").split(",") if t.strip()}
        missing = tools(skill_text) - tools(text)
        if missing:
            failures.append(
                f"{rel}: allowed-tools omits {sorted(missing)}, which "
                f"skills/{skill}/SKILL.md declares — the skill runs inline under "
                f"this command's permissions and would stall on that branch"
            )

# --- Check 1b: no command self-delegates, repo-wide -----------------------
#
# Not just the three above: any commands/<name>.md in any plugin that
# instructs Skill(skill: "<plugin>:<name>") is instructing a call to itself.
# This is what should have caught plan-status and markdown-to-html the first
# time deep-grill/documenting-plans were fixed — it is written repo-wide and
# name-agnostic on purpose, so the next shadowed wrapper doesn't need its own
# entry added here to be caught. A literal mention inside an explicit "do not
# call" warning is the documented fix, not the defect, so a self-reference is
# allowed only when negated just before it.
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
# markdown-to-html doesn't fit DELEGATORS (real usage docs, well over
# MAX_LINES) but its skill's --async dispatch shares the same shadowing bug in
# its own subagent prompt, plus a second bug found in review: an earlier fix
# told the fresh subagent to resume at Step 4, skipping Step 2 — the only step
# that parses the source's frontmatter/sections/steps — so synthesis had
# nothing to render. Guarded here so neither can silently regress.
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

print(f"PASS: {len(DELEGATORS)} commands load their skill by path "
      f"(<={MAX_LINES} lines each); no command self-delegates; "
      f"markdown-to-html's async dispatch runs the full workflow and its "
      f"allowed-tools grants nothing unused; {checked} slash references all resolve")
PY
