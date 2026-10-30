// Run: node --test "kit/plugins/design-system-tools/skills/customize-design/scripts/*.test.mjs"
//
// The parity bar: the generalized script must print exactly what oncue-app's repo-only
// `.claude/skills/customize-design/scripts/contrast.mjs` printed on 2026-10-30, from the SCSS
// mixins it was written for AND from a plain CSS file it never saw.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const SCRIPT = join(HERE, 'contrast.mjs');
const FIXTURES = join(HERE, '..', 'fixtures');
const run = (...args) => spawnSync('node', [SCRIPT, ...args], { encoding: 'utf8' });

const PAIRS = [
  'ink on paper', 'ink-soft on paper', 'island on paper', 'ink on paper-sunk',
  'ink-soft on paper-sunk', 'island on paper-sunk', 'island on island-bg', 'ink on island-bg',
];
const LIGHT = [21.0, 6.28, 5.31, 18.42, 5.51, 4.65, 4.6, 18.19];
const DARK = [16.86, 7.48, 7.32, 15.22, 6.75, 6.61, 6.2, 14.29];

/** The printed table as `[{pair, light, dark}]`, in print order. */
function table(stdout) {
  return stdout
    .split('\n')
    .map((line) => /^(\S+ on \S+)\s+light (\d+\.\d\d)\s+dark (\d+\.\d\d)/.exec(line))
    .filter(Boolean)
    .map((m) => ({ pair: m[1], light: Number(m[2]), dark: Number(m[3]) }));
}

function tmpTokens(t, css) {
  const dir = mkdtempSync(join(tmpdir(), 'ds-contrast-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const file = join(dir, 'tokens.css');
  writeFileSync(file, css);
  return file;
}

for (const [label, file] of [
  ['SCSS mixins (oncue-app at 2f0b5d2)', 'oncue/_design-tokens.scss'],
  ['plain CSS scopes, no Sass', 'plain-css/tokens.css'],
]) {
  test(`${label}: the eight default pairs print the OnCue ratios in both themes`, () => {
    const r = run('--tokens', join(FIXTURES, file));
    assert.equal(r.status, 0, r.stderr);
    assert.equal(r.stderr, '', 'every declaration in the fixture lands in a theme');
    const rows = table(r.stdout);
    assert.deepEqual(rows.map((x) => x.pair), PAIRS);
    assert.deepEqual(rows.map((x) => x.light), LIGHT);
    assert.deepEqual(rows.map((x) => x.dark), DARK);
  });
}

test('--design-md reads the frontmatter colors map and measures the named pair', () => {
  const r = run('--design-md', join(FIXTURES, 'oncue/DESIGN.md'), '--pairs', 'island:paper,ink:paper');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^island on paper\s+light 5\.31/m);
  assert.match(r.stdout, /^ink on paper\s+light 21\.00/m);
});

test('--pairs picks the pairs on a token file too', () => {
  const r = run('--tokens', join(FIXTURES, 'plain-css/tokens.css'), '--pairs', 'rule:paper');
  // rule on paper is a hairline, not text: it prints, and the floor makes it exit 1.
  assert.equal(r.status, 1);
  assert.match(r.stdout, /^rule on paper\s+light 1\.34 FAIL\s+dark 1\.39 FAIL/m);
});

test('a bare hex pair measures without any file', () => {
  const r = run('#185c53:#fcfcfd');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^#185c53 on #fcfcfd: 7\.60$/m);
});

test('a ratio is floored, so 4.499 never prints as a passing 4.50, and the floor exits 1', () => {
  // #747871 on white is 4.49906…:1 — rounding would print a passing 4.50.
  const r = run('#747871:#ffffff');
  assert.equal(r.status, 1);
  assert.match(r.stdout, /^#747871 on #ffffff: 4\.49 FAIL$/m);
});

test('oklch(), hsl() and translucent values cannot be measured: exit 2, not a wrong number', (t) => {
  const file = tmpTokens(t, ':root { --ink: oklch(0.2 0.02 60); --paper: #fff; }\n.dark { --ink: #fff; --paper: hsl(0 0% 7%); }');
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 2);
  assert.match(r.stderr, /oklch\(0\.2 0\.02 60\)/);
  assert.equal(run('#0008:#fff').status, 2);
});

test('a token missing from a theme exits 2 and names the token and the theme', (t) => {
  const file = tmpTokens(t, ':root { --ink: #000; --paper: #fff; }\n[data-theme="dark"] { --ink: #fff; }');
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 2);
  assert.match(r.stderr, /--paper.*dark/);
});

