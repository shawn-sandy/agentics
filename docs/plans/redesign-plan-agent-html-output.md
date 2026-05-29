---
status: completed
type: feature
created: 2026-05-29
repo-name: agentics
---

# Plan: Upgrade plan-agent HTML output with visual energy

## Context

The plan-agent's `SKELETON.html` produces correct, functional plans but the visual design is flat — plain white cards, muted grey section labels, no sidebar navigation, and a thin progress bar. The result feels like an internal ticket template rather than a compelling engineering artefact.

The `plan-interview` plugin contains a richer reference in its `markdown-to-html` skill (`kit/plugins/plan-interview/skills/markdown-to-html/`) with proven patterns: sticky sidebar + scroll rail, CSS step timeline with connectors and circle nodes, step chips (todo/done), localStorage persistence, and WCAG-compliant accessibility. Borrowing these patterns while preserving the plan-agent's card-based layout will produce dramatically more engaging plans.

## Objective

Overhaul `SKELETON.html` to adopt the visual and UX patterns from `plan-interview`'s `markdown-to-html` skill — sidebar navigation, step timeline, gradient header, step chips, localStorage persistence — then update `SKILL.md` writing-style guidance so generated content matches the elevated tone. Version bump to 0.6.0.

## Files to Change

| File | Change |
|------|--------|
| `kit/plugins/plan-agent/skills/planning/reference/SKELETON.html` | Full redesign — sidebar layout, CSS timeline, gradient header, step chips, localStorage, accessibility |
| `kit/plugins/plan-agent/skills/planning/SKILL.md` | Add writing-style addendum; remind AI to use `.step-chip` and correct classes |
| `kit/plugins/plan-agent/CHANGELOG.md` | v0.6.0 entry |
| `.claude-plugin/marketplace.json` | Bump plan-agent to 0.6.0 |
| `docs/plans/the-plan-agent-output-is-peppy-shore.md` | This file — commit with changes |

**Reference skill (read-only):**
`kit/plugins/plan-interview/skills/markdown-to-html/SKILL.md` and `assets/` — borrow patterns, do not copy verbatim.

---

## Implementation — `SKELETON.html`

### 1. Layout restructure — 2-column grid with sticky sidebar

Wrap the entire page in a `.layout` grid (220px sidebar + `1fr` main), mirroring `markdown-to-html`:

```html
<body>
  <a href="#main" class="skip-link">Skip to content</a>
  <header class="plan-header">…</header>
  <div class="layout">
    <nav class="plan-nav" aria-label="Plan sections">
      <div class="scroll-rail" aria-hidden="true"></div>
      <ul>
        <li><a href="#context">📋 Context</a></li>
        <li><a href="#steps">🚀 Steps</a></li>
        <li><a href="#criteria">✅ Criteria</a></li>
        <li><a href="#verification">🔍 Verification</a></li>
        <li><a href="#next-steps">🔜 Next Steps</a></li>
      </ul>
    </nav>
    <main id="main">
      <!-- section cards go here -->
    </main>
  </div>
</body>
```

CSS:
```css
.layout {
  display: grid;
  grid-template-columns: 200px 1fr;
  gap: 2rem;
  max-width: 1000px;
  margin: 0 auto;
  padding: 1.5rem 1rem 4rem;
  align-items: start;
}
.plan-nav {
  position: sticky;
  top: 1rem;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: .75rem 0;
  box-shadow: var(--shadow);
  overflow: hidden;
  position: relative;
}
@media (max-width: 700px) {
  .layout { grid-template-columns: 1fr; }
  .plan-nav { position: static; }
}
```

### 2. Gradient header with rainbow accent bar

Replace the plain white header with a rich dark-to-indigo gradient:

```css
.plan-header {
  background: linear-gradient(135deg, #0f172a 0%, #1e3a8a 60%, #312e81 100%);
  border: none;
  border-radius: 0;               /* full-width at top */
  padding: 0;
  position: relative;
}
.plan-header::before {
  content: "";
  display: block;
  height: 4px;
  background: linear-gradient(90deg, #38bdf8, #818cf8, #c084fc);
}
.plan-header-inner { padding: 1.75rem 2rem 1.5rem; max-width: 1000px; margin: 0 auto; }
.plan-title  { color: #f0f9ff; font-size: 1.7rem; font-weight: 700; }
.plan-meta   { color: #94a3b8; }
.status-badge text color shifts to white regardless of status (background drives the colour)
```

### 3. Scroll rail in sidebar

Identical pattern to `markdown-to-html/assets/scripts.js`:

```css
.plan-nav { position: relative; }   /* already set above */
.scroll-rail {
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 3px;
  background: var(--border);
  border-radius: 2px;
  overflow: hidden;
}
.scroll-rail::after {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0;
  height: calc(var(--scroll-pct, 0) * 1%);
  background: var(--accent);
  transition: height .1s linear;
}
```

JS (in embedded script at bottom):
```js
window.addEventListener('scroll', function () {
  var pct = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
  document.querySelector('.scroll-rail').style.setProperty('--scroll-pct', pct.toFixed(1));
});
```

### 4. Scroll spy — active sidebar link

Use `IntersectionObserver` (threshold 0.3) to track visible sections and toggle `class="active"` + `aria-current="true"` on sidebar links, mirroring `markdown-to-html` approach.

### 5. CSS step timeline — connector line + circle nodes

Change `.steps-list` to `position: relative` and add a vertical connector with circle nodes:

```css
.steps-list { position: relative; }
.steps-list::before {             /* vertical connector */
  content: "";
  position: absolute;
  left: 1.1rem;
  top: 1.5rem; bottom: 1.5rem;
  width: 2px;
  background: var(--border);
}
.step-card {
  position: relative;
  padding-left: 3rem;            /* room for timeline node */
}
.step-card::before {             /* circle node */
  content: "";
  position: absolute;
  left: .55rem; top: 1.25rem;
  width: .875rem; height: .875rem;
  border-radius: 50%;
  background: var(--border);
  border: 2px solid var(--surface);
  transition: background .2s;
}
.step-card.completed::before { background: var(--green); }
```

Move `.step-number` inside `.step-body` (it becomes the action number label, not the timeline node).

### 6. Step chips — todo / done status badges

Add a `.step-chip` span after each step number (mirroring `markdown-to-html`):

```html
<div class="step-action">
  <span class="step-chip" id="chip-1">todo</span>
  {step-1-action}
</div>
```

```css
.step-chip {
  display: inline-block;
  font-size: .65rem; font-weight: 700;
  text-transform: uppercase; letter-spacing: .05em;
  padding: .15em .5em;
  border-radius: 9999px;
  background: var(--grey-bg); color: var(--muted);
  margin-right: .5rem;
  vertical-align: middle;
  user-select: none;
}
.step-card.completed .step-chip {
  background: var(--green-bg); color: var(--green);
}
```

### 7. localStorage persistence for checkboxes

Replaces the existing minimal checkbox JS. Mirrors `markdown-to-html/assets/scripts.js`:

```js
var STORAGE_KEY = 'plan-steps-' + encodeURIComponent(document.title);

function saveSteps() {
  var state = {};
  document.querySelectorAll('#criteria-list input[type="checkbox"]').forEach(function (cb, i) {
    state[i] = cb.checked;
  });
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch(e) {}
}

function restoreSteps() {
  var raw; try { raw = localStorage.getItem(STORAGE_KEY); } catch(e) {}
  if (!raw) return;
  var state = JSON.parse(raw);
  document.querySelectorAll('#criteria-list input[type="checkbox"]').forEach(function (cb, i) {
    if (state[i]) { cb.checked = true; cb.dispatchEvent(new Event('change')); }
  });
}
```

### 8. Progress bar — animate on load + gradient fill

```css
.progress-bar-bg   { height: 12px; }
.progress-bar-fill {
  background: linear-gradient(90deg, #10b981, #06b6d4);
  transition: width .5s cubic-bezier(.4,0,.2,1);
}
@keyframes shimmer {
  0%   { background-position: -200% center; }
  100% { background-position:  200% center; }
}
.progress-bar-fill[style*="0%"] {   /* shimmer when at 0 */
  background-size: 200% 100%;
  animation: shimmer 2s linear infinite;
}
```

