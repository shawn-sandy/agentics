# HTML Layout Specification: Plan Review Artifact

This specification defines every layout, visual, security, and accessibility
contract for the self-contained HTML file emitted by `plan-review-agents`
Step 8. Read this file in full before synthesizing the HTML string. Fill
named injection slots from the reference skeleton at the bottom; do not
generate document structure freehand.

---

## themes

Define four themes via `body.theme-*` CSS custom properties in a single
inlined `<style>` block. Apply `body class="theme-default"` unless a future
flag overrides it.

```css
/* ── token definitions ─────────────────────────────────────── */
body.theme-default  { --bg: #ffffff; --surface: #f5f7fa; --border: #d0d5dd;
                      --text: #101828; --text-muted: #475467;
                      --accent: #1d4ed8; --accent-fg: #ffffff;
                      --badge-approve: #15803d; --badge-revise: #92400e;
                      --badge-reject: #b91c1c; --badge-fg: #ffffff; }

body.theme-developer{ --bg: #0d1117; --surface: #161b22; --border: #30363d;
                      --text: #e6edf3; --text-muted: #8b949e;
                      --accent: #58a6ff; --accent-fg: #0d1117;
                      --badge-approve: #2ea043; --badge-revise: #d29922;
                      --badge-reject: #f85149; --badge-fg: #ffffff; }

body.theme-document { --bg: #faf9f6; --surface: #f0ede8; --border: #ccc7be;
                      --text: #1a1a1a; --text-muted: #5a5a5a;
                      --accent: #2563eb; --accent-fg: #ffffff;
                      --badge-approve: #166534; --badge-revise: #78350f;
                      --badge-reject: #991b1b; --badge-fg: #ffffff; }

body.theme-minimal  { --bg: #ffffff; --surface: #ffffff; --border: #e5e7eb;
                      --text: #111111; --text-muted: #6b7280;
                      --accent: #000000; --accent-fg: #ffffff;
                      --badge-approve: #166534; --badge-revise: #92400e;
                      --badge-reject: #991b1b; --badge-fg: #ffffff; }
```

**WCAG AA contrast requirements (all four themes):**

- Normal text (`--text` on `--bg`): minimum 4.5:1.
- Muted text (`--text-muted` on `--bg`): minimum 4.5:1.
- Large text (≥18 pt or ≥14 pt bold) and UI components: minimum 3:1.
- Badge text (`--badge-fg` on badge background): minimum 4.5:1.
- Accent interactive text (`--accent` on `--bg`): minimum 4.5:1.

Do not alter token values in ways that drop below these ratios.

---

## layout

Two-column layout: sticky sidebar nav on the left, main content on the
right. The sidebar collapses to a single-column stack at `≤768px`.

```css
.layout        { display: grid;
                 grid-template-columns: 240px 1fr;
                 gap: 2rem; max-width: 1100px;
                 margin: 0 auto; padding: 1.5rem; }
@media (max-width: 768px) {
  .layout      { grid-template-columns: 1fr; }
  .sidebar     { position: static; }
}
.sidebar       { position: sticky; top: 1.5rem;
                 align-self: start; }
```

Sidebar: `<nav aria-label="Table of contents">` containing an `<ol>` of
anchor links to every `<h2>` in the document. Each TOC anchor can receive
`aria-current="location"` toggled by scroll-spy JS (visual only — scroll-spy
must **not** move keyboard focus).

Main content: `<main id="main-content">` holds plan body and appendix.

Landmark order: `<nav>` sidebar, then `<main>`.

`:focus-visible` outline must be visible on all interactive elements. Do not
suppress with `outline: none` in the CSS reset; use `:focus:not(:focus-visible)`
to hide mouse-click rings while preserving keyboard outlines:

```css
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
:focus:not(:focus-visible) { outline: none; }
```

---

## decision badge

Rendered from the `Final decision:` line in section 14 of the synthesized
report. Verdict strings: `Approve`, `Approve with revisions`, `Reject`.

