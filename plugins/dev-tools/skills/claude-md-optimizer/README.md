# claude-md-optimizer Skill

Audits and optimizes `CLAUDE.md` files against Claude Code best practices. Also activates when Claude appears to be ignoring instructions — a common symptom of a poorly structured `CLAUDE.md`.

## Overview

The `claude-md-optimizer` skill runs a structured 6-step audit of your `CLAUDE.md` file, scores it across six dimensions, and surfaces specific recommendations. Generating an optimized version and writing it to disk are opt-in steps.

## Activation

**Phrases that activate the skill:**
```
"Optimize my CLAUDE.md"
"Audit my CLAUDE.md"
"Review my CLAUDE.md"
"Clean up my CLAUDE.md"
"Claude is ignoring my instructions"
"Claude isn't following the rules in CLAUDE.md"
"Why is Claude behaving inconsistently?"
```

The last three triggers are diagnostic — if Claude is ignoring instructions, the most common cause is context overflow from a bloated `CLAUDE.md`, not missing instructions.

## File Resolution

The skill determines which file to audit using this priority order:

1. **Explicit path** — a path you provide in your message (e.g., `"Audit ~/projects/myapp/CLAUDE.md"`)
2. **Project-level file** — `$PWD/CLAUDE.md` in the current working directory
3. **Global file** — `~/.claude/CLAUDE.md`

The skill tells you which file it will audit before proceeding. If no file is found and no path was given, it stops and asks you to provide one.

## 6-Dimension Scoring

The audit scores each dimension 0, 1, or 2. Maximum total: **12 points**.

| Dimension | What it checks | Max |
|-----------|---------------|-----|
| **Instruction Budget** | ~100–150 instructions fit Claude's context allocation; too many causes silent overflow | 2 |
| **Section Quality** | Presence of 5 key sections: overview, tech stack, common commands, folder structure, conventions | 2 |
| **80% Rule Compliance** | Only content relevant to 80%+ of sessions belongs here (not deployment runbooks, onboarding, one-offs) | 2 |
| **Progressive Disclosure** | Complex reference content delegated to separate files rather than embedded inline | 2 |
| **Safety & Hygiene** | No secrets, no linter-replaceable rules, no facts Claude can infer from the codebase | 2 |
| **Structure & Navigability** | Clear `##` heading hierarchy, no contradictions, `CLAUDE.md.local` pattern considered | 2 |

## Grading Scale

| Total Score | Grade |
|-------------|-------|
| 10–12 | Optimized |
| 7–9 | Functional |
| 4–6 | Needs work |
| 0–3 | Rewrite |

## Output Format

The skill produces a structured report:

```
## CLAUDE.md Audit Report

File: [path audited]
Lines: [n] | Estimated instructions: [n ± 30–50]

### Scores
| Dimension              | Score | Max |
|------------------------|-------|-----|
| Instruction Budget     | [n]   | 2   |
| ...                    | ...   | ... |
| Total                  | [n]   | 12  |

Grade: [Optimized / Functional / Needs work / Rewrite]

### Critical Issues
[Secrets found, dimensions scoring 0 — in priority order]

### Per-dimension findings
[One bullet per dimension with specific observations]

### Top 3 Recommendations
[Highest-impact changes, in order]
```

## Opt-in Actions

After presenting the report, the skill offers two opt-in steps:

**Step 5 — Generate optimized version:**
The skill asks if you want an optimized `CLAUDE.md` generated in the chat (as a code block, not written to disk). The optimized version:
- Removes credentials (replaced with `[REDACTED - move to .env]`)
- Moves 80%-rule violations to a `## Suggested Move to Separate Files` section
- Condenses padded sections
- Adds stub headings for missing key sections
- Preserves your wording and intent

**Step 6 — Write to disk:**
After showing the optimized version, the skill asks for a second explicit confirmation before overwriting your file. It will remind you to back up first.

## Scope

- Audits **only the specified file** — does not scan the entire project
- Does **not rewrite** without explicit confirmation (Steps 5 and 6 are always opt-in)
- Does **not add** instructions that weren't in the original file (except missing section stubs)
- Evaluates `CLAUDE.md` structure only — not plugin manifests, commands, or other config files

## Tips

- A shorter `CLAUDE.md` is almost always better than a longer one
- Both your global (`~/.claude/CLAUDE.md`) and project-level (`./CLAUDE.md`) files are loaded — their **combined** instruction count matters
- The `CLAUDE.md.local` pattern lets individual developers add machine-specific instructions without modifying the shared file
- If Claude starts ignoring instructions after the file grows, run this skill before adding more instructions
