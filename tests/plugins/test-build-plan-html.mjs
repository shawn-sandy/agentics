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
  extractNextSteps,
  extractSections,
  parseSpecMarkdown,
  ParseError,
  unguardScriptClose,
} from '../../scripts/lib/plan-spec.mjs';
import { CHECK_ROWS, deriveEffort, firstDiff, inline, renderPlanHtml } from '../../scripts/build-plan-html.mjs';
import * as shell from '../../scripts/lib/plan-shell.mjs';

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

ok('enumerated frontmatter rejects near-misses instead of falling back', () => {
  // Each of these used to render as something the author did not write:
  // status: complete became todo, workflow: yes meant "no workflow", and
  // type: took any string at all and reached the gallery as a filter chip.
  const cases = [
    ['status', 'complete'], ['status', 'done'], ['status', 'Completed'],
    ['type', 'enhancement'], ['type', 'bogus'],
    ['effort', 'huge'],
    ['workflow', 'yes'], ['workflow', 'TRUE'],
    // A present-but-empty value is a half-finished edit, not a request for
    // the default — only an absent key defaults.
    ['status', ''], ['type', ''], ['effort', ''], ['workflow', ''],
    // A trailing YAML comment is stripped before validation, so the error
    // must still come from the value and not from the comment.
    ['status', 'complete   # oops'],
  ];
  for (const [key, value] of cases) {
    const parsed = parseSpecMarkdown(SAMPLE_SPEC);
    parsed.metadata[key] = value;
    assert.throws(
      () => renderPlanHtml(parsed, { fileName: 's.html', planPath: 's.html' }),
      // An empty value has no text to echo, so the message says (empty) —
      // asserting includes('') would pass on any string at all.
      (err) => err instanceof ParseError
        && err.message.includes(key)
        && err.message.includes(value === '' ? '(empty)' : value),
      `${key}: ${value || '(empty)'} must be rejected, not silently corrected`
    );
  }
});

ok('enumerated frontmatter accepts every documented value, and absent keys default', () => {
  const accept = [
    ['status', 'todo'], ['status', 'in-progress'], ['status', 'completed'],
    ['type', 'feature'], ['type', 'fix'], ['type', 'refactor'], ['type', 'docs'], ['type', 'chore'],
    ['effort', 'low'], ['effort', 'medium'], ['effort', 'high'],
    // auto names the heuristic; true/false are the pre-7.0 spelling of
    // always/never and must keep rendering committed specs.
    ['workflow', 'auto'], ['workflow', 'always'], ['workflow', 'never'],
    ['workflow', 'true'], ['workflow', 'false'],
  ];
  for (const [key, value] of accept) {
    const parsed = parseSpecMarkdown(SAMPLE_SPEC);
    parsed.metadata[key] = value;
    assert.doesNotThrow(
      () => renderPlanHtml(parsed, { fileName: 's.html', planPath: 's.html' }),
      `${key}: ${value} is documented and must render`
    );
  }
  // The frontmatter parser keeps everything after the colon, so the inline
  // comments used throughout the authoring docs land inside the value. Those
  // snippets must stay copy-pasteable now that these keys are strict.
  for (const [key, value] of [
    ['status', 'todo            # todo | in-progress | completed'],
    ['type', 'feature         # feature | fix | refactor | docs | chore'],
    ['effort', 'high            # low | medium | high'],
    ['workflow', 'auto            # auto | always | never'],
  ]) {
    const parsed = parseSpecMarkdown(SAMPLE_SPEC);
    parsed.metadata[key] = value;
    assert.doesNotThrow(
      () => renderPlanHtml(parsed, { fileName: 's.html', planPath: 's.html' }),
      `${key} with a trailing YAML comment must render`
    );
  }
  // The comment is stripped, not kept — a commented value must not leak into
  // the rendered attribute.
  const commented = parseSpecMarkdown(SAMPLE_SPEC);
  commented.metadata.status = 'completed      # done and dusted';
  assert.ok(
    renderPlanHtml(commented, { fileName: 's.html', planPath: 's.html' }).includes('data-status="completed"'),
    'a commented value renders as the bare value'
  );

  // An omitted key is not a near-miss — it takes the documented default.
  const bare = parseSpecMarkdown(SAMPLE_SPEC);
  for (const key of ['status', 'type', 'effort', 'workflow']) delete bare.metadata[key];
  const html = renderPlanHtml(bare, { fileName: 's.html', planPath: 's.html' });
  assert.ok(html.includes('data-status="todo"'), 'absent status defaults to todo');
  assert.ok(html.includes('<meta name="plan-type" content="feature">'), 'absent type defaults to feature');
});

ok('workflow always/never override the file-count heuristic in both directions', () => {
  const wide = SAMPLE_SPEC.replace(
    /## Files[\s\S]*?## Steps/,
    '## Files\n- a/one.mjs (new)\n- b/two.mjs (new)\n- c/three.mjs (new)\n- d/four.mjs (new)\n- e/five.mjs (new)\n\n## Steps'
  );
  const render = (spec, workflow) => {
    const parsed = parseSpecMarkdown(spec);
    if (workflow) parsed.metadata.workflow = workflow;
    return renderPlanHtml(parsed, { fileName: 'w.html', planPath: 'w.html' });
  };
  // workflow: never on a spec the heuristic would have opted in — expect no
  // workflow row and no fan-out license.
  assert.ok(!render(wide, 'never').includes('id="workflow-cmd"'), 'workflow: never leaves no workflow row on a wide spec');
  assert.ok(!render(wide, 'never').includes('Fan out across parallel subagents'), 'workflow: never leaves no fan-out license on a wide spec');
  // workflow: always on a spec too small for the heuristic — expect both.
  assert.ok(render(SAMPLE_SPEC, 'always').includes('id="workflow-cmd"'), 'workflow: always adds a workflow row to a small spec');
  assert.ok(render(SAMPLE_SPEC, 'always').includes('Fan out across parallel subagents'), 'workflow: always adds the fan-out license to a small spec');
  // auto and an absent key agree.
  assert.equal(render(wide, 'auto'), render(wide, null), 'auto is the same as omitting the key');
});

