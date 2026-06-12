#!/usr/bin/env node
/**
 * Unit + integration test for scripts/backfill-plan-digests.mjs.
 *
 * Unit: hasDigest(), guardScriptClose(), extractSections(), buildDigest().
 * Integration: runBackfill() over a temp corpus (synthetic plans + a copy of
 * the real docs/plans) — every parseable file gains a digest, a pre-seeded
 * file is skipped, an unparseable plan is skipped and listed (no partial
 * digest), literal closing-script sequences are guarded on injection,
 * status/checkbox bytes are untouched, and a second run injects 0.
 *
 * Run: node tests/plugins/test-backfill-digest.mjs
 */

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildDigest,
  extractSections,
  guardScriptClose,
  hasDigest,
  injectDigest,
  runBackfill,
} from '../../scripts/backfill-plan-digests.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const REAL_PLANS_DIR = join(ROOT, 'docs', 'plans');

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

// The canonical extractor from the digest contract, used to verify
// round-tripping of injected digests.
function awkExtract(file) {
  return execFileSync(
    'awk',
    ['!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\\/script>/{exit} f', file],
    { encoding: 'utf8' },
  );
}

/** Minimal synthetic plan using the real generated selectors. */
function makePlan({ title = 'Test fixture plan', status = 'todo', stepWhy = 'WHY ONE', checked = '' } = {}) {
  return `<!DOCTYPE html>
<html lang="en" data-status="${status}">
<head>
<meta name="plan-status" content="${status}">
<title>Plan: ${title}</title>
<style>.x{color:red}</style>
</head>
<body>
<header><div class="objective-card" id="objective"><div class="section-label">Objective</div><p>OBJECTIVE TEXT for ${title}</p></div></header>
<main>
<section class="section-card" id="context" aria-labelledby="h-context"><h2 id="h-context">Context</h2><p>CONTEXT TEXT &amp; entities &lt;kept&gt;.</p></section>
<section class="section-card card-files" id="files"><h2>Files</h2><div class="file-tree"><div class="file-tree-root">repo/</div><ul class="file-list">
<li class="file-dir">src/</li>
<ul class="file-list"><li><code>a.ts</code> <span class="file-badge file-badge-new">new</span> <span class="file-note">note A</span></li></ul>
<li><code>scripts/c.mjs</code> <span class="file-badge file-badge-modified">modified</span> <span class="file-note">note C</span></li>
</ul></div></section>
<section class="section-card card-steps" id="steps" aria-labelledby="h-steps"><h2 id="h-steps">Steps</h2><div class="steps-list">
<div class="step-card${status === 'completed' ? ' completed' : ''}"><div class="step-card-header"><div class="step-number">1</div><div class="step-body">
<div class="step-action"><span class="step-chip">todo</span> <span class="step-chip-text">STEP ONE ACTION</span></div>
<div class="step-why">${stepWhy}</div>
<details class="step-verify-toggle"><summary>Verify</summary><div class="verify-body">VERIFY ONE</div></details>
</div></div></div>
</div></section>
<section class="section-card card-tests" id="tests"><h2>Tests</h2><div class="test-tier-label">Tier 1 — Code-touching plan</div>
<div class="objective-test-card"><div class="test-card-header"><span class="test-badge test-badge-objective">Objective</span><span class="test-card-title">OBJ TEST</span></div><div class="test-card-body"><p><strong>File:</strong> <code>t.test.ts</code></p></div></div>
<div class="test-list"><div class="test-card"><div class="test-card-header"><span class="test-badge test-badge-unit">Unit</span><span class="test-card-title">UNIT TEST</span></div><div class="test-card-body"><p><strong>Targets:</strong> <code>u.ts</code></p></div></div></div>
</section>
<section class="section-card" id="criteria"><h2>Criteria</h2><ul class="criteria-list" id="criteria-list">
<li><input type="checkbox" id="ac1"${checked}><label for="ac1">CRITERION ONE</label></li>
</ul></section>
<section class="section-card card-verification" id="verification" aria-labelledby="h-verification"><h2 id="h-verification">Verification</h2><p>VERIFICATION TEXT</p></section>
</main>
</body>
</html>
`;
}

console.log('=== Backfill Digest Test ===');
console.log('-- unit: hasDigest --');

ok('detects a real digest opening tag', () => {
  assert.equal(hasDigest('<script type="text/markdown" id="plan-digest">x</script>'), true);
});

ok('ignores a quoted extractor one-liner (idempotency keystone)', () => {
  const quoted = `<!-- awk '!f && /<script[^>]*id="plan-digest"/{f=1;next}' -->`;
  assert.equal(hasDigest(quoted), false);
});

ok('ignores entity-escaped mentions in plan prose', () => {
  assert.equal(hasDigest('&lt;script type="text/markdown" id="plan-digest"&gt;'), false);
});

console.log('-- unit: guardScriptClose --');

ok('guards literal closing-script sequences, case-insensitively', () => {
  assert.equal(guardScriptClose('a </script> b </SCRIPT x'), 'a <\\/script> b <\\/SCRIPT x');
});

