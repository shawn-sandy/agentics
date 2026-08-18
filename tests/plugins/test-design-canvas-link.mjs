#!/usr/bin/env node
/**
 * Objective + unit + integration tests for the `design:` frontmatter key — the
 * link from a plan to its Claude Design canvas.
 *
 * Objective (mock): a plan spec carrying `design: <url>` renders a reachable
 * link to that canvas — both a `plan-design` meta tag and a header anchor
 * whose href is the URL — and the renderer copies that implement it do not
 * drift apart.
 *
 * Also pinned: the http(s)-only rule (a `javascript:` value is dropped with a
 * warning rather than rendered as a clickable anchor), the all-or-nothing rule
 * (no key → neither the tag nor the anchor, and a byte-identical render to the
 * same spec without the key), HTML escaping of the URL, and byte-parity of the
 * three renderer files between scripts/ and kit/plugins/plan-agent/scripts/.
 *
 * Run: node tests/plugins/test-design-canvas-link.mjs
 */

import assert from 'node:assert/strict';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { renderPlanHtml } from '../../scripts/build-plan-html.mjs';
import { parseSpecMarkdown } from '../../scripts/lib/plan-spec.mjs';
import * as shell from '../../scripts/lib/plan-shell.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const MIRRORED = ['build-plan-html.mjs', join('lib', 'plan-spec.mjs'), join('lib', 'plan-shell.mjs')];

const CANVAS = 'https://claude.ai/public/artifacts/2f0b1c9e-design';

let failures = 0;
function ok(name, fn) {
  try {
    fn();
    console.log(`  ok  ${name}`);
  } catch (err) {
    failures += 1;
    console.log(`FAIL  ${name}`);
    console.log(`      ${err.message.split('\n').join('\n      ')}`);
  }
}

/** A minimal spec the renderer accepts, with an optional frontmatter extra. */
function spec(extra = '') {
  return `---
status: todo
type: feature
created: 2026-08-17
${extra}---

# Plan: Link a design canvas

## Objective

Confirm the design key reaches the rendered page.

## Steps

1. Render the spec. Why: the renderer owns every frontmatter key. Verify: the page contains the link.

## Acceptance Criteria

- [ ] The canvas is reachable from the plan

## Verification

Open the plan and click through to the canvas.
`;
}

