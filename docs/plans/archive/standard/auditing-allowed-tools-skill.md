# Plan: `auditing-allowed-tools` Skill

## Context

Claude Code skills can declare `allowed-tools:` in their SKILL.md frontmatter to pre-authorize tools so the user isn't prompted for permission mid-run. Authors currently guess this list by hand — too narrow and users get prompted; too broad and the skill silently gains capabilities it shouldn't have.

This plan adds a new skill that does two related things:

1. **Static audit** — Read a SKILL.md, scan the body for tools it actually uses, and recommend (or patch) the minimal `allowed-tools` declaration.
2. **Session audit** — Read a Claude Code session transcript (JSONL) and report what tools Claude actually invoked, so authors can cross-reference reality against the skill's declared `allowed-tools`.

The new skill lives **inside the existing `skill-reviewer` plugin** (alongside `reviewing-skills` and `planning-skills`) rather than as a new plugin — it's a natural extension of that plugin's skill-auditing scope, and the exploration confirmed that `reviewing-skills` and `plugin-validator` do **not** currently recommend or check `allowed-tools`.

## Key findings from exploration

- Skills live at `kit/plugins/<plugin>/skills/<skill-name>/SKILL.md`.
- All 22 existing skills in the repo already declare `allowed-tools`, using a **comma-separated** format (e.g. `allowed-tools: AskUserQuestion, Bash, Read, Write`). One skill uses the restricted form `Bash(git *)` (`kit/plugins/git-agent/skills/commit-agent/SKILL.md:4`).
- `skill-reviewer` v1.5.0 audits SKILL.md quality but has **no** `allowed-tools` generation or validation logic.
- `agentic-plugin-dev`'s `plugin-creator` template does not include `allowed-tools`.
- `.claude/rules/plugin-patterns.md` has **no** documented guidance on `allowed-tools`.
- Session transcripts are JSONL files at `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl` (encoded cwd = absolute path with `/` → `-`, e.g. `-home-user-agentics`). Subagent transcripts live under `<session-uuid>/subagents/*.jsonl`.
- Each `tool_use` appears as `message.content[{type:"tool_use", name:"<Tool>", input:{...}}]` in a single JSONL line. There is **no** dedicated `permission_request` event — every logged `tool_use` represents a tool Claude needed, which is effectively the set of permissions the session consumed.

## Design

### New skill location

```
kit/plugins/skill-reviewer/skills/auditing-allowed-tools/
├── SKILL.md
└── scripts/
    └── session_tool_scan.py     # parses JSONL and emits tool-usage JSON
```

Only one reference script — a small Python file — because the JSONL parsing is mechanical and benefits from being out of the LLM context. Static body-scanning stays inline in SKILL.md (Grep-based, simple).

### Frontmatter

```yaml
---
name: auditing-allowed-tools
description: Use when the user asks to audit, recommend, fix, or generate the `allowed-tools` frontmatter for a SKILL.md, or to review which tools/permissions Claude used during a Claude Code session. Use when the user says "what allowed-tools should this skill have", "fix skill permissions", "audit tool usage", or "what tools did Claude use in this session". Does NOT score or audit general SKILL.md quality — use reviewing-skills for that.
allowed-tools: AskUserQuestion, Bash, Read, Write, Edit, Glob, Grep
---
```

### Skill body — three modes

The skill routes on user intent:

**Mode 1: Static skill audit** (recommend `allowed-tools` from a SKILL.md body)

1. **Resolve target SKILL.md** using this precedence chain:
   1. **Explicit path** — user message contains an absolute or repo-relative path to a `SKILL.md`.
   2. **Conversation context** — if another skill (e.g. `reviewing-skills`, `planning-skills`) was just run on a specific SKILL.md, or a SKILL.md was recently read/edited in this session, reuse that path. Confirm once: "Audit `allowed-tools` for `<path>`? (y/n)".
   3. **Selection picker** — otherwise, run `Glob` for `**/SKILL.md` rooted at `$PWD` (plus `~/.claude/skills/**/SKILL.md` if that dir exists) and present the results through `AskUserQuestion`:
      - If ≤4 results, list them as options directly.
      - If >4 results, group by plugin (e.g. `skill-reviewer/reviewing-skills`) and paginate; show the first page and let the user type an explicit path via the "Other" escape hatch.
      - If 0 results: report "No SKILL.md files found under `$PWD`" and ask for an explicit path.
