# WCAG 2.2 AA Compliance Reviewer

A Claude Code skill for reviewing HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance. Identifies violations, provides specific fixes, and recommends automated testing approaches.

## Overview

The WCAG Compliance Reviewer performs systematic accessibility audits of web code to ensure compliance with WCAG 2.2 Level AA standards. It provides specific code fixes, categorizes issues by severity, and recommends appropriate testing tools based on code complexity. Also covers all WCAG 2.1 and 2.0 criteria.

This skill is applicable for code reviews, component development, and accessibility testing in both vanilla HTML/CSS and React/TypeScript projects.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install wcag-compliance-reviewer@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/wcag-compliance-reviewer
```

## Usage

This plugin provides one skill. There are no commands or agents.

### Skills

#### `wcag-compliance-reviewer`

**Auto-activated** — activates automatically when user intent matches the description. No explicit invocation required.

Reviews HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA violations. Provides targeted fixes for each accessibility issue found.

**Trigger:** Use when you ask to review code for accessibility, check WCAG 2.2 Level AA compliance, identify accessibility issues in components, or audit pages/applications for a11y standards.

**Example prompts that activate this skill:**

- "Review this component for accessibility issues"
- "Check my form for WCAG compliance"
- "Audit this page for a11y standards"
- "Are there any accessibility violations in this code?"

## Features

- **Systematic WCAG Review** - Organized by four WCAG principles (Perceivable, Operable, Understandable, Robust)
- **Specific Code Fixes** - Before/after code examples with explanations
- **Severity Categorization** - Issues classified as Errors, Warnings, or Recommendations
- **Automated Testing Guidance** - Tool recommendations based on code complexity
- **Static Analysis Script** - Python script for initial scanning
- **Comprehensive Reference Documentation** - WCAG guidelines, common violations, testing guides

## Review Process

### Step 1: Determine WCAG Version and Source

**Default:** Use WCAG 2.2 AA from static reference (`references/wcag-aa-guidelines.md`)

**Fetch from W3C website if:**
- User asks for "latest guidelines" (to check for versions beyond 2.2)
- User requests "official W3C guidelines"
- Uncertain whether guidelines have been updated beyond 2.2

### Step 2: Initial Assessment

Identify code characteristics:
- File types (HTML, CSS, JSX/TSX)
- Interactive elements (buttons, forms, links, custom controls)
- Dynamic content (modals, tooltips, notifications)
- Media content (images, videos, audio)

### Step 3: Load Relevant References

**WCAG Guidelines Source (choose one):**

**Option A: Static Reference (default, faster)**
- `references/wcag-aa-guidelines.md` - Complete WCAG 2.2 AA success criteria (includes all 2.1 criteria)

**Option B: Fetch from W3C**
- WCAG 2.2 Quick Reference: https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=a,aa
- WCAG 2.1 Quick Reference (older): https://www.w3.org/WAI/WCAG21/quickref/?versions=2.1&levels=a,aa

**Always load:**
- `references/common-violations.md` - Code examples and fixes
- `references/testing-guide.md` - When testing setup is requested

### Step 4: Systematic Review by WCAG Principle

**A. Perceivable (Priority: High)**
- All images have alt text (1.1.1)
- Color contrast ratios ≥ 4.5:1 for text, ≥ 3:1 for UI (1.4.3, 1.4.11)
- No information conveyed by color alone (1.4.1)
- Semantic HTML structure (1.3.1)
- Proper heading hierarchy (1.3.1)
- Responsive reflow at 320px (1.4.10)

**B. Operable (Priority: High)**
- All interactive elements keyboard accessible (2.1.1)
- Focus indicators visible with 3:1 contrast (2.4.7)
- Logical focus order (2.4.3)
- No keyboard traps (2.1.2)
- Skip links or landmarks for navigation (2.4.1)
- Descriptive link text (2.4.4)
- Focused elements not obscured by sticky headers/footers (2.4.11) — NEW in 2.2
- Drag interactions have single-pointer alternatives (2.5.7) — NEW in 2.2
- Touch/pointer targets at least 24×24 CSS pixels (2.5.8) — NEW in 2.2

**C. Understandable (Priority: Medium)**
- Lang attribute on html element (3.1.1)
- Form labels present and associated (3.3.2)
- Error identification and suggestions (3.3.1, 3.3.3)
- Consistent navigation patterns (3.2.3)
- No context changes on focus/input (3.2.1, 3.2.2)
- Help mechanisms in consistent relative order across pages (3.2.6) — NEW in 2.2
- Previously entered info auto-populated in multi-step processes (3.3.7) — NEW in 2.2
- Authentication does not require cognitive function tests (3.3.8) — NEW in 2.2

**D. Robust (Priority: Medium)**
- ~~Parsing (4.1.1)~~ — Removed in WCAG 2.2; no longer required
- Semantic HTML or proper ARIA (4.1.2)
- Valid ARIA attributes (4.1.2)
- Status messages use ARIA live regions (4.1.3)
- All interactive elements have accessible names (4.1.2)

### Step 5: Categorize Issues by Severity

**Errors (Must Fix):**
- Missing alt text on images
- Insufficient color contrast
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
- Drag-only interactions without single-pointer alternative (2.5.7)
- Previously entered information not auto-populated in multi-step forms (3.3.7)
- Help mechanisms in inconsistent order across pages (3.2.6)

**Recommendations (Best Practices):**
- Use semantic HTML over ARIA
- Add descriptive page titles
- Implement skip links
- Use ARIA landmarks consistently

### Step 6: Provide Specific Fixes

For each issue:
1. Quote the problematic code
2. Explain the WCAG violation with success criterion reference
3. Provide corrected code
4. Explain why the fix works

**Example Format:**
```
❌ Issue: Missing alt text (WCAG 1.1.1 - Level A)

