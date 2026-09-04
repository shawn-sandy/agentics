#!/usr/bin/env node
/**
 * Objective-verification test for plan phase checkpoints and the Decisions
 * ledger.
 *
 * Objective: a phased plan with a Decisions ledger survives render, extract,
 * and re-render with its phase names, phase order, and decision bullets
 * intact — and an unphased plan is completely unaffected.
 *
 * The format is bidirectional (parseSpecMarkdown ⇄ buildDigest, renderPlanHtml
 * ⇄ extractSections), so a grouping level carried at three of those four sites
 * is silent data loss rather than a missing feature. The cycle assertions
 * below are what catch a change applied to one side and missed on the other.
 *
 * The unphased check is a frozen sha256 of a fixed fixture rendered by the
 * pre-phases renderer. It is deliberately strict: the plan CSS block is
 * emitted verbatim into EVERY plan, so a single new rule silently rewrites
 * every committed plan in docs/plans/ on its next render. If you changed the
 * shell on purpose, re-derive the hash and say so in the commit.
 *
 * Also pinned: the phase checkpoint contract prose in build/SKILL.md and
 * finalize-plan/SKILL.md, guarded the way tests/plugins/test-exitplanmode-guard.sh
 * guards its own required string — this catches DELETION of the contract, not
 * a runtime behaviour claim.
 *
 * Run: node tests/plugins/test-plan-phases.mjs
 */

import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildDigest,
  extractSections,
  parseSpecMarkdown,
  ParseError,
  unguardScriptClose,
} from '../../scripts/lib/plan-spec.mjs';
import { renderPlanHtml } from '../../scripts/build-plan-html.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const SKILLS = join(ROOT, 'kit', 'plugins', 'plan-agent', 'skills');

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

const PHASED_SPEC = `---
status: in-progress
type: feature
created: 2026-01-02
repo: phase-repo
---
# Plan: A plan with phases

## Objective
Prove phases and decisions survive the round trip.

## Context
Only paragraph of context.

## Decisions
- Headings beat a \`phases:\` frontmatter range list — headings survive step insertion.
- \`build\` stops at a boundary by default and takes \`--continue\` to push through.
- Compaction is safe mid-plan because durable state lives in the spec.

## Steps

### Phase: Parse

1. [x] Teach the splitter about phase headings. Why: it folds them into step text today. Verify: no verify string contains a # character.
2. [x] Re-emit them from the digest. Why: buildDigest is the exact inverse. Verify: deep-equal after a round trip.

### Phase: Render

3. Group the step cards. Why: the progress JS counts .step-card. Verify: the count still matches.
4. Render the Decisions card. Why: a resumed session re-litigates what it cannot see. Verify: the nav gains an entry.

## Acceptance Criteria
- [x] Phases parse.
- [ ] Phases render.

## Verification
Render, extract, re-render, and diff.
`;

/** A plan phased partway through: step 1 has no phase, phasing starts at 2 —
 * the retrofit shape (finish some steps, then add checkpoints for the rest). */
const PARTIALLY_PHASED_SPEC = `---
status: in-progress
type: feature
created: 2026-01-02
repo: phase-repo
---
# Plan: A plan phased partway through

## Objective
Prove a leading unphased step does not corrupt the first phase's range.

## Steps

1. [x] Do the unphased setup step. Why: it predates the retrofit. Verify: it still carries no phase.

### Phase: Build

2. Group the step cards. Why: the progress JS counts .step-card. Verify: the count still matches.
3. Render the Decisions card. Why: a resumed session re-litigates what it cannot see. Verify: the nav gains an entry.

## Acceptance Criteria
- [x] Setup is done.
- [ ] Build phase is done.

## Verification
Render, extract, re-render, and diff.
`;

/** The frozen unphased fixture. Do not edit without re-deriving BASELINE_SHA256. */
const UNPHASED_SPEC = `---
status: todo
type: feature
created: 2026-01-02
repo: baseline-repo
glance: A frozen fixture that must never change shape.
---
# Plan: Unphased baseline

## Objective
Keep the unphased render frozen.

## Context
Only paragraph.

## Files
- scripts/a.mjs (new) — the new module

## Steps
1. Do the first thing. Why: it unblocks the rest. Verify: run the check.
2. Do the second thing. Why: the first is not enough. Verify: run the other check.

## Tests
Tier 1 — This plan changes application code
- Objective Baseline objective test File: tests/x.mjs Run: node tests/x.mjs

## Acceptance Criteria
- The first criterion holds.

## Verification
Run everything and confirm it passes.
`;

/** sha256 of renderUnphased() under the current renderer. Regenerate only for
 * a deliberate shell change. Re-derived 2026-09-04 for the header-link chips
 * (9.13.1): the prototype / issue / design anchors gained one chip rule and an
 * `order` slot in `.plan-header-actions`, shifting Save as PDF and the theme
 * toggle to orders 4 and 5, and joined the coarse-pointer 44px hit-area list.
 * Previously re-derived 2026-09-02 for the plan-document polish (eyebrow
 * removed, browser-surface theming, tabular figures, compositor-driven scroll
 * rail, objective-card side-tab removed, 44px hit areas, square theme toggle). */
