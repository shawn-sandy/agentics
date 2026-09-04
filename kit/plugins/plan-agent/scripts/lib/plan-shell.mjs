/**
 * plan-shell.mjs — the presentation shell for generated HTML plans.
 *
 * Style and layout ONLY, never plan content: the CSS, icon sprite, and
 * JavaScript below are extracted verbatim from the versioned template at
 * kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html,
 * and every template function takes its content as pre-escaped HTML args.
 * scripts/build-plan-html.mjs is the only consumer; it derives, escapes, and
 * assembles — this module just stamps the ~55 KB of boilerplate the model
 * used to emit by hand.
 *
 * The CSS / ICON_SPRITE / SCRIPT blocks were originally spliced from
 * SKELETON.html by a one-shot generator, but that file is now legacy (it
 * still carries the pre-token hard-coded palette) and is kept only for
 * reference and its smoke tests. THIS file is the template: edit the blocks
 * here, then run `node scripts/rerender-plans.mjs` so the ~110 committed
 * plans under docs/plans/ pick the change up.
 *
 * UI strings below were once byte-for-byte contracts that finalize-plan and
 * the status gates matched with literal find/replace on the HTML. Since the
 * md-first flows (plan-agent 2.20.0) tools edit the Markdown spec and
 * re-render, so these are ordinary presentation strings now — reword freely
 * alongside SKELETON.html.
 */

/* ── UI strings ───────────────────────────────────────────────────── */
const STEP_CHIP = '<span class="step-chip">todo</span>';
const STEP_CHIP_DONE = '<span class="step-chip">done</span>';
const NO_ITEMS_REPORT = 'No items to report — all requirements met.';
const GOAL_LABEL = 'Pursue as goal — optimize for the outcome';
const GOAL_LABEL_PARALLEL = 'Pursue as goal — optimize for the outcome, in parallel';