2. Read the selected file. Parse existing `allowed-tools` line if any.
3. Scan the body for evidence of tool use:
   - **Named tools**: regex for capitalized tokens on the known tool list — `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `TodoWrite`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `NotebookEdit`, `Task`.
   - **Bash commands**: code fences and inline code containing known CLIs — `git`, `gh`, `glab`, `npm`, `pnpm`, `python`, `python3`, `node`, `jq`, `rg`, `curl`, `ls`, `cat` — to decide whether to suggest `Bash(git *)` style restriction or unrestricted `Bash`.
   - **MCP tools**: `mcp__<server>__<tool>` pattern.
   - **Scripts**: `scripts/*.py`, `scripts/*.sh` references → implies `Bash`.
   - **Negative signals**: lines containing `do not use`, `NEVER use`, `don't run` followed by a tool name are excluded.
4. Build recommended set = union of detected tools. If all Bash usage is one CLI family (e.g. only `git`/`gh`), suggest the restricted form; otherwise unrestricted `Bash`.
5. Diff recommended vs. declared:
   - **Missing**: declared set is too narrow → user would be prompted at runtime.
   - **Unused**: declared tools that don't appear in body → overly broad.
   - **OK**: sets match.
6. Print a report (table: tool | detected? | declared? | status).
7. Offer to patch the frontmatter via `Edit`. **Require explicit second confirmation** before writing (mirrors `reviewing-skills` Step 6 pattern). Three apply options presented via `AskUserQuestion`:
   - **Add missing tools only** — preserve anything the user already declared, append the detected-but-missing entries.
   - **Replace with minimal set** — overwrite the entire `allowed-tools:` line with the recommended minimal set.
   - **Report only, don't edit** — write nothing; the user will edit by hand.

   If the file has no `allowed-tools` line at all, the flow instead inserts a new line immediately below `description:` (or at the end of the frontmatter if `description:` is missing — surfaced as a warning in the report).

**Mode 1b: Review handoff** (reviewing-skills → auditing-allowed-tools)

When `reviewing-skills` completes a skill audit, the user can say "now check/fix its allowed-tools" and this skill picks up the same target automatically via the conversation-context rule in step 1. No extra command is needed — the description keyword overlap handles activation. The SKILL.md includes a one-line example of this handoff so users know it exists.

**Mode 2: Session audit** (what tools did Claude use in a session)
1. Resolve the session JSONL:
   - Explicit path from user, OR
   - "current session" / "this session" → find newest `*.jsonl` by mtime under `~/.claude/projects/<encoded-cwd>/`, where encoded-cwd = `$PWD` with `/` replaced by `-`.
   - If ambiguous, list recent sessions (path + mtime + first user message preview) and ask which one.
2. Run `scripts/session_tool_scan.py <jsonl-path> [--include-subagents]`.
   - Script reads each line, extracts every `{type:"tool_use"}` block from `message.content`.
   - Emits JSON summary: total calls, unique tool names, per-tool call counts, and for `Bash` a breakdown by first-word command (`git`, `gh`, `python3`, ...).
   - Optionally walks `<session-dir>/subagents/*.jsonl` when `--include-subagents`.
3. Print a compact report (tool | call count | sample inputs).
4. Produce an **inferred `allowed-tools` line** based on observed usage — the minimal declaration a skill would need to run this session without prompts.

**Mode 3: Cross-reference** (skill ↔ session)
1. Run Mode 1 on the SKILL.md and Mode 2 on the session.
2. Compare the three sets: declared, statically detected, actually used.
3. Report gaps — e.g. "Session used `WebFetch` 3× but the skill declares no `WebFetch` and the body never mentions it — likely an undocumented dependency."

### Script: `scripts/session_tool_scan.py`

Small (~60 LOC) standalone Python 3 script. No third-party deps. Emits JSON on stdout for the skill to read and render.

CLI:
```
python3 session_tool_scan.py <path.jsonl> [--include-subagents] [--since <ISO-timestamp>]
```

Output shape:
```json
{
  "session_id": "...",
  "line_count": 412,
  "tool_calls_total": 87,
  "tools": {
    "Bash": {"count": 42, "commands": {"git": 21, "gh": 10, "python3": 11}},
    "Read": {"count": 18},
    "Edit": {"count": 9}
  },
  "recommended_allowed_tools": "Bash, Edit, Read"
}
```

### Version + registry changes

- `kit/plugins/skill-reviewer/CHANGELOG.md` — add 1.6.0 entry.
- `.claude-plugin/marketplace.json` — bump `skill-reviewer` from `1.5.0` → `1.6.0` and extend its `tags` with `allowed-tools`, `permissions`, `session-audit`.
- `kit/plugins/skill-reviewer/README.md` — add a "Skills" subsection describing `auditing-allowed-tools` with a usage example.
- `.claude/rules/plugin-patterns.md` — add a short "Declaring `allowed-tools`" subsection pointing at the new skill. (Low-risk doc fix; exploration confirmed this guidance is currently missing.)

### Files to create/modify

| Path | Action |
|------|--------|
| `kit/plugins/skill-reviewer/skills/auditing-allowed-tools/SKILL.md` | **create** |
| `kit/plugins/skill-reviewer/skills/auditing-allowed-tools/scripts/session_tool_scan.py` | **create** |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | **edit** — add v1.6.0 entry |
| `kit/plugins/skill-reviewer/README.md` | **edit** — document new skill |
| `.claude-plugin/marketplace.json` | **edit** — bump skill-reviewer to 1.6.0 |
| `.claude/rules/plugin-patterns.md` | **edit** — document `allowed-tools` guidance |
| `docs/plans/staged-forging-flurry.md` | **include in commit** per repo rules |

## Verification

1. **Static mode happy path**: run the skill against `kit/plugins/git-agent/skills/commit-agent/SKILL.md` — it should detect Bash-git usage and confirm the declared `Bash(git *)` is correct (status: OK).
2. **Static mode finds gap**: temporarily remove `Bash` from a test SKILL.md's `allowed-tools`, run the skill, verify it reports "missing: Bash" and offers to patch.
3. **Session mode**: run `python3 scripts/session_tool_scan.py ~/.claude/projects/-home-user-agentics/<some-session>.jsonl` directly and check the JSON output is well-formed and tool counts look plausible (spot-check against `grep -c tool_use` on the raw file).
4. **Subagent aggregation**: pick a session with subagents under `<session-uuid>/subagents/`, run with `--include-subagents`, confirm counts increase.
5. **Current-session resolution**: from `/home/user/agentics`, invoke the skill with "audit the current session" — it should pick the newest file under `~/.claude/projects/-home-user-agentics/`.
6. **Confirmation gate**: trigger Mode 1 patch flow, answer "no" at the confirmation prompt — verify nothing is written. Answer "yes" — verify only the `allowed-tools` line is edited, nothing else in the frontmatter touched.
7. **Marketplace sanity**: after editing `marketplace.json`, the project's auto-validation hook should pass. Run `/plugin-validator` (from `agentic-plugin-dev`) against the updated `skill-reviewer` plugin to confirm structure is still valid.
8. **Picker flow**: invoke the skill with no target ("audit allowed-tools") from `/home/user/agentics`. Verify the Glob finds all 22 SKILL.md files under `kit/plugins/**/SKILL.md`, the grouping/pagination works, and selecting one kicks off Mode 1 against that file.
9. **Handoff flow**: run `reviewing-skills` on a target first, then follow up with "now fix its allowed-tools". Verify `auditing-allowed-tools` picks up the same target automatically without re-prompting for a path.
10. **Apply-mode matrix**: for one test skill with a stale `allowed-tools: Read` line where the body also uses `Bash` and `Write`, verify all three apply options: "add missing" yields `Read, Bash, Write`; "replace minimal" yields `Bash, Read, Write` (minus any unused); "report only" leaves the file untouched.

## Out of scope

- Generating `allowed-tools` for commands or agents (only SKILL.md for now).
- Real-time permission interception or prompt-replay.
- Writing a generic SKILL.md quality audit (use `reviewing-skills`).
- Parsing hook events or `settings.json` `permissions` rules (those are a separate, user-level system — the skill only works with `allowed-tools` frontmatter).

## Stress-test notes and hardening

These risks surfaced while reviewing the plan. Each is addressed explicitly in the SKILL.md body.

1. **False positives in name-based tool detection.** Scanning for bare capitalized words like `Read` or `Edit` would match prose (e.g. "Read the documentation"). Mitigations the skill must apply:
   - Only count a name as evidence if it appears in **one** of: a fenced code block, an inline backtick span (`` `Read` ``), a heading that mentions it as a tool, or a structured list of the form `- **Tool**:` / `- allowed-tools:`.
   - Exclude any match on a line (or within ±1 line) containing `do not`, `NEVER`, `don't`, `avoid`, or `skip` followed by the tool name within ~6 tokens.
   - Require ≥2 independent signals for `Bash` before recommending it (e.g. a `bash` code fence **plus** a known CLI token), to avoid flagging skills that only quote command-line examples.
