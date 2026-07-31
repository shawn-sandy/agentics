#!/usr/bin/env node
/**
 * Objective test for plan/tracking-issue linking.
 *
 * A tracking ticket created for a plan has to stay reachable from the plan
 * itself — otherwise nobody knows which issue to close when the plan is done.
 *
 *   1. A spec carrying `issue:` renders the `plan-issue` meta tag plus a header
 *      anchor pointing at the ticket URL, with visible text and an aria-label.
 *   2. A spec without it renders neither.
 *
 * Run: node tests/plugins/test-plan-issue-link.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const ISSUE_URL = 'https://github.com/shawn-sandy/agentics/issues/512';

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

function spec(issue) {
  return `---
status: todo
type: feature
created: 2026-07-31
${issue ? `issue: ${issue}\n` : ''}---

# Plan: Track gym workouts

## Objective

Track workouts.

## Steps

1. Do the thing. Why: it is needed. Verify: it happened.

## Acceptance Criteria

- [ ] The thing is done.

## Verification

Run the thing.
`;
}

/** Extract the header issue anchor, or null. */
function issueAnchor(html) {
  const m = html.match(/<a class="issue-link" href="([^"]+)"([\s\S]*?)<\/a>/);
  if (!m) return null;
  return {
    href: m[1],
    text: m[2].replace(/^[\s\S]*?>/, '').trim(),
    ariaLabel: (m[2].match(/aria-label="([^"]*)"/) || [, ''])[1],
  };
}

function render(issue) {
  // realpath: on macOS $TMPDIR is a symlink into /private and cwd reports the
  // resolved form, which the renderer's cwd-relative paths depend on.
  // Prefix deliberately avoids the string "plan-issue": the renderer leaks the
  // project path into the HTML, which would satisfy the no-tag assertion below.
  const proj = realpathSync(mkdtempSync(join(tmpdir(), 'ticket-link-')));
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  const specPath = join(proj, 'docs', 'plans', 'track-gym-workouts.md');
  const outPath = join(proj, 'docs', 'plans', 'track-gym-workouts.html');
  writeFileSync(specPath, spec(issue));
  const res = spawnSync('node', [RENDERER, specPath, '-o', outPath], { encoding: 'utf8', cwd: proj });
  assert.equal(res.status, 0, res.stderr);
  const html = readFileSync(outPath, 'utf8');
  rmSync(proj, { recursive: true, force: true });
  return html;
}

ok('spec with issue: renders the meta tag and a header anchor to the ticket', () => {
  const html = render(ISSUE_URL);
  assert.ok(
    html.includes(`<meta name="plan-issue" content="${ISSUE_URL}">`),
    'plan-issue meta tag carries the ticket URL'
  );

  const anchor = issueAnchor(html);
  assert.ok(anchor, 'header issue anchor is present');
  assert.equal(anchor.href, ISSUE_URL, 'anchor points at the ticket');
  assert.ok(anchor.text.length > 0, 'anchor has non-empty visible text');
  assert.match(anchor.text, /512/, 'visible text names the issue number');
  assert.ok(anchor.ariaLabel.length > 0, 'anchor has a non-empty aria-label');
});

// Asserting only "non-empty" here is what let the fallback ship broken: the
// label was `Issue`, the template's `|| 'Tracking issue'` was dead code, and
// the test passed anyway. Pin the exact documented string.
ok('a URL with no trailing number falls back to the "Tracking issue" label', () => {
  const anchor = issueAnchor(render('https://example.com/tracker/plan-abc'));
  assert.ok(anchor, 'header issue anchor is present');
  assert.equal(anchor.text, 'Tracking issue', 'anchor uses the documented fallback label');
});

ok('a non-http(s) issue: value renders neither the meta tag nor the anchor', () => {
  const html = render('javascript:alert(document.domain)');
  assert.ok(!html.includes('name="plan-issue"'), 'no plan-issue meta tag for a non-http(s) scheme');
  assert.equal(issueAnchor(html), null, 'no header anchor for a non-http(s) scheme');
  assert.ok(!html.includes('javascript:alert'), 'the rejected value is not emitted anywhere');
});

ok('spec without issue: renders neither the meta tag nor the anchor', () => {
  const html = render(null);
  assert.ok(!html.includes('name="plan-issue"'), 'no plan-issue meta tag');
  assert.equal(issueAnchor(html), null, 'no header issue anchor');
});

console.log(`\n${passed} passed`);
if (process.exitCode) console.error('FAILURES — see above');
