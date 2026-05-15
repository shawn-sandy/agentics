# Final Report Template

The lead reproduces the fenced block below verbatim after collecting findings
from all five reviewers. Replace placeholder text inside `[brackets]`. Section
14 is omitted when the user chose review-only mode at Step 2.

Any reviewer whose section opens with `Reviewer unavailable — not assessed`
must also be named in section 1 (Executive summary) and listed as a risk in
section 3 (Highest-risk issues).

---

```markdown
## Product Plan Review — [Plan filename or title]

*Reviewed by: PM · Lead Developer · UX Designer · Frontend Engineer ·
Accessibility Expert — coordinated by Lead Coordinator*

---

### 1. Executive Summary

[2–4 sentences on overall quality, confidence level, and the final decision.
If any reviewer was unavailable, name them here: "Note: the [Role] reviewer
was unavailable; that domain was not assessed."]

---

### 2. Role-by-Role Review

#### Product Manager

[Reproduce the PM reviewer's full output schema findings here.]

#### Lead Developer

[Reproduce the Lead Developer reviewer's full output schema findings here.]

#### UX Designer

[Reproduce the UX Designer reviewer's full output schema findings here.]

#### Lead Frontend Engineer

[Reproduce the Lead Frontend Engineer reviewer's full output schema findings here.]

#### Accessibility Expert

[Reproduce the Accessibility Expert reviewer's full output schema findings here.]

---

### 3. Highest-Risk Issues

[List the top 3–5 issues across all reviewers that pose the greatest risk to
success. Pull from critical concerns and risks/blockers sections. If any
reviewer was unavailable, include "Unassessed domain: [Role] review not
conducted — [domain] risks are unknown" as a line item.]

---

### 4. Blocking Issues

[Issues that must be resolved before development can start. Include role,
issue, and why it blocks.]

---

### 5. Important but Non-Blocking Improvements

[Issues that should be addressed but will not block delivery if deferred.
Include role and recommended change.]

---

### 6. UX Recommendations

[Consolidated UX guidance from the UX Designer reviewer and any UX-adjacent
concerns from other reviewers. List as concrete, actionable items.]

---

### 7. Accessibility Requirements

[Consolidated accessibility guidance from the Accessibility Expert reviewer.
List as actionable items with WCAG success criterion references where
applicable.]

---

### 8. Frontend Implementation Considerations

[Consolidated frontend guidance from the Lead Frontend Engineer reviewer.
List as actionable items.]

---

### 9. Technical Feasibility Concerns

[Consolidated technical guidance from the Lead Developer reviewer. List as
actionable items.]

---

### 10. Open Questions Before Development

[Compile every "Questions that must be answered" item from all five
reviewers, grouped by role. Deduplicate overlapping questions.]

---

### 11. Recommended Changes to the Plan

[Concrete amendments the lead recommends based on synthesis across all five
reviewers. Write as a numbered list of specific edits to the plan, not
abstract guidance.]

---

### 12. Conflicts or Tradeoffs Between Reviewer Recommendations

[Name any cases where reviewer recommendations conflict or create tradeoffs.
For each conflict, explain the tradeoff and recommend how to resolve it.
If no conflicts exist, write "No conflicts identified."]

---

### 13. Final Decision

**[Approve / Approve with revisions / Reject]**

[One or two sentences explaining the decision, the key condition(s) for
approval (if applicable), and which issues are blocking vs non-blocking.]

---

### 14. Revised Product Plan

*(Omit this section if the user chose review-only mode at Step 2.)*

[Write a complete, revised version of the product plan incorporating all
recommended changes from section 11. The revised plan replaces the original
in spirit — it is not a diff. Write it as a standalone plan the development
team can act on directly.]
```
