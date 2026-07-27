#!/usr/bin/env node
/**
 * Objective (smoke) test for plan/prototype linking.
 *
 * Asserts the plan's stated objective end to end: a plan and its prototype
 * reference each other, and drift between them is detected.
 *
 *   1. A spec carrying `prototype:` renders the `plan-prototype` meta tag plus
 *      a header anchor with non-empty accessible text and an href that
 *      resolves to the prototype file on disk — from docs/plans/ and from a
 *      custom, nested plansDirectory.
 *   2. A spec without it renders neither.
 *   3. The plans gallery card gains a text-bearing prototype chip, with no
 *      nested anchor in the emitted card.
 *   4. check-prototype-drift.py is silent on a matched fixture pair and
 *      reports on a diverged one.
 *
 * Run: node tests/plugins/test-prototype-plan-link.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve as resolvePath } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const PLANS_INDEX = join(ROOT, 'scripts', 'build-plans-index.sh');
const DRIFT_HOOK = join(ROOT, 'kit', 'plugins', 'plan-agent', 'hooks', 'check-prototype-drift.py');

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

const MODEL = '{"entity":"Workout","fields":[{"name":"date","type":"date"},{"name":"exercise","type":"string"}],"action":"Log","successSignal":"total count"}';

function spec({ prototype, protoModel } = {}) {
  const extra = [
    prototype ? `prototype: ${prototype}` : '',
    protoModel ? `proto-model: ${protoModel}` : '',
  ].filter(Boolean);
  return `---
status: todo
type: feature
created: 2026-07-25
${extra.join('\n')}${extra.length ? '\n' : ''}---

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
}

const SKELETON = join(
  ROOT, 'kit', 'plugins', 'plan-agent', 'skills', 'prototype', 'reference', 'PROTOTYPE-SKELETON.html'
);

/**
 * Fill the REAL skeleton, not a hand-rolled stand-in. A minimal fixture hid a
 * live bug: the skeleton's authoring comment ships a literal
 * `data-field="key"` into every generated prototype, and the drift hook read
 * it as a real field.
 */
function prototypeHtml({ source, fields }) {
  const model = JSON.stringify({
    entity: 'Workout',
    fields,
    action: 'Log',
    successSignal: 'total count',
  });
  const subs = {
    '{{SOURCE_PLAN}}': source,
    '{{PROTO_CREATED}}': '2026-07-25',
    '{{TITLE}}': 'Track gym workouts',
    '{{STORE_KEY}}': 'track-gym-workouts',
    '{{SEED_JSON}}': '[]',
    '{{PROTO_MODEL}}': model,
    '{{SUMMARY}}': 'Workouts',
    '{{COLUMNS}}': fields
      .map((f) => `<th scope="col" data-field="${f.name}" data-type="${f.type}">${f.name}</th>`)
      .join('\n      '),
    '{{FORM_FIELDS}}': fields
      .map((f) => `<div class="field"><label for="${f.name}">${f.name}</label><input id="${f.name}" name="${f.name}" data-required></div>`)
      .join('\n  '),
    '{{PRIMARY_ACTION}}': 'Log',
  };
  let html = readFileSync(SKELETON, 'utf8');
  for (const [token, value] of Object.entries(subs)) html = html.split(token).join(value);
  assert.ok(!html.includes('{{'), 'every skeleton placeholder was substituted');
  return html;
}

const MATCHED_FIELDS = [
  { name: 'date', type: 'date' },
  { name: 'exercise', type: 'string' },
];

/**
 * Render from inside the project dir, the way render-plan-html.py does: the
 * renderer derives `plan-path` relative to cwd, and `prototype:` is
 * repo-relative — the two only share a frame when cwd is the project root.
 */
function render(projectDir, specPath, outPath) {
  const res = spawnSync('node', [RENDERER, specPath, '-o', outPath], { encoding: 'utf8', cwd: projectDir });
  assert.equal(res.status, 0, res.stderr);
  return readFileSync(outPath, 'utf8');
}

function runDriftHook(projectDir, protoPath) {
  return spawnSync('python3', [DRIFT_HOOK], {
    input: JSON.stringify({ tool_input: { file_path: protoPath } }),
    encoding: 'utf8',
    env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
  });
}

