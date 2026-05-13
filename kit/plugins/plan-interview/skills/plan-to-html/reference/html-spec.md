# HTML Output Specification for plan-to-html

This file defines the layout contract, semantic requirements, theme palettes, and
JavaScript feature set that the `plan-to-html` skill must follow when generating
HTML output. The skill references this file in its synthesis step — do not embed
the full spec in `SKILL.md`.

---

## Required Sections

The following sections must appear in the HTML document when present in the plan.
Omit a section entirely (including its sidebar anchor) if it is absent from the
source plan.

| Section name | Source heading | Always present? |
|---|---|---|
| Context | `## Context` | Only if in plan |
| Objective | `## Objective` | Only if in plan |
| Steps | `## Steps` | Only if in plan |
| Verification | `## Verification` | Only if in plan |
| Next Steps | `## Next Steps` | Only if in plan |
| Unresolved Questions | `## Unresolved Questions` | Only if in plan |
| Interview Summary | `## Interview Summary` | Only if in plan |

---

## Page Structure

```html
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{plan title}</title>
    <style>/* all CSS inline here — no external stylesheets */</style>
  </head>
  <body class="theme-{selected-theme}">
    <header>          <!-- plan title, status badge, metadata row -->
      <div class="progress-bar" role="progressbar" aria-label="Plan progress">
        <div class="progress-fill"></div>
      </div>
    </header>
    <div class="layout">
      <nav aria-label="Plan sections">  <!-- sticky sidebar with anchor links -->
        <ul>
          <li><a href="#context">Context</a></li>
          <!-- one <li> per section present in this plan -->
        </ul>
      </nav>
      <main>          <!-- all section content -->
        <section id="context">…</section>
        <!-- one <section> per plan section -->
      </main>
    </div>
    <script>/* all JS inline here — no external scripts */</script>
  </body>
</html>
```

**Scripting policy:** Inline `<script>` blocks are allowed for progressive
enhancement. All JS must be embedded in a single `<script>` block immediately
before `</body>`. No `<script src>` to external resources.

**External resource policy:** No `<link>` to external stylesheets. No CDN URLs of
any kind. No external fonts (`@import url(...)`). Fully self-contained.

**Content sanitization:** All text derived from the plan file (title, section
headings, body text) must be HTML-escaped before embedding. Replace `&` → `&amp;`,
`<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`. Apply markdown rendering (see the
**Markdown Rendering** section) *after* escaping raw text.

---

## Header

The `<header>` element contains:

1. Progress bar (always, derived from plan status — see **Progress Indicator**)
2. `<h1>` — plan title (H1 from source plan, with `Plan:` prefix stripped)
3. Status badge — see **Status Badge** section below
4. Metadata row — see field rendering rules below

**Metadata field rendering:**

| Field | Absent behavior |
|---|---|
| `created` | Render as `n/a` |
| `modified` | Omit from metadata row entirely (absence is normal for new plans) |
| `type` | Omit from metadata row entirely |
| `status` | Render badge as `unknown` — see **Status Badge** section |

The theme name is always shown (it was chosen by the user at runtime, not read
from frontmatter).

---

## Navigation (Sticky Sidebar)

```html
<nav aria-label="Plan sections">
  <ul>
    <li><a href="#context">Context</a></li>
    <li><a href="#steps">Steps</a></li>
    <!-- one <li> per section present in this plan -->
  </ul>
</nav>
```

- Sticky: `position: sticky; top: 1rem` on the nav element
- Only include anchor links for sections that exist in the plan
- Active state: the scroll-spy script (see **JavaScript Features**) adds
  `class="active"` to the currently visible section's `<a>` element

CSS for active nav link:

```css
nav a.active {
  color: var(--color-accent);
  font-weight: 600;
}
```

---

## Steps Section

Steps must use an ordered list, not `<div>` elements:

```html
<section id="steps">
  <h2>Steps</h2>
  <ol class="steps-list">
    <li class="step-card" data-step-id="{plan-slug}-{index}">
      <label class="step-check">
        <input type="checkbox" class="step-checkbox">
        <h3 class="step-action">{action text}</h3>
      </label>
      <p class="step-why">{why text — the rationale line}</p>
      <p class="step-verify">&#10003; {verify text — how to confirm this step}</p>
    </li>
  </ol>
</section>
```

