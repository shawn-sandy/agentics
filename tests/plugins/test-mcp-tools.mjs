// mcp-tools: the plugin is wired into the marketplace and the skill keeps its
// activation contract. Run: node tests/plugins/test-mcp-tools.mjs
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const PLUGIN = join(ROOT, 'kit/plugins/mcp-tools');
const SKILL = join(PLUGIN, 'skills/fix-playwright-mcp/SKILL.md');

test('marketplace registers the plugin at an X.Y.Z version with a real source path', () => {
  const m = JSON.parse(readFileSync(join(ROOT, '.claude-plugin/marketplace.json'), 'utf8'));
  const entry = m.plugins.find((p) => p.name === 'mcp-tools');
  assert.ok(entry, 'mcp-tools is not in marketplace.json');
  assert.match(entry.version, /^\d+\.\d+\.\d+$/);
  assert.equal(join(ROOT, entry.source.path), PLUGIN);
  assert.ok(existsSync(SKILL), 'skills/fix-playwright-mcp/SKILL.md is missing');
});

test('plugin.json carries no version, so the marketplace value is not overridden', () => {
  const manifest = JSON.parse(readFileSync(join(PLUGIN, '.claude-plugin/plugin.json'), 'utf8'));
  assert.equal(manifest.name, 'mcp-tools');
  assert.equal('version' in manifest, false);
});

test('the skill is command-only and carries the plan-mode guard verbatim', () => {
  const text = readFileSync(SKILL, 'utf8');
  assert.match(text, /^disable-model-invocation: true$/m, 'skill must stay command-only');
  const guard = '**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.';
  assert.ok(text.split('\n').includes(guard), 'plan-mode guard is missing or reworded');
});

test('the fix resolves the pin at run time and never edits the plugin cache', () => {
  const text = readFileSync(SKILL, 'utf8');
  assert.match(text, /npm view @playwright\/mcp version/, 'version must be resolved at run time');
  assert.match(text, /@playwright\/mcp@<resolved>/, 'the add command must take the resolved version');
  assert.match(text, /Never edit the plugin's cached `\.mcp\.json`/, 'the cache warning is load-bearing');
});
