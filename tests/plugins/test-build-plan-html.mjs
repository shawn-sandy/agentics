#!/usr/bin/env node
/**
 * Objective + unit + integration tests for the Markdown-spec-to-HTML plan
 * renderer: scripts/build-plan-html.mjs, parseSpecMarkdown() in
 * scripts/lib/plan-spec.mjs, the presentation shell scripts/lib/plan-shell.mjs,
 * and the kit/plugins/plan-agent/hooks/render-plan-html.py regeneration hook.
 *
 * Objective (smoke): rendered plan HTML re-extracts to an identical spec —
 * for every committed plan in docs/plans/ whose sections extract cleanly,
 * extract → buildDigest → parseSpecMarkdown → renderPlanHtml → extractSections
 * produces a deep-equal sections object (modulo the documented, deliberately
 * non-injective closing-script guard). At least 10 plans must round-trip.
 *
 * Also pinned: the three frozen shell strings, the required plan-* meta tags,
 * zero unfilled skeleton placeholder tokens, effort derivation thresholds,
 * CLI exit codes, and the hook's plansDirectory settings precedence
 * (settings.local.json → settings.json → global → docs/plans).
 *
 * Run: node tests/plugins/test-build-plan-html.mjs
 */

import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildDigest,
  extractSections,
  parseSpecMarkdown,
  ParseError,
  unguardScriptClose,
} from '../../scripts/lib/plan-spec.mjs';
import { deriveEffort, renderPlanHtml } from '../../scripts/build-plan-html.mjs';
import { GOAL_LABEL, NO_ITEMS_REPORT, STEP_CHIP } from '../../scripts/lib/plan-shell.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const HOOK = join(ROOT, 'kit', 'plugins', 'plan-agent', 'hooks', 'render-plan-html.py');
const PLANS_DIR = join(ROOT, 'docs', 'plans');

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

const SAMPLE_SPEC = `---
status: todo
type: feature
created: 2026-07-12
repo: sample-repo
glance: A short plain-language summary of the work.
---
# Plan: Ship a sample feature

## Objective
Ship the sample feature end to end.

## Context
First paragraph of context.

Second paragraph after a blank line.

## Files
- scripts/a.mjs (new) — the new module
- scripts/b.mjs (modified)

## Steps
1. Do the first thing. Why: because it unblocks everything. Verify: run the check.
2. Do the second thing. Why: because the first is not enough. Verify: run the other check.

## Tests
Tier 1 — This plan changes application code
- Objective Sample objective test File: tests/x.mjs Run: node tests/x.mjs
- Unit Sample unit test File: tests/y.mjs

## Acceptance Criteria
- The first criterion holds.
- The second criterion holds.

## Verification
Run everything and confirm it all passes.
`;

function bigSpec(stepCount) {
  const steps = Array.from({ length: stepCount }, (_, i) => `${i + 1}. Do thing ${i + 1}. Why: reason ${i + 1}. Verify: check ${i + 1}.`).join('\n');
  return `# Plan: A larger plan

## Objective
Do many things.

## Steps
${steps}

## Acceptance Criteria
- All the things are done.

## Verification
Confirm all the things.
`;
}

/** The guard is deliberately non-injective; normalize expected sections the
 * same way extract-plan-spec.mjs normalizes its printed output. */
const norm = (v) =>
  typeof v === 'string'
    ? unguardScriptClose(v)
    : Array.isArray(v)
      ? v.map(norm)
      : v && typeof v === 'object'
        ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, norm(x)]))
        : v;

/* ── Unit: parseSpecMarkdown ──────────────────────────────────────── */

ok('parseSpecMarkdown maps frontmatter to metadata', () => {
  const { metadata } = parseSpecMarkdown(SAMPLE_SPEC);
  assert.equal(metadata.status, 'todo');
  assert.equal(metadata.type, 'feature');
  assert.equal(metadata.created, '2026-07-12');
  assert.equal(metadata.repo, 'sample-repo');
  assert.equal(metadata.glance, 'A short plain-language summary of the work.');
});

ok('parseSpecMarkdown splits numbered steps into action/why/verify', () => {
  const { sections } = parseSpecMarkdown(SAMPLE_SPEC);
  assert.equal(sections.steps.length, 2);
  assert.deepEqual(sections.steps[0], {
    action: 'Do the first thing.',
    why: 'because it unblocks everything.',
    verify: 'run the check.',
  });
});