**Rules:**

- The full verdict text label must be rendered as visible content — do not
  convey the decision through color alone (WCAG 1.4.1).
- Badge is a `<span class="badge badge-approve|badge-revise|badge-reject">`.
- Badge text is a `<strong>` wrapping the full label, e.g.:
  `<span class="badge badge-approve"><strong>Approve</strong></span>`
- Badge colors use `--badge-approve`, `--badge-revise`, `--badge-reject` (text
  `--badge-fg`). Do not remove or visually hide the text label.
- Place the badge in the `<header>` below the `<h1>`, adjacent to the
  plan title, so it is the first element a reader encounters.

```css
.badge         { display: inline-block; padding: .25em .75em;
                 border-radius: .25em; font-size: .9rem;
                 color: var(--badge-fg); }
.badge-approve { background: var(--badge-approve); }
.badge-revise  { background: var(--badge-revise); }
.badge-reject  { background: var(--badge-reject); }
```

---

## reviewer cards

One card per reviewer role. Six roles: Product Manager, Lead Developer,
UX Designer, Lead Frontend Engineer, Accessibility Expert, Security Expert.

Card structure:

```html
<article class="reviewer-card" aria-labelledby="card-pm">
  <h3 id="card-pm">Product Manager</h3>
  <dl>
    <dt>Approval</dt><dd>Approve with revisions</dd>
    <dt>Works well</dt><dd><!-- escaped content --></dd>
    <dt>Critical concerns</dt><dd><!-- escaped content --></dd>
    <dt>Missing requirements</dt><dd><!-- escaped content --></dd>
  </dl>
</article>
```

**Reviewer-unavailable variant:**

When a reviewer was marked `Reviewer unavailable — not assessed`, render a
pill instead of a card:

```html
<span class="unavailable-pill">
  <span class="unavailable-icon" aria-hidden="true">&#9888;</span>
  <span class="unavailable-label">Lead Developer — not assessed</span>
</span>
```

The `.unavailable-label` must be visible text (not aria-hidden) to satisfy
WCAG 1.1.1. Do not hide the label with `display:none` or `visibility:hidden`.

```css
.unavailable-pill  { display: inline-flex; align-items: center; gap: .4em;
                     padding: .25em .75em; border-radius: 9999px;
                     background: var(--surface); border: 1px solid var(--border);
                     font-size: .875rem; color: var(--text-muted); }
```

Place all reviewer cards in a `<section aria-labelledby="sec-reviewers">` with
an `<h2 id="sec-reviewers">Role-by-Role Review</h2>` heading.

---

## tables

**Conflicts table** (section 13 of the report):

```html
<table>
  <thead>
    <tr>
      <th scope="col">Topic</th>
      <th scope="col">Conflict</th>
      <th scope="col">Resolution</th>
    </tr>
  </thead>
  <tbody>
    <!-- one <tr> per conflict row, cells HTML-escaped -->
  </tbody>
</table>
```

Empty state (no conflicts): render a single row:

```html
<tr><td colspan="3">No conflicts identified.</td></tr>
```

**Inline-edits table** (section 15a):

Use `<ul><li>` for list-like multi-line cell content. Use `<p>` for prose.
Use `<br>` only for inline line-breaks within a sentence. Do not use bare
`\n` text nodes for structural separation.

Table CSS baseline:

```css
table        { width: 100%; border-collapse: collapse;
               font-size: .9rem; }
th, td       { padding: .5em .75em; border: 1px solid var(--border);
               text-align: left; vertical-align: top; }
thead th     { background: var(--surface);
               color: var(--text); font-weight: 600; }
```

---

## appendix toggle

The full 15-section panel review is wrapped in a native `<details>` element,
collapsed by default. `<summary>` is the visible toggle label.

**Rules:**

- Use native `<details>`/`<summary>` exclusively for all collapsible controls.
  Do not add a JS-driven toggle alongside it — simultaneous JS + native
  `<details>` causes interaction conflicts.
