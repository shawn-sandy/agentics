# Plan: Update wcag-compliance-reviewer to WCAG 2.2

## Context

The `wcag-compliance-reviewer` plugin (v1.0.1) currently defaults to WCAG 2.1 Level AA across its metadata, skill logic, and documentation. WCAG 2.2 became a W3C Recommendation on October 5, 2023 and is now the current standard. The user wants the plugin to default to WCAG 2.2 so reviews cover the latest accessibility criteria.

The reference file `wcag-aa-guidelines.md` was partially updated to WCAG 2.2 but contains an error: it labels **2.4.11 as "Focus Appearance"** when the correct WCAG 2.2 criterion is **2.4.11 "Focus Not Obscured (Minimum)"** (AA). "Focus Appearance" is actually **2.4.13** at Level AAA. All other files still say WCAG 2.1.

**Version bump:** 1.0.1 → 1.1.0 (MINOR — new criteria added, backward compatible)

## New WCAG 2.2 Criteria (Level A + AA)

| SC | Name | Level | Summary |
|----|------|-------|---------|
| 2.4.11 | Focus Not Obscured (Minimum) | AA | Focused element at least partially visible, not hidden behind sticky headers/footers |
| 2.5.7 | Dragging Movements | AA | Single-pointer alternative for all drag interactions |
| 2.5.8 | Target Size (Minimum) | AA | Interactive targets at least 24×24 CSS pixels |
| 3.2.6 | Consistent Help | A | Help mechanisms in same relative order across pages |
| 3.3.7 | Redundant Entry | A | Auto-populate previously-entered info in multi-step flows |
| 3.3.8 | Accessible Authentication (Minimum) | AA | No cognitive function tests required for auth |
| 4.1.1 | Parsing | — | **Removed** in WCAG 2.2 |

## Files to Modify (8 files, in dependency order)

### Step 1: `plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json`
- Bump `version` to `"1.1.0"`
- Change description: `"WCAG 2.1"` → `"WCAG 2.2"`
- Change keyword `"wcag-2.1"` → `"wcag-2.2"`, append `"wcag-2.1"` for discoverability

### Step 2: `.claude-plugin/marketplace.json`
- Bump `version` to `"1.1.0"` for the wcag-compliance-reviewer entry
- Change description: `"WCAG 2.1"` → `"WCAG 2.2"`
- Change tag `"wcag-2.1"` → `"wcag-2.2"`, append `"wcag-2.1"`

### Step 3: `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md` (largest change)

**3a. Frontmatter + title + overview** — Replace all "WCAG 2.1" with "WCAG 2.2"

**3b. Step 1 (Determine Version)** — Invert defaults:
- Default: WCAG 2.2 AA from static reference
- Web fetch: when user asks for older versions or "latest/official"

**3c. Step 3 (Load References)** — Update Option A label to "WCAG 2.2 AA", reorder URLs to list 2.2 first

**3d. Step 4 (Systematic Review)** — Add new criteria to each principle section:
- **Operable**: Add 2.4.11 Focus Not Obscured, 2.5.7 Dragging Movements, 2.5.8 Target Size
- **Understandable**: Add 3.2.6 Consistent Help, 3.3.7 Redundant Entry, 3.3.8 Accessible Authentication
- **Robust**: Note 4.1.1 Parsing removal

**3e. Step 5 (Categorize Severity)** — Add 2.2 violations:
- Errors: targets < 24×24px, focus hidden by content, auth requiring cognitive tests, drag-only without alternative
- Warnings: help in inconsistent order, redundant entry required

**3f. Quick Reference Checklist** — Add new section for WCAG 2.2 items (target size, dragging, focus not obscured, auth, redundant entry, consistent help)

**3g. Resources section** — Change "WCAG 2.1 Level AA" → "WCAG 2.2 Level AA"

### Step 4: `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/references/wcag-aa-guidelines.md`

**Critical correction:** Fix the misidentified criterion:
- Change 2.4.11 from "Focus Appearance" to "Focus Not Obscured (Minimum)" with correct description (focused element not hidden behind sticky content)
- Remove the incorrect Focus Appearance content (that's 2.4.13 AAA, out of scope for AA reference)
- Update Quick Reference section accordingly

### Step 5: `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/references/common-violations.md`

Add 6 new sections (11-16) with before/after code examples:
- **Target Size** (2.5.8) — undersized buttons → min-width/min-height 24px
- **Focus Not Obscured** (2.4.11) — sticky header hiding focused element → scroll-padding/margin
- **Dragging Movements** (2.5.7) — drag-only reorder → add move up/down buttons
- **Accessible Authentication** (3.3.8) — CAPTCHA/paste disabled → passkeys/paste-friendly
- **Redundant Entry** (3.3.7) — re-enter address → "same as shipping" checkbox
- **Consistent Help** (3.2.6) — help in different positions → consistent nav placement

Update the Table of Contents with entries 11-16.

### Step 6: `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/scripts/check_wcag.py`

- Update docstrings: "WCAG 2.1" → "WCAG 2.2"
- Add CSS check for target size < 24px (heuristic warning)
- Add React/HTML check for `draggable`/`onDragStart` without alternatives (warning)
- Upgrade focus outline removal from `warning` to `error` severity

### Step 7: `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/references/testing-guide.md`

- Lines 19, 155, 237: Change "WCAG 2.1" → "WCAG 2.2"

### Step 8: `plugins/wcag-compliance-reviewer/README.md`

- Title, description, overview: "WCAG 2.1" → "WCAG 2.2" throughout
- Step 1: Make WCAG 2.2 the default
- Steps 3-5: Add new 2.2 criteria and severity items
- Quick Reference Checklist: Add 2.2 items
- Resources section: Reorder to list 2.2 first, mark 2.1 as "(older)"
- References description: "WCAG 2.1" → "WCAG 2.2"

### Step 9: `plugins/wcag-compliance-reviewer/CHANGELOG.md`

Add new entry for v1.1.0 documenting all changes.

## Verification

1. **Version sync check:**
   ```bash
   grep -r '"version"' plugins/wcag-compliance-reviewer/.claude-plugin/ .claude-plugin/marketplace.json
   ```
   Both should show `"1.1.0"` for wcag-compliance-reviewer.

2. **No stale WCAG 2.1 "default" references:**
   ```bash
   grep -rn "WCAG 2.1" plugins/wcag-compliance-reviewer/
   ```
   Should only appear in secondary/contextual positions (e.g., "wcag-2.1" keyword for discoverability, CHANGELOG history), never as the default standard.

3. **Python script runs without errors:**
   ```bash
   python3 plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/scripts/check_wcag.py --help
   ```

4. **Commit:** `feat(plugins/wcag-compliance-reviewer): bump version to 1.1.0` with description of WCAG 2.2 upgrade.
