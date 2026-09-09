#!/usr/bin/env node
/**
 * Lane grammar for plan specs (docs/plans/add-lane-orchestration.md).
 *
 * A `### Lane: <name> (owns: ...; after: ...)` heading inside `## Steps`
 * groups a run of steps that one worktree-isolated worker can own end to end.
 * This suite is the contract for that grammar: parse shape, digest round-trip,
 * the --check ownership rules, the --lanes JSON, the rendered lane surfaces,
 * and — the half that matters most — that a spec with no lane heading renders
 * exactly as it did before lanes existed.
 *
 * Backward compatibility is asserted as digest round-trip plus zero lane
 * markup, not as a pinned HTML snapshot: a snapshot breaks on every unrelated
 * renderer change and the drift noise would hide a real regression.
 *
 * Run: node tests/plan-lanes.test.mjs
 */

import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { buildDigest, decodeEntities, extractSections, parseSpecMarkdown, ParseError } from '../scripts/lib/plan-spec.mjs';
import { checkLanes, laneTable, renderPlanHtml } from '../scripts/build-plan-html.mjs';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
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

/* ── Fixtures ─────────────────────────────────────────────────────── */

const TAIL = `
## Tests

Tier 1 — This plan changes application code
- Objective: lanes parse. File: tests/plan-lanes.test.mjs; Type: smoke; Asserts: a laned spec renders; Run: node tests/plan-lanes.test.mjs

## Acceptance Criteria

- [ ] Every lane renders a chip

## Verification

Render the spec and read the Lanes panel.
`;

// The proposal's Appendix A example, verbatim in shape: two worker lanes and
// a lead lane that owns nothing and runs after both.
const LANED_SPEC = `---
status: todo
type: feature
created: 2026-09-09
workflow: auto
---
# Plan: Orchestrate the renderer

## Objective
Make the plan the dispatch contract.

## Files
- scripts/lib/plan-spec.mjs (modified) — parse lanes
- scripts/build-plan-html.mjs (modified) — check rules, --lanes
- skills/build/SKILL.md (modified) — dispatcher
- commands/fix.md (modified) — lockstep
- commands/refactor.md (modified) — lockstep
- tests/plan-lanes.test.mjs (new) — the suite
- CHANGELOG.md (modified)

## Steps

### Lane: renderer (owns: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs, tests/plan-lanes.test.mjs)

1. Parse \`### Lane:\` headings into sections.lanes. Why: the parser is the single source. Verify: \`node tests/plan-lanes.test.mjs\` exits 0.
2. Add the --check rules. Why: a bad split fails at authoring time. Verify: \`plan-agent-render tests/fixtures/overlap.md --check\` exits 1.

### Lane: build-skill (owns: skills/build/**, commands/fix.md, commands/refactor.md; after: renderer)

3. Rewrite Step 2 as the dispatcher. Why: build dispatches by shape. Verify: grep finds the branch condition.

### Lane: lead (after: renderer, build-skill)

4. Bump marketplace.json and write the CHANGELOG entry. Why: each phase is a minor bump. Verify: \`BASE_REF=main node scripts/check-plugin-versions.mjs\` exits 0.
${TAIL}`;

// Lane-free, two files in one directory: no workflow prompt under today's
// file-count gate, and nothing lane-shaped anywhere in the output.
const NO_LANES_SPEC = `---
status: todo
type: fix
created: 2026-09-09
---
# Plan: Fix the thing

## Objective
Fix the thing the old way.

## Context
A plan written before this grammar existed.

## Files
- src/a.mjs (modified) — first
- src/b.mjs (modified) — second

## Steps

### Phase: Parse

1. Do the first thing. Why: it unblocks everything. Verify: run the check.
2. Do the second thing. Why: the first is not enough. Verify: run the other check.
${TAIL}`;