- `<details>` must have no `open` attribute on load (collapsed by default).
- Print styles must expand all `<details>` — see the **print** section.

```html
<details id="appendix">
  <summary>Panel Review (full 15-section report)</summary>
  <div class="appendix-body">
    <!-- all 15 sections, HTML-escaped and structured -->
  </div>
</details>
```

```css
details > summary { cursor: pointer; font-weight: 600;
                    padding: .5em 0; color: var(--accent);
                    list-style: none; }
details > summary::-webkit-details-marker { display: none; }
details > summary::before { content: "▶ "; font-size: .75em; }
details[open] > summary::before { content: "▼ "; }
```

---

## print

`@media print` must:

1. Hide the sidebar: `.sidebar { display: none; }`.
2. Collapse the two-column grid to single-column: `.layout { display: block; }`.
3. Expand all `<details>`: `details { display: block; } summary { display: none; }`.
4. Remove sticky positioning: `.sidebar { position: static; }` (redundant with
   `display:none` but included for robustness).

```css
@media print {
  .sidebar   { display: none; }
  .layout    { display: block; }
  details    { display: block; }
  summary    { display: none; }
}
```

---

## no-external-deps

The file must be fully self-contained. The following are forbidden:

| Forbidden construct | Example |
|---|---|
| `<link>` tags | `<link rel="stylesheet" href="...">` |
| `<script src="...">` | remote or local script references |
| `<iframe>` | any iframe |
| `<object>` or `<embed>` | plugin content |
| CSS `@import` | `@import url('...')` |
| CSS `url(https?://...)` | remote font or image |
| SVG `<use href="https?://...">` | remote sprite |
| `<meta http-equiv="refresh">` | auto-redirect |
| Remote font loading | Google Fonts, Typekit, etc. |

All CSS must be in a single `<style>` block inside `<head>`. All JS must be
in a single `<script>` block at the bottom of `<body>` (scroll-spy only).
Images embedded as `data:image/*` base64 are permitted.

Verification grep (must return no matches on the emitted file):

```
grep -E '<link |<script[^>]*src=|<iframe|<object |<embed |@import|url\(https?:|<use[^>]*href="https?:|<meta[^>]*http-equiv="refresh"'
```

---

## Security & Escaping Contract

**All interpolated values** — plan body, reviewer outputs, decision strings,
table cell content, reviewer names, plan title, filename stem — **must be
HTML-escaped before insertion**:

| Raw character | Escaped form |
|---|---|
| `<` | `&lt;` |
| `>` | `&gt;` |
| `&` | `&amp;` |
| `"` | `&quot;` |
| `'` | `&#39;` |

**Markdown rendering** — if the plan body is rendered from markdown to HTML
(rather than shown as `<pre>`), apply all of the following:

- Disable raw HTML passthrough (treat `<script>` in markdown as literal text).
- Strip `javascript:`, `vbscript:`, and `data:` (except `data:image/*`) from
  any link `href` or `src` attribute before output.
- Strip all event-handler attributes (`onclick`, `onload`, `onerror`, etc.)
  from any generated element.

**CSP meta tag** — the following `<meta>` must appear in `<head>` before any
inline `<style>`:

```html
<meta http-equiv="Content-Security-Policy"
      content="default-src 'none'; style-src 'self' 'unsafe-inline';
               script-src 'self' 'unsafe-inline'; img-src data:;
               base-uri 'none'; form-action 'none'; frame-ancestors 'none'">
```

**Scroll-spy JS** — the only permitted JavaScript is scroll-spy that updates
`aria-current="location"` on the active TOC anchor. It must not:
- Move keyboard focus programmatically (WCAG 2.4.3).
- Dynamically load external resources.
- Use dynamic code execution or `innerHTML` with unsanitized strings.

---

## Reference HTML Skeleton