Line 23:
<img src="logo.png">

✅ Fix:
<img src="logo.png" alt="Company Name Logo">

Why: Screen readers announce "logo.png" without alt text, which is not meaningful. The alt text provides the image's purpose.
```

### Step 7: Recommend Testing Approach

**For all reviews:**
- eslint-plugin-jsx-a11y for linting
- Browser extension (axe DevTools or WAVE)

**For component libraries:**
- jest-axe for component testing
- Keyboard navigation testing
- Screen reader testing

**For full applications:**
- pa11y-ci or Lighthouse CI
- Comprehensive manual testing checklist

### Step 8: Summary Output Format

```
# Accessibility Review Summary

## Issues Found: X errors, Y warnings

### Critical Issues (Errors)
[List with line numbers, rules, and fixes]

### Warnings
[List with line numbers, rules, and fixes]

### Recommendations
[List best practice improvements]

## Testing Recommendations
[Specific tools for this codebase]

## Quick Wins
[Easy fixes with significant impact]
```

## Quick Reference Checklist

### Images & Media
- [ ] All images have alt text
- [ ] Decorative images use alt="" or aria-hidden="true"
- [ ] Complex images have longer descriptions

### Forms
- [ ] All inputs have labels
- [ ] Errors associated with fields
- [ ] Required fields marked
- [ ] Autocomplete attributes on user data inputs

### Keyboard & Focus
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible (3:1 contrast)
- [ ] No positive tabindex values
- [ ] Logical focus order
- [ ] No keyboard traps

### Color & Contrast
- [ ] Text contrast ≥ 4.5:1 (normal text)
- [ ] Text contrast ≥ 3:1 (large text: 18pt+ or 14pt+ bold)
- [ ] UI component contrast ≥ 3:1
- [ ] Information not conveyed by color alone

### Structure & Semantics
- [ ] Semantic HTML (header, nav, main, article, footer)
- [ ] Proper heading hierarchy (h1-h6)
- [ ] Lists use ul/ol/dl
- [ ] Buttons use <button>, links use <a>
- [ ] Lang attribute on <html>

### ARIA
- [ ] ARIA used only when necessary
- [ ] ARIA attributes are valid
- [ ] ARIA states update dynamically
- [ ] Status messages use live regions
- [ ] Custom controls have proper roles and states

### Dynamic Content
- [ ] Modals trap focus and restore on close
- [ ] Status updates announced (aria-live)
- [ ] Loading states indicated
- [ ] Error messages clear and helpful

### WCAG 2.2 New Criteria
- [ ] Touch/pointer targets at least 24×24 CSS pixels (2.5.8)
- [ ] Drag interactions have single-pointer alternatives (2.5.7)
- [ ] Focused elements not obscured by sticky headers/footers (2.4.11)
- [ ] Help mechanisms in same relative order across pages (3.2.6)
- [ ] Previously entered info auto-populated in multi-step processes (3.3.7)
- [ ] Authentication does not require cognitive function tests (3.3.8)

## Code Examples

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

## Bundled Resources

### Scripts (scripts/)

**check_wcag.py** - Automated accessibility checker

Static analysis for HTML/CSS/React/TypeScript files:

```bash
python scripts/check_wcag.py path/to/component.tsx
```

**Catches ~30% of issues:**
- Missing alt text
- onClick without keyboard handlers
- Missing form labels
- Focus outline removal
- Potential contrast issues

**Note:** Always perform comprehensive manual review using the full checklist.

### References (references/)

**wcag-aa-guidelines.md** - Complete WCAG 2.2 Level AA success criteria
- Organized by principle (Perceivable, Operable, Understandable, Robust)
- Success criterion descriptions
- Level A and AA requirements

**common-violations.md** - Common accessibility violations
- Before/after code examples
- HTML/CSS and React/TypeScript examples
- Specific WCAG criterion references
- Explanations of why violations occur

**testing-guide.md** - Automated testing tools and setup
- Tool recommendations (eslint-plugin-jsx-a11y, jest-axe, axe DevTools)
- Setup instructions for each tool
- Manual testing checklists
- Screen reader testing guidance

## WCAG Compliance Levels

### Level A (Minimum)
Basic web accessibility features. Failure to meet Level A means some users cannot access content at all.

### Level AA (Mid-range)
**This skill focuses on Level AA compliance.** Addresses the biggest and most common barriers for disabled users.

### Level AAA (Highest)
Highest and most complex level. Not required for general compliance but recommended where possible.

## Common Violations and Fixes

### Missing Alt Text

**❌ Problem:**
```html
<img src="chart.png">
```

**✅ Solution:**
```html
<img src="chart.png" alt="Bar chart showing Q4 sales increased 25%">
```

### Poor Color Contrast

**❌ Problem:**
```css
.text {
  color: #777;  /* 3.8:1 contrast ratio */
  background: #fff;
}
```

**✅ Solution:**
```css
.text {
  color: #595959;  /* 4.6:1 contrast ratio */
  background: #fff;
}
```

### Missing Form Labels

**❌ Problem:**
```html
<input type="email" placeholder="Email">
```

**✅ Solution:**
```html
<label for="email">Email:</label>
<input type="email" id="email" placeholder="you@example.com">
```

### Keyboard Inaccessible Button

**❌ Problem:**
```html
<div onclick="handleClick()">Click me</div>
```

**✅ Solution:**
```html
<button onclick="handleClick()">Click me</button>
```

## Testing Tools

### Linting (Development)
- **eslint-plugin-jsx-a11y** - ESLint rules for accessibility
- Catches issues during development
- Integrates with build process

### Browser Extensions (Manual Testing)
- **axe DevTools** - Comprehensive accessibility testing
- **WAVE** - Visual feedback on accessibility
- **Lighthouse** - Google's audit tool

### Automated Testing (CI/CD)
- **jest-axe** - Accessibility testing for Jest
- **pa11y-ci** - Command-line accessibility testing
- **Lighthouse CI** - Automated Lighthouse audits

### Screen Readers (Manual Testing)
- **NVDA** (Windows, free)
- **VoiceOver** (macOS/iOS, built-in)
- **JAWS** (Windows, commercial)

## Requirements

- Claude Code installed and configured
- Python 3.7+ (for check_wcag.py script)
- Web browser with developer tools
- Optional: Node.js for automated testing tools

The skill declares `allowed-tools` explicitly in its frontmatter for consistent, session-independent tool access.

## Resources

### Official WCAG Documentation

- [WCAG 2.2 Overview](https://www.w3.org/WAI/WCAG22/Understanding/)
- [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [WCAG 2.1 (older version)](https://www.w3.org/WAI/WCAG21/Understanding/)

### Testing Tools

- [axe DevTools](https://www.deque.com/axe/devtools/)
- [WAVE Browser Extension](https://wave.webaim.org/extension/)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)

### Learning Resources

- [WebAIM](https://webaim.org/) - Web accessibility resources
- [A11y Project](https://www.a11yproject.com/) - Community-driven accessibility guide
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)

## Best Practices

### During Development

1. Use semantic HTML first, ARIA as fallback
2. Test keyboard navigation early and often
3. Check color contrast during design phase
4. Include accessibility in code review checklist

### Code Review

1. Run automated tools first (linting, static analysis)
2. Perform manual review with checklist
3. Test with keyboard navigation
4. Verify focus indicators are visible

### Remediation

1. Fix errors (must fix) first
2. Address warnings (should fix) next
3. Implement recommendations (best practices) when possible
4. Re-test after fixes

## Troubleshooting

### Script Won't Run

- Verify Python 3.7+ is installed
- Check file path is correct
- Ensure file has proper permissions
- Review script output for specific errors

### False Positives

- Manual review required for context
- Some issues need human judgment
- Verify against actual WCAG criteria
- Test with assistive technology

### Complex Components

- Break review into smaller sections
- Focus on one WCAG principle at a time
- Test individual component features
- Combine automated and manual testing

## Contributing

To improve this skill:

1. Update WCAG guidelines reference with newer versions
2. Add more code examples to common-violations.md
3. Enhance testing-guide.md with new tools
4. Improve check_wcag.py script detection
5. Test with real accessibility audits

## License

This skill follows the same license as your project configuration. See LICENSE.txt for complete terms.

---

**Made for Claude Code** - Ensuring web accessibility for all users