2. **Current-session resolution cannot use an env var.** Verified `CLAUDE_CODE_SESSION_ID=cse_...` exists but does NOT match the JSONL UUID format (`ed4403ba-...`). Fallback ordering: (a) explicit path from user, (b) explicit UUID from user resolved under `~/.claude/projects/<encoded-cwd>/`, (c) newest `*.jsonl` by mtime in that directory. Encode cwd as `$PWD` with `/` → `-` and verify the resulting dir exists before mtime-sorting.
3. **Recursive-edit hazard.** If the target SKILL.md is `auditing-allowed-tools/SKILL.md` itself, the skill must print the recommendation but refuse auto-apply and instruct the user to edit by hand.
4. **Script path resolution at runtime.** Existing skills invoke scripts with a bare relative path (`python scripts/foo.py`), which only works if cwd is the skill folder. The new skill must construct an absolute path from the SKILL.md's own location (Claude knows the absolute path because it just read the file) and invoke `python3 "<abs-skill-dir>/scripts/session_tool_scan.py" …`. The SKILL.md will show this pattern explicitly with a placeholder, not a hardcoded path.
5. **Bash restriction syntax.** `Bash(git *)` is used by `kit/plugins/git-agent/skills/commit-agent/SKILL.md:4` — treat that as empirical evidence the syntax is supported. If a future Claude Code version rejects it, the skill gracefully falls back to unrestricted `Bash` (documented in the SKILL.md as a known failure mode).
6. **Subagent transcript schema.** Not fully verified — the `session_tool_scan.py` script must defensively skip lines that lack the expected `message.content[].type == "tool_use"` shape instead of crashing, and count parse-failures in its JSON output under `skipped_lines`.
7. **Streaming reads on an actively-written JSONL.** The session file for the *current* session is being written while the skill runs. The script must read line-by-line and tolerate a truncated final line (try/except per line).
8. **Trigger overlap with `reviewing-skills`.** A user saying "review my skill" could activate either skill. Disambiguation is handled by the `auditing-allowed-tools` description: it leads with permission/allowed-tools keywords and explicitly says "Does NOT score or audit general SKILL.md quality — use reviewing-skills for that."
9. **Large transcripts.** Some `.jsonl` files are several MB. The Python script must not materialize the whole file; iterate `open(path)` line-by-line. No `readlines()`, no `json.load()` on the whole file.
10. **MCP tool names in `allowed-tools`.** Unverified whether `mcp__github__create_pull_request` is a valid `allowed-tools` entry. The skill detects MCP usage but recommends it as a **comment in the report** rather than injecting it into the frontmatter automatically, until the convention is confirmed.