/** Extract the href of the header prototype anchor, or null. */
function prototypeAnchor(html) {
  const m = html.match(/<a class="prototype-link" href="([^"]+)"([\s\S]*?)<\/a>/);
  if (!m) return null;
  const text = m[2].replace(/^[\s\S]*?>/, '').trim();
  const label = m[2].match(/aria-label="([^"]*)"/);
  return { href: m[1], text, ariaLabel: label ? label[1] : '' };
}

function makeProject() {
  // realpath: on macOS $TMPDIR is a symlink into /private, and process.cwd()
  // reports the resolved form — an unresolved path makes every cwd-relative
  // path the renderer derives absurd.
  const proj = realpathSync(mkdtempSync(join(tmpdir(), 'proto-plan-link-')));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'prototypes'), { recursive: true });
  return proj;
}

/* ── 1. Renderer emits the link and the meta tag ──────────────────── */

ok('spec with prototype: renders meta tag + header anchor whose href resolves', () => {
  const proj = makeProject();
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'docs', 'plans', 'track-gym-workouts.html');
  const protoPath = join(proj, 'docs', 'prototypes', 'track-gym-workouts.html');
  writeFileSync(specPath, spec({ prototype: 'docs/prototypes/track-gym-workouts.html', protoModel: MODEL }));
  writeFileSync(protoPath, prototypeHtml({ source: 'docs/plans/track-gym-workouts.md', fields: MATCHED_FIELDS }));

  const html = render(proj, specPath, outPath);
  assert.match(html, /<meta name="plan-prototype" content="docs\/prototypes\/track-gym-workouts\.html">/);

  const anchor = prototypeAnchor(html);
  assert.ok(anchor, 'header prototype anchor is present');
  assert.ok(anchor.text.length > 0, 'anchor has non-empty visible text');
  assert.ok(anchor.ariaLabel.length > 0, 'anchor has a non-empty aria-label');
  assert.equal(anchor.href, '../prototypes/track-gym-workouts.html');
  // The href must resolve against the RENDERED PLAN's directory, not cwd.
  const resolved = resolvePath(dirname(outPath), anchor.href);
  assert.equal(resolved, protoPath, 'href resolves to the prototype file on disk');
  rmSync(proj, { recursive: true, force: true });
});

ok('href resolves from a custom nested plansDirectory too', () => {
  const proj = makeProject();
  mkdirSync(join(proj, 'custom', 'deep', 'plans'), { recursive: true });
  const specPath = join(proj, 'custom', 'deep', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'custom', 'deep', 'plans', 'track-gym-workouts.html');
  const protoPath = join(proj, 'docs', 'prototypes', 'track-gym-workouts.html');
  writeFileSync(protoPath, prototypeHtml({ source: 'docs/plans/track-gym-workouts.md', fields: MATCHED_FIELDS }));
  writeFileSync(
    specPath,
    spec({ prototype: 'docs/prototypes/track-gym-workouts.html', protoModel: MODEL }).replace(
      'created: 2026-07-25',
      'created: 2026-07-25\npath: custom/deep/plans/track-gym-workouts.html'
    )
  );

  const html = render(proj, specPath, outPath);
  const anchor = prototypeAnchor(html);
  assert.ok(anchor, 'header prototype anchor is present');
  assert.equal(anchor.href, '../../../docs/prototypes/track-gym-workouts.html');
  assert.equal(resolvePath(dirname(outPath), anchor.href), protoPath, 'href resolves from the nested dir');
  // A hard-coded ../prototypes/ would have produced custom/deep/prototypes/.
  assert.ok(!anchor.href.startsWith('../prototypes/'), 'href is not the hard-coded sibling path');
  rmSync(proj, { recursive: true, force: true });
});

ok('spec without prototype: renders neither the meta tag nor the anchor', () => {
  const proj = makeProject();
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'docs', 'plans', 'track-gym-workouts.html');
  writeFileSync(specPath, spec());
  const html = render(proj, specPath, outPath);
  assert.ok(!html.includes('plan-prototype'), 'no plan-prototype meta tag');
  assert.equal(prototypeAnchor(html), null, 'no header prototype anchor');
  rmSync(proj, { recursive: true, force: true });
});