ok('parseSpecMarkdown parses Files entries to path/badge/note', () => {
  const { sections } = parseSpecMarkdown(SAMPLE_SPEC);
  assert.deepEqual(sections.files, [
    { path: 'scripts/a.mjs', badge: 'new', note: 'the new module' },
    { path: 'scripts/b.mjs', badge: 'modified', note: '' },
  ]);
});

ok('parseSpecMarkdown parses Tests tier and entries; prose falls back', () => {
  const { sections } = parseSpecMarkdown(SAMPLE_SPEC);
  assert.equal(sections.tests.tier, 'Tier 1 — This plan changes application code');
  assert.equal(sections.tests.entries.length, 2);
  assert.equal(sections.tests.prose, null);
  const prose = parseSpecMarkdown(SAMPLE_SPEC.replace(/## Tests[\s\S]*?## Acceptance/, '## Tests\nJust prose, no cards.\n\n## Acceptance'));
  assert.deepEqual(prose.sections.tests, { tier: null, entries: [], prose: 'Just prose, no cards.' });
});

ok('parseSpecMarkdown raises ParseError on missing required sections', () => {
  for (const heading of ['## Objective', '## Steps', '## Acceptance Criteria', '## Verification']) {
    const mutated = SAMPLE_SPEC.replace(heading, '## Removed');
    assert.throws(() => parseSpecMarkdown(mutated), ParseError, `expected ParseError without ${heading}`);
  }
  assert.throws(() => parseSpecMarkdown('no title here'), ParseError);
});

ok('parseSpecMarkdown inverts buildDigest for a synthetic sections object', () => {
  const { sections } = parseSpecMarkdown(SAMPLE_SPEC);
  const again = parseSpecMarkdown(unguardScriptClose(buildDigest(sections)));
  assert.deepEqual(again.sections, sections);
});

/* ── Unit: renderer + shell ───────────────────────────────────────── */

const sampleParsed = parseSpecMarkdown(SAMPLE_SPEC);
const sampleHtml = renderPlanHtml(sampleParsed, { fileName: 'sample.html', planPath: 'docs/plans/sample.html', repo: 'sample-repo' });

ok('rendered sample re-extracts to the identical sections object', () => {
  assert.deepEqual(extractSections(sampleHtml), sampleParsed.sections);
});

ok('derived effort follows the skill thresholds', () => {
  assert.equal(deriveEffort(3, 2), 'low');
  assert.equal(deriveEffort(4, 2), 'medium');
  assert.equal(deriveEffort(3, 3), 'medium');
  assert.equal(deriveEffort(7, 0), 'high');
  assert.equal(deriveEffort(1, 6), 'high');
  assert.ok(sampleHtml.includes('data-effort="low"'), '2-step 2-file spec renders low');
  const big = renderPlanHtml(parseSpecMarkdown(bigSpec(7)), { fileName: 'big.html', planPath: 'big.html' });
  assert.ok(big.includes('data-effort="high"'), '7-step spec renders high');
});

ok('implement and goal meta tags quote title and relative path verbatim', () => {
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-implement" content="Read and implement all steps in the plan at docs/plans/sample.html — Ship a sample feature">'
    )
  );
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-goal" content="Achieve this goal: Ship a sample feature. The plan at docs/plans/sample.html describes one approach — use it as reference, but optimize for the outcome">'
    )
  );
});

ok('workflow meta tag omitted for small specs, present for wide ones', () => {
  // The CSS always carries the .plan-workflow rules; only the meta tag and
  // drawer row are conditional.
  assert.ok(!sampleHtml.includes('<meta name="plan-workflow"'), 'sample spec (2 files, 1 dir) has no workflow meta');
  assert.ok(!sampleHtml.includes('id="workflow-cmd"'), 'sample spec has no workflow drawer row');
  const wide = parseSpecMarkdown(SAMPLE_SPEC.replace(
    /## Files[\s\S]*?## Steps/,
    '## Files\n- a/one.mjs (new)\n- b/two.mjs (new)\n- c/three.mjs (new)\n- d/four.mjs (new)\n- e/five.mjs (new)\n\n## Steps'
  ));
  const wideHtml = renderPlanHtml(wide, { fileName: 'w.html', planPath: 'w.html' });
  assert.ok(wideHtml.includes('<meta name="plan-workflow" content="Run a workflow to implement the plan at w.html'));
});