ok('the auto heuristic fires at 4 files across 2 directories, not below', () => {
  const withFiles = (...paths) => parseSpecMarkdown(SAMPLE_SPEC.replace(
    /## Files[\s\S]*?## Steps/,
    `## Files\n${paths.map((p) => `- ${p} (new)`).join('\n')}\n\n## Steps`
  ));
  const fires = (...paths) => renderPlanHtml(withFiles(...paths), { fileName: 'w.html', planPath: 'w.html' })
    .includes('id="workflow-cmd"');

  // Both halves of the && are load-bearing: neither count alone opts in.
  assert.ok(fires('a/1.mjs', 'a/2.mjs', 'b/3.mjs', 'b/4.mjs'), '4 files across 2 dirs opts in');
  assert.ok(!fires('a/1.mjs', 'a/2.mjs', 'b/3.mjs'), '3 files across 2 dirs stays out');
  assert.ok(!fires('a/1.mjs', 'a/2.mjs', 'a/3.mjs', 'a/4.mjs'), '4 files in 1 dir stays out');
  // Bare filenames share the repo root — they are one directory, not four.
  assert.ok(!fires('README.md', 'package.json', 'LICENSE', 'Makefile'), '4 root-level files are 1 dir, not 4');
  assert.ok(fires('README.md', 'LICENSE', 'a/1.mjs', 'a/2.mjs'), 'root plus one nested dir is 2 dirs');
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

/* ── Unit: `### Phase:` groupings inside Steps ────────────────────── */

/** SAMPLE_SPEC's two-step Steps section with `steps` substituted verbatim. */
const withSteps = (steps) =>
  SAMPLE_SPEC.replace(
    '1. Do the first thing. Why: because it unblocks everything. Verify: run the check.\n2. Do the second thing. Why: because the first is not enough. Verify: run the other check.',
    steps,
  );

ok('parseSpecMarkdown groups steps under phase headings, flat numbering intact', () => {
  // Heading before the first step AND a heading between two steps — the second
  // is the case that used to be folded into step 1's Verify: text.
  const { sections } = parseSpecMarkdown(withSteps(
    `### Phase: Alpha

1. Do the first thing. Why: because it unblocks everything. Verify: run the check.

### Phase: Beta

2. Do the second thing. Why: because the first is not enough. Verify: run the other check.`,
  ));
  assert.deepEqual(sections.phases, [
    { name: 'Alpha', firstStep: 1, lastStep: 1 },
    { name: 'Beta', firstStep: 2, lastStep: 2 },
  ]);
  // Same two steps as the unphased spec: grouping must not touch content.
  assert.deepEqual(sections.steps, parseSpecMarkdown(SAMPLE_SPEC).sections.steps);
});

ok('a phase heading between two steps never leaks into the preceding Verify: text', () => {
  const { sections } = parseSpecMarkdown(withSteps(
    `1. Do the first thing. Why: because it unblocks everything. Verify: run the check.
### Phase: Beta
2. Do the second thing. Why: because the first is not enough. Verify: run the other check.`,
  ));
  for (const s of sections.steps) {
    assert.ok(!s.verify.includes('#'), `heading markup leaked into a verify: ${s.verify}`);
    assert.ok(!s.verify.includes('Phase'), `phase name leaked into a verify: ${s.verify}`);
  }
  // Steps before the first heading belong to no phase — the range starts at 2.
  assert.deepEqual(sections.phases, [{ name: 'Beta', firstStep: 2, lastStep: 2 }]);
});

ok('a step whose Verify: text contains a hash character is left alone', () => {
  const { sections } = parseSpecMarkdown(withSteps(
    `### Phase: Alpha

1. Do the first thing. Why: because it unblocks everything. Verify: confirm issue #42 closed and the ### marker survives.
2. Do the second thing. Why: because the first is not enough. Verify: run the other check.`,
  ));
  assert.equal(sections.steps[0].verify, 'confirm issue #42 closed and the ### marker survives.');
  assert.deepEqual(sections.phases, [{ name: 'Alpha', firstStep: 1, lastStep: 2 }]);
});

ok('a Steps section with no phase heading parses phases as null', () => {
  assert.equal(parseSpecMarkdown(SAMPLE_SPEC).sections.phases, null);
});

ok('a phase heading with no steps under it is a ParseError', () => {
  assert.throws(
    () => parseSpecMarkdown(withSteps(
      `### Phase: Empty

### Phase: Alpha

1. Do the first thing. Why: because it unblocks everything. Verify: run the check.
2. Do the second thing. Why: because the first is not enough. Verify: run the other check.`,
    )),
    (err) => err instanceof ParseError && /phase "Empty" has no steps/.test(err.message),
  );
});

ok('buildDigest re-emits phase headings so they survive a spec reconstruction', () => {
  const { sections } = parseSpecMarkdown(withSteps(
    `### Phase: Alpha

1. Do the first thing. Why: because it unblocks everything. Verify: run the check.

### Phase: Beta

2. Do the second thing. Why: because the first is not enough. Verify: run the other check.`,
  ));
  const digest = unguardScriptClose(buildDigest(sections));
  assert.match(digest, /### Phase: Alpha/);
  assert.match(digest, /### Phase: Beta/);
  assert.deepEqual(parseSpecMarkdown(digest).sections.phases, sections.phases);
  assert.deepEqual(parseSpecMarkdown(digest).sections, sections);
});

/* ── Unit: the `## Decisions` ledger ──────────────────────────────── */

const withDecisions = (block) => SAMPLE_SPEC.replace('## Files', `${block}\n## Files`);

ok('parseSpecMarkdown reads Decisions bullets, null when the section is absent', () => {
  assert.equal(parseSpecMarkdown(SAMPLE_SPEC).sections.decisions, null);
  const one = parseSpecMarkdown(withDecisions('## Decisions\n- Only one choice was settled.\n'));
  assert.deepEqual(one.sections.decisions, ['Only one choice was settled.']);
  const many = parseSpecMarkdown(withDecisions('## Decisions\n- First choice.\n- Second choice.\n- Third choice.\n'));
  assert.deepEqual(many.sections.decisions, ['First choice.', 'Second choice.', 'Third choice.']);
});

ok('a present-but-empty Decisions section is a ParseError, not a silent null', () => {
  assert.throws(() => parseSpecMarkdown(withDecisions('## Decisions\n\n')), ParseError);
});

ok('Decisions round-trips through buildDigest and renders its own card', () => {
  const parsed = parseSpecMarkdown(withDecisions('## Decisions\n- First choice.\n- Second choice.\n'));
  const again = parseSpecMarkdown(unguardScriptClose(buildDigest(parsed.sections)));
  assert.deepEqual(again.sections, parsed.sections);
  assert.ok(shell.SECTION_CHROME.decisions, 'SECTION_CHROME needs a decisions entry to render the card');
  const html = renderPlanHtml(parsed, { fileName: 'd.html', planPath: 'docs/plans/d.html', repo: 'r' });
  assert.match(html, /id="decisions"/);
  assert.deepEqual(extractSections(html).decisions, parsed.sections.decisions);
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
  // Pin the spec path and each prompt's distinguishing lead-in, not the whole
  // string — the verify gate's wording is tuned between releases and an
  // assertion that spans it fails on copy edits that change no behaviour.
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-implement" content="Read and implement all steps in the plan at docs/plans/sample.md — Ship a sample feature.'
    )
  );
  assert.ok(
    sampleHtml.includes(
      '<meta name="plan-goal" content="Achieve this goal: Ship a sample feature. The plan at docs/plans/sample.md describes one approach — use it as reference, but optimize for the outcome.'
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
    assert.match(p, /\bTests\b/, 'names the runnable checks');
    assert.match(p, /\bVerification\b/, 'names end-to-end verification');
    assert.match(p, /\bAcceptance Criteria\b/, 'names the criteria check');
    assert.match(p, /\bw\.md\b/, 'says where the outcome gets recorded');
    assert.match(p, /\bcompleted\b/, 'has a success state');
    assert.match(p, /\bfailed\b/, 'has a failure path that does not mark done');
    // Only copyCmd() rebuilds a prompt from live DOM state; copyGoal() and
    // copyWorkflow() copy this tail verbatim. An unfinished spec has no `[x]`
    // to copy and the rendered progress bar reads from those markers, so the
    // record clause has to spell them out or two of the three paths ship a
    // plan that reports done at 0/N.
    assert.match(p, /\[x\] marker/, 'names the step marker to tick');
    assert.match(p, /- \[x\]/, 'names the criterion marker to tick');
    assert.match(p, /set status: completed/, 'names the status literal to write');
    assert.match(p, /re-render the HTML/, 'orders the re-render — the PostToolUse hook was observed not firing on Edit');
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

ok('the follow-ups heading matches case-insensitively and accepts "Out of Scope"', () => {
  // Every one of these used to parse as an unknown heading and be discarded
  // silently — a clean exit 0 with the follow-up cards missing from the HTML.
  for (const heading of ['## Next steps', '## NEXT STEPS', '## Out of Scope', '## Out of scope']) {
    const spec = NEXT_STEPS_SPEC.replace('## Next Steps', heading);
    const { nextSteps } = parseSpecMarkdown(spec);
    assert.ok(nextSteps, `${heading} produced no nextSteps`);
    assert.equal(nextSteps.items.length, 2, `${heading} lost items`);
    const html = renderPlanHtml(parseSpecMarkdown(spec), { fileName: 'ns.html', planPath: 'ns.html' });
    assert.equal(
      (html.match(/<details class="next-step-item">/g) || []).length,
      2,
      `${heading} rendered no cards`,
    );
  }
  // A heading that is genuinely not the follow-ups section stays unmatched.
  assert.equal(parseSpecMarkdown(NEXT_STEPS_SPEC.replace('## Next Steps', '## Resources')).nextSteps, null);
});

ok('Next Steps survives the HTML round trip instead of being dropped', () => {
  const parsed = parseSpecMarkdown(NEXT_STEPS_SPEC);
  const html = renderPlanHtml(parsed, { fileName: 'ns.html', planPath: 'ns.html' });
  // extractNextSteps is the read-side twin of the renderer's card markup.
  const recovered = extractNextSteps(html);
  assert.deepEqual(recovered, parsed.nextSteps, 'recovered cards differ from the authored ones');
  // The full recovery path a plan with no .md sibling goes through:
  // HTML -> sections + nextSteps -> digest markdown -> parse -> render.
  const digest = unguardScriptClose(buildDigest(extractSections(html), recovered));
  assert.match(digest, /^## Next Steps$/m, 'digest lost the Next Steps section');
  const reparsed = parseSpecMarkdown(digest);
  assert.deepEqual(reparsed.nextSteps, parsed.nextSteps, 'digest round trip changed the cards');
  const rehtml = renderPlanHtml(reparsed, { fileName: 'ns.html', planPath: 'ns.html' });
  assert.equal(
    (rehtml.match(/<details class="next-step-item">/g) || []).length,
    2,
    're-rendered plan lost its cards',
  );
  // Plans with no follow-ups still round-trip to nothing, not an empty section.
  assert.equal(extractNextSteps(sampleHtml), null);
});

ok('angle-bracket placeholders in a prompt survive extraction', () => {
  // The prompt is escaped on the way in, so the <pre> holds no markup — and a
  // regex tag-strip here would silently eat the placeholders a prompt like
  // `gh repo clone <owner>/<repo>` depends on.
  const spec = `${SAMPLE_SPEC}
## Next Steps

- Clone and patch the repo
  \`\`\`text
  Run gh repo clone <owner>/<repo>, then edit <path>/config.json.
  \`\`\`
`;
  const parsed = parseSpecMarkdown(spec);
  const prompt = 'Run gh repo clone <owner>/<repo>, then edit <path>/config.json.';
  assert.equal(parsed.nextSteps.items[0].prompt, prompt);
  const html = renderPlanHtml(parsed, { fileName: 'ns.html', planPath: 'ns.html' });
  assert.ok(html.includes('&lt;owner&gt;/&lt;repo&gt;'), 'placeholders must be escaped in the HTML');
  assert.equal(extractNextSteps(html).items[0].prompt, prompt, 'placeholders lost on extraction');
});

ok('a prompt keeps a nested fence when the outer fence is longer', () => {
  // CommonMark: a fence closes only on the same character at >= its own
  // length. The old open/closed toggle ended the prompt at the inner ```yaml
  // and leaked the remainder into the card description.
  const spec = `${SAMPLE_SPEC}
## Next Steps

- Add the dispatcher
  \`\`\`\`text
  Add commands/panel-bg.md with this frontmatter:

  \`\`\`yaml
  description: run in background
  \`\`\`

  Then run npm test to verify.
  \`\`\`\`
`;
  const expected = 'Add commands/panel-bg.md with this frontmatter:\n\n```yaml\ndescription: run in background\n```\n\nThen run npm test to verify.';
  const { nextSteps } = parseSpecMarkdown(spec);
  assert.equal(nextSteps.items.length, 1);
  assert.equal(nextSteps.items[0].prompt, expected, 'prompt truncated at the nested fence');
  assert.equal(nextSteps.items[0].desc, '', 'prompt tail leaked into the description');
  // Headings after a nested fence are still found — an unbalanced toggle
  // would swallow the rest of the spec.
  const withTrailing = parseSpecMarkdown(`${spec}\n## Completion Report\n- A finding — a reason\n`);
  assert.equal(withTrailing.progress.report.length, 1, 'heading after the nested fence was swallowed');
  // buildDigest re-emits an outer fence long enough to survive re-parsing.
  const digest = unguardScriptClose(buildDigest(parseSpecMarkdown(spec).sections, nextSteps));
  assert.equal(parseSpecMarkdown(digest).nextSteps.items[0].prompt, expected, 'digest re-fenced the prompt too short');
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

/* ── Inline Markdown in prose ─────────────────────────────────────── */

/** Focused fixture: every inline marker, plus the shapes that must NOT be
 * mistaken for one — a doubled-star glob inside backticks, a bare slash-glob,
 * and a bare number (which an index-based code-span placeholder would eat). */
const INLINE_SPEC = `# Plan: Inline markers

## Objective
Render \`kit/plugins/x.mjs\` with **bold** and *italic* intact.

## Context
\`artifact-tools\` ships two commands. **Risk — collision.** *Mitigation:* none.

Globs stay literal: \`**/*.md\` matches, and */skills/* is not emphasis.
The build takes 5 minutes and 12 seconds.

## Steps
1. Write \`a.md\`. Why: **framing** only. Verify: run \`bash t.sh\`.
2. Delete *nothing*. Why: it is *load-bearing*. Verify: \`node x.mjs\` exits 0.

## Acceptance Criteria
- \`foo.mjs\` is **done**.

## Verification
Run \`node x.mjs\` and confirm **every** check passes.
`;

const inlineParsed = parseSpecMarkdown(INLINE_SPEC);
const inlineHtml = renderPlanHtml(inlineParsed, { fileName: 'i.html', planPath: 'i.html' });

ok('inline markers render as tagged spans, not literal characters', () => {
  assert.ok(inlineHtml.includes('<code class="md">kit/plugins/x.mjs</code>'), 'backticks become a code span');
  assert.ok(inlineHtml.includes('<strong class="md">bold</strong>'), 'double stars become strong');
  assert.ok(inlineHtml.includes('<em class="md">italic</em>'), 'single stars become em');
  // The bug this fixes: markers surviving into the page as visible characters.
  const objective = inlineHtml.slice(inlineHtml.indexOf('id="objective"'), inlineHtml.indexOf('plan-implement'));
  assert.ok(!objective.includes('`'), 'no literal backtick reaches the rendered objective');
  assert.ok(!objective.includes('**'), 'no literal double-star reaches the rendered objective');
});

ok('inline markers survive the render → extract round trip byte for byte', () => {
  // The whole reason inline() and remark() must stay a matched pair: an
  // extractor that only stripped tags would silently delete every marker,
  // and the next render would lose the formatting for good.
  assert.deepEqual(extractSections(inlineHtml), inlineParsed.sections);
});

ok('inline markdown does not fire on globs, bare numbers, or non-prose code', () => {
  const context = inlineHtml.slice(inlineHtml.indexOf('id="context"'), inlineHtml.indexOf('id="files"') + 1 || inlineHtml.indexOf('id="steps"'));
  // A doubled-star glob inside backticks must stay inside the code span —
  // reading it as bold would emit <strong> and corrupt the path.
  assert.ok(context.includes('<code class="md">**/*.md</code>'), 'glob inside backticks is not read as bold');
  assert.ok(!context.includes('<em class="md">/skills/</em>'), 'bare slash-glob is not read as emphasis');
  assert.ok(context.includes('5 minutes and 12 seconds'), 'bare numbers are not eaten by the code-span placeholder');
  // File-tree leaves and the copyable prompts use bare <code>; gaining a
  // class here would make the extractor wrap them in backticks.
  assert.ok(inlineHtml.includes('<code id="implement-cmd"'), 'the implement prompt keeps its bare code element');
  assert.ok(!/<code class="md"[^>]*id="/.test(inlineHtml), 'no prompt element is tagged as inline markdown');
});

ok('a star attached to a word never opens emphasis across the next glob', () => {
  // Regression: the first guard only rejected slashes inside the span, so the
  // star in `product-reviewer-*.md` paired with the star of the NEXT glob and
  // swallowed every word between them into one <em> — 569 characters in the
  // worst committed plan. The round-trip test could not see it: remark()
  // faithfully restores both stars, so only the rendered page was wrong.
  const prose = 'Reads plan-reviewer-*.md agent definitions and mirrors the product-reviewer-*.md siblings.';
  const out = inline(prose);
  assert.ok(!out.includes('<em'), `a glob pair must not open emphasis, got: ${out}`);
  assert.ok(out.includes('plan-reviewer-*.md') && out.includes('product-reviewer-*.md'), 'both globs keep their stars');

  // Two bare extension globs in one sentence are the same trap.
  assert.ok(!inline('Match *.md and *.ts under docs.').includes('<em'), 'bare extension globs are not emphasis');

  // ...while real emphasis, including multi-word, still renders. Committed
  // plans use all of these shapes.
  for (const [text, want] of [
    ['Delete *nothing* from the file.', 'nothing'],
    ['*Mitigation:* none.', 'Mitigation:'],
    ['It is a *prose rewrite*, not a port.', 'prose rewrite'],
    ['Confirm *the document contradicts itself* here.', 'the document contradicts itself'],
  ]) {
    assert.ok(inline(text).includes(`<em class="md">${want}</em>`), `real emphasis must survive: ${text}`);
  }
});

ok('a NUL in the source text cannot forge the code-span placeholder', () => {
  // The placeholder is NUL-delimited. UTF-8 can encode NUL, so a spec
  // carrying one could otherwise impersonate a placeholder and render as
  // <code class="md">undefined</code>. Stripping on the way in closes that.
  const nul = String.fromCharCode(0);
  const forged = `Prefix ${nul}0${nul} suffix with a real \`span\` after it.`;
  const out = inline(forged);
  assert.ok(!out.includes('undefined'), `a forged placeholder must not resolve, got: ${out}`);
  assert.equal((out.match(/<code class="md">/g) || []).length, 1, 'only the real backtick span becomes a code span');
  assert.ok(out.includes('<code class="md">span</code>'), 'the real span still renders');
  assert.ok(!out.includes(nul), 'no raw NUL survives into the rendered page');
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

ok('CLI creates missing -o parent directories', () => {
  // The skills document the artifact-plan re-render as
  // `-o "$SCRATCHPAD/<stem>.html"`, and <stem> always carries directories
  // (docs/plans/foo). Without mkdir the renderer died with an unhandled
  // ENOENT stack trace, so the documented command could not be run as written.
  const spec = join(tmp, 'nested-src.md');
  const out = join(tmp, 'nested', 'docs', 'plans', 'nested-src.html');
  writeFileSync(spec, SAMPLE_SPEC);
  const res = spawnSync('node', [RENDERER, spec, '-o', out], { encoding: 'utf8' });
  assert.equal(res.status, 0, res.stderr);
  assert.ok(existsSync(out), `${out} was not written`);
  assert.ok(readFileSync(out, 'utf8').startsWith('<!DOCTYPE html>'));
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

/* ── Unit + integration: --check ──────────────────────────────────── */

/** Render `spec` to `out` inside tmp, then return both paths. */
function rendered(name, specText = SAMPLE_SPEC) {
  const spec = join(tmp, `${name}.md`);
  const out = join(tmp, `${name}.html`);
  writeFileSync(spec, specText);
  execFileSync('node', [RENDERER, spec, '-o', out]);
  return { spec, out };
}

const check = (spec, out) => spawnSync('node', [RENDERER, spec, '-o', out, '--check'], { encoding: 'utf8' });

/** The row labels --check actually printed, in printed order. */
const rowOrder = (stdout) =>
  [...stdout.matchAll(/^ {2}(html|steps|criteria) +(?:PASS|FAIL|SKIP)\b/gm)].map((m) => m[1]);

ok('rendering an unchanged spec twice over one output path is byte-identical', () => {
  // --check is a byte comparison, so a genuinely volatile field — a timestamp,
  // a generated id, a locale-dependent date — would fail it on every correct
  // plan. This is the property that makes the whole gate viable.
  const { spec, out } = rendered('determinism');
  const first = readFileSync(out, 'utf8');
  execFileSync('node', [RENDERER, spec, '-o', out]);
  assert.equal(readFileSync(out, 'utf8'), first, 're-render introduced a volatile field');

  // The one field that could drift is plan-created, which is read back from
  // the existing HTML precisely so it does not.
  const bare = rendered('determinism-nocreated', SAMPLE_SPEC.replace('created: 2026-07-12\n', ''));
  const before = readFileSync(bare.out, 'utf8');
  execFileSync('node', [RENDERER, bare.spec, '-o', bare.out]);
  assert.equal(readFileSync(bare.out, 'utf8'), before, 'plan-created was restamped instead of read back');
});

ok('a different output path changes plan-file/plan-path and nothing else', () => {
  // These two are DERIVED FROM the output path, not volatile — which is why
  // --check compares at a fixed path rather than normalizing them away.
  // Normalizing would let the check pass an HTML file copied in from another
  // location, one of the exact stale states it exists to catch.
  const spec = join(tmp, 'crosspath.md');
  writeFileSync(spec, SAMPLE_SPEC);
  execFileSync('node', [RENDERER, spec, '-o', join(tmp, 'crosspath-one.html')]);
  execFileSync('node', [RENDERER, spec, '-o', join(tmp, 'crosspath-two.html')]);
  const one = readFileSync(join(tmp, 'crosspath-one.html'), 'utf8').split('\n');
  const two = readFileSync(join(tmp, 'crosspath-two.html'), 'utf8').split('\n');
  assert.equal(one.length, two.length, 'a path change must not alter the line count');
  const differing = one.filter((line, i) => line !== two[i]);
  assert.ok(differing.length > 0, 'the output path must be visible in the render at all');
  for (const line of differing) {
    assert.match(
      line,
      /plan-file|plan-path/,
      `a field other than plan-file/plan-path varies with the output path: ${line.slice(0, 80)}`
    );
  }
});

ok('firstDiff anchors its window on the first differing column', () => {
  assert.equal(firstDiff('identical', 'identical'), null, 'equal input has no first difference');
  // A plan's longest lines are the several-hundred-character prompt meta tags;
  // a window taken from column 0 would print the same 40 characters twice.
  const long = 'x'.repeat(200);
  const d = firstDiff(`${long}A`, `${long}B`);
  assert.equal(d.line, 1);
  assert.equal(d.column, 201);
  assert.ok(d.onDisk.includes('A'), `the differing character must be inside the window: ${d.onDisk}`);
  assert.ok(d.rendered.includes('B'), `the differing character must be inside the window: ${d.rendered}`);
  assert.ok(d.onDisk.length < 60, `the window is bounded, not the whole line: ${d.onDisk.length}`);
  // A file that simply ends early reports a line, not a crash on undefined.
  const short = firstDiff('one\ntwo', 'one\ntwo\nthree');
  assert.equal(short.line, 3);
  assert.match(short.onDisk, /file ends here/);
});

ok('--check exits 0 with a PASS row for a freshly rendered plan', () => {
  const { spec, out } = rendered('check-fresh');
  const res = check(spec, out);
  assert.equal(res.status, 0, `${res.stdout}${res.stderr}`);
  assert.match(res.stdout, /^ {2}html +PASS/m, 'html row passes');
  assert.match(res.stdout, /^check: PASS/m, 'summary line reports PASS');
});

ok('--check writes nothing at all', () => {
  const { spec, out } = rendered('check-readonly');
  const before = readFileSync(out, 'utf8');
  const listBefore = readdirSync(tmp).sort();
  assert.equal(check(spec, out).status, 0);
  assert.equal(readFileSync(out, 'utf8'), before, '--check modified the HTML it was asked to verify');
  assert.deepEqual(readdirSync(tmp).sort(), listBefore, '--check created or removed a file');
});

ok('--check reports the first differing line of a stale HTML file', () => {
  const { spec, out } = rendered('check-stale');
  const lines = readFileSync(out, 'utf8').split('\n');
  const idx = lines.findIndex((l) => l.includes('<meta name="plan-type"'));
  assert.ok(idx > 0, 'fixture must contain a plan-type meta tag to corrupt');
  lines[idx] += 'DRIFT';
  writeFileSync(out, lines.join('\n'));

  const res = check(spec, out);
  assert.equal(res.status, 1, 'a stale render must exit non-zero');
  assert.match(res.stdout, /^ {2}html +FAIL/m, 'the html row is the one that fails');
  assert.match(res.stdout, new RegExp(`first difference at line ${idx + 1}\\b`), 'names the edited line number');
  assert.match(res.stdout, /on disk:/, 'shows the on-disk side');
  assert.match(res.stdout, /rendered:/, 'shows the freshly rendered side');
  assert.ok(readFileSync(out, 'utf8').includes('DRIFT'), '--check repaired the file instead of reporting it');
});

ok('--check on a missing HTML file fails with the render command named, not a stack trace', () => {
  const spec = join(tmp, 'check-missing.md');
  const out = join(tmp, 'check-missing.html');
  writeFileSync(spec, SAMPLE_SPEC);
  assert.ok(!existsSync(out), 'the output file must be absent for this case');

  const res = check(spec, out);
  assert.equal(res.status, 1);
  assert.match(res.stdout, /^ {2}html +FAIL/m);
  assert.match(res.stdout, /does not exist/);
  assert.ok(res.stdout.includes(`plan-agent-render "${spec}" -o "${out}"`), 'names the command that fixes it');
  assert.ok(!/^\s+at /m.test(res.stderr), `a missing file must not throw: ${res.stderr}`);
  assert.ok(!existsSync(out), '--check must not create the missing file');
});

ok('--check skips the consistency rows below status: completed', () => {
  // A todo or in-progress plan with unchecked steps is correct, not
  // inconsistent — asserting completeness there would fail every live plan.
  const { spec, out } = rendered('check-partial', PARTIAL_SPEC);
  const res = check(spec, out);
  assert.equal(res.status, 0, `${res.stdout}${res.stderr}`);
  assert.match(res.stdout, /^ {2}steps +SKIP/m, 'steps skipped, not passed');
  assert.match(res.stdout, /^ {2}criteria +SKIP/m, 'criteria skipped, not passed');
  assert.match(res.stdout, /^check: PASS \(1 passed, 2 skipped, 0 failed\)/m);
});

ok('--check passes a completed spec that is genuinely complete', () => {
  const { spec, out } = rendered('check-done', DONE_SPEC);
  const res = check(spec, out);
  assert.equal(res.status, 0, `${res.stdout}${res.stderr}`);
  assert.match(res.stdout, /^ {2}steps +PASS/m);
  assert.match(res.stdout, /^ {2}criteria +PASS/m);
  assert.match(res.stdout, /^check: PASS \(3 passed, 0 skipped, 0 failed\)/m);
});

ok('--check fails a completed spec with an unchecked criterion, quoting it', () => {
  const openCriterion = DONE_SPEC.replace('- [x] The second criterion holds.', '- The second criterion holds.');
  const { spec, out } = rendered('check-open-criterion', openCriterion);
  const res = check(spec, out);
  assert.equal(res.status, 1, 'an incomplete completed-spec must exit non-zero');
  assert.match(res.stdout, /^ {2}criteria +FAIL/m);
  assert.ok(res.stdout.includes('The second criterion holds.'), 'quotes the offending criterion text');
  // The HTML was rendered from this very spec, so freshness still holds — the
  // two properties are reported independently, which is the point of the table.
  assert.match(res.stdout, /^ {2}html +PASS/m, 'a spec-consistency failure must not implicate the html row');
});

ok('--check fails a completed spec with an unchecked step, quoting it', () => {
  const openStep = DONE_SPEC.replace('2. [x] Do the second thing.', '2. Do the second thing.');
  const { spec, out } = rendered('check-open-step', openStep);
  const res = check(spec, out);
  assert.equal(res.status, 1);
  assert.match(res.stdout, /^ {2}steps +FAIL/m);
  assert.ok(res.stdout.includes('Do the second thing.'), 'quotes the offending step action');
  assert.match(res.stdout, /^ {2}criteria +PASS/m, 'the criteria row is unaffected');
});

ok('--check prints its rows in a fixed order for pass, stale, and inconsistent plans', () => {
  // The model has to find the property that broke without parsing prose, and a
  // stable order is what the reader (and this assertion) can rely on.
  const pass = rendered('order-pass');
  const stale = rendered('order-stale');
  writeFileSync(stale.out, `${readFileSync(stale.out, 'utf8')}\n<!-- drift -->`);
  const bad = rendered('order-bad', DONE_SPEC.replace('- [x] The second criterion holds.', '- The second criterion holds.'));

  // Spelled out, NOT compared against the imported CHECK_ROWS: reordering that
  // constant would reorder both sides of the assertion and the test would keep
  // passing while the printed order silently changed.
  const EXPECTED = ['html', 'steps', 'criteria'];
  assert.deepEqual(CHECK_ROWS, EXPECTED, 'the exported row contract changed — update the gate docs too');

  const outputs = [check(pass.spec, pass.out), check(stale.spec, stale.out), check(bad.spec, bad.out)];
  assert.deepEqual(outputs.map((r) => r.status), [0, 1, 1], 'the three scenarios must differ in exit status');
  for (const res of outputs) {
    assert.deepEqual(rowOrder(res.stdout), EXPECTED, `row order drifted: ${res.stdout}`);
  }
});

ok('--check on a spec missing a required section exits 1 without a stack trace', () => {
  // parseSpecMarkdown requires ## Acceptance Criteria, so this is a spec error
  // reported as one — an exit 1 with guidance, never an unhandled throw.
  const spec = join(tmp, 'check-nocriteria.md');
  writeFileSync(spec, SAMPLE_SPEC.replace('## Acceptance Criteria', '## Removed'));
  const res = check(spec, join(tmp, 'check-nocriteria.html'));
  assert.equal(res.status, 1);
  assert.match(res.stderr, /not a valid plan spec/);
  assert.ok(!/^\s+at /m.test(res.stderr), `must not print a stack trace: ${res.stderr}`);
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

// A sibling's existence is the file-published signal, so every hook case below
// seeds one before writing the spec. Without it the hook correctly skips the
// render (see tests/plugins/test-render-hook-artifact-skip.sh) and these
// assertions would pass vacuously.
ok('hook regenerates an existing sibling HTML for a spec written in the plans dir', () => {
  const proj = makeProject();
  const spec = join(proj, 'docs', 'plans', 'sample.md');
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  writeFileSync(spec, SAMPLE_SPEC);
  writeFileSync(join(proj, 'docs', 'plans', 'sample.html'), '<html><body>stale</body></html>\n');
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
  // Seeded so the assertion means "left alone", not "the sibling gate skipped it".
  writeFileSync(join(proj, 'notes', 'readme.html'), '<html><body>stale</body></html>\n');
  assert.equal(runHook(proj, outside).status, 0);
  assert.doesNotMatch(readFileSync(join(proj, 'notes', 'readme.html'), 'utf8'), /<title>Plan:/,
    'markdown outside the plans dir is not rendered');
  const notSpec = join(proj, 'docs', 'plans', 'notes.md');
  writeFileSync(notSpec, '# Notes\n\nJust notes.\n');
  writeFileSync(join(proj, 'docs', 'plans', 'notes.html'), '<html><body>stale</body></html>\n');
  assert.equal(runHook(proj, notSpec).status, 0);
  assert.doesNotMatch(readFileSync(join(proj, 'docs', 'plans', 'notes.html'), 'utf8'), /<title>Plan:/,
    'non-spec markdown is not rendered');
  rmSync(proj, { recursive: true, force: true });
});

ok('hook honors plansDirectory from settings.local.json over settings.json', () => {
  const proj = makeProject({ localSettings: { plansDirectory: 'custom/plans' } });
  mkdirSync(join(proj, 'custom', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const customSpec = join(proj, 'custom', 'plans', 'sample.md');
  writeFileSync(customSpec, SAMPLE_SPEC);
  writeFileSync(join(proj, 'custom', 'plans', 'sample.html'), '<html><body>stale</body></html>\n');
  assert.equal(runHook(proj, customSpec).status, 0);
  assert.match(readFileSync(join(proj, 'custom', 'plans', 'sample.html'), 'utf8'), /<title>Plan:/,
    'custom plans dir re-renders');
  const defaultSpec = join(proj, 'docs', 'plans', 'other.md');
  writeFileSync(defaultSpec, SAMPLE_SPEC);
  writeFileSync(join(proj, 'docs', 'plans', 'other.html'), '<html><body>stale</body></html>\n');
  assert.equal(runHook(proj, defaultSpec).status, 0);
  assert.doesNotMatch(readFileSync(join(proj, 'docs', 'plans', 'other.html'), 'utf8'), /<title>Plan:/,
    'docs/plans ignored when custom dir configured');
  rmSync(proj, { recursive: true, force: true });
});

ok('hook prefers the plugin-bundled renderer when the project has none', () => {
  const proj = mkdtempSync(join(tmpdir(), 'render-hook-bundled-'));
  mkdirSync(join(proj, '.claude'), { recursive: true });
  writeFileSync(join(proj, '.claude', 'settings.json'), JSON.stringify({ plansDirectory: 'docs/plans' }));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const spec = join(proj, 'docs', 'plans', 'sample.md');
  writeFileSync(spec, SAMPLE_SPEC);
  writeFileSync(join(proj, 'docs', 'plans', 'sample.html'), '<html><body>stale</body></html>\n');
  // No project scripts/ dir at all — only the bundled copy can render.
  const res = runHook(proj, spec, { CLAUDE_PLUGIN_ROOT: join(ROOT, 'kit', 'plugins', 'plan-agent') });
  assert.equal(res.status, 0, res.stderr);
  const html = readFileSync(join(proj, 'docs', 'plans', 'sample.html'), 'utf8');
  assert.deepEqual(extractSections(html), sampleParsed.sections);
  assert.ok(existsSync(join(proj, 'docs', 'plans', 'index.html')), 'gallery index rebuilt after render');
  rmSync(proj, { recursive: true, force: true });
});

ok('a spec with no prototype: key renders the same markup as the pre-change renderer', () => {
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
    // What this guard protects is the DOM contract the extractor and the
    // gallery read — NOT the rendered bytes. Presentation is expected to
    // evolve: a byte diff also fails on every deliberate markup, stylesheet,
    // and inline-script change, which makes an intentional redesign
    // indistinguishable from an accidental regression. So compare the
    // extracted spec, then assert the one thing this test was actually added
    // for: the prototype feature does not leak into a spec that never asked
    // for it.
    assert.ok(/<meta name="plan-implement" content="[^"]+"/.test(after), 'prompt payloads are non-empty');
    assert.ok(/<style\b[^>]*>\s*\S/.test(after), 'stylesheet is non-empty');
    assert.deepEqual(
      extractSections(after),
      extractSections(before),
      'the extractor contract drifted for a spec that carries no prototype: key'
    );
    assert.ok(!after.includes('name="plan-prototype"'), 'no prototype meta tag for a spec without the key');
    assert.ok(!after.includes('class="prototype-link"'), 'no prototype header link for a spec without the key');
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
  for (const rel of ['build-plan-html.mjs', 'extract-plan-spec.mjs', 'lib/plan-spec.mjs', 'lib/plan-shell.mjs']) {
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
  writeFileSync(join(proj, 'docs', 'plans', 'broken.html'), '<html><body>stale</body></html>\n');
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