/* ── 2. Gallery chip ──────────────────────────────────────────────── */

ok('plans gallery card gains a text-bearing prototype chip with no nested anchor', () => {
  const proj = makeProject();
  const linked = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const plain = join(proj, 'docs', 'plans', 'write-plain-plan.md');
  writeFileSync(linked, spec({ prototype: 'docs/prototypes/track-gym-workouts.html', protoModel: MODEL }));
  writeFileSync(plain, spec());
  render(proj, linked, join(proj, 'docs', 'plans', 'track-gym-workouts.html'));
  render(proj, plain, join(proj, 'docs', 'plans', 'write-plain-plan.html'));

  const res = spawnSync('bash', [PLANS_INDEX, proj], { encoding: 'utf8' });
  assert.equal(res.status, 0, res.stderr);
  const index = readFileSync(join(proj, 'docs', 'plans', 'index.html'), 'utf8');

  const cards = index.split('<a class="gallery-card"').slice(1);
  const linkedCard = cards.find((c) => c.includes('track-gym-workouts.html'));
  const plainCard = cards.find((c) => c.includes('write-plain-plan.html'));
  assert.ok(linkedCard && plainCard, 'both plan cards rendered');

  const chip = linkedCard.match(/<span class="proto-chip"[^>]*>([^<]*)<\/span>/);
  assert.ok(chip, 'linked card carries a proto-chip span');
  assert.ok(chip[1].trim().length > 0, 'chip exposes non-empty accessible text');
  assert.ok(!plainCard.includes('proto-chip'), 'unlinked card carries no chip');

  // The whole card is already an <a>; a nested one is invalid HTML.
  const cardHtml = linkedCard.slice(0, linkedCard.indexOf('</a>'));
  assert.ok(!cardHtml.includes('<a '), 'no anchor nested inside the card anchor');
  rmSync(proj, { recursive: true, force: true });
});

/* ── 3. Drift detection ───────────────────────────────────────────── */

ok('drift hook is silent on a matched pair and reports on a diverged one', () => {
  const proj = makeProject();
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const protoPath = join(proj, 'docs', 'prototypes', 'track-gym-workouts.html');
  writeFileSync(specPath, spec({ prototype: 'docs/prototypes/track-gym-workouts.html', protoModel: MODEL }));
  writeFileSync(protoPath, prototypeHtml({ source: 'docs/plans/track-gym-workouts.md', fields: MATCHED_FIELDS }));

  const clean = runDriftHook(proj, protoPath);
  assert.equal(clean.status, 0);
  assert.equal(clean.stderr.trim(), '', 'matched pair produces no warning');

  // Rename one field in the model block only — the DOM and the plan both keep
  // the original name, so BOTH comparisons must fire.
  const diverged = readFileSync(protoPath, "utf8").replace(
    '<script type="application/json" id="proto-model">{"entity":"Workout","fields":[{"name":"date"',
    '<script type="application/json" id="proto-model">{"entity":"Workout","fields":[{"name":"day"'
  );
  assert.ok(diverged.includes('"name":"day"'), 'fixture rewrite applied');
  writeFileSync(protoPath, diverged);

  const dirty = runDriftHook(proj, protoPath);
  assert.equal(dirty.status, 0, 'drift hook still exits 0');
  const lines = dirty.stderr.trim().split('\n').filter(Boolean);
  assert.equal(lines.length, 2, `expected two warnings, got: ${dirty.stderr}`);
  for (const line of lines) {
    assert.match(line, /day/, 'warning names the diverging field');
    assert.match(line, /track-gym-workouts\.html/, 'warning names the prototype');
  }
  assert.ok(
    lines.some((l) => l.includes('docs/plans/track-gym-workouts.md')),
    'the plan-mismatch warning names the plan spec'
  );
  rmSync(proj, { recursive: true, force: true });
});

console.log(`\n${passed} passed`);
if (process.exitCode) console.error('FAILURES — see above');