ok('frozen strings survive byte-for-byte in shell and rendered output', () => {
  assert.equal(STEP_CHIP, '<span class="step-chip">todo</span>');
  assert.equal(NO_ITEMS_REPORT, 'No items to report — all requirements met.');
  assert.equal(GOAL_LABEL, 'Pursue as goal — optimize for the outcome');
  for (const frozen of [STEP_CHIP, NO_ITEMS_REPORT, GOAL_LABEL]) {
    assert.ok(sampleHtml.includes(frozen), `rendered output carries: ${frozen}`);
  }
});

ok('rendered output has every required plan-* meta tag and no unfilled placeholders', () => {
  for (const name of ['status', 'effort', 'type', 'created', 'repo', 'file', 'path', 'implement', 'goal']) {
    assert.ok(sampleHtml.includes(`<meta name="plan-${name}" content="`), `plan-${name} present`);
  }
  const leftovers = sampleHtml.match(/\{[a-z][a-z0-9-]*\}/g);
  assert.equal(leftovers, null, `unfilled skeleton tokens: ${leftovers}`);
});

ok('sidebar nav is filtered to the sections actually present', () => {
  const links = [...sampleHtml.matchAll(/<a href="#([a-z-]+)">/g)].map((m) => m[1]);
  assert.deepEqual(links, ['objective', 'progress', 'context', 'files', 'steps', 'tests', 'criteria', 'verification', 'completion']);
  const minimal = renderPlanHtml(parseSpecMarkdown(bigSpec(2)), { fileName: 'm.html', planPath: 'm.html' });
  const minLinks = [...minimal.matchAll(/<a href="#([a-z-]+)">/g)].map((m) => m[1]);
  assert.deepEqual(minLinks, ['objective', 'progress', 'steps', 'criteria', 'verification', 'completion']);
});

ok('spec text is HTML-escaped in the rendered output', () => {
  const hostile = parseSpecMarkdown(bigSpec(2).replace('Do many things.', 'Guard <script>alert("x")</script> & more.'));
  const html = renderPlanHtml(hostile, { fileName: 'h.html', planPath: 'h.html' });
  assert.ok(html.includes('Guard &lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; more.'));
  assert.equal(extractSections(html).objective, 'Guard <script>alert("x")</script> & more.');
});

/* ── Integration: CLI ─────────────────────────────────────────────── */

const tmp = mkdtempSync(join(tmpdir(), 'build-plan-html-'));

ok('CLI renders a spec to the -o output file', () => {
  const spec = join(tmp, 'cli-sample.md');
  const out = join(tmp, 'cli-sample-out.html');
  writeFileSync(spec, SAMPLE_SPEC);
  execFileSync('node', [RENDERER, spec, '-o', out]);
  const html = readFileSync(out, 'utf8');
  assert.ok(html.startsWith('<!DOCTYPE html>'));
  assert.deepEqual(extractSections(html), sampleParsed.sections);
  assert.ok(html.includes('<meta name="plan-file" content="cli-sample-out.html">'));
});