/* ── Blocks extracted verbatim from SKELETON.html ─────────────────── */
export const CSS = `/* ── Design tokens ─────────────────────────────────────────────────
     Indigo-violet lead on warm-neutral paper. Status is carried by form
     (soft fill + rule) rather than a second colour scale, so every status
     chip inherits the theme instead of pinning white text onto a hue that
     only works on one background. Type has three roles: --mono for every
     structural label, --ui for chrome, --prose for reading text.
     Contrast is a hard constraint, not a preference — every text token
     below clears 4.5:1 on the surfaces it is used against in BOTH
     palettes, and tests/plugins/test-plan-redesign.mjs measures it. ── */
  :root {
    --paper:      #fbfbfd;
    --panel:      #ffffff;
    --sunk:       #f4f4f8;
    --ink:        #14141c;
    --ink-2:      #494959;
    --ink-3:      #63637a;
    --rule:       #e4e4ee;
    --rule-soft:  #f0f0f6;
    --accent:     #3730c4;
    --accent-soft:#eeedfb;
    --accent-line:#c6c2f0;
    --on-accent:  #ffffff;
    --moss:       #2c6a44;
    --moss-soft:  #ecf4ef;
    --moss-line:  #c0dccb;
    --signal:     #8a5209;
    --signal-soft:#fbf3e6;
    --signal-line:#e8d3ac;
    --red:        #b42318;
    --red-bg:     #fdf1f0;
    --red-border: #edc4bf;
    --purple:     #3730c4;
    --purple-bg:  #eeedfb;
    --purple-border:#c6c2f0;
    --wish-bg:    #f4f4f8;
    --wish-border:#c6c2f0;
    --radius:     4px;
    --shadow:     0 1px 2px rgba(20,20,28,.05);
    --mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
    --ui:   system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
    /* Prose is the UI stack on purpose. It used to be Georgia, which collided
       with the mono code spans that saturate plan prose — the corpus carries
       3,000+ of them, so a serif/mono clash was the page's dominant texture.
       No webfont: the Artifact CSP blocks font CDNs, and inlining a face as a
       data URI would add six figures of bytes to each of ~100 committed plan
       files. Character comes from scale, weight, and tracking instead. */
    --prose: var(--ui);
  }

  /* Dark palette. Written twice on purpose: an explicit choice
     ([data-theme]) has to beat the OS preference, and plain CSS has no way
     to share one declaration block between an attribute selector and a
     media query. Keep the two lists in sync — the redesign test asserts
     both selectors define the same token names. */
  :root[data-theme="dark"] {
    --paper:      #0f0f16;
    --panel:      #17171f;
    --sunk:       #1d1d27;
    --ink:        #ecebf2;
    --ink-2:      #b2b0c2;
    --ink-3:      #8a889c;
    --rule:       #2a2a36;
    --rule-soft:  #22222c;
    --accent:     #a8a2f5;
    --accent-soft:#1f1d33;
    --accent-line:#454070;
    --on-accent:  #14141c;
    --moss:       #7cc099;
    --moss-soft:  #17271e;
    --moss-line:  #2e4838;
    --signal:     #e0a86a;
    --signal-soft:#271e12;
    --signal-line:#4a3820;
    --red:        #f4998f;
    --red-bg:     #2a1918;
    --red-border: #4c2a26;
    --purple:     #a8a2f5;
    --purple-bg:  #1f1d33;
    --purple-border:#454070;
    --wish-bg:    #1f1d33;
    --wish-border:#454070;
    --shadow:     0 1px 2px rgba(0,0,0,.4);
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --paper:      #0f0f16;
      --panel:      #17171f;
      --sunk:       #1d1d27;
      --ink:        #ecebf2;
      --ink-2:      #b2b0c2;
      --ink-3:      #8a889c;
      --rule:       #2a2a36;
      --rule-soft:  #22222c;
      --accent:     #a8a2f5;
      --accent-soft:#1f1d33;
      --accent-line:#454070;
      --on-accent:  #14141c;
      --moss:       #7cc099;
      --moss-soft:  #17271e;
      --moss-line:  #2e4838;
      --signal:     #e0a86a;
      --signal-soft:#271e12;
      --signal-line:#4a3820;
      --red:        #f4998f;
      --red-bg:     #2a1918;
      --red-border: #4c2a26;
      --purple:     #a8a2f5;
      --purple-bg:  #1f1d33;
      --purple-border:#454070;
      --wish-bg:    #1f1d33;
      --wish-border:#454070;
      --shadow:     0 1px 2px rgba(0,0,0,.4);
    }
  }
  /* Native controls (checkboxes, scrollbars) follow the resolved theme. */
  :root { color-scheme: light; }
  :root[data-theme="dark"] { color-scheme: dark; }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) { color-scheme: dark; }
  }

  /* ── Reset & base ──────────────────────────────────────────────── */
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  html { scroll-behavior: smooth; }
  body {
    font-family: var(--ui);
    font-size: 16px;
    line-height: 1.55;
    -webkit-font-smoothing: antialiased;
    color: var(--ink);
    background: var(--paper);
  }
  a { color: var(--accent); }
  code, pre {
    font-family: var(--mono);
    font-size: .875em;
  }
  /* Inline spans rendered from backtick markers in plan prose. Scoped to .md
     so the bare <code> carrying file paths and copyable prompts keeps its own
     layout — those live inside chips and rows that already style themselves.
     No backticks in this comment: the whole stylesheet is a JS template. */
  /* Deliberately quiet. A plan paragraph routinely carries five or six of
     these; with a fill AND a border each they turned running prose into a
     barcode, which was the loudest thing on the page. Tint only, no border,
     and a hair smaller than the surrounding text. */
  code.md {
    background: var(--sunk);
    border-radius: 3px;
    padding: .1em .3em;
    font-size: .85em;
    color: var(--ink);
    /* Long paths must wrap rather than force the card into a sideways scroll. */
    overflow-wrap: anywhere;
  }
  strong.md { font-weight: 650; color: var(--ink); }
  em.md { font-style: italic; }
  pre {
    background: var(--sunk);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    padding: .75rem 1rem;
    overflow-x: auto;
    white-space: pre-wrap;
    word-break: break-word;
  }

  /* ── SVG icon helper ────────────────────────────────────────────── */
  .icon {
    width: 1rem;
    height: 1rem;
    display: inline-block;
    vertical-align: middle;
    flex-shrink: 0;
  }

  /* ── Skip link ─────────────────────────────────────────────────── */
  .skip-link {
    position: absolute;
    left: -9999px; top: auto;
    width: 1px; height: 1px;
    overflow: hidden;
  }
  .skip-link:focus {
    position: fixed;
    left: 1rem; top: 1rem;
    width: auto; height: auto;
    overflow: visible;
    background: var(--accent);
    color: var(--on-accent);
    padding: .5rem 1rem;
    border-radius: var(--radius);
    font-weight: 700;
    z-index: 9999;
    text-decoration: none;
  }

  /* ── Header — document cover ────────────────────────────────────── */
  .plan-header {
    background: var(--paper);
    border-bottom: 1px solid var(--rule);
    padding: 0;
  }
  .plan-header::before {
    content: "";
    display: block;
    height: 3px;
    background: var(--accent);
  }
  .plan-header-inner {
    max-width: 1040px;
    margin: 0 auto;
    padding: 1.75rem 1.5rem 1.5rem;
  }
  .plan-header-top {
    display: block;
  }
  /* Sans, not mono. A 2.2rem monospaced headline read as a terminal dump
     rather than a document title; the weight and the tight tracking carry
     the emphasis instead. */
  .plan-title {
    font-size: clamp(1.7rem, 4vw, 2.35rem);
    font-weight: 700;
    letter-spacing: -.028em;
    line-height: 1.12;
    color: var(--ink);
    max-width: 24ch;
    text-wrap: balance;
  }
  /* State reads before controls. The markup order is fixed by the renderer
     (buttons, then badges), so the visual order is set here rather than by
     moving nodes the extractor and the gallery both walk. */
  .plan-header-actions {
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-wrap: wrap;
    margin-top: 1rem;
  }
  .plan-header-actions .status-badge { order: 1; }
  .plan-header-actions .effort-badge { order: 2; }
  .plan-header-actions .prototype-link,
  .plan-header-actions .issue-link,
  .plan-header-actions .design-link { order: 3; }
  .plan-header-actions .save-pdf-btn { order: 4; margin-left: auto; }
  .plan-header-actions .theme-toggle { order: 5; }
  @media (max-width: 560px) {
    .plan-header-actions .save-pdf-btn { margin-left: 0; }
  }

  /* Status badge */
  .status-badge {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    font-size: .7rem;
    font-weight: 700;
    letter-spacing: .06em;
    text-transform: uppercase;
    padding: .25rem .75rem;
    border-radius: 999px;
    white-space: nowrap;
    flex-shrink: 0;
    font-family: var(--mono);
    color: var(--ink-3);
    background: var(--sunk);
    border: 1px solid var(--rule);
  }
  .status-badge::before {
    content: "";
    display: inline-block;
    width: .45em;
    height: .45em;
    border-radius: 50%;
    background: currentColor;
    flex-shrink: 0;
  }
  [data-status="in-progress"] .status-badge { color: var(--signal); background: var(--signal-soft); border-color: var(--signal-line); }
  [data-status="completed"]   .status-badge { color: var(--moss);   background: var(--moss-soft);   border-color: var(--moss-line); }

  /* Effort badge — color tracks the data-effort attribute, mirroring .status-badge */
  .effort-badge {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    font-size: .7rem;
    font-weight: 700;
    letter-spacing: .06em;
    text-transform: uppercase;
    padding: .25rem .75rem;
    border-radius: 999px;
    white-space: nowrap;
    flex-shrink: 0;
    font-family: var(--mono);
    color: var(--ink-3);
    background: var(--sunk);
    border: 1px solid var(--rule);
  }
  .effort-badge::before { content: "Effort "; opacity: .7; }
  [data-effort="low"]    .effort-badge { color: var(--moss);   border-color: var(--moss-line); }
  [data-effort="medium"] .effort-badge { color: var(--signal); border-color: var(--signal-line); }
  [data-effort="high"]   .effort-badge { color: var(--red);    border-color: var(--red-border); }

  /* Header links (prototype / issue / design) — the badges' chip, in the
     accent colour so they still read as links. Before this rule they had no
     CSS at all: bare underlined text at the flex default order 0, ahead of
     the status badge. No underline — the pill border is the affordance, and
     an underline under .7rem uppercase mono cuts straight through it. */
  .prototype-link,
  .issue-link,
  .design-link {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    font-size: .7rem;
    font-weight: 700;
    letter-spacing: .06em;
    text-transform: uppercase;
    padding: .25rem .75rem;
    border-radius: 999px;
    white-space: nowrap;
    flex-shrink: 0;
    font-family: var(--mono);
    color: var(--accent);
    background: var(--accent-soft);
    border: 1px solid var(--accent-line);
    text-decoration: none;
  }
  .prototype-link:hover,
  .issue-link:hover,
  .design-link:hover { border-color: var(--accent); text-decoration: underline; }

  @keyframes pulse-dot { 0%, 100% { opacity: 1; } 50% { opacity: .3; } }
  [data-status="in-progress"] .status-badge::before {
    animation: pulse-dot 1.4s ease-in-out infinite;
  }
  @media (prefers-reduced-motion: reduce) {
    html { scroll-behavior: auto; }
    [data-status="in-progress"] .status-badge::before { animation: none; }
  }

  /* Save as PDF button */
  .save-pdf-btn {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    padding: .4rem 1rem;
    font-size: .75rem;
    font-weight: 600;
    font-family: var(--mono);
    color: var(--on-accent);
    background: var(--accent);
    border: 1px solid var(--accent);
    border-radius: 4px;
    cursor: pointer;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
    transition: filter .15s, box-shadow .15s;
  }
  .save-pdf-btn:hover { filter: brightness(1.12); }
  .save-pdf-btn:active { filter: brightness(.92); }
  .save-pdf-btn:focus-visible { outline: 3px solid var(--accent); outline-offset: 2px; }
  @media (prefers-reduced-motion: reduce) { .save-pdf-btn { transition: none; } }

  /* Theme toggle — a square sibling of Save as PDF, not a second label.
     The comment here used to claim "same shape as Save as PDF" while
     matching it on nothing: 44px tall against 32px, uppercase mono against
     sentence case, plus .08em of extra tracking. The pair read as two
     unrelated controls and the quieter one won an argument it should never
     have entered.

     The word is now a sun/moon icon, and the box is derived from the PDF
     button rather than guessed — identical padding, and an icon of 1.4em at
     the same .75rem font, which is exactly that button's line box. Both
     resolve to 31.6px, so the toggle is a true square beside it.

     The old min-width/min-height of 44px was a touch-target workaround. The
     pointer: coarse block down by the print styles now gives every control
     the same 44px hit area, so the base style no longer has to be
     thumb-sized on a desktop where it will never be tapped. */
  .theme-toggle {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: .4rem;
    font-size: .75rem;
    line-height: 1.4;
    color: var(--ink-2);
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: 4px;
    cursor: pointer;
    flex-shrink: 0;
  }
  .theme-toggle .icon { width: 1.4em; height: 1.4em; }
  .theme-toggle:hover { color: var(--accent); border-color: var(--accent-line); }
  .theme-toggle:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

  /* Meta row */
  .plan-meta {
    display: flex;
    gap: 1.5rem;
    flex-wrap: wrap;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--rule);
    font-variant-numeric: tabular-nums;
    font-family: var(--mono);
    font-size: .7rem;
    color: var(--ink-2);
  }
  .plan-meta span {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
  }
  .plan-meta .icon { opacity: .55; }

  /* ── Layout ────────────────────────────────────────────────────── */
  .layout {
    display: grid;
    grid-template-columns: 15rem minmax(0, 1fr);
    gap: 3.5rem;
    max-width: 1100px;
    margin: 0 auto;
    padding: 2.5rem 1.5rem 5rem;
    align-items: start;
  }
  /* 900, not 720: the sidebar now carries a step rail and is 15rem wide, so
     between those two widths the main column was narrow enough to break a
     copyable path across four lines. Collapse to one column sooner. */
  @media (max-width: 900px) {
    .layout { grid-template-columns: 1fr; padding: 1.5rem .75rem 4rem; gap: 0; }
  }

  /* ── Sidebar — table of contents ───────────────────────────────── */
  .plan-nav {
    position: sticky;
    top: 1.5rem;
    align-self: start;
    overflow: hidden;
  }
  @media (max-width: 900px) {
    .plan-nav {
      position: static;
      border-bottom: 1px solid var(--rule);
      padding-bottom: 1.5rem;
      margin-bottom: 2rem;
    }
  }
  .nav-heading {
    font-family: var(--mono);
    font-size: .625rem;
    font-weight: 600;
    letter-spacing: .16em;
    text-transform: uppercase;
    color: var(--ink-3);
    padding: 0 1rem .6rem;
    margin-bottom: .25rem;
    border-bottom: 1px solid var(--rule);
  }
  .scroll-rail {
    position: absolute;
    left: 0; top: 0; bottom: 0;
    width: 2px;
    background: var(--rule);
    border-radius: 1px;
    overflow: hidden;
    pointer-events: none;
  }
  /* Scaled, not resized. This fill is rewritten on every scroll frame of a
     document that routinely passes 9,000px, and animating the height property relaid
     out the sidebar on each one. scaleY is compositor-only, and with the
     handler throttled to one write per animation frame the growth is already
     smooth — the old .1s transition only lagged the rail behind the
     scrollbar. Nothing animates now, so there is no reduced-motion case: a
     position indicator that tracks the scrollbar is not motion. */
  .scroll-rail::after {
    content: "";
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 100%;
    transform: scaleY(calc(var(--scroll-pct, 0) / 100));
    transform-origin: top center;
    background: var(--accent);
  }
  .plan-nav ul { list-style: none; padding: 0; margin: 0; }
  .plan-nav > ul > li > a {
    display: flex;
    align-items: center;
    min-height: 44px;
    padding: .125rem 1rem .125rem 1.25rem;
    font-size: .825rem;
    color: var(--ink-2);
    text-decoration: none;
    gap: .5rem;
    border-left: 2px solid transparent;
    transition: color .12s, border-color .12s;
  }
  .plan-nav a:hover { color: var(--ink); border-left-color: var(--accent-line); }
  .plan-nav a.active { color: var(--accent); font-weight: 600; border-left-color: var(--accent); }
  .plan-nav a:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  .plan-nav .icon { opacity: .65; }
  .plan-nav a.active .icon,
  .plan-nav a:hover .icon { opacity: 1; }

  /* ── Step rail — one link per step, the plan's real structure ───── */
  .rail-steps {
    list-style: none;
    margin: 0;
    padding: 0;
    border-top: 1px solid var(--rule);
    padding-top: .5rem;
    margin-top: .75rem;
  }
  .rail-heading {
    font-family: var(--mono);
    font-size: .625rem;
    font-weight: 600;
    letter-spacing: .16em;
    text-transform: uppercase;
    color: var(--ink-3);
    padding: 0 1rem .45rem 1.25rem;
  }
  a.rail-step {
    display: grid;
    grid-template-columns: 1.6rem minmax(0, 1fr);
    align-items: baseline;
    gap: .35rem;
    min-height: 30px;
    padding: .3rem 1rem .3rem 1.25rem;
    font-size: .78rem;
    line-height: 1.35;
    color: var(--ink-2);
    text-decoration: none;
    border-left: 2px solid var(--rule-soft);
    transition: color .12s, border-color .12s;
  }
  @media (prefers-reduced-motion: reduce) { a.rail-step { transition: none; } }
  a.rail-step .rail-no {
    font-family: var(--mono);
    font-size: .7rem;
    color: var(--ink-3);
  }
  a.rail-step .rail-text {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  a.rail-step.done .rail-no { color: var(--moss); }
  a.rail-step.done .rail-text { color: var(--ink-3); }
  a.rail-step.active {
    color: var(--ink);
    font-weight: 600;
    border-left-color: var(--accent);
    background: linear-gradient(90deg, var(--accent-soft), transparent 75%);
  }
  a.rail-step.active .rail-no { color: var(--accent); }
  /* Visually-hidden step state — the tick glyph alone tells a screen reader
     nothing, so every rail link carries "step N of M[, done]" in text. */
  .rail-state {
    position: absolute;
    width: 1px; height: 1px;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
  }
  /* Once the sidebar stops being a sidebar the step list collapses into a
     disclosure rather than disappearing — a phone reader keeps every jump
     target. The element ships OPEN and the inline script closes it below the
     breakpoint: a closed-by-default <details> would hide the whole rail on
     desktop when scripting is off, and no-JS-on-mobile only costs some
     scrolling. */
  .rail-disclosure { margin-top: .75rem; }
  .rail-disclosure > summary {
    display: none;
    font-family: var(--mono);
    font-size: .7rem;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--ink-2);
    cursor: pointer;
    list-style: none;
    align-items: center;
    gap: .4rem;
    min-height: 44px;
    padding: 0 1rem 0 1.25rem;
  }
  .rail-disclosure > summary::-webkit-details-marker { display: none; }
  .rail-disclosure > summary::before { content: "▶"; font-size: .55em; }
  .rail-disclosure[open] > summary::before { content: "▼"; }
  @media (max-width: 900px) {
    .rail-disclosure > summary { display: flex; }
  }

  /* ── Objective card — executive summary ────────────────────────── */
  /* A lead statement, not a slab. The filled panel put a saturated block of
     colour directly above the green Implement row, so the page opened on two
     competing fills before a word of content. One accent rule carries the
     same "this is the point" signal at a fraction of the noise. */
  .objective-card {
    background: transparent;
    border: 0;
    border-left: 2px solid var(--accent);
    border-radius: 0;
    padding: .1rem 0 .1rem 1.25rem;
    margin-bottom: 2rem;
    color: var(--ink);
  }
  .objective-card > p {
    font-size: 1.15rem;
    line-height: 1.5;
    letter-spacing: -.011em;
    color: var(--ink);
    max-width: 62ch;
    text-wrap: pretty;
  }
  .objective-card .section-label,
  .plan-glance-label {
    font-family: var(--mono);
    font-size: .625rem;
    font-weight: 600;
    letter-spacing: .16em;
    text-transform: uppercase;
    color: var(--accent);
    margin-bottom: .5rem;
  }

  /* ── At a glance — the plain-language register of the same goal, nested
        inside #objective so the reader meets one summary, not two. ────── */
  .plan-glance {
    margin-top: 1rem;
    padding-top: .85rem;
    border-top: 1px solid var(--rule);
    max-width: 66ch;
  }
  .plan-glance p { margin: 0; color: var(--ink-2); font-size: .92rem; line-height: 1.65; }

  /* ── Progress bar ──────────────────────────────────────────────── */
  .progress-wrap {
    margin-bottom: 2.5rem;
    padding-bottom: 1.5rem;
    border-bottom: 1px solid var(--rule);
  }
  .progress-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: .6rem;
    /* "11 / 13 done" is rewritten every time a box is ticked. Proportional
       figures reflow the label under the reader's cursor as it counts. */
    font-variant-numeric: tabular-nums;
    font-family: var(--mono);
    font-size: .65rem;
    font-weight: 600;
    color: var(--ink-2);
    text-transform: uppercase;
    letter-spacing: .16em;
  }
  .progress-bar-bg { height: 4px; background: var(--rule); border-radius: 999px; overflow: hidden; }
  /* This one keeps its width transition, unlike the scroll rail above, and
     the reasons are the pill and the no-JS render. scaleX on a 4px bar with
     a 999px radius squashes the end caps into ellipses at low percentages,
     and the server-rendered state is an inline width:N% so the bar is
     correct with scripting off. It also animates once per checkbox tick
     rather than once per scroll frame, so the layout cost is noise. */
  .progress-bar-fill {
    height: 100%;
    border-radius: 999px;
    background: var(--accent);
    transition: width .5s cubic-bezier(.4,0,.2,1);
    width: 0%;
  }
  @media (prefers-reduced-motion: reduce) {
    .progress-bar-fill { transition: none; }
  }

  /* ── Document sections ─────────────────────────────────────────── */
  .section-card {
    background: transparent;
    border: none;
    border-top: 1px solid var(--rule);
    border-radius: 0;
    padding: 2rem 0 1.25rem;
    margin-bottom: 0;
    box-shadow: none;
  }
  .section-card:first-of-type { border-top: none; }
  .section-card h2 {
    font-size: 1.05rem;
    font-weight: 650;
    letter-spacing: -.015em;
    color: var(--ink);
    margin-bottom: 1.25rem;
    display: flex;
    align-items: center;
    gap: .6rem;
  }
  .section-card h2::after { content: ""; flex: 1; height: 1px; background: var(--rule); }
  .section-card h2 .icon { opacity: .75; }
  .section-card .section-intro {
    font-size: .85rem;
    color: var(--ink-2);
    margin: -1rem 0 1.25rem;
  }
  .section-card p {
    margin-bottom: .75rem;
    /* Reading text sits in the primary ink. It was --ink-2, which set every
       paragraph of the document one step back from the labels around it. */
    color: var(--ink);
    font-size: .975rem;
    line-height: 1.68;
    max-width: 68ch;
  }
  .section-card p.section-intro { font-family: var(--ui); font-size: .85rem; }
  .section-card p strong.md { color: var(--ink); }
  .section-card p:last-child { margin-bottom: 0; }
  .section-card ul, .section-card ol {
    padding-left: 1.4rem;
    display: flex;
    flex-direction: column;
    gap: .4rem;
  }

  /* ── Steps ──────────────────────────────────────────────────────── */
  .steps-list { display: flex; flex-direction: column; }

  /* Records, not cards: a rule between steps, no box and no dotted
     timeline. The sidebar rail is the page's one progress device now. */
  .step-card {
    background: transparent;
    border: 0;
    border-top: 1px solid var(--rule-soft);
    border-radius: 0;
    padding: 1.05rem 0;
    box-shadow: none;
    position: relative;
    scroll-margin-top: 1.5rem;
  }
  .step-card:first-child { border-top: 0; }

  .step-card-header { display: flex; align-items: flex-start; gap: .75rem; }
  .step-number {
    flex-shrink: 0;
    width: 2rem;
    font-variant-numeric: tabular-nums;
    font-family: var(--mono);
    color: var(--ink-3);
    font-size: .8rem;
    font-weight: 600;
    padding-top: .12rem;
  }
  .step-card.completed .step-number { color: var(--moss); }
  .step-body { flex: 1; min-width: 0; }
  /* Emphasised body, not a heading. At 600 across a full-width line the
     action out-shouted the section headings above it, and a plan of twelve
     steps read as twelve headlines. */
  .step-action {
    /* 500, not 550: the system stack has no variable axis here, so 550 snaps
       to semibold and the step reads as a heading again. */
    font-weight: 500;
    font-size: .95rem;
    line-height: 1.6;
    margin-bottom: .35rem;
    display: flex;
    align-items: baseline;
    gap: .45rem;
    flex-wrap: wrap;
    color: var(--ink);
  }
  .step-chip {
    display: inline-block;
    font-family: var(--mono);
    font-size: .58rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .12em;
    padding: .12em .5em;
    border-radius: 3px;
    background: var(--sunk);
    color: var(--ink-3);
    border: 1px solid var(--rule);
    vertical-align: middle;
    user-select: none;
    flex-shrink: 0;
  }
  .step-card.completed .step-chip {
    background: var(--moss-soft);
    color: var(--moss);
    border-color: var(--moss-line);
  }
  .step-chip-text { flex: 1; }

  /* Why and Verify are both always visible. Verify is the line a reader
     needs WHILE executing the step — putting it behind a disclosure was the
     single worst call in the previous shell. */
  .step-note {
    display: grid;
    grid-template-columns: 4rem minmax(0, 1fr);
    gap: .1rem .75rem;
    margin-top: .5rem;
    font-size: .85rem;
    line-height: 1.6;
    color: var(--ink-2);
  }
  .step-note > .step-note-label {
    font-family: var(--mono);
    font-size: .6rem;
    font-weight: 600;
    letter-spacing: .14em;
    text-transform: uppercase;
    color: var(--ink-3);
    padding-top: .25rem;
  }
  .step-verify > .step-note-label { color: var(--accent); }
  @media (max-width: 560px) {
    .step-note { grid-template-columns: 1fr; gap: .1rem; }
  }

  /* ── Acceptance criteria ───────────────────────────────────────── */
  .criteria-list {
    list-style: none; padding: 0;
    display: flex; flex-direction: column; gap: .6rem;
  }
  .criteria-list li {
    display: flex;
    align-items: flex-start;
    gap: .75rem;
    padding: .6rem .75rem;
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    background: var(--panel);
    transition: background .12s;
  }
  .criteria-list li:has(input:checked) { background: var(--sunk); }
  .criteria-list input[type="checkbox"] {
    flex-shrink: 0;
    width: 1rem; height: 1rem;
    margin-top: .2rem;
    accent-color: var(--moss);
    cursor: pointer;
  }
  .criteria-list label { cursor: pointer; font-size: .9rem; }
  .criteria-list input:checked + label { text-decoration: line-through; color: var(--ink-2); }

  /* ── Completion checklist ────────────────────────────────────── */
  .completion-checklist {
    background: var(--panel);
    border: 2px solid var(--signal);
    border-radius: var(--radius);
    padding: 1.25rem 1.5rem;
    margin-top: 1rem;
  }
  .completion-checklist.all-complete { border-color: var(--moss); }
  .completion-header {
    display: flex;
    align-items: center;
    gap: .5rem;
    margin-bottom: 1rem;
  }
  .completion-badge {
    font-size: .6rem;
    font-weight: 700;
    letter-spacing: .08em;
    text-transform: uppercase;
    padding: .15rem .6rem;
    border-radius: 999px;
    background: var(--signal-soft);
    color: var(--signal);
    border: 1px solid var(--signal-line);
  }
  .completion-checklist.all-complete .completion-badge {
    background: var(--moss-soft);
    color: var(--moss);
    border-color: var(--moss-line);
  }
  .completion-list {
    list-style: none; padding: 0;
    display: flex; flex-direction: column; gap: .6rem;
  }
  .completion-list li {
    display: flex;
    align-items: flex-start;
    gap: .75rem;
    padding: .6rem .75rem;
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    background: var(--panel);
    transition: background .12s;
  }
  .completion-list li:has(input:checked) { background: var(--sunk); }
  .completion-list input[type="checkbox"] {
    flex-shrink: 0;
    width: 1rem; height: 1rem;
    margin-top: .2rem;
    accent-color: var(--moss);
  }
  .completion-list label { font-size: .9rem; }
  .completion-list input:checked + label { text-decoration: line-through; color: var(--ink-2); }
  @media (prefers-reduced-motion: reduce) {
    .completion-list li { transition: none; }
  }

  /* ── Completion report ─────────────────────────────────────── */
  .completion-report {
    margin-top: 1.25rem;
    padding-top: 1rem;
    border-top: 1px solid var(--rule);
  }
  .report-heading {
    font-size: .75rem;
    font-weight: 700;
    letter-spacing: .08em;
    text-transform: uppercase;
    color: var(--ink-2);
    margin-bottom: .75rem;
  }
  .report-empty {
    font-style: italic;
    color: var(--ink-3);
    font-size: .875rem;
  }
  .report-list { margin: 0; padding: 0; }
  .report-list dt {
    font-weight: 600;
    color: var(--ink);
    font-size: .875rem;
    display: flex;
    align-items: center;
    gap: .4rem;
    margin-top: .75rem;
  }
  .report-list dt:first-child { margin-top: 0; }
  .report-list dt::before {
    content: "";
    display: inline-block;
    width: .5rem; height: .5rem;
    border-radius: 50%;
    background: var(--red);
    flex-shrink: 0;
  }
  .report-list dd {
    color: var(--ink-2);
    font-size: .85rem;
    margin-left: .9rem;
    margin-top: .2rem;
    margin-bottom: 0;
  }

  /* ── Next steps ────────────────────────────────────────────────── */
  .next-steps-list { padding: 0; display: flex; flex-direction: column; gap: .75rem; }
  .next-step-item {
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    overflow: hidden;
    background: var(--panel);
  }
  .next-step-item summary {
    font-weight: 600;
    font-size: .9rem;
    padding: .75rem 1rem;
    cursor: pointer;
    list-style: none;
    display: flex;
    align-items: center;
    gap: .5rem;
    background: var(--panel);
    user-select: none;
    min-height: 44px;
  }
  .next-step-item summary::before { content: "▶"; font-size: .55em; color: var(--ink-3); transition: transform .2s; }
  .next-step-item[open] summary::before { transform: rotate(90deg); }
  .next-step-prompt { padding: .75rem 1rem 1rem; background: var(--sunk); border-top: 1px solid var(--rule); }
  .next-step-prompt p { font-size: .8rem; color: var(--ink-2); margin-bottom: .5rem; }
  .next-step-prompt pre { margin: 0; }
  @media (prefers-reduced-motion: reduce) { .next-step-item summary::before { transition: none; } }

  /* ── Copy prompt button ─────────────────────────────────────── */
  .copy-prompt-btn {
    display: inline-flex;
    align-items: center;
    gap: .35rem;
    margin-top: .6rem;
    padding: .3rem .75rem;
    font-size: .775rem;
    font-weight: 500;
    color: var(--accent);
    background: var(--accent-soft);
    border: 1px solid var(--accent-line);
    border-radius: var(--radius);
    cursor: pointer;
    transition: background .12s, color .12s, border-color .12s;
    font-family: inherit;
    line-height: 1.4;
  }
  .copy-prompt-btn:hover { background: var(--accent-soft); border-color: var(--accent); }
  .copy-prompt-btn:active { background: var(--accent-line); }
  .copy-prompt-btn.copied { color: var(--moss); background: var(--moss-soft); border-color: var(--moss-line); }
  .copy-prompt-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  @media print { .copy-prompt-btn { display: none !important; } }
  @media (prefers-reduced-motion: reduce) { .copy-prompt-btn { transition: none; } }
  /* Shared clipboard-failure state for every copy button */
  .copy-failed { color: var(--red) !important; background: var(--red-bg) !important; border-color: var(--red-border) !important; white-space: normal; }

  /* Wish list variant */
  .wish-list-header {
    display: flex;
    align-items: center;
    gap: .5rem;
    font-size: .68rem;
    font-weight: 700;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--purple);
    margin: 1.5rem 0 .75rem;
  }
  .wish-list-header::after {
    content: "";
    flex: 1;
    height: 1px;
    background: var(--wish-border);
    opacity: .5;
  }
  .wish-item { border: 1px dashed var(--wish-border) !important; background: var(--wish-bg) !important; }
  .wish-item summary { background: var(--wish-bg) !important; color: var(--purple); }
  .wish-badge {
    font-size: .6rem;
    background: var(--purple-bg);
    color: var(--purple);
    padding: .1rem .5rem;
    border-radius: 999px;
    font-weight: 700;
    letter-spacing: .04em;
    text-transform: uppercase;
    margin-left: auto;
    border: 1px solid var(--purple-border);
  }

  /* ── Collapsible optional sections ─────────────────────────────── */
  .optional-section {
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    margin-top: 1.5rem;
    overflow: hidden;
    background: var(--panel);
  }
  .optional-section > summary {
    padding: .875rem 1.25rem;
    font-weight: 600;
    font-size: .9rem;
    cursor: pointer;
    list-style: none;
    display: flex;
    align-items: center;
    gap: .6rem;
    user-select: none;
    min-height: 44px;
  }
  .optional-section > summary::before,
  .plan-more-ways > summary::before { content: "▶"; font-size: .55em; color: var(--ink-3); transition: transform .2s; }
  .optional-section[open] > summary::before,
  .plan-more-ways[open] > summary::before { transform: rotate(90deg); }
  .optional-body { padding: 0 1.25rem 1.25rem; border-top: 1px solid var(--rule); padding-top: 1rem; }
  .unresolved-list { list-style: none; padding: 0; display: flex; flex-direction: column; gap: 1rem; }
  .unresolved-item summary { font-weight: 600; padding: .35rem 0; cursor: pointer; list-style: none; user-select: none; font-size: .9rem; }
  .unresolved-prompt { margin-top: .5rem; }
  @media (prefers-reduced-motion: reduce) { .optional-section > summary::before, .plan-more-ways > summary::before { transition: none; } }

  /* ── More-ways drawer (goal / workflow / plan-source rows) ─────── */
  .plan-more-ways {
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    background: var(--panel);
    margin: -.5rem 0 1.5rem;
    font-size: .8rem;
    overflow: hidden;
  }
  .plan-more-ways > summary {
    padding: .55rem 1rem;
    font-size: .78rem;
    font-weight: 600;
    color: var(--ink-2);
    cursor: pointer;
    list-style: none;
    display: flex;
    align-items: center;
    gap: .5rem;
    user-select: none;
    min-height: 44px;
  }
  .plan-more-ways > summary:hover { color: var(--accent); }
  .more-ways-hint { font-weight: 400; color: var(--ink-2); }
  .plan-more-ways-body {
    padding: .75rem 1rem 1rem;
    border-top: 1px solid var(--rule);
    display: flex;
    flex-direction: column;
    gap: .75rem;
  }
  @media print { .plan-more-ways { display: none !important; } }

  /* ── Implement prompt ─────────────────────────────────────────── */
  .plan-implement {
    display: flex;
    align-items: flex-start;
    gap: .6rem;
    margin-bottom: 1.5rem;
    padding: .55rem .8rem;
    /* Not moss: moss means "done" everywhere else on the page, so a green
       call-to-action on an unstarted plan said the opposite of what it meant.
       Not a tinted slab either — this prompt runs to eight wrapped lines of
       monospace, and any fill that large outshouted the objective above it.
       Neutral surface, accent only on the label. */
    background: var(--sunk);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    font-size: .8rem;
  }
  .plan-implement-label {
    font-family: var(--mono);
    font-size: .62rem;
    font-weight: 600;
    letter-spacing: .14em;
    text-transform: uppercase;
    color: var(--accent);
    flex-shrink: 0;
    margin-top: .2rem;
  }
  .plan-implement code {
    font-family: var(--mono);
    font-size: .82rem;
    color: var(--ink);
    flex: 1;
    overflow-wrap: anywhere;
  }
  .copy-cmd-btn {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .2rem .6rem;
    font-size: .72rem;
    font-weight: 500;
    color: var(--ink-2);
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    cursor: pointer;
    transition: background .12s, color .12s, border-color .12s;
    font-family: inherit;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .copy-cmd-btn:hover { background: var(--accent-soft); color: var(--accent); border-color: var(--accent-line); }
  .copy-cmd-btn.copied { color: var(--moss); background: var(--moss-soft); border-color: var(--moss-line); }
  .copy-cmd-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  [data-status="completed"] .copy-cmd-btn { display: none; }
  @media print { .plan-implement { display: none !important; } }
  @media (prefers-reduced-motion: reduce) { .copy-cmd-btn { transition: none; } }

  /* ── Plan source (file name + relative path — lives in the drawer) ── */
  /* Borderless like its sibling drawer rows — the drawer body supplies the frame */
  .plan-source {
    display: flex;
    flex-direction: column;
    gap: .4rem;
    margin: 0;
    padding: .55rem .75rem;
    font-size: .8rem;
  }
  .plan-source-row { display: flex; align-items: center; gap: .6rem; }
  .plan-source-label {
    font-size: .65rem;
    font-weight: 700;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--ink-2);
    flex-shrink: 0;
    width: 2.4rem;
  }
  .plan-source code {
    font-family: var(--mono);
    font-size: .82rem;
    color: var(--ink);
    flex: 1;
    overflow-wrap: anywhere;
  }
  .copy-src-btn {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .2rem .6rem;
    font-size: .72rem;
    font-weight: 500;
    color: var(--ink-2);
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    cursor: pointer;
    transition: background .12s, color .12s, border-color .12s;
    font-family: inherit;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .copy-src-btn:hover { background: var(--accent-soft); color: var(--accent); border-color: var(--accent-line); }
  .copy-src-btn.copied { color: var(--moss); background: var(--moss-soft); border-color: var(--moss-line); }
  .copy-src-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  @media print { .copy-src-btn { display: none !important; } }
  @media (prefers-reduced-motion: reduce) { .copy-src-btn { transition: none; } }

  /* ── Workflow prompt row (conditional — remove row when empty; lives in the drawer) ── */
  .plan-workflow {
    margin: 0;
    font-size: .8rem;
  }
  .plan-workflow-label {
    font-size: .7rem;
    font-weight: 600;
    color: var(--accent);
    padding: .1rem 0;
  }
  .plan-workflow-inner {
    display: flex;
    align-items: flex-start;
    gap: .6rem;
    margin-top: .4rem;
    padding: .45rem .75rem;
    background: var(--accent-soft);
    border: 1px solid var(--accent-line);
    border-radius: var(--radius);
  }
  .plan-workflow code {
    font-family: var(--mono);
    font-size: .82rem;
    color: var(--ink);
    flex: 1;
    overflow-wrap: anywhere;
  }
  .copy-workflow-btn {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .2rem .6rem;
    font-size: .72rem;
    font-weight: 500;
    color: var(--ink-2);
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    cursor: pointer;
    transition: background .12s, color .12s, border-color .12s;
    font-family: inherit;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .copy-workflow-btn:hover { background: var(--accent-soft); color: var(--accent); border-color: var(--accent-line); }
  .copy-workflow-btn.copied { color: var(--moss); background: var(--moss-soft); border-color: var(--moss-line); }
  .copy-workflow-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  [data-status="completed"] .plan-workflow { display: none; }
  /* Redundant under .plan-more-ways' print hide; kept to mirror the test-pinned .plan-goal print rule */
  @media print { .plan-workflow { display: none !important; } }
  @media (prefers-reduced-motion: reduce) { .copy-workflow-btn { transition: none; } }

  /* ── Goal prompt row (outcome-driven — always present; lives in the drawer) ── */
  .plan-goal {
    margin: 0;
    font-size: .8rem;
  }
  .plan-goal-label {
    font-size: .7rem;
    font-weight: 600;
    color: var(--purple);
    padding: .1rem 0;
  }
  .plan-goal-inner {
    display: flex;
    align-items: flex-start;
    gap: .6rem;
    margin-top: .4rem;
    padding: .45rem .75rem;
    background: var(--purple-bg);
    border: 1px solid var(--purple-border);
    border-radius: var(--radius);
  }
  .plan-goal code {
    font-family: var(--mono);
    font-size: .82rem;
    color: var(--ink);
    flex: 1;
    overflow-wrap: anywhere;
  }
  .copy-goal-btn {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .2rem .6rem;
    font-size: .72rem;
    font-weight: 500;
    color: var(--ink-2);
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    cursor: pointer;
    transition: background .12s, color .12s, border-color .12s;
    font-family: inherit;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
  }
  .copy-goal-btn:hover { background: var(--accent-soft); color: var(--accent); border-color: var(--accent-line); }
  .copy-goal-btn.copied { color: var(--moss); background: var(--moss-soft); border-color: var(--moss-line); }
  .copy-goal-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  [data-status="completed"] .plan-goal { display: none; }
  /* Redundant under .plan-more-ways' print hide, but pinned byte-for-byte by test-goal-prompt.sh check 4 */
  @media print { .plan-goal { display: none !important; } }
  @media (prefers-reduced-motion: reduce) { .copy-goal-btn { transition: none; } }

  /* ── Tests section ──────────────────────────────────────────────── */
  .test-list {
    display: flex;
    flex-direction: column;
    gap: .75rem;
  }
  .test-card {
    background: var(--panel);
    border: 1px solid var(--rule);
    border-radius: var(--radius);
    padding: 1rem 1.25rem;
    box-shadow: var(--shadow);
  }
  .test-card-header {
    display: flex;
    align-items: center;
    gap: .6rem;
    margin-bottom: .5rem;
    flex-wrap: wrap;
  }
  .test-badge {
    display: inline-block;
    font-size: .6rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: .06em;
    padding: .15em .55em;
    border-radius: 999px;
    flex-shrink: 0;
  }
  .test-badge-unit        { background: var(--accent-soft); color: var(--accent); border: 1px solid var(--accent-line); }
  .test-badge-integration { background: var(--signal-soft);  color: var(--signal);  border: 1px solid var(--signal-line); }
  .test-badge-e2e         { background: var(--purple-bg);  color: var(--purple);  border: 1px solid var(--purple-border); }
  .test-badge-objective   { background: var(--moss-soft);  color: var(--moss);  border: 1px solid var(--moss-line); }
  .test-card-title {
    font-weight: 600;
    font-size: .95rem;
    color: var(--ink);
    flex: 1;
  }
  .test-card-body { font-size: .875rem; color: var(--ink-2); }
  .test-card-body p { margin-bottom: .4rem; }
  .test-card-body p:last-child { margin-bottom: 0; }
  .test-card-body code { font-size: .85em; }
  .test-card-body strong { color: var(--ink); font-weight: 600; }
  .test-tier-label {
    font-size: .68rem;
    font-weight: 700;
    letter-spacing: .1em;
    text-transform: uppercase;
    color: var(--ink-2);
    margin-bottom: .75rem;
    display: flex;
    align-items: center;
    gap: .4rem;
  }
  .test-tier-label::after {
    content: "";
    flex: 1;
    height: 1px;
    background: var(--rule);
  }
  .objective-test-card {
    background: var(--moss-soft);
    /* An even 1px rule, not a 4px tab on one edge. The fill, the border
       tint, the Objective badge and the moss title already say "this is the
       test that decides", three times over. */
    border: 1px solid var(--moss-line);
    border-radius: var(--radius);
    padding: 1.25rem 1.5rem;
    margin-bottom: 1rem;
    box-shadow: var(--shadow);
  }
  .objective-test-card .test-card-header { margin-bottom: .6rem; }
  .objective-test-card .test-card-title { color: var(--moss); }
  .objective-test-card .test-card-body { color: var(--moss); }
  .objective-test-card .test-card-body strong { color: var(--moss); }
  /* ── Footer ────────────────────────────────────────────────────── */
  .plan-footer {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: .4rem;
    font-size: .75rem;
    color: var(--ink-3);
    margin-top: 3rem;
    padding-top: 1.25rem;
    border-top: 1px solid var(--rule);
  }
  .plan-footer .icon { opacity: .35; }

  /* ── Browser surfaces ────────────────────────────────────────────
     The parts nobody drew. A plan is a long read — this file is ~9,000px
     tall — so the selection highlight and the scrollbar are two of the most
     persistent elements on screen, and both shipped as OS defaults: a
     system-blue highlight over a violet document, and a scrollbar belonging
     to no palette here. Themed from existing tokens, so both palettes and
     the toggle follow for free with no new names for the parity test to
     police. Measured with the same checker as the token table: selected
     text reads 10.8:1 (light) and 8.0:1 (dark); the thumb sits at 5.7:1 and
     5.5:1 against paper, a target rather than a tint. ── */
  ::selection {
    background: var(--accent-line);
    color: var(--ink);
  }
  html {
    scrollbar-width: thin;
    scrollbar-color: var(--ink-3) transparent;
  }
  ::-webkit-scrollbar { width: 11px; height: 11px; }
  ::-webkit-scrollbar-track { background: transparent; }
  /* Transparent border + content-box clip floats a 5px thumb inside an 11px
     gutter, so it reads the same over paper, over --sunk code blocks, and
     over any panel it crosses. */
  ::-webkit-scrollbar-thumb {
    background: var(--ink-3);
    border: 3px solid transparent;
    background-clip: content-box;
    border-radius: 999px;
  }
  ::-webkit-scrollbar-thumb:hover { background: var(--ink-2); }
  /* Plan prose is dense with file paths; a default underline cuts straight
     through every descender in them. */
  a { text-underline-offset: .18em; text-decoration-thickness: .07em; }

  /* ── Focus styles ───────────────────────────────────────────────── */
  :focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

  /* ── Touch targets ──────────────────────────────────────────────
     The sidebar links and the theme toggle already commit to 44px; the rest
     of the controls never got the same pass and measured 20-32px tall on a
     phone. Finishing the decision rather than making a new one.

     Buttons keep their drawn size — an invisible ::after centred on each one
     stretches only the hit area, so the masthead does not grow a chunky
     44px-tall back link. The step rail is a list, where taller rows are the
     better touch design anyway, so that one takes the height for real.

     Acceptance criteria are already fine: each 16px checkbox is paired with
     a <label for> that measures 329x111, so the whole criterion is the
     target. Nothing to add there. ── */
  @media (pointer: coarse) {
    .save-pdf-btn,
    .plan-back-link,
    .prototype-link,
    .issue-link,
    .design-link,
    .copy-prompt-btn,
    .copy-cmd-btn,
    .copy-src-btn,
    .copy-workflow-btn,
    .copy-goal-btn { position: relative; }
    .save-pdf-btn::after,
    .plan-back-link::after,
    .prototype-link::after,
    .issue-link::after,
    .design-link::after,
    .copy-prompt-btn::after,
    .copy-cmd-btn::after,
    .copy-src-btn::after,
    .copy-workflow-btn::after,
    .copy-goal-btn::after {
      content: "";
      position: absolute;
      left: 0; right: 0; top: 50%;
      height: 44px;
      transform: translateY(-50%);
    }
    a.rail-step { min-height: 44px; }
    /* Square control, so this one needs the width too — the overlay above
       only stretches height and inherits the button's own edges. */
    .theme-toggle { position: relative; }
    .theme-toggle::after {
      content: "";
      position: absolute;
      left: 50%; top: 50%;
      width: 44px; height: 44px;
      transform: translate(-50%, -50%);
    }
  }

  /* ── Print styles ───────────────────────────────────────────────── */
  @media print {
    .plan-nav, .scroll-rail, .progress-wrap, .save-pdf-btn, .theme-toggle { display: none !important; }
    .layout { display: block !important; }
    .step-card, .section-card { box-shadow: none !important; break-inside: avoid; }
    .step-chip { display: none !important; }
    a[href]::after { content: " (" attr(href) ")"; font-size: .8em; }
  }

  /* ═════════════════════════════════════════════════════════════════
     OPT-IN VISUAL COMPONENTS
     Pure-CSS / token-driven — no CDN, no external script. These rules
     are always present (harmless when unused); the matching <body>
     section blocks are kept only when a plan needs them and deleted
     otherwise. See SKILL.md → "Visual Components".
     ═════════════════════════════════════════════════════════════════ */

  /* ── Files file-tree ────────────────────────────────────────────── */
  .file-tree { font-family: var(--mono); font-size: .85rem; }
  .file-tree-root { font-weight: 700; color: var(--ink); margin-bottom: .5rem; display: flex; align-items: center; gap: .35rem; }
  .file-list, .file-list ul { list-style: none; padding-left: 1.25rem; margin: 0; border-left: 1px dashed var(--rule); }
  .file-list li { padding: .2rem 0; display: flex; align-items: center; gap: .5rem; flex-wrap: wrap; color: var(--ink-2); }
  .file-list li.file-dir { color: var(--ink); font-weight: 600; }
  /* The nested list is a CHILD of the bold directory row, so without this it
     inherits the 600 and every file under a subdirectory renders bold. */
  .file-list li.file-dir > ul { flex-basis: 100%; font-weight: 400; color: var(--ink-2); }
  .file-badge { font-size: .6rem; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; padding: .1em .45em; border-radius: 999px; }
  .file-badge-new       { background: var(--moss-soft); color: var(--moss); border: 1px solid var(--moss-line); }
  .file-badge-modified  { background: var(--signal-soft); color: var(--signal); border: 1px solid var(--signal-line); }
  .file-badge-deleted   { background: var(--red-bg);   color: var(--red);   border: 1px solid var(--red-border); }
  .file-badge-generated { background: var(--accent-soft); color: var(--accent); border: 1px solid var(--accent-line); }
  .file-note { font-size: .75rem; font-weight: 400; color: var(--ink-3); font-style: italic; font-family: var(--ui); }

  /* ── Flow / pipeline diagram ────────────────────────────────────── */
  .pipeline { display: flex; flex-direction: column; align-items: center; gap: 0; margin: 0 auto; max-width: 580px; }
  .pipeline-node { width: 100%; border: 1px solid var(--rule); border-radius: var(--radius); padding: .7rem 1.25rem; background: var(--panel); text-align: center; box-shadow: var(--shadow); }
  .pipeline-label { font-size: .62rem; font-weight: 700; letter-spacing: .1em; text-transform: uppercase; margin-bottom: .2rem; color: var(--accent); }
  .pipeline-node code { font-size: .82rem; font-weight: 600; display: block; color: var(--ink); }
  .pipeline-sub { font-size: .74rem; color: var(--ink-2); margin-top: .2rem; }
  .pipeline-arrow { font-size: .85rem; color: var(--ink-3); padding: .25rem 0; }

  /* ── Comparison grid (2–3 way) ──────────────────────────────────── */
  .compare-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-top: 1rem; }
  @media (max-width: 600px) { .compare-grid { grid-template-columns: 1fr; } }
  .compare-header { font-size: .66rem; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; padding: .35rem .75rem; border-radius: var(--radius) var(--radius) 0 0; text-align: center; }
  .compare-col-add     .compare-header { background: var(--moss-soft);  color: var(--moss);  border: 1px solid var(--moss-line); }
  .compare-col-neutral .compare-header { background: var(--accent-soft); color: var(--accent); border: 1px solid var(--accent-line); }
  .compare-col-remove  .compare-header { background: var(--red-bg);    color: var(--red);    border: 1px solid var(--red-border); }
  .compare-list { list-style: none; padding: .5rem .75rem; margin: 0; border: 1px solid var(--rule); border-top: none; border-radius: 0 0 var(--radius) var(--radius); background: var(--panel); }
  .compare-list li { font-family: var(--mono); font-size: .78rem; color: var(--ink-2); padding: .15rem 0; }

  /* ── Bar chart (value via inline --val) ─────────────────────────── */
  .bar-chart { display: flex; flex-direction: column; gap: .55rem; }
  .bar-row { display: grid; grid-template-columns: 9.5rem 1fr 3rem; align-items: center; gap: .75rem; }
  @media (max-width: 520px) { .bar-row { grid-template-columns: 1fr; gap: .15rem; } }
  .bar-label { font-size: .82rem; color: var(--ink); }
  .bar-track { background: var(--rule); border-radius: 999px; height: .7rem; overflow: hidden; }
  .bar-fill { height: 100%; width: var(--val, 0%); background: var(--accent); border-radius: 999px; }
  .bar-fill.full { background: var(--moss); }
  .bar-fill.zero { background: var(--ink-3); }
  .bar-value { font-size: .78rem; font-weight: 600; color: var(--ink-2); white-space: nowrap; text-align: right; }

  /* ── Data table ─────────────────────────────────────────────────── */
  .plan-table { width: 100%; border-collapse: collapse; font-size: .85rem; margin-top: .5rem; }
  .plan-table caption { text-align: left; font-size: .78rem; color: var(--ink-3); font-style: italic; margin-bottom: .5rem; }
  .plan-table th, .plan-table td { text-align: left; padding: .5rem .75rem; border: 1px solid var(--rule); vertical-align: top; }
  .plan-table thead th { background: var(--sunk); font-weight: 700; color: var(--ink-2); text-transform: uppercase; font-size: .66rem; letter-spacing: .05em; }
  .plan-table tbody tr:nth-child(even) { background: var(--sunk); }
  .plan-table code { font-size: .8em; }

  /* Shared sub-heading used inside visual sections */
  .diagram-subheading { font-size: .78rem; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; color: var(--ink-2); margin: 1.75rem 0 .75rem; }

  /* ── Resources (images, screenshots & reference links) ──────────── */
  .resource-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 1rem; margin-bottom: 1rem; }
  .resource-figure { margin: 0; border: 1px solid var(--rule); border-radius: var(--radius); overflow: hidden; background: var(--panel); box-shadow: var(--shadow); }
  .resource-figure > a { display: block; line-height: 0; }
  .resource-figure img { display: block; width: 100%; height: auto; background: var(--sunk); }
  .resource-figure figcaption { font-size: .74rem; line-height: 1.5; color: var(--ink-2); padding: .5rem .75rem; border-top: 1px solid var(--rule); }
  .resource-links { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: .1rem; }
  .resource-links li { display: flex; flex-wrap: wrap; align-items: baseline; gap: .5rem; padding: .4rem 0; border-bottom: 1px solid var(--rule); }
  .resource-links li:last-child { border-bottom: none; }
  .resource-links a { font-weight: 600; word-break: break-word; }
  .resource-note { font-size: .78rem; color: var(--ink-3); font-style: italic; }

  /* Was .5rem under a mono "IMPLEMENTATION PLAN" eyebrow that named the one
     thing every document in this directory already is — the back-link says
     Plans, the title says what this one does, and the meta row carries the
     type. With the eyebrow gone the title needs that space back. */
  .plan-back-nav { margin-bottom: 1.1rem; }
  .plan-back-link {
    display: inline-flex;
    align-items: center;
    gap: .3125rem;
    font-size: .8125rem;
    color: var(--ink-2);
    text-decoration: none;
    transition: color .15s;
  }
  .plan-back-link:hover { color: var(--accent); }
  .plan-back-link svg { width: 14px; height: 14px; flex-shrink: 0; }`;

