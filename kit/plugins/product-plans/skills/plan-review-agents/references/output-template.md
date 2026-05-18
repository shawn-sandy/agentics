# Final Report Template

The lead reproduces the fenced block below verbatim after collecting findings
from all six reviewers. Replace placeholder text inside `[brackets]`.

**Plan improvement flow:** Section 12 drives the specific improvements. Section
15a is the structured inline-edits table that Step 7 applies directly to the
source plan. Sections 15a and 15b are both omitted when the user chose
review-only mode at Step 2.

**Rejection flow:** When the final decision is `Reject`, section 14 includes
two additional subsections — `#### Rejection Summary` and
`#### Remediation Prompt` — gated by HTML comments (`<!-- BEGIN reject-only -->`
/ `<!-- END reject-only -->`). The remediation prompt has two variants (interactive
and background); select the one matching `mode` from Step 0. When the decision is
`Approve` or `Approve with revisions`, omit everything between the reject-only
comments.

Any reviewer whose section opens with `Reviewer unavailable — not assessed`
must also be named in section 1 (Executive summary) and listed as a risk in
section 3 (Highest-risk issues).

The report's primary deliverable is an improved plan. Sections 12 and 15a
must be filled with enough specificity to drive concrete file edits.

**Fence convention:** The outer fence uses 5 backticks so that inner 3-backtick
blocks (such as the remediation prompt's `` ```text `` fence) nest safely per
CommonMark spec.

---

`````markdown
## Product Plan Review — [Plan filename or title]

*Reviewed by: PM · Lead Developer · UX Designer · Lead Frontend Engineer ·
Accessibility Expert · Security Expert — coordinated by Lead Coordinator*

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

#### Security Expert

[Reproduce the Security Expert reviewer's full output schema findings here.]

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

### 9. Security Requirements

[Consolidated security guidance from the Security Expert reviewer. List as
actionable items, noting any OWASP Top 10 categories or compliance obligations
where applicable.]

---

### 10. Technical Feasibility Concerns

[Consolidated technical guidance from the Lead Developer reviewer. List as
actionable items.]

---

### 11. Open Questions Before Development

[Compile every "Questions that must be answered" item from all six
reviewers, grouped by role. Deduplicate overlapping questions.]

---

### 12. Recommended Changes to the Plan

[Concrete amendments the lead recommends based on synthesis across all six
reviewers. Write as a numbered list of specific edits to the plan, not
abstract guidance. When `output_mode = review + update plan in place`, every
item here must have a corresponding row in section 15a — use `insert after`
for new sections rather than routing anything to 15b only. In review-only
mode, sections 15a and 15b are omitted; this list serves as the improvement
record for the reader.]

---

### 13. Conflicts or Tradeoffs Between Reviewer Recommendations

[Name any cases where reviewer recommendations conflict or create tradeoffs.
For each conflict, explain the tradeoff and recommend how to resolve it.
If no conflicts exist, write "No conflicts identified."]

---

### 14. Final Decision

Final decision: **[Approve / Approve with revisions / Reject]**

[One or two sentences explaining the decision, the key condition(s) for
approval (if applicable), and which issues are blocking vs non-blocking.]

<!-- BEGIN reject-only — include only when the final decision is Reject -->

#### Rejection Summary

[Consolidated list of blocking issues and critical concerns that drove the
rejection. Each item must be prefixed with the originating reviewer role in
square brackets, e.g. `[Lead Dev]`, `[Security]`.

Pull from:
- Section 4 (Blocking Issues) — reproduce verbatim, do not summarize.
- Section 3 (Highest-Risk Issues) — reproduce the items that drove the
  rejection, prefixed with reviewer role.

**When section 4 is empty:** A panel can reject without formal blocking issues
— for example, when multiple reviewers flag critical concerns that are not
individually classified as blocking but are collectively fatal. In this case,
use the highest-risk issues from section 3 as the blocking-issue equivalent
and add the note: "No individual blocking issues were filed, but the following
critical concerns were severe enough in aggregate to warrant rejection."]

#### Remediation Prompt

[A self-contained prompt the user can copy-paste into a fresh Claude session
to fix the plan and re-run the review panel. Select the variant matching
`mode` from Step 0.]

<!-- Interactive mode variant (mode = interactive): -->
```text
The plan at <plan-path> was rejected by the review panel. Fix the following
issues, then re-run the review:

## Blocking issues
[Reproduce every item from section 4 — or section 3 critical concerns if
section 4 is empty — with reviewer role prefix]

## Critical concerns
[Reproduce every item from section 3 with reviewer role prefix]

## Recommended changes
[Reproduce every item from section 12]

After fixing, run: /product-plans:plan-review-agents <plan-path>
```

<!-- Background mode variant (mode = background): -->
```text
The plan at <plan-path> was rejected by the review panel. The following
issues must be addressed before re-running the review.

## Blocking issues
[Reproduce every item from section 4 — or section 3 critical concerns if
section 4 is empty — with reviewer role prefix]

## Critical concerns
[Reproduce every item from section 3 with reviewer role prefix]

## Recommended changes
[Reproduce every item from section 12]

Re-run the review panel after addressing these issues:
/product-plans:plan-review-agents <plan-path>
```

<!-- END reject-only -->

---

### 15a. Inline Edits to Apply

*(This section drives the integration pass in Step 7 — it is the mechanism
by which panel findings improve the plan. Omit if `output_mode = review only`.
The lead generates a numbered list of discrete edits derived from the
recommendations in section 12. Each entry identifies a section in the source
plan, the action to perform, and the verbatim content to write. Applied in
order using `Edit` in Step 7 Pass 1.)*

| # | Section heading | Action | Content |
|---|-----------------|--------|---------|
| 1 | [exact `##` or `###` heading from the source plan, e.g. `## Steps`] | `edit` \| `append` \| `insert after "[anchor heading]"` | [verbatim content to write — replacement body for `edit`, trailing addition for `append`, new section for `insert`] |
| 2 | … | … | … |

*(Every recommended change from section 12 must have a row here. For
recommendations that add entirely new content rather than editing an existing
section, use `insert after "[nearest anchor heading]"` to append a new section
at the appropriate position in the plan. Do not omit rows for unmapped changes
— that would leave the plan unmodified for those items.)*

---

### 15b. Complete Revised Plan

*(Omit this section if the user chose review-only mode at Step 2.)*

*(This is a reference view only — all actual plan edits are driven by section
15a rows applied in Step 7 Pass 1. Do not route any recommendations here
instead of 15a; they will not be applied to the source file.)*

[Write a complete, revised version of the product plan incorporating all
recommended changes from section 12. The revised plan replaces the original
in spirit — it is not a diff. Write it as a standalone plan the development
team can act on directly.]
`````
