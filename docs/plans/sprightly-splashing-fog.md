# Plan: Update wcag-aa-guidelines.md to WCAG 2.2 Level AA

## Context

The `wcag-compliance-reviewer` plugin currently references WCAG 2.1 Level AA. WCAG 2.2 was published September 2023, adding 9 new success criteria and deprecating one. The reference file must be updated so the skill reviews code against the current standard.

**Target file:** `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/references/wcag-aa-guidelines.md`

---

## Changes to `wcag-aa-guidelines.md`

### 1. Title + intro
- Change: `# WCAG 2.1 Level AA Success Criteria Reference` → `# WCAG 2.2 Level AA Success Criteria Reference`

### 2. Section 2.4 — Add new criterion

**2.4.11 Focus Appearance (Level AA)** — NEW in 2.2
- Keyboard focus indicator must have minimum area (perimeter of component × 2 CSS px)
- Contrast ratio of at least 3:1 between focused and unfocused states
- Contrast ratio of at least 3:1 against adjacent colors
- Insert after existing **2.4.7 Focus Visible**

### 3. Section 2.5 — Add two new criteria

**2.5.7 Dragging Movements (Level AA)** — NEW in 2.2
- All functionality using dragging motions must have a single-pointer alternative
- Exception: When dragging is essential

**2.5.8 Target Size (Minimum) (Level AA)** — NEW in 2.2
- Touch/pointer targets must be at least 24×24 CSS pixels
- Exception: Inline targets (links within text), agent-controlled, essential presentation
- Insert after existing **2.5.4 Motion Actuation**

### 4. Section 3.2 — Add new criterion

**3.2.6 Consistent Help (Level A)** — NEW in 2.2
- If a help mechanism (human contact, self-help, automated) appears on multiple pages, it must appear in the same relative order
- Insert after existing **3.2.4 Consistent Identification**

### 5. Section 3.3 — Add two new criteria

**3.3.7 Redundant Entry (Level A)** — NEW in 2.2
- Information entered in a previous step that is required again in the same process must be auto-populated or selectable
- Exception: When re-entering is essential (passwords), or the information is no longer valid

**3.3.8 Accessible Authentication (Minimum) (Level AA)** — NEW in 2.2
- Authentication process must not require cognitive function test (memorizing, transcribing, solving)
- Exception: Alternative method available, or test uses object/personal content recognition
- Insert after existing **3.3.4 Error Prevention**

### 6. Section 4.1 — Deprecate removed criterion

**4.1.1 Parsing** — REMOVED in WCAG 2.2
- Mark with `~~4.1.1 Parsing~~ (Removed in WCAG 2.2)`
- Add note: "This criterion was deprecated and removed in WCAG 2.2. Modern browsers handle malformed HTML consistently, making it no longer necessary for accessibility compliance."

### 7. Quick Reference section
- Add to the list:
  - Focus appearance (3:1 contrast, minimum area)
  - Target size (24×24 CSS px minimum)
  - Dragging alternatives (single-pointer alternative required)
  - Redundant entry (auto-populate across process steps)
  - Accessible authentication (no cognitive function test)
- Remove or note: Parsing (4.1.1) removed

### 8. Documentation links
- Update primary link to WCAG 2.2: `https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa`
- Update Understanding link: `https://www.w3.org/WAI/WCAG22/Understanding/`
- Keep ARIA Authoring Practices link (unchanged)

---

## Related Files (note only — out of scope unless user requests)

These files reference "WCAG 2.1" but were not requested:
- `plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json` — description + keyword `wcag-2.1`
- `plugins/wcag-compliance-reviewer/README.md` — mentions WCAG 2.1 throughout
- `plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md` — skill description
- Version bump: `1.0.0 → 1.1.0` (minor: new content, backward compatible)

---

## Verification

1. Confirm all 6 new Level A/AA criteria are present with correct criterion numbers
2. Confirm 4.1.1 Parsing is marked as removed
3. Confirm Quick Reference reflects the additions
4. Confirm links point to WCAG 2.2 URLs
5. Cross-check criterion numbers against: https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa
