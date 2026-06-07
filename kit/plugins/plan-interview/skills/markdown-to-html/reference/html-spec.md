# HTML Output Specification for markdown-to-html

<!-- SPEC AUTHORITATIVE: This file is the single source of truth for HTML output.
     scripts/build-assets.sh extracts tagged blocks to generate assets/themes.css
     and assets/scripts.js. All CSS/JS changes must be made here first. -->

This file defines the layout contract, security rules, semantic requirements, theme
palettes, visual enhancements, and JavaScript features that the `markdown-to-html`
skill must follow when generating HTML output. The skill references this file in its
synthesis step — do not embed the full spec in `SKILL.md`.

---

## Security and Encoding

All user-controlled content must be encoded at the sink, never at source.

### Per-sink encoding rules

| Sink | Rule |
|---|---|
| HTML text nodes (body, headings, step text) | Replace `&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;`, `"`→`&quot;` |
| HTML attribute values | Same as above, PLUS `'`→`&#39;` |
| SVG `<text>` content | Same HTML-entity encoding as text nodes |
| Link `href` attribute | Allow-list check (see below) BEFORE attribute-encoding |

### URL allow-list

Only emit `<a href="...">` when the URL starts with one of:

- `http://`
- `https://`
- `mailto:`
- `#`

For any other scheme (`javascript:`, `data:`, `vbscript:`, `file://`, etc.):
render the label as plain escaped text and discard the URL entirely.

### Theme allow-list

Valid theme names: `default`, `developer`, `document`, `minimal`.

Before interpolating into `<body class="theme-{value}">`, validate against this
list. If the value is not in the list, fall back to `default`. Never interpolate
an unvalidated value into a class attribute.

### Path traversal defense

Before reading any input file (SKILL.md Step 1):

1. Resolve the absolute path with `realpath`.
2. Confirm it is under `$PWD`.
3. Confirm the extension is `.md` or `.markdown`.
4. Confirm it is not a symlink pointing outside the workspace.

On failure: print an error identifying the failing check and stop with non-zero exit.

---

## Render Modes

The skill operates in one of two modes.

### Plan mode

Auto-detected when **any** of the following is true:
- The source file contains a `## Steps` section, OR
- The YAML frontmatter contains a `status:` key AND the H1 starts with `Plan:`

Plan-mode output includes:
- Sidebar navigation with scroll-rail
- Step cards with checkboxes, localStorage persistence, step-chip labels
- CSS step timeline (connector lines via `::before` on `<ol>` + circle nodes via `::before` on `<li>`)
- SVG section diagram (when ≥2 sections present)
- Progress bar dynamically updated from checkbox completion percentage

Force with `--mode=plan`.

### Doc mode

Active when plan-mode detection does not trigger, or when `--mode=doc` is passed.

Doc-mode output:
- Sidebar navigation (no scroll-rail)
- No step cards — body rendered as flowing prose and lists
- No timeline, no SVG diagram, no dynamic progress bar
- `## Heading` sections become `<section id="...">` + `<h2>`
- All markdown rendering rules apply

Force with `--mode=doc`.

---

## Page Structure

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{plain-text document title}</title>
    <style>/* all CSS inline — no external stylesheets */</style>
  </head>
  <body class="theme-{validated-theme}">
    <a href="#main-content" class="skip-link">Skip to main content</a>
    <header>
      <!-- plan mode only: -->
      <div class="progress-bar" role="progressbar" aria-valuenow="{pct}"
           aria-valuemin="0" aria-valuemax="100" aria-label="Plan progress">
        <div class="progress-fill" style="width:{pct}%"></div>
      </div>
      <h1>{title}</h1>
      <button class="save-pdf-btn" type="button" onclick="savePDF()"
              aria-label="Save this plan as PDF">
        Save as PDF
      </button>
      <!-- plan mode only: -->
      <span class="status-badge status-{value}">{label}</span>
      <div class="metadata-row">…</div>
    </header>
    <div class="layout">
      <nav aria-label="Document sections">
        <!-- plan mode only: -->
        <div class="scroll-rail" aria-hidden="true"></div>
        <ul>
          <li><a href="#context">Context</a></li>
        </ul>
      </nav>
      <main id="main-content">
        <section id="context" aria-labelledby="context-heading">
          <h2 id="context-heading">Context</h2>…
        </section>
      </main>
    </div>
    <script>/* all JS inline — no external scripts */</script>
  </body>
</html>
```

**`<title>` content:** Plain text only — no HTML tags inside `<title>`.

**Skip link:** `<a href="#main-content" class="skip-link">` must be the first
focusable element inside `<body>`. `<main>` must carry `id="main-content"`.

**Section labeling:** Each `<section>` must have `aria-labelledby` pointing to
its `<h2 id="…-heading">`. This satisfies WCAG SC 1.3.1.

**External resource policy:** No `<link>` to external stylesheets. No CDN URLs.
No `@import url(…)`. Fully self-contained.

---

## Header

The `<header>` element contains in order:

1. Progress bar (plan mode only — see **Progress Indicator**)
2. `<h1>` — document title (H1 from source, `Plan:` prefix stripped)
3. Save as PDF button (both modes — see **Save as PDF Button**)
4. Status badge (plan mode only — see **Status Badge**)
5. Metadata row

**Metadata field rendering:**

| Field | Absent behavior |
|---|---|
| `created` | Render as `n/a` |
| `modified` | Omit from metadata row entirely |
| `type` | Omit from metadata row entirely |
| `status` | Render badge as `unknown` |

The selected theme name is always shown in the metadata row (runtime choice,
not read from frontmatter).

---

## Navigation (Sticky Sidebar)

```html
<nav aria-label="Document sections">
  <div class="scroll-rail" aria-hidden="true"></div><!-- plan mode only -->
  <ul>
    <li><a href="#context">Context</a></li>
  </ul>
</nav>
```

- `position: sticky; top: 1rem` on the nav element (collapsed to `static` on mobile)
- Only include anchor links for sections present in the source document
- Active state: scroll-spy sets `class="active"` AND `aria-current="true"` on the
  `<a>` for the currently visible section (WCAG SC 4.1.2)

**Scroll rail:** `<div class="scroll-rail" aria-hidden="true">` positioned inside
`<nav>` (plan mode only). JS updates `--scroll-pct` on this element as the user
scrolls, producing a visual progress indicator in the sidebar.

---

## Steps Section (Plan Mode Only)

```html
<section id="steps" aria-labelledby="steps-heading">
  <h2 id="steps-heading">Steps</h2>
  <ol class="steps-list">
    <li class="step-card" data-step-id="{plan-slug}-{index}">
      <label class="step-label">
        <input type="checkbox" class="step-checkbox"
               id="step-{plan-slug}-{index}"
               aria-describedby="step-why-{index}">
        <span class="step-chip" aria-hidden="true">todo</span>
        <h3 class="step-action">{action text}</h3>
      </label>
      <p class="step-why" id="step-why-{index}">{why text}</p>
      <p class="step-verify">&#10003; {verify text}</p>
      <span class="step-status" aria-live="polite" aria-atomic="true"></span>
    </li>
  </ol>
</section>
```

**Checkbox accessibility:**
- `<input type="checkbox">` has `id` and is wrapped in `<label>` (wrap pattern)
- `aria-describedby` points to `step-why-{index}` paragraph
- The `<label>` wraps: checkbox + chip + h3 — click area covers all three

**Step chip:** `<span class="step-chip" aria-hidden="true">` is a real element (not
`::after`), freeing both pseudo-elements for the timeline. JS updates `textContent`
to `done` when checked.

**Step status live region:** `<span class="step-status" aria-live="polite">`
announces completion to screen readers. JS sets text to
"Step {n} marked as complete" / "Step {n} marked as incomplete".

**Completed card behavior:**
- Checkbox checked → card gets `class="step-card completed"`
- `step-action` gets `text-decoration: line-through; opacity: 0.6`
- `step-chip` text → `done`

**No why/verify:** Omit those `<p>` elements entirely when absent in the source.

---

## CSS Step Timeline (Plan Mode Only)

<!-- BUILD-EXTRACT:TIMELINE-CSS START -->
```css
.steps-list {
  list-style: none;
  padding-left: 2rem;
  position: relative;
}

/* Vertical connector line */
.steps-list::before {
  content: "";
  position: absolute;
  left: 0.75rem;
  top: 1.5rem;
  bottom: 1.5rem;
  width: 2px;
  background: var(--color-border);
}

/* Circle node per step */
.step-card::before {
  content: "";
  position: absolute;
  left: -1.6rem;
  top: 1.25rem;
  width: 0.75rem;
  height: 0.75rem;
  border-radius: 50%;
  background: var(--color-border);
  border: 2px solid var(--color-card-bg);
  transition: background 0.2s ease;
}

.step-card.completed::before {
  background: var(--color-accent);
  border-color: var(--color-accent);
}

@media (prefers-reduced-motion: reduce) {
  .step-card::before { transition: none; }
}
```
<!-- BUILD-EXTRACT:TIMELINE-CSS END -->

---

## Status Chip (Plan Mode Only)

<!-- BUILD-EXTRACT:CHIP-CSS START -->
```css
.step-chip {
  display: inline-block;
  font-size: 0.65rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0.15em 0.5em;
  border-radius: 9999px;
  background: var(--color-border);
  color: var(--color-body-text);
  vertical-align: middle;
  margin-right: 0.5rem;
  user-select: none;
}

.step-card.completed .step-chip {
  background: var(--color-accent);
  color: #fff;
}
```
<!-- BUILD-EXTRACT:CHIP-CSS END -->

---

## Scroll Rail (Plan Mode Only)

<!-- BUILD-EXTRACT:RAIL-CSS START -->
```css
.scroll-rail {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--color-border);
  border-radius: 2px;
  overflow: hidden;
}

.scroll-rail::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: calc(var(--scroll-pct, 0) * 1%);
  background: var(--color-accent);
  transition: height 0.1s linear;
}

@media (prefers-reduced-motion: reduce) {
  .scroll-rail::after { transition: none; }
}
```
<!-- BUILD-EXTRACT:RAIL-CSS END -->

---

## Status Badge (Plan Mode Only)

```html
<span class="status-badge status-{value}">{label}</span>
```

| Frontmatter value | CSS class | Label | Color |
|---|---|---|---|
| `todo` | `status-todo` | todo | Gray `#6b7280` |
| `in-progress` | `status-in-progress` | in progress | Amber `#d97706` |
| `completed` | `status-completed` | completed | Green `#16a34a` |
| absent or unknown | `status-unknown` | unknown | Gray `#6b7280` |

Badge style: rounded pill, small font, white text, `padding: 0.2em 0.7em`.

---

## Save as PDF Button

Present in both plan and doc modes. Placed in the header between `<h1>` and the
status badge (or metadata row in doc mode).

```html
<button class="save-pdf-btn" type="button" onclick="savePDF()"
        aria-label="Save this plan as PDF">
  Save as PDF
</button>
```

Clicking triggers `window.print()`, which opens the browser's native print
dialog. On Chrome, Edge, Firefox, and Safari the dialog offers a "Save as PDF"
destination. No external dependencies.

<!-- BUILD-EXTRACT:SAVE-PDF-CSS START -->
```css
.save-pdf-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.4rem 1rem;
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
  background: var(--color-accent);
  border: 1px solid var(--color-accent);
  border-radius: 4px;
  cursor: pointer;
  font-family: inherit;
  line-height: 1.4;
  white-space: nowrap;
  transition: background 0.15s, box-shadow 0.15s;
}
.save-pdf-btn:hover {
  filter: brightness(0.85);
  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
}
.save-pdf-btn:active { filter: brightness(0.75); }
.save-pdf-btn:focus-visible { outline: 3px solid var(--color-accent); outline-offset: 2px; }
@media (prefers-reduced-motion: reduce) { .save-pdf-btn { transition: none; } }
```
<!-- BUILD-EXTRACT:SAVE-PDF-CSS END -->

Hidden in print output (see **Print Styles**).

---

## Progress Indicator (Plan Mode Only)

| Status | Fill width | Color |
|---|---|---|
| `todo` | `5%` | Gray `#6b7280` |
| `in-progress` | `50%` | Amber `#d97706` |
| `completed` | `100%` | Green `#16a34a` |
| absent or unknown | `5%` | Gray `#6b7280` |

JS updates the fill dynamically from checkbox completion percentage when steps exist.

```css
.progress-bar {
  width: 100%;
  height: 4px;
  background: rgba(255,255,255,0.2);
}
.progress-fill {
  height: 100%;
  background: {status-color};
  transition: width 0.3s ease;
}
@media (prefers-reduced-motion: reduce) {
  .progress-fill { transition: none; }
}
```

---

## SVG Section Diagram (Plan Mode Only)

Render when ≥2 sections are present. Place inside a `<figure>` after `<header>`:

```html
<figure class="section-diagram" aria-labelledby="diagram-title">
  <svg role="img" aria-labelledby="diagram-title"
       viewBox="0 0 {W} 80" width="100%" height="80">
    <title id="diagram-title">Plan sections: {comma-separated names}</title>
    <!-- connector lines, then nodes -->
    <line x1="{prev+nodeWidth}" y1="40" x2="{nextX}" y2="40"
          stroke="var(--color-border)" stroke-width="2"/>
    <g class="svg-node" data-section="{section-id}" style="cursor:pointer">
      <rect x="{x}" y="22" width="{nodeWidth}" height="36"
            rx="6" fill="var(--color-card-bg)" stroke="var(--color-border)"/>
      <text x="{cx}" y="44" text-anchor="middle"
            font-size="11" fill="var(--color-body-text)">{name}</text>
    </g>
  </svg>
  <figcaption>{count} sections</figcaption>
</figure>
```

**Auto-compact geometry:**

```
nodeWidth  = max(60, min(120, floor(1024 / sectionCount)))
nodeHeight = 36
gap        = max(8, min(24, floor((1024 - sectionCount * nodeWidth) / (sectionCount - 1))))
W          = sectionCount * nodeWidth + (sectionCount - 1) * gap
```

**Accessibility:** `role="img"` + `aria-labelledby` on `<svg>`. `<title>` as first
child of `<svg>`. SVG `<text>` content HTML-entity-encoded.

**Interaction:** JS adds a `click` listener to each `.svg-node` that calls
`document.getElementById(section-id).scrollIntoView({behavior:'smooth'})`.

---

## Color Palette Themes

<!-- BUILD-EXTRACT:THEMES START -->
```css
body.theme-default {
  --color-header-bg: #1e293b;
  --color-header-text: #f8fafc;
  --color-nav-bg: #f1f5f9;
  --color-nav-text: #334155;
  --color-nav-hover: #2563eb;
  --color-accent: #2563eb;
  --color-body-bg: #ffffff;
  --color-body-text: #1e293b;
  --color-muted: #64748b;
  --color-border: #e2e8f0;
  --color-card-bg: #f8fafc;
  --color-code-bg: #e2e8f0;
}

body.theme-developer {
  --color-header-bg: #0d1117;
  --color-header-text: #e6edf3;
  --color-nav-bg: #161b22;
  --color-nav-text: #8b949e;
  --color-nav-hover: #3fb950;
  --color-accent: #3fb950;
  --color-body-bg: #0d1117;
  --color-body-text: #e6edf3;
  --color-muted: #8b949e;
  --color-border: #30363d;
  --color-card-bg: #161b22;
  --color-code-bg: #21262d;
}

body.theme-document {
  --color-header-bg: #4a3728;
  --color-header-text: #fdf6ec;
  --color-nav-bg: #fdf6ec;
  --color-nav-text: #4a3728;
  --color-nav-hover: #8b5e3c;
  --color-accent: #8b5e3c;
  --color-body-bg: #fdf6ec;
  --color-body-text: #2c1a0e;
  --color-muted: #6b4c38;
  --color-border: #d4b896;
  --color-card-bg: #f5eddf;
  --color-code-bg: #ede0cc;
}

body.theme-minimal {
  --color-header-bg: #000000;
  --color-header-text: #ffffff;
  --color-nav-bg: #ffffff;
  --color-nav-text: #000000;
  --color-nav-hover: #333333;
  --color-accent: #000000;
  --color-body-bg: #ffffff;
  --color-body-text: #000000;
  --color-muted: #555555;
  --color-border: #dddddd;
  --color-card-bg: #f9f9f9;
  --color-code-bg: #eeeeee;
}
```
<!-- BUILD-EXTRACT:THEMES END -->

All four themes share the identical layout. Only CSS custom properties differ.
Define them on `body.theme-*` (no `:root` defaults needed — a theme class is always
present).

| Property | Purpose |
|---|---|
| `--color-header-bg` | `<header>` background |
| `--color-header-text` | `<header>` text and `<h1>` |
| `--color-nav-bg` | Sidebar background |
| `--color-nav-text` | Sidebar link text |
| `--color-nav-hover` | Sidebar link hover |
| `--color-accent` | Links, verify checkmarks, active states |
| `--color-body-bg` | `<main>` and page background |
| `--color-body-text` | Main body text |
| `--color-muted` | `step-why` muted text |
| `--color-border` | Card borders and dividers |
| `--color-card-bg` | Step card background |
| `--color-code-bg` | Inline `<code>` background |

---

## Global Styles

<!-- BUILD-EXTRACT:GLOBAL-STYLES START -->
```css
.skip-link {
  position: absolute;
  left: -9999px;
  top: auto;
  width: 1px;
  height: 1px;
  overflow: hidden;
}
.skip-link:focus {
  position: static;
  width: auto;
  height: auto;
  padding: 0.5rem 1rem;
  background: var(--color-accent);
  color: #fff;
  z-index: 100;
}

:focus-visible {
  outline: 3px solid var(--color-accent);
  outline-offset: 2px;
}

html { scroll-behavior: smooth; }

body {
  margin: 0;
  font-family: system-ui, -apple-system, sans-serif;
  background: var(--color-body-bg);
  color: var(--color-body-text);
}

header {
  background: var(--color-header-bg);
  color: var(--color-header-text);
  padding: 1.5rem 2rem 1rem;
}

header h1 {
  margin: 0.5rem 0 0.25rem;
  font-size: 1.5rem;
  color: var(--color-header-text);
}

.metadata-row {
  font-size: 0.8rem;
  opacity: 0.75;
  margin-top: 0.5rem;
}

.status-badge {
  display: inline-block;
  padding: 0.2em 0.7em;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  color: #fff;
}
.status-todo, .status-unknown { background: #6b7280; }
.status-in-progress { background: #d97706; }
.status-completed { background: #16a34a; }

.layout {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: 2rem;
  max-width: 1024px;
  margin: 0 auto;
  padding: 1.5rem;
}

nav {
  position: sticky;
  top: 1rem;
  align-self: start;
  background: var(--color-nav-bg);
  border-radius: 8px;
  padding: 0.75rem 0;
}

nav ul { list-style: none; padding: 0 0 0 1rem; margin: 0; }

nav a {
  display: flex;
  align-items: center;
  min-height: 44px;
  padding: 0.35rem 0.5rem;
  color: var(--color-nav-text);
  text-decoration: none;
  border-radius: 4px;
  font-size: 0.875rem;
}

nav a:hover { color: var(--color-nav-hover); }

nav a.active,
nav a[aria-current="true"] {
  color: var(--color-accent);
  font-weight: 600;
}

main { min-width: 0; }

section { margin-bottom: 2rem; }

.step-card {
  background: var(--color-card-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem 1.25rem;
  margin-bottom: 0.75rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  transition: box-shadow 0.15s ease, transform 0.15s ease;
  position: relative;
}

.step-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.12);
  transform: translateY(-1px);
}

.step-card.completed .step-action {
  text-decoration: line-through;
  opacity: 0.6;
}

.step-label {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  cursor: pointer;
}

.step-checkbox {
  width: 1.25rem;
  height: 1.25rem;
  flex-shrink: 0;
  cursor: pointer;
  margin-top: 0.2rem;
}

.step-action { margin: 0; font-size: 1rem; }

.step-why {
  color: var(--color-muted);
  font-size: 0.875rem;
  margin: 0.5rem 0 0;
}

.step-verify {
  color: var(--color-accent);
  font-size: 0.875rem;
  margin: 0.25rem 0 0;
}

.step-status {
  position: absolute;
  left: -9999px;
  width: 1px;
  height: 1px;
  overflow: hidden;
}

code {
  background: var(--color-code-bg);
  border-radius: 3px;
  padding: 0.1em 0.35em;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 0.875em;
}

pre {
  background: var(--color-code-bg);
  border: 1px solid var(--color-border);
  border-radius: 6px;
  padding: 1rem;
  overflow-x: auto;
}

pre code { background: none; padding: 0; font-size: 0.85em; }

.section-diagram {
  max-width: 1024px;
  margin: 0 auto 1rem;
  padding: 0 1.5rem;
  overflow-x: auto;
}

.section-diagram figcaption {
  font-size: 0.75rem;
  color: var(--color-muted);
  text-align: center;
  margin-top: 0.25rem;
}

@media (prefers-reduced-motion: reduce) {
  html { scroll-behavior: auto; }
  .step-card { transition: none; }
  .step-card:hover { transform: none; }
  .progress-fill { transition: none; }
}

@media (max-width: 768px) {
  .layout { grid-template-columns: 1fr; }
  nav { position: static; }
  .scroll-rail { display: none; }
}
```
<!-- BUILD-EXTRACT:GLOBAL-STYLES END -->

---

## JavaScript Features

<!-- BUILD-EXTRACT:SAVE-PDF-JS START -->
```javascript
function savePDF() {
  window.print();
}
```
<!-- BUILD-EXTRACT:SAVE-PDF-JS END -->

<!-- BUILD-EXTRACT:SCROLL-SPY START -->
```javascript
(function () {
  'use strict';
  var links = {};
  document.querySelectorAll('nav a[href^="#"]').forEach(function (a) {
    links[a.getAttribute('href').slice(1)] = a;
  });
  var rail = document.querySelector('.scroll-rail');
  function updateRail() {
    if (!rail) return;
    var pct = (window.scrollY / Math.max(1,
      document.documentElement.scrollHeight - window.innerHeight)) * 100;
    rail.style.setProperty('--scroll-pct', Math.min(100, Math.round(pct)));
  }
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        Object.values(links).forEach(function (a) {
          a.classList.remove('active');
          a.removeAttribute('aria-current');
        });
        var link = links[entry.target.id];
        if (link) {
          link.classList.add('active');
          link.setAttribute('aria-current', 'true');
        }
      }
    });
  }, { threshold: 0.3 });
  document.querySelectorAll('main section').forEach(function (s) {
    observer.observe(s);
  });
  document.querySelectorAll('.svg-node').forEach(function (node) {
    node.addEventListener('click', function () {
      var id = node.dataset.section;
      var el = id && document.getElementById(id);
      if (el) el.scrollIntoView({ behavior: 'smooth' });
    });
  });
  window.addEventListener('scroll', updateRail, { passive: true });
  updateRail();
})();
```
<!-- BUILD-EXTRACT:SCROLL-SPY END -->

<!-- BUILD-EXTRACT:STEP-COMPLETION START -->
```javascript
(function () {
  'use strict';
  var STORE_KEY = 'plan-steps-' + encodeURIComponent(document.title);
  var saved = {};
  try { saved = JSON.parse(localStorage.getItem(STORE_KEY) || '{}'); } catch (e) {}

  function updateProgress() {
    var bar = document.querySelector('.progress-bar[role="progressbar"]');
    var fill = document.querySelector('.progress-fill');
    if (!fill) return;
    var boxes = document.querySelectorAll('.step-checkbox');
    if (!boxes.length) return;
    var checked = Array.from(boxes).filter(function (b) { return b.checked; }).length;
    var pct = Math.round((checked / boxes.length) * 100);
    fill.style.width = pct + '%';
    if (bar) {
      bar.setAttribute('aria-valuenow', String(pct));
      bar.setAttribute('aria-valuetext', pct + '% complete');
    }
  }

  document.querySelectorAll('.step-card').forEach(function (card, idx) {
    var id = card.dataset.stepId;
    var cb = card.querySelector('.step-checkbox');
    var chip = card.querySelector('.step-chip');
    var status = card.querySelector('.step-status');
    if (!cb || !id) return;
    if (saved[id]) {
      cb.checked = true;
      card.classList.add('completed');
      if (chip) chip.textContent = 'done';
    }
    cb.addEventListener('change', function () {
      var done = cb.checked;
      card.classList.toggle('completed', done);
      if (chip) chip.textContent = done ? 'done' : 'todo';
      if (status) {
        status.textContent = 'Step ' + (idx + 1) + ' marked as ' +
          (done ? 'complete' : 'incomplete');
      }
      saved[id] = done;
      try { localStorage.setItem(STORE_KEY, JSON.stringify(saved)); } catch (e) {}
      updateProgress();
    });
  });
  updateProgress();
})();
```
<!-- BUILD-EXTRACT:STEP-COMPLETION END -->

---

## Markdown Rendering

Apply these rules **after** HTML-escaping. Apply top to bottom.

| Pattern | HTML output | Notes |
|---|---|---|
| `**text**` or `__text__` | `<strong>text</strong>` | Bold |
| `*text*` or `_text_` | `<em>text</em>` | Italic |
| `` `code` `` | `<code>code</code>` | Inline code |
| `[label](url)` | `<a href="url" rel="noopener noreferrer">label</a>` | Allow-list check first |
| `~~text~~` | `<del>text</del>` | Strikethrough |

**Fenced code blocks:**
```html
<pre><code class="lang-{language}">{escaped content}</code></pre>
```
No language tag → `class="lang-text"`. Content escaped but not markdown-rendered.

**Paragraph breaks:** consecutive blank lines → `</p><p>`.

**Lists:** `- item`, `* item`, `1. item` → `<ul>/<ol>` + `<li>`. Nested (2-space/tab) → nested elements.

**Headings within sections:** `### Sub-heading` → `<h4>` (preserves hierarchy;
`<h3>` is reserved for step-card actions).

Do not apply markdown rendering to: `<h1>` title, `<h2>` section headings, fenced
code block content.

---

## Semantic Rules

Required in every generated HTML file:

- `<!DOCTYPE html>` as the first line
- `lang="en"` on `<html>`
- `<title>` present and non-empty (plain text only)
- `<a href="#main-content" class="skip-link">` as first focusable element in `<body>`
- `<main id="main-content">` landmark wrapping all section content
- `<nav aria-label="Document sections">` landmark for the sidebar
- `<header>` landmark for title, badge, metadata
- Each `<section>` has `aria-labelledby` pointing to its `<h2 id>`
- Each `<input type="checkbox">` wrapped in `<label>` (no orphan checkboxes)
- `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, `aria-label` on progress bar (plan mode)
- `aria-current="true"` on the active sidebar `<a>` (set by JS scroll-spy)
- Color contrast ≥ 4.5:1 for all body text (theme values are pre-validated)
- Touch targets ≥ 44×44px for sidebar links and step checkboxes

---

## Print Styles

```css
@media print {
  header { background: #fff !important; color: #000 !important; box-shadow: none; }
  .progress-bar { display: none; }
  .scroll-rail { display: none; }
  .step-chip { display: none; }
  .save-pdf-btn { display: none; }
  nav { display: none; }
  .section-diagram { display: none; }
  .skip-link { display: none; }
  .layout { display: block; }
  .step-card { box-shadow: none; border: 1px solid #ccc; break-inside: avoid; }
  a[href]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: #555; }
  .status-badge {
    border: 1px solid currentColor;
    background: none !important;
    color: inherit !important;
  }
}
```

---

## Required Sections

Omit a section (and its sidebar anchor) if absent from the source document.

| Section | Source heading | Plan mode | Doc mode |
|---|---|---|---|
| Context | `## Context` | Optional | Optional |
| Objective | `## Objective` | Optional | Optional |
| Steps | `## Steps` | Optional | Prose |
| Verification | `## Verification` | Optional | Optional |
| Next Steps | `## Next Steps` | Optional | Optional |
| Unresolved Questions | `## Unresolved Questions` | Optional | Optional |
| Interview Summary | `## Interview Summary` | Optional | Optional |

In doc mode, all `## Heading` sections become `<section>` + `<h2>` elements.

---

## Graceful Unknown State

Never stop or warn for missing frontmatter:

- `status` absent → badge shows "unknown" in gray; progress bar at 5%
- `created` absent → show `n/a` in metadata row
- `modified` absent → omit from metadata row
- `type` absent → omit from metadata row entirely
