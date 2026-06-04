# Plan: Create `agent-reviewer` Plugin

## Context

The marketplace has a `skill-reviewer` plugin that audits SKILL.md files against best practices. There is no equivalent for **subagent definition files** (`agents/*.md`). Users creating subagents have no way to validate their definitions against the official documentation at [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents). This plugin fills that gap with a scored, structured audit skill.

## Objective

Create a new `agent-reviewer` plugin at `kit/plugins/agent-reviewer/` with a `reviewing-agents` skill that audits Claude Code subagent definition files across 5 dimensions, produces a scored report, and optionally generates a corrected version.

## Steps

### 1. Create plugin manifest

**File:** `kit/plugins/agent-reviewer/.claude-plugin/plugin.json`

```json
{
  "name": "agent-reviewer",
  "description": "Review and audit Claude Code subagent definition files against official best practices",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["agents", "sub-agents", "best-practices", "agent-review", "quality-audit"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/agent-reviewer",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

- No `version` in plugin.json -- set only in `marketplace.json` (per project convention).

### 2. Create `reviewing-agents` skill (SKILL.md)

**File:** `kit/plugins/agent-reviewer/skills/reviewing-agents/SKILL.md`

- **Frontmatter:** `name: reviewing-agents`, `allowed-tools: AskUserQuestion, Bash, Read, Write`
- **Description:** trigger phrases include "review my agent", "audit this agent", "check agent quality", "score my agent definition"
- **Scope exclusion:** "Does NOT create or scaffold new agents -- use agent-creator for that. Does NOT review SKILL.md files -- use skill-reviewer for that."

**Workflow (mirrors `reviewing-skills` pattern):**

1. **Resolve target** -- explicit path, conversation context, glob `agents/*.md`, or ask
2. **Read and measure** -- line count, word count, frontmatter fields present, body sections, plugin agent detection (walk up to find `.claude-plugin/plugin.json`), agent type detection (read-only / editor / background / orchestrator)
3. **Determine guidelines source** -- static `references/best-practices.md` by default; live fetch from `https://code.claude.com/docs/en/sub-agents` on request
4. **Regression risk check** -- optional git-based comparison (same skip conditions as skill-reviewer)
5. **Score 5 dimensions** -- delegate to `references/audit-steps.md`
6. **Output report** -- scored table + grade
7. **Offer fix** -- auto-correct frontmatter, flag body issues with inline comments
8. **Write to disk** -- two-step confirmation

Target: ~150-170 lines (matching `reviewing-skills` length).

### 3. Create `references/best-practices.md`

**File:** `kit/plugins/agent-reviewer/skills/reviewing-agents/references/best-practices.md`

Normative rules organized by audit dimension. Key sections:

- **Frontmatter compliance rules** -- all 16 fields with valid values, format constraints, and defaults
- **Tool configuration rules** -- least privilege, read-only pattern, background safety, Agent tool caveat (no effect in subagents)
- **Description quality rules** -- delegation context, trigger phrases, scope exclusion, keyword density
- **System prompt quality rules** -- required sections (Role, Workflow), recommended sections (Output Format, Scope Boundaries), background STOP instruction, memory instruction pairing
- **Security & isolation rules** -- bypassPermissions flag, plugin agent ignored fields, background + mutations
- **Anti-patterns table** -- error / warning / suggestion levels with detection criteria and fixes

Source of truth: official docs at `https://code.claude.com/docs/en/sub-agents`.

Target: ~400-450 lines.

### 4. Create `references/audit-steps.md`

**File:** `kit/plugins/agent-reviewer/skills/reviewing-agents/references/audit-steps.md`

Procedural steps for the audit workflow:

- **Regression risk comparison matrix** -- name (BREAKING), description triggers (BREAKING), tools list (WARNING), model/permissionMode (WARNING), line reduction >30% (WARNING), new anti-patterns (INFO)
- **Scoring rubric** -- 5 dimensions, 2 pts each, detailed criteria per score level
- **Report template** -- summary, scores table, grade, regression risk section
- **Fix generation rules** -- frontmatter auto-fixes vs body inline suggestions
- **Write confirmation** -- two-step pattern

Target: ~250-300 lines.

### 5. Create CHANGELOG.md

**File:** `kit/plugins/agent-reviewer/CHANGELOG.md`

v1.0.0 entry documenting all initial features.

### 6. Create README.md

**File:** `kit/plugins/agent-reviewer/README.md`

Following the `skill-reviewer` README pattern: Overview, Features, Installation, Usage examples, Plugin Structure tree, Components, Scoring dimensions table, Grade thresholds.

### 7. Register in marketplace

**File:** `.claude-plugin/marketplace.json` (edit existing)

Add new entry to `plugins` array:

```json
{
  "name": "agent-reviewer",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/shawn-sandy/agentics.git",
    "path": "kit/plugins/agent-reviewer"
  },
  "version": "1.0.0",
  "description": "Review and audit Claude Code subagent definition files against official best practices",
  "category": "development",
  "tags": ["agents", "sub-agents", "best-practices", "agent-review", "quality-audit", "security"]
}
```

Bump marketplace version from `3.1.0` to `3.2.0` (minor: new plugin added).

## Scoring Dimensions

| # | Dimension | Points | Key Checks |
|---|-----------|--------|------------|
| 1 | Frontmatter Compliance | 0-2 | Required fields, valid values, naming conventions |
| 2 | Tool Configuration | 0-2 | Least privilege, Agent tool caveat, background safety |
| 3 | Description Quality | 0-2 | Delegation context, trigger phrases, scope exclusion |
| 4 | System Prompt Quality | 0-2 | Role + Workflow sections, STOP instruction, memory pairing |
| 5 | Security & Isolation | 0-2 | bypassPermissions, plugin ignored fields, mutation restrictions |

**Grades:** Excellent (9-10), Good (6-8), Needs Work (3-5), Rewrite (0-2)

## Key Anti-Patterns to Detect

| Level | Anti-Pattern | Detection |
|-------|-------------|-----------|
| Error | Missing `name` or `description` | Frontmatter parse |
| Error | `name` not lowercase/hyphens | Regex check |
| Error | YAML parse failure | Frontmatter parse |
| Warning | `Agent` in `tools` list | Subagents cannot spawn subagents |
| Warning | Plugin agent with `permissionMode`/`hooks`/`mcpServers` | Silently ignored at runtime |
| Warning | `background: true` + unrestricted `Write`/`Edit`/`Bash` | Safety concern |
| Warning | `memory` set but no memory instructions in body | Broken persistence pattern |
| Warning | `bypassPermissions` without justification | Security risk |
| Suggestion | Missing scope exclusion in description | Best practice |
| Suggestion | Missing `## Output Format` section | Completeness |
| Suggestion | Both `tools` and `disallowedTools` set | Unusual but valid |

## Critical Files to Reuse

- [SKILL.md](kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md) -- template for workflow structure
- [audit-steps.md](kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md) -- template for scoring + report format
- [best-practices.md](kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md) -- template for rules organization
- [plugin.json](kit/plugins/skill-reviewer/.claude-plugin/plugin.json) -- template for manifest
- [marketplace.json](.claude-plugin/marketplace.json) -- registration target

## Files Created / Modified

| Action | File |
|--------|------|
| Create | `kit/plugins/agent-reviewer/.claude-plugin/plugin.json` |
| Create | `kit/plugins/agent-reviewer/skills/reviewing-agents/SKILL.md` |
| Create | `kit/plugins/agent-reviewer/skills/reviewing-agents/references/best-practices.md` |
| Create | `kit/plugins/agent-reviewer/skills/reviewing-agents/references/audit-steps.md` |
| Create | `kit/plugins/agent-reviewer/CHANGELOG.md` |
| Create | `kit/plugins/agent-reviewer/README.md` |
| Edit | `.claude-plugin/marketplace.json` |

## Verification

1. **Load plugin locally:** `claude --plugin-dir ./kit/plugins/agent-reviewer`
2. **Test on existing agents:** Run `reviewing-agents` against `kit/plugins/code-review/agents/agent-code-reviewer.md` -- should score high (well-structured existing agent)
3. **Test anti-pattern detection:** Create a temporary bad agent file with `bypassPermissions`, `Agent` in tools, missing description -- verify warnings fire
4. **Test plugin agent detection:** Review an agent inside a plugin directory -- verify permissionMode/hooks/mcpServers ignored-field warnings
5. **Validate marketplace.json:** `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"`
6. **Regression check:** Run against a git-tracked agent file -- verify regression risk section appears

## Next Steps (out of scope for v1.0.0)

- `planning-agents` skill -- help users draft or improve agent definitions (analogous to `planning-skills`)
- Background `agent-agent-reviewer` subagent for delegation from other agents
- Batch mode: audit all agents in a directory at once
- Update `agent-creator`'s `references/agent-schema.md` to align with the new canonical field list (it's missing `effort`, `color`, `initialPrompt`)

## Interview Summary

### Key Decisions Confirmed

1. **Keep 5 separate scoring dimensions** -- Tool Configuration and Security & Isolation remain distinct despite partial overlap. Tool Config covers least-privilege and correctness; Security covers permission modes, background safety, and plugin caveats.
2. **Live fetch stays optional** -- Default to static `references/best-practices.md`; live fetch from `code.claude.com/docs/en/sub-agents` only on explicit user request.
3. **Fix output offers both options** -- Present diff first, then ask whether user wants inline comments in a copy or the diff applied directly.
4. **Compatibility note for agent-creator** -- `best-practices.md` includes a brief note that `agent-creator`'s `agent-schema.md` may lag behind official docs.
5. **Skip plugin-ignored-fields warning for marketplace repos** -- When the agent is inside a known marketplace structure (`kit/plugins/`), suppress the permissionMode/hooks/mcpServers warning.
6. **maxTurns thresholds: <5 and >50** -- Warning level for values outside this range.
7. **Golden template comparison for new agents** -- For files with no git history, compare against a structural template and report missing sections as "template gaps."
8. **All 4 edge cases handled** -- Empty body (score 0 on Dim 4), non-YAML frontmatter (hard failure), mixed tools+disallowedTools (INFO), duplicate YAML keys (ERROR).

### Open Risks & Concerns

- YAML multi-line parsing (folded `>` and block `|` scalars) needs explicit handling guidance with examples in best-practices.md.
- Marketplace version at implementation time should be verified dynamically, not hardcoded as `3.1.0 -> 3.2.0`.
- Verification threshold undefined -- "should score high" needs a concrete number (>= 8/10 recommended).
- Golden template file missing from file list -- needs either `references/agent-template.md` or a dedicated section in `best-practices.md`.

### Recommended Amendments

1. Add golden template to file list (either `references/agent-template.md` or a section in `best-practices.md`).
2. Revise Step 7 to present diff first, then offer inline comments or direct application as two choices.
3. Add the 4 confirmed edge cases (empty body, non-YAML, mixed tools, duplicate keys) to audit-steps reference.
4. Include folded/block scalar examples in best-practices.md for YAML parsing guidance.
5. Document marketplace-repo suppression logic in SKILL.md workflow for plugin detection.
6. Change "should score high" to ">= 8/10" in verification step.