ok('leaves already-guarded sequences intact', () => {
  assert.equal(guardScriptClose('safe <\\/script> text'), 'safe <\\/script> text');
});

console.log('-- unit: extractSections / buildDigest --');

ok('extracts every spec section from a synthetic plan', () => {
  const s = extractSections(makePlan({}));
  assert.equal(s.title, 'Test fixture plan');
  assert.match(s.objective, /OBJECTIVE TEXT/);
  assert.match(s.context, /CONTEXT TEXT & entities <kept>\./);
  assert.deepEqual(s.files.map((f) => f.path), ['src/a.ts', 'scripts/c.mjs']);
  assert.deepEqual(s.files.map((f) => f.badge), ['new', 'modified']);
  assert.equal(s.steps.length, 1);
  assert.equal(s.steps[0].action, 'STEP ONE ACTION');
  assert.equal(s.steps[0].why, 'WHY ONE');
  assert.equal(s.steps[0].verify, 'VERIFY ONE');
  assert.match(s.tests.tier, /Tier 1/);
  assert.equal(s.tests.entries.length, 2);
  assert.deepEqual(s.criteria, ['CRITERION ONE']);
  assert.match(s.verification, /VERIFICATION TEXT/);
});

ok('rejects a plan with no objective (no partial digests)', () => {
  const broken = makePlan({}).replace('id="objective"', 'id="not-objective"');
  assert.throws(() => extractSections(broken), /no objective element/);
});

ok('rejects a step without why text', () => {
  const broken = makePlan({ stepWhy: '' });
  assert.throws(() => extractSections(broken), /step 1 has no why text/);
});