const BASELINE_SHA256 = '6e3f557789423f6d829d16ffac19855efdfb7c38e106d7f5566bd74f810d93ab';

const render = (parsed, stem) =>
  renderPlanHtml(parsed, {
    fileName: `${stem}.html`,
    planPath: `docs/plans/${stem}.html`,
    mdPath: `docs/plans/${stem}.md`,
    repo: parsed.metadata.repo,
    today: '2026-01-02',
  });

/* ── Objective: the render → extract → re-render cycle ─────────────── */

ok('objective: a phased plan with Decisions survives render → extract → re-render', () => {
  const parsed = parseSpecMarkdown(PHASED_SPEC);
  const expectedPhases = [
    { name: 'Parse', firstStep: 1, lastStep: 2 },
    { name: 'Render', firstStep: 3, lastStep: 4 },
  ];
  assert.deepEqual(parsed.sections.phases, expectedPhases, 'spec parse');
  assert.equal(parsed.sections.decisions.length, 3, 'spec decisions');

  // Round 1: spec → HTML → sections.
  const html = render(parsed, 'phased');
  const extracted = extractSections(html);
  assert.deepEqual(extracted.phases, expectedPhases, 'phases lost on DOM extraction');
  assert.deepEqual(extracted.decisions, parsed.sections.decisions, 'decisions lost on DOM extraction');
  assert.deepEqual(extracted, parsed.sections, 'sections diverged on DOM extraction');

  // Round 2: sections → digest markdown → sections (the buildDigest inverse).
  const reparsed = parseSpecMarkdown(unguardScriptClose(buildDigest(extracted)));
  assert.deepEqual(reparsed.sections, parsed.sections, 'sections diverged through the digest');

  // Round 3: re-render the recovered spec — the cycle must be stable, which is
  // what proves neither side quietly normalized the other's output.
  const reHtml = render({ ...reparsed, metadata: parsed.metadata }, 'phased');
  assert.deepEqual(extractSections(reHtml), parsed.sections, 're-render diverged');
});

ok('a leading unphased step does not shift the first phase\'s range on extraction', () => {
  const parsed = parseSpecMarkdown(PARTIALLY_PHASED_SPEC);
  const expectedPhases = [{ name: 'Build', firstStep: 2, lastStep: 3 }];
  assert.deepEqual(parsed.sections.phases, expectedPhases, 'spec parse');

  const html = render(parsed, 'partial');
  // Step 1 renders as a bare card before the phase-group — stepsBody()'s
  // lead-in loop — which is exactly what extractSections() must count past.
  assert.match(html, /<div class="step-card[^"]*"[^>]*id="step-1"[\s\S]*?<div class="phase-group"/);
  const extracted = extractSections(html);
  assert.deepEqual(extracted.phases, expectedPhases, 'first phase range absorbed the leading unphased step');

  const reparsed = parseSpecMarkdown(unguardScriptClose(buildDigest(extracted)));
  assert.deepEqual(reparsed.sections, parsed.sections, 'sections diverged through the digest');
  const reHtml = render({ ...reparsed, metadata: parsed.metadata }, 'partial');
  assert.deepEqual(extractSections(reHtml), parsed.sections, 're-render diverged');
});

ok('objective: an unphased plan renders byte-identically to its pre-phases output', () => {
  const parsed = parseSpecMarkdown(UNPHASED_SPEC);
  assert.equal(parsed.sections.phases, null, 'unphased spec must parse phases as null');
  assert.equal(parsed.sections.decisions, null, 'no Decisions section must parse as null');
  const html = render(parsed, 'baseline');
  assert.ok(!html.includes('phase-group'), 'no phase wrapper in an unphased render');
  assert.ok(!html.includes('data-phase'), 'no phase attribute in an unphased render');
  assert.ok(!html.includes('id="decisions"'), 'no Decisions card without the section');
  assert.equal(
    createHash('sha256').update(html).digest('hex'),
    BASELINE_SHA256,
    'unphased render changed — a new shared-CSS rule rewrites every committed plan; if deliberate, re-derive BASELINE_SHA256',
  );
});

/* ── Render invariants the acceptance criteria name ────────────────── */

ok('every step card stays matchable by the .step-card selector inside phase groups', () => {
  const parsed = parseSpecMarkdown(PHASED_SPEC);
  const html = render(parsed, 'phased');
  // The progress bar and completion checklist both read
  // querySelectorAll('.step-card'); nesting that broke the selector would
  // silently zero them. Count the same way the browser would.
  const cards = html.match(/<div class="step-card[" ]/g) || [];
  assert.equal(cards.length, parsed.sections.steps.length, 'step-card count != step count');
  assert.match(html, /<summary>4 steps<\/summary>/, 'the sidebar rail total must equal the step count');
});