export const RESPONSIVE_CSS = `/* plan-responsive-fix v1 — injected by scripts/retrofit-responsive-plans.mjs */
body { overflow-wrap: anywhere; }
main, nav, aside { min-width: 0; }
.layout > *, .wrap > *, .compare-grid > * { min-width: 0; }
pre { white-space: pre-wrap; max-width: 100%; }
table { max-width: 100%; }
img, video { max-width: 100%; height: auto; }
@media (max-width: 600px) { .compare-grid { grid-template-columns: 1fr; } }`;

export const ICON_SPRITE = `<svg xmlns="http://www.w3.org/2000/svg" style="display:none" aria-hidden="true">
  <symbol id="ic-bolt" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z"/>
  </symbol>
  <symbol id="ic-chart-bar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z"/>
  </symbol>
  <symbol id="ic-document-text" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
  </symbol>
  <symbol id="ic-folder" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z"/>
  </symbol>
  <symbol id="ic-list-bullet" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"/>
  </symbol>
  <symbol id="ic-check-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
  </symbol>
  <symbol id="ic-magnifying-glass" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"/>
  </symbol>
  <symbol id="ic-arrow-right-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="m12.75 15 3-3m0 0-3-3m3 3h-7.5M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
  </symbol>
  <symbol id="ic-calendar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5"/>
  </symbol>
  <symbol id="ic-code-bracket" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M17.25 6.75 22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3-4.5 16.5"/>
  </symbol>
  <symbol id="ic-tag" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z"/>
    <path d="M6 6h.008v.008H6V6Z"/>
  </symbol>
  <symbol id="ic-sparkles" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456ZM16.894 20.567 16.5 21.75l-.394-1.183a2.25 2.25 0 0 0-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 0 0 1.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 0 0 1.423 1.423l1.183.394-1.183.394a2.25 2.25 0 0 0-1.423 1.423Z"/>
  </symbol>
  <symbol id="ic-question-mark-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 5.25h.008v.008H12v-.008Z"/>
  </symbol>
  <symbol id="ic-clipboard-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M11.35 3.836c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 0 0 .75-.75 2.25 2.25 0 0 0-.1-.664m-5.8 0A2.251 2.251 0 0 1 13.5 2.25H15a2.25 2.25 0 0 1 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m8.9-4.414c.376.023.75.05 1.124.08 1.131.094 1.976 1.057 1.976 2.192V16.5A2.25 2.25 0 0 1 18 18.75h-2.25m-7.5-10.5H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V18.75m-7.5-10.5h6.375c.621 0 1.125.504 1.125 1.125v9.375m-8.25-3 1.5 1.5 3-3.75"/>
  </symbol>
  <symbol id="ic-beaker" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9.75 3.104v5.714a2.25 2.25 0 0 1-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 0 1 4.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0 1 12 15a9.065 9.065 0 0 0-6.23-.693L5 14.5m14.8.8 1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0 1 12 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5"/>
  </symbol>
  <symbol id="ic-photo" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"/>
  </symbol>
  <symbol id="ic-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z"/>
  </symbol>
  <symbol id="ic-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M21.752 15.002A9.718 9.718 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z"/>
  </symbol>
</svg>`;

