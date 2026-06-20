#!/usr/bin/env node
/**
 * Objective + unit test for scripts/extract-plan-spec.mjs and its shared
 * library scripts/lib/plan-spec.mjs.
 *
 * Objective (smoke): the extractor prints the plan spec on demand —
 *   - embedded-first: a legacy plan that still carries a #plan-digest block
 *     yields that digest UN-guarded (real </script>, clean markdown — not the
 *     raw awk bytes);
 *   - DOM-derive: a digest-free plan yields a spec built from the visible DOM
 *     with all the expected headings.
 * Unit: embedded-vs-DOM resolution, readEmbeddedDigest un-guards without
 * stopping early at a guarded sequence, the shared-lib import resolves, and the
 * CLI exits non-zero on missing/misused input.
 *
 * Run: node tests/plugins/test-extract-plan-spec.mjs
 */

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildDigest,
  extractSections,
  hasDigest,
  readEmbeddedDigest,
  unguardScriptClose,
} from '../../scripts/lib/plan-spec.mjs';
import { resolveSpec } from '../../scripts/extract-plan-spec.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const EXTRACTOR = join(ROOT, 'scripts', 'extract-plan-spec.mjs');

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

/** Minimal synthetic plan using the real generated selectors. */
function makePlan({ title = 'Extractor fixture plan', stepWhy = 'WHY ONE' } = {}) {
  return `<!DOCTYPE html>
<html lang="en" data-status="todo">
<head>
<meta name="plan-status" content="todo">
<title>Plan: ${title}</title>
<style>.x{color:red}</style>
</head>
<body>
<header><div class="objective-card" id="objective"><div class="section-label">Objective</div><p>OBJECTIVE TEXT for ${title}</p></div></header>
<main>
<section class="section-card" id="context" aria-labelledby="h-context"><h2 id="h-context">Context</h2><p>CONTEXT TEXT.</p></section>
<section class="section-card card-steps" id="steps" aria-labelledby="h-steps"><h2 id="h-steps">Steps</h2><div class="steps-list">
<div class="step-card"><div class="step-card-header"><div class="step-number">1</div><div class="step-body">
<div class="step-action"><span class="step-chip">todo</span> <span class="step-chip-text">STEP ONE ACTION</span></div>
<div class="step-why">${stepWhy}</div>
<details class="step-verify-toggle"><summary>Verify</summary><div class="verify-body">VERIFY ONE</div></details>
</div></div></div>
</div></section>
<section class="section-card card-tests" id="tests"><h2>Tests</h2><div class="test-tier-label">Tier 1 — Code-touching plan</div>
<div class="objective-test-card"><div class="test-card-header"><span class="test-badge test-badge-objective">Objective</span><span class="test-card-title">OBJ TEST</span></div><div class="test-card-body"><p><strong>File:</strong> <code>t.test.ts</code></p></div></div>
</section>
<section class="section-card" id="criteria"><h2>Criteria</h2><ul class="criteria-list" id="criteria-list">
<li><input type="checkbox" id="ac1"><label for="ac1">CRITERION ONE</label></li>
</ul></section>
<section class="section-card card-verification" id="verification" aria-labelledby="h-verification"><h2 id="h-verification">Verification</h2><p>VERIFICATION TEXT</p></section>
</main>
</body>
</html>
`;
}

/**
 * Embed a digest the way a legacy/backfilled plan does: a guiding comment that
 * quotes the awk one-liner (so `id="plan-digest"` appears BEFORE the real tag)
 * followed by the script block. A correct reader must skip the quoted mention.
 */
function makeEmbedded(plan, digest) {
  const block = [
    '',
    '<!-- MACHINE-READABLE DIGEST',
    `     awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\\/script>/{exit} f' <file> -->`,
    '<script type="text/markdown" id="plan-digest">',
    digest,
    '</script>',
  ].join('\n');
  return plan.replace(/(<body>)/, `$1${block}`);
}

console.log('=== Extract Plan Spec Test ===');

// A fixture whose step why quotes a literal closing-script tag (entity-escaped
// in HTML) so the guard/un-guard round-trip is actually exercised.
const GUARD_WHY = 'guard a literal &lt;/script&gt; sequence';
const plan = makePlan({ stepWhy: GUARD_WHY });
const sections = extractSections(plan);
const guardedDigest = buildDigest(sections);

console.log('-- objective: embedded-first yields the UN-guarded spec --');

ok('extractor returns the embedded digest, un-guarded (not awk-byte-identical)', () => {
  const embedded = makeEmbedded(plan, guardedDigest);
  assert.ok(hasDigest(embedded), 'fixture should register as having a digest');
  const expected = unguardScriptClose(guardedDigest).trim();
  assert.equal(resolveSpec(embedded), expected);
  // The guard round-trip must have actually happened on this fixture.
  assert.ok(guardedDigest.includes('<\\/script'), 'precondition: digest carries a guarded sequence');
  assert.notEqual(expected, guardedDigest, 'output must differ from the raw guarded bytes');
});

