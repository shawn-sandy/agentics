---
status: completed
type: feature
created: 2026-05-18
modified: 2026-05-18
---

# Plan: Add rejection remediation prompt to plan-review-agents

## Context

The `plan-review-agents` skill produces a 15-section report with a final decision of `Approve`, `Approve with revisions`, or `Reject`. Currently all three outcomes follow the same code path -- section 14 states the verdict in one line plus a rationale sentence. When a plan is rejected, the user must manually cross-reference sections 3 (highest-risk issues), 4 (blocking issues), and 12 (recommended changes) to understand what went wrong and what to fix. There is no actionable, consolidated output for rejection.

The project uses a "self-contained prompt" pattern in plan `Next Steps` sections: a label followed by a fenced `` ```text `` block containing a standalone prompt a user can copy-paste into Claude. This feature brings that pattern into the review panel's rejection output.

A stress test of the initial design surfaced three high-severity gaps and several medium/low issues that this revised plan addresses:

- **Re-run loop breakage** -- Step 7 always *appends* a `## Panel Review` section. On re-run after fixing a rejected plan, reviewers read their own old review and a second Panel Review gets appended. No handling exists for pre-existing panel review sections.
- **Background mode framing** -- "Paste into Claude" is wrong when the background agent *is* Claude. The prompt needs context-aware framing.
- **Triple-nested fences** -- The output template wraps the report in a 3-backtick `` ```markdown `` fence. Adding an inner `` ```text `` block breaks CommonMark parsing. The outer fence must be widened to 5 backticks.

## Objective

Extend section 14 of the plan-review-agents report with decision-specific output:

- **Reject** — a `#### Rejection Summary` (blocking issues with reviewer attribution) and a `#### Remediation Prompt` (self-contained, fenced `` ```text `` block the user can copy-paste into Claude to fix the plan and re-run the panel).
- **Approve / Approve with revisions** — unchanged (verdict line + rationale).

The remediation prompt is context-aware (interactive vs. background mode), handles edge cases (empty blocking issues, split decisions), and the re-run loop works cleanly via dated `## Panel Review` headings that preserve history across runs.

## Steps

1. **Widen the outer fence in `output-template.md` from 3 to 5 backticks** (lines 20 and 194). -- *Why:* CommonMark terminates a 3-backtick fence at the first 3-backtick line it encounters. The inner `` ```text `` block for the remediation prompt would prematurely close the outer fence. A 5-backtick fence can only be closed by 5+ backticks, so 3-backtick inner blocks nest safely. -- *Verify:* Lines 20 and 194 use ````` ````` `````; no other lines in the file use 5+ backticks.

2. **Add reject-only subsections to section 14 in `output-template.md`** (after line 157). Add `#### Rejection Summary` (blocking issues from section 4 + critical concerns from section 3 that drove the rejection, each prefixed with the originating reviewer role) and `#### Remediation Prompt` (fenced `` ```text `` block). Gate with HTML comments marking reject-only boundaries. -- *Why:* This is the data contract that drives all downstream rendering. Placing it inside section 14 avoids renumbering the established 15-section structure. -- *Verify:* Re-read section 14; confirm the two subsections exist, are gated by reject-only comments, and that sections 15a/15b are unchanged.

3. **Handle empty section 4 in the rejection summary template.** Add a note in the template: when section 4 (Blocking Issues) is empty but the decision is Reject, the Rejection Summary should use the highest-risk issues from section 3 that drove the rejection as the blocking-issue equivalent, with a note explaining they were severe enough in aggregate to warrant rejection. -- *Why:* A panel can reject without formal "blockers" -- e.g., all reviewers flag critical concerns that aren't individually classified as blocking but are collectively fatal. A blank blocking-issues list in the remediation prompt would confuse users. -- *Verify:* The template text for the Rejection Summary addresses the empty-section-4 case explicitly.

4. **Make the remediation prompt context-aware for background mode.** The prompt template should have two variants: (a) interactive -- "Copy and paste this prompt into Claude..."; (b) background -- "Re-run the review panel after addressing these issues: `/product-plans:plan-review-agents <path>`" (no "paste into Claude" framing). Add a note in the template gating the variant on `mode`. -- *Why:* In background mode, the prompt is appended to the plan file by the background agent. "Paste into Claude" makes no sense when no user is actively watching. -- *Verify:* The template has both variants with a clear mode gate.

5. **Update SKILL.md Step 6** (line ~189) -- add a "Rejection remediation" paragraph instructing the lead to populate the new template sections. Specify: reproduce (don't summarize) sections 3/4/12; prefix each issue with the originating reviewer role; substitute the plan path from Step 1; select the interactive or background variant based on `mode` from Step 0. -- *Why:* The template alone isn't enough; the lead needs explicit cross-referencing instructions. -- *Verify:* Re-read Step 6; confirm the paragraph names sections 3, 4, 12, the plan path, mode detection, and the "reproduce not summarize" rule.

6. **Use dated `## Panel Review` headings in SKILL.md Step 7.** Change Pass 2 to use `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` instead of bare `## Panel Review`. Do not strip old reviews -- each re-run appends a new dated section. Reviewers in subsequent runs see all historical reviews for context. -- *Why:* The user wants to preserve review history inline in the plan file. Dated headings keep each review distinct and the markdown structure valid (each is its own H2 section). Using seconds precision avoids collisions when rapid re-runs occur within the same minute. -- *Verify:* Re-read Step 7 Pass 2; confirm it uses a dated heading format with seconds precision. Confirm no Pass 0 stripping logic exists. Confirm the heading format is `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)`.

7. **Update `references/html-spec.md`** -- replace the existing decision badge with a decision banner, add a remediation prompt section (reject only). Key decisions from stress testing, interview, and panel review:
   - **Decision banner replaces badge**: Remove the existing `## Decision Badge` section from the header skeleton. Add a `## Decision Banner` section: a `<div role="status">` placed in `<main>` between the plan body and the appendix toggle, rendered for all three outcomes. Approve = green (`--badge-approve`), Revise = amber (`--badge-revise`), Reject = red (`--badge-reject`) + remediation prompt. Uses the existing badge color tokens. Only one announcement point (the banner); no badge in `<header>`.
   - **Remediation placement**: Inside the reject decision banner, outside `<details>`. For a rejected plan, the remediation prompt is the most actionable element -- burying it inside a collapsed appendix is a UX anti-pattern.
   - **Scrollable `<pre>`**: `max-height: 300px; overflow-y: auto` with `tabindex="0"` for keyboard scrolling, `:focus-visible` ring, and `role="region" aria-label="Remediation prompt text"`.
   - **Clipboard fallback**: `navigator.clipboard.writeText()` with `document.execCommand('copy')` fallback for `file://` origins (Chrome/Edge block Clipboard API on non-secure contexts). On failure, the `aria-live` region announces "Could not copy -- select the text manually". The `aria-live` span must pre-exist in the DOM (not dynamically created) per WCAG 4.1.3.
   - **Print styles**: Add `.copy-btn { display: none; }` to `@media print`.
   - **Accessibility**: `aria-live="polite"` visually-hidden span (pre-existing in DOM) announces both clipboard success ("Copied") and failure ("Could not copy -- select the text manually"). `role="status"` on the decision banner. Copy button needs `aria-label="Copy remediation prompt to clipboard"` (WCAG 4.1.2).
   - **Historical reviews in HTML**: Each `## Panel Review (timestamp)` renders as its own collapsed `<details>` in the appendix, newest first.
   - **CSS**: `.remediation` with `border-left: 4px solid var(--badge-reject)`, `background: var(--surface)` (fallback) then `color-mix(in srgb, var(--badge-reject) 5%, var(--surface))`. Add fallback for browsers without `color-mix()` support.
   - **Permitted JS scope**: Broaden to include clipboard handler alongside scroll-spy and print fallback. Extend Security & Escaping Contract to cover remediation prompt content.
   - **Skeleton**: Remove badge from `<header>`. Add decision banner injection point in `<main>` before `<details id="appendix">`. Add pre-existing `aria-live` span in skeleton. Update generator version to `v3.4.0`.
   -- *Why:* The HTML artifact must render decision status prominently for all outcomes and rejection content accessibly. Replacing the badge avoids duplicate screen reader announcements (flagged by Frontend reviewer). -- *Verify:* Confirm the decision banner section covers all three outcomes with `role="status"`. Confirm no badge remains in `<header>`. Confirm the remediation section has scrollable `<pre>` with `tabindex="0"`. Confirm `@media print` hides `.copy-btn`. Confirm clipboard JS has `execCommand` fallback and `aria-live` announces both success and failure. Confirm `aria-live` span is pre-existing in DOM. Confirm historical reviews render as separate collapsed `<details>` elements. Confirm Security & Escaping Contract covers remediation content.

8. **Add Step 8 re-read instruction to SKILL.md.** After Step 7 (integrate findings) and before the existing Step 8 (emit HTML), add an instruction for the lead to re-read the plan file. -- *Why:* Step 8 needs the plan content including the just-appended Panel Review section to render historical reviews in the HTML artifact. Without re-reading, the lead only has the synthesized report from Step 6, not the file as modified by Step 7. -- *Verify:* Re-read SKILL.md; confirm the Step 8 instructions include re-reading the resolved plan file path before generating HTML.

9. **Update the header comment** in `output-template.md` (lines 1-17) to document the rejection flow and the 5-backtick convention. -- *Why:* The header is the first thing a reader sees; it should explain the conditional behavior and why the outer fence is wider than usual. -- *Verify:* Confirm the header mentions "Rejection flow", the two subsections, and the 5-backtick fence.

10. **Update the plugin README** (`kit/plugins/product-plans/README.md`) to document the rejection remediation feature, decision banner, and dated Panel Review headings. -- *Why:* The README documents user-visible output behavior. The new features change what the user sees. -- *Verify:* README mentions the remediation prompt, the decision banner, and the dated `## Panel Review (timestamp)` format.

11. **Bump version to 3.4.0** in `CHANGELOG.md` and `.claude-plugin/marketplace.json` (line 283). -- *Why:* New feature = MINOR bump per marketplace rules. -- *Verify:* `CHANGELOG.md` has `## 3.4.0 -- 2026-05-18` as the first entry covering: reject-only remediation, decision banner for all outcomes, dated Panel Review headings, clipboard fallback, and HTML changes. `marketplace.json` line 283 reads `"version": "3.4.0"`.

## Acceptance Criteria

### Report output
- [ ] When the final decision is `Reject`, section 14 includes `#### Rejection Summary` and `#### Remediation Prompt`
- [ ] When the final decision is `Approve` or `Approve with revisions`, section 14 is unchanged (no reject-only content)
- [ ] The remediation prompt is a fenced `` ```text `` block containing: plan path, blocking issues (with reviewer attribution), critical concerns, recommended changes, and re-run instructions
- [ ] The prompt is self-contained -- pasting it into a fresh Claude session provides everything needed
- [ ] Interactive mode prompt says "Copy and paste into Claude"; background mode says "Re-run the panel"
- [ ] Empty section 4 + Reject is handled -- critical concerns from section 3 substitute with explanatory note
- [ ] No section renumbering (still 15 sections: 1-14, 15a, 15b)

### Re-run loop
- [ ] Re-runs append a new dated `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` section; old reviews are preserved inline
- [ ] Reviewers in subsequent runs see all historical reviews for context
- [ ] 15a edits still apply on Reject (partial improvement) with a note that some edits may fail against a previously-edited plan

### HTML artifact
- [ ] Decision banner (`<div role="status">`) renders for all three outcomes, placed in `<main>` before `<details id="appendix">`
- [ ] No decision badge remains in `<header>` (banner replaces badge)
- [ ] Reject decision banner includes the remediation section with a scrollable `<pre>` (`max-height: 300px`, `tabindex="0"`, `role="region"`)
- [ ] Clipboard JS has `execCommand('copy')` fallback; `aria-live` region (pre-existing in DOM) announces both success and failure
- [ ] Copy button has `aria-label="Copy remediation prompt to clipboard"` (WCAG 4.1.2)
- [ ] The copy button is hidden in print (`@media print`)
- [ ] Historical reviews render as separate collapsed `<details>` in the HTML appendix, newest first
- [ ] Security & Escaping Contract covers remediation prompt content
- [ ] CSS `.remediation` has `color-mix()` background with `var(--surface)` fallback

### Infrastructure
- [ ] The outer fence in `output-template.md` uses 5 backticks to safely nest inner fenced blocks
- [ ] README documents the new features (remediation prompt, decision banner, dated Panel Review)
- [ ] Version bumped to 3.4.0 in both `marketplace.json` and `CHANGELOG.md`

## Verification

1. **Read all modified files** and confirm changes match acceptance criteria section by section.
2. **Trace the rejection path (interactive)**: output-template section 14 reject-only content present -> SKILL.md Step 6 populates Rejection Summary + Remediation Prompt with "paste into Claude" variant using sections 3/4/12 -> Step 7 applies 15a edits (note: some may fail on Reject if plan structure was partially edited) + appends dated `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` -> Step 8 re-reads the plan file, then renders HTML decision banner (red, `role="status"`) + remediation `<pre>` (scrollable, `tabindex="0"`) + copy button with clipboard JS + `aria-live` feedback, all outside `<details>`.
3. **Trace the rejection path (background)**: same as #2 but Step 6 uses "re-run the panel" variant (no "paste into Claude" framing).
4. **Trace the approve path**: confirm section 14 has no reject-only content (HTML comments gate); HTML shows green decision banner with no remediation section; Step 7 still appends dated Panel Review.
5. **Trace the approve-with-revisions path**: confirm section 14 has no reject-only content; HTML shows amber decision banner; 15a edits apply normally.
6. **Trace the re-run path**: confirm Step 7 appends a new dated `## Panel Review (timestamp)` without stripping old ones; confirm each historical review is a separate collapsed `<details>` in the HTML, newest first; confirm reviewers see all historical sections.
7. **Verify HTML skeleton**: no badge in `<header>`; decision banner injection point in `<main>` before `<details id="appendix">`; `role="status"` on banner; remediation `<pre>` has `tabindex="0"`, `max-height: 300px`, `role="region"`; copy button has `aria-label`; clipboard JS has `execCommand('copy')` fallback; `aria-live` span pre-exists in DOM; `@media print` hides `.copy-btn`; Security & Escaping Contract covers remediation content.
8. **Verify `output-template.md`**: 5-backtick outer fence on both ends; both prompt variants with mode gate; header comment documents rejection flow and 5-backtick convention.
9. **Verify no section renumbering** (still 15 sections: 1-14, 15a, 15b).

## Files to modify

| File | Change |
|------|--------|
| [`output-template.md`](../../kit/plugins/product-plans/skills/plan-review-agents/references/output-template.md) | Widen outer fence to 5 backticks (lines 20, 194); add reject-only `#### Rejection Summary` and `#### Remediation Prompt` subsections to section 14 with HTML-comment gates; handle empty section 4 fallback; add both interactive and background prompt variants with mode gate; update header comment to document rejection flow and 5-backtick convention |
| [`SKILL.md`](../../kit/plugins/product-plans/skills/plan-review-agents/SKILL.md) | Add "Rejection remediation" paragraph to Step 6 (reproduce sections 3/4/12, prefix with reviewer role, substitute plan path, select mode variant); change Step 7 Pass 2 to dated `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` heading; add Step 8 re-read instruction before HTML generation; add partial-edit note for Reject in Step 7 Pass 1 |
| [`html-spec.md`](../../kit/plugins/product-plans/skills/plan-review-agents/references/html-spec.md) | Replace decision badge with `## Decision Banner` (all outcomes, `role="status"`, `<main>` placement); add `## Remediation Prompt` section (reject only, scrollable `<pre>` with `tabindex="0"`, `role="region"`, `max-height: 300px`); clipboard fallback JS with `execCommand('copy')` and `aria-live` (pre-existing in DOM); copy button `aria-label` (WCAG 4.1.2); print styles; `color-mix()` CSS with fallback; historical reviews as collapsed `<details>` newest first; extend Security & Escaping Contract; update skeleton (remove badge from header, add banner injection point, add `aria-live` span); update permitted-JS scope; bump generator version to `v3.4.0` |
| [`README.md`](../../kit/plugins/product-plans/README.md) | Document rejection remediation prompt, decision banner (all outcomes), dated Panel Review headings |
| [`CHANGELOG.md`](../../kit/plugins/product-plans/CHANGELOG.md) | Prepend 3.4.0 entry with: reject-only remediation, decision banner, dated Panel Review, clipboard fallback, HTML changes |
| [`marketplace.json`](../../.claude-plugin/marketplace.json:283) | Bump version `"3.3.0"` -> `"3.4.0"` |

## Key design decisions

1. **Reject-only remediation, not "approve with revisions"**: `Approve with revisions` already has sections 12 + 15a applying edits in place. A lighter "revisions prompt" can reuse this structure later (see Next Steps).
2. **Inside section 14, not a new section**: Avoids renumbering 15a/15b and breaking the "15-section report" framing. Gated by HTML comments for clean conditional rendering.
3. **Reproduce, don't summarize**: The remediation prompt's issue lists are exact copies from sections 3/4/12 with reviewer role prefixes. Prevents drift between the report and the prompt.
4. **5-backtick outer fence**: CommonMark-spec-compliant nesting. A 3-backtick inner block cannot close a 5-backtick outer fence. No external consumers of the file (confirmed via grep).
5. **Banner replaces badge**: A single `<div role="status">` decision banner in `<main>` replaces the old badge in `<header>`. Avoids duplicate screen reader announcements (flagged by Frontend reviewer). Color-coded by decision: approve = green, revise = amber, reject = red + remediation.
6. **Keep all reviews inline with dated headings**: Each re-run appends `## Panel Review (YYYY-MM-DD HH:MM:SS UTC)` with seconds precision to avoid collisions. No stripping. Reviewers see historical context. HTML renders each as a collapsed `<details>`, newest first.
7. **Apply 15a edits on Reject**: Partial improvement is better than none. The user fixes remaining issues on top. Add a note that some edits may fail against a previously-edited plan.
8. **Step 8 re-reads the plan file**: After Step 7 modifies the plan (inline edits + Panel Review append), Step 8 re-reads the file to capture the current state including historical reviews. Without this, the HTML generator only has the Step 6 synthesis, not the full file.
9. **`execCommand('copy')` fallback**: Chrome and Edge block `navigator.clipboard` on `file://` origins. The deprecated `execCommand` still works universally. Clipboard JS is progressive enhancement.
10. **`aria-live` pre-exists in DOM**: The visually-hidden `aria-live="polite"` span is in the HTML skeleton from initial render, not dynamically created. This ensures assistive technology registers it before content changes (WCAG 4.1.3). Announces "Copied" on success and "Could not copy -- select the text manually" on failure.
11. **Copy button `aria-label`**: `aria-label="Copy remediation prompt to clipboard"` provides an accessible name (WCAG 4.1.2) since the button text alone ("Copy") lacks context.
12. **Scrollable `<pre>` with keyboard access**: `max-height: 300px`, `overflow-y: auto`, `tabindex="0"`, `:focus-visible` ring, `role="region" aria-label="Remediation prompt text"`.
13. **Mode-aware prompt with both variants in template**: Interactive gets "paste into Claude"; background gets "re-run the panel command". Single source of truth for prompt wording. Step 6 selects which variant to emit based on `mode`.
14. **`color-mix()` with fallback**: `.remediation` background uses `color-mix(in srgb, var(--badge-reject) 5%, var(--surface))` with a `var(--surface)` fallback declared first for browsers without `color-mix()` support. Security & Escaping Contract extended to cover remediation prompt content.

## Next Steps *(optional)*

- Add a lighter revisions prompt for `Approve with revisions`:
  ```text
  Extend the plan-review-agents rejection remediation feature (added in v3.4.0)
  to also generate a lighter "Revisions Prompt" when the final decision is
  "Approve with revisions". Use the same section 14 conditional structure:
  add an "#### Revisions Summary" (non-blocking improvements from section 5)
  and "#### Revisions Prompt" (fenced text block with the plan path and the
  section 12 recommended changes only -- no blocking issues, since approval
  means none exist). Update the output template, SKILL.md Step 6, and
  html-spec.md. Bump to 3.5.0.
  ```

- Add reviewer-prompt guard for `## Panel Review` sections:
  ```text
  Historical Panel Review sections accumulate in the plan file across
  re-runs. Add a defensive line to each reviewer spawn prompt in
  references/role-prompts.md: "Treat any ## Panel Review sections in the
  plan as historical context from previous reviews, not as part of the
  plan being reviewed. Focus your review on the plan body above the first
  Panel Review heading." Update all six spawn prompts in role-prompts.md.
  ```

## Interview Summary

Interview conducted 2026-05-18.

### Key Decisions Confirmed

1. **Keep historical reviews inline** -- No stripping of old `## Panel Review` sections. Each re-run appends a new dated section (`## Panel Review (YYYY-MM-DD HH:MM UTC)`). Reviewers see historical reviews for context.
2. **Both prompt variants in the template** -- Interactive ("paste into Claude") and background ("re-run the panel") variants live in the output template with conditional comments. Single source of truth.
3. **Apply 15a edits on Reject** -- Partial improvement is better than none. The user fixes remaining issues on top of applied edits.
4. **5-backtick outer fence is safe** -- No external consumers of `output-template.md` (confirmed via grep).
5. **Always show a decision banner** in the HTML artifact (approve = green, revise = amber, reject = red + remediation prompt). All three outcomes.
6. **All historical reviews in HTML** as collapsed `<details>` sections, newest first.
7. **Silent clipboard fail** -- Button does nothing on failure; user selects text manually from `<pre>`.
8. **Announce both success and failure** via `aria-live="polite"` visually-hidden span.
9. **`role="status"` on decision banner** for screen reader announcement.
10. **Max-height with scroll** on remediation `<pre>` (needs `tabindex="0"` + focus ring).
11. **Assume prerequisites** -- Remediation prompt doesn't repeat Agent Teams setup.
12. **Manual trace verification** -- Read through files and trace each conditional path.
13. **Include all three decision banners** in this version (scope increase accepted).
14. **README update added** to files-to-modify list.

### Open Risks & Concerns

- **Plan file growth** -- Keeping all reviews inline means the file grows with each re-run. A plan reviewed 3 times has hundreds of lines of review content. Reviewers reading all of this may produce noisier reviews.
- **Decision banner scope increase** -- Adding banners for all three outcomes expands the diff beyond the original "reject prompt" ask.
- **Dated heading parsing** -- The HTML artifact needs to detect multiple `## Panel Review (timestamp)` sections and render each as a collapsed `<details>`. This adds parsing logic to Step 8.
- **Scrollable `<pre>` a11y** -- Keyboard focus management for scrollable regions requires careful implementation (`tabindex="0"`, `role="region"`, `:focus-visible`).

### Recommended Plan Amendments (applied)

- Step 6: Replaced "strip old Panel Review" with "use dated headings, keep all reviews"
- Step 7: Added decision banner for all three outcomes; added scrollable `<pre>` spec; added `aria-live` success/failure; added historical reviews rendering
- Step 9: Added README update
- Acceptance criteria: Updated to reflect all interview decisions
- Verification: Updated with separate interactive/background rejection traces and re-run trace

## Panel Review (2026-05-18 17:45:00 UTC)

### 1. Executive Summary

Six reviewers assessed the plan for adding rejection remediation prompts to the plan-review-agents skill. The plan is well-structured with clear steps, strong accessibility considerations, and thoughtful edge case handling. All six reviewers provided findings.

**Overall assessment: Approve with revisions** -- the plan is implementable as-is but benefits from the refinements identified below.

### 2. Role-by-Role Review

**Product Manager** -- Focused on user value, scope, and success metrics. Confirmed the feature addresses a real pain point (rejected plans leave users stranded). Flagged the scope expansion to all-outcome banners as a risk to delivery timeline. Recommended success metrics and noted the self-contained prompt pattern aligns with existing project conventions.

**Lead Developer** -- Assessed technical feasibility and architecture. Confirmed the 5-backtick CommonMark approach, section 14 nesting, and mode-aware branching are sound. Identified a critical gap: Step 8 (HTML generation) cannot access historical reviews without re-reading the plan file after Step 7 modifies it. Recommended adding a re-read instruction. Also flagged that 15a edits on Reject may partially fail if the plan was previously edited.

**UX Designer** -- Reviewed user flows and interaction design. Confirmed the decision banner placement (in `<main>`, outside collapsed appendix) follows UX best practices for actionable content. Validated the copy-paste workflow. Noted that the "silent clipboard fail" language in the interview contradicts the aria-live announcement -- recommended clarifying that "silent" means visually silent (button state unchanged), while screen readers still get feedback.

**Lead Frontend Engineer** -- Reviewed component architecture and DOM structure. Identified a duplication issue: the existing html-spec.md has a decision badge in `<header>`, and the plan adds a banner in `<main>`. Having both creates duplicate screen reader announcements. Recommended the banner replace the badge entirely. Also recommended `color-mix()` CSS fallback for older browsers and extending the Security & Escaping Contract to cover remediation prompt content.

**Accessibility Expert** -- Reviewed WCAG compliance. Confirmed `role="status"` on the decision banner, `tabindex="0"` on scrollable `<pre>`, and `aria-live` feedback are correct. Identified that the `aria-live` span must pre-exist in the DOM (not dynamically created) per WCAG 4.1.3. Recommended `aria-label` on the copy button (WCAG 4.1.2) since "Copy" alone lacks context. Confirmed WCAG 1.4.1 compliance via text labels alongside color.

**Security Expert** -- Reviewed the Security & Escaping Contract, CSP, and clipboard handling. Confirmed the existing CSP (`unsafe-inline` for styles and scripts) is adequate for the self-contained artifact. Noted that remediation prompt content (which includes user-authored plan text) must be HTML-escaped before injection into the `<pre>` element. Recommended extending the Security & Escaping Contract section in html-spec.md to explicitly name remediation content as requiring escaping.

### 3. Highest-Risk Issues

1. **[Lead Dev] Step 8 re-read gap** -- After Step 7 modifies the plan file (inline edits + Panel Review append), Step 8 generates the HTML artifact. But Step 8 only has the synthesized report from Step 6, not the modified file. Historical `## Panel Review` sections won't appear in the HTML unless the lead re-reads the file. **Severity: High** -- breaks the historical-reviews-in-HTML acceptance criterion.

2. **[Frontend] Badge/banner duplication** -- The existing html-spec.md has a decision badge in `<header>`. Adding a decision banner in `<main>` creates two announcement points. Screen readers would announce the decision twice. **Severity: High** -- accessibility regression.

3. **[Security] Remediation content escaping** -- The remediation prompt includes user-authored plan text reproduced from sections 3/4/12. If the plan contains HTML-like content (angle brackets, ampersands), it could break the `<pre>` rendering or create injection vectors. The Security & Escaping Contract must explicitly cover this content. **Severity: Medium** -- injection risk in self-contained HTML.

### 4. Blocking Issues

No formally blocking issues. All three highest-risk items above are addressable within the plan's existing structure without architectural changes.

### 5. Non-Blocking Improvements

1. **[PM] Add success metrics** -- Define how to measure whether the feature achieves its goal (e.g., percentage of rejected plans that get re-submitted after remediation prompt is used).
2. **[UX] Clarify "silent fail" language** -- The interview noted "silent clipboard fail" but also "aria-live announces failure." Clarify that "silent" means visually silent (button unchanged), while assistive technology gets an announcement.
3. **[A11y] Copy button accessible name** -- Add `aria-label="Copy remediation prompt to clipboard"` to the copy button for WCAG 4.1.2 compliance.
4. **[Frontend] `color-mix()` CSS fallback** -- Add `background: var(--surface)` before the `color-mix()` declaration so browsers without support still get a reasonable background.
5. **[Lead Dev] Partial-edit note for Reject** -- When 15a edits apply on Reject, some may target sections that don't match after previous edits. Add a note that partial application is expected and non-fatal.
6. **[A11y] `aria-live` span must pre-exist in DOM** -- Don't dynamically create the `aria-live` region; include it in the HTML skeleton so assistive technology registers it before content changes.
7. **[Security] Extend Security & Escaping Contract** -- Add a line in html-spec.md stating that remediation prompt content (reproduced from plan sections) must be HTML-escaped before injection into `<pre>`.

### 6. Cross-Reviewer Agreements

- **All reviewers** agree the 5-backtick fence approach is correct and safe.
- **PM + UX + A11y** agree the decision banner should be visible for all outcomes, not just Reject.
- **Lead Dev + Frontend + Security** agree the plan's architecture (section 14 nesting, no renumbering) is sound.
- **UX + A11y** agree the remediation prompt must be outside the collapsed appendix for discoverability.
- **Frontend + A11y** agree the banner should replace (not supplement) the badge.

### 7. Cross-Reviewer Conflicts

1. **"Silent fail" vs. aria-live announcement** -- The interview record says "silent clipboard fail" (decision #7) but also "announce both success and failure" (decision #8). **Resolution**: These are compatible. "Silent" refers to the visual UI (button state unchanged); the `aria-live` region provides feedback to assistive technology only. The plan should clarify this distinction in the key design decisions.

2. **Plan file growth vs. reviewer context** -- PM flagged that keeping all reviews inline causes unbounded file growth. Lead Dev noted reviewers benefit from historical context. **Resolution**: Accept the growth for now; the plan already has a Next Steps item for a reviewer-prompt guard that instructs reviewers to treat Panel Review sections as historical context, not plan content.

### 8. Assumption Challenges

- **Assumption: Users will know to copy the prompt.** The UX reviewer noted that the remediation prompt's value depends on users recognizing it as copy-pasteable. The decision banner placement and copy button mitigate this, but the plan should ensure the prompt has clear introductory text.
- **Assumption: `execCommand('copy')` will continue working.** The Security reviewer noted this API is deprecated. The plan correctly treats clipboard as progressive enhancement (user can manually select text), so this assumption is acceptable.

### 9. Balance Assessment

All six perspectives are represented. The plan leans technical (strong on CommonMark, HTML, CSS, and ARIA details) but the PM and UX reviews ensured user-value and interaction-design concerns were addressed. The Accessibility review identified specific WCAG criteria. No single perspective dominated the synthesis.

### 10. Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Step 8 re-read gap breaks historical reviews in HTML | High (confirmed gap) | High | Add re-read instruction to SKILL.md |
| Badge/banner duplication causes double announcement | High (confirmed gap) | High | Replace badge with banner |
| Remediation content injection in HTML | Medium | Medium | Extend Security & Escaping Contract |
| `color-mix()` unsupported in older browsers | Low | Low | Declare `var(--surface)` fallback first |
| Plan file growth causes noisy reviews | Medium | Low | Next Steps item for reviewer-prompt guard |
| 15a edits partially fail on Reject | Medium | Low | Add partial-edit note; non-fatal |

### 11. Missing Requirements

- No success metrics for the feature (PM suggestion -- deferred to implementation)
- No explicit test plan for clipboard fallback across browsers (acceptable for a plan-level spec)
- No rollback strategy (acceptable -- all changes are additive and the version bump is reversible)

### 12. Recommended Changes

1. **Add Step 8 re-read instruction** to SKILL.md between current Step 7 and Step 8. The lead must re-read the plan file after Step 7 modifies it, before generating the HTML artifact.
2. **Replace badge with banner** in html-spec.md. Remove the existing decision badge section from the header skeleton. The decision banner in `<main>` is the sole announcement point.
3. **Extend Security & Escaping Contract** in html-spec.md to explicitly name remediation prompt content as requiring HTML escaping.
4. **Add `aria-label` to copy button** in html-spec.md: `aria-label="Copy remediation prompt to clipboard"`.
5. **Add `aria-live` span to HTML skeleton** as a pre-existing element (not dynamically created).
6. **Add `color-mix()` fallback** in html-spec.md: declare `background: var(--surface)` before the `color-mix()` line.
7. **Clarify "silent fail"** in key design decisions: visually silent (button unchanged), assistive technology gets `aria-live` feedback.
8. **Add partial-edit note** to Step 7 Pass 1 in the plan: some 15a edits may fail when applying to a Reject outcome if the plan was previously edited.
9. **Use seconds precision** in dated Panel Review headings (`HH:MM:SS` not `HH:MM`) to avoid collisions on rapid re-runs.
10. **Update plan Objective** to explicitly name the two subsections (`#### Rejection Summary` and `#### Remediation Prompt`) and note which outcomes are affected.

### 13. Implementation Priorities

1. **Critical** (must be in this version):
   - Step 8 re-read instruction (breaks acceptance criterion without it)
   - Badge-to-banner replacement (prevents accessibility regression)
   - Security & Escaping Contract extension (prevents injection risk)

2. **Important** (strongly recommended):
   - `aria-label` on copy button (WCAG 4.1.2)
   - `aria-live` span pre-existing in DOM (WCAG 4.1.3)
   - `color-mix()` CSS fallback
   - Seconds precision in dated headings

3. **Nice to have** (can defer):
   - Success metrics
   - Partial-edit note (behavior is correct; note is documentation)

### 14. Final Decision

**Approve with revisions.**

The plan is well-designed and addresses the core user need (actionable output on rejection). The three highest-risk items (Step 8 re-read, badge/banner duplication, remediation content escaping) are all addressable within the existing plan structure. The recommended changes strengthen accessibility, security, and correctness without changing the architecture.

### 15a. Inline Edits Applied

| Target Section | Action | Summary |
|---------------|--------|---------|
| Objective | edit | Added labeled internal structure (`#### Rejection Summary`, `#### Remediation Prompt`), split decision definition by outcome |
| Steps | edit | Added Step 8 re-read instruction, seconds precision in dated headings, partial-edit note for Reject, Security & Escaping Contract extension, badge-to-banner replacement, copy button `aria-label`, `aria-live` pre-existing in DOM |
| Acceptance Criteria | edit | Expanded to 21-item grouped checklist (Report output, Re-run loop, HTML artifact, Infrastructure) |
| Verification | edit | Expanded to 9 items with separate interactive/background rejection traces, approve-with-revisions trace, and HTML skeleton verification |
| Files to modify | edit | Expanded change descriptions to reflect all panel findings |
| Key design decisions | edit | Expanded to 14 numbered decisions incorporating all panel findings |

### 15b. Revised Plan

The revised plan with all inline edits applied is the content of this file above the Panel Review section.
