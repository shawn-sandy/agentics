# Plan: Improve skill-reviewer/reviewing-skills Against Official Best Practices

## Context

The `reviewing-skills` SKILL.md and its reference files were aligned with an earlier version of Anthropic's skill authoring guide. The official guide at `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` contains additional patterns, anti-patterns, and guidance not yet reflected in the audit criteria.

## Files to Modify

- `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md`
- `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md`
- `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md`
- `plugins/skill-reviewer/README.md`
- `plugins/skill-reviewer/.claude-plugin/plugin.json` (version bump)
- `.claude-plugin/marketplace.json` (version sync)
- `plugins/skill-reviewer/CHANGELOG.md`

## Changes

### 1. Fix Live Fetch URL in `SKILL.md`

- Change `https://code.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` → `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`

### 2. Update Quick Reference Checklist in `SKILL.md`

Add to **Body** section:
- `[ ]` Complex workflows use a checklist pattern (copy-and-check-off steps)
- `[ ]` No "options without a default" pattern (pick one, mention alternatives)
- `[ ]` No assumed tool/package availability without explicit install instructions

Add to **Structure** section:
- `[ ]` Feedback loops present for quality-critical or iterative tasks

Add new **Scripts** section (for skills with executable code):
- `[ ]` MCP tools referenced with fully qualified `ServerName:tool_name` format
- `[ ]` No unexplained magic numbers (all constants documented)
- `[ ]` Error handling explicit — scripts handle failures rather than punting to Claude
- `[ ]` Required packages listed with install instructions

### 3. Update `references/best-practices.md`

Add the following new sections (after existing content):

**a. New content patterns:**
- Checklist workflow pattern — copy-and-check-off for complex multi-step tasks
- Feedback loop pattern — run validator → fix → repeat cycle
- Template pattern — strict (`ALWAYS use this template`) vs flexible (`use as default, adapt as needed`)
- Conditional workflow pattern — decision branches based on task type
- "Old patterns" section for deprecated content (use `<details>` tag)

**b. Token budget consciousness:**
- Only add context Claude doesn't already have
- Challenge each paragraph: does Claude need this explanation?
- Concise example vs verbose example (from official docs)

**c. Script quality rules (new subsection under Anti-patterns):**
- Solve, don't punt — scripts must handle error conditions, not fail and let Claude improvise
- No voodoo constants — all numeric values must be justified in comments
- Clear execution intent — distinguish "Run this script" from "Read this script as reference"
- No assumed installations — list required packages with install commands

**d. MCP tool references:**
- Always use `ServerName:tool_name` format to avoid "tool not found" errors

**e. Evaluation-driven development (new section):**
- Build evaluations before writing extensive documentation
- Evaluation structure: query + expected_behavior + files
- Iterative refinement cycle: Claude A (author) → Claude B (agent using skill) → observe → refine

**f. Update line count thresholds to match official docs:**
- Official doc says "under 500 lines for optimal performance" — adjust `Ideal` threshold in the table

**g. Update TOC at top of `best-practices.md`:**
- Add entries for all new sections (feedback loop, template pattern, conditional workflow, token budget, script quality, MCP tools, evaluation-driven development)

### 4. Update `references/audit-steps.md`

**Dimension 2 (Body Quality):** Update line count thresholds:
- Change `<400` Ideal → `<500` Ideal (align with official 500-line threshold)
- Remove `400–499` Warning tier — no longer a distinct band
- Change 2pts threshold from `<400 lines AND <3,000 words` → `<500 lines AND <3,000 words`
- 0pts threshold remains: `≥500 lines or ≥5,000 words`

**Dimension 3 (Structure):** Add check:
- Feedback loop present for iterative/quality-critical tasks (Suggestion if absent)

**Dimension 4 (Anti-patterns):** Add new entries (all apply regardless of whether skill uses scripts):

| Anti-pattern | Severity |
|---|---|
| Assumes tools/packages installed without install instructions | Warning |
| MCP tool referenced without `ServerName:` prefix | Warning |
| Script uses unexplained magic numbers (voodoo constants) | Suggestion |
| Script punts to Claude on error (no error handling) | Warning |
| Verbose over-explanation of things Claude already knows | Suggestion |

Detection rule for script-related checks: apply if skill contains a `scripts/` folder reference OR has bash/python code blocks with external tool invocations.

**Step 4 (Report):** Update Guidelines Source line:
- Replace `code.claude.com` → `platform.claude.com` in the report format template (line: `**Guidelines Source:** [Static: references/best-practices.md | Live fetch: code.claude.com | ...]`)

### 5. Update README.md

Add/update the audit scoring section to reflect:
- New anti-patterns in Dimension 4 (script checks, MCP tool format, assumed installs)
- Updated line count threshold (500 lines is now the official limit)
- Feedback loop and checklist workflow as Suggestion-level checks

### 6. Version Bump to 1.2.0

- `plugin.json`: `"version": "1.2.0"`
- `marketplace.json`: matching version for `skill-reviewer`
- `CHANGELOG.md`: add entry — note both new checks AND the scoring threshold change (`<400 → <500` Ideal threshold; skills in the 400–499 range will now score 2/2 instead of 1/2)

## Verification

1. Run the reviewing-skills skill against `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` itself — it should score well.
2. Run against a known-bad SKILL.md (e.g., one with `$ARGUMENTS`, Windows paths, assumed installs) — new anti-patterns should surface.
3. Verify the live fetch URL resolves correctly when used.
4. Confirm `plugin.json` and `marketplace.json` versions match.

## Unresolved Questions

None.

---

## Interview Summary

### Key Decisions Confirmed

- **Line count threshold**: Align with official Anthropic guidance — `<500 lines` = Ideal (2pts). Remove the conservative `<400` boundary.
- **Script anti-patterns**: Add as Warnings with score impact (reduce Dimension 4 from 2→1 if present). No conditionality — applies to all skills.
- **Workflow patterns**: Feedback loop and checklist patterns added as Suggestions only — no score impact.
- **README**: Include `plugins/skill-reviewer/README.md` in the files to modify.

### Open Risks & Concerns

1. **TOC update omitted**: `best-practices.md` TOC must be updated when new sections are added.
2. **Script detection rule missing**: Audit instructions need to define how to detect if a skill is script-based before applying script Warning checks.
3. **Scoring threshold change is backward-incompatible**: Skills scored under the old threshold will retroactively score higher. CHANGELOG should note this explicitly.
4. **Report template URL**: `audit-steps.md` has `code.claude.com` hardcoded in the Step 4 template — needs a discrete edit step.

### Recommended Plan Amendments

1. Add `plugins/skill-reviewer/README.md` to the files list
2. Add a discrete step: "Update TOC in `best-practices.md`"
3. Add a script detection rule to the Dimension 4 update instructions (check for `scripts/` folder or bash/python code blocks)
4. Call out the Step 4 report template URL change as its own bullet
5. CHANGELOG entry should note the scoring threshold change, not just "new checks added"