test('--light-scope and --dark-scope override the default scope detection', (t) => {
  const file = tmpTokens(t, '.day { --ink: #000; --paper: #fff; }\n.night { --ink: #fff; --paper: #000; }');
  assert.equal(run('--tokens', file, '--pairs', 'ink:paper').status, 2, 'unknown scopes measure nothing');
  const r = run('--tokens', file, '--pairs', 'ink:paper', '--light-scope', '.day', '--dark-scope', '.night');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^ink on paper\s+light 21\.00\s+dark 21\.00/m);
});

test('a dark media block wins over the :root it wraps', (t) => {
  const file = tmpTokens(t, [
    ':root { --ink: #000; --paper: #fff; }',
    '@media (prefers-color-scheme: dark) { :root { --ink: #fff; --paper: #000; } }',
  ].join('\n'));
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^ink on paper\s+light 21\.00\s+dark 21\.00/m);
});

test('a brace inside a block or line comment never opens or closes a scope', (t) => {
  // Unstripped, the `}` and `.dark {` inside each comment would file --paper under dark.
  for (const css of [
    ':root { --ink: #000; /* } .dark { */ --paper: #fff; }',
    ':root { --ink: #000; // } .dark {\n --paper: #fff; }',
  ]) {
    const r = run('--tokens', tmpTokens(t, css), '--pairs', 'ink:paper');
    assert.equal(r.status, 0, `${css}\n${r.stderr}`);
    assert.match(r.stdout, /^ink on paper\s+light 21\.00$/m);
  }
});

test('a // inside a value is not a comment: url(//cdn), url(https://…) and a base64 data URI', (t) => {
  const file = tmpTokens(t, [
    ':root {',
    '  --logo: url(//cdn.example.test/logo.svg);',
    '  --mark: url("https://example.test/mark.svg");',
    '  --pixel: url(data:image/png;base64,iVBOR//8AAA==);',
    '  --ink: #000; // trailing comments after a ; still go',
    '  --paper: #fff;',
    '}',
  ].join('\n'));
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^ink on paper\s+light 21\.00$/m);
});

test(':not(...) never decides the theme, and class names containing dark or light do', (t) => {
  const file = tmpTokens(t, [
    ':root:not([data-theme="dark"]) { --ink: #ccc; --paper: #fff; }',
    'html:not(.dark) { --rule: #eee; }',
    '.theme-dark { --ink: #fff; --paper: #000; }',
  ].join('\n'));
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 1, r.stderr);
  assert.match(r.stdout, /^ink on paper\s+light 1\.60 FAIL\s+dark 21\.00/m);
});

test('declarations under a scope that is neither light nor dark are named on stderr, never dropped silently', (t) => {
  const file = tmpTokens(t, ':root { --ink: #000; --paper: #fff; }\n.night { --ink: #fff; --paper: #fff; }');
  const r = run('--tokens', file, '--pairs', 'ink:paper');
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stderr, /\.night/);
  assert.match(r.stderr, /--dark-scope/);
});

test('the DESIGN.md reader survives CRLF, a blank line inside the map, a trailing comment and an unquoted hex', (t) => {
  const dir = mkdtempSync(join(tmpdir(), 'ds-design-md-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const file = join(dir, 'DESIGN.md');
  writeFileSync(file, [
    '---', 'name: Acme', 'colors:', "  ink: '#000000' # the text", '', '  paper: "#ffffff"', '  rule: #dedede',
    'typography:', '  body:', '    fontSize: 1rem', '---', '', '# Design System: Acme', '',
  ].join('\r\n'));
  const r = run('--design-md', file, '--pairs', 'ink:paper,rule:paper');
  assert.equal(r.status, 1, r.stderr);
  assert.match(r.stdout, /^ink on paper\s+light 21\.00$/m);
  assert.match(r.stdout, /^rule on paper\s+light 1\.34 FAIL$/m);
});

test('the script still runs when reached through a symlinked directory', (t) => {
  const dir = mkdtempSync(join(tmpdir(), 'ds-symlink-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  symlinkSync(HERE, join(dir, 'scripts'));
  const r = spawnSync('node', [join(dir, 'scripts', 'contrast.mjs'), '#747871:#ffffff'], { encoding: 'utf8' });
  assert.equal(r.status, 1, 'the entry guard must recognise the symlinked path');
  assert.match(r.stdout, /4\.49 FAIL/);
});

test('no pairs and no default set exits 2 with the usage', (t) => {
  const file = tmpTokens(t, ':root { --brand: #333; --bg: #fff; }');
  const r = run('--tokens', file);
  assert.equal(r.status, 2);
  assert.match(r.stderr, /--pairs/);
});
