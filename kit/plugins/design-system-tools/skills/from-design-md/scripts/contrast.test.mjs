// Ported from ~/.claude/skills/design-system-from-design-md/scripts/contrast.test.mjs.
// Run: node --test "kit/plugins/design-system-tools/skills/from-design-md/scripts/*.test.mjs"
import assert from 'node:assert/strict';
import test from 'node:test';
import { ratio, resolve } from './contrast.mjs';

const color = {
  themes: [{ id: 'light' }, { id: 'dark' }],
  tokens: [
    { name: 'ink', value: { light: '#000', dark: '#ffffff' } },
    { name: 'paper', value: { light: '#fff', dark: 'rgb(0, 0, 0)' } },
    { name: 'status', value: '#777777' },
    { name: 'text', value: { light: '{ink}' } },
    { name: 'loop', value: '{loop}' },
  ],
};

test('black on white is 21:1 in both themes, hex and rgb()', () => {
  for (const t of ['light', 'dark']) assert.equal(ratio(resolve(color, 'ink', t), resolve(color, 'paper', t)), 21);
});

test('aliases resolve per theme and a missing theme falls back to the first', () => {
  assert.equal(resolve(color, 'text', 'dark'), '#ffffff');
  assert.equal(resolve(color, 'status', 'dark'), '#777777');
});

test('ratio is floored, so a near-miss never rounds up to 4.5', () => {
  // #777777 on white is 4.478…:1
  assert.equal(ratio('#777777', '#ffffff'), 4.47);
});

test('circular aliases, unknown tokens and translucent colours throw', () => {
  assert.throws(() => resolve(color, 'loop', 'light'));
  assert.throws(() => resolve(color, 'nope', 'light'));
  assert.throws(() => ratio('#0008', '#fff'));
});