ok('buildDigest renders the spec and applies the closing-script guard', () => {
  const digest = buildDigest(extractSections(makePlan({ stepWhy: 'why with literal &lt;/script&gt; quoted' })));
  assert.match(digest, /^# Plan: Test fixture plan/);
  assert.match(digest, /## Objective/);
  assert.match(digest, /- src\/a\.ts \(new\) — note A/);
  assert.match(digest, /1\. STEP ONE ACTION Why: why with literal <\\\/script> quoted Verify: VERIFY ONE/);
  assert.match(digest, /- CRITERION ONE/);
  assert.ok(!digest.includes('</script'), 'digest must not contain an unguarded closing-script sequence');
  assert.ok(!/todo|checkbox/.test(digest), 'digest must not carry status or checkbox state');
});

ok('injectDigest places the block as first element child of <body>', () => {
  const html = injectDigest(makePlan({}), 'DIGEST BODY');
  const body = html.split(/<\/head>\s*<body[^>]*>/)[1];
  const noComment = body.replace(/<!--[\s\S]*?-->/g, '');
  const firstTag = noComment.match(/<[a-zA-Z][^>]*>/)[0];
  assert.equal(firstTag, '<script type="text/markdown" id="plan-digest">');
});

console.log('-- integration: synthetic corpus --');

const tmp = mkdtempSync(join(tmpdir(), 'backfill-digest-'));
try {
  writeFileSync(join(tmp, 'normal-plan.html'), makePlan({ title: 'Normal plan' }));
  writeFileSync(
    join(tmp, 'completed-plan.html'),
    makePlan({ title: 'Completed plan', status: 'completed', checked: ' checked' }),
  );
  writeFileSync(
    join(tmp, 'guarded-plan.html'),
    makePlan({ title: 'Guarded plan', stepWhy: 'quotes a literal &lt;/script&gt; tag' }),
  );
  writeFileSync(join(tmp, 'preseeded-plan.html'), injectDigest(makePlan({ title: 'Preseeded plan' }), 'EXISTING DIGEST'));
  writeFileSync(join(tmp, 'broken-plan.html'), makePlan({ title: 'Broken plan' }).replace('id="objective"', 'id="nope"'));
  writeFileSync(join(tmp, 'index.html'), '<html><body>gallery, not a plan</body></html>');
  const originals = Object.fromEntries(
    readdirSync(tmp).map((n) => [n, readFileSync(join(tmp, n), 'utf8')]),
  );

  ok('dry run reports without writing', () => {
    const r = runBackfill(tmp, { dryRun: true });
    assert.deepEqual(r.injected.sort(), ['completed-plan.html', 'guarded-plan.html', 'normal-plan.html']);
    for (const [name, content] of Object.entries(originals)) {
      assert.equal(readFileSync(join(tmp, name), 'utf8'), content, `${name} modified by dry run`);
    }
  });

  let firstRun;
  ok('real run injects every parseable plan and reports the rest', () => {
    firstRun = runBackfill(tmp, { dryRun: false });
    assert.deepEqual(firstRun.injected.sort(), ['completed-plan.html', 'guarded-plan.html', 'normal-plan.html']);
    assert.deepEqual(firstRun.hasDigest, ['preseeded-plan.html']);
    assert.equal(firstRun.unparseable.length, 1);
    assert.equal(firstRun.unparseable[0].file, 'broken-plan.html');
    assert.match(firstRun.unparseable[0].reason, /no objective/);
    assert.equal(firstRun.failed.length, 0);
  });

  ok('index.html, pre-seeded, and unparseable files are byte-identical', () => {
    for (const name of ['index.html', 'preseeded-plan.html', 'broken-plan.html']) {
      assert.equal(readFileSync(join(tmp, name), 'utf8'), originals[name], `${name} was modified`);
    }
  });

  const INJECTED_BLOCK_RE = /\n\n<!-- ═+\n     MACHINE-READABLE DIGEST \(backfilled\)[\s\S]*?\n<\/script>/;

  ok('injection is insertion-only: status and checkbox bytes unchanged', () => {
    for (const name of ['normal-plan.html', 'completed-plan.html', 'guarded-plan.html']) {
      const now = readFileSync(join(tmp, name), 'utf8');
      assert.ok(hasDigest(now), `${name} did not gain a digest`);
      const withoutBlock = now.replace(INJECTED_BLOCK_RE, '');
      assert.equal(withoutBlock, originals[name], `${name} has byte changes beyond the inserted block`);
    }
    const completed = readFileSync(join(tmp, 'completed-plan.html'), 'utf8');
    assert.match(completed, /data-status="completed"/);
    assert.match(completed, /<input type="checkbox" id="ac1" checked>/);
  });

  ok('a guarded closing-script sequence cannot end the block early', () => {
    const extracted = awkExtract(join(tmp, 'guarded-plan.html'));
    assert.match(extracted, /quotes a literal <\\\/script> tag/);
    assert.match(extracted, /## Verification/, 'extraction must reach the end of the digest');
  });

  ok('the canonical awk round-trips an injected digest', () => {
    const extracted = awkExtract(join(tmp, 'normal-plan.html'));
    assert.match(extracted, /# Plan: Normal plan/);
    assert.match(extracted, /OBJECTIVE TEXT/);
    assert.match(extracted, /VERIFICATION TEXT/);
  });

  ok('second run injects 0 (idempotent)', () => {
    const r2 = runBackfill(tmp, { dryRun: false });
    assert.equal(r2.injected.length, 0);
    assert.equal(r2.hasDigest.length, 4);
  });
} finally {
  rmSync(tmp, { recursive: true, force: true });
}

console.log('-- integration: real docs/plans corpus (temp copy) --');

const tmpReal = mkdtempSync(join(tmpdir(), 'backfill-digest-real-'));
try {
  // The working tree's plans are already backfilled. Strip backfilled blocks
  // from the temp copies so the test always exercises injection from the
  // pre-digest state; hand-authored digests (different comment) stay put and
  // are counted as hasDigest skips.
  const BACKFILLED_BLOCK_RE = /\n\n<!-- ═+\n     MACHINE-READABLE DIGEST \(backfilled\)[\s\S]*?\n<\/script>/;
  for (const e of readdirSync(REAL_PLANS_DIR, { withFileTypes: true })) {
    if (e.isFile() && e.name.endsWith('.html')) {
      const content = readFileSync(join(REAL_PLANS_DIR, e.name), 'utf8');
      writeFileSync(join(tmpReal, e.name), content.replace(BACKFILLED_BLOCK_RE, ''));
    }
  }
  const originals = Object.fromEntries(
    readdirSync(tmpReal).map((n) => [n, readFileSync(join(tmpReal, n), 'utf8')]),
  );

  ok('backfills the real corpus with no I/O failures', () => {
    const r = runBackfill(tmpReal, { dryRun: false });
    assert.equal(r.failed.length, 0);
    assert.ok(r.injected.length >= 30, `expected >=30 injected, got ${r.injected.length}`);
    for (const { file, reason } of r.unparseable) {
      assert.ok(reason.length > 0, `${file} skipped without a reason`);
      assert.equal(readFileSync(join(tmpReal, file), 'utf8'), originals[file], `${file} skipped but modified`);
    }
    const INJECTED_BLOCK_RE = /\n\n<!-- ═+\n     MACHINE-READABLE DIGEST \(backfilled\)[\s\S]*?\n<\/script>/;
    for (const file of r.injected) {
      const now = readFileSync(join(tmpReal, file), 'utf8');
      assert.equal(now.replace(INJECTED_BLOCK_RE, ''), originals[file], `${file} changed beyond the inserted block`);
      const extracted = awkExtract(join(tmpReal, file));
      assert.match(extracted, /## Objective/, `${file}: extracted digest lacks an Objective`);
      assert.match(extracted, /## Verification/, `${file}: extracted digest lacks a Verification`);
    }
  });

  ok('real corpus second run injects 0 (idempotent)', () => {
    const r2 = runBackfill(tmpReal, { dryRun: false });
    assert.equal(r2.injected.length, 0);
  });
} finally {
  rmSync(tmpReal, { recursive: true, force: true });
}

console.log('');
if (process.exitCode) {
  console.error('Backfill digest test FAILED.');
} else {
  console.log(`All ${passed} backfill-digest checks passed.`);
}