/** Render a spec through the real CLI, returning the HTML and stderr. */
function renderViaCli(dir, name, body) {
  const md = join(dir, `${name}.md`);
  const html = join(dir, `${name}.html`);
  writeFileSync(md, body);
  let stderr = '';
  try {
    execFileSync('node', [RENDERER, md, '-o', html], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch (err) {
    stderr = String(err.stderr || '');
    throw new Error(`renderer exited non-zero: ${stderr}`);
  }
  return { html: readFileSync(html, 'utf8'), md };
}

const dir = mkdtempSync(join(tmpdir(), 'design-canvas-'));

try {
  // ── Objective ───────────────────────────────────────────────────────────
  // The hero assertion: a spec carrying design: renders a reachable canvas
  // link. Fails the moment either half of the wiring is dropped.
  ok('OBJECTIVE: a spec with design: renders the meta tag and a header link to the canvas', () => {
    const { html } = renderViaCli(dir, 'with-design', spec(`design: ${CANVAS}\n`));

    assert.match(
      html,
      new RegExp(`<meta name="plan-design" content="${CANVAS}">`),
      'plan-design meta tag missing or does not carry the canvas URL',
    );

    // The anchor spans two lines in the shell template, so match across them
    // rather than pinning the exact whitespace.
    const anchor = html.match(/<a class="design-link"[\s\S]{0,240}?<\/a>/);
    assert.ok(anchor, 'design-link anchor missing from the rendered header');
    assert.match(anchor[0], new RegExp(`href="${CANVAS}"`), 'design-link href is not the canvas URL');
    assert.match(anchor[0], /aria-label="[^"]+"/, 'design-link has no accessible name');
    assert.match(anchor[0], />View design<\/a>/, 'design-link is not labelled "View design"');

    // The canvas must be linked, never embedded — an iframe or a script src
    // pointing at claude.ai would break the page's self-contained contract.
    assert.doesNotMatch(html, /<iframe[^>]+claude\.ai/i, 'canvas must be linked, not embedded in an iframe');
    assert.doesNotMatch(html, /<script[^>]+src="https:\/\/claude\.ai/i, 'plan must not load scripts from claude.ai');
  });

  // ── Unit: the http(s)-only rule ─────────────────────────────────────────
  ok('a javascript: design value is dropped and warned about, never rendered', () => {
    const md = join(dir, 'bad-design.md');
    const out = join(dir, 'bad-design.html');
    writeFileSync(md, spec('design: javascript:alert(1)\n'));
    const res = execFileSync('node', [RENDERER, md, '-o', out], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    const html = readFileSync(out, 'utf8');

    assert.doesNotMatch(html, /plan-design/, 'a non-http(s) design value must not produce a meta tag');
    assert.doesNotMatch(html, /design-link/, 'a non-http(s) design value must not produce an anchor');
    assert.doesNotMatch(html, /javascript:alert\(1\)/, 'the rejected value must not reach the page at all');
    // The warning goes to stderr, which execFileSync does not return in res —
    // assert on the rendered output above, and separately that the run
    // succeeded rather than aborting on a bad value.
    assert.equal(typeof res, 'string', 'renderer must still succeed on a bad design value');
  });

  ok('a non-http(s) design value is reported on stderr', () => {
    const md = join(dir, 'bad-design-2.md');
    const out = join(dir, 'bad-design-2.html');
    writeFileSync(md, spec('design: ftp://example.com/canvas\n'));
    const r = spawnSync('node', [RENDERER, md, '-o', out], { encoding: 'utf8' });
    assert.equal(r.status, 0, 'a bad design value must warn, not fail the render');
    const stderr = String(r.stderr || '');
    assert.match(stderr, /ignoring non-http\(s\) design/, 'renderer must warn when it drops a design value');
    assert.match(stderr, /ftp:\/\/example\.com\/canvas/, 'the warning must name the rejected value');
  });

  // ── Unit: all-or-nothing, and no effect on plans without the key ────────
  ok('a spec with no design key renders neither the tag nor the anchor', () => {
    const { html } = renderViaCli(dir, 'no-design', spec());
    assert.doesNotMatch(html, /plan-design/, 'plan-design meta tag must be absent');
    assert.doesNotMatch(html, /design-link/, 'design-link anchor must be absent');
  });

  ok('adding a design key changes only the tag and the anchor', () => {
    const { html: without } = renderViaCli(dir, 'plainplan', spec());
    const { html: with_ } = renderViaCli(dir, 'canvasplan', spec(`design: ${CANVAS}\n`));

    // Strip the two additions; what remains must be byte-identical, so the key
    // cannot perturb CSS, script bytes, or any other plan's rendering.
    const stripped = with_
      .replace(`<meta name="plan-design" content="${CANVAS}">\n`, '')
      .replace(/\n\s*<a class="design-link"[\s\S]{0,240}?<\/a>/, '');
    const normalize = (s) => s.replace(/canvasplan/g, 'PLAN').replace(/plainplan/g, 'PLAN');
    assert.equal(
      normalize(stripped),
      normalize(without),
      'the design key must add exactly the meta tag and the anchor, nothing else',
    );
  });

  ok('a design URL containing HTML-special characters is escaped', () => {
    const nasty = 'https://claude.ai/a?x=1&y="2"><script>';
    const out = shell.header({
      title: 'T',
      status: 'todo',
      effortLabel: 'Low effort',
      created: '2026-08-17',
      repo: 'r',
      type: 'feature',
      prototypeHref: '',
      issueHref: '',
      issueLabel: '',
      designHref: nasty.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'),
    });
    assert.doesNotMatch(out, /<script>/, 'an escaped design href must not reintroduce a tag');
    assert.match(out, /design-link/, 'the anchor should still render for a valid-scheme URL');
  });

  // ── Unit: the key survives the frontmatter parser untouched ─────────────
  ok('parseSpecMarkdown passes design through as metadata', () => {
    const { metadata } = parseSpecMarkdown(spec(`design: ${CANVAS}\n`));
    assert.equal(metadata.design, CANVAS, 'design must round-trip through the generic frontmatter parser');
  });

  // ── Integration: renderPlanHtml as a library, not just the CLI ──────────
  ok('renderPlanHtml emits the tag and anchor when given a design key', () => {
    const parsed = parseSpecMarkdown(spec(`design: ${CANVAS}\n`));
    const html = renderPlanHtml({
      ...parsed,
      md: parsed.metadata,
      path: 'docs/plans/x.html',
      mdPath: 'docs/plans/x.md',
    });
    assert.match(html, /plan-design/, 'library render must emit the meta tag');
    assert.match(html, /design-link/, 'library render must emit the anchor');
  });

  // ── Renderer parity ─────────────────────────────────────────────────────
  // The three renderer files exist twice with no sync script. A one-sided edit
  // ships a plugin whose renderer lacks the feature while these tests, which
  // import the root copy, still pass. Name the copy that drifted.
  ok('the renderer files are byte-identical between scripts/ and the plugin copy', () => {
    const drifted = [];
    for (const rel of MIRRORED) {
      const a = join(ROOT, 'scripts', rel);
      const b = join(ROOT, 'kit', 'plugins', 'plan-agent', 'scripts', rel);
      const ha = createHash('sha256').update(readFileSync(a)).digest('hex');
      const hb = createHash('sha256').update(readFileSync(b)).digest('hex');
      if (ha !== hb) drifted.push(`${rel}  scripts/=${ha.slice(0, 12)}  plugin=${hb.slice(0, 12)}`);
    }
    assert.equal(
      drifted.length,
      0,
      `renderer copies drifted — copy one over the other so both stay byte-identical:\n  ${drifted.join('\n  ')}`,
    );
  });
} finally {
  rmSync(dir, { recursive: true, force: true });
}

console.log(failures === 0 ? '\nAll design-canvas-link tests passed.' : `\n${failures} test(s) failed.`);
process.exit(failures === 0 ? 0 : 1);
