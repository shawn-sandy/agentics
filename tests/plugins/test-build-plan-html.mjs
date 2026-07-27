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
 * Also pinned: the required plan-* meta tags, zero unfilled skeleton
 * placeholder tokens, effort derivation thresholds, CLI exit codes, the
 * spec-carried progress state (checkbox criteria, [x] step markers, the
 * Completion Report section, the derived completion checklist), and the
 * hook's plansDirectory settings precedence (settings.local.json →
 * settings.json → global → docs/plans).
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
# schema: v1 — a frontmatter comment must not read as the title heading
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

ok('parseSpecMarkdown ignores headings inside fenced code blocks', () => {
  const fencedSpec = SAMPLE_SPEC.replace(
    'First paragraph of context.',
    'First paragraph of context.\n\n```text\n# Plan: quoted title\n## Steps\nnot real structure\n```\n\nStill context.'
  );
  const { sections } = parseSpecMarkdown(fencedSpec);
  assert.equal(sections.title, 'Ship a sample feature');
  assert.ok(sections.context.includes('## Steps'), 'quoted heading stays inside context');
  assert.equal(sections.steps.length, 2, 'real Steps section still parsed');
});

ok('parseSpecMarkdown rejects steps with an empty action, Why:, or Verify: part', () => {
  // After whitespace collapse an empty part either fails the marker regex
  // ("missing") or the emptiness check ("empty") — both are ParseErrors.
  const emptyWhy = SAMPLE_SPEC.replace('Why: because it unblocks everything.', 'Why:');
  assert.throws(() => parseSpecMarkdown(emptyWhy), ParseError);
  const emptyVerify = SAMPLE_SPEC.replace('Verify: run the check.', 'Verify:');
  assert.throws(() => parseSpecMarkdown(emptyVerify), ParseError);
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

ok('implement and goal meta tags reference the markdown spec path, not the HTML', () => {
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-implement" content="Read and implement all steps in the plan at docs/plans/sample.md — Ship a sample feature. Then verify before reporting done:'
    )
  );
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-goal" content="Achieve this goal: Ship a sample feature. The plan at docs/plans/sample.md describes one approach — use it as reference, but optimize for the outcome. Then verify before reporting done:'
    )
  );
  assert.ok(sampleHtml.includes('<meta name="plan-md" content="docs/plans/sample.md">'), 'plan-md meta carries the spec path');
  assert.ok(sampleHtml.includes('id="plan-md"'), 'drawer has the Spec source row');
  // An explicit mdPath option wins over the .html → .md derivation.
  const custom = renderPlanHtml(sampleParsed, { fileName: 'sample.html', planPath: 'docs/plans/sample.html', mdPath: 'specs/sample.md' });
  assert.ok(custom.includes('plan at specs/sample.md — Ship a sample feature'));
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
  assert.ok(wideHtml.includes('<meta name="plan-workflow" content="Run a workflow to implement the plan at w.md'));
});

