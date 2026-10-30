// Run: node --test "kit/plugins/design-system-tools/skills/customize-design/scripts/*.test.mjs"
//
// The scaffold writes the seven-token direction in three scopes plus a starter DESIGN.md,
// adjusting the brand colour until every pair measures, so customize-design always has
// something to rebrand.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const SCAFFOLD = join(HERE, 'scaffold.mjs');
const CONTRAST = join(HERE, 'contrast.mjs');
const TOKENS = ['ink', 'ink-soft', 'paper', 'paper-sunk', 'island', 'island-bg', 'rule'];
const SCOPES = [':root', '@media (prefers-color-scheme: dark)', ':root[data-theme="dark"]'];

function scaffold(t, args, { dir = mkdtempSync(join(tmpdir(), 'ds-scaffold-')) } = {}) {
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  // DESIGN.md lands in the current directory, tokens.css in --out: run from the temp dir.
  const r = spawnSync('node', [SCAFFOLD, ...args, '--out', dir], { cwd: dir, encoding: 'utf8' });
  return { dir, ...r };
}

/** `{ name: value }` declared inside the block whose header starts with `header`. */
function block(css, header) {
  const start = css.indexOf(header);
  assert.notEqual(start, -1, `no "${header}" block`);
  const open = css.indexOf('{', start);
  let depth = 1;
  let end = open + 1;
  for (; end < css.length && depth > 0; end += 1) {
    if (css[end] === '{') depth += 1;
    else if (css[end] === '}') depth -= 1;
  }
  return Object.fromEntries(
    [...css.slice(open + 1, end).matchAll(/--([\w-]+)\s*:\s*([^;]+);/g)].map((m) => [m[1], m[2].trim()]),
  );
}

const { ratio } = await import(CONTRAST).catch(() => ({ ratio: () => assert.fail('contrast.mjs is missing') }));

test('a dark brand colour is kept as the light accent and tinted until it reads on #111111', (t) => {
  const { dir, status, stderr } = scaffold(t, ['--accent', '#185c53', '--name', 'Acme']);
  assert.equal(status, 0, stderr);
  const css = readFileSync(join(dir, 'tokens.css'), 'utf8');
  for (const scope of SCOPES) {
    const decls = block(css, scope);
    for (const name of TOKENS) assert.ok(decls[name], `${scope} lacks --${name}`);
  }
  const light = block(css, ':root');
  const dark = block(css, ':root[data-theme="dark"]');
  assert.equal(light.island, '#185c53', 'a colour that already measures is not changed');
  assert.notEqual(dark.island, '#185c53');
  assert.ok(ratio(dark.island, '#111111') >= 4.5, `dark island ${dark.island} on #111111`);
  assert.deepEqual(block(css, '@media (prefers-color-scheme: dark)'), dark, 'both dark scopes agree');
  for (const role of ['display', 'sans', 'mono']) assert.ok(light[`font-family-${role}`], `--font-family-${role}`);

  const design = readFileSync(join(dir, 'DESIGN.md'), 'utf8');
  const front = design.split('\n---\n')[0];
  assert.match(front, /^name: Acme$/m);
  for (const name of TOKENS) assert.match(front, new RegExp(`^  ${name}: '#[0-9a-f]{6}'$`, 'm'));
  assert.match(front, /^  island: '#185c53'$/m);
  assert.match(design, /5\.31|7\.79/, 'the measured ratio is written into the spec');

  const check = spawnSync('node', [CONTRAST, '--tokens', join(dir, 'tokens.css')], { encoding: 'utf8' });
  assert.equal(check.status, 0, check.stdout + check.stderr);
});

test('a light brand colour is darkened step by step until it measures, and the wash keeps the original', (t) => {
  const { dir, status, stdout, stderr } = scaffold(t, ['--accent', '#f5a623']);
  assert.equal(status, 0, stderr);
  const css = readFileSync(join(dir, 'tokens.css'), 'utf8');
  const light = block(css, ':root');
  assert.notEqual(light.island, '#f5a623');
  // 20 steps of 2% toward black, and the wash is the ORIGINAL at 8% over each paper.
  assert.equal(light.island, '#936415');
  assert.equal(light['island-bg'], '#fef8ed');
  assert.equal(block(css, ':root[data-theme="dark"]')['island-bg'], '#231d12');
  assert.ok(ratio(light.island, '#ffffff') >= 4.5, `${light.island} on white`);
  assert.ok(ratio(light.island, light['paper-sunk']) >= 4.5, `${light.island} on sunk paper`);
  assert.ok(ratio(light.island, light['island-bg']) >= 4.5, `${light.island} on its wash`);
  assert.match(stdout, /darkened/i, 'the report says the colour was darkened');
  const check = spawnSync('node', [CONTRAST, '--tokens', join(dir, 'tokens.css')], { encoding: 'utf8' });
  assert.equal(check.status, 0, check.stdout + check.stderr);
  // --name defaults to the folder: the temp dir's basename.
  assert.match(readFileSync(join(dir, 'DESIGN.md'), 'utf8'), new RegExp(`^name: ${dir.split('/').pop()}$`, 'm'));
});

