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

## decision banner

Rendered from the `Final decision:` line in section 14 of the synthesized
report. Verdict strings: `Approve`, `Approve with revisions`, `Reject`.

The decision banner is a `<div role="status">` placed in `<main>` between
the plan body and the `<details id="appendix">` toggle. It is the **sole**
decision announcement point — there is no badge in `<header>`.

**Rules:**

- The full verdict text label must be rendered as visible content — do not
  convey the decision through color alone (WCAG 1.4.1).
- Render for **all three outcomes**: Approve (green), Approve with revisions
  (amber), Reject (red + remediation prompt).
- Banner colors use `--badge-approve`, `--badge-revise`, `--badge-reject`
  (text `--badge-fg`). Do not remove or visually hide the text label.
- When the decision is `Reject`, the banner also contains the remediation
  section (see the `## remediation prompt` section below).

```css
.decision-banner { padding: 1em 1.25em; border-radius: .5em; margin: 1.5em 0;
                   color: var(--badge-fg); }
.decision-banner strong { font-size: 1.1rem; }
.decision-banner.banner-approve { background: var(--badge-approve); }
.decision-banner.banner-revise  { background: var(--badge-revise); }
.decision-banner.banner-reject  { background: var(--badge-reject); }
```

```html
<div class="decision-banner banner-approve|banner-revise|banner-reject" role="status">
  <strong>Approve|Approve with revisions|Reject</strong>
  <p>[Rationale sentence from section 14]</p>
  <!-- remediation section here when Reject — see below -->
</div>
```

---

## remediation prompt

Rendered **only** when the final decision is `Reject`. Placed inside the
decision banner `<div>`, after the rationale paragraph.

**Structure:**

```html
<div class="remediation">
  <h3>Remediation Prompt</h3>
  <p>Copy the prompt below and paste it into a fresh Claude session to fix
  the plan and re-run the review.</p>
  <div style="position: relative;">
    <pre role="region" aria-label="Remediation prompt text" tabindex="0">[HTML-escaped prompt text from section 14 #### Remediation Prompt]</pre>
    <button class="copy-btn" aria-label="Copy remediation prompt to clipboard">Copy</button>
  </div>
  <span class="sr-only" aria-live="polite"></span>
</div>
```

**CSS:**

```css
.remediation     { margin-top: 1em; padding: 1em; border-radius: .375em;
                   border-left: 4px solid var(--badge-reject);
                   background: var(--surface);
                   background: color-mix(in srgb, var(--badge-reject) 5%, var(--surface));
                   color: var(--text); }
.remediation h3  { font-size: 1rem; margin-bottom: .5em; }
.remediation pre { max-height: 300px; overflow-y: auto; padding: .75em;
                   background: var(--bg); border: 1px solid var(--border);
                   border-radius: .25em; font-size: .85rem;
                   white-space: pre-wrap; word-wrap: break-word; }
.remediation pre:focus-visible { outline: 2px solid var(--accent);
                                  outline-offset: 2px; }
.copy-btn        { position: absolute; top: .5em; right: .5em;
                   padding: .25em .75em; border: 1px solid var(--border);
                   border-radius: .25em; background: var(--surface);
                   color: var(--text); cursor: pointer; font-size: .8rem; }
.copy-btn:hover  { background: var(--border); }
.sr-only         { position: absolute; width: 1px; height: 1px;
                   padding: 0; margin: -1px; overflow: hidden;
                   clip: rect(0,0,0,0); white-space: nowrap;
                   border: 0; }
```

**Accessibility:**

- The `<pre>` has `tabindex="0"` for keyboard scrolling and
  `role="region" aria-label="Remediation prompt text"`.
- The copy button has `aria-label="Copy remediation prompt to clipboard"`
  (WCAG 4.1.2).
- The `<span class="sr-only" aria-live="polite">` **must pre-exist in the
  DOM** from initial render (not dynamically created) so assistive technology
  registers it before content changes (WCAG 4.1.3). On clipboard success it
  receives the text "Copied"; on failure it receives "Could not copy —
  select the text manually".

**Print:** `.copy-btn { display: none; }` in `@media print`.

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

## historical reviews

When the plan file contains multiple `## Panel Review (timestamp)` sections
(from re-runs), each one renders as its own collapsed `<details>` element
inside the appendix, **newest first** (reverse chronological order). The
most recent review is the primary appendix `<details>`; older reviews are
nested after it.

```html
<details class="historical-review">
  <summary>Panel Review (2026-05-18 14:30:00 UTC)</summary>
  <div class="appendix-body">
    <!-- older review content, HTML-escaped -->
  </div>
</details>
```

```css
.historical-review { margin-top: 1em; border: 1px solid var(--border);
                     border-radius: .375em; padding: .5em; }
```

---

## print

`@media print` must:

1. Hide the sidebar: `.sidebar { display: none; }`.
2. Collapse the two-column grid to single-column: `.layout { display: block; }`.
3. Expand all `<details>`: set `details { display: block; }` and
   `summary { display: none; }`. Also add `::details-content { content-visibility: visible; }`
   to force the hidden slot to render (supported in Chrome 131+, Firefox 136+).
   For older browser coverage, add `beforeprint`/`afterprint` JS listeners that
   set and remove the `open` attribute on every `<details>` element (see the
   Reference HTML Skeleton `<script>` block).
4. Remove sticky positioning: `.sidebar { position: static; }` (redundant with
   `display:none` but included for robustness).

```css
@media print {
  .sidebar          { display: none; }
  .layout           { display: block; }
  details           { display: block; }
  summary           { display: none; }
  ::details-content { content-visibility: visible; }
  .copy-btn         { display: none; }
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
in a single `<script>` block at the bottom of `<body>` (scroll-spy,
print fallback, and clipboard handler only).
Images embedded as `data:image/*` base64 are permitted.

Verification grep (must return no matches on the emitted file):

```
grep -E '<link |<script[^>]*src=|<iframe|<object |<embed |@import|url\(https?:|<use[^>]*href="https?:|<meta[^>]*http-equiv="refresh"'
```

---

## Security & Escaping Contract

**All interpolated values** — plan body, reviewer outputs, decision strings,
table cell content, reviewer names, plan title, filename stem,
**remediation prompt content** (reproduced from plan sections 3/4/12) —
**must be HTML-escaped before insertion**:

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

**Permitted JS** — the only permitted JavaScript is:

1. **Scroll-spy** that updates `aria-current="location"` on the active TOC
   anchor.
2. **Print fallback** that sets/removes the `open` attribute on `<details>`
   elements around `beforeprint`/`afterprint` events.
3. **Clipboard handler** for the copy button (reject decision only): uses
   `navigator.clipboard.writeText()` with a `document.execCommand('copy')`
   fallback for `file://` origins. On success, sets the `aria-live` span
   text to "Copied"; on failure, sets it to "Could not copy — select the
   text manually". The `aria-live` span must pre-exist in the DOM.

All JS must not:
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
  <meta name="generator" content="product-plans v3.4.5">
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

    /* ── decision banner (injection point) ──────────────────── */
    /* paste banner CSS from the decision banner section */

    /* ── remediation (injection point) ───────────────────────── */
    /* paste remediation CSS from the remediation prompt section */

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
      .sidebar          { display: none; }
      .layout           { display: block; }
      details           { display: block; }
      summary           { display: none; }
      ::details-content { content-visibility: visible; }
      .copy-btn         { display: none; }
    }
  </style>
</head>
<body class="theme-default">

  <header>
    <h1><!-- plan title (HTML-escaped) --></h1>
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

      <!-- injection point: decision banner
           <div class="decision-banner banner-approve|banner-revise|banner-reject" role="status">
             <strong>Approve|Approve with revisions|Reject</strong>
             <p>[Rationale from section 14]</p>
             (when Reject, include remediation section here — see remediation prompt spec)
           </div> -->
      <span class="sr-only" aria-live="polite"></span>

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

      <!-- injection point: historical reviews (if any).
           Each ## Panel Review (timestamp) section from the plan file
           renders as its own collapsed <details>, newest first. -->

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

    /* Print fallback: set open attribute on all details before printing
       so older browsers (pre-::details-content support) expand them. */
    (function () {
      function openAll()  { document.querySelectorAll('details').forEach(function(d){ d.open = true; }); }
      function closeAll() { document.querySelectorAll('details').forEach(function(d){ d.removeAttribute('open'); }); }
      window.addEventListener('beforeprint', openAll);
      window.addEventListener('afterprint',  closeAll);
    })();

    /* Clipboard handler for remediation prompt copy button.
       Uses navigator.clipboard with execCommand fallback for file:// origins.
       aria-live span must pre-exist in DOM. */
    (function () {
      var btn = document.querySelector('.copy-btn');
      if (!btn) return;
      var pre = document.querySelector('.remediation pre');
      var live = document.querySelector('[aria-live="polite"]');
      if (!pre || !live) return;
      btn.addEventListener('click', function () {
        var text = pre.textContent;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(
            function () { live.textContent = 'Copied'; },
            function () { fallback(text); }
          );
        } else {
          fallback(text);
        }
      });
      function fallback(text) {
        try {
          var ta = document.createElement('textarea');
          ta.value = text;
          ta.style.position = 'fixed';
          ta.style.opacity = '0';
          document.body.appendChild(ta);
          ta.select();
          var ok = document.execCommand('copy');
          document.body.removeChild(ta);
          live.textContent = ok ? 'Copied' : 'Could not copy — select the text manually';
        } catch (e) {
          live.textContent = 'Could not copy — select the text manually';
        }
      }
    })();
  </script>

</body>
</html>
```
