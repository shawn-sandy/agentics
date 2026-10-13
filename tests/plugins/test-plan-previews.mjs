#!/usr/bin/env node
/**
 * Tests for the plan spec's `## Previews` section: live, sandboxed UI
 * previews rendered inside the plan page.
 *
 * Objective (smoke): a spec with a Previews item renders a figure.plan-preview
 * holding an iframe whose opaque-origin `data:` URL decodes to the authored
 * html byte for byte, previews survive every path a spec takes
 * (render → extract → digest → parse, re-render, backfill, extract CLI), and
 * a preview-less spec renders byte-identical to the golden captured before
 * previews existed (tests/fixtures/plan-previews/no-previews.html).
 *
 * The renderer and spec modules are imported as namespaces so a missing
 * export fails an assertion instead of the import.
 *
 * Run: node tests/plugins/test-plan-previews.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import vm from 'node:vm';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import * as spec from '../../scripts/lib/plan-spec.mjs';
import * as render from '../../scripts/build-plan-html.mjs';
import * as extractCli from '../../scripts/extract-plan-spec.mjs';
import * as backfill from '../../scripts/backfill-plan-digests.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const RENDERER = join(ROOT, 'scripts', 'build-plan-html.mjs');
const RERENDER = join(ROOT, 'scripts', 'rerender-plans.mjs');
const FIXTURES = join(ROOT, 'tests', 'fixtures', 'plan-previews');
const TMP = mkdtempSync(join(tmpdir(), 'plan-previews-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

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

// Carries the three sequences the escaping has to survive: an entity the
// author wrote (`&amp;`), a double quote, and the guarded closing tag an
// author must write inside a script string (`<\/script>`) — next to a REAL
// closing tag, which is what makes a non-injective guard visible.
const SAVE_HTML = [
  '<!doctype html>',
  '<html lang="en">',
  '<head><style>:root { --ink:#14141c; } :root[data-theme="dark"] { --ink:#ecebf2; }</style></head>',
  '<body>',
  '<p class="note">Fish &amp; chips — "quoted"</p>',
  '<button id="save" type="button">Save</button>',
  '<script>',
  "  document.getElementById('save').onclick = function () { document.body.insertAdjacentHTML('beforeend', '<script>void 0<\\/script>'); };",
  '</script>',
  '</body>',
  '</html>',
].join('\n');

const FORM_HTML = '<html><body><form><label>Name <input name="n"></label></form></body></html>';
const EMPTY_HTML = '<html><body><p>Nothing saved yet</p></body></html>';

const indent = (s) => s.split('\n').map((l) => (l ? `  ${l}` : '')).join('\n');

const specWith = (previews) => `---
status: todo
type: feature
created: 2026-10-13
repo: fixture
---

# Plan: Preview fixture

## Objective

Render a live preview inside the plan.

## Steps

1. Build the settings form. Why: users need somewhere to type. Verify: the form renders.
2. Style the save button. Why: every state must read. Verify: hover and disabled differ.
3. Wire the save action. Why: input must persist. Verify: a reload keeps the value.

## Tests

Tier 1 — This plan changes application code
- Objective: the preview renders. File: tests/x.mjs; Run: node tests/x.mjs

## Acceptance Criteria

- [ ] The preview renders

## Verification

Open the page and click the preview.
${previews}
## Next Steps

- A follow-up that must still parse
  \`\`\`text
  Do the follow-up.
  \`\`\`
`;

const PREVIEWS_MD = `
## Previews

- Save button (step 2)
  Tokens from the fixture stylesheet.
  Second description line with \`--ink\`.
  \`\`\`html
${indent(SAVE_HTML)}
  \`\`\`
- Settings form (steps 1, 3)
  \`\`\`html
  ${FORM_HTML}
  \`\`\`
- Untagged empty state
  \`\`\`html
  ${EMPTY_HTML}
  \`\`\`
`;

const EXPECTED_ITEMS = [
  { label: 'Save button', steps: [2], desc: 'Tokens from the fixture stylesheet.\nSecond description line with `--ink`.', html: SAVE_HTML },
  { label: 'Settings form', steps: [1, 3], desc: '', html: FORM_HTML },
  { label: 'Untagged empty state', steps: [], desc: '', html: EMPTY_HTML },
];

const OPTS = { fileName: 'preview-fixture.html', planPath: 'docs/plans/preview-fixture.html', repo: 'fixture' };

const parsePreviewSpec = () => spec.parseSpecMarkdown(specWith(PREVIEWS_MD));
const renderPreviewSpec = () => render.renderPlanHtml(parsePreviewSpec(), OPTS);

const DATA_URL = 'data:text/html;charset=utf-8,';

/** Each preview `<iframe … src="data:…">` with the attributes on either side of src. */
const iframes = (html) =>
  [...html.matchAll(/<iframe\b([^>]*?)\ssrc="(data:[^"]*)"([^>]*)>/g)].map((m) => ({ before: m[1], src: m[2], after: m[3] }));