Copy this skeleton and fill each `<!-- injection point -->` comment. Do not
alter landmark nesting, heading levels, or the `<head>` element order.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none'; style-src 'self' 'unsafe-inline';
                 script-src 'self' 'unsafe-inline'; img-src data:;
                 base-uri 'none'; form-action 'none'; frame-ancestors 'none'">
  <meta name="generator" content="product-plans v3.3.0">
  <title><!-- plan H1 heading text (HTML-escaped), or filename stem if no H1 --></title>
  <style>
    /* ── reset ──────────────────────────────────────────────── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: var(--bg);
           color: var(--text); line-height: 1.6; }

    /* ── theme tokens (injection point) ─────────────────────── */
    /* paste theme CSS blocks from the themes section */

    /* ── layout (injection point) ───────────────────────────── */
    /* paste layout CSS from the layout section */

    /* ── decision badge (injection point) ───────────────────── */
    /* paste badge CSS from the decision badge section */

    /* ── reviewer cards (injection point) ───────────────────── */
    /* paste reviewer card / unavailable pill CSS */

    /* ── tables (injection point) ───────────────────────────── */
    /* paste table CSS from the tables section */

    /* ── appendix toggle (injection point) ──────────────────── */
    /* paste details/summary CSS */

    /* ── focus ───────────────────────────────────────────────── */
    :focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
    :focus:not(:focus-visible) { outline: none; }

    /* ── print ───────────────────────────────────────────────── */
    @media print {
      .sidebar { display: none; }
      .layout  { display: block; }
      details  { display: block; }
      summary  { display: none; }
    }
  </style>
</head>
<body class="theme-default">

  <header>
    <h1><!-- plan title (HTML-escaped) --></h1>
    <!-- injection point: decision badge
         <span class="badge badge-approve|badge-revise|badge-reject">
           <strong>Approve|Approve with revisions|Reject</strong>
         </span> -->
    <p class="provenance">
      Generated: <!-- ISO-8601 UTC timestamp --> &middot;
      Source: <code><!-- source plan filename (HTML-escaped) --></code>
    </p>
  </header>

  <div class="layout">

    <aside class="sidebar">
      <nav aria-label="Table of contents">
        <ol>
          <!-- injection point: one <li><a href="#section-id">Section title</a></li>
               per <h2> in main content -->
        </ol>
      </nav>
    </aside>

    <main id="main-content">

      <!-- injection point: revised plan body (section 15b) as primary surface.
           Use <h2> for top-level plan sections, <h3> for sub-sections.
           All content HTML-escaped (or safely rendered from markdown). -->

      <details id="appendix">
        <summary>Panel Review (full 15-section report)</summary>
        <div class="appendix-body">

          <!-- injection point: panel review sections 1-14 as <section> elements.
               Each top-level review section: <h2>.
               Reviewer subsections: <h3>.
               All content HTML-escaped. -->

          <section aria-labelledby="sec-reviewers">
            <h2 id="sec-reviewers">Role-by-Role Review</h2>
            <!-- injection point: reviewer cards or unavailable pills -->
          </section>

          <!-- injection point: conflicts table (section 13) -->
          <!-- injection point: inline-edits table (section 15a) -->

        </div>
      </details>

    </main>
  </div>

  <footer>
    <p class="disclaimer">This document may contain confidential plan content
    and reviewer findings. Classify before sharing.</p>
  </footer>

  <script>
    /* Scroll-spy: updates aria-current="location" on active TOC anchor.
       Does NOT move keyboard focus. Uses IntersectionObserver. */
    (function () {
      var headings = document.querySelectorAll('main h2[id]');
      var links = document.querySelectorAll('nav a[href^="#"]');
      if (!headings.length || !links.length) return;
      var obs = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (!e.isIntersecting) return;
          links.forEach(function (l) { l.removeAttribute('aria-current'); });
          var active = document.querySelector('nav a[href="#' + e.target.id + '"]');
          if (active) active.setAttribute('aria-current', 'location');
        });
      }, { rootMargin: '0px 0px -60% 0px', threshold: 0 });
      headings.forEach(function (h) { obs.observe(h); });
    })();
  </script>

</body>
</html>
```