Visual treatment:
- `step-action`: bold, standard body color
- `step-why`: muted color (≥4.5:1 contrast on background), smaller font-size
- `step-verify`: prefixed with a checkmark character (✓ or &#10003;), distinct
  color (e.g., green or theme accent), same small font-size as why
- `step-card`: card with border, padding, rounded corners, subtle box-shadow;
  hover state raises the shadow and shifts slightly

Checkbox behavior:
- When checked, `step-card` receives `class="step-card completed"` via JS
- Completed card: `step-action` gains `text-decoration: line-through; opacity: 0.6`
- Checkbox state persists in `localStorage` (see **JavaScript Features**)

The `<h3>` inside the `<li>` must be the step action text only — do not include
step numbers in the heading text (the `<ol>` provides numbering).

If a step has no why/verify text, omit those elements entirely.

---

## Status Badge

Inline `<span>` element placed in the `<header>` after the `<h1>`:

```html
<span class="status-badge status-{value}">{label}</span>
```

| Frontmatter value | CSS class | Label | Color |
|---|---|---|---|
| `todo` | `status-todo` | todo | Gray (`#6b7280`) |
| `in-progress` | `status-in-progress` | in progress | Amber (`#d97706`) |
| `completed` | `status-completed` | completed | Green (`#16a34a`) |
| absent or unknown | `status-unknown` | unknown | Gray (`#6b7280`) |

Badge style: rounded pill, small font, white text, `padding: 0.2em 0.7em`.

---

## Progress Indicator

A thin horizontal bar at the top of `<header>` (above the `<h1>`). The fill width
is determined by plan status:

| Status | Fill width | Color |
|---|---|---|
| `todo` | `5%` | Gray (`#6b7280`) |
| `in-progress` | `50%` | Amber (`#d97706`) |
| `completed` | `100%` | Green (`#16a34a`) |
| absent or unknown | `5%` | Gray (`#6b7280`) |

When steps are present and the JS step-completion feature is active, the progress
bar fill is updated dynamically from the percentage of checked steps. The initial
fill from status serves as the starting state before any checkboxes are toggled.

```css
.progress-bar {
  width: 100%;
  height: 4px;
  background: rgba(255,255,255,0.2);
}
.progress-fill {
  height: 100%;
  width: {initial-pct}%;   /* replaced at generation time */
  background: {status-color};
  transition: width 0.3s ease;
}
```

---

## Color Palette Themes

All four themes share the identical layout. Only these CSS custom properties
change between themes. Define them directly on each `body.theme-*` class (no
`:root` defaults required — a theme class is always present on `<body>`):

| Property | Purpose |
|---|---|
| `--color-header-bg` | `<header>` background color |
| `--color-header-text` | `<header>` text and `<h1>` color |
| `--color-nav-bg` | Sidebar `<nav>` background |
| `--color-nav-text` | Sidebar link text color |
| `--color-nav-hover` | Sidebar link hover color |
| `--color-accent` | Accent color (links, verify checkmarks, active states) |
| `--color-body-bg` | `<main>` and page background |
| `--color-body-text` | Main body text |
| `--color-muted` | `step-why` muted text |
| `--color-border` | Card borders and dividers |
| `--color-card-bg` | Step card background (slightly offset from body-bg) |
| `--color-code-bg` | Inline `<code>` background |

### Theme: Default

Clean neutral grays with blue accent.

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
```

### Theme: Developer

Dark charcoal header, green accent (terminal-inspired).

```css
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
```

### Theme: Document

Warm off-white background, sepia/brown accent.

```css
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
```

### Theme: Minimal

Pure white background, black text, no accent color.

```css
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

Apply the theme class to `<body>` based on the user's selection:
`<body class="theme-default">` / `<body class="theme-developer">` / etc.

---

## JavaScript Features

Include a single `<script>` block immediately before `</body>` that implements:

### 1 — Scroll Spy (active nav highlighting)

Use `IntersectionObserver` to watch all `<section>` elements. When a section
becomes visible (threshold: 0.3), add `class="active"` to the corresponding
sidebar `<a>` and remove it from all others.

```javascript
(function () {
  const links = {};
  document.querySelectorAll('nav a[href^="#"]').forEach(a => {
    links[a.getAttribute('href').slice(1)] = a;
  });
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        Object.values(links).forEach(a => a.classList.remove('active'));
        const link = links[entry.target.id];
        if (link) link.classList.add('active');
      }
    });
  }, { threshold: 0.3 });
  document.querySelectorAll('main section').forEach(s => observer.observe(s));
})();
```

### 2 — Step Completion (localStorage persistence)

Each `.step-checkbox` stores its checked state in `localStorage` keyed by the
parent `.step-card`'s `data-step-id`. On page load, restore all states. On change,
persist and toggle the `completed` class on the card. Also update the progress bar
if it exists.

```javascript
(function () {
  const STORE_KEY = 'plan-steps-' + encodeURIComponent(document.title);
  const saved = JSON.parse(localStorage.getItem(STORE_KEY) || '{}');

  function updateProgress() {
    const fill = document.querySelector('.progress-fill');
    if (!fill) return;
    const boxes = document.querySelectorAll('.step-checkbox');
    if (!boxes.length) return;
    const checked = Array.from(boxes).filter(b => b.checked).length;
    fill.style.width = Math.round((checked / boxes.length) * 100) + '%';
  }

  document.querySelectorAll('.step-card').forEach(card => {
    const id = card.dataset.stepId;
    const cb = card.querySelector('.step-checkbox');
    if (!cb || !id) return;
    if (saved[id]) {
      cb.checked = true;
      card.classList.add('completed');
    }
    cb.addEventListener('change', () => {
      card.classList.toggle('completed', cb.checked);
      saved[id] = cb.checked;
      localStorage.setItem(STORE_KEY, JSON.stringify(saved));
      updateProgress();
    });
  });
  updateProgress();
})();
```

---

## Markdown Rendering

When embedding plan content in the HTML body, apply these conversion rules **after**
HTML-escaping the raw text. Order matters — apply rules top to bottom.

The escaping pass runs first (replacing `&`, `<`, `>`, `"`). The markdown pass then
works on escaped text, so it must match escaped patterns where appropriate.

| Markdown pattern | HTML output | Notes |
|---|---|---|
| `**text**` or `__text__` | `<strong>text</strong>` | Bold |
| `*text*` or `_text_` | `<em>text</em>` | Italic (single delimiter only) |
| `` `code` `` | `<code>code</code>` | Inline code |
| `[label](url)` | `<a href="url" rel="noopener">label</a>` | Links — only emit if URL starts with `http://`, `https://`, or `/`; otherwise render as plain text |
| `~~text~~` | `<del>text</del>` | Strikethrough |

**Fenced code blocks** (``` ``` ``` or `~~~`): render as:

```html
<pre><code class="lang-{language}">{escaped content}</code></pre>
```

If no language tag is present, use `class="lang-text"`. The content inside the
block is HTML-escaped but **not** markdown-rendered (no bold inside code blocks).

**Paragraph breaks:** two or more consecutive blank lines in a section body
produce `</p><p>` separation. Single blank lines within a paragraph do not break.

**Lists:** markdown list items (`- item`, `* item`, `1. item`) within section
bodies are rendered as `<ul>/<ol>` + `<li>` elements. Nested lists (two-space or
tab indent) become nested `<ul>/<ol>`.

**Headings within sections:** `### Sub-heading` within a body section becomes
`<h4>` (not `<h3>`, to preserve the document heading hierarchy — `<h3>` is
reserved for step-card actions).

Do not apply markdown rendering to:
- The plan `<h1>` title (already handled separately)
- `<h2>` section headings (already handled separately)
- Content inside fenced code block delimiters

---

## Semantic Rules

All of the following are required in every generated HTML file:

- `lang="en"` on `<html>` element
- `<h1>` — plan title only; appears once in `<header>`
- `<h2>` — section names (Context, Steps, Verification, etc.); one per section
- `<h3>` — step action text within `<ol><li>` step cards only
- `<h4>` — sub-headings within section bodies (from `###` in source)
- `<main>` landmark wrapping all section content
- `<nav aria-label="Plan sections">` landmark for the sidebar
- `<header>` landmark for title + badge + metadata
- `role="progressbar"` and `aria-label` on the progress bar container
- Color contrast ≥ 4.5:1 for all body text against its background (use the
  theme values above — they are pre-validated)
- Touch targets ≥ 44×44px for sidebar links and step checkboxes

---

## Responsive Layout

Two-column layout above 768px; single-column below 768px:

```css
html {
  scroll-behavior: smooth;
}

.layout {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: 2rem;
  max-width: 1024px;
  margin: 0 auto;
  padding: 1.5rem;
}

.step-card {
  background: var(--color-card-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem 1.25rem;
  margin-bottom: 0.75rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  transition: box-shadow 0.15s ease, transform 0.15s ease;
}

.step-card:hover {
  box-shadow: 0 4px 12px rgba(0,0,0,0.12);
  transform: translateY(-1px);
}

.step-card.completed .step-action {
  text-decoration: line-through;
  opacity: 0.6;
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

pre code {
  background: none;
  padding: 0;
  font-size: 0.85em;
}

@media (max-width: 768px) {
  .layout {
    grid-template-columns: 1fr;
  }
  nav {
    position: static;  /* collapse sticky on mobile */
  }
}
```

---

## Print Styles

Include a `@media print` block that produces clean, ink-friendly output:

```css
@media print {
  header {
    background: #fff !important;
    color: #000 !important;
    box-shadow: none;
  }
  .progress-bar { display: none; }
  nav { display: none; }
  .layout {
    display: block;
  }
  .step-card {
    box-shadow: none;
    border: 1px solid #ccc;
    break-inside: avoid;
  }
  a[href]::after {
    content: " (" attr(href) ")";
    font-size: 0.8em;
    color: #555;
  }
  .status-badge {
    border: 1px solid currentColor;
    background: none !important;
    color: inherit !important;
  }
}
```

---

## Graceful Unknown State

Never stop or warn the user for missing frontmatter — render gracefully in all
cases. The authoritative per-field rules are in the **Header** section above
(metadata field rendering table). Summary:

- `status` absent → badge shows "unknown" in gray; progress bar at 5%
- `created` absent → `n/a` in metadata row
- `modified` absent → omit from metadata row (do not show `n/a`)
- `type` absent → omit from metadata row entirely
