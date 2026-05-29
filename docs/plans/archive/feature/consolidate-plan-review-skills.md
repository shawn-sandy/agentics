---
status: completed
type: feature
created: 2026-05-20
---

# Consolidate plan-interview Skill and plan-review-agents Overlap

## Context

Two plugins both review plans before implementation begins, producing overlapping outputs
that confuse users about which to reach for:

- **plan-interview** (v2.1.0) — stress-tests implementation plans via structured Q&A rounds
  (Technical, UX, Accessibility, Edge Cases), with a `deep-grill` for decision-branch walking.
  Also owns lifecycle management: status tracking, archival, documentation, HTML export,
  file hygiene. Runs as a single agent (Claude itself as interviewer).

- **product-plans** (v3.4.0) — improves product plans/PRDs via a parallel panel of six
  specialist agents (PM, Lead Dev, UX, Frontend, A11y, Security). Produces a 15-section
  report, applies inline edits to the source file, and emits an HTML review artifact.

### Where They Actually Overlap

| What | plan-interview | plan-review-agents |
|------|---------------|-------------------|
| Technical gaps & trade-offs | Round 1 (always) | Lead Developer reviewer |
| UX / user flows | Round 2a (if UI) | UX Designer reviewer |
| Accessibility | Round 2b (if UI) | Accessibility Expert reviewer |
| Edge cases | Round 3 (if complex) | Distributed across roles |
| Structured findings summary | ✅ | ✅ 15-section report |
| Optional inline edits to plan | ✅ (appended summary) | ✅ (applied edits + appended Panel Review) |
| HTML output | ✅ markdown-to-html (general) | ✅ `*-review.html` artifact |
| Auto-activation conflicts | "stress-test/validate/critique plan" | "improve/optimize/update plan" |
| File resolution logic | 5-priority pattern | 5-priority pattern (identical) |
| YAML frontmatter parsing | ✅ | ✅ |

**Root cause:** plan-interview's review scope is a functional subset of product-plans, but
plan-interview is faster (single-agent), more interactive (Q&A per round), and deeper on
technical decision branches (deep-grill). product-plans is slower, multi-agent, and broader
(PM strategy, security, frontend specifics). Neither is strictly better — they serve different
moments and plan types.

**Additional secondary overlap** (less critical):
- `agent-reviewer` and `skill-reviewer` share the same 5-dimension scoring rubric and
  report structure — but are correctly separated by file type (agents vs. SKILL.md).
- Both plugins have independent `html-spec.md` files with overlapping theme/layout patterns.

---

## Implementation Plan: Two Phases

### Phase 1 — Reframe via Tiers (Option A)

**Goal:** Eliminate trigger-phrase conflicts and give users a clear "which to use" signal.
No structural changes — safe to ship as a standalone PR.

**Changes:**

1. **`kit/plugins/plan-interview/skills/plan-interview/SKILL.md`**
   - Narrow the `description` to explicitly scope to *implementation plans* (what files to create/modify, technical approach):
     *"Use when you need fast, single-agent technical validation of an implementation plan before coding begins…"*
   - Adjust auto-activation trigger phrases to avoid overlap:
     - Keep: "stress-test plan", "interview plan", "validate implementation plan", "find technical gaps", "critique implementation plan"
     - Remove: any phrases that overlap with "improve plan" / "optimize plan"
   - Add a Step 5.5 (after summary): if the plan looks like a product plan / PRD (PM scope, user stories, business goals), suggest `product-plans:plan-review-agents` as the better tool.

2. **`kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`**
   - Narrow the `description` to explicitly scope to *product plans and PRDs*:
     *"Use when you need comprehensive multi-role review of a product plan, PRD, or feature proposal…"*
   - Adjust trigger phrases: keep "improve/optimize/update plan" but add "product plan", "PRD", "feature proposal"; remove any phrases that could fire on a technical implementation plan.
   - Add a note after Step 9 output: if the plan is a technical implementation plan, `plan-interview:plan-interview` provides faster single-agent validation.

3. **`kit/plugins/plan-interview/README.md`** and **`kit/plugins/product-plans/README.md`**
   - Add a shared **"Which tool to use?"** section to both READMEs:

     | Situation | Use |
     |-----------|-----|
     | Technical implementation plan (files, code, APIs) | `plan-interview` |
     | Product plan, PRD, feature proposal | `product-plans` |
     | Comprehensive stakeholder review of any plan | `product-plans` |
     | Quick pre-coding gap check (single agent) | `plan-interview` |

4. **`kit/plugins/plan-interview/hooks.json`** — no change (ExitPlanMode hook correctly suggests plan-interview after planning).

