---
name: auditing-allowed-tools
description: "Audits and fixes `allowed-tools` for SKILL.md files. Recommends or patches permissions; cross-references against session transcripts. Use when asked to audit, fix, or review tool permissions."
allowed-tools: AskUserQuestion, Bash, Read, Write, Edit, Glob, Grep
argument-hint: "[SKILL.md path] [session UUID]"
---

## Overview

Recommends (and optionally applies) the minimal `allowed-tools:` declaration a SKILL.md needs so users aren't prompted mid-run, and reports which tools Claude actually invoked during a past session. Three modes:

- **Mode 1 — Static audit**: scan a SKILL.md body, recommend or patch `allowed-tools`.
- **Mode 2 — Session audit**: parse a session JSONL, report observed tool usage.
- **Mode 3 — Cross-reference**: compare a SKILL.md against a real session to find gaps.

Route on user intent. If the request is ambiguous ("check my skill"), assume Mode 1.

## When not to use

Does not score or audit general SKILL.md quality — use reviewing-skills for that.

## Mode 1: Static audit

### Step 1: Resolve target SKILL.md

Use this precedence:

1. **Explicit path** — if the user provided a file path to a SKILL.md, use it directly.
2. **Conversation context** — if `reviewing-skills`, `planning-skills`, or any recent `Read`/`Edit` in this conversation targeted a specific SKILL.md, reuse that path. Confirm once: `Audit allowed-tools for <path>? (y/n)`.
3. **Selection picker** — otherwise:
   - `Glob` for `**/SKILL.md` under `$PWD`.
   - If 0 matches, ask the user for an explicit path.
   - If 1–4 matches, present them directly via `AskUserQuestion`.
   - If >4 matches, group by plugin folder (e.g. `skill-reviewer/reviewing-skills`) and present the first page (4 entries); the user can pick "Other" to type an explicit path.

**Recursive-edit guard**: if the resolved target is this skill's own SKILL.md (`auditing-allowed-tools/SKILL.md`), print the recommendation but skip the auto-apply step and instruct the user to edit by hand.

### Step 2: Read and parse frontmatter

Use `Read` on the target. Extract:

- The YAML frontmatter (between the first two `---` lines).
- The current `allowed-tools:` value, parsed as a comma-separated list of entries. Each entry is either a bare tool name (`Read`) or a restricted form (`Bash(git *)`).
- The body (everything after the closing `---`).

If there is no `allowed-tools:` line, record `declared = []` and flag this in the report; insertion (not replacement) will be needed in Step 7.

### Step 3: Scan the body for tool evidence

Apply these rules to the body text. Every rule produces *signals* that count toward the recommended set.

**Named tools** — for each of: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `TodoWrite`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `NotebookEdit`, `Task`, `Agent`

A match counts as a signal **only if** it appears in one of:

- A fenced code block (```` ``` ```` … ```` ``` ````)
- An inline backtick span (`` `Read` ``)
- A heading, e.g. `### Use the Read tool`
- A structured list: `- **Tool**:`, `- Tools used:`, or `allowed-tools:`

Exclude any match where the same line (or the line immediately above/below) contains `do not`, `NEVER`, `don't`, `avoid`, or `skip` within ~6 tokens before the tool name.

**Bash commands** — scan fenced code blocks with the `bash`/`sh` language hint (or unlabeled fences containing `$`/`#` prompts). Extract the first word of each command line and map it to known CLIs: `git`, `gh`, `glab`, `npm`, `pnpm`, `yarn`, `python`, `python3`, `node`, `jq`, `rg`, `curl`, `wget`, `ls`, `cat`, `find`, `grep`, `sed`, `awk`.

Each distinct CLI family is tracked separately. **Require ≥2 independent signals before recommending `Bash`** — either (a) a named-tool mention of `Bash` plus any CLI token, or (b) two distinct CLI tokens in code fences. This avoids flagging skills that merely quote a command-line example in prose.

**MCP tools** — find `mcp__<server>__<tool>` patterns. Record them as detected but do **not** inject them into the frontmatter (the `allowed-tools` convention for MCP is unconfirmed). Report them as a separate "MCP references" note.

**Scripts** — any reference to `scripts/*.py`, `scripts/*.sh`, or `python3 scripts/…` counts as a Bash signal plus a note that the script exists.

### Step 4: Build the recommended set

