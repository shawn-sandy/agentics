#!/usr/bin/env node
// Objective test for artifact-default publishing: the plans gallery cards an
// artifact-only plan straight from its .md spec, linking the artifact URL —
// and a sibling .html, when published, always wins the card.
//
// Four fixtures pin the whole rule: an artifact-only spec (carded by URL, new
// tab, chip, sr-only note), a spec with a sibling .html (carded by file path,
// same tab, even though the spec also carries artifact-url), a keyless spec
// (invisible — nothing to link), and a javascript:-scheme spec (invisible with
// a stderr warning — the generator writes raw hrefs into a page people open).

import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, copyFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const TMP = mkdtempSync(join(tmpdir(), 'gallery-artifact-cards-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) { console.log(`PASS: ${name}`); pass++; }
  else { console.log(`FAIL: ${name}${detail ? ` — ${detail}` : ''}`); fail++; }
}

// The driver's splice unit, lifted from its source (same extraction as
// test-gallery-row-layout.mjs) so a contract change there fails here too.
const driverSrc = readFileSync(join(ROOT, 'scripts/merge-plans-index.mjs'), 'utf8');
const m = driverSrc.match(/const CARD_RE = (\/.*\/[gimsuy]*);/);
if (!m) throw new Error('CARD_RE not found in merge-plans-index.mjs');
const CARD_RE = new RegExp(m[1].slice(1, m[1].lastIndexOf('/')), m[1].slice(m[1].lastIndexOf('/') + 1));

// ── Fixtures ────────────────────────────────────────────────────────────────
const ARTIFACT_URL = 'https://claude.ai/public/artifacts/test-abc';

function spec({ title, status = 'todo', type = 'feature', created = '2026-08-20', artifactUrl, steps = [] }) {
  const fm = ['---', `status: ${status}`, `type: ${type}`, `created: ${created}`];
  if (artifactUrl) fm.push(`artifact-url: ${artifactUrl}`);
  fm.push('---');
  const stepLines = steps.map((done, i) =>
    `${i + 1}. ${done ? '[x] ' : ''}Do thing ${i + 1} Why: fixture Verify: check ${i + 1}.`);
  return `${fm.join('\n')}\n\n# Plan: ${title}\n\n## Objective\n\nFixture objective.\n\n## Steps\n\n${stepLines.join('\n')}\n\n## Acceptance Criteria\n\n- [ ] done\n\n## Verification\n\nRun the fixture check.\n`;
}

function planHtml({ title, status, type, created }) {
  return `<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n<title>Plan: ${title}</title>\n<meta name="plan-status" content="${status}">\n<meta name="plan-type" content="${type}">\n<meta name="plan-created" content="${created}">\n</head><body></body></html>\n`;
}

const plansDir = join(TMP, 'docs', 'plans');
mkdirSync(plansDir, { recursive: true });

// 1. Artifact-only: spec with artifact-url, no sibling .html.
writeFileSync(join(plansDir, 'add-artifact-only.md'), spec({
  title: 'Add the artifact only plan', status: 'in-progress',
  artifactUrl: ARTIFACT_URL, steps: [true, false, false],
}));
// 2. File wins: spec with artifact-url AND a sibling .html.
writeFileSync(join(plansDir, 'ship-file-plan.md'), spec({
  title: 'Ship the file plan', status: 'todo', artifactUrl: 'https://claude.ai/public/artifacts/other',
}));
writeFileSync(join(plansDir, 'ship-file-plan.html'), planHtml({
  title: 'Ship the file plan', status: 'todo', type: 'feature', created: '2026-08-19',
}));
// 3. Keyless spec, no sibling: nothing to link, no card.
writeFileSync(join(plansDir, 'draft-keyless.md'), spec({ title: 'Draft the keyless plan' }));
// 4. Non-http(s) scheme: no card, stderr warning.
writeFileSync(join(plansDir, 'fix-evil-scheme.md'), spec({
  title: 'Fix the evil scheme', artifactUrl: 'javascript:alert(1)',
}));
// 5. Not a plan at all: docs/plans also holds session exports, which carry the
// same artifact-url: key and no plan sections. The gallery is the *plans*
// gallery — an artifact-url alone must not promote a non-plan into it.
mkdirSync(join(plansDir, 'sessions'), { recursive: true });
writeFileSync(join(plansDir, 'sessions', 'add-thing-session.md'),
  `---\ntype: session-export\ndate: 2026-08-21\nartifact-url: ${ARTIFACT_URL}-session\n---\n\n# Add the thing\n\n## Summary\n\nWhat happened.\n`);

const build = spawnSync('bash', [join(ROOT, 'docs/plans/build-index.sh'), TMP], {
  encoding: 'utf8',
  env: { ...process.env, HOME: TMP, CLAUDE_PLUGIN_ROOT: '' },
});
check('build-index.sh exits 0 over the fixture', build.status === 0, build.stderr);
if (build.status !== 0) {
  console.log(`\n${pass} passed, ${fail} failed`);
  process.exit(1);
}

const index = readFileSync(join(plansDir, 'index.html'), 'utf8');
const cards = index.match(CARD_RE) ?? [];

check('exactly two cards emitted (artifact-only + file plan)', cards.length === 2,
  `matched ${cards.length}`);
check('reported item count matches the two cards',
  /\(2 items/.test(build.stdout), build.stdout.trim());

const artifactCard = cards.find((c) => c.includes('data-local="add-artifact-only"'));
const fileCard = cards.find((c) => c.includes('data-local="ship-file-plan"'));

check('artifact-only spec gets a card keyed data-local="add-artifact-only"', !!artifactCard);
if (artifactCard) {
  check('artifact card href is the artifact URL', artifactCard.includes(`href="${ARTIFACT_URL}"`));
  check('artifact card opens a new tab', artifactCard.includes('target="_blank"'));
  check('artifact card carries rel="noopener"', artifactCard.includes('rel="noopener"'));
  check('artifact card carries the artifact chip',
    /class="artifact-chip"[^>]*>artifact</.test(artifactCard));
  check('artifact card carries the sr-only destination note',
    /opens on claude\.ai/.test(artifactCard));
  check('artifact card reads status from spec frontmatter',
    artifactCard.includes('data-status="in-progress"'));
  check('artifact card counts steps from the spec ([x] markers)',
    artifactCard.includes('data-steps-done="1"') && artifactCard.includes('data-steps-total="3"'));
}

check('sibling .html wins the card for ship-file-plan', !!fileCard);
if (fileCard) {
  check('file card href is the relative .html path', fileCard.includes('href="ship-file-plan.html"'));
  check('file card stays same-tab', !fileCard.includes('target="_blank"'));
}

check('keyless spec gets no card', !index.includes('draft-keyless'));
check('javascript: scheme spec gets no card', !index.includes('fix-evil-scheme'));
check('javascript: scheme is warned about on stderr',
  /fix-evil-scheme|non-http/i.test(build.stderr), build.stderr.trim() || '(empty stderr)');
check('session export with an artifact-url gets no card',
  !index.includes('add-thing-session'));
check('no card contains a nested anchor', cards.every((c) => !/<a[\s>]/.test(c.slice(2))));

// ── The other three galleries print the same Plans total ────────────────────
// Every gallery topbar shows a PLANS tab count, and each generator computes it
// off the filesystem rather than reading the plans index (they run in arbitrary
// order, so a parse would report whichever index happened to be stale). Three
// counters that do not know about artifact-only plans disagree with the plans
// page the moment the first one exists, which reads as data loss.
const tmplDir = join(TMP, 'kit', 'plugins', 'plan-agent', 'templates');
mkdirSync(tmplDir, { recursive: true });
const SIBLINGS = [
  ['build-artifacts-index.sh', 'artifacts', 'plans-gallery.html'],
  ['build-designs-index.sh', 'designs', 'designs-gallery.html'],
  ['build-prototypes-index.sh', 'prototypes', 'prototypes-gallery.html'],
];
for (const [, , tmpl] of new Set(SIBLINGS)) {
  copyFileSync(join(ROOT, 'kit/plugins/plan-agent/templates', tmpl), join(tmplDir, tmpl));
}
for (const [script, dir] of SIBLINGS) {
  mkdirSync(join(TMP, 'docs', dir), { recursive: true });
  // The artifacts generator skips an empty collection outright, so it needs one
  // item before it will render a topbar to read the Plans count off.
  if (dir === 'artifacts') {
    writeFileSync(join(TMP, 'docs', dir, 'sample.html'),
      '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Sample</title></head><body></body></html>\n');
  }
  const run = spawnSync('bash', [join(ROOT, 'kit/plugins/plan-agent/hooks', script), TMP], {
    encoding: 'utf8', env: { ...process.env, HOME: TMP, CLAUDE_PLUGIN_ROOT: '' },
  });
  let out = '';
  try { out = readFileSync(join(TMP, 'docs', dir, 'index.html'), 'utf8'); } catch { /* not written */ }
  const tabbed = Number(out.match(/Plans<span class="n">(\d+)/)?.[1]);
  check(`${script} prints the same Plans total as the gallery (${cards.length})`,
    tabbed === cards.length, `got ${tabbed}${run.status !== 0 ? ` (exit ${run.status}: ${run.stderr.trim()})` : ''}`);
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