// Lane-free, four files across two top-level directories: today's
// fileCount >= 4 && dirCount >= 2 gate must still emit the workflow prompt.
const FOUR_FILE_SPEC = NO_LANES_SPEC.replace(
  '## Files\n- src/a.mjs (modified) — first\n- src/b.mjs (modified) — second',
  '## Files\n- src/a.mjs (modified) — first\n- src/b.mjs (modified) — second\n- tests/a.test.mjs (new) — third\n- tests/b.test.mjs (new) — fourth',
);

/** Swap the whole `## Steps` body of LANED_SPEC for `body`. */
const withSteps = (body) => LANED_SPEC.replace(/## Steps[\s\S]*?(?=\n## Tests)/, `## Steps\n\n${body}\n`);

const STEP = (n, text) => `${n}. ${text}. Why: because. Verify: check it.`;

/** Render a spec through the library entry point with fixed paths. */
const render = (spec) => renderPlanHtml(parseSpecMarkdown(spec), { fileName: 'plan.html', planPath: 'docs/plans/plan.html', mdPath: 'docs/plans/plan.md', repo: 'repo' });

/* ── Parse ────────────────────────────────────────────────────────── */

ok('parseSpecMarkdown reads lane headings into sections.lanes with flat step ranges', () => {
  const { sections } = parseSpecMarkdown(LANED_SPEC);
  assert.deepEqual(sections.lanes, [
    { name: 'renderer', owns: ['scripts/lib/plan-spec.mjs', 'scripts/build-plan-html.mjs', 'tests/plan-lanes.test.mjs'], after: [], firstStep: 1, lastStep: 2 },
    { name: 'build-skill', owns: ['skills/build/**', 'commands/fix.md', 'commands/refactor.md'], after: ['renderer'], firstStep: 3, lastStep: 3 },
    { name: 'lead', owns: [], after: ['renderer', 'build-skill'], firstStep: 4, lastStep: 4 },
  ]);
  assert.equal(sections.phases, null, 'lane headings are not phases');
  assert.equal(sections.steps.length, 4, 'numbering stays flat and global');
});

ok('a spec with no lane heading parses lanes as null', () => {
  assert.equal(parseSpecMarkdown(NO_LANES_SPEC).sections.lanes, null);
});

ok('a Phase heading inside a lane stays a checkpoint and both groupings coexist', () => {
  const { sections } = parseSpecMarkdown(withSteps(`### Lane: a (owns: src/a.mjs)

### Phase: One

${STEP(1, 'First')}

### Phase: Two

${STEP(2, 'Second')}

### Lane: b (owns: src/b.mjs; after: a)

${STEP(3, 'Third')}`));
  assert.deepEqual(sections.phases, [
    { name: 'One', firstStep: 1, lastStep: 1 },
    { name: 'Two', firstStep: 2, lastStep: 2 },
  ]);
  assert.deepEqual(sections.lanes.map((l) => [l.name, l.firstStep, l.lastStep]), [['a', 1, 2], ['b', 3, 3]]);
});

ok('a lane heading with no steps under it is a ParseError', () => {
  assert.throws(
    () => parseSpecMarkdown(withSteps(`### Lane: empty (owns: x)\n\n### Lane: a (owns: src/a.mjs)\n\n${STEP(1, 'First')}`)),
    (err) => err instanceof ParseError && /lane "empty" has no steps/.test(err.message),
  );
});

ok('an unknown clause inside a lane heading is a ParseError naming the lane', () => {
  assert.throws(
    () => parseSpecMarkdown(withSteps(`### Lane: a (owns: x; needs: y)\n\n${STEP(1, 'First')}`)),
    (err) => err instanceof ParseError && /lane "a"/.test(err.message) && /needs/.test(err.message),
  );
});

/* ── Round trip ───────────────────────────────────────────────────── */

ok('buildDigest re-emits lane headings and the digest re-parses to identical sections', () => {
  const { sections } = parseSpecMarkdown(LANED_SPEC);
  const digest = buildDigest(sections);
  assert.match(digest, /^### Lane: renderer \(owns: scripts\/lib\/plan-spec\.mjs, scripts\/build-plan-html\.mjs, tests\/plan-lanes\.test\.mjs\)$/m);
  assert.match(digest, /^### Lane: build-skill \(owns: skills\/build\/\*\*, commands\/fix\.md, commands\/refactor\.md; after: renderer\)$/m);
  assert.match(digest, /^### Lane: lead \(after: renderer, build-skill\)$/m);
  const again = parseSpecMarkdown(digest);
  assert.deepEqual(again.sections, sections);
  assert.equal(buildDigest(again.sections), digest, 'second digest is byte-identical to the first');
});

ok('a lane-free spec round-trips byte-stably through the digest', () => {
  const { sections } = parseSpecMarkdown(NO_LANES_SPEC);
  const digest = buildDigest(sections);
  assert.ok(!/### Lane:/.test(digest), 'no lane heading appears');
  assert.equal(buildDigest(parseSpecMarkdown(digest).sections), digest);
});

ok('extractSections reads lanes back out of the rendered HTML', () => {
  const { sections } = parseSpecMarkdown(LANED_SPEC);
  const back = extractSections(render(LANED_SPEC));
  assert.deepEqual(back.lanes, sections.lanes);
  assert.deepEqual(back, sections, 'full sections round-trip through HTML');
  assert.equal(extractSections(render(NO_LANES_SPEC)).lanes, null);
});

ok('a malformed plan-lanes meta row is a ParseError, never a downstream TypeError', () => {
  // A hand-edited or truncated page can carry a row with no owns/after. The
  // backfill batch catches ParseError only, so anything else aborts the run.
  const html = render(LANED_SPEC).replace(/<meta name="plan-lanes" content="([^"]*)">/, (_, c) => {
    const rows = JSON.parse(decodeEntities(c)).map(({ name, firstStep, lastStep }) => ({ name, firstStep, lastStep }));
    return `<meta name="plan-lanes" content="${JSON.stringify(rows).replace(/&/g, '&amp;').replace(/"/g, '&quot;')}">`;
  });
  assert.throws(() => buildDigest(extractSections(html)), (err) => err instanceof ParseError && /plan-lanes/.test(err.message));
});

/* ── --check rules (library) ──────────────────────────────────────── */

const errorsOf = (spec) => checkLanes(parseSpecMarkdown(spec).sections).errors;
const warningsOf = (spec) => checkLanes(parseSpecMarkdown(spec).sections).warnings;

ok('the Appendix A example passes every check rule clean', () => {
  assert.deepEqual(checkLanes(parseSpecMarkdown(LANED_SPEC).sections), { errors: [], warnings: [] });
});

ok('a lane-free spec has nothing to check', () => {
  assert.deepEqual(checkLanes(parseSpecMarkdown(NO_LANES_SPEC).sections), { errors: [], warnings: [] });
});

ok('overlapping ownership of a listed file fails naming the file and both lanes', () => {
  const errors = errorsOf(withSteps(`### Lane: a (owns: scripts/lib/plan-spec.mjs)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs)\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /scripts\/lib\/plan-spec\.mjs/.test(e) && /"a"/.test(e) && /"b"/.test(e)), errors.join('\n'));
});

ok('nested owns globs across lanes fail even when no listed file sits in the overlap', () => {
  const errors = errorsOf(withSteps(`### Lane: wide (owns: tools/**)\n\n${STEP(1, 'First')}\n\n### Lane: narrow (owns: tools/lib/**)\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /"narrow"/.test(e) && /"wide"/.test(e) && /tools\/lib\/\*\*/.test(e)), errors.join('\n'));
});

ok('an after: naming an unknown lane fails naming both', () => {
  const errors = errorsOf(withSteps(`### Lane: a (owns: src/a.mjs; after: ghost)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: src/b.mjs)\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /"a"/.test(e) && /ghost/.test(e)), errors.join('\n'));
});

ok('after: lead is rejected — lead runs last', () => {
  const errors = errorsOf(withSteps(`### Lane: a (owns: src/a.mjs; after: lead)\n\n${STEP(1, 'First')}\n\n### Lane: lead\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /"a"/.test(e) && /after: lead/.test(e)), errors.join('\n'));
});

ok('a dependency cycle fails naming the lanes on it', () => {
  const errors = errorsOf(withSteps(`### Lane: a (owns: src/a.mjs; after: b)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: src/b.mjs; after: a)\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /cycle/i.test(e) && /"a"/.test(e) && /"b"/.test(e)), errors.join('\n'));
});

ok('a step outside every lane in a laned spec fails naming the step', () => {
  const errors = errorsOf(withSteps(`${STEP(1, 'Loose')}\n\n### Lane: a (owns: src/a.mjs)\n\n${STEP(2, 'First')}`));
  assert.ok(errors.some((e) => /step 1/.test(e)), errors.join('\n'));
});

ok('a non-lead lane without owns: fails; lead without owns: is fine', () => {
  const errors = errorsOf(withSteps(`### Lane: a\n\n${STEP(1, 'First')}\n\n### Lane: lead\n\n${STEP(2, 'Second')}`));
  assert.ok(errors.some((e) => /"a"/.test(e) && /owns:/.test(e)), errors.join('\n'));
  assert.ok(!errors.some((e) => /"lead"/.test(e)), 'lead may omit owns:');
});

ok('an owns: glob matching no ## Files path warns without failing', () => {
  const spec = withSteps(`### Lane: a (owns: scripts/lib/plan-spec.mjs, docs/never/**)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: scripts/build-plan-html.mjs)\n\n${STEP(2, 'Second')}`);
  assert.deepEqual(errorsOf(spec), []);
  assert.ok(warningsOf(spec).some((w) => /"a"/.test(w) && /docs\/never\/\*\*/.test(w)), warningsOf(spec).join('\n'));
});

/* ── --check and --lanes (CLI) ────────────────────────────────────── */

const tmp = mkdtempSync(join(tmpdir(), 'plan-lanes-'));
const cli = (spec, ...flags) => {
  const md = join(tmp, `${flags.join('').replace(/\W/g, '') || 'render'}-${Math.random().toString(36).slice(2, 8)}.md`);
  writeFileSync(md, spec);
  return spawnSync('node', [RENDERER, md, '-o', md.replace(/\.md$/, '.html'), ...flags], { encoding: 'utf8', cwd: ROOT });
};

ok('--check exits 1 naming the lane on each ownership rule', () => {
  const cases = {
    overlap: `### Lane: a (owns: scripts/lib/plan-spec.mjs)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: scripts/lib/plan-spec.mjs)\n\n${STEP(2, 'Second')}`,
    nested: `### Lane: a (owns: tools/**)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: tools/lib/**)\n\n${STEP(2, 'Second')}`,
    unknown: `### Lane: a (owns: src/a.mjs; after: ghost)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: src/b.mjs)\n\n${STEP(2, 'Second')}`,
    afterLead: `### Lane: a (owns: src/a.mjs; after: lead)\n\n${STEP(1, 'First')}\n\n### Lane: lead\n\n${STEP(2, 'Second')}`,
    cycle: `### Lane: a (owns: src/a.mjs; after: b)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: src/b.mjs; after: a)\n\n${STEP(2, 'Second')}`,
    unlaned: `${STEP(1, 'Loose')}\n\n### Lane: a (owns: src/a.mjs)\n\n${STEP(2, 'First')}`,
  };
  for (const [name, body] of Object.entries(cases)) {
    const res = cli(withSteps(body), '--check');
    assert.equal(res.status, 1, `${name}: expected exit 1, got ${res.status}\n${res.stdout}${res.stderr}`);
    assert.match(res.stderr, /lane "a"|"a" and|"b" and|step 1/, `${name}: stderr names the lane\n${res.stderr}`);
  }
});

ok('a dead owns: glob warns on stderr and exits 0', () => {
  const spec = withSteps(`### Lane: a (owns: scripts/lib/plan-spec.mjs, docs/never/**)\n\n${STEP(1, 'First')}\n\n### Lane: b (owns: scripts/build-plan-html.mjs)\n\n${STEP(2, 'Second')}`);
  const res = cli(spec);
  assert.equal(res.status, 0, res.stderr);
  assert.match(res.stderr, /docs\/never\/\*\*/);
});

ok('--check exits 0 clean on the Appendix A example once rendered', () => {
  const md = join(tmp, 'appendix-a.md');
  writeFileSync(md, LANED_SPEC);
  const out = md.replace(/\.md$/, '.html');
  execFileSync('node', [RENDERER, md, '-o', out], { cwd: ROOT });
  const res = spawnSync('node', [RENDERER, md, '-o', out, '--check'], { encoding: 'utf8', cwd: ROOT });
  assert.equal(res.status, 0, res.stdout + res.stderr);
});

ok('--lanes prints every lane with owns, after, and steps as JSON', () => {
  const res = cli(LANED_SPEC, '--lanes');
  assert.equal(res.status, 0, res.stderr);
  const lanes = JSON.parse(res.stdout);
  assert.deepEqual(lanes.map((l) => l.name), ['renderer', 'build-skill', 'lead']);
  assert.deepEqual(lanes[1].owns, ['skills/build/**', 'commands/fix.md', 'commands/refactor.md']);
  assert.deepEqual(lanes[1].after, ['renderer']);
  assert.deepEqual(lanes[0].steps.map((s) => s.n), [1, 2]);
  assert.deepEqual(Object.keys(lanes[0].steps[0]), ['n', 'action', 'why', 'verify', 'done']);
  assert.equal(lanes[0].steps[0].done, false);
  assert.deepEqual(lanes[2].steps.map((s) => s.n), [4]);
});

ok('--lanes on a lane-free spec prints an empty list', () => {
  const res = cli(NO_LANES_SPEC, '--lanes');
  assert.equal(res.status, 0, res.stderr);
  assert.deepEqual(JSON.parse(res.stdout), []);
});

ok('laneTable carries step done-state from the spec markers', () => {
  const parsed = parseSpecMarkdown(LANED_SPEC.replace('1. Parse', '1. [x] Parse'));
  const table = laneTable(parsed);
  assert.equal(table[0].steps[0].done, true);
  assert.equal(table[0].steps[1].done, false);
});

/* ── Workflow prompt gating ───────────────────────────────────────── */

const hasWorkflowMeta = (html) => /<meta name="plan-workflow"/.test(html);

ok('a two-lane spec under workflow: auto emits the plan-workflow meta', () => {
  assert.ok(hasWorkflowMeta(render(LANED_SPEC)));
});

ok('a one-lane spec under workflow: auto does not', () => {
  const one = withSteps(`### Lane: only (owns: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs, skills/build/SKILL.md, CHANGELOG.md)\n\n${STEP(1, 'First')}`);
  assert.ok(!hasWorkflowMeta(render(one)));
});

ok('workflow: never suppresses the prompt on a laned spec; always keeps it on one lane', () => {
  assert.ok(!hasWorkflowMeta(render(LANED_SPEC.replace('workflow: auto', 'workflow: never'))));
  const one = withSteps(`### Lane: only (owns: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs, skills/build/SKILL.md, CHANGELOG.md)\n\n${STEP(1, 'First')}`);
  assert.ok(hasWorkflowMeta(render(one.replace('workflow: auto', 'workflow: always'))));
});

ok('the lane-free four-file fixture still gets its workflow prompt from the file-count gate', () => {
  assert.ok(hasWorkflowMeta(render(FOUR_FILE_SPEC)));
  assert.ok(!hasWorkflowMeta(render(NO_LANES_SPEC)), 'two files in one directory never did');
});

/* ── Rendered lane surfaces ───────────────────────────────────────── */

const LANE_MARKUP = [/lane-chip/, /id="lanes"/, /href="#lanes"/, /lane-brief-/, /<meta name="plan-lanes"/];

ok('the laned fixture renders a labeled lane chip on every step card', () => {
  const html = render(LANED_SPEC);
  const cards = html.split(/(?=<div class="step-card[" ])/).slice(1);
  assert.equal(cards.length, 4);
  assert.match(cards[0], /<span class="step-chip lane-chip">lane renderer<\/span>/);
  assert.match(cards[2], /lane build-skill/);
  assert.match(cards[3], /lane lead/);
});

ok('the Lanes panel is its own card with a nav entry and real list semantics', () => {
  const html = render(LANED_SPEC);
  assert.match(html, /<section class="section-card card-lanes" id="lanes"/);
  assert.match(html, /<li><a href="#lanes">/);
  const panel = html.slice(html.indexOf('id="lanes"'), html.indexOf('id="steps"'));
  assert.equal((panel.match(/<li class="lane-item"/g) || []).length, 3, 'one list item per lane');
  assert.match(panel, /<ul class="lane-owns"/);
  assert.match(panel, /<ul class="lane-after"/);
  const filesAt = html.indexOf('id="files"');
  assert.ok(filesAt < html.indexOf('id="lanes"') && html.indexOf('id="lanes"') < html.indexOf('id="steps"'), 'between Files and Steps');
});

ok('one copyable worker brief per worker lane sits in the More-ways drawer', () => {
  const html = render(LANED_SPEC);
  const drawer = html.slice(html.indexOf('<details class="plan-more-ways">'), html.indexOf('</details>', html.indexOf('<details class="plan-more-ways">')));
  assert.match(drawer, /id="lane-brief-renderer"/);
  assert.match(drawer, /id="lane-brief-build-skill"/);
  assert.ok(!/id="lane-brief-lead"/.test(drawer), 'lead never runs as a worker, so it gets no brief');
  assert.match(drawer, /aria-label="Copy worker brief — lane renderer"/);
  const brief = decodeEntities(drawer.match(/id="lane-brief-build-skill"[^>]*>([\s\S]*?)<\/code>/)[1]);
  assert.match(brief, /lane "build-skill"/);
  assert.match(brief, /skills\/build\/\*\*, commands\/fix\.md, commands\/refactor\.md/);
  assert.match(brief, /<plan-branch>--build-skill/);
  assert.match(brief, /3\. Rewrite Step 2 as the dispatcher\. Why: build dispatches by shape\. Verify: grep finds the branch condition\./);
  assert.match(brief, /LANE REPORT/);
  assert.match(brief, /Do not edit docs\/plans\/plan\.md/);
});

ok('the plan-lanes meta carries the --lanes JSON', () => {
  const html = render(LANED_SPEC);
  const meta = html.match(/<meta name="plan-lanes" content="([^"]*)">/);
  assert.ok(meta, 'meta present');
  const lanes = JSON.parse(decodeEntities(meta[1]));
  assert.deepEqual(lanes, laneTable(parseSpecMarkdown(LANED_SPEC)));
});

ok('the lane-free fixture carries zero lane markup', () => {
  for (const spec of [NO_LANES_SPEC, FOUR_FILE_SPEC]) {
    const html = render(spec);
    for (const re of LANE_MARKUP) assert.ok(!re.test(html), `${re} leaked into a lane-free plan`);
  }
});

/* ── Wrap up ──────────────────────────────────────────────────────── */

rmSync(tmp, { recursive: true, force: true });
console.log(`\n${passed} checks passed${process.exitCode ? ' (with failures)' : ''}`);