### 9. Section icons and coloured left borders

Each `.section-card` gets a semantic id (for sidebar anchoring) and a left accent border:

```html
<section class="section-card card-context" id="context" aria-labelledby="h-context">
  <h2 id="h-context"><span class="section-icon">📋</span> Context</h2>…
</section>
```

```css
.section-card { border-left: 4px solid transparent; transition: box-shadow .2s, transform .2s; }
.section-card:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(0,0,0,.1); }
.section-card h2 {
  font-size: .85rem; font-weight: 700;
  color: var(--text);            /* dark, not muted */
  text-transform: uppercase; letter-spacing: .05em;
}
.card-context      { border-left-color: #60a5fa; }
.card-steps        { border-left-color: #818cf8; }
.card-criteria     { border-left-color: #34d399; }
.card-verification { border-left-color: #fb923c; background: linear-gradient(135deg, #f0fdf4, #fff 60%); }
```

### 10. Pulsing in-progress status dot

```css
@keyframes pulse-dot { 0%, 100% { opacity: 1; } 50% { opacity: .3; } }
[data-status="in-progress"] .status-badge::before {
  animation: pulse-dot 1.4s ease-in-out infinite;
}
```

### 11. Stronger objective card

```css
.objective-card {
  background: linear-gradient(135deg, #eff6ff, #f0f9ff);
  border: 2px solid #3b82f6;
  border-left-width: 5px;
  font-size: 1.1rem;
  font-weight: 600;
}
```

### 12. Print styles

```css
@media print {
  .plan-nav, .scroll-rail { display: none; }
  .layout { display: block; }
  .plan-header { background: #000; color: #fff; }
  .step-card, .section-card { box-shadow: none; border: 1px solid #ccc; break-inside: avoid; }
  .step-chip, .progress-wrap { display: none; }
}
```

### 13. Accessibility baseline

- `<a href="#main" class="skip-link">` as first body child; visible on focus only
- `id` attributes on every `<section>` and `<h2>` (for `aria-labelledby`)
- `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax` on progress bar
- `aria-live="polite"` step status region (visually hidden, announces chip state change)

---

## SKILL.md Writing Style Addendum

Add under the existing **Writing Style** bullet in `SKILL.md`:

> **Tone:** Write like an enthusiastic senior engineer briefing the team. Objective: a rallying statement, not a ticket summary ("*Ship a dark-mode toggle that persists across themes*" not "*Add dark mode*"). Step actions: lead with a strong imperative verb ("*Wire up the ThemeContext provider*" not "*ThemeContext setup*"). Do not add extra emoji to prose — icons are provided by `<span class="section-icon">` in the skeleton HTML.

Also update the section template reminder: for each step card, include a `<span class="step-chip" id="chip-N">todo</span>` inside `.step-action` per the updated skeleton.

---

## Verification

1. Load the plugin locally: `claude --plugin-dir ./kit/plugins/plan-agent`
2. Run `/plan-agent:planning "add dark-mode toggle to settings page"`
3. Open the generated `.html` file in a browser and confirm:
   - **Header:** dark gradient with rainbow accent bar; title is white/light
   - **Layout:** two-column (sidebar + main) on desktop; collapses to 1 col on mobile
   - **Sidebar:** sticky, shows section links; scroll rail fills as you scroll
   - **Scroll spy:** active link highlighted as you scroll through sections
   - **Steps:** vertical connector line with circle nodes; nodes turn green when step is checked
   - **Step chips:** "todo"/"done" pill badges update when criteria checkboxes tick
   - **Section cards:** coloured left borders; cards lift on hover
   - **Progress bar:** 12px tall, teal-green gradient
   - **localStorage:** refresh page → checkbox state is restored
   - **Print:** `Ctrl+P` — sidebar hidden, clean single-column layout
4. Validate marketplace JSON: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"`
5. Confirm plan file is included in the commit.