5. **HTML output from plan-interview (new):**
   - After Step 6 (summary compiled), plan-interview skill invokes `markdown-to-html` skill with
     `--mode=plan` to generate `<plan-stem>-interview.html`.
   - This HTML becomes the shared artifact that product-plans can subsequently amend.
   - product-plans' Step 8 (HTML artifact generation) is updated to detect an existing
     `*-interview.html` and append the Panel Review section to it (as a new `<section>` after the
     main plan content) rather than creating a net-new `*-review.html`. If no prior HTML exists,
     it creates one as before.
   - This creates a single living HTML document: plan interview findings → panel review findings,
     accumulated in order.

6. **Version bumps:** PATCH bump for both plugins (description/metadata correction).

**Effort:** XS — 4 file edits + 2 CHANGELOG entries.  
**Risk:** Zero functional regression. Trigger-phrase changes could affect auto-activation; verify with spot-tests.

---

### Phase 2 — plan-interview Skill Becomes a Router (Option C)

**Goal:** Single activation surface — users never need to know which plugin to reach for.
Builds on Phase 1's tier definitions. Ships as a separate PR.

**Changes:**

1. **`kit/plugins/plan-interview/skills/plan-interview/SKILL.md`** — rewrite Steps 0–3:
   - **Step 1 (resolve):** unchanged — resolve plan file via 5-priority pattern.
   - **Step 2 (classify):** read the plan and classify it:
     - **Implementation plan** signals: `## Steps`, `## Files to Create/Modify`, code blocks with file paths, backtick identifiers, technical stack references.
     - **Product plan / PRD** signals: `## User Stories`, `## Success Metrics`, `## Business Goals`, `## Personas`, `## Requirements`, PM-language keywords.
     - Mixed / ambiguous → ask user.
   - **Step 3 (route):**
     - If implementation plan (or user confirms) → proceed with current interview logic (Rounds 1–3).
     - If product plan → say *"This looks like a product plan. Routing to the cross-functional panel review…"* and invoke:
       ```
       Skill(skill: "product-plans:plan-review-agents", args: "<resolved-path>")
       ```
     - If ambiguous → `AskUserQuestion`: *"Quick 3-round technical interview, or full cross-functional panel (6 reviewers)?"*
   - Steps 4–6 (interview rounds, summary) are unchanged.
   - Add `Skill` and `ToolSearch` to `allowed-tools` frontmatter (needed to invoke the cross-plugin skill).

2. **`kit/plugins/plan-interview/commands/plan-interview.md`** — add a `--quick` flag that skips
   classification and goes directly to the interview (escape hatch for users who always want the technical review).

3. **`kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`** — add a note that this skill
   can also be reached via `plan-interview:plan-interview` routing; no workflow changes needed.

4. **`kit/plugins/plan-interview/README.md`** — update to describe the routing behavior.

5. **Version bumps:** MINOR bump for plan-interview (new routing behavior); PATCH bump for product-plans (doc note only).

**Effort:** S — 2 file edits with moderate complexity in plan-interview SKILL.md; 2 minor edits elsewhere.  
**Risk:** Cross-plugin `Skill` invocation — verify that `Skill` tool can call across plugin namespaces at runtime. If not supported, fallback: emit a message instructing the user to invoke `product-plans:plan-review-agents` manually.

---

## Recommendation

Ship **Phase 1** immediately — it's low-risk and resolves the most visible confusion (conflicting triggers, no "which to use" guidance). Validate that the trigger-phrase narrowing behaves correctly before committing to Phase 2.

Ship **Phase 2** once Phase 1 is stable — the router makes the two-tier system invisible to users who don't know (or don't care) which plugin owns what.

---

## Critical Files

| File | Role |
|------|------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Main review skill — trigger phrases, 6-step workflow |
| `kit/plugins/plan-interview/skills/deep-grill/SKILL.md` | Decision branch walk — overlaps with Lead Dev reviewer |
| `kit/plugins/plan-interview/hooks.json` | ExitPlanMode hook — currently points to plan-interview skill |
| `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md` | 6-agent panel skill — trigger phrases, 9-step workflow |
| `kit/plugins/product-plans/skills/plan-review-agents/references/role-prompts.md` | Spawn directives for all 6 reviewers |
| `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md` | Overlaps most with deep-grill |
| `.claude-plugin/marketplace.json` | Versions for both plugins; update on any bump |

## Verification

After implementing any option:
1. `Verify activation triggers don't conflict`: Speak each trigger phrase and confirm only the intended skill activates.
2. `Test cross-reference links`: If Option A, confirm the suggested cross-reference at end of each review leads the user correctly.
3. `Test ExitPlanMode hook`: After exiting plan mode, confirm the hook suggestion points to the correct skill.
4. `Run validate-plugin on both`: `/validate-plugin plan-interview` and `/validate-plugin product-plans` (or merged plugin).
5. `Check marketplace.json`: Verify version bumps and descriptions are updated and JSON is valid.