export const SCRIPT = `/* ── Theme toggle ───────────────────────────────────────────── */
/* The <head> script has already applied any stored choice. This only has to
   resolve what is currently on screen, flip it, and remember the answer. */
function resolvedTheme() {
  var set = document.documentElement.getAttribute('data-theme');
  if (set === 'dark' || set === 'light') return set;
  return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
    ? 'dark' : 'light';
}

function syncThemeButton(btn) {
  if (!btn) return;
  var dark = resolvedTheme() === 'dark';
  btn.setAttribute('aria-pressed', dark ? 'true' : 'false');
  btn.setAttribute('aria-label', dark ? 'Use light theme' : 'Use dark theme');
  /* The icon names the destination, not the current state — a sun while dark
     means "go light", which is what aria-label has always said. Swap the
     symbol reference; never innerHTML, so nothing here can inject markup. */
  var use = btn.querySelector('use');
  if (use) use.setAttribute('href', dark ? '#ic-sun' : '#ic-moon');
}

function toggleTheme(btn) {
  var next = resolvedTheme() === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', next);
  try { localStorage.setItem('plan-theme', next); } catch (e) { /* not persisted */ }
  syncThemeButton(btn || document.getElementById('theme-toggle'));
}

/* ── Save as PDF (native browser print dialog) ──────────────── */
function savePDF() {
  window.print();
}

/* ── Build rich implementation prompt from DOM ──────────────── */
function buildImplementPrompt() {
  var cmdEl = document.getElementById('implement-cmd');
  var status = document.documentElement.getAttribute('data-status') || 'todo';
  var stepCards = Array.prototype.slice.call(document.querySelectorAll('.step-card'));
  var criteriaItems = Array.prototype.slice.call(document.querySelectorAll('#criteria-list li'));

  var totalSteps = stepCards.length;
  var doneSteps = stepCards.filter(function(c) { return c.classList.contains('completed'); }).length;
  var totalCriteria = criteriaItems.length;
  var checkedCriteria = criteriaItems.filter(function(li) {
    var cb = li.querySelector('input[type="checkbox"]');
    return cb && cb.checked;
  }).length;

  var planPathMeta = document.querySelector('meta[name="plan-path"]');
  var planPath = (planPathMeta && planPathMeta.getAttribute('content')) || '<plan-file>';
  var mdMeta = document.querySelector('meta[name="plan-md"]');
  var specPath = (mdMeta && mdMeta.getAttribute('content')) || planPath.replace(/\\.html$/, '.md');

  var lines = [];
  lines.push(cmdEl ? cmdEl.textContent.trim() : 'Implement the plan');
  lines.push('');
  lines.push('Status: ' + status + ' (' + doneSteps + '/' + totalSteps + ' steps done, ' + checkedCriteria + '/' + totalCriteria + ' criteria met)');
  lines.push('');
  lines.push('Instructions:');
  lines.push('1. Read the plan spec at ' + specPath + ' (Markdown — the source of truth; the sibling HTML at ' + planPath + ' is a rendered view of it).');
  lines.push('2. Implement every step still marked todo; after completing each step, mark it done by adding its [x] marker in the spec (e.g. "3. [x] ...").');
  lines.push('3. When all steps are done, verify each acceptance criterion and flip its bullet to "- [x]" in the spec.');
  lines.push('4. Run the objective test\\'s Run command from the plan\\'s Tests section, then walk the Verification section end-to-end and confirm the stated objective actually works — on failure, fix and re-verify before continuing; never mark the plan done on a failing check.');
  lines.push('5. Set "status: completed" in the spec frontmatter only once every step is marked, every criterion is checked, and verification passes.');
  lines.push('6. Re-render the sibling HTML from the spec so it shows every step and criterion complete (the plan-agent render hook does this on save; otherwise run the bundled build-plan-html.mjs renderer) — never edit the HTML by hand.');

  return lines.join('\\n');
}

/* ── Shared clipboard helper ────────────────────────────────── */
/* All copy buttons delegate here. \`restoreLabel\` is the button's   */
/* idle text. On failure (Clipboard API rejects AND execCommand     */
/* fails) the button shows a visible error so the user knows to      */
/* select manually — never a silent no-op.                          */
function clipboardCopy(text, btn, restoreLabel) {
  function show(labelText, cls, delay) {
    if (btn._copyTimer) clearTimeout(btn._copyTimer);
    btn.textContent = labelText;
    btn.classList.remove('copied', 'copy-failed');
    if (cls) btn.classList.add(cls);
    btn._copyTimer = setTimeout(function () {
      btn.textContent = restoreLabel;
      btn.classList.remove('copied', 'copy-failed');
      btn._copyTimer = null;
    }, delay);
  }
  function flash() { show('Copied ✓', 'copied', 2000); }
  function fail()  { show('Copy failed — select manually', 'copy-failed', 4000); }
  function fallback() {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.cssText = 'position:fixed;left:-9999px;top:-9999px;opacity:0';
    document.body.appendChild(ta);
    ta.select();
    var ok = false;
    try { ok = document.execCommand('copy'); } catch (e) {}
    document.body.removeChild(ta);
    if (ok) flash(); else fail();
  }
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text).then(flash).catch(fallback);
  } else {
    fallback();
  }
}

/* ── Copy implement prompt ──────────────────────────────────── */
function copyCmd(btn) {
  clipboardCopy(buildImplementPrompt(), btn, 'Copy');
}

/* ── Copy workflow prompt (element absent when plan has no workflow) ── */
function copyWorkflow(btn) {
  var code = document.getElementById('workflow-cmd');
  if (!code) return;
  clipboardCopy(code.textContent, btn, 'Copy');
}

/* ── Copy goal prompt ──────────────────────────────────────── */
function copyGoal(btn) {
  var code = document.getElementById('goal-cmd');
  if (!code) return;
  clipboardCopy(code.textContent, btn, 'Copy');
}

/* ── Copy plan file name / relative path ────────────────────── */
function copyPath(btn, id) {
  var el = document.getElementById(id);
  if (!el) return;
  clipboardCopy(el.textContent.trim(), btn, 'Copy');
}

/* ── Copy prompt button (global — required by inline onclick) ── */
function copyPrompt(btn) {
  var pre = btn.previousElementSibling;
  if (!pre || pre.tagName !== 'PRE') {
    pre = btn.parentElement && btn.parentElement.querySelector('pre');
  }
  if (!pre) return;
  clipboardCopy(pre.textContent, btn, 'Copy prompt');
}

(function () {
  'use strict';

  /* ── Progress bar — state from HTML attributes ──────────────── */
  /* State lives in the HTML itself: a criterion is done iff its       */
  /* <input> carries the \`checked\` attribute, which the browser        */
  /* renders natively on load. Toggling a box syncs the attribute so   */
  /* the live DOM (and any saved copy of this file) stays the single   */
  /* portable source of truth — no browser-only storage layer.         */
  var bar        = document.getElementById('progress-bar');
  var label      = document.getElementById('progress-label');
  var liveRegion = document.getElementById('criteria-status');
  var checkboxes = Array.prototype.slice.call(
    document.querySelectorAll('#criteria-list input[type="checkbox"]')
  );
  var total = checkboxes.length;

  function updateProgress() {
    var done = checkboxes.filter(function (cb) { return cb.checked; }).length;
    var pct  = total ? Math.round(done / total * 100) : 0;
    if (bar) {
      bar.style.width = pct + '%';
      bar.setAttribute('aria-valuenow', pct);
      if (pct > 0) bar.classList.add('has-progress');
      else         bar.classList.remove('has-progress');
    }
    if (label) label.textContent = done + ' / ' + total + ' done';
  }

  checkboxes.forEach(function (cb, i) {
    cb.addEventListener('change', function () {
      cb.toggleAttribute('checked', cb.checked);
      updateProgress();
      if (liveRegion) {
        liveRegion.textContent = 'Criterion ' + (i + 1) +
          ' marked as ' + (cb.checked ? 'complete' : 'incomplete');
      }
    });
  });

  updateProgress();

  /* ── Completion checklist auto-update ──────────────────────── */
  var ccCheckboxes = Array.prototype.slice.call(
    document.querySelectorAll('#completion-list input[type="checkbox"]')
  );
  var completionCard = document.getElementById('completion-checklist');

  function updateCompletion() {
    var stepCards = document.querySelectorAll('.step-card');
    var allStepsDone = stepCards.length > 0 &&
      Array.prototype.slice.call(stepCards).every(function(c) {
        return c.classList.contains('completed');
      });
    if (ccCheckboxes[0]) ccCheckboxes[0].checked = allStepsDone;

    var allCriteriaChecked = total > 0 &&
      checkboxes.every(function(cb) { return cb.checked; });
    if (ccCheckboxes[1]) ccCheckboxes[1].checked = allCriteriaChecked;

    var metaStatus = document.querySelector('meta[name="plan-status"]');
    var statusIsCompleted =
      document.documentElement.getAttribute('data-status') === 'completed' &&
      (!metaStatus || metaStatus.getAttribute('content') === 'completed');
    if (ccCheckboxes[2]) ccCheckboxes[2].checked = statusIsCompleted;

    var allComplete = allStepsDone && allCriteriaChecked && statusIsCompleted;
    if (completionCard) {
      if (allComplete) completionCard.classList.add('all-complete');
      else completionCard.classList.remove('all-complete');
    }
  }

  updateCompletion();

  checkboxes.forEach(function(cb) {
    cb.addEventListener('change', updateCompletion);
  });

  if ('MutationObserver' in window) {
    new MutationObserver(updateCompletion).observe(
      document.documentElement, { attributes: true, attributeFilter: ['data-status'] }
    );
  }

  /* ── Scroll rail ─────────────────────────────────────────────── */
  /* One style write per animation frame. The listener used to write on every
     scroll event, which on a trackpad is several per frame and each one read
     scrollHeight — a forced layout on the scroll hot path. */
  var rail = document.querySelector('.scroll-rail');
  if (rail) {
    var raf = window.requestAnimationFrame
      ? window.requestAnimationFrame.bind(window)
      : function (fn) { return setTimeout(fn, 16); };
    var railQueued = false;
    function writeRail() {
      railQueued = false;
      var maxY = document.documentElement.scrollHeight - window.innerHeight;
      var pct  = maxY > 0 ? (window.scrollY / maxY * 100).toFixed(1) : 0;
      rail.style.setProperty('--scroll-pct', pct);
    }
    function updateRail() {
      if (railQueued) return;
      railQueued = true;
      raf(writeRail);
    }
    window.addEventListener('scroll', updateRail, { passive: true });
    writeRail();
  }

  /* ── Step rail disclosure ────────────────────────────────────── */
  /* Ships open so the rail is present with scripting off; below the layout
     breakpoint it collapses, where an always-open list would push the plan
     itself off the first screen. */
  var railBox = document.querySelector('.rail-disclosure');
  if (railBox && window.matchMedia) {
    var narrow = window.matchMedia('(max-width: 900px)');
    var syncRail = function (mq) { railBox.open = !mq.matches; };
    syncRail(narrow);
    if (narrow.addEventListener) narrow.addEventListener('change', syncRail);
    else if (narrow.addListener) narrow.addListener(syncRail);
  }

  /* ── Theme button ────────────────────────────────────────────── */
  syncThemeButton(document.getElementById('theme-toggle'));

  /* ── Scroll spy ──────────────────────────────────────────────── */
  /* Track which targets are on screen rather than reacting only to
     entries that ARE intersecting: with one link per step, a stale
     "you are here" marker left behind after scrolling past the last
     target is worse than no marker at all. */
  var navLinks = Array.prototype.slice.call(
    document.querySelectorAll('.plan-nav a[href^="#"]')
  );
  if (navLinks.length && 'IntersectionObserver' in window) {
    var targets = navLinks
      .map(function (a) { return document.getElementById(a.getAttribute('href').slice(1)); })
      .filter(Boolean);
    var visible = [];
    var setActive = function (id) {
      navLinks.forEach(function (a) {
        var isActive = id !== null && a.getAttribute('href') === '#' + id;
        a.classList.toggle('active', isActive);
        if (isActive) a.setAttribute('aria-current', 'true');
        else          a.removeAttribute('aria-current');
      });
    };
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var at = visible.indexOf(entry.target);
        if (entry.isIntersecting) { if (at === -1) visible.push(entry.target); }
        else if (at !== -1) { visible.splice(at, 1); }
      });
      if (visible.length === 0) { setActive(null); return; }
      /* Document order, not intersection order — the observer fires in
         whatever order the entries arrive. */
      var first = null;
      targets.forEach(function (el) {
        if (first === null && visible.indexOf(el) !== -1) first = el;
      });
      setActive(first ? first.id : null);
    }, { threshold: 0, rootMargin: '-20% 0px -70% 0px' });
    targets.forEach(function (el) { observer.observe(el); });
  }
})();`;

