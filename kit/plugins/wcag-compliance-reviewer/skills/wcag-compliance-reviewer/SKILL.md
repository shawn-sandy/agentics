---
name: wcag-compliance-reviewer
description: "Reviews HTML/CSS and React code for WCAG 2.2 Level AA violations. Provides targeted fixes for each accessibility issue found. Use when the user asks to check WCAG compliance or audit accessibility."
allowed-tools: Read, Grep, Glob, WebFetch, Bash(wcag-check *), Bash(python3 *), mcp__Claude_Browser__preview_start, mcp__Claude_Browser__navigate, mcp__Claude_Browser__read_page, mcp__Claude_Browser__javascript_tool, mcp__Claude_Browser__resize_window
license: MIT
metadata:
  author: shawn-sandy
  version: "1.0"
---

## WCAG 2.2 AA Compliance Reviewer

## Overview

Review code changes for WCAG 2.2 Level AA accessibility compliance in HTML/CSS and React/TypeScript components. This skill identifies violations, provides specific fixes, and recommends automated testing approaches. Also covers all WCAG 2.1 and 2.0 criteria.

## Table of Contents

- [Review Process](#review-process)
  - [1. Determine WCAG Version and Source](#1-determine-wcag-version-and-source)
  - [2. Initial Assessment](#2-initial-assessment)
  - [3. Load Relevant References](#3-load-relevant-references)
  - [4. Measured Values: Measure or Label](#4-measured-values-measure-or-label)
  - [5. Systematic Review by WCAG Principle](#5-systematic-review-by-wcag-principle)
  - [6. Categorize Issues by Severity](#6-categorize-issues-by-severity)
  - [7. Provide Specific Fixes](#7-provide-specific-fixes)
  - [8. Recommend Testing Approach](#8-recommend-testing-approach)
  - [9. Summary Output Format](#9-summary-output-format)
- [Quick Reference Checklist](#quick-reference-checklist)
- [Code Examples for Common Patterns](#code-examples-for-common-patterns)
- [Using the Automated Checker Script](#using-the-automated-checker-script)
- [Resources](#resources)

## Review Process

Follow these steps exactly when reviewing code for accessibility.

### 1. Determine WCAG Version and Source

**Default:** Use WCAG 2.2 AA from static reference (`references/wcag-aa-guidelines.md`)

**Fetch from W3C website if:**
- User asks for "latest guidelines" (to check for versions beyond 2.2)
- User requests "official W3C guidelines" or "pull from the website"
- Uncertain whether guidelines have been updated beyond 2.2

**Use WCAG 2.1 instead if:**
- User explicitly specifies WCAG 2.1
- Project requirements mandate 2.1 compliance only

**Example user phrases that trigger web fetch:**
- "Check against the latest WCAG standards"
- "Use the current W3C guidelines"
- "Pull the official accessibility guidelines"

### 2. Initial Assessment

Read the code and identify:
- File types (HTML, CSS, JSX/TSX)
- Interactive elements (buttons, forms, links, custom controls)
- Dynamic content (modals, tooltips, notifications)
- Media content (images, videos, audio)

### 3. Load Relevant References

Based on the code type and complexity, load the appropriate reference files:

**WCAG Guidelines Source:**

Choose one of these approaches based on user request:

**Option A: Use static reference (default, faster)**
- `references/wcag-aa-guidelines.md` - Complete WCAG 2.2 AA success criteria (includes all 2.1 criteria)
- Use when user doesn't specifically request latest/live guidelines

**Option B: Fetch from official W3C website**

Use when user:
- Explicitly asks for "latest" or "current" guidelines
- Asks to check against a version beyond 2.2
- Wants to verify against official source
- Says "pull from the website" or similar

Fetch using web_fetch:
```
WCAG 2.2 AA Quick Reference:
https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=a,aa

Understanding WCAG 2.2:
https://www.w3.org/WAI/WCAG22/Understanding/

WCAG 2.1 AA Quick Reference (older version):
https://www.w3.org/WAI/WCAG21/quickref/?versions=2.1&levels=a,aa

Understanding WCAG 2.1:
https://www.w3.org/WAI/WCAG21/Understanding/
```

After fetching, combine official guidelines with code examples from `references/common-violations.md`

**Always load when reviewing code:**
- `references/common-violations.md` - Code examples and fixes for HTML/CSS/React/TypeScript
- `references/testing-guide.md` - When user asks about testing or wants to set up automated checks

### 4. Measured Values: Measure or Label

Contrast ratios, computed sizes, and touch-target dimensions are **measurements,
not readings**. Never state one that you did not obtain from a tool run.

Reading a hex pair out of a stylesheet and reporting "3.8:1" is the single
failure mode this skill is most prone to, because the number looks like analysis
and reads as authoritative. Source CSS is not the rendered result: a `color`
declaration can be overridden by specificity, recomputed by `color-mix()` or
`light-dark()`, altered by opacity or a blend mode, or inherited from a variable
whose value is only resolved at runtime. Two ratios shipped by this skill were
wrong for exactly that reason and were caught downstream.

**For anything with a number attached:**

1. **Measure it.** Against a running page, read computed styles with the browser
   MCP or Playwright:

   ```js
   const s = getComputedStyle(el);
   ({ color: s.color, bg: s.backgroundColor, outline: s.outlineColor,
      box: el.getBoundingClientRect() });   // box → touch targets, 2.5.8
   ```

   For a static file with no server, compute from the *resolved* values: read
   both colors, flatten any alpha against the actual backdrop, and run the WCAG
   relative-luminance formula with `Bash(python3 *)`, showing the arithmetic.

   ```python
   def lum(c):  # c = (r, g, b), each 0-255
       def ch(v):
           v /= 255
           return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
       r, g, b = (ch(x) for x in c)
       return 0.2126 * r + 0.7152 * g + 0.0722 * b

   ratio = (max(lum(fg), lum(bg)) + 0.05) / (min(lum(fg), lum(bg)) + 0.05)
   ```

   **`wcag-check` does not compute this.** Its `_similar_lightness` averages
   RGB and returns a boolean for "both light or both dark", then emits
   *"Potential color contrast issue — verify 4.5:1"*. That is a prompt to go
   measure, not a measurement, and its output must never be pasted as one. Use
   it to *surface candidate pairs* worth checking; get the number from the
   formula above or from the browser.
2. **Paste the raw tool output** into the finding, before the conclusion. A
   ratio with no visible measurement behind it is an estimate wearing a
   measurement's clothes.
3. **Only when you can neither reach a browser *nor* resolve the values
   statically**, write `UNVERIFIED — <reason>` (`no browser, values unresolved`)
   and describe what to check by hand. A ratio you computed from resolved
   values with the arithmetic shown **is** verified — the absence of a browser
   does not downgrade it, or step 1's static path would never produce a usable
   number. Never substitute a `grep` of the source and report it as
   verification.

An honest `UNVERIFIED` costs the reader one manual check. A confident wrong
ratio costs them the entire audit's credibility.

Everything without a number — a missing `alt`, an unlabeled input, a heading
skip, an `onClick` with no key handler — is a genuine source reading. Report
those from the code directly.

### 5. Systematic Review by WCAG Principle

Review code against the four WCAG principles in this order:

**A. Perceivable (Priority: High)**
1. Check all images for alt text (1.1.1)
2. Verify color contrast ratios (1.4.3, 1.4.11)
3. Confirm no information conveyed by color alone (1.4.1)
4. Check semantic HTML structure (1.3.1)
5. Verify proper heading hierarchy (1.3.1)
6. Check responsive reflow at 320px (1.4.10)
7. Verify text spacing compatibility (1.4.12)

**B. Operable (Priority: High)**
1. Test keyboard accessibility - all interactive elements must be keyboard operable (2.1.1)
2. Verify focus indicators are visible with 3:1 contrast (2.4.7)
3. Check focus order is logical (2.4.3)
4. Verify no keyboard traps exist (2.1.2)
5. Check skip links or landmarks for navigation (2.4.1)
6. Verify descriptive link text (2.4.4)
7. Check focused elements are not obscured by sticky headers/footers (2.4.11) — NEW in 2.2
8. Verify all drag interactions have single-pointer alternatives (2.5.7) — NEW in 2.2
9. Check touch/pointer targets are at least 24×24 CSS pixels (2.5.8) — NEW in 2.2

**C. Understandable (Priority: Medium)**
1. Check lang attribute on html element (3.1.1)
2. Verify form labels are present and associated (3.3.2)
3. Check error identification and suggestions (3.3.1, 3.3.3)
4. Verify consistent navigation patterns (3.2.3)
5. Check no context changes on focus/input (3.2.1, 3.2.2)
6. Check help mechanisms appear in consistent relative order across pages (3.2.6) — NEW in 2.2
7. Verify previously-entered information is auto-populated in multi-step processes (3.3.7) — NEW in 2.2
8. Verify authentication does not require cognitive function tests (3.3.8) — NEW in 2.2

**D. Robust (Priority: Medium)**
1. ~~Parsing (4.1.1)~~ — Removed in WCAG 2.2; no longer required
2. Verify semantic HTML or proper ARIA (4.1.2)
3. Check ARIA attributes are valid (4.1.2)
4. Verify status messages use ARIA live regions (4.1.3)
5. Check all interactive elements have accessible names (4.1.2)

### 6. Categorize Issues by Severity

**Errors (Must Fix):**
- Missing alt text on images
- Insufficient color contrast (< 4.5:1 for text, < 3:1 for UI components)
- Keyboard inaccessible elements
- Missing form labels
- Invalid ARIA attributes
- Missing focus indicators
- Missing lang attribute
- Touch/pointer targets smaller than 24×24 CSS pixels (2.5.8)
- Focused element entirely hidden behind sticky content (2.4.11)
- Authentication requiring cognitive function tests without alternative (3.3.8)

**Warnings (Should Fix):**
- Positive tabindex values
- autoFocus usage
- Links without descriptive text
- Potential color-only indicators
- Missing autocomplete on user data inputs
- Drag-only interactions without single-pointer alternative (2.5.7)
- Previously entered information not auto-populated in multi-step forms (3.3.7)
- Help mechanisms in inconsistent order across pages (3.2.6)

**Recommendations (Best Practices):**
- Use semantic HTML over ARIA when possible
- Add descriptive page titles
- Implement skip links
- Use ARIA landmarks consistently
- Note: 4.1.1 Parsing was removed in WCAG 2.2 — valid HTML is still best practice but no longer a compliance requirement

### 7. Provide Specific Fixes

For each issue identified:

1. **Quote the problematic code** from the user's file
2. **Explain the WCAG violation** with specific success criterion reference
3. **Provide corrected code** using examples from `common-violations.md`
4. **Explain why the fix works** in terms of assistive technology interaction

Example format:
```
❌ Issue: Missing alt text (WCAG 1.1.1 - Level A)

Line 23:
<img src="logo.png">

✅ Fix:
<img src="logo.png" alt="Company Name Logo">

Why: Screen readers announce "logo.png" without alt text, which is not meaningful. The alt text provides the image's purpose.
```

### 8. Recommend Testing Approach

Based on the code complexity, recommend appropriate testing tools from `references/testing-guide.md`:

**For all reviews, recommend:**
- eslint-plugin-jsx-a11y for linting during development
- Browser extension (axe DevTools or WAVE) for quick checks

**For component libraries or complex UIs, additionally recommend:**
- jest-axe for component testing
- Keyboard navigation testing
- Screen reader testing with NVDA/VoiceOver

**For full applications, additionally recommend:**
- pa11y-ci or Lighthouse CI for automated testing
- Comprehensive manual testing checklist

### 9. Summary Output Format

Structure the review output as follows:

```
# Accessibility Review Summary

## Issues Found: X errors, Y warnings

### Critical Issues (Errors)
[List each error with line number, rule, and fix]

### Warnings
[List each warning with line number, rule, and fix]

### Recommendations
[List best practice improvements]

## Testing Recommendations
[Specific tools and approaches for this codebase]

## Quick Wins
[Easy fixes that provide significant accessibility improvements]
```

## Quick Reference Checklist

Use this for rapid reviews:

**Images & Media:**
- [ ] All images have alt text
- [ ] Decorative images use alt="" or aria-hidden="true"
- [ ] Complex images have longer descriptions

**Forms:**
- [ ] All inputs have labels (label, aria-label, or aria-labelledby)
- [ ] Errors are associated with fields (aria-describedby, aria-invalid)
- [ ] Required fields are marked
- [ ] Autocomplete attributes on user data inputs

**Keyboard & Focus:**
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible (3:1 contrast)
- [ ] No positive tabindex values
- [ ] Logical focus order
- [ ] No keyboard traps in modals/dialogs

**Color & Contrast:**
- [ ] Text contrast ≥ 4.5:1 (normal text)
- [ ] Text contrast ≥ 3:1 (large text: 18pt+ or 14pt+ bold)
- [ ] UI component contrast ≥ 3:1
- [ ] Information not conveyed by color alone

**Structure & Semantics:**
- [ ] Semantic HTML (header, nav, main, article, footer)
- [ ] Proper heading hierarchy (h1-h6, no skipped levels)
- [ ] Lists use ul/ol/dl
- [ ] Buttons use <button>, links use <a>
- [ ] lang attribute on <html> element

**ARIA:**
- [ ] ARIA used only when necessary (prefer semantic HTML)
- [ ] ARIA attributes are valid
- [ ] ARIA states update dynamically
- [ ] Status messages use live regions
- [ ] Custom controls have proper roles and states

**Dynamic Content:**
- [ ] Modals trap focus and restore on close
- [ ] Status updates announced (aria-live)
- [ ] Loading states indicated
- [ ] Error messages clear and helpful

**WCAG 2.2 New Criteria:**
- [ ] Touch/pointer targets at least 24×24 CSS pixels (2.5.8)
- [ ] Drag interactions have single-pointer alternatives (2.5.7)
- [ ] Focused elements not obscured by sticky headers/footers (2.4.11)
- [ ] Help mechanisms in same relative order across pages (3.2.6)
- [ ] Previously entered info auto-populated in multi-step processes (3.3.7)
- [ ] Authentication does not require cognitive function tests (3.3.8)

## Code Examples for Common Patterns

### Accessible Button with Icon
```tsx
// ✅ Good - TypeScript
<button onClick={handleDelete} aria-label="Delete item">
  <TrashIcon aria-hidden="true" />
</button>
```

### Accessible Modal
```tsx
// ✅ Good - Focus trap and restoration
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="modal-title"
>
  <h2 id="modal-title">Modal Title</h2>
  <button onClick={onClose}>Close</button>
  {children}
</div>
```

### Form with Error Handling
```tsx
// ✅ Good - Associated error, proper ARIA
<label htmlFor="email">Email:</label>
<input
  type="email"
  id="email"
  aria-invalid={!!error}
  aria-describedby={error ? "email-error" : undefined}
/>
{error && (
  <div id="email-error" role="alert">
    {error}
  </div>
)}
```

## Using the Automated Checker Script

For initial scanning of files, use the provided Python script:

```bash
wcag-check path/to/component.tsx
```

`wcag-check` is a bundled `bin/` wrapper; a plugin's `bin/` is on the Bash
tool's `PATH`, so it works from any directory. Do not spell this as a
plugin-root-anchored path — the Bash tool refuses any command containing
`${VAR}` or `$VAR` with `error: Contains expansion`, before permission rules
are consulted.

This performs static analysis to catch common issues like:
- Missing alt text
- onClick without keyboard handlers
- Missing form labels
- Focus outline removal
- Potential contrast issues

**Note:** The script catches ~30% of issues. Always perform comprehensive manual review using the full checklist above.

## Resources

### scripts/
- `check_wcag.py` - Automated accessibility checker for HTML/CSS/React/TypeScript files

### references/
- `wcag-aa-guidelines.md` - Complete WCAG 2.2 Level AA success criteria organized by principle
- `common-violations.md` - Common accessibility violations with before/after code examples for HTML/CSS and React/TypeScript
- `testing-guide.md` - Automated testing tools, setup instructions, and manual testing checklists
