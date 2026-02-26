# Plan: Add Detailed READMEs for Each Skill

## Context

The `dev-tools` plugin has 3 skills (`code-review`, `claude-md-optimizer`, `plan-interview`), but none have skill-level README files. The plugin-level `README.md` also only documents `code-review` — the other two skills are missing from the features list, plugin structure tree, and components section.

This plan creates a README for each skill directory and fixes the plugin-level README gaps.

---

## Files to Create

### 1. `plugins/dev-tools/skills/code-review/README.md`

Content outline:
- **Overview** — automatic code review skill; when it activates
- **Activation** — natural language triggers ("review this code", "check for bugs", "is this secure?")
- **What it reviews** — 4 dimensions: Code Quality, Potential Bugs, Security, Best Practices (with sub-bullet detail)
- **Output format** — Summary / Critical Issues / Improvements / Positive Observations
- **Examples** — sample activation phrases and expected output shape
- **Scope** — what the skill does NOT do (full codebase scans, style-only nitpicks)
- **Tips** — how to phrase requests for best results

### 2. `plugins/dev-tools/skills/claude-md-optimizer/README.md`

Content outline:
- **Overview** — audits CLAUDE.md files against best practices; also triggers when Claude is ignoring instructions
- **Activation** — triggers ("optimize my CLAUDE.md", "audit CLAUDE.md", "Claude is ignoring my instructions")
- **File resolution** — how the skill picks which CLAUDE.md to audit (explicit path > project > global)
- **6-dimension scoring** — table summarizing all 6 dimensions and max scores
- **Grading scale** — Optimized / Functional / Needs work / Rewrite
- **Output format** — scored report, per-dimension findings, top 3 recommendations
- **Opt-in actions** — generating an optimized version (Step 5) and writing to disk (Step 6)
- **Scope** — only audits the specified file; does not rewrite without confirmation
- **Tips** — CLAUDE.md.local pattern, shorter is better, combined file counts

### 3. `plugins/dev-tools/skills/plan-interview/README.md`

Content outline:
- **Overview** — stress-tests implementation plans via structured interview rounds before coding starts
- **Activation** — triggers ("stress-test this plan", "interview my plan", "find gaps in this plan")
- **NOT for** — quick approvals or sign-offs
- **Plan file resolution** — 5-step priority order (explicit path > open file > project config > global config > fallback)
- **Interview rounds** — table of all rounds (R1 Technical, R2a UX, R2b Accessibility, R3 Edge Cases) and when they run
- **Scope triggers** — short (1 round), medium (2 rounds), complex (3 rounds); UI signals always add Round 2
- **Output format** — Plan Interview Summary (Key Decisions / Open Risks / Next Steps / Simplification Opportunities)
- **Opt-in** — appending summary to the plan file
- **Scope** — does not approve plans; surfaces risks only
- **Tips** — what makes a good plan for interviewing

---

## Files to Modify

### 4. `plugins/dev-tools/README.md`

Changes needed:
- **Features > Skills** — add `claude-md-optimizer` and `plan-interview` entries (currently only `code-review` is listed)
- **Plugin Structure tree** — add `claude-md-optimizer/` and `plan-interview/` under `skills/`
- **Components section** — add skill documentation blocks for `claude-md-optimizer` and `plan-interview`

---

## Verification

1. Confirm all 3 README files exist:
   ```
   ls plugins/dev-tools/skills/*/README.md
   ```
2. Confirm the plugin README lists all 3 skills in the Features and Components sections
3. Confirm the Plugin Structure tree shows all 3 skill directories