/* ── Section chrome — intros are presentation-only (the extractor
      strips <p class="section-intro">), headings match the skeleton ── */
export const SECTION_CHROME = {
  context: { icon: 'ic-document-text', heading: 'Context', intro: 'The story behind this plan — what prompted the work and why it matters now.' },
  decisions: { icon: 'ic-sparkles', heading: 'Decisions', intro: 'Choices already settled — read these before re-opening any of them.' },
  files: { icon: 'ic-folder', heading: 'Files that change', intro: 'Every file this plan touches, and what happens to each one.' },
  steps: { icon: 'ic-list-bullet', heading: 'Steps', intro: 'The step-by-step work, in order — each step says what to do, why it matters, and how to check it worked.' },
  tests: { icon: 'ic-beaker', heading: 'Tests', intro: 'The tests that prove the change does what it promises.' },
  criteria: { icon: 'ic-check-circle', heading: 'Definition of done', intro: 'The plan counts as done when every statement below is true — check each one off as you verify it.' },
  verification: { icon: 'ic-magnifying-glass', heading: 'Final check', intro: 'One last pass to confirm the whole change works end to end.' },
  completion: { icon: 'ic-clipboard-check', heading: 'Wrapping up', intro: 'Three gates that must all pass before this plan is marked completed.' },
  'next-steps': { icon: 'ic-arrow-right-circle', heading: 'Next steps', intro: 'Follow-up ideas that came up along the way — none of them are required to finish this plan.' },
};

