# Design Patterns for Claude Skills

Reference for the `planning-skills` skill. Based on patterns codified in Anthropic's "The Complete Guide to Building Skills for Claude" (Jan 2026).

---

## Sequential / Pipeline Pattern

**Use when:** Users need a multi-step process executed in a specific order. Each step depends on the output of the previous step.

**Examples:**
- Sprint planning: Fetch status → Analyze capacity → Suggest priorities → Create tasks
- Code review: Resolve file → Read and measure → Score dimensions → Report → Offer fixes
- Onboarding: Collect info → Validate → Provision accounts → Send welcome

**Structure signals:**
- Numbered steps (`Step 1`, `Step 2`, ...)
- `TodoWrite` for progress tracking
- "Follow these steps exactly." (rigid freedom level)
- Rollback or error-handling instructions between steps

**Recommended SKILL.md body outline:**

```markdown
## Overview
[What the skill does]. Follow these steps exactly.

## Table of Contents
[If ≥100 lines]

## Step 1 — [First action]
[Instructions]

## Step 2 — [Second action]
[Instructions, may reference output from Step 1]

## Step N — [Final action]
[Instructions, present results]
```

**Key considerations:**
- Include error handling between steps — what happens if a step fails?
- Use `TodoWrite` to track progress through long pipelines
- Consider rollback instructions for destructive steps

---

## Orchestrator Pattern

**Use when:** The workflow coordinates multiple services, APIs, or tools. The skill acts as a conductor rather than doing all the work itself.

**Examples:**
- Deploy workflow: Build → Test → Push to staging → Notify Slack → Update Linear
- Data pipeline: Fetch from API → Transform → Write to database → Generate report
- Cross-service sync: Read Figma → Generate components → Push to repo → Open PR

**Structure signals:**
- MCP tool calls or API integrations
- Phase separation markers (`## Phase 1: Gather`, `## Phase 2: Process`)
- Service-specific configuration sections
- Retry or fallback logic for external calls

**Recommended SKILL.md body outline:**

```markdown
## Overview
[What the skill orchestrates]. Adapt these principles to the situation.

## Prerequisites
[Required services, API keys, MCP connections]

## Phase 1 — [Gather / Input]
[Which services to query, what data to collect]

## Phase 2 — [Process / Transform]
[How to combine and process the gathered data]

## Phase 3 — [Output / Distribute]
[Where to send results, what to notify]

## Error Handling
[Fallback behavior for each service]
```

**Key considerations:**
- List all external dependencies in a Prerequisites section
- Include fallback behavior for each external service
- Separate service-specific config from workflow logic
- Note which MCP tools are required

---

## Iterative / Refinement Pattern

**Use when:** The output quality improves through multiple passes. First-draft output is insufficient for the use case.

**Examples:**
- Technical writing: Draft → Expert review → Revise → Final polish
- Code generation: Generate → Test → Fix failures → Re-test until passing
- Design review: Initial assessment → Targeted deep-dives → Consolidated report

**Structure signals:**
- Draft → Review → Revise loops
- Quality gates ("Score must be ≥8/10 before proceeding")
- Revision limits ("Maximum 3 revision rounds")
- Before/after examples showing improvement

**Recommended SKILL.md body outline:**

```markdown
## Overview
[What the skill produces]. Follow these steps exactly.

## Step 1 — Generate Initial Draft
[Instructions for first pass]

## Step 2 — Evaluate Quality
[Quality criteria, scoring rubric, or checklist]

## Step 3 — Refine
[Instructions for improving based on evaluation]
[Loop back to Step 2 if quality threshold not met]

## Step 4 — Finalize
[When to stop iterating, how to present final output]

## Quality Thresholds
[Explicit criteria for "good enough"]
```

**Key considerations:**
- Set a maximum iteration count to prevent infinite loops
- Define explicit quality thresholds (not "until it looks good")
- Include at least one before/after example
- Distinguish between "must fix" and "nice to have" in the evaluation step

---

## Adaptive Pattern

**Use when:** The same goal requires different approaches depending on context — file type, project structure, user environment, or tool availability.

**Examples:**
- Code formatting: Different linters for JS vs. Python vs. Rust
- Testing: Unit tests for utilities, integration tests for API routes, E2E for UI
- Documentation: README for libraries, API docs for services, tutorials for frameworks

**Structure signals:**
- Conditional branching ("If the file is `.tsx`, then...", "If Python project, then...")
- File-type or environment detection logic
- Decision trees or lookup tables
- Shared output format despite different processing paths

**Recommended SKILL.md body outline:**

```markdown
## Overview
[What the skill handles]. Adapt these principles to the situation.

## Step 1 — Detect Context
[How to determine which branch to follow]
[File type detection, project structure analysis, etc.]

## Branch A — [Context 1]
[Instructions specific to this context]

## Branch B — [Context 2]
[Instructions specific to this context]

## Branch C — [Context 3]
[Instructions specific to this context]

## Common Output Format
[Shared format regardless of which branch was taken]
```

**Key considerations:**
- Detection logic must be unambiguous — no overlapping branches
- Document what happens when context is unclear (ask the user)
- Keep the output format consistent across branches
- Consider a "default" branch for unrecognized contexts

---

## Choosing a Pattern

Use this decision tree to recommend a pattern:

1. **Does the workflow span multiple external services or APIs?**
   - Yes → **Orchestrator**
2. **Does output quality improve with multiple passes?**
   - Yes → **Iterative / Refinement**
3. **Does the same goal require different approaches based on context?**
   - Yes → **Adaptive**
4. **Is it a multi-step process in a fixed order?**
   - Yes → **Sequential / Pipeline**

If a skill combines patterns (e.g., a Sequential pipeline with an Adaptive sub-step), use the dominant pattern for overall structure and note the sub-pattern within the relevant step.

If the planned skill serves two distinct user intents that rarely overlap, consider a **Skill Pack** (multiple skills in one plugin) instead of a single skill. See the Skill Packs section in `best-practices.md` for guidance on when and how to split.

---

## Pattern Combinations

Complex skills may combine patterns. Common combinations:

| Primary | Secondary | Example |
|---------|-----------|---------|
| Sequential | Adaptive | Code review pipeline that adapts checks per language |
| Orchestrator | Iterative | Deploy workflow that retries failed health checks |
| Sequential | Iterative | Plan generation with revision rounds between steps |
| Adaptive | Sequential | Context detection followed by context-specific pipeline |

When combining, structure the SKILL.md around the primary pattern and embed the secondary pattern within the relevant step.
