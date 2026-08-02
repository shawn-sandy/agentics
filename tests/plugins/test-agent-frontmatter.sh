#!/usr/bin/env bash
# Objective-verification test for the agent frontmatter fixes.
#
# Invariant: every kit/plugins/*/agents/*.md declares its tool scope with the
# AGENT key `tools:`, never the SKILL key `allowed-tools:`; declares an explicit
# `model:`; and names no tool outside the known-valid set.
#
# Why this matters: `allowed-tools:` is valid on a SKILL and inert on an AGENT.
# An agent that declares `allowed-tools: Read, Glob, Grep, Bash` looks scoped in
# the file and inherits Write, Edit, and unrestricted Bash at runtime — the
# declaration is silently discarded. That is invisible to a reader and only
# visible in the live agent registry, which is exactly why seven read-only plan
# reviewers shipped with full write access. Do not "correct" `tools:` back to
# `allowed-tools:` on an agent; the keys are not interchangeable across
# component types.
#
# The known-valid tool set below is the second half of the same defect: a tool
# name that no longer exists (MultiEdit, retired from Claude Code) is not an
# error at load time, it is simply a grant of nothing — so any behaviour that
# depended on it degrades silently.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_DIR="$ROOT/kit/plugins"
[ -d "$PLUGIN_DIR" ] || { echo "FAIL: kit/plugins missing at $PLUGIN_DIR" >&2; exit 1; }

echo "=== Agent Frontmatter Test ==="

python3 - "$PLUGIN_DIR" <<'PY'
import glob, os, re, sys

plugin_dir = sys.argv[1]

# Known-valid tool names: documented Claude Code built-in tools.
#
# This list must NOT be derived from "whatever the agents currently declare" —
# that would make the check circular, blessing any phantom already in the tree
# (which is exactly how `MultiEdit` survived). Every name here is a tool that
# actually exists; when Claude Code adds one, add it here in the same PR.
#
# Deliberately absent:
#   MultiEdit — retired from Claude Code. A grant of nothing.
#   Task      — the pre-rename spelling of `Agent`. Listing both would defeat
#               the purpose of this check: one of them is necessarily a phantom,
#               and whitelisting the pair guarantees a pass on the ambiguity.
VALID_TOOLS = {
    # File and search
    "Read", "Write", "Edit", "NotebookEdit", "Glob", "Grep",
    # Execution
    "Bash", "BashOutput", "KillShell",
    # Web
    "WebFetch", "WebSearch",
    # Orchestration and session
    "Agent", "Skill", "SlashCommand", "TodoWrite",
    "AskUserQuestion", "ExitPlanMode", "ToolSearch",
}

# Agents whose entire job is to read and report. The plan's objective was not
# "spell the key correctly" — it was that these seven hold no write access. The
# key rename is the mechanism; this is the property. Asserted separately because
# a correctly-spelled `tools:` naming Write is the same defect with better
# spelling, and would otherwise pass every check above.
READ_ONLY_AGENT_GLOB = "plan-reviewer-"
WRITE_TOOLS = {"Write", "Edit", "NotebookEdit"}

# Frontmatter keys carrying a tool list. `allowed-tools` is intentionally NOT
# here — its presence on an agent is itself a failure, checked separately.
TOOL_KEYS = ("tools", "disallowedTools")

def frontmatter(path):
    """Return the raw YAML frontmatter block, or None if the file has none."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else None

def tool_list(block, key):
    """Parse a `key: A, B(scope), C` line into bare tool names.

    Scope arguments are stripped: `Bash(git *)` is the Bash tool, scoped. The
    scoping syntax is valid and orthogonal to whether the tool name is real.
    """
    m = re.search(rf"^{key}:\s*(.+)$", block, re.M)
    if not m:
        return None
    return [re.sub(r"\(.*\)$", "", t.strip()) for t in m.group(1).split(",") if t.strip()]

failures = []
# Recursive: an agent filed into a subdirectory must not slip the gate. A
# single-level glob would let kit/plugins/x/agents/nested/y.md declare
# `allowed-tools:` undetected — the original defect, in the one place this
# test exists to prevent it.
agents = sorted(glob.glob(
    os.path.join(plugin_dir, "*", "agents", "**", "*.md"), recursive=True
))
if not agents:
    print("FAIL: no agent files found under kit/plugins/*/agents/")
    sys.exit(1)

for path in agents:
    rel = os.path.relpath(path, os.path.dirname(plugin_dir.rstrip("/")))
    block = frontmatter(path)
    if block is None:
        failures.append(f"{rel}: no YAML frontmatter block")
        continue

    # 1. The skills key must not appear on an agent — it is silently ignored,
    #    so the agent inherits every tool despite looking scoped.
    if re.search(r"^allowed-tools:", block, re.M):
        failures.append(
            f"{rel}: uses the SKILL key `allowed-tools:` — inert on an agent, "
            f"so the agent inherits ALL tools. Rename it to `tools:`."
        )

    # 2. An explicit tools: declaration is required. Absent, the agent inherits
    #    everything by default, which is the same defect by omission.
    declared = tool_list(block, "tools")
    if declared is None:
        failures.append(f"{rel}: declares no `tools:` — inherits every tool by default")

    # 3. An explicit model: is required so tier is chosen by intent, not
    #    inheritance from whatever session happens to spawn the agent.
    if not re.search(r"^model:\s*\S+", block, re.M):
        failures.append(f"{rel}: declares no explicit `model:`")

    # 4. Every named tool must exist. A phantom name grants nothing.
    for key in TOOL_KEYS:
        for tool in tool_list(block, key) or []:
            if tool not in VALID_TOOLS:
                failures.append(
                    f"{rel}: `{key}:` names unknown tool `{tool}` — "
                    f"not a Claude Code tool, so the grant is a no-op"
                )

    # 5. The read-only reviewers must actually be read-only. This is the
    #    plan's objective; checks 1-4 only cover the mechanism.
    if os.path.basename(path).startswith(READ_ONLY_AGENT_GLOB):
        granted = set(declared or [])
        writes = sorted(granted & WRITE_TOOLS)
        if writes:
            failures.append(
                f"{rel}: read-only reviewer grants {', '.join(writes)} — "
                f"its job is to read a plan and report findings"
            )
        # Bare `Bash` is unrestricted shell, which is write access by another
        # name. The plan-agent reviewers scope theirs to `Bash(git *)`.
        m = re.search(r"^tools:\s*(.+)$", block, re.M)
        if m and re.search(r"(^|,)\s*Bash\s*(,|$)", m.group(1)):
            failures.append(
                f"{rel}: read-only reviewer grants unrestricted `Bash` — "
                f"scope it to `Bash(git *)` as the plan-agent reviewers do"
            )

if failures:
    print(f"FAIL: {len(failures)} problem(s) across {len(agents)} agent file(s):")
    for f in failures:
        print(f"  - {f}")
    sys.exit(1)

print(f"PASS: {len(agents)} agent files declare `tools:` (not `allowed-tools:`), "
      f"an explicit `model:`, and only known-valid tools")
PY