/* Sidebar nav entries in skeleton order; the renderer filters to the
   sections actually present. */
export const NAV_ENTRIES = [
  { id: 'objective', icon: 'ic-bolt', label: 'Objective' },
  { id: 'progress', icon: 'ic-chart-bar', label: 'Progress' },
  { id: 'context', icon: 'ic-document-text', label: 'Context' },
  { id: 'decisions', icon: 'ic-sparkles', label: 'Decisions' },
  { id: 'files', icon: 'ic-folder', label: 'Files that change' },
  { id: 'steps', icon: 'ic-list-bullet', label: 'Steps' },
  { id: 'tests', icon: 'ic-beaker', label: 'Tests' },
  { id: 'criteria', icon: 'ic-check-circle', label: 'Definition of done' },
  { id: 'verification', icon: 'ic-magnifying-glass', label: 'Final check' },
  { id: 'completion', icon: 'ic-clipboard-check', label: 'Wrapping up' },
  { id: 'next-steps', icon: 'ic-arrow-right-circle', label: 'Next steps' },
];

const icon = (id) => `<svg class="icon" aria-hidden="true"><use href="#${id}"/></svg>`;

/* ── Template functions — args are pre-escaped HTML strings ────────── */

/** <head> meta tags. `workflow`/`prototype`/`issue`/`design` may be empty → tag omitted entirely. */
export function metaTags({ status, effort, type, created, repo, file, path, md, implement, goal, workflow, prototype, issue, design }) {
  const tags = [
    `<meta name="plan-status" content="${status}">`,
    `<meta name="plan-effort" content="${effort}">`,
    `<meta name="plan-type" content="${type}">`,
    `<meta name="plan-created" content="${created}">`,
    `<meta name="plan-repo" content="${repo}">`,
    `<meta name="plan-file" content="${file}">`,
    `<meta name="plan-path" content="${path}">`,
    `<meta name="plan-md" content="${md}">`,
    `<meta name="plan-implement" content="${implement}">`,
    `<meta name="plan-goal" content="${goal}">`,
  ];
  if (workflow) tags.push(`<meta name="plan-workflow" content="${workflow}">`);
  if (prototype) tags.push(`<meta name="plan-prototype" content="${prototype}">`);
  if (issue) tags.push(`<meta name="plan-issue" content="${issue}">`);
  if (design) tags.push(`<meta name="plan-design" content="${design}">`);
  return tags.join('\n');
}

