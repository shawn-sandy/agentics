#!/usr/bin/env node
/**
 * Objective (smoke) test for plan/design-canvas linking.
 *
 * Asserts the plan's stated objective: a plan and its published design canvas
 * reference each other, and the link survives rendering.
 *
 *   1. A spec carrying `design:` and `design-dir:` renders the `plan-design`
 *      meta tag plus a header anchor with non-empty accessible text whose href
 *      is the artifact URL VERBATIM — a canvas lives at a URL, so unlike
 *      `prototype:` nothing is relativized against the output directory.
 *   2. A spec carrying neither renders neither.
 *   3. A spec carrying a non-http(s) `design:` renders neither. Escaping leaves
 *      a scheme intact, so `javascript:` would otherwise ship an
 *      ordinary-looking anchor that runs on click.
 *   4. The renderer's two byte-identical copies still hash identically.
 *      `build-plan-html.mjs` and its lib both ship twice with no shared parity
 *      guard, so editing one and not the other half-ships the feature.
 *
 * Run: node tests/plugins/test-design-plan-link.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');

const CANVAS_URL = 'https://claude.ai/public/artifacts/abc123';
const DESIGN_DIR = 'docs/designs/track-gym-workouts';

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

/* ── Fixtures ─────────────────────────────────────────────────────── */

function spec({ design, designDir } = {}) {
  const extra = [
    design ? `design: ${design}` : '',
    designDir ? `design-dir: ${designDir}` : '',
  ].filter(Boolean);
  return `---
status: todo
type: feature
created: 2026-08-21
${extra.join('\n')}${extra.length ? '\n' : ''}---

# Plan: Track gym workouts

## Objective

Track workouts.

## Steps

1. Add the workout log form. Why: it is needed. Verify: it happened.

## Acceptance Criteria

- [ ] The thing is done.

## Verification

Run the thing.
`;
}

/**
 * Render from inside the project dir, the way render-plan-html.py does: the
 * renderer derives `plan-path` relative to cwd.
 */
function render(projectDir, specPath, outPath) {
  const res = spawnSync('node', [RENDERER, specPath, '-o', outPath], { encoding: 'utf8', cwd: projectDir });
  assert.equal(res.status, 0, res.stderr);
  return readFileSync(outPath, 'utf8');
}

/** Extract the header design anchor, or null. */
function designAnchor(html) {
  const m = html.match(/<a class="design-link" href="([^"]+)"([\s\S]*?)<\/a>/);
  if (!m) return null;
  const text = m[2].replace(/^[\s\S]*?>/, '').trim();
  const label = m[2].match(/aria-label="([^"]*)"/);
  return { href: m[1], text, ariaLabel: label ? label[1] : '' };
}

function makeProject() {
  // realpath: on macOS $TMPDIR is a symlink into /private, and process.cwd()
  // reports the resolved form.
  const proj = realpathSync(mkdtempSync(join(tmpdir(), 'design-plan-link-')));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'designs', 'track-gym-workouts'), { recursive: true });
  return proj;
}

function renderSpec(body) {
  const proj = makeProject();
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'docs', 'plans', 'track-gym-workouts.html');
  writeFileSync(specPath, body);
  const html = render(proj, specPath, outPath);
  rmSync(proj, { recursive: true, force: true });
  return html;
}

/* ── 1. Renderer emits the meta tag and the header anchor ─────────── */

ok('spec with design: + design-dir: renders the meta tag and a labelled header anchor', () => {
  const html = renderSpec(spec({ design: CANVAS_URL, designDir: DESIGN_DIR }));
  assert.match(
    html,
    new RegExp(`<meta name="plan-design" content="${CANVAS_URL.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}">`),
    'plan-design meta tag carries the artifact URL'
  );

  const anchor = designAnchor(html);
  assert.ok(anchor, 'header design anchor is present');
  assert.ok(anchor.text.length > 0, 'anchor has non-empty visible text');
  assert.ok(anchor.ariaLabel.length > 0, 'anchor has a non-empty aria-label');
  // Verbatim, not relativized: a canvas is a URL, not a repo path.
  assert.equal(anchor.href, CANVAS_URL, 'href is the artifact URL verbatim');
});

/* ── 2. Absent key renders nothing ────────────────────────────────── */

ok('spec with neither key renders neither the meta tag nor the anchor', () => {
  const html = renderSpec(spec());
  assert.ok(!html.includes('plan-design'), 'no plan-design meta tag');
  assert.equal(designAnchor(html), null, 'no header design anchor');
});

/* ── 3. Non-http(s) is dropped for BOTH the tag and the link ──────── */

ok('a javascript: design: value renders neither the meta tag nor the anchor', () => {
  const html = renderSpec(spec({ design: 'javascript:alert(1)', designDir: DESIGN_DIR }));
  assert.ok(!html.includes('plan-design'), 'no plan-design meta tag for a javascript: value');
  assert.equal(designAnchor(html), null, 'no header design anchor for a javascript: value');
  assert.ok(!html.includes('javascript:alert'), 'the unusable value appears nowhere in the output');
});

/* ── 4. The renderer's duplicated copies stay byte-identical ──────── */

ok('both renderer copies hash identically', () => {
  const pairs = [
    ['scripts/build-plan-html.mjs', 'kit/plugins/plan-agent/scripts/build-plan-html.mjs'],
    ['scripts/lib/plan-shell.mjs', 'kit/plugins/plan-agent/scripts/lib/plan-shell.mjs'],
  ];
  const sha = (rel) => createHash('sha256').update(readFileSync(join(ROOT, rel))).digest('hex');
  for (const [a, b] of pairs) {
    assert.equal(sha(a), sha(b), `${a} and ${b} have drifted — edit both copies`);
  }
});

console.log(`\n${passed} passed`);
if (process.exitCode) console.error('FAILURES — see above');