ok('embedded output un-guards: real </script>, no guarded <\\/script, reaches the end', () => {
  const out = resolveSpec(makeEmbedded(plan, guardedDigest));
  assert.ok(out.includes('</script>'), 'expected a real closing-script tag');
  assert.ok(!out.includes('<\\/script'), 'guarded sequence must be reversed');
  assert.match(out, /## Verification\nVERIFICATION TEXT/, 'extraction must reach past the guarded sequence');
});

console.log('-- objective: DOM-derive fallback for digest-free plans --');

ok('digest-free plan derives a spec from the DOM with all headings', () => {
  const domPlan = makePlan({});
  assert.ok(!hasDigest(domPlan), 'fixture should be digest-free');
  const out = resolveSpec(domPlan);
  for (const heading of ['# Plan:', '## Objective', '## Steps', '## Acceptance Criteria', '## Verification', '## Tests']) {
    assert.ok(out.includes(heading), `DOM-derived spec missing "${heading}"`);
  }
  assert.match(out, /1\. STEP ONE ACTION Why: WHY ONE Verify: VERIFY ONE/, 'numbered step missing');
});

console.log('-- unit: resolution + readEmbeddedDigest + lib --');

ok('embedded-first beats the DOM (precedence)', () => {
  // Embed a sentinel digest whose title differs from the DOM title; the
  // extractor must return the embedded sentinel, not a DOM re-derivation.
  const sentinel = '# Plan: EMBEDDED SENTINEL\n\n## Objective\nfrom the embedded block';
  const embedded = makeEmbedded(makePlan({ title: 'DOM TITLE' }), sentinel);
  const out = resolveSpec(embedded);
  assert.match(out, /EMBEDDED SENTINEL/);
  assert.ok(!out.includes('DOM TITLE'), 'must not fall through to the DOM when a digest is present');
});

ok('readEmbeddedDigest skips the quoted one-liner and un-guards without stopping early', () => {
  const embedded = makeEmbedded(plan, guardedDigest);
  const inner = readEmbeddedDigest(embedded);
  assert.match(inner, /^# Plan:/, 'must target the real digest tag, not the quoted comment');
  assert.ok(inner.includes('</script>') && !inner.includes('<\\/script'), 'must un-guard');
  assert.match(inner, /## Verification/, 'must not stop at the guarded sequence');
});

ok('readEmbeddedDigest returns null when there is no digest', () => {
  assert.equal(readEmbeddedDigest(makePlan({})), null);
});

ok('unguardScriptClose is the inverse of the guard', () => {
  const raw = 'a </script> b </SCRIPT x';
  assert.equal(unguardScriptClose('a <\\/script> b <\\/SCRIPT x'), raw);
});

ok('the shared lib import resolves with the expected exports', async () => {
  const lib = await import('../../scripts/lib/plan-spec.mjs');
  for (const name of ['hasDigest', 'extractSections', 'buildDigest', 'guardScriptClose', 'unguardScriptClose', 'readEmbeddedDigest']) {
    assert.equal(typeof lib[name], 'function', `lib missing export ${name}`);
  }
});

console.log('-- unit: CLI contract --');

const tmp = mkdtempSync(join(tmpdir(), 'extract-plan-spec-'));
try {
  const planFile = join(tmp, 'plan.html');
  writeFileSync(planFile, makePlan({}));

  ok('CLI prints DOM-derived spec and exits 0', () => {
    const out = execFileSync('node', [EXTRACTOR, planFile], { encoding: 'utf8' });
    assert.match(out, /## Objective/);
    assert.match(out, /## Verification/);
  });

  ok('CLI exits non-zero on a missing file', () => {
    assert.throws(
      () => execFileSync('node', [EXTRACTOR, join(tmp, 'nope.html')], { stdio: 'pipe' }),
      (err) => err.status === 1,
    );
  });

  ok('CLI exits non-zero with no argument', () => {
    assert.throws(
      () => execFileSync('node', [EXTRACTOR], { stdio: 'pipe' }),
      (err) => err.status === 2,
    );
  });

  ok('CLI exits non-zero on an unparseable plan', () => {
    const broken = join(tmp, 'broken.html');
    writeFileSync(broken, makePlan({}).replace('id="objective"', 'id="nope"'));
    assert.throws(
      () => execFileSync('node', [EXTRACTOR, broken], { stdio: 'pipe' }),
      (err) => err.status === 1,
    );
  });
} finally {
  rmSync(tmp, { recursive: true, force: true });
}

console.log('');
if (process.exitCode) {
  console.error('Extract plan spec test FAILED.');
} else {
  console.log(`All ${passed} extract-plan-spec checks passed.`);
}