/**
 * `prototypeHref` is the already-relative link from this plan's own output
 * directory to its prototype — empty when the spec carries no `prototype:`
 * key, in which case no anchor is emitted at all.
 *
 * The three anchors below share one chip rule (`.prototype-link, .issue-link,
 * .design-link`) and one `order` slot in `.plan-header-actions`, between the
 * badges and the controls. They used to carry no CSS at all so that plans
 * without a prototype kept their bytes; the cost was a link in a flex row of
 * explicitly ordered children — it fell to `order: 0` and rendered as bare
 * underlined text ahead of the status badge.
 *
 * `issueHref` is the tracking ticket's full URL, empty when the spec carries
 * no `issue:` key — same all-or-nothing anchor.
 *
 * `designHref` is the published design canvas's artifact URL, empty when the
 * spec carries no `design:` key. Emitted VERBATIM — unlike `prototypeHref`,
 * which is a repo path the caller relativized against this plan's own output
 * directory, a canvas is not a file in the tree and has nothing to relativize
 * against. Same all-or-nothing anchor.
 */
export function header({ title, status, effortLabel, created, repo, type, prototypeHref, issueHref, issueLabel, designHref }) {
  const prototypeLink = prototypeHref
    ? `\n        <a class="prototype-link" href="${prototypeHref}"
           aria-label="View the interactive prototype for this plan">View prototype</a>`
    : '';
  const issueLink = issueHref
    ? `\n        <a class="issue-link" href="${issueHref}"
           aria-label="View the tracking issue for this plan">${issueLabel || 'Tracking issue'}</a>`
    : '';
  const designLink = designHref
    ? `\n        <a class="design-link" href="${designHref}"
           aria-label="View the design canvas for this plan">View design</a>`
    : '';
  return `<header class="plan-header">
  <div class="plan-header-inner">
    <div class="plan-back-nav">
      <a href="./index.html" class="plan-back-link">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/></svg>
        Plans
      </a>
    </div>
    <div class="plan-header-top">
      <h1 class="plan-title">${title}</h1>
      <div class="plan-header-actions">
        <button class="save-pdf-btn" type="button" onclick="savePDF()"
                aria-label="Save this plan as PDF">Save as PDF</button>
        <button class="theme-toggle" type="button" id="theme-toggle" onclick="toggleTheme(this)"
                aria-pressed="false" aria-label="Use dark theme"><svg class="icon" aria-hidden="true"><use href="#ic-moon"/></svg></button>
        <span class="effort-badge" aria-label="Effort level">${effortLabel}</span>${prototypeLink}${designLink}${issueLink}
        <span class="status-badge">${status}</span>
      </div>
    </div>
    <div class="plan-meta">
      <span>${icon('ic-calendar')} ${created}</span>
      <span>${icon('ic-code-bracket')} ${repo}</span>
      <span>${icon('ic-tag')} ${type}</span>
      <span>${icon('ic-bolt')} ${effortLabel} effort</span>
    </div>
  </div>
</header>`;
}

/**
 * Sidebar nav from NAV_ENTRIES filtered to present ids, plus a rail of one
 * link per step.
 *
 * The section links are emitted with a BARE href and nothing else, and the
 * step links carry a leading `class` plus an id containing a digit — that is
 * what keeps `/<a href="#([a-z-]+)">/` in the renderer tests matching exactly
 * the section list and never a step. Do not add attributes to the section
 * anchors, and do not drop the class from the step anchors.
 *
 * `steps` is [{ action, done }] in document order; an empty list emits no
 * rail at all, so a spec with no steps renders the nav it always did.
 */
export function nav(ids, steps = []) {
  const items = NAV_ENTRIES.filter((e) => ids.includes(e.id))
    .map((e) => `      <li><a href="#${e.id}">${icon(e.icon)} ${e.label}</a></li>`)
    .join('\n');
  const total = steps.length;
  const railItems = steps
    .map((st, i) => {
      const n = i + 1;
      const state = st.done ? `step ${n} of ${total}, done` : `step ${n} of ${total}`;
      return `        <li><a class="rail-step${st.done ? ' done' : ''}" href="#step-${n}"><span class="rail-no">${st.done ? '✓' : n}</span><span class="rail-text">${st.action}</span><span class="rail-state">${state}</span></a></li>`;
    })
    .join('\n');
  const rail = total === 0
    ? ''
    : `
    <details class="rail-disclosure" open>
      <summary>${total} steps</summary>
      <div class="rail-heading">Steps</div>
      <ul class="rail-steps">
${railItems}
      </ul>
    </details>`;
  return `  <nav class="plan-nav" aria-label="Plan sections">
    <div class="scroll-rail" aria-hidden="true"></div>
    <div class="nav-heading">On this page</div>
    <ul>
${items}
    </ul>${rail}
  </nav>`;
}

/**
 * The single goal panel. `glanceHtml` is the output of glanceBlock() and is
 * nested INSIDE `#objective` — the two are the same goal in two registers, and
 * rendering them as siblings left a reader unable to tell which was
 * authoritative. Safe for the extractor: extractSections() strips a nested
 * `.plan-glance` out of the objective before reading it.
 */
export function objectiveCard(objective, glanceHtml = '') {
  const glance = glanceHtml ? `\n${glanceHtml}` : '';
  return `    <div class="objective-card" id="objective">
      <div class="section-label">Objective</div>
      <p>${objective}</p>${glance}
    </div>`;
}