/** The markup of step card N, up to the next card or the end of the list. */
const stepCardOf = (html, n) => {
  const at = html.indexOf(`id="step-${n}"`);
  const next = html.indexOf('id="step-', at + 1);
  return html.slice(at, next === -1 ? html.indexOf('</section>', at) : next);
};

/** Assert parsing `md` throws a ParseError whose message matches every pattern. */
const rejects = (md, ...patterns) =>
  assert.throws(
    () => spec.parseSpecMarkdown(md),
    (err) => {
      assert.ok(err instanceof spec.ParseError, `expected a ParseError, got ${err && err.constructor && err.constructor.name}: ${err && err.message}`);
      for (const p of patterns) assert.match(err.message, p);
      return true;
    },
  );

/* ── Parse ────────────────────────────────────────────────────────── */

console.log('-- parse --');

ok('a Previews item parses into label, step tags, description, and verbatim html', () => {
  const parsed = parsePreviewSpec();
  assert.ok(parsed.previews, 'parse result must carry previews');
  assert.deepEqual(parsed.previews, { items: EXPECTED_ITEMS });
});

ok('previews ride beside sections, and Next Steps still parses', () => {
  const parsed = parsePreviewSpec();
  assert.ok(!('previews' in parsed.sections), 'previews must not leak into sections');
  assert.equal(parsed.nextSteps.items.length, 1);
  assert.equal(parsed.nextSteps.items[0].prompt, 'Do the follow-up.');
});

ok('a spec with no Previews section parses previews as null', () => {
  assert.equal(spec.parseSpecMarkdown(specWith('')).previews, null);
});

ok('a longer outer fence keeps an inner three-backtick block inside the html', () => {
  const html = '<html><body><pre>\n```js\nconst x = 1;\n```\n</pre></body></html>';
  const md = specWith(`
## Previews

- Code sample (step 1)
  \`\`\`\`html
${indent(html)}
  \`\`\`\`
`);
  const item = spec.parseSpecMarkdown(md).previews.items[0];
  assert.equal(item.html, html);
  assert.equal(item.desc, '');
});

/* ── Errors ───────────────────────────────────────────────────────── */

console.log('-- errors --');

ok('an item with no html block fails naming the item', () => {
  rejects(specWith('\n## Previews\n\n- Lonely label (step 1)\n  Only a description.\n'), /Previews item 1/, /Lonely label/, /html block/);
});

ok('a block with no <html tag fails naming the item', () => {
  rejects(specWith('\n## Previews\n\n- Fragment (step 1)\n  ```html\n  <div>just a fragment</div>\n  ```\n'), /Previews item 1/, /Fragment/, /<html/);
});

ok('an empty label fails naming the item', () => {
  rejects(specWith(`\n## Previews\n\n- ${EXPECTED_ITEMS[2].label}\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n- (step 1)\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n`), /Previews item 2/, /label/);
});

ok('a tagged step beyond the step count fails naming the item', () => {
  rejects(specWith(`\n## Previews\n\n- Ghost (step 9)\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n`), /Previews item 1/, /Ghost/, /step 9/);
});