ok('CLI exits 1 with a helpful message on an unparseable spec', () => {
  const bad = join(tmp, 'bad.md');
  writeFileSync(bad, '# Plan: Broken\n\nNo sections at all.\n');
  const res = spawnSync('node', [RENDERER, bad], { encoding: 'utf8' });
  assert.equal(res.status, 1);
  assert.match(res.stderr, /not a valid plan spec/);
  assert.match(res.stderr, /## Objective/);
});

ok('CLI exits 2 on misuse and 1 on a missing file', () => {
  assert.equal(spawnSync('node', [RENDERER], { encoding: 'utf8' }).status, 2);
  assert.equal(spawnSync('node', [RENDERER, join(tmp, 'nope.md')], { encoding: 'utf8' }).status, 1);
});

/* ── Integration: render-plan-html.py hook ────────────────────────── */

function makeProject({ localSettings = null, settings = { plansDirectory: 'docs/plans' } } = {}) {
  const proj = mkdtempSync(join(tmpdir(), 'render-hook-proj-'));
  symlinkSync(join(ROOT, 'scripts'), join(proj, 'scripts'));
  mkdirSync(join(proj, '.claude'), { recursive: true });
  writeFileSync(join(proj, '.claude', 'settings.json'), JSON.stringify(settings));
  if (localSettings) writeFileSync(join(proj, '.claude', 'settings.local.json'), JSON.stringify(localSettings));
  return proj;
}

function runHook(proj, filePath) {
  return spawnSync('python3', [HOOK], {
    cwd: proj,
    env: { ...process.env, CLAUDE_PROJECT_DIR: proj },
    input: JSON.stringify({ tool_input: { file_path: filePath } }),
    encoding: 'utf8',
  });
}

ok('hook regenerates the sibling HTML for a spec written in the plans dir', () => {
  const proj = makeProject();
  const spec = join(proj, 'docs', 'plans', 'sample.md');
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  writeFileSync(spec, SAMPLE_SPEC);
  const res = runHook(proj, spec);
  assert.equal(res.status, 0, res.stderr);
  const html = readFileSync(join(proj, 'docs', 'plans', 'sample.html'), 'utf8');
  assert.deepEqual(extractSections(html), sampleParsed.sections);
  rmSync(proj, { recursive: true, force: true });
});

ok('hook ignores markdown outside the plans dir and non-spec markdown inside it', () => {
  const proj = makeProject();
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'notes'), { recursive: true });
  const outside = join(proj, 'notes', 'readme.md');
  writeFileSync(outside, SAMPLE_SPEC);
  assert.equal(runHook(proj, outside).status, 0);
  assert.ok(!existsSync(join(proj, 'notes', 'readme.html')), 'no HTML outside plans dir');
  const notSpec = join(proj, 'docs', 'plans', 'notes.md');
  writeFileSync(notSpec, '# Notes\n\nJust notes.\n');
  assert.equal(runHook(proj, notSpec).status, 0);
  assert.ok(!existsSync(join(proj, 'docs', 'plans', 'notes.html')), 'no HTML for non-spec markdown');
  rmSync(proj, { recursive: true, force: true });
});

ok('hook honors plansDirectory from settings.local.json over settings.json', () => {
  const proj = makeProject({ localSettings: { plansDirectory: 'custom/plans' } });
  mkdirSync(join(proj, 'custom', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const customSpec = join(proj, 'custom', 'plans', 'sample.md');
  writeFileSync(customSpec, SAMPLE_SPEC);
  assert.equal(runHook(proj, customSpec).status, 0);
  assert.ok(existsSync(join(proj, 'custom', 'plans', 'sample.html')), 'custom plans dir re-renders');
  const defaultSpec = join(proj, 'docs', 'plans', 'other.md');
  writeFileSync(defaultSpec, SAMPLE_SPEC);
  assert.equal(runHook(proj, defaultSpec).status, 0);
  assert.ok(!existsSync(join(proj, 'docs', 'plans', 'other.html')), 'docs/plans ignored when custom dir configured');
  rmSync(proj, { recursive: true, force: true });
});

ok('hook exits non-zero with stderr when the renderer fails on a broken spec', () => {
  const proj = makeProject();
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const broken = join(proj, 'docs', 'plans', 'broken.md');
  writeFileSync(broken, '# Plan: Broken\n\nNo sections.\n');
  const res = runHook(proj, broken);
  assert.equal(res.status, 2);
  assert.match(res.stderr, /not a valid plan spec/);
  rmSync(proj, { recursive: true, force: true });
});

/* ── Objective (smoke): round-trip property over committed plans ──── */

ok('committed plans round-trip: extract → digest → parse → render → re-extract', () => {
  let roundTripped = 0;
  let skipped = 0;
  for (const f of readdirSync(PLANS_DIR).filter((n) => n.endsWith('.html') && n !== 'index.html')) {
    let sections;
    try {
      sections = extractSections(readFileSync(join(PLANS_DIR, f), 'utf8'));
    } catch {
      skipped += 1; // legacy review artifacts without the full plan DOM
      continue;
    }
    const expected = norm(sections);
    const parsed = parseSpecMarkdown(unguardScriptClose(buildDigest(sections)));
    assert.deepEqual(parsed.sections, expected, `${f}: digest parse diverged`);
    const html = renderPlanHtml(parsed, { fileName: f, planPath: `docs/plans/${f}`, repo: 'agentics' });
    assert.deepEqual(extractSections(html), expected, `${f}: rendered HTML re-extracts differently`);
    roundTripped += 1;
  }
  assert.ok(roundTripped >= 10, `expected ≥10 clean round trips, got ${roundTripped}`);
  console.log(`       ${roundTripped} plans round-tripped cleanly (${skipped} legacy files skipped)`);
});

rmSync(tmp, { recursive: true, force: true });
console.log(`\n${passed} checks passed${process.exitCode ? ' (with failures)' : ''}`);
