---
name: reviewing-agents
description: "Use when the user asks to review, audit, score, or check an agent definition file (agents/*.md) for quality and best practices."
allowed-tools: AskUserQuestion, Bash, Read, Write
---

## Overview

Performs a structured, scored audit of Claude Code subagent definition files
against official best practices. Produces a scored report across 5 quality
dimensions and optionally generates a corrected version.

Follow these steps exactly.

## When not to use

Does not scaffold new agents — use agent-creator. Does not review SKILL.md files — use skill-reviewer.

## Table of Contents

- [Step 1: Resolve Target Agent File](#step-1-resolve-target-agent-file)
- [Step 2: Read and Measure](#step-2-read-and-measure)
- [Step 2b: Determine Guidelines Source](#step-2b-determine-guidelines-source)
- [Step 2c: Regression Risk Check](#step-2c-regression-risk-check)
- [Steps 3-7: Audit, Score, Report, Fix, and Write](#steps-3-7-audit-score-report-fix-and-write)
- [Quick Reference Checklist](#quick-reference-checklist)

---

## Step 1: Resolve Target Agent File

Determine which agent definition file to audit:

1. **Explicit path in message** -- If the user provided a file path, use it directly.
2. **Conversation context** -- If an agent has been recently discussed or created, use that file.
3. **Glob for agents** -- Search for `agents/*.md` files in the project and present a picker via AskUserQuestion.
4. **Ask if still unclear** -- "Which agent definition file would you like me to review? Please provide the path."

Validate the resolved file is an agent definition (has YAML frontmatter with at least a `name:` field). If the file is a SKILL.md, redirect: "This looks like a skill file. Use `/reviewing-skills` instead."

---

## Step 2: Read and Measure

Read the target file and record:

| Metric | Value |
|--------|-------|
| Total lines | Count all lines |
| Word count | Count words in body (after closing `---`) |
| Frontmatter fields present | name, description, tools, disallowedTools, model, permissionMode, maxTurns, skills, mcpServers, hooks, memory, background, effort, isolation, color, initialPrompt |
| Body lines | Lines after closing `---` |
| Body sections detected | Role, Workflow/Behavior, Output Format, Scope Boundaries, Memory instructions |
| Agent type | Read-only, Editor, Background, Orchestrator (infer from tools + background field) |

**Plugin agent detection:**

Walk up from the agent file's directory to find `.claude-plugin/plugin.json`.
If found AND the agent is inside a known marketplace structure (`kit/plugins/`),
set `marketplace_repo = true` -- suppress plugin-ignored-fields warnings.
If found but NOT in `kit/plugins/`, set `plugin_agent = true` -- warn about
ignored fields (permissionMode, hooks, mcpServers).

**Edge case detection:**

- **Empty body** -- Frontmatter present but zero body lines. Will score 0 on System Prompt Quality.
- **Non-YAML frontmatter** -- File does not start with `---`. Report as hard failure.
- **Duplicate YAML keys** -- Same key appears twice in frontmatter. Flag as ERROR (YAML parsers silently use last value).

Note the presence or absence of:
- YAML frontmatter delimiters (`---`)
- `name:` field
- `description:` field with "Use when..." trigger phrase
- `## Role` section in body
- `## Workflow` or `## Behavior` section in body
- `## Output Format` section in body
- `## Scope Boundaries` section in body
- STOP instruction (for background agents)
- Memory consult/update instructions (if `memory:` is set)

---

## Step 2b: Determine Guidelines Source

**Default:** Use `references/best-practices.md` (static, always available).

**Fetch live from official docs when user says:**
- "use latest", "check official docs", "fetch from platform", "use current guidelines"

Live fetch URL:
```
https://code.claude.com/docs/en/sub-agents
```

If live fetch fails: fall back to `references/best-practices.md` silently and note the failure in the audit output under a "Guidelines Source" line.

---

## Step 2c: Regression Risk Check

**For files with git history:** Compare the current agent file against its last committed version to detect breaking changes and regressions. See `references/audit-steps.md` for the comparison matrix.

**Skip if any of the following are true:**
- Not inside a git repository (`git rev-parse --git-dir` returns non-zero)
- File has never been committed (`git log --oneline -- <path>` returns no output)
- User says "skip regression check", "no comparison", or "first review"

**For new files (no git history):** Run the golden template comparison instead.
Check whether the agent file includes the expected structural sections:
`## Role`, `## Workflow` or `## Behavior`, and (for agents that produce output)
`## Output Format`. Report missing sections as "template gaps" alongside the
dimension scores. See `references/best-practices.md` -- Golden Template section.

---

## Steps 3-7: Audit, Score, Report, Fix, and Write

Continue with `references/audit-steps.md` for:

- **Step 3:** Score 5 dimensions (2 pts each, max 10)
- **Step 4:** Output scored report with grade
- **Step 5:** Present fixes as a unified diff in chat output
- **Step 6:** Ask whether to apply diff directly or add inline `<!-- SUGGESTION -->` comments to a copy
- **Step 7:** Write-to-disk confirmation (requires explicit second confirmation)

---

## Quick Reference Checklist

**Frontmatter Compliance**
- [ ] YAML delimiters (`---`) present and matching
- [ ] `name:` present, lowercase + hyphens only, <=64 chars
- [ ] `name:` does not contain `anthropic` or `claude` as substring
- [ ] `description:` present, <=1024 chars, third person
- [ ] `model:` valid if present (sonnet, opus, haiku, full model ID, inherit)
- [ ] `permissionMode:` valid if present (default, acceptEdits, auto, dontAsk, bypassPermissions, plan)
- [ ] `maxTurns:` in range 5-50 if present
- [ ] `effort:` valid if present (low, medium, high, xhigh, max)
- [ ] `color:` valid if present (red, blue, green, yellow, purple, orange, pink, cyan)
- [ ] `background:` boolean if present
- [ ] `isolation:` is `worktree` if present
- [ ] `memory:` valid if present (user, project, local)
- [ ] No unrecognized frontmatter field names
- [ ] No duplicate YAML keys

**Tool Configuration**
- [ ] All tool names in `tools:` are valid Claude Code tools
- [ ] `Agent` not listed in `tools:` (no effect in subagents)
- [ ] Both `tools` and `disallowedTools` set noted as INFO
- [ ] Read-only agents have `disallowedTools: Write, Edit, NotebookEdit`
- [ ] Background agents do not have unrestricted Write/Edit/Bash
- [ ] If tools omitted: inherits all -- appropriate for purpose?

**Description Quality**
- [ ] "Use when..." trigger phrase present
- [ ] Delegation context explains WHEN to delegate (not just what it does)
- [ ] Scope exclusion present ("Does NOT...", "Not intended for...")
- [ ] >=3 searchable domain keywords
- [ ] Third person (no I, you, we, your)

**System Prompt Quality**
- [ ] `## Role` section present
- [ ] `## Workflow` or `## Behavior` section present with numbered steps
- [ ] Output format defined (if agent produces reports)
- [ ] Scope boundaries defined (in scope / out of scope)
- [ ] STOP instruction present (if `background: true`)
- [ ] Memory consult/update instructions present (if `memory:` is set)
- [ ] Body length 20-300 lines
- [ ] No hardcoded absolute paths

**Security & Isolation**
- [ ] `bypassPermissions` not used (or has explicit justification)
- [ ] `background: true` + mutation tools restricted
- [ ] Plugin agent: ignored fields not set (unless marketplace repo)
- [ ] Memory enabled with corresponding body instructions
- [ ] `maxTurns` not outside 5-50 range
