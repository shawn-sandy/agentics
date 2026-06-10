# Plan Review Synthesis Template

This template is used to structure the team's synthesis of reviewer findings and the edits to apply.

## Executive Summary

<One paragraph synthesizing the team's overall assessment of the plan: is it sound, sound with revisions, or should it be rethought? Note any key conflicts or recurring concerns across reviewers.>

---

## Role-by-Role Findings

### Architecture Review

<Summarize the Architecture Reviewer's findings: key concerns, recommendations, and whether the design is sound.>

### Completeness Review

<Summarize the Completeness Reviewer's findings: key gaps, recommendations, and whether all steps are specific enough.>

### Testability Review

<Summarize the Testability Reviewer's findings: test coverage gaps, recommendations, and whether acceptance criteria are verifiable.>

### Risk Review

<Summarize the Risk Reviewer's findings: key risks, mitigations, and overall risk level.>

### Conventions Review

<Summarize the Conventions Reviewer's findings: style/naming/organization issues, recommendations, and fit with project patterns.>

### UX Review *(if spawned)*

<Summarize the UX Reviewer's findings: user flow clarity, error handling, interaction design. Include only if UI signals were detected.>

### Accessibility Review *(if spawned)*

<Summarize the Accessibility Reviewer's findings: WCAG AA compliance gaps, keyboard/screen reader support, semantic HTML. Include only if UI signals were detected.>

---

## Agreements & Conflicts

<Document where multiple reviewers flagged the same concern (amplify as "confirmed concern"), and where recommendations contradicted each other (explain the tradeoff and recommend a resolution).>

---

## Highest-Risk Issues

<Distilled list of the most critical concerns across all reviewers, in priority order. Each entry ties back to the reviewer who surfaced it and recommends how to address it.>

---

## Inline Edits to Apply

| Target Element | Action | New Content / Notes | Source / Rationale |
|---|---|---|---|
| `.objective-card` | edit | <New or revised objective statement if needed.> | Architecture — objective conflates two separate deliverables |
| `#criteria-list li#ac1` | edit | <Revised acceptance criterion if needed.> | Testability — criterion ac1 is not falsifiable as written |
| `.step-card #step-N .step-why` | edit | <Clarified "why" for step N if needed.> | Completeness — step N states what but not why |
| `.step-card #step-N .verify-body` | edit | <More specific verification instructions for step N if needed.> | Completeness — step N's verification is too vague to confirm success |
| `#criteria-list` | append | `<li id="ac-new">New acceptance criterion</li>` | Risk — no criterion covers the rollback path |
| `.step-card:nth-child(N)` | insert after | `<div class="step-card">... new step ...</div>` | Completeness — a required step is missing between steps N and N+1 |
| `.verification-section` | edit | <Revised end-to-end verification if needed.> | Testability — end-to-end verification never exercises the new flow |

**Notes:**
- Each row is applied as a separate `Edit` operation in order.
- `action: edit` — replace the targeted element's content.
- `action: append` — add content to the end of the targeted element.
- `action: insert after` — insert a new sibling immediately after the named anchor heading or element.
- All inserted content must be HTML-escaped (e.g., `<` becomes `&lt;`).
- Never modify `<style>` or `<script>` blocks.
- Skip rows whose target element cannot be matched in the source plan.
- The `Source / Rationale` column names the originating reviewer plus a one-line why for each edit; it feeds the per-finding triage in Step 6b — Walkthrough & Analysis.

### Triage Outcome

<Filled by Step 7 Pass 2 after the Step 6b walkthrough. Records the developer's decision for every proposed edit.>

**Accepted** (applied as-is):

- <Target element and finding for each edit the developer accepted unchanged.>

**Modified** (applied with the developer's revised content):

- <Target element, finding, and the revised content that was applied in place of the proposed content.>

**Rejected** (recorded only, never applied):

- <Target element, finding, and the developer's reason for declining the edit.>

<If the walkthrough was skipped, state which bypass applied — `--skip-analysis`, background mode, "Apply all", or review-only mode — and that all proposed edits were applied (or none, for review-only).>

---

## Revised Plan

<The full revised plan after all inline edits have been applied. This is the source of truth for what the implementer will see next. Copy it from the edited HTML, not a manual summary.>