ok('each phase renders an h3 inside its data-phase wrapper, with no skipped heading level', () => {
  const html = render(parseSpecMarkdown(PHASED_SPEC), 'phased');
  for (const name of ['Parse', 'Render']) {
    assert.match(
      html,
      new RegExp(`<div class="phase-group" data-phase="${name}"[^>]*>\\s*<h3[^>]*>${name}</h3>`),
      `phase "${name}" must render an h3 inside its data-phase wrapper`,
    );
  }
  assert.equal((html.match(/<h1\b/g) || []).length, 1, 'exactly one h1');
  assert.ok((html.match(/<h2\b/g) || []).length > 0, 'h2 section headings present');
  assert.equal((html.match(/<h4\b/g) || []).length, 0, 'no h4 — the outline runs h1 → h2 → h3');
});

ok('each phase heading precedes only its own steps, in document order', () => {
  const html = render(parseSpecMarkdown(PHASED_SPEC), 'phased');
  const order = [...html.matchAll(/data-phase="([^"]+)"|id="(step-\d+)"/g)].map((m) => m[1] || m[2]);
  assert.deepEqual(order, ['Parse', 'step-1', 'step-2', 'Render', 'step-3', 'step-4']);
});

ok('a Decisions section renders a card and a sidebar nav entry', () => {
  const html = render(parseSpecMarkdown(PHASED_SPEC), 'phased');
  assert.match(html, /<section class="section-card card-decisions" id="decisions"/, 'Decisions card');
  assert.match(html, /<li><a href="#decisions">/, 'Decisions sidebar nav entry');
  // Nav entries are filtered to sections present — Decisions sits after Context.
  assert.ok(html.indexOf('href="#decisions"') > html.indexOf('href="#context"'), 'nav order');
  assert.ok(html.indexOf('id="decisions"') > html.indexOf('id="context"'), 'card order');
});

ok('a phase heading with no steps under it is a spec error, not a silent drop', () => {
  const spec = PHASED_SPEC.replace('### Phase: Render\n', '### Phase: Empty\n\n### Phase: Render\n');
  assert.throws(() => parseSpecMarkdown(spec), (err) => err instanceof ParseError && /phase "Empty" has no steps/.test(err.message));
});

ok('adding phases to an in-progress plan keeps existing [x] markers valid', () => {
  const parsed = parseSpecMarkdown(PHASED_SPEC);
  assert.deepEqual(parsed.progress.steps, [true, true, false, false], 'markers must survive grouping');
  const html = render(parsed, 'phased');
  assert.equal((html.match(/class="step-card completed"/g) || []).length, 2, 'two completed cards');
  // The first unmarked step is 3 — inside phase two. build resumes there, not
  // at a phase start, which is only true while grouping stays orthogonal.
  assert.equal(parsed.progress.steps.indexOf(false) + 1, 3);
});

/* ── Contract prose: the checkpoint loop must not be silently deleted ─ */

// The core SKILL.md bodies are held under a 600-word ceiling by
// test-progressive-disclosure.sh, so the loop's mechanics live in a reference
// file. Each string is asserted against the file that must actually carry it:
// the core states the default and the override, the reference states the offer.
const CONTRACTS = {
  'build/SKILL.md': [
    '### Phase: <name>',
    'references/phase-checkpoints.md',
    'stops at each boundary by default',
    '`--continue` overrides',
    'Unphased specs never stop',
  ],
  'build/references/phase-checkpoints.md': [
    'Compact and continue',
    'Stop here — resume later',
    'Continue without compacting',
    '/compact Keep: the plan spec at <spec path>',
    '<finished phase>',
    '/plan-agent:build <spec path>',
    '`--continue`, skip the offer',
    '## Decisions',
    'the first step with no `[x]` marker',
  ],
  'finalize-plan/SKILL.md': [
    '### Phase: <name>',
    'status: completed',
    'in-progress',
    '## Completion Report',
  ],
};

for (const [rel, strings] of Object.entries(CONTRACTS)) {
  ok(`${rel} carries its phase checkpoint contract`, () => {
    const body = readFileSync(join(SKILLS, rel), 'utf8');
    for (const s of strings) {
      assert.ok(body.includes(s), `missing contract string: ${s}`);
    }
  });
}

ok('right-sizing.md no longer sends the author to a mechanism that does not exist', () => {
  const body = readFileSync(join(SKILLS, 'implementation-plan', 'guidelines', 'right-sizing.md'), 'utf8');
  assert.ok(!body.includes('probably two plans — split it'), 'the dead-end split advice must be gone');
  assert.ok(body.includes('### Phase:'), 'right-sizing must show the phase syntax');
});

ok('section-catalog.md documents both new sections', () => {
  const body = readFileSync(join(SKILLS, 'implementation-plan', 'guidelines', 'section-catalog.md'), 'utf8');
  assert.ok(body.includes('### Phase:'), 'phase syntax');
  assert.ok(body.includes('## Decisions'), 'Decisions syntax');
});

console.log(`\n${passed} checks passed${process.exitCode ? ' (with failures)' : ''}`);
