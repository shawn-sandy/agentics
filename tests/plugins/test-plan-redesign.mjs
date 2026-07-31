#!/usr/bin/env node
/**
 * Objective test for the plan-document and gallery redesign.
 *
 * Objective: a rendered plan carries the new design — a dark palette reachable
 * from a toggle, text that clears WCAG AA contrast in BOTH palettes, one goal
 * panel instead of two stacked summaries, a visible Verify line, and a sidebar
 * step rail — without breaking the DOM contract the extractor and the gallery
 * read.
 *
 * Every assertion here fails if the behaviour regresses. The contrast checks in
 * particular are the reason this file exists: the shell it replaced shipped
 * `--subtle: #9ca3af` on white at 2.5:1 for years because no test ever measured
 * a colour, and a screenshot cannot show a ratio.
 *
 * Run: node tests/plugins/test-plan-redesign.mjs
 */

import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { extractSections, parseSpecMarkdown } from '../../scripts/lib/plan-spec.mjs';
import { renderPlanHtml } from '../../scripts/build-plan-html.mjs';
import { CSS } from '../../scripts/lib/plan-shell.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));

let passed = 0;
function ok(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  PASS ${name}`);
  } catch (err) {
    console.error(`  FAIL ${name}`);
    console.error(`       ${err.message}`);
    process.exitCode = 1;
  }
}

/* ── Fixture: two done steps, one open, plus a glance ──────────────── */
const SPEC = `---
status: in-progress
type: refactor
created: 2026-07-31
glance: Rebuild the shell so a plan is readable in either theme.
---

# Plan: Redesign fixture

## Objective
Prove the redesigned shell renders and still extracts.

## Context
The shell drifted into a generic default and failed contrast.

## Steps

1. [x] Replace the token block. Why: the palette is the whole refresh. Verify: render a plan and read the computed colours.
2. [x] Add the theme toggle. Why: the dark palette is unreachable without it. Verify: toggle and reload.
3. Add the step rail. Why: the sidebar collapsed twelve steps into one entry. Verify: every rail link resolves.

## Acceptance Criteria

- [x] Tokens replaced
- [ ] Rail present

## Verification
Render a committed plan and measure the computed colours in both themes.
`;

const parsed = parseSpecMarkdown(SPEC);
const html = renderPlanHtml(parsed, { fileName: 'fixture.html', planPath: 'docs/plans/fixture.html' });

/* ── Contrast maths (WCAG 2.x relative luminance) ──────────────────── */
function channel(v) {
  const c = v / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}
function luminance(hex) {
  const h = hex.replace('#', '');
  const full = h.length === 3 ? h.split('').map((c) => c + c).join('') : h;
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(full.slice(i, i + 2), 16));
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}
function contrast(fg, bg) {
  const [a, b] = [luminance(fg), luminance(bg)].sort((x, y) => y - x);
  return (a + 0.05) / (b + 0.05);
}

/** Token name → hex, read from one `{ … }` declaration block of the stylesheet. */
function tokensIn(block) {
  const out = {};
  for (const m of block.matchAll(/(--[a-z0-9-]+)\s*:\s*(#[0-9a-fA-F]{3,6})\s*;/g)) {
    out[m[1]] = m[2];
  }
  return out;
}
function blockAfter(css, selector) {
  const at = css.indexOf(selector);
  assert.notEqual(at, -1, `stylesheet has no ${selector} block`);
  const open = css.indexOf('{', at);
  const close = css.indexOf('}', open);
  return css.slice(open + 1, close);
}

const LIGHT = tokensIn(blockAfter(CSS, '\n  :root {'));
const DARK = tokensIn(blockAfter(CSS, ':root[data-theme="dark"] {'));
const DARK_MEDIA = tokensIn(blockAfter(CSS, ':root:not([data-theme="light"]) {'));

/* Every text token, against every surface it is actually rendered on. */
const PAIRS = [
  ['--ink', '--paper'], ['--ink', '--panel'], ['--ink', '--sunk'],
  ['--ink-2', '--paper'], ['--ink-2', '--panel'], ['--ink-2', '--sunk'],
  ['--ink-3', '--paper'], ['--ink-3', '--panel'], ['--ink-3', '--sunk'],
  ['--accent', '--paper'], ['--accent', '--panel'], ['--accent', '--accent-soft'],
  ['--moss', '--paper'], ['--moss', '--panel'], ['--moss', '--moss-soft'],
  ['--signal', '--paper'], ['--signal', '--panel'], ['--signal', '--signal-soft'],
  ['--red', '--paper'], ['--red', '--panel'], ['--red', '--red-bg'],
  ['--purple', '--paper'], ['--purple', '--panel'], ['--purple', '--purple-bg'],
  ['--purple', '--wish-bg'],
  ['--on-accent', '--accent'],
];

/* ── Objective: the design is present and readable ─────────────────── */

ok('both palettes define every token, and each palette clears 4.5:1', () => {
  assert.deepEqual(
    Object.keys(DARK).sort(),
    Object.keys(DARK_MEDIA).sort(),
    'the [data-theme="dark"] block and the prefers-color-scheme block define different tokens'
  );
  for (const [name, value] of Object.entries(DARK)) {
    assert.equal(DARK_MEDIA[name], value, `${name} differs between the two dark blocks`);
  }

  for (const [label, palette] of [['light', LIGHT], ['dark', { ...LIGHT, ...DARK }]]) {
    for (const [fg, bg] of PAIRS) {
      assert.ok(palette[fg], `${label}: ${fg} is not defined`);
      assert.ok(palette[bg], `${label}: ${bg} is not defined`);
      const ratio = contrast(palette[fg], palette[bg]);
      assert.ok(
        ratio >= 4.5,
        `${label}: ${fg} (${palette[fg]}) on ${bg} (${palette[bg]}) is ${ratio.toFixed(2)}:1, below 4.5:1`
      );
    }
  }
});

ok('the retired tokens and the superseded rules are gone', () => {
  for (const dead of ['--subtle', '--grey-bg', '--border-mid', '--bg', '--surface',
                      '--text', '--muted', '--accent-bg', '--green', '--amber']) {
    assert.ok(
      !new RegExp(`\\${dead}\\s*:`).test(CSS) && !CSS.includes(`var(${dead})`),
      `retired token ${dead} still appears in the stylesheet`
    );
  }
  for (const rule of ['.steps-list::before', '.step-verify-toggle']) {
    assert.ok(!CSS.includes(rule), `superseded rule ${rule} still in the stylesheet`);
  }
  assert.ok(!/\.plan-glance\s*\{[^}]*margin:\s*-/.test(CSS), 'the .plan-glance negative-margin hack is still present');
  assert.ok(CSS.includes('html { scroll-behavior: auto; }'), 'reduced-motion scroll rule lost');
  assert.equal(html.match(/\{[a-z][a-z0-9-]*\}/g), null, 'unfilled skeleton tokens in the rendered page');
});

ok('the theme is reachable and resolved before first paint', () => {
  const headEnd = html.indexOf('</head>');
  const preload = html.slice(0, html.indexOf('<style'));
  assert.ok(preload.includes("localStorage.getItem('plan-theme')"),
    'the stored theme is not read before the stylesheet — the page would flash the wrong theme');
  assert.ok(preload.indexOf('<script>') < headEnd, 'the theme script is not inside <head>');
  assert.ok(html.includes('id="theme-toggle"'), 'no theme toggle button');
  assert.ok(/<button class="theme-toggle"[^>]*aria-pressed="false"/.test(html), 'toggle has no aria-pressed state');
  assert.ok(/min-height:\s*44px/.test(CSS.slice(CSS.indexOf('.theme-toggle'))), 'toggle hit area is under 44px');
  assert.ok(/@media print \{[\s\S]*?\.theme-toggle[\s\S]*?display: none/.test(CSS),
    'the theme toggle is not hidden by the print stylesheet');
  assert.ok(/function toggleTheme/.test(html), 'no toggleTheme handler shipped');
  assert.ok(/localStorage\.setItem\('plan-theme'/.test(html), 'the choice is never persisted');
  assert.ok(/prefers-color-scheme: dark/.test(html), 'a first visit has nothing to follow');
});

ok('one goal panel: the glance renders inside #objective and stays out of it', () => {
  const objectiveAt = html.indexOf('<div class="objective-card" id="objective">');
  assert.notEqual(objectiveAt, -1, 'no objective card');
  const objectiveEnd = html.indexOf('</div>', html.indexOf('<section class="plan-glance"'));
  assert.ok(
    html.indexOf('<section class="plan-glance"') > objectiveAt,
    'the glance is not nested inside the objective card'
  );
  assert.ok(objectiveEnd > objectiveAt, 'glance markup is malformed');
  assert.equal(html.match(/class="plan-glance"/g).length, 1, 'the glance renders more than once');

  const sections = extractSections(html);
  assert.equal(sections.objective, 'Prove the redesigned shell renders and still extracts.');
  assert.ok(
    !sections.objective.includes('Rebuild the shell'),
    'glance text leaked into the extracted objective'
  );
});

ok('Verify renders visible, outside any <details>, still inside .verify-body', () => {
  assert.ok(!html.includes('step-verify-toggle'), 'the verify disclosure is still emitted');
  const card = html.slice(html.indexOf('id="step-3"'));
  const verifyAt = card.indexOf('class="verify-body"');
  assert.notEqual(verifyAt, -1, 'no verify-body in the step card');
  const detailsAt = card.lastIndexOf('<details', verifyAt);
  const detailsClose = card.lastIndexOf('</details>', verifyAt);
  assert.ok(detailsAt === -1 || detailsClose > detailsAt, 'verify-body sits inside an open <details>');
  assert.ok(card.includes('every rail link resolves'), 'verify text lost');
});

ok('every step card is addressable and every rail link resolves to one', () => {
  const cardIds = [...html.matchAll(/<div class="step-card[^"]*" id="(step-\d+)">/g)].map((m) => m[1]);
  assert.deepEqual(cardIds, ['step-1', 'step-2', 'step-3'], 'step cards are not addressable in order');
  assert.ok(html.includes('<div class="step-card completed" id="step-1">'),
    'a done step lost `class="step-card completed"` as a literal substring');

  const railHrefs = [...html.matchAll(/<a class="rail-step[^"]*" href="#(step-\d+)">/g)].map((m) => m[1]);
  assert.deepEqual(railHrefs, cardIds, 'the rail does not link to exactly the step cards');

  const states = [...html.matchAll(/<span class="rail-state">([^<]+)<\/span>/g)].map((m) => m[1]);
  assert.deepEqual(states, ['step 1 of 3, done', 'step 2 of 3, done', 'step 3 of 3'],
    'rail links do not announce their number and done state in text');
});

ok('section anchors stay bare, and the progress block keeps its ids', () => {
  const links = [...html.matchAll(/<a href="#([a-z-]+)">/g)].map((m) => m[1]);
  assert.deepEqual(links,
    ['objective', 'progress', 'context', 'steps', 'criteria', 'verification', 'completion'],
    'the section-link regex no longer sees exactly the section anchors');
  assert.equal((html.match(/id="progress-bar"/g) || []).length, 1, 'progress-bar id count changed');
  assert.equal((html.match(/id="progress-label"/g) || []).length, 1, 'progress-label id count changed');
});

ok('the step list survives a narrow viewport behind a disclosure', () => {
  assert.ok(/<details class="rail-disclosure" open>/.test(html),
    'the rail is not shipped open — with scripting off it would be hidden on desktop');
  assert.ok(/@media \(max-width: 900px\) \{\s*\.rail-disclosure > summary \{ display: flex; \}/.test(CSS),
    'the disclosure summary never appears at narrow widths');
  assert.ok(!/\.rail-steps[^{]*\{[^}]*display:\s*none/.test(CSS),
    'the step list is removed rather than collapsed at narrow widths');
});

ok('the scroll spy can clear its active link', () => {
  const spy = html.slice(html.indexOf('/* ── Scroll spy'));
  assert.ok(spy.includes('setActive(null)'), 'nothing clears the active link when no target intersects');
  assert.ok(/visible\.splice/.test(spy), 'the observer never drops targets that left the viewport');
});

/* ── Round trip: the DOM contract the extractor and gallery read ───── */

ok('renderPlanHtml → extractSections round-trips the parsed spec', () => {
  assert.deepEqual(extractSections(html), parsed.sections);
});

/* ── Gallery: grouping data and controls ───────────────────────────── */

const GALLERY = readFileSync(
  join(ROOT, 'kit', 'plugins', 'plan-agent', 'templates', 'plans-gallery.html'), 'utf8');
const INDEX = readFileSync(join(ROOT, 'docs', 'plans', 'index.html'), 'utf8');

ok('the generated plans index carries grouping data and leads with in-flight work', () => {
  const cards = [...INDEX.matchAll(/<a class="gallery-card"[\s\S]*?<\/a>/g)].map((m) => m[0]);
  assert.ok(cards.length >= 10, `expected a populated gallery, got ${cards.length} cards`);
  for (const card of cards) {
    assert.ok(/data-month="\d{4}-\d{2}"/.test(card),
      `a card carries no data-month: ${card.slice(0, 90)}`);
  }
  const statuses = cards.map((c) => (c.match(/data-status="([^"]*)"/) || [])[1] || '');
  const lastFlight = statuses.lastIndexOf('in-progress');
  const firstOther = statuses.findIndex((s) => s !== 'in-progress');
  assert.ok(lastFlight === -1 || firstOther === -1 || lastFlight < firstOther,
    'in-progress cards are not sorted ahead of the rest');
  assert.ok(INDEX.includes(`<span>${cards.length} items</span>`),
    'the footer count the merge driver patches does not match the card count');
});

ok('the gallery groups client-side and hides the status control when unused', () => {
  assert.ok(GALLERY.includes('function rebuildSeparators'), 'no client-side separator builder');
  assert.ok(!INDEX.includes('<div class="gallery-sep"'),
    'a separator is baked into the generated markup, where the merge driver would destroy it');
  assert.ok(/statusSeg\.style\.display = "none"/.test(GALLERY),
    'the status control is not hidden for a gallery whose cards carry no status');
  assert.ok(/rebuildSeparators\(visible\)/.test(GALLERY),
    'separators are not rebuilt from the visible set on every filter change');
  assert.ok(GALLERY.includes('data-title'), 'search no longer matches on data-title');
});

console.log(`\n${passed} checks passed${process.exitCode ? ' (with failures)' : ''}`);
