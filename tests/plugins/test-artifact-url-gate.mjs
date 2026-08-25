#!/usr/bin/env node
// The renderer's verification-gate tail must carry the republish instruction
// when the spec is published: copyGoal and copyWorkflow copy the gate
// verbatim, so a republish clause anywhere else is dropped on two of the
// three prompt paths, and a fresh-session implementing agent would leave the
// artifact stale the moment steps start ticking.
//
// Three fixtures: artifact-url present (all three prompts name the URL),
// absent (gate unchanged — no republish talk), and a javascript: scheme
// (dropped with a warning, exactly like the issue: and design: guards).

import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const TMP = mkdtempSync(join(tmpdir(), 'artifact-url-gate-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) { console.log(`PASS: ${name}`); pass++; }
  else { console.log(`FAIL: ${name}${detail ? ` — ${detail}` : ''}`); fail++; }
}

const ARTIFACT_URL = 'https://claude.ai/public/artifacts/test-123';

function spec(artifactLine) {
  return `---
status: todo
type: feature
created: 2026-08-20
workflow: always
${artifactLine ? artifactLine + '\n' : ''}---

# Plan: Tail the prompt fixture

## Objective

Fixture objective.

## Steps

1. Do the thing Why: fixture Verify: check.

## Acceptance Criteria

- [ ] done

## Verification

Run the fixture check.
`;
}

function render(name, artifactLine) {
  const md = join(TMP, `${name}.md`);
  const html = join(TMP, `${name}.html`);
  writeFileSync(md, spec(artifactLine));
  const r = spawnSync('node', [RENDERER, md, '-o', html], { encoding: 'utf8' });
  return { r, html };
}

function metas(html) {
  const src = readFileSync(html, 'utf8');
  const get = (n) => {
    const m = src.match(new RegExp(`<meta\\s+name="${n}"\\s+content="([^"]*)"`));
    return m ? m[1] : '';
  };
  return { implement: get('plan-implement'), goal: get('plan-goal'), workflow: get('plan-workflow') };
}

// ── 1. artifact-url present ─────────────────────────────────────────────────
{
  const { r, html } = render('with-url', `artifact-url: ${ARTIFACT_URL}`);
  check('renderer exits 0 with artifact-url', r.status === 0, r.stderr);
  if (r.status === 0) {
    const m = metas(html);
    for (const [name, text] of Object.entries(m)) {
      check(`${name} prompt exists`, text.length > 0);
      check(`${name} prompt instructs republishing`, /republish/i.test(text),
        text.slice(-160));
      // Whole-token match, not a substring: the prompt must name THIS url, and
      // "…/test-123" is also a substring of "…/test-1234" and of any host that
      // merely embeds it. Extract each URL the prompt carries, drop trailing
      // sentence punctuation, then compare for equality.
      const named = (text.match(/https?:\/\/[^\s"'<>]+/g) ?? [])
        .map((u) => u.replace(/[.,;:)\]]+$/, ''));
      // Explicit `===` rather than named.includes(...): `named` is an array, so
      // includes() is already exact-equality membership, but CodeQL cannot infer
      // the receiver type and reads it as a string substring test.
      check(`${name} prompt names the artifact URL`,
        named.some((u) => u === ARTIFACT_URL),
        named.join(' ') || '(no url in prompt)');
    }
  }
}

// ── 2. artifact-url absent ──────────────────────────────────────────────────
{
  const { r, html } = render('without-url', '');
  check('renderer exits 0 without artifact-url', r.status === 0, r.stderr);
  if (r.status === 0) {
    const m = metas(html);
    check('gate unchanged when the key is absent',
      !/republish/i.test(m.implement + m.goal + m.workflow));
  }
}

// ── 3. javascript: scheme dropped with a warning ────────────────────────────
{
  const { r, html } = render('evil-url', 'artifact-url: javascript:alert(1)');
  check('renderer exits 0 on a javascript: artifact-url', r.status === 0, r.stderr);
  if (r.status === 0) {
    const m = metas(html);
    check('javascript: value never reaches the prompts',
      !/republish|javascript:alert/i.test(m.implement + m.goal + m.workflow));
    check('javascript: value is warned about', /ignoring non-http\(s\) artifact-url/i.test(r.stderr),
      (r.stderr + r.stdout).trim().slice(0, 200) || '(no warning output)');
  }
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
