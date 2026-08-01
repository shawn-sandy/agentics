#!/usr/bin/env node
// Objective test for the gallery row layout: the generated index renders the
// prototype's rows under the shared shell WITHOUT breaking the splice unit
// scripts/merge-plans-index.mjs depends on.
//
// The two halves are inseparable. The row markup is only correct if the merge
// driver can still find, count, and splice it — a row that looks right and
// merges wrong loses every incoming plan on the first concurrent PR. So the
// regexes below are lifted out of the driver source rather than restated here:
// if the driver's contract changes, this test changes with it or fails.

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const TMP = mkdtempSync(join(tmpdir(), 'gallery-row-layout-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log(`PASS: ${name}`);
    pass++;
  } else {
    console.log(`FAIL: ${name}${detail ? ` — ${detail}` : ''}`);
    fail++;
  }
}

// ── The driver's own regexes ────────────────────────────────────────────────
// merge-plans-index.mjs runs on import (it reads argv and writes files), so the
// literals are read out of its source instead of imported. Extracted, not
// reimplemented: a copy here would keep passing after the driver moved on.
const driverSrc = readFileSync(join(ROOT, 'scripts/merge-plans-index.mjs'), 'utf8');
function driverRegex(name) {
  const m = driverSrc.match(new RegExp(`const ${name} = (/.*/[gimsuy]*);`));
  if (!m) throw new Error(`${name} not found in merge-plans-index.mjs`);
  const body = m[1].slice(1, m[1].lastIndexOf('/'));
  const flags = m[1].slice(m[1].lastIndexOf('/') + 1);
  return new RegExp(body, flags);
}
const CARD_RE = driverRegex('CARD_RE');
const COUNT_RE = driverRegex('COUNT_RE');

// ── Fixture ─────────────────────────────────────────────────────────────────
// Each plan carries the step-card markup the real renderer emits: one
// `class="step-card"` per step, ` completed` appended on the finished ones,
// plus a `step-card-header` inside every step — the near-miss the count must
// not pick up.
function step(done) {
  return `<div class="step-card${done ? ' completed' : ''}">` +
         '<div class="step-card-header">Step</div></div>';
}