test('an existing tokens.css is never overwritten, and DESIGN.md is not written either', (t) => {
  const dir = mkdtempSync(join(tmpdir(), 'ds-scaffold-'));
  writeFileSync(join(dir, 'tokens.css'), '/* mine */\n');
  const r = scaffold(t, ['--accent', '#185c53'], { dir });
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /tokens\.css/);
  assert.equal(readFileSync(join(dir, 'tokens.css'), 'utf8'), '/* mine */\n');
  assert.equal(existsSync(join(dir, 'DESIGN.md')), false, 'nothing is written when any target exists');
});

test('an existing DESIGN.md is never overwritten, and tokens.css is not written either', (t) => {
  const dir = mkdtempSync(join(tmpdir(), 'ds-scaffold-'));
  writeFileSync(join(dir, 'DESIGN.md'), '# mine\n');
  const r = scaffold(t, ['--accent', '#185c53'], { dir });
  assert.notEqual(r.status, 0);
  assert.match(r.stderr, /DESIGN\.md/);
  assert.equal(readFileSync(join(dir, 'DESIGN.md'), 'utf8'), '# mine\n');
  assert.equal(existsSync(join(dir, 'tokens.css')), false);
});

test('a dangling symlink at a target path is refused too, and nothing else is written', (t) => {
  // existsSync() says false for a dangling link; an exclusive create must still refuse it.
  const dir = mkdtempSync(join(tmpdir(), 'ds-scaffold-'));
  symlinkSync(join(dir, 'nowhere'), join(dir, 'tokens.css'));
  const r = scaffold(t, ['--accent', '#185c53'], { dir });
  assert.equal(r.status, 2, r.stdout);
  assert.match(r.stderr, /tokens\.css/);
  assert.equal(existsSync(join(dir, 'nowhere')), false, 'nothing was written through the link');
  assert.equal(existsSync(join(dir, 'DESIGN.md')), false);
});

test('a --design-md path in a folder that does not exist yet is created, and both files land', (t) => {
  const { dir, status, stderr } = scaffold(t, ['--accent', '#185c53', '--design-md', 'docs/DESIGN.md']);
  assert.equal(status, 0, stderr);
  assert.ok(existsSync(join(dir, 'tokens.css')));
  assert.ok(existsSync(join(dir, 'docs', 'DESIGN.md')));
});

test('the starter DESIGN.md keeps its description past the brand hex, and a name that would break YAML or CSS is refused', (t) => {
  const { dir, status, stderr } = scaffold(t, ['--accent', '#185c53', '--name', "Acme & Co's Site"]);
  assert.equal(status, 0, stderr);
  const front = readFileSync(join(dir, 'DESIGN.md'), 'utf8').split('\n---\n')[0];
  // Unquoted, ` #185c53 …` would be a YAML comment and the description would end at "single".
  assert.match(front, /^description: "[^"]*#185c53[^"]*signal[^"]*"$/m);
  for (const bad of ['Acme: Design System', 'x */ body{display:none} /*', 'Acme # not']) {
    const r = scaffold(t, ['--accent', '#185c53', '--name', bad]);
    assert.equal(r.status, 2, `name ${JSON.stringify(bad)} must be refused`);
    assert.match(r.stderr, /--name/);
  }
});

test('the script still runs when reached through a symlinked directory', (t) => {
  const dir = mkdtempSync(join(tmpdir(), 'ds-scaffold-link-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  symlinkSync(HERE, join(dir, 'scripts'));
  const r = spawnSync('node', [join(dir, 'scripts', 'scaffold.mjs'), '--accent', '#185c53', '--out', dir], { cwd: dir, encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(existsSync(join(dir, 'tokens.css')), 'the entry guard must recognise the symlinked path');
});

test('a missing or malformed --accent exits 2 with the usage', (t) => {
  assert.equal(scaffold(t, []).status, 2);
  const r = scaffold(t, ['--accent', 'tomato']);
  assert.equal(r.status, 2);
  assert.match(r.stderr, /--accent/);
});