ok('every prompt carries the verify-then-mark-completed gate', () => {
  // An agent handed any of these prompts must run the checks AND record the
  // result in the spec — a plan left at status: todo is not "done".
  const wide = parseSpecMarkdown(SAMPLE_SPEC.replace(
    /## Files[\s\S]*?## Steps/,
    '## Files\n- a/one.mjs (new)\n- b/two.mjs (new)\n- c/three.mjs (new)\n- d/four.mjs (new)\n- e/five.mjs (new)\n\n## Steps'
  ));
  const html = renderPlanHtml(wide, { fileName: 'w.html', planPath: 'w.html' });
  const prompts = ['plan-implement', 'plan-goal', 'plan-workflow'].map((name) => {
    const m = html.match(new RegExp(`<meta name="${name}" content="([^"]*)"`));
    assert.ok(m, `${name} meta tag is present`);
    return m[1];
  });
  for (const p of prompts) {
    assert.match(p, /run the objective test&#39;s Run command/, 'names the runnable check');
    assert.match(p, /walk the Verification section/, 'names end-to-end verification');
    assert.match(p, /confirm every acceptance criterion holds/, 'names the criteria check');
    assert.match(p, /set status: completed/, 'marks the plan completed');
    assert.match(p, /leave status: in-progress/, 'has a failure path that does not mark done');
  }
});

/* ── Unit: Next Steps section ─────────────────────────────────────── */

const NEXT_STEPS_SPEC = `${SAMPLE_SPEC}
## Next Steps

Loose intro line before the items.

- Add a follow-up feature
  A short description of the follow-up.
  \`\`\`text
  In the repo, add the follow-up feature.
  - Bump the version and update the CHANGELOG.
  \`\`\`
- A promptless wish-list item
`;

ok('parseSpecMarkdown parses Next Steps bullets into items beside sections', () => {
  const { sections, nextSteps } = parseSpecMarkdown(NEXT_STEPS_SPEC);
  assert.equal(nextSteps.prose, 'Loose intro line before the items.');
  assert.equal(nextSteps.items.length, 2);
  assert.deepEqual(nextSteps.items[0], {
    summary: 'Add a follow-up feature',
    desc: 'A short description of the follow-up.',
    prompt: 'In the repo, add the follow-up feature.\n- Bump the version and update the CHANGELOG.',
  });
  assert.deepEqual(nextSteps.items[1], { summary: 'A promptless wish-list item', desc: '', prompt: null });
  // Sections stay pure — the round-trip contract is untouched.
  assert.deepEqual(sections, parseSpecMarkdown(SAMPLE_SPEC).sections);
  assert.equal(parseSpecMarkdown(SAMPLE_SPEC).nextSteps, null);
  // A "## Next Steps *(optional)*" heading variant still parses.
  const suffixed = parseSpecMarkdown(NEXT_STEPS_SPEC.replace('## Next Steps', '## Next Steps *(optional)*'));
  assert.equal(suffixed.nextSteps.items.length, 2);
  // Bullet-less content falls back to prose.
  const proseOnly = parseSpecMarkdown(`${SAMPLE_SPEC}\n## Next Steps\n\n### Phase 2\n\nJust prose, no bullets.\n`);
  assert.deepEqual(proseOnly.nextSteps.items, []);
  assert.ok(proseOnly.nextSteps.prose.includes('Just prose, no bullets.'));
  assert.throws(() => parseSpecMarkdown(`${SAMPLE_SPEC}\n## Next Steps\n\n\n`), ParseError, 'empty section is a ParseError');
});

ok('Next Steps renders as collapsible cards with copy buttons and a nav entry', () => {
  const parsed = parseSpecMarkdown(NEXT_STEPS_SPEC);
  const html = renderPlanHtml(parsed, { fileName: 'ns.html', planPath: 'ns.html' });
  assert.ok(html.includes('<section class="section-card card-next-steps" id="next-steps"'), 'section card rendered');
  assert.ok(html.includes('<summary>Add a follow-up feature</summary>'), 'item summary rendered');
  assert.ok(html.includes('<pre>In the repo, add the follow-up feature.\n- Bump the version and update the CHANGELOG.</pre>'), 'prompt rendered verbatim in a pre');
  assert.ok(html.includes('onclick="copyPrompt(this)"'), 'copy-prompt button wired');
  assert.ok(html.includes('<p>Loose intro line before the items.</p>'), 'loose prose rendered');
  const links = [...html.matchAll(/<a href="#([a-z-]+)">/g)].map((m) => m[1]);
  assert.ok(links.includes('next-steps'), 'nav includes next-steps');
  // Content extraction is untouched by the extra section.
  assert.deepEqual(extractSections(html), sampleParsed.sections);
  // Specs without the section render neither the card nor the nav entry.
  assert.ok(!sampleHtml.includes('card-next-steps'), 'no card without the section');
});

/* ── Unit: spec-carried progress state ────────────────────────────── */

// SAMPLE_SPEC with one step done, one criterion checked, status in-progress.
const PARTIAL_SPEC = SAMPLE_SPEC.replace('status: todo', 'status: in-progress')
  .replace('1. Do the first thing.', '1. [x] Do the first thing.')
  .replace('- The first criterion holds.', '- [x] The first criterion holds.');

// Everything done: status completed, both steps [x], both criteria [x],
// plus a Completion Report section.
const DONE_SPEC = SAMPLE_SPEC.replace('status: todo', 'status: completed')
  .replace('1. Do the first thing.', '1. [x] Do the first thing.')
  .replace('2. Do the second thing.', '2. [x] Do the second thing.')
  .replace('- The first criterion holds.', '- [x] The first criterion holds.')
  .replace('- The second criterion holds.', '- [x] The second criterion holds.');
const REPORTED_SPEC = DONE_SPEC.replace(
  '## Verification',
  '## Completion Report\n- The second criterion holds. — tsc --noEmit exited with code 1\n\n## Verification'
);

ok('parseSpecMarkdown reads checkbox state into progress, keeping sections pure', () => {
  const { sections, progress } = parseSpecMarkdown(PARTIAL_SPEC);
  assert.deepEqual(progress.steps, [true, false]);
  assert.deepEqual(progress.criteria, [true, false]);
  assert.deepEqual(progress.report, []);
  // Content is identical to the unchecked spec — state never leaks into text.
  assert.deepEqual(sections, parseSpecMarkdown(SAMPLE_SPEC).sections);
  assert.deepEqual(parseSpecMarkdown(SAMPLE_SPEC).progress, { steps: [false, false], criteria: [false, false], report: [] });
});

ok('parseSpecMarkdown parses Completion Report entries and rejects malformed ones', () => {
  const { progress } = parseSpecMarkdown(REPORTED_SPEC);
  assert.deepEqual(progress.report, [
    { item: 'The second criterion holds.', reason: 'tsc --noEmit exited with code 1' },
  ]);
  const noDash = REPORTED_SPEC.replace('holds. — tsc', 'holds. tsc');
  assert.throws(() => parseSpecMarkdown(noDash), ParseError);
});

ok('progress state renders: checked inputs, completed step cards, live progress bar', () => {
  const html = renderPlanHtml(parseSpecMarkdown(PARTIAL_SPEC), { fileName: 'p.html', planPath: 'p.html' });
  assert.ok(html.includes('<input type="checkbox" id="ac1" checked>'), 'done criterion renders checked');
  assert.ok(html.includes('<input type="checkbox" id="ac2">'), 'open criterion renders unchecked');
  assert.ok(html.includes('class="step-card completed"'), 'done step card carries completed class');
  assert.ok(html.includes('<span class="step-chip">done</span>'), 'done step chip flips');
  assert.ok(html.includes('<span class="step-chip">todo</span>'), 'open step chip stays todo');
  assert.ok(html.includes('id="progress-label">1 / 2 done<'), 'progress label reflects checked count');
  assert.ok(html.includes('aria-valuenow="50"'), 'progress bar reflects checked count');
  // Progress must not disturb content extraction.
  assert.deepEqual(extractSections(html), sampleParsed.sections);
});

ok('completion checklist and report are derived from spec state', () => {
  assert.ok(sampleHtml.includes('<input type="checkbox" id="cc1" disabled>'), 'todo spec: cc1 unchecked');
  assert.ok(sampleHtml.includes('<div class="completion-checklist" id="completion-checklist">'), 'todo spec: no all-complete class');
  assert.ok(sampleHtml.includes('No items to report — all requirements met.'), 'default report sentence');

  const done = renderPlanHtml(parseSpecMarkdown(DONE_SPEC), { fileName: 'd.html', planPath: 'd.html' });
  for (const cc of ['cc1', 'cc2', 'cc3']) {
    assert.ok(done.includes(`<input type="checkbox" id="${cc}" disabled checked>`), `${cc} checked`);
  }
  assert.ok(done.includes('completion-checklist all-complete'), 'all-complete class present');
  assert.ok(done.includes('data-status="completed"'), 'status stamped from frontmatter');

  const reported = renderPlanHtml(parseSpecMarkdown(REPORTED_SPEC), { fileName: 'r.html', planPath: 'r.html' });
  assert.ok(reported.includes('<dl class="report-list">'), 'report list rendered');
  assert.ok(reported.includes('<dt>The second criterion holds.</dt>'), 'report dt carries the item');
  assert.ok(reported.includes('<dd>tsc --noEmit exited with code 1</dd>'), 'report dd carries the reason');
  assert.ok(!reported.includes('<p class="report-empty">'), 'default sentence replaced by the report list');
});

ok('rendered output has every required plan-* meta tag and no unfilled placeholders', () => {
  for (const name of ['status', 'effort', 'type', 'created', 'repo', 'file', 'path', 'md', 'implement', 'goal']) {
    assert.ok(sampleHtml.includes(`<meta name="plan-${name}" content="`), `plan-${name} present`);
  }
  const leftovers = sampleHtml.match(/\{[a-z][a-z0-9-]*\}/g);
  assert.equal(leftovers, null, `unfilled skeleton tokens: ${leftovers}`);
  assert.ok(sampleHtml.includes('html { scroll-behavior: auto; }'), 'reduced-motion scroll rule present');
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
  // The CLI wires the real spec path into plan-md and the prompts.
  assert.match(html, /<meta name="plan-md" content="[^"]*cli-sample\.md">/);
  assert.match(html, /Read and implement all steps in the plan at [^"]*cli-sample\.md/);
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

ok('CLI refuses an output path equal to the input spec', () => {
  const spec = join(tmp, 'same.md');
  writeFileSync(spec, SAMPLE_SPEC);
  const res = spawnSync('node', [RENDERER, spec, '-o', spec], { encoding: 'utf8' });
  assert.equal(res.status, 2);
  assert.match(res.stderr, /must differ/);
  assert.ok(readFileSync(spec, 'utf8').startsWith('---'), 'source spec untouched');
});

ok('CLI keeps plan-created stable when re-rendering over an existing sibling', () => {
  const spec = join(tmp, 'stable.md');
  const out = join(tmp, 'stable.html');
  // No created: frontmatter — first render stamps a date, re-render must reuse it.
  writeFileSync(spec, SAMPLE_SPEC.replace('created: 2026-07-12\n', ''));
  writeFileSync(out, '<meta name="plan-created" content="2020-01-01">');
  execFileSync('node', [RENDERER, spec, '-o', out]);
  assert.ok(readFileSync(out, 'utf8').includes('<meta name="plan-created" content="2020-01-01">'));
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

function runHook(proj, filePath, extraEnv = {}) {
  // CLAUDE_PLUGIN_ROOT is cleared by default so these tests exercise the
  // project-scripts fallback deterministically; the bundled-resolution test
  // sets it explicitly.
  const env = { ...process.env, CLAUDE_PROJECT_DIR: proj };
  delete env.CLAUDE_PLUGIN_ROOT;
  Object.assign(env, extraEnv);
  return spawnSync('python3', [HOOK], {
    cwd: proj,
    env,
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

ok('hook prefers the plugin-bundled renderer when the project has none', () => {
  const proj = mkdtempSync(join(tmpdir(), 'render-hook-bundled-'));
  mkdirSync(join(proj, '.claude'), { recursive: true });
  writeFileSync(join(proj, '.claude', 'settings.json'), JSON.stringify({ plansDirectory: 'docs/plans' }));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const spec = join(proj, 'docs', 'plans', 'sample.md');
  writeFileSync(spec, SAMPLE_SPEC);
  // No project scripts/ dir at all — only the bundled copy can render.
  const res = runHook(proj, spec, { CLAUDE_PLUGIN_ROOT: join(ROOT, 'kit', 'plugins', 'plan-agent') });
  assert.equal(res.status, 0, res.stderr);
  const html = readFileSync(join(proj, 'docs', 'plans', 'sample.html'), 'utf8');
  assert.deepEqual(extractSections(html), sampleParsed.sections);
  assert.ok(existsSync(join(proj, 'docs', 'plans', 'index.html')), 'gallery index rebuilt after render');
  rmSync(proj, { recursive: true, force: true });
});

ok('a spec with no prototype: key renders byte-identically to the pre-change renderer', () => {
  // Materialize the renderer as it exists on the merge base and render the
  // same spec through both. A spec that never opted into the prototype link
  // must be unaffected by the feature that added it.
  const base = process.env.BASE_REF || 'origin/main';
  const proj = mkdtempSync(join(tmpdir(), 'render-backcompat-'));
  try {
    mkdirSync(join(proj, 'scripts', 'lib'), { recursive: true });
    for (const rel of ['build-plan-html.mjs', 'lib/plan-spec.mjs', 'lib/plan-shell.mjs']) {
      const src = execFileSync('git', ['show', `${base}:scripts/${rel}`], {
        cwd: ROOT,
        encoding: 'utf8',
        maxBuffer: 32 * 1024 * 1024,
      });
      writeFileSync(join(proj, 'scripts', rel), src);
    }
    assert.ok(!SAMPLE_SPEC.includes('prototype:'), 'fixture carries no prototype: key');

    // Each run gets its own dir but an identical internal layout, and renders
    // from inside it — plan-file/plan-path are derived from the output path
    // relative to cwd, so anything else diffs for reasons unrelated to code.
    const render = (renderer, dir) => {
      const wd = join(proj, dir);
      mkdirSync(wd, { recursive: true });
      writeFileSync(join(wd, 'sample.md'), SAMPLE_SPEC);
      const res = spawnSync('node', [renderer, 'sample.md', '-o', 'sample.html'], { cwd: wd, encoding: 'utf8' });
      assert.equal(res.status, 0, res.stderr);
      return readFileSync(join(wd, 'sample.html'), 'utf8');
    };
    const before = render(join(proj, 'scripts', 'build-plan-html.mjs'), 'before');
    const after = render(RENDERER, 'after');
    assert.equal(after, before, 'output drifted for a spec that carries no prototype: key');
  } catch (err) {
    // A shallow clone, a missing base ref, or no git at all is an environment
    // gap, not a regression — skip loudly rather than failing the suite.
    // `git show <missing>:<path>` says "invalid object name", not "unknown
    // revision", and a git-less box throws ENOENT before saying anything.
    const envGap = err.code === 'ENOENT'
      || /invalid object name|unknown revision|does not exist|ambiguous argument|not a git repository|fatal:/i.test(
        `${err.message}${err.stderr || ''}`
      );
    if (envGap) {
      console.log(`       (skipped: ${base} not available — ${String(err.message).split('\n')[0]})`);
    } else {
      throw err;
    }
  } finally {
    rmSync(proj, { recursive: true, force: true });
  }
});

ok('plugin-bundled renderer copies are byte-identical to the repo-root sources', () => {
  for (const rel of ['build-plan-html.mjs', 'lib/plan-spec.mjs', 'lib/plan-shell.mjs']) {
    const source = readFileSync(join(ROOT, 'scripts', rel), 'utf8');
    const bundled = readFileSync(join(ROOT, 'kit', 'plugins', 'plan-agent', 'scripts', rel), 'utf8');
    assert.equal(bundled, source, `kit/plugins/plan-agent/scripts/${rel} drifted from scripts/${rel} — re-copy it`);
  }
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