ok('a step tag the parser cannot read fails instead of joining the label', () => {
  for (const tag of ['(steps 1-2)', '(step 1 and 2)', '(step: 1)', '(Steps one)']) {
    rejects(specWith(`\n## Previews\n\n- Card ${tag}\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n`), /Previews item 1/, /Card/, /step tag/);
  }
});

ok('an <html in a comment does not count as the document tag', () => {
  rejects(specWith('\n## Previews\n\n- Commented (step 1)\n  ```html\n  <!-- the <html> tag goes here -->\n  <div>fragment</div>\n  ```\n'), /Previews item 1/, /Commented/, /<html/);
  const html = '<!doctype html>\n<!-- the <html> element is below -->\n<html lang="en"><body>ok</body></html>';
  const md = specWith(`\n## Previews\n\n- Commented (step 1)\n  \`\`\`html\n${indent(html)}\n  \`\`\`\n`);
  assert.equal(spec.parseSpecMarkdown(md).previews.items[0].html, html);
});

ok('the <html> tag check stays linear on a run of comments with no <html> after it', () => {
  // A comment body that can stretch over the next `-->` makes this
  // exponential: 26 comments took about 3s, 40 never finishes. The vm
  // timeout turns a hang into a failure.
  const block = `${Array.from({ length: 40 }, (_, i) => `<!-- c${i} -->`).join('\n')}\n<div>fragment</div>`;
  const matched = vm.runInNewContext('re.test(s)', { re: spec.PREVIEW_HTML_TAG, s: block }, { timeout: 1000 });
  assert.equal(matched, false);
});

ok('a second fenced block under one item fails instead of becoming description text', () => {
  rejects(specWith(`\n## Previews\n\n- Two blocks (step 1)\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n  \`\`\`html\n  ${FORM_HTML}\n  \`\`\`\n`), /Previews item 1/, /Two blocks/, /one html block/);
});

ok('a step tag followed by more text fails instead of joining the label', () => {
  rejects(specWith(`\n## Previews\n\n- Card (step 1) extra words\n  \`\`\`html\n  ${EMPTY_HTML}\n  \`\`\`\n`), /Previews item 1/, /Card/, /step tag/);
});

/* ── Render ───────────────────────────────────────────────────────── */

console.log('-- render --');

ok('one figure.plan-preview per item, in a Previews section after Steps', () => {
  const html = renderPreviewSpec();
  assert.equal((html.match(/<figure class="plan-preview"/g) || []).length, 3);
  const at = html.indexOf('id="previews"');
  assert.ok(at > html.indexOf('id="steps"') && at < html.indexOf('id="tests"'), 'Previews section must sit between Steps and Tests');
});

ok('each iframe loads its html from an opaque-origin data: URL, eager and titled', () => {
  const html = renderPreviewSpec();
  const frames = iframes(html);
  assert.equal(frames.length, 3);
  frames.forEach((f, i) => {
    const attrs = `${f.before} ${f.after}`;
    // A data: URL frame gets an opaque origin, so it cannot reach the plan
    // page. No sandbox attribute: any sandboxed frame runs out of process and
    // never paints inside the claude.ai artifact viewer in the desktop app.
    assert.doesNotMatch(attrs, /\bsandbox=/, `frame ${i + 1} must not be sandboxed`);
    assert.doesNotMatch(attrs, /\bsrcdoc=/, `frame ${i + 1} must not use srcdoc`);
    assert.doesNotMatch(attrs, /loading="lazy"/, `frame ${i + 1} must load eagerly`);
    assert.match(attrs, new RegExp(`title="Preview: ${EXPECTED_ITEMS[i].label}"`), `frame ${i + 1} title`);
    assert.equal(f.src, DATA_URL + encodeURIComponent(EXPECTED_ITEMS[i].html), `frame ${i + 1} src`);
  });
});

ok('every tagged step shows a preview chip linking to its figure, with a 24×24px target', () => {
  const html = renderPreviewSpec();
  const chips = (n) => [...stepCardOf(html, n).matchAll(/<a class="step-chip preview-chip" href="#(preview-\d+)"[^>]*\bstyle="([^"]*)"[^>]*>preview<\/a>/g)];
  assert.deepEqual(chips(1).map((m) => m[1]), ['preview-2']);
  assert.deepEqual(chips(2).map((m) => m[1]), ['preview-1']);
  assert.deepEqual(chips(3).map((m) => m[1]), ['preview-2']);
  for (const n of [1, 2, 3]) {
    const style = chips(n)[0][2];
    const px = (prop) => Number((style.match(new RegExp(`${prop}:\\s*(\\d+)px`)) || [])[1]);
    assert.ok(px('min-height') >= 24 && px('min-width') >= 24, `step ${n} chip target: ${style}`);
  }
  for (const id of ['preview-1', 'preview-2', 'preview-3']) assert.ok(html.includes(`<figure class="plan-preview" id="${id}"`), `figure ${id}`);
});

ok('the Previews nav entry follows Steps, and the theme script is present', () => {
  const html = renderPreviewSpec();
  const nav = [...html.matchAll(/<a href="#([a-z-]+)">/g)].map((m) => m[1]);
  assert.equal(nav[nav.indexOf('steps') + 1], 'previews');
  const script = html.match(/<script id="plan-preview-theme">([\s\S]*?)<\/script>/);
  assert.ok(script, 'theme-sync script missing');
  assert.match(script[1], /MutationObserver/);
  assert.match(script[1], /data-theme/);
  assert.match(script[1], /data:text\/html/);
});

ok('the theme script rewrites the real <html> tag, not one in a comment', () => {
  const html = renderPreviewSpec().replace(encodeURIComponent(EMPTY_HTML), encodeURIComponent('<!doctype html>\n<!-- the &lt;html&gt; tag --><!-- <html> -->\n<html lang="en"><body>x</body></html>'));
  const script = html.match(/<script id="plan-preview-theme">([\s\S]*?)<\/script>/)[1];
  const frames = iframes(html).map((f) => {
    const attrs = { src: f.src };
    return { getAttribute: (k) => attrs[k], setAttribute: (k, v) => { attrs[k] = v; }, attrs, doc: () => decodeURIComponent(attrs.src.slice(DATA_URL.length)) };
  });
  const initial = frames.map((f) => f.attrs.src);
  const root = { attrs: { 'data-theme': 'dark' }, getAttribute(k) { return this.attrs[k] === undefined ? null : this.attrs[k]; } };
  let observer = null;
  vm.runInNewContext(script, {
    document: { documentElement: root, querySelectorAll: () => frames },
    window: { MutationObserver: true },
    MutationObserver: function (cb) { this.observe = () => { observer = cb; }; },
  });
  assert.ok(frames[2].doc().includes('<!-- <html> -->\n<html data-theme="dark" lang="en">'), frames[2].doc());
  assert.ok(frames[0].doc().includes('<html data-theme="dark" lang="en">'));
  // A <base> would break fragment links: in a data: document `#x` already
  // resolves against the document itself.
  assert.ok(!frames[0].doc().includes('<base'), 'no base injected');
  root.attrs['data-theme'] = 'light';
  observer();
  assert.ok(frames[0].doc().includes('<html data-theme="light" lang="en">'));
  delete root.attrs['data-theme'];
  observer();
  assert.deepEqual(frames.map((f) => f.attrs.src), initial, 'following the OS restores the markup URL, so the frame loads once');
});

/* ── Round trip ───────────────────────────────────────────────────── */

console.log('-- round trip --');

ok('extractPreviews(render(spec)) returns the parsed previews', () => {
  assert.deepEqual(spec.extractPreviews(renderPreviewSpec()), { items: EXPECTED_ITEMS });
});

