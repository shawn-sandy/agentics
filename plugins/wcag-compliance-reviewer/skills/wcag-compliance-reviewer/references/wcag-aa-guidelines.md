# WCAG 2.2 Level AA Success Criteria Reference

This document provides the complete list of WCAG 2.2 Level AA success criteria organized by principle.

## Table of Contents

1. [Perceivable](#1-perceivable)
2. [Operable](#2-operable)
3. [Understandable](#3-understandable)
4. [Robust](#4-robust)

---

## 1. Perceivable

Information and user interface components must be presentable to users in ways they can perceive.

### 1.1 Text Alternatives

**1.1.1 Non-text Content (Level A)**
- All non-text content must have text alternatives that serve the equivalent purpose
- Images: Use alt text describing the content/function
- Decorative images: Use empty alt="" or aria-hidden="true"
- Complex images: Provide longer descriptions via aria-describedby or adjacent text
- Form inputs: Use labels, aria-label, or aria-labelledby
- Icons: Provide text alternatives or aria-labels

### 1.2 Time-based Media

**1.2.1 Audio-only and Video-only (Level A)**
- Pre-recorded audio-only: Provide transcript
- Pre-recorded video-only: Provide transcript or audio description

**1.2.2 Captions (Level A)**
- Captions required for all pre-recorded audio content in synchronized media

**1.2.3 Audio Description or Media Alternative (Level A)**
- Audio description or text alternative for pre-recorded video

**1.2.4 Captions (Live) (Level AA)**
- Captions required for all live audio content in synchronized media

**1.2.5 Audio Description (Level AA)**
- Audio description for all pre-recorded video content

### 1.3 Adaptable

**1.3.1 Info and Relationships (Level A)**
- Information, structure, and relationships conveyed through presentation must be programmatically determinable
- Use semantic HTML: header, nav, main, article, section, aside, footer
- Use proper heading hierarchy (h1-h6)
- Use lists (ul, ol, dl) for list content
- Use tables with proper headers (th) and scope attributes
- Use fieldset and legend for form groups
- Use aria-labelledby and aria-describedby for relationships

**1.3.2 Meaningful Sequence (Level A)**
- Reading and navigation order must be logical and intuitive
- DOM order should match visual order
- Use CSS for layout, not to change reading order

**1.3.3 Sensory Characteristics (Level A)**
- Instructions must not rely solely on sensory characteristics (shape, size, visual location, orientation, sound)
- Bad: "Click the round button on the right"
- Good: "Click the Submit button (round button on the right)"

**1.3.4 Orientation (Level AA)**
- Content must not restrict view and operation to a single display orientation (portrait or landscape)
- Exception: When specific orientation is essential

**1.3.5 Identify Input Purpose (Level AA)**
- Input fields that collect user information must have autocomplete attributes
- Use HTML autocomplete attribute for common input types (name, email, address, etc.)

### 1.4 Distinguishable

**1.4.1 Use of Color (Level A)**
- Color must not be the only visual means of conveying information, indicating action, prompting response, or distinguishing elements
- Links must be distinguished by more than color alone (underline, icon, etc.)
- Form validation errors need icons or text, not just red color

**1.4.2 Audio Control (Level A)**
- If audio plays automatically for more than 3 seconds, provide mechanism to pause/stop/control volume

**1.4.3 Contrast (Minimum) (Level AA)**
- Text contrast ratio of at least 4.5:1 for normal text
- Text contrast ratio of at least 3:1 for large text (18pt+ or 14pt+ bold)
- Applies to text and images of text
- Exceptions: Logos, inactive UI components, pure decoration

**1.4.4 Resize Text (Level AA)**
- Text can be resized up to 200% without loss of content or functionality
- No horizontal scrolling required
- Test: Browser zoom to 200%

**1.4.5 Images of Text (Level AA)**
- Use actual text rather than images of text
- Exceptions: Customizable by user, essential presentation (logos)

**1.4.10 Reflow (Level AA)**
- Content must reflow to single column at 320px width (or 256px height for horizontal scrolling)
- No loss of information or functionality
- No two-dimensional scrolling required
- Exception: Content requiring two-dimensional layout (data tables, maps, diagrams)

**1.4.11 Non-text Contrast (Level AA)**
- UI components and graphical objects have contrast ratio of at least 3:1
- Applies to: Form inputs, buttons, focus indicators, icons, charts
- Active UI components must be distinguishable from surrounding content

**1.4.12 Text Spacing (Level AA)**
- No loss of content or functionality when users apply:
  - Line height (line spacing) at least 1.5x font size
  - Spacing following paragraphs at least 2x font size
  - Letter spacing at least 0.12x font size
  - Word spacing at least 0.16x font size

**1.4.13 Content on Hover or Focus (Level AA)**
- For content that appears on hover or focus:
  - Dismissible: Can be dismissed without moving pointer/focus
  - Hoverable: Pointer can move to the triggered content
  - Persistent: Remains visible until dismissed, hover/focus removed, or no longer valid

---

## 2. Operable

User interface components and navigation must be operable.

### 2.1 Keyboard Accessible

**2.1.1 Keyboard (Level A)**
- All functionality must be available via keyboard
- No keyboard traps
- Custom controls must be keyboard accessible
- Use native HTML controls when possible

**2.1.2 No Keyboard Trap (Level A)**
- Users must be able to navigate away from any component using only keyboard
- If non-standard exit needed, users must be informed

**2.1.4 Character Key Shortcuts (Level A)**
- If single character shortcuts exist, at least one of:
  - Can be turned off
  - Can be remapped
  - Only active when component has focus

### 2.2 Enough Time

**2.2.1 Timing Adjustable (Level A)**
- For time limits, provide one of:
  - Ability to turn off
  - Ability to adjust (at least 10x default)
  - Ability to extend before time expires (at least 20 seconds warning)

**2.2.2 Pause, Stop, Hide (Level A)**
- For moving, blinking, scrolling, or auto-updating content:
  - If auto-starts, lasts >5 seconds, and presented with other content: Provide pause/stop/hide mechanism
  - For auto-updating: Provide pause/stop/hide or control frequency

### 2.3 Seizures and Physical Reactions

**2.3.1 Three Flashes or Below Threshold (Level A)**
- Content must not flash more than 3 times per second
- Or flash must be below general flash and red flash thresholds

### 2.4 Navigable

**2.4.1 Bypass Blocks (Level A)**
- Provide mechanism to bypass repeated blocks (skip links, ARIA landmarks)
- "Skip to main content" link
- Proper landmark regions

**2.4.2 Page Titled (Level A)**
- Pages have descriptive titles
- Use descriptive &lt;title&gt; elements

**2.4.3 Focus Order (Level A)**
- Focusable elements receive focus in logical order
- DOM order matches visual order for interactive elements

**2.4.4 Link Purpose (In Context) (Level A)**
- Link purpose can be determined from link text or context
- Avoid "click here" or "read more" without context
- Use descriptive link text

**2.4.5 Multiple Ways (Level AA)**
- Multiple ways to locate pages (navigation, search, sitemap, etc.)
- Exception: Web page is result of a process step

**2.4.6 Headings and Labels (Level AA)**
- Headings and labels are descriptive
- Use proper heading hierarchy
- Label form inputs clearly

**2.4.7 Focus Visible (Level AA)**
- Keyboard focus indicator must be visible
- Default browser focus rings acceptable
- Custom focus indicators must have 3:1 contrast ratio

**2.4.11 Focus Not Obscured (Minimum) (Level AA)** — NEW in WCAG 2.2
- When a user interface component receives keyboard focus, it must be at least partially visible
- Must not be entirely hidden behind author-created content such as sticky headers, sticky footers, or non-modal dialogs
- Ensures keyboard users can always see where their focus is

### 2.5 Input Modalities

**2.5.1 Pointer Gestures (Level A)**
- All functionality using multipoint or path-based gestures has single-pointer alternative
- Exception: When multipoint/path is essential

**2.5.2 Pointer Cancellation (Level A)**
- For single-pointer functionality:
  - No down-event activation
  - Or up-event can abort/undo
  - Or down-event reversal available
  - Or down-event essential
- Prevents accidental activation

**2.5.3 Label in Name (Level A)**
- For UI components with labels that include text or images of text:
  - Accessible name contains visible text
  - Visible label matches or is contained in accessible name

**2.5.4 Motion Actuation (Level A)**
- Functionality operated by device motion or user motion can also be operated by UI components
- Motion actuation can be disabled

**2.5.7 Dragging Movements (Level AA)** — NEW in WCAG 2.2
- All functionality using dragging motions must have a single-pointer alternative
- Exception: When dragging is essential

**2.5.8 Target Size (Minimum) (Level AA)** — NEW in WCAG 2.2
- Touch/pointer targets must be at least 24×24 CSS pixels
- Exception: Inline targets (links within text), agent-controlled, essential presentation

---

## 3. Understandable

Information and user interface operation must be understandable.

### 3.1 Readable

**3.1.1 Language of Page (Level A)**
- Default human language of page is programmatically determinable
- Set lang attribute on &lt;html&gt; element

**3.1.2 Language of Parts (Level AA)**
- Language of each passage or phrase can be programmatically determined
- Use lang attribute on elements with different languages

### 3.2 Predictable

**3.2.1 On Focus (Level A)**
- Receiving focus does not initiate change of context
- No automatic navigation, form submission, etc. on focus alone

**3.2.2 On Input (Level A)**
- Changing component value does not automatically cause change of context
- Warn users before context changes
- Use submit buttons for form submission

**3.2.3 Consistent Navigation (Level AA)**
- Navigation mechanisms repeated on multiple pages occur in same relative order
- Consistent menu/navigation placement

**3.2.4 Consistent Identification (Level AA)**
- Components with same functionality are identified consistently
- Icons, buttons, links with same function have consistent labels

**3.2.6 Consistent Help (Level A)** — NEW in WCAG 2.2
- If a help mechanism (human contact, self-help, automated) appears on multiple pages, it must appear in the same relative order

### 3.3 Input Assistance

**3.3.1 Error Identification (Level A)**
- Input errors are automatically detected and described to user in text
- Use aria-invalid and error messages
- Associate errors with fields using aria-describedby

**3.3.2 Labels or Instructions (Level A)**
- Labels or instructions provided when content requires user input
- Label all form fields
- Provide instructions for complex inputs

**3.3.3 Error Suggestion (Level AA)**
- If input error detected and suggestions known, provide suggestions to user
- Exception: Security or purpose compromised

**3.3.4 Error Prevention (Legal, Financial, Data) (Level AA)**
- For legal/financial transactions or data submissions:
  - Reversible: Submissions are reversible
  - Checked: Data is checked for errors and user can correct
  - Confirmed: Confirmation mechanism available

**3.3.7 Redundant Entry (Level A)** — NEW in WCAG 2.2
- Information entered in a previous step that is required again in the same process must be auto-populated or selectable
- Exception: When re-entering is essential (passwords), or the information is no longer valid

**3.3.8 Accessible Authentication (Minimum) (Level AA)** — NEW in WCAG 2.2
- Authentication process must not require cognitive function test (memorizing, transcribing, solving)
- Exception: Alternative method available, or test uses object/personal content recognition

---

## 4. Robust

Content must be robust enough to be interpreted by a wide variety of user agents, including assistive technologies.

### 4.1 Compatible

~~**4.1.1 Parsing**~~ (Removed in WCAG 2.2)
- This criterion was deprecated and removed in WCAG 2.2. Modern browsers handle malformed HTML consistently, making it no longer necessary for accessibility compliance.

**4.1.2 Name, Role, Value (Level A)**
- For all UI components:
  - Name and role can be programmatically determined
  - States, properties, values can be programmatically set
  - Notification of changes available to user agents
- Use semantic HTML or proper ARIA attributes
- Ensure custom controls properly communicate state

**4.1.3 Status Messages (Level AA)**
- Status messages can be programmatically determined through role or properties
- Can be presented without receiving focus
- Use ARIA live regions: aria-live, role="status", role="alert"
- For success messages, errors, progress, etc.

---

## Quick Reference: Most Common AA Issues

1. **Color contrast** - Text must have 4.5:1 ratio (3:1 for large text)
2. **Keyboard access** - All interactive elements keyboard operable
3. **Focus indicators** - Visible focus states required
4. **Focus not obscured** - Focused element at least partially visible, not hidden by sticky content — NEW in 2.2
5. **Alt text** - Images need descriptive alternatives
6. **Form labels** - All inputs must be labeled
7. **Heading structure** - Logical heading hierarchy
8. **ARIA** - Proper ARIA usage (name, role, value)
9. **Link text** - Descriptive link text
10. **Language** - Page language declared
11. **Responsive** - Content reflows at 320px width
12. **Target size** - Touch/pointer targets at least 24×24 CSS px — NEW in 2.2
13. **Dragging alternatives** - Single-pointer alternative required for all drag interactions — NEW in 2.2
14. **Redundant entry** - Auto-populate information across process steps — NEW in 2.2
15. **Accessible authentication** - No cognitive function test in auth flow — NEW in 2.2
16. ~~**Parsing (4.1.1)**~~ - Removed in WCAG 2.2; no longer required

---

## Documentation Links

- WCAG 2.2 Official: https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa
- Understanding WCAG 2.2: https://www.w3.org/WAI/WCAG22/Understanding/
- ARIA Authoring Practices: https://www.w3.org/WAI/ARIA/apg/
