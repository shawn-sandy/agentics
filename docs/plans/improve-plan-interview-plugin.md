# Plan: Improve plan-interview Plugin (v1.5.0)

## Context

The `plan-interview` plugin was reviewed against the [official Claude Code plugin reference](https://code.claude.com/docs/en/plugins-reference). Several gaps were found: a missing `Bash` tool in allowed-tools (bug), no `allowed-tools` on the skill, ~240 lines of duplicated content between command and skill, and no agent for codebase exploration. This plan addresses each gap to align the plugin with reference best practices.

## Changes

### 1. Fix: Add `Bash` to plan-interview command's allowed-tools

**File:** `plugins/plan-interview/commands/plan-interview.md`

Step 2 instructs Claude to rename files with `mv`, but `Bash` is not in
`allowed-tools`. Change:

```yaml
allowed-tools: Read, Glob, AskUserQuestion, Write, Edit, TodoWrite
```

to:

```yaml
allowed-tools: Read, Glob, AskUserQuestion, Write, Edit, TodoWrite, Bash
```

Note: `review-rename-plans.md` already has `Bash` -- no change needed there.

### 2. Rename skill and add `allowed-tools` to SKILL.md frontmatter

**File:** `plugins/plan-interview/skills/plan-interview/SKILL.md`

Rename the skill directory from `skills/plan-interview/` to
`skills/plan-stress-test/` and update the SKILL.md frontmatter:

```yaml
---
name: plan-stress-test
description:
  Use when the user asks to stress-test, validate, critique, or find gaps and
  risks in an implementation plan.
allowed-tools: Read, Glob, AskUserQuestion, Write, Edit, TodoWrite, Bash
---
```

Changes:
- **Rename** `name` from `plan-interview` to `plan-stress-test` to avoid
  namespace collision with the `/plan-interview:plan-interview` command
- **Add** `allowed-tools` matching the command's tool set plus `Bash`

**Rename the directory:**

```bash
git mv plugins/plan-interview/skills/plan-interview plugins/plan-interview/skills/plan-stress-test
```

### 3. Slim down the command to delegate via Skill tool

**File:** `plugins/plan-interview/commands/plan-interview.md`

Replace the full duplicated instructions (lines 19-265) with a delegation body
that explicitly invokes the renamed skill via the Skill tool. Keep:

- The frontmatter (with corrected allowed-tools from Step 1)
- The `# /plan-interview:plan-interview` heading
- The `## Usage` section with examples

Replace the `## Instructions` section with:

```markdown
## Instructions

Use the Skill tool to invoke the `plan-stress-test` skill, passing `$ARGUMENTS`
as the plan file path argument.

If `$ARGUMENTS` is empty, invoke the skill without arguments -- it will
auto-detect the plan file from IDE context, project settings, or the default
plans directory.

Arguments: $ARGUMENTS
```

This eliminates ~240 lines of duplicated content. The skill holds the canonical
instructions; the command is a thin entry point.

### 4. Create plan-researcher agent

**File (new):** `plugins/plan-interview/agents/plan-researcher.md`

Frontmatter (modeled after `plugins/code-review/agents/agent-code-reviewer.md`):

```yaml
---
name: plan-researcher
description: >
  Read-only subagent that explores codebase files and modules referenced in a
  plan to gather context before a plan interview. Use when the plan-interview
  skill needs to ground its questions in actual code structure.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit, NotebookEdit
model: haiku
permissionMode: plan
maxTurns: 8
background: false
---
```

Body instructs the agent to:

1. Accept a plan file path and list of key components/files from the caller
2. For each referenced file/module:
   - If the file exists: read it, summarize purpose, public API, dependencies,
     and complexity signals
   - If the file does not exist: report it as "planned, not yet created"
3. Return a structured context summary the parent skill can use

### 5. Wire agent into SKILL.md Step 2

**File:** `plugins/plan-interview/skills/plan-stress-test/SKILL.md`

After the existing "Extract the following to guide question generation" block in
Step 2, add a new subsection:

```markdown
**Codebase context gathering** (optional):

If the "Key components" extraction identified specific file paths or module
names that exist in the codebase, use the Agent tool to invoke the
`plan-researcher` subagent:

- Set `subagent_type` to `plan-interview:plan-researcher`
- In the prompt, provide: the plan file path and the list of key
  components/files extracted above
- The agent will return a structured summary of each file's purpose, API,
  dependencies, and complexity signals
- Use this context to generate more specific, grounded interview questions
  in Step 3

If no specific file paths are mentioned in the plan, or all referenced files
are marked as "to be created," skip this step.
```

### 6. Expand marketplace tags

**File:** `.claude-plugin/marketplace.json`

Update `plan-interview` entry tags from:

```json
["planning", "interview", "stress-test", "architecture"]
```

to:

```json
["planning", "interview", "stress-test", "architecture", "validation", "plan-review", "pre-implementation"]
```

### 7. Bump version and update docs

1. **`.claude-plugin/marketplace.json`** -- change `plan-interview` version
   from `"1.4.0"` to `"1.5.0"`

2. **`plugins/plan-interview/CHANGELOG.md`** -- add v1.5.0 entry:

   ```markdown
   ## [1.5.0] - 2026-03-13

   ### Added

   - `plan-researcher` agent -- read-only Haiku subagent that explores code
     referenced in plans to ground interview questions in actual code structure
   - `allowed-tools` frontmatter field added to SKILL.md
   - `Bash` added to plan-interview command's allowed-tools (fixes rename bug)
   - Codebase context gathering step wired into SKILL.md Step 2

   ### Changed

   - Skill renamed from `plan-interview` to `plan-stress-test` to avoid
     namespace collision with the command
   - Plan-interview command slimmed to delegate to skill via Skill tool,
     eliminating ~240 lines of duplicated content
   - Marketplace tags expanded with `validation`, `plan-review`,
     `pre-implementation`
   ```

3. **`plugins/plan-interview/README.md`** -- update:
   - Rename skill reference in Components table to `plan-stress-test`
   - Add `plan-researcher` agent to Components table
   - Add brief Agent section describing what it does
   - Update any skill invocation examples to use the new name

## Execution Order

1. Step 1 -- Fix `Bash` in command allowed-tools (bug fix, no dependencies)
2. Step 2 -- Rename skill directory + update frontmatter
3. Step 5 -- Wire agent invocation into SKILL.md Step 2
4. Step 3 -- Slim down command to Skill tool delegation (depends on skill rename)
5. Step 4 -- Create plan-researcher agent
6. Step 6 -- Update marketplace tags
7. Step 7 -- Version bump, changelog, README (always last)

## Verification

1. Load plugin locally:
   `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Run `/plan-interview:plan-interview` on an existing plan file -- confirm it
   invokes the `plan-stress-test` skill and interview workflow executes
3. Verify skill auto-activates: ask "stress-test my plan" without slash command
4. Check `/agents` shows `plan-researcher` agent
5. Validate marketplace.json:
   `grep '"version"' .claude-plugin/marketplace.json | grep plan-interview`
6. Confirm no namespace collision between command and skill

## Decisions

- **No `settings.json`**: Per docs, only `agent` settings are supported. The
  `plansDirectory` config belongs in `.claude/settings.json`, not the plugin.
- **No `argument-hint` on SKILL.md**: Skills auto-activate from intent;
  argument hints are a command-only UI pattern.
- **No `model` on SKILL.md**: Should inherit the user's chosen model.
- **No `question-framework.md`**: Dropped per interview finding -- SKILL.md is
  ~320 lines, well under the 500-line threshold. Extraction would add a file
  and Read call for minimal benefit. Revisit if the skill grows beyond 500
  lines.
- **`user-invocable`/`disable-model-invocation`**: Defaults are correct (both
  allow auto-activation AND manual invocation).

## Next Steps

- Consider adding `memory: project` to the plan-researcher agent once it proves
  useful, so it builds codebase knowledge across sessions
- Evaluate whether `plan-hygiene` and `review-rename-plans` commands should also
  be converted to skills for auto-activation
- Consider a `PostToolUse` hook that auto-runs plan-hygiene after plan mode exits
- If SKILL.md grows beyond 500 lines, extract question-framework.md as a
  supporting file

## Interview Summary

### Key Decisions Confirmed

1. **Command delegation**: Use an explicit Skill tool call (not implicit reference)
2. **Agent model**: Haiku is sufficient for read-only exploration
3. **Missing files**: Agent reports as "planned, not yet created"
4. **Cache**: Version bump 1.4.0 to 1.5.0 handles invalidation
5. **Bash scope**: Broad access acceptable; user permission mode governs
6. **Skill rename**: `plan-interview` to `plan-stress-test` to avoid collision
7. **Drop question-framework.md**: Premature at ~320 lines; keep inline

### Resolved Risks

- **Skill rename cascade**: Accounted for in Steps 2, 3, and 7 with all
  affected files listed
- **Command delegation syntax**: Step 3 now specifies explicit Skill tool
  invocation
- **Agent wiring**: Step 5 provides exact instructions for SKILL.md update
- **review-rename-plans.md**: Already has `Bash` -- no change needed
