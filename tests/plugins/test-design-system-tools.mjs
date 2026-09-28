// design-system-tools: the plugin is wired into the marketplace, and the
// contrast script's maths holds. Run: node tests/plugins/test-design-system-tools.mjs
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const PLUGIN = join(ROOT, 'kit/plugins/design-system-tools');
const SKILL = join(PLUGIN, 'skills/from-design-md/SKILL.md');
const { ratio, resolve } = await import(join(PLUGIN, 'skills/from-design-md/scripts/contrast.mjs'));

test('marketplace registers the plugin at an X.Y.Z version with a real source path', () => {
  const m = JSON.parse(readFileSync(join(ROOT, '.claude-plugin/marketplace.json'), 'utf8'));
  const entry = m.plugins.find((p) => p.name === 'design-system-tools');
  assert.ok(entry, 'design-system-tools is not in marketplace.json');
  assert.match(entry.version, /^\d+\.\d+\.\d+$/);
  assert.equal(join(ROOT, entry.source.path), PLUGIN);
  assert.ok(existsSync(SKILL), 'skills/from-design-md/SKILL.md is missing');
});

test('plugin.json carries no version, so the marketplace value is not overridden', () => {
  const manifest = JSON.parse(readFileSync(join(PLUGIN, '.claude-plugin/plugin.json'), 'utf8'));
  assert.equal(manifest.name, 'design-system-tools');
  assert.equal('version' in manifest, false);
});

test('the skill carries the plan-mode guard verbatim', () => {
  const guard = '**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.';
  assert.ok(readFileSync(SKILL, 'utf8').split('\n').includes(guard));
});

// The Bash tool refuses `$VAR` in a command, so the skill must reach the
// script through the plugin's bin/, which Claude Code puts on PATH.
test('the documented bare command runs from bin/ on PATH', (t) => {
  assert.match(readFileSync(SKILL, 'utf8'), /^design-system-contrast /m);
  const dir = mkdtempSync(join(tmpdir(), 'ds-contrast-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const tokens = join(dir, 'tokens.json');
  writeFileSync(tokens, JSON.stringify({
    color: { themes: [{ id: 'light' }], tokens: [{ name: 'ink', value: '#000' }, { name: 'paper', value: '#fff' }] },
  }));
  const out = execFileSync('design-system-contrast', [tokens, 'ink:paper'], {
    encoding: 'utf8',
    env: { ...process.env, PATH: `${join(PLUGIN, 'bin')}${delimiter}${process.env.PATH}` },
  });
  assert.match(out, /ink on paper {2}light 21\.00:1/);
});

const color = {
  themes: [{ id: 'light' }, { id: 'dark' }],
  tokens: [
    { name: 'ink', value: { light: '#000', dark: '#ffffff' } },
    { name: 'paper', value: { light: '#fff', dark: 'rgb(0, 0, 0)' } },
    { name: 'status', value: '#777777' },
    { name: 'text', value: { light: '{ink}' } },
    { name: 'loop', value: '{loop}' },
    { name: 'darkonly', value: { dark: '#000' } },
  ],
};

test('black on white is 21:1 in both themes, in hex and rgb()', () => {
  for (const t of ['light', 'dark']) {
    assert.equal(ratio(resolve(color, 'ink', t), resolve(color, 'paper', t)), 21);
  }
});

test('aliases resolve per theme and a missing theme falls back to the first', () => {
  assert.equal(resolve(color, 'text', 'dark'), '#ffffff');
  assert.equal(resolve(color, 'status', 'dark'), '#777777');
});

test('a near-miss is floored, never rounded up to 4.5', () => {
  // #777777 on white is 4.478…:1
  assert.equal(ratio('#777777', '#ffffff'), 4.47);
});

test('circular aliases, unknown tokens and translucent colours throw', () => {
  assert.throws(() => resolve(color, 'loop', 'light'), /circular/);
  assert.throws(() => resolve(color, 'nope', 'light'), /unknown/);
  assert.throws(() => ratio('#0008', '#fff'), /cannot measure/);
});

test('an out-of-range rgb() channel throws instead of printing a plausible ratio', () => {
  assert.throws(() => ratio('rgb(300, 0, 0)', '#000'));
});

test('a token with no value for the theme or the first theme names itself in the error', () => {
  assert.throws(() => resolve(color, 'darkonly', 'light'), /darkonly/);
});
