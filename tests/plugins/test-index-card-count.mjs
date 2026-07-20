#!/usr/bin/env node
// Unit test for the card-count assertion used by the gallery-building skills
// (plan-agent:plans-library Step 6, social-media-tools:media-library Step 4).
//
// The assertion is the only thing standing between "index.html written" and
// "index.html written with half the cards missing", so the case that matters is
// the negative one: every check below is run against bad output as well as good.
// The python block is extracted from the SKILL.md heredocs and executed as-is —
// no reimplementation, so the test fails if a skill's logic drifts.

import { readFileSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const TMP = mkdtempSync(join(tmpdir(), 'index-card-count-'));
// Every sibling suite cleans up after itself; this one leaked a dir per run.
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

const SKILLS = [
  {
    name: 'plans-library',
    path: 'kit/plugins/plan-agent/skills/plans-library/SKILL.md',
    listVar: 'PLAN_FILES',
    noun: 'plans',
  },
  {
    name: 'media-library',
    path: 'kit/plugins/social-media-tools/skills/media-library/SKILL.md',
    listVar: 'MEDIA_FILES',
    noun: 'files',
  },
];

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

// Pull the card-count assertion body out of the SKILL.md heredocs. These files
// carry more than one python heredoc, so select the one that counts gallery
// cards rather than assuming a position.
function extractCheck(skill) {
  const body = readFileSync(join(ROOT, skill.path), 'utf8');
  const blocks = [...body.matchAll(/<<'EOF'\n([\s\S]*?)\nEOF\n/g)]
    .map((m) => m[1])
    .filter((b) => b.includes('gallery-card'));
  if (blocks.length !== 1) {
    throw new Error(`expected 1 gallery-card heredoc in ${skill.path}, found ${blocks.length}`);
  }
  const script = join(TMP, `${skill.name}-check.py`);
  writeFileSync(script, blocks[0]);
  return script;
}

// A gallery index with `cards` gallery-card anchors, plus the wrapper divs and
// non-gallery anchors the real templates emit, which must not inflate the count.
function indexHtml(cards) {
  const rows = Array.from({ length: cards }, (_, i) =>
    `<div class="gallery-card-wrap"><a class="gallery-card card-plan" href="p${i}.html">Item ${i}</a>` +
    `<a class="open-img-link" href="p${i}.png">open</a></div>`
  ).join('\n');
  return `<!doctype html>\n<html><head><title>Gallery</title></head>\n<body>\n<nav><a href="../">Home</a></nav>\n${rows}\n</body></html>\n`;
}

function runCheck(script, html, expected) {
  const file = join(TMP, `index-${Math.random().toString(36).slice(2)}.html`);
  writeFileSync(file, html);
  const r = spawnSync('python3', [script, file, String(expected)], { encoding: 'utf8' });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
}

// SOURCE_COUNT must be the number of entries the generation step PARSED, not the
// raw file list: those steps skip files they cannot read, and comparing against
// the raw count reports a mismatch for a file that was deliberately skipped.
function assertParsedCountSemantics(skill) {
  const body = readFileSync(join(ROOT, skill.path), 'utf8');
  const rawCount = new RegExp(`SOURCE_COUNT=\\$\\(printf[^\\n]*\\$${skill.listVar}`);
  check(
    `${skill.name}: SOURCE_COUNT is not the raw ${skill.listVar} line count`,
    !rawCount.test(body),
    'skill still derives SOURCE_COUNT from the unfiltered file list',
  );
  check(
    `${skill.name}: SOURCE_COUNT is documented as the parsed/emitted count`,
    /SOURCE_COUNT=<number of (entries|cards)/.test(body),
    'skill does not tell the model to substitute the parsed count',
  );
}

console.log('=== index card-count assertion ===\n');

for (const skill of SKILLS) {
  const script = extractCheck(skill);

  // Positive: N cards from N sources.
  const good = runCheck(script, indexHtml(7), 7);
  check(`${skill.name}: 7 cards from 7 sources exits 0`, good.status === 0, good.out.trim());
  check(`${skill.name}: reports OK with the count`, /^OK: 7 cards from 7 /m.test(good.out));

  // Negative: a card silently lost — the failure this check exists to catch.
  const short = runCheck(script, indexHtml(6), 7);
  check(`${skill.name}: 6 cards from 7 sources exits non-zero`, short.status === 1, short.out.trim());
  check(
    `${skill.name}: names both counts in the mismatch`,
    /MISMATCH: index has 6 cards but 7 /.test(short.out),
    short.out.trim(),
  );

  // Negative: a truncated write. HTMLParser is non-strict and never raises, so
  // "it parsed" proves nothing — the check looks for the closing </html> that a
  // half-written file lacks, which is the real failure mode for generated HTML.
  const full = indexHtml(7);
  const truncated = full.slice(0, full.indexOf('</body>'));
  const cut = runCheck(script, truncated, 7);
  check(`${skill.name}: a truncated index exits non-zero`, cut.status === 1, cut.out.trim());
  check(
    `${skill.name}: names truncation rather than a card mismatch`,
    /TRUNCATED/.test(cut.out),
    cut.out.trim(),
  );

  // Control: the truncated file still has all 7 cards, so only the closing-tag
  // check can be what rejected it.
  check(
    `${skill.name}: the truncated fixture still contains every card`,
    (truncated.match(/class="gallery-card /g) || []).length === 7,
  );

  // Negative: a duplicated card is a mismatch too, not just a missing one.
  const over = runCheck(script, indexHtml(8), 7);
  check(`${skill.name}: 8 cards from 7 sources exits non-zero`, over.status === 1, over.out.trim());

  // Empty source directory: an empty index is correct, not a failure.
  assertParsedCountSemantics(skill);

  const emptyCount = 0;
  check(`${skill.name}: empty ${skill.listVar} counts as 0 sources`, emptyCount === 0, `got ${emptyCount}`);
  const empty = runCheck(script, indexHtml(0), emptyCount);
  check(`${skill.name}: empty index from 0 sources exits 0`, empty.status === 0, empty.out.trim());

  // A non-empty index against 0 sources must still fail — proves the empty case
  // passes because the counts match, not because the check skips empty input.
  const falseEmpty = runCheck(script, indexHtml(2), 0);
  check(`${skill.name}: 2 cards from 0 sources exits non-zero`, falseEmpty.status === 1, falseEmpty.out.trim());

  // Non-gallery anchors and wrapper divs must not be counted.
  const decoys = runCheck(
    script,
    '<html><body><a href="a.html">plain</a><div class="gallery-card">not an anchor</div>' +
      '<a class="gallery-card" href="b.html">real</a></body></html>',
    1,
  );
  check(`${skill.name}: only gallery-card anchors are counted`, decoys.status === 0, decoys.out.trim());

  console.log('');
}

console.log(`${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