/** At-a-glance block — nested inside #objective by objectiveCard(). */
export function glanceBlock(glance) {
  return `      <section class="plan-glance" aria-labelledby="plan-glance-label">
        <div class="plan-glance-label" id="plan-glance-label">At a glance</div>
        <p>${glance}</p>
      </section>`;
}

export function implementRow(implement) {
  return `    <div class="plan-implement">
      <span class="plan-implement-label">Implement</span>
      <code id="implement-cmd" aria-label="Implement prompt">${implement}</code>
      <button class="copy-cmd-btn" type="button"
              onclick="copyCmd(this)" aria-label="Copy implement prompt to clipboard">Copy</button>
    </div>`;
}

/**
 * More-ways drawer. `workflow` empty → row omitted, drawer kept.
 * A non-empty `workflow` is also the gate for the goal prompt's fan-out
 * phrasing, so the label tracks it rather than taking its own parameter.
 */
export function moreWaysDrawer({ goal, workflow, file, path, md }) {
  const workflowRow = workflow
    ? `
        <div class="plan-workflow">
          <div class="plan-workflow-label">Run as workflow — launch parallel subagents</div>
          <div class="plan-workflow-inner">
            <code id="workflow-cmd" aria-label="Workflow prompt">${workflow}</code>
            <button class="copy-workflow-btn" type="button"
                    onclick="copyWorkflow(this)" aria-label="Copy workflow prompt to clipboard">Copy</button>
          </div>
        </div>
`
    : '';
  return `    <details class="plan-more-ways">
      <summary>More ways to run this plan <span class="more-ways-hint">— goal &amp; workflow prompts, file path</span></summary>
      <div class="plan-more-ways-body">

        <div class="plan-goal">
          <div class="plan-goal-label">${workflow ? GOAL_LABEL_PARALLEL : GOAL_LABEL}</div>
          <div class="plan-goal-inner">
            <code id="goal-cmd" aria-label="Goal prompt">${goal}</code>
            <button class="copy-goal-btn" type="button"
                    onclick="copyGoal(this)" aria-label="Copy goal prompt to clipboard">Copy</button>
          </div>
        </div>
${workflowRow}
        <div class="plan-source">
          <div class="plan-source-row">
            <span class="plan-source-label">File</span>
            <code id="plan-file" aria-label="Plan file name">${file}</code>
            <button class="copy-src-btn" type="button"
                    onclick="copyPath(this, 'plan-file')" aria-label="Copy plan file name to clipboard">Copy</button>
          </div>
          <div class="plan-source-row">
            <span class="plan-source-label">Path</span>
            <code id="plan-path" aria-label="Plan relative path">${path}</code>
            <button class="copy-src-btn" type="button"
                    onclick="copyPath(this, 'plan-path')" aria-label="Copy plan relative path to clipboard">Copy</button>
          </div>
          <div class="plan-source-row">
            <span class="plan-source-label">Spec</span>
            <code id="plan-md" aria-label="Plan spec markdown path">${md}</code>
            <button class="copy-src-btn" type="button"
                    onclick="copyPath(this, 'plan-md')" aria-label="Copy plan spec path to clipboard">Copy</button>
          </div>
        </div>

      </div>
    </details>`;
}

/** Progress bar with its server-rendered initial state; the inline script
 * recomputes it from the live checkboxes on load and on every toggle. */
export function progressBlock(doneCount, criteriaCount) {
  const pct = criteriaCount ? Math.round((doneCount / criteriaCount) * 100) : 0;
  return `    <div class="progress-wrap" id="progress">
      <div class="progress-header">
        <span>Definition of done</span>
        <span id="progress-label">${doneCount} / ${criteriaCount} done</span>
      </div>
      <div class="progress-bar-bg">
        <div class="progress-bar-fill${pct > 0 ? ' has-progress' : ''}" id="progress-bar"
             role="progressbar" aria-valuenow="${pct}" aria-valuemin="0" aria-valuemax="100"
             aria-label="Plan progress" style="width:${pct}%"></div>
      </div>
    </div>`;
}

/** Generic section wrapper matching the skeleton's .section-card shape. */
export function sectionCard(id, body) {
  const { icon: ic, heading, intro } = SECTION_CHROME[id];
  return `    <section class="section-card card-${id}" id="${id}" aria-labelledby="h-${id}">
      <h2 id="h-${id}">
        ${icon(ic)}
        ${heading}
      </h2>
      <p class="section-intro">${intro}</p>
${body}
    </section>`;
}

/** items: [{ summary, desc, prompt }] — pre-escaped HTML strings; `prompt`
 * may be empty. Mirrors the legacy hand-written Next Steps markup: one
 * collapsible details per follow-up, prompt in a <pre> with a copyPrompt()
 * button. */
export function nextStepsBlock(items) {
  const rows = items
    .map((it) => {
      const desc = it.desc ? `\n            <p>${it.desc}</p>` : '';
      if (!it.prompt) {
        return `        <details class="next-step-item">
          <summary>${it.summary}</summary>
          <div class="next-step-prompt">${desc || `\n            <p>${it.summary}</p>`}
          </div>
        </details>`;
      }
      return `        <details class="next-step-item">
          <summary>${it.summary}</summary>
          <div class="next-step-prompt">${desc}
            <p>Paste this prompt into Claude to execute this follow-up:</p>
            <pre>${it.prompt}</pre>
            <button class="copy-prompt-btn" type="button"
                    onclick="copyPrompt(this)" aria-label="Copy prompt to clipboard">Copy prompt</button>
          </div>
        </details>`;
    })
    .join('\n\n');
  return `      <div class="next-steps-list">
${rows}
      </div>`;
}

export function fileTreeBlock(repo, rows) {
  return `      <div class="file-tree">
        <div class="file-tree-root">${icon('ic-folder')} ${repo}/</div>
        <ul class="file-list">
${rows}
        </ul>
      </div>`;
}

/**
 * One step record. `class="step-card"` stays the FIRST attribute and keeps
 * `completed` as a literal second word — extractSections() matches
 * `class="step-card[" ]` — and `id="step-N"` is the target the sidebar rail
 * links to. The verify text is plain visible content inside
 * `<div class="verify-body">`, no longer wrapped in a <details>.
 */
export function stepCard(n, { action, why, verify, done = false }) {
  return `        <div class="step-card${done ? ' completed' : ''}" id="step-${n}">
          <div class="step-card-header">
            <div class="step-number">${n}</div>
            <div class="step-body">
              <div class="step-action">
                ${done ? STEP_CHIP_DONE : STEP_CHIP}
                <span class="step-chip-text">${action}</span>
              </div>
              <div class="step-note step-why-note">
                <span class="step-note-label">Why</span>
                <div class="step-why">${why}</div>
              </div>
              <div class="step-note step-verify">
                <span class="step-note-label">Verify</span>
                <div class="verify-body">${verify}</div>
              </div>
            </div>
          </div>
        </div>`;
}

/**
 * A run of step cards under one `### Phase:` heading. `name` is the raw phase
 * name attribute-escaped, `heading` the same name through inline(); extraction
 * reads the attribute, so the two may legitimately differ.
 *
 * ponytail: the h3 and the wrapper carry inline styles instead of classes in
 * the shared CSS block. That block is emitted verbatim into EVERY rendered
 * plan, so one new rule rewrites the bytes of ~100 committed plans that have
 * no phases at all. Move these into CSS as `.phase-group`/`.phase-name` the
 * next time a change is already rewriting every plan.
 */
const PHASE_NAME_STYLE = 'font-size:.75rem;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--ink-2);margin:0 0 .75rem;';

export function phaseGroup({ name, heading, body }) {
  return `        <div class="phase-group" data-phase="${name}" style="margin-top:1.5rem;">
          <h3 class="phase-name" style="${PHASE_NAME_STYLE}">${heading}</h3>
${body}
        </div>`;
}

/** One `- ` bullet per settled decision. Same inline-style rule as
 * phaseGroup(): local styling keeps phase-free plans byte-stable. */
export function decisionsListBlock(items) {
  const lis = items.map((text) => `        <li style="margin-bottom:.5rem;">${text}</li>`).join('\n');
  return `      <ul class="decisions-list" style="padding-left:1.15rem;">
${lis}
      </ul>`;
}

/** items: [{ text, done }] — done renders the `checked` attribute, the
 * file-persisted completion state the spec's `- [x]` bullets carry. */
export function criteriaListBlock(items) {
  const lis = items
    .map(
      ({ text, done }, i) => `        <li>
          <input type="checkbox" id="ac${i + 1}"${done ? ' checked' : ''}>
          <label for="ac${i + 1}">${text}</label>
        </li>`
    )
    .join('\n');
  return `      <ul class="criteria-list" id="criteria-list">
${lis}
      </ul>
      <span id="criteria-status" aria-live="polite" aria-atomic="true"
            style="position:absolute;left:-9999px;width:1px;height:1px;overflow:hidden;"></span>`;
}

/**
 * Completion checklist with its state derived from the spec (all steps done,
 * all criteria checked, status completed) — the same conditions the inline
 * script recomputes from the live DOM on load. `reportHtml` replaces the
 * default "No items to report" paragraph when the spec carries a
 * `## Completion Report` section.
 */
export function completionBlock({ allStepsDone = false, allCriteriaDone = false, statusCompleted = false, reportHtml = '' } = {}) {
  const allComplete = allStepsDone && allCriteriaDone && statusCompleted;
  const box = (id, on, label) => `          <li>
            <input type="checkbox" id="${id}" disabled${on ? ' checked' : ''}>
            <label for="${id}">${label}</label>
          </li>`;
  return `      <div class="completion-checklist${allComplete ? ' all-complete' : ''}" id="completion-checklist">
        <div class="completion-header">
          <span class="completion-badge" id="completion-badge">Required</span>
        </div>
        <ul class="completion-list" id="completion-list">
${box('cc1', allStepsDone, 'All step TODOs marked as done')}
${box('cc2', allCriteriaDone, 'All acceptance criteria verified and checked off')}
${box('cc3', statusCompleted, 'Plan status updated to completed')}
        </ul>
        <div class="completion-report" id="completion-report">
          <h3 class="report-heading">Completion Report</h3>
${reportHtml || `          <p class="report-empty">${NO_ITEMS_REPORT}</p>`}
        </div>
      </div>`;
}

export function footer({ created, repo }) {
  return `    <footer class="plan-footer">
      ${icon('ic-sparkles')}
      Generated by plan-agent · ${created} · ${repo}
    </footer>`;
}

/** Assemble the full self-contained document. */
export function page({ status, effort, title, meta, headerHtml, navHtml, mainHtml }) {
  return `<!DOCTYPE html>
<html lang="en" data-status="${status}" data-effort="${effort}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script>
/* Runs in <head> before the first paint, on purpose: a plan opened from
   file:// has no server to stamp the attribute, and a flash of the wrong
   theme on every load is worse than having no dark mode at all. Storage
   throws in some sandboxed file:// contexts — fall through to
   prefers-color-scheme rather than blocking the render. */
try {
  var t = localStorage.getItem('plan-theme');
  if (t === 'dark' || t === 'light') document.documentElement.dataset.theme = t;
} catch (e) { /* no storage — prefers-color-scheme decides */ }
</script>
${meta}
<title>Plan: ${title}</title>
<style>
${CSS}
</style>
<style id="plan-responsive-fix" data-version="1">
${RESPONSIVE_CSS}
</style>
</head>
<body>

${ICON_SPRITE}

<a href="#main" class="skip-link">Skip to content</a>

${headerHtml}

<div class="layout">

${navHtml}

  <main id="main">

${mainHtml}

  </main>
</div><!-- /.layout -->

<script>
${SCRIPT}
</script>
</body>
</html>
`;
}