function plan({ title, status, type, effort, created, total = 0, done = 0 }) {
  const steps = Array.from({ length: total }, (_, i) => step(i < done)).join('\n');
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>Plan: ${title}</title>
<meta name="plan-status" content="${status}">
<meta name="plan-type" content="${type}">
<meta name="plan-effort" content="${effort}">
<meta name="plan-created" content="${created}">
<style>.step-card { border: 0; } .step-card-header { font-weight: 600; }</style>
</head><body>${steps}</body></html>
`;
}

const PLANS = [
  { file: 'ship-the-row-layout.html', title: 'Ship the row layout', status: 'in-progress',
    type: 'refactor', effort: 'high', created: '2026-07-30', total: 12, done: 4 },
  { file: 'start-the-parser.html', title: 'Start the parser', status: 'in-progress',
    type: 'feature', effort: 'medium', created: '2026-07-28', total: 8, done: 0 },
  { file: 'land-the-merge-driver.html', title: 'Land the merge driver', status: 'completed',
    type: 'fix', effort: 'low', created: '2026-06-14', total: 5, done: 5 },
  { file: 'queue-the-hub-redesign.html', title: 'Queue the hub redesign', status: 'todo',
    type: 'docs', effort: '', created: '2026-06-02', total: 0, done: 0 },
];

// Sibling collections, so the topbar counts have something to count.
const SIBLINGS = {
  prototypes: 2,
  artifacts: 1,
  'media/social': 3,
};

// A NON-DEFAULT plansDirectory on purpose: plansDirectory is configurable, and
// a topbar that hard-codes docs/plans reports the wrong Plans count and links
// from the wrong depth for every project that moves it.
const plansDir = join(TMP, 'docs', 'notes', 'plans');
mkdirSync(join(TMP, '.claude'), { recursive: true });
writeFileSync(join(TMP, '.claude', 'settings.json'),
  JSON.stringify({ plansDirectory: 'docs/notes/plans' }));
mkdirSync(plansDir, { recursive: true });
for (const p of PLANS) writeFileSync(join(plansDir, p.file), plan(p));
// An index.html already on disk must not be counted as a plan.
writeFileSync(join(plansDir, 'index.html'), '<html>stale</html>');
for (const [rel, n] of Object.entries(SIBLINGS)) {
  const d = join(TMP, 'docs', ...rel.split('/'));
  mkdirSync(d, { recursive: true });
  for (let i = 0; i < n; i++) writeFileSync(join(d, `item-${i}.html`), '<html></html>');
  writeFileSync(join(d, 'index.html'), '<html></html>');
}

const build = spawnSync('bash', [join(ROOT, 'docs/plans/build-index.sh'), TMP], {
  encoding: 'utf8',
  // HOME is redirected so a real ~/.claude/settings.json cannot point the
  // generator at the developer's own plans directory mid-test.
  env: { ...process.env, HOME: TMP, CLAUDE_PLUGIN_ROOT: '' },
});
check('build-index.sh exits 0 over the fixture', build.status === 0, build.stderr);
// Every check below reads the index the generator was supposed to write. If it
// did not run, readFileSync throws ENOENT and buries the real cause under a
// stack trace — report and stop instead.
if (build.status !== 0) {
  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(1);
}

const index = readFileSync(join(plansDir, 'index.html'), 'utf8');

// ── The splice unit ─────────────────────────────────────────────────────────
const cards = index.match(CARD_RE) ?? [];
check(
  `CARD_RE matches one card per fixture plan (${PLANS.length})`,
  cards.length === PLANS.length,
  `matched ${cards.length}`,
);
check(
  'no card contains a nested anchor',
  cards.every((c) => !/<a[\s>]/.test(c.slice(2))),
  'a nested <a> would truncate the card at the wrong </a>',
);
check(
  'the splice region between the first and last card holds no <li>',
  !/<li[\s>]/i.test(index.slice(index.indexOf(cards[0]), index.lastIndexOf(cards.at(-1)))),
  'a wrapper between cards is destroyed by the first concurrent merge',
);
check(
  'class="gallery-card" is the leading attribute pair on every card',
  cards.every((c) => c.startsWith('<a class="gallery-card" ')),
);

const counts = [...index.matchAll(COUNT_RE)];
check('COUNT_RE matches exactly twice', counts.length === 2, `matched ${counts.length}`);
check(
  'both patched counts equal the card count',
  counts.every((m) => Number(m[2]) === PLANS.length),
  counts.map((m) => m[2]).join(', '),
);

// ── Step progress ───────────────────────────────────────────────────────────
for (const p of PLANS) {
  const card = cards.find((c) => c.includes(`href="${p.file}"`));
  if (!card) {
    check(`${p.file}: card rendered`, false);
    continue;
  }
  const done = card.match(/data-steps-done="(\d+)"/)?.[1];
  const total = card.match(/data-steps-total="(\d+)"/)?.[1];
  check(
    `${p.file}: step counts are ${p.done} / ${p.total}`,
    Number(done) === p.done && Number(total) === p.total,
    `got ${done} / ${total} — step-card-header must not count as a step`,
  );
  const hasText = card.includes(`>${p.done} / ${p.total} steps<`);
  check(
    `${p.file}: "N / M steps" is ${p.status === 'in-progress' && p.total ? 'server-rendered' : 'absent'}`,
    hasText === (p.status === 'in-progress' && p.total > 0),
  );
}

// ── Status is announced, not only drawn ─────────────────────────────────────
check(
  'every card pairs an aria-hidden glyph with visually-hidden status text',
  cards.every((c) => /<span class="glyph" aria-hidden="true">.*?<\/span><span class="sr-only">[a-z ]+<\/span>/.test(c)),
);
check(
  'no card carries an aria-label that would override its visible text',
  cards.every((c) => !c.includes('aria-label=')),
);
check('the .sr-only clip utility is defined', /\.sr-only\s*\{[^}]*clip-path/.test(index));

// ── Rows, not cards ─────────────────────────────────────────────────────────
check('every card renders a row title', cards.every((c) => c.includes('<span class="r-title">')));
check('the view toggle is gone', !/view-btn|list-view/.test(index));
check('no card-grid track definition survives', !index.includes('repeat(auto-fill'));
for (const token of ['--subtle', '--grey-bg', '--border-mid']) {
  check(`the retired token ${token} is absent`, !index.includes(token));
}
check('no phase label is rendered', !/Phase \d+ of \d+/.test(index));

// ── Topbar ──────────────────────────────────────────────────────────────────
const topbar = index.match(/<nav class="tabs"[\s\S]*?<\/nav>/)?.[0] ?? '';
check('the topbar renders five tabs', (topbar.match(/<a /g) ?? []).length === 5, topbar);
check(
  'exactly one tab is marked aria-current="page"',
  (topbar.match(/aria-current="page"/g) ?? []).length === 1,
);
check('the current tab is Plans', /aria-current="page">Plans/.test(topbar));
const tabCount = (label) => Number(topbar.match(new RegExp(`${label}<span class="n">(\\d+)`))?.[1]);
check(`Plans tab counts ${PLANS.length}`, tabCount('Plans') === PLANS.length, String(tabCount('Plans')));
for (const [rel, n] of Object.entries(SIBLINGS)) {
  const label = { prototypes: 'Prototypes', artifacts: 'Artifacts', 'media/social': 'Social' }[rel];
  check(`${label} tab counts ${n} (index.html excluded)`, tabCount(label) === n, String(tabCount(label)));
}
const href = (label) => topbar.match(new RegExp(`<a href="([^"]+)"[^>]*>${label}`))?.[1];
check('the Plans tab links to this page', href('Plans') === 'index.html', href('Plans'));
for (const [label, expected] of [['Home', '../../index.html'], ['Prototypes', '../../prototypes/index.html'],
                                 ['Artifacts', '../../artifacts/index.html'], ['Social', '../../media/social/index.html']]) {
  check(`the ${label} tab href resolves from docs/notes/plans`, href(label) === expected, href(label));
}

check(
  'the topbar declares an opaque background before its color-mix value',
  index.indexOf('background: var(--paper);\n        background: color-mix') !== -1,
  'a browser without color-mix drops the second declaration and needs the first',
);
check('no template placeholder survives substitution', !/\{\{[A-Z_]+\}\}/.test(index));

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