- Union all detected tool names.
- For Bash, if exactly **one** CLI family was detected, suggest the restricted form `Bash(<cli> *)`. If two or more, suggest unrestricted `Bash`.
- Drop anything that only appeared in negative contexts (from Step 3's exclusion rules).
- Sort alphabetically for a stable output.

### Step 5: Diff declared vs. recommended

For each tool in `declared ∪ recommended`, classify:

| Status | Meaning |
|--------|---------|
| OK | in both sets |
| MISSING | in recommended but not declared — user will be prompted at runtime |
| UNUSED | in declared but no body signal — overly broad permission |

### Step 6: Print the report

Format:

```
Target: <path>
Declared:    <current allowed-tools line, or "(none)">
Recommended: <comma-separated minimal set>

Tool             Detected  Declared  Status
---------------  --------  --------  --------
Bash(git *)         yes       yes      OK
Read                yes       yes      OK
Write               yes       no       MISSING
TodoWrite           no        yes      UNUSED

MCP references (informational): mcp__github__create_pull_request
Notes: <any warnings — missing frontmatter, recursive-edit, etc.>
```

### Step 7: Offer to apply

Use `AskUserQuestion` with three options:

1. **Add missing tools only** — append `MISSING` entries to the declared list, preserve order, keep `UNUSED` entries as-is.
2. **Replace with minimal set** — overwrite the `allowed-tools:` line with the recommended set (drops `UNUSED`).
3. **Report only** — write nothing.

If the user picks option 1 or 2, use `Edit` with the **full current line** as `old_string` and the new line as `new_string`. This touches only the `allowed-tools:` line — nothing else in the frontmatter. Confirm success by re-reading the file and printing the new line.

If the target had no `allowed-tools:` line at all, insert a new line immediately below `description:`. If `description:` is also missing, surface a warning and refuse to insert — the file needs a proper frontmatter first.

Do **not** auto-apply in the recursive-edit case (see Step 1).

## Mode 1b: Review handoff

When `reviewing-skills` or `planning-skills` has just operated on a SKILL.md and the user says "now check/fix its allowed-tools" (or similar), this skill picks up the same target from conversation context. No extra path needed — just confirm once and jump to Step 2. Users can chain the two skills naturally:

```
> Review kit/plugins/foo/skills/bar/SKILL.md
(reviewing-skills runs its audit)
> Now fix its allowed-tools
(auditing-allowed-tools picks up the same target)
```

## Mode 2: Session audit

### Step 1: Resolve the session JSONL

Precedence:

1. **Explicit path** — user provided an absolute path to a `.jsonl` file.
2. **Explicit UUID** — user provided a session UUID; resolve to `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl`.
3. **"current session" / "this session" / (no target)** — find the newest `*.jsonl` by mtime under `~/.claude/projects/<encoded-cwd>/`, where `encoded-cwd` is the current `$PWD` with every `/` replaced by `-` (e.g. `/home/user/agentics` → `-home-user-agentics`).

Verify the directory exists before listing. If the directory is missing, report:

```
No session transcripts found for $PWD. Expected: ~/.claude/projects/<encoded-cwd>/
```

If there are multiple recent sessions and the user's intent is ambiguous, list the 5 newest (path + mtime) and ask which one.

### Step 2: Run the scan script

The script lives in `scripts/session_tool_scan.py` inside this skill's folder. Invoke the bundled `bin/` wrapper as a bare command — the plugin's `bin/` is on the Bash tool's `PATH`, so it resolves regardless of the current working directory:

```bash
skill-reviewer-scan-tools <jsonl-path> [--include-subagents]
```

Do **not** spell this as a plugin-root-anchored path. Claude Code's Bash tool refuses any command whose text contains `${VAR}` or `$VAR` with `error: Contains expansion`, and the refusal fires before permission rules are consulted — so such a command never runs, at any permission level.

If the bare command is not found (e.g. the skill was loaded ad hoc rather than as an installed plugin), fall back to an absolute path built from the directory containing this SKILL.md (known because you just read it). Pass `--include-subagents` when the user wants subagent transcripts aggregated in, or when running Mode 3.

The script emits JSON on stdout with this shape:

```json
{
  "file": "…",
  "session_id": "…",
  "tool_calls_total": 87,
  "skipped_lines": 0,
  "subagent_files_scanned": 0,
  "tools": {
    "Bash": {"count": 42, "commands": {"git": 21, "gh": 10, "python3": 11}},
    "Read": {"count": 18},
    "Edit": {"count": 9}
  },
  "recommended_allowed_tools": "Bash, Edit, Read"
}
```

### Step 3: Render the report

```
Session: <session_id>
File:    <jsonl-path>
Total tool calls: <N> (subagents: <M>)
Skipped malformed lines: <K>

Tool        Calls   Notes
----------  ------  -----------------------------------
Bash           42   git (21), gh (10), python3 (11)
Read           18
Edit            9

Inferred minimal allowed-tools for this session:
    allowed-tools: <recommended_allowed_tools>
```

If `skipped_lines > 0`, note it (usually the in-progress last line).

## Mode 3: Cross-reference

When the user provides both a SKILL.md target and a session (or asks "did my skill actually need everything it declared"), run Mode 1 and Mode 2 in sequence, then compare three sets:

- `declared` — from frontmatter
- `static` — from body scan (Mode 1 Step 4)
- `observed` — from session scan (Mode 2)

Report gaps:

- In `observed` but not `static` and not `declared` → **undocumented runtime dependency**
- In `static` but not `observed` → skill *talks about* the tool but didn't use it this session (may still be correct)
- In `declared` but neither `static` nor `observed` → clear candidate for removal

## Limits and known issues

- `Bash(git *)` style restrictions are used elsewhere in this repo (`git-agent/commit-agent`) — treated as supported. If a future Claude Code version rejects it, drop back to unrestricted `Bash`.
- MCP tool names (`mcp__…`) are reported but never written into `allowed-tools` automatically — the declaration format for MCP is not confirmed.
- The script tolerates partial last lines in an actively-written session JSONL. A non-zero `skipped_lines` count usually means the final line was mid-write.
- This skill only audits SKILL.md `allowed-tools` — it does not touch `settings.json` `permissions` rules, hook configurations, or command/agent frontmatter.

## Quick examples

Audit a specific file, report only:
```
> Check if kit/plugins/foo/skills/bar/SKILL.md has the right allowed-tools
```

Pick a skill from a list:
```
> Audit allowed-tools for one of my skills
```

Review this session's tool usage:
```
> What tools did Claude actually use in this session?
```

Cross-check a skill against a session:
```
> Did foo/bar/SKILL.md actually need everything it declared? Use the current session.
```
