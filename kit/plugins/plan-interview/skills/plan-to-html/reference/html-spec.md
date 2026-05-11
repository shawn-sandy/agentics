# HTML Output Specification for plan-to-html

This file defines the layout contract, semantic requirements, and theme palettes
that the `plan-to-html` skill must follow when generating HTML output. The skill
references this file in its synthesis step — do not embed the full spec in
SKILL.md.

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

```
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{plan title}</title>
    <style>/* all CSS inline here — no external stylesheets */</style>
  </head>
  <body>
    <header>          <!-- plan title, status badge, metadata row -->
    <div class="layout">
      <nav aria-label="Plan sections">  <!-- sticky sidebar with anchor links -->
      <main>          <!-- all section content -->
    </div>
  </body>
</html>
```

No `<script>` tags. No `<link>` or `<script src>` to external resources.
No JavaScript of any kind.

---

## Header

The `<header>` element contains:

1. `<h1>` — plan title (H1 from source plan, with `Plan:` prefix stripped)
2. Status badge — see **Status Badge** section below
3. Metadata row — see field rendering rules below

**Metadata field rendering:**

| Field | Absent behavior |
|---|---|
| `created` | Render as `n/a` |
| `modified` | Omit from metadata row entirely (absence is normal for new plans) |
| `type` | Omit from metadata row entirely |
| `status` | Render badge as `unknown` — see **Status Badge** section |

The Theme name is always shown (it was chosen by the user at runtime, not read
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
- Active state (`:target` pseudo-class or scroll position) is optional — do not
  add JS to implement it

---

## Steps Section

Steps must use an ordered list, not `<div>` elements:

```html
<section id="steps">
  <h2>Steps</h2>
  <ol class="steps-list">
    <li class="step-card">
      <h3 class="step-action">{action text}</h3>
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

The `<h3>` inside the `<li>` must be the step action text only — do not include
step numbers in the heading text (the `<ol>` provides numbering).

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

## Color Palette Themes

All four themes share the identical layout. Only these CSS custom properties
change between themes — define them in `:root` and override per theme class
on `<body>`:

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
}
```

Apply the theme class to `<body>` based on the user's selection:
`<body class="theme-default">` / `<body class="theme-developer">` / etc.

---

## Semantic Rules

All of the following are required in every generated HTML file:

- `<h1>` — plan title only; appears once in `<header>`
- `<h2>` — section names (Context, Steps, Verification, etc.); one per section
- `<h3>` — step action text within `<ol><li>` step cards
- `<main>` landmark wrapping all section content
- `<nav aria-label="Plan sections">` landmark for the sidebar
- `<header>` landmark for title + badge + metadata
- Color contrast ≥ 4.5:1 for all body text against its background (use the
  theme values above — they are pre-validated)
- Touch targets ≥ 44×44px for any interactive elements (sidebar links)

---

## Responsive Layout

Two-column layout above 768px; single-column below 768px:

```css
.layout {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: 2rem;
  max-width: 960px;
  margin: 0 auto;
  padding: 1.5rem;
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

## Graceful Unknown State

Never stop or warn the user for missing frontmatter — render gracefully in all
cases. The authoritative per-field rules are in the **Header** section above
(metadata field rendering table). Summary:

- `status` absent → badge shows "unknown" in gray
- `created` absent → `n/a` in metadata row
- `modified` absent → omit from metadata row (do not show `n/a`)
- `type` absent → omit from metadata row entirely
