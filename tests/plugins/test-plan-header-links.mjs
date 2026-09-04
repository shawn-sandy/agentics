#!/usr/bin/env node
/**
 * Regression test for the plan header's link chips.
 *
 * `.plan-header-actions` is a flex row whose children are placed by explicit
 * `order` values: badges first, controls last. The prototype / issue / design
 * anchors the renderer emits into that row used to carry no CSS at all, so
 * they defaulted to `order: 0`, jumped ahead of the status badge, and rendered
 * as bare underlined text beside two pill badges.
 *
 *   1. Each header link class is selected by a rule in the shared stylesheet.
 *   2. Their `order` sits strictly after both badges and strictly before both
 *      controls.
 *   3. They share the badges' chip geometry (padding, radius, font size).
 *
 * This is the CI guard. Computed-style verification (real `order`, drawn
 * pill) is done in a browser against the rendered page, not here.
 *
 * Run: node tests/plugins/test-plan-header-links.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');

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

const SPEC = `---
status: todo
type: feature
created: 2026-09-04
prototype: docs/prototypes/track-gym-workouts.html
issue: https://github.com/shawn-sandy/agentics/issues/512
design: https://claude.ai/public/artifacts/00000000-0000-4000-8000-000000000000
---

# Plan: Track gym workouts

## Objective

Track workouts.

## Steps

1. Do the thing. Why: it is needed. Verify: it happened.

## Acceptance Criteria

- [ ] The thing is done.

## Verification

Run the thing.
`;

function render() {
  const proj = realpathSync(mkdtempSync(join(tmpdir(), 'header-links-')));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'prototypes'), { recursive: true });
  writeFileSync(join(proj, 'docs', 'prototypes', 'track-gym-workouts.html'), '<!doctype html><title>proto</title>\n');
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'docs', 'plans', 'track-gym-workouts.html');
  writeFileSync(specPath, SPEC);
  const res = spawnSync('node', [RENDERER, specPath, '-o', outPath], { encoding: 'utf8', cwd: proj });
  assert.equal(res.status, 0, res.stderr);
  const html = readFileSync(outPath, 'utf8');
  rmSync(proj, { recursive: true, force: true });
  return html;
}

/** Flatten every `selector { body }` pair in the page's <style> blocks (comments stripped, @media context dropped). */
function rules(html) {
  const css = [...html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/g)].map((m) => m[1]).join('\n')
    .replace(/\/\*[\s\S]*?\*\//g, '');
  const out = [];
  for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    out.push({ selectors: m[1].split(',').map((s) => s.trim()), body: m[2] });
  }
  return out;
}

function declaration(rule, prop) {
  const m = rule.body.match(new RegExp(`(?:^|;)\\s*${prop}\\s*:\\s*([^;]+)`));
  return m ? m[1].trim() : null;
}

/** First declared value of `prop` across rules whose selector list includes `selector`. */
function declared(all, selector, prop) {
  for (const r of all) {
    if (!r.selectors.includes(selector)) continue;
    const v = declaration(r, prop);
    if (v !== null) return v;
  }
  return null;
}

const html = render();
const all = rules(html);
const LINKS = ['prototype-link', 'issue-link', 'design-link'];

ok('the header renders all three link anchors inside .plan-header-actions', () => {
  const row = html.match(/<div class="plan-header-actions">([\s\S]*?)<\/div>/);
  assert.ok(row, 'actions row present');
  for (const cls of LINKS) assert.ok(row[1].includes(`class="${cls}"`), `${cls} anchor is in the row`);
});

ok('each header link class is selected by a rule in the shared stylesheet', () => {
  for (const cls of LINKS) {
    const hit = all.some((r) => r.selectors.some((s) => s.includes(`.${cls}`)));
    assert.ok(hit, `.${cls} has no CSS rule at all — it renders as a bare underlined link`);
  }
});

ok('link order sits after both badges and before both controls', () => {
  const orderOf = (cls) => {
    const v = declared(all, `.plan-header-actions .${cls}`, 'order');
    assert.ok(v !== null, `.plan-header-actions .${cls} declares no order (defaults to 0, ahead of the badges)`);
    assert.match(v, /^-?\d+$/, `order for .${cls} is an integer (got "${v}")`);
    return Number(v);
  };
  const badges = ['status-badge', 'effort-badge'].map(orderOf);
  const controls = ['save-pdf-btn', 'theme-toggle'].map(orderOf);
  for (const cls of LINKS) {
    const o = orderOf(cls);
    assert.ok(o > Math.max(...badges), `.${cls} order ${o} must exceed the badges (${badges})`);
    assert.ok(o < Math.min(...controls), `.${cls} order ${o} must precede the controls (${controls})`);
  }
});

ok('link chips share the status badge geometry', () => {
  for (const prop of ['padding', 'border-radius', 'font-size']) {
    const badge = declared(all, '.status-badge', prop);
    assert.ok(badge !== null, `.status-badge declares ${prop}`);
    for (const cls of LINKS) {
      const link = all.find((r) => r.selectors.some((s) => s.endsWith(`.${cls}`)) && declaration(r, prop) !== null);
      assert.ok(link, `.${cls} declares ${prop}`);
      assert.equal(declaration(link, prop), badge, `.${cls} ${prop} matches .status-badge`);
    }
  }
});

console.log(`\n${passed} passed`);
if (process.exitCode) console.error('FAILURES — see above');