ok('a preview figure extractPreviews cannot read fails instead of vanishing', () => {
  // A re-render from the DOM rebuilds the page from what this returns, so a
  // silently skipped figure would be deleted from the plan.
  const html = renderPreviewSpec().replace('<figure class="plan-preview" id="preview-2"', '<figure data-x="1" class="plan-preview" id="preview-2"');
  assert.throws(() => spec.extractPreviews(html), (err) => err instanceof spec.ParseError && /preview/i.test(err.message));
});

ok('the spec markdown re-parses to the same previews, html included', () => {
  const parsed = parsePreviewSpec();
  const md = spec.specMarkdown(parsed.sections, parsed.nextSteps, parsed.previews);
  assert.deepEqual(spec.parseSpecMarkdown(md).previews, { items: EXPECTED_ITEMS });
});

ok('the DOM-derived spec (extract CLI path) keeps previews and the guarded <\\/script>', () => {
  const out = extractCli.resolveSpec(renderPreviewSpec());
  assert.deepEqual(spec.parseSpecMarkdown(out).previews, { items: EXPECTED_ITEMS });
});

ok('buildDigest takes previews third and still guards every real closing tag', () => {
  const parsed = parsePreviewSpec();
  const digest = spec.buildDigest(parsed.sections, parsed.nextSteps, parsed.previews);
  assert.match(digest, /^## Previews$/m);
  assert.match(digest, /^- Settings form \(steps 1, 3\)$/m);
  assert.doesNotMatch(digest, /<\/script/i, 'an embedded digest must not end its own script block');
});

ok('a re-render from the DOM (no .md beside the plan) keeps the previews', () => {
  const dir = mkdtempSync(join(TMP, 'rerender-'));
  const file = join(dir, 'preview-fixture.html');
  writeFileSync(file, renderPreviewSpec());
  const run = spawnSync('node', [RERENDER, '--dir', dir], { encoding: 'utf8', cwd: ROOT });
  assert.equal(run.status, 0, run.stderr);
  assert.match(run.stdout, /re-rendered 1 of 1 plans/, 'the page must actually be re-rendered, not skipped');
  assert.deepEqual(spec.extractPreviews(readFileSync(file, 'utf8')), { items: EXPECTED_ITEMS });
});

ok('a backfilled digest carries the previews', () => {
  const dir = mkdtempSync(join(TMP, 'backfill-'));
  const file = join(dir, 'preview-fixture.html');
  writeFileSync(file, renderPreviewSpec());
  const result = backfill.runBackfill(dir);
  assert.deepEqual(result.injected, ['preview-fixture.html']);
  const page = readFileSync(file, 'utf8');
  assert.match(spec.readEmbeddedDigest(page), /^## Previews$/m, 'the digest must carry the section');
  // The guard is non-injective, so the extract CLI must not trust an embedded
  // digest for a page with previews: SAVE_HTML holds a literal <\/script>.
  assert.deepEqual(spec.parseSpecMarkdown(extractCli.resolveSpec(page)).previews, { items: EXPECTED_ITEMS });
});

/* ── Golden ───────────────────────────────────────────────────────── */

console.log('-- golden --');

ok('a preview-less spec renders byte-identical to the golden captured before previews', () => {
  const out = join(TMP, 'no-previews.html');
  const run = spawnSync('node', [RENDERER, 'tests/fixtures/plan-previews/no-previews.md', '-o', out], { encoding: 'utf8', cwd: ROOT });
  assert.equal(run.status, 0, run.stderr);
  const rendered = readFileSync(out, 'utf8');
  const golden = readFileSync(join(FIXTURES, 'no-previews.html'), 'utf8');
  assert.ok(rendered === golden, `render differs from the golden: ${JSON.stringify(render.firstDiff(golden, rendered))}`);
  for (const marker of ['class="plan-preview"', 'preview-chip', 'id="previews"', 'plan-preview-theme', 'data:text/html']) {
    assert.ok(!rendered.includes(marker), `preview-less plan carries preview bytes: ${marker}`);
  }
});

console.log(`\n${passed} checks passed${process.exitCode ? ' (with failures)' : ''}`);
