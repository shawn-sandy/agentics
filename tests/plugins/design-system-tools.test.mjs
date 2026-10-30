// design-system-tools: the three skills are wired, every script a SKILL.md names ships, and
// the version is one number everywhere. Run: node --test tests/plugins/design-system-tools.test.mjs
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const PLUGIN = join(ROOT, 'kit/plugins/design-system-tools');
const SKILLS = join(PLUGIN, 'skills');
const EXPECTED = ['align-design-md', 'customize-design', 'from-design-md'];
const GUARD = '**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.';

const read = (...p) => readFileSync(join(...p), 'utf8');
const frontmatter = (md) => {
  const block = /^---\n([\s\S]*?)\n---/.exec(md)?.[1] ?? '';
  return Object.fromEntries([...block.matchAll(/^([\w-]+):\s*"?(.*?)"?\s*$/gm)].map((m) => [m[1], m[2]]));
};

test('the three skill folders each carry a SKILL.md with name, description and the plan-mode guard', () => {
  assert.deepEqual(readdirSync(SKILLS).filter((d) => !d.startsWith('.')).sort(), EXPECTED);
  for (const skill of EXPECTED) {
    const md = read(SKILLS, skill, 'SKILL.md');
    const fm = frontmatter(md);
    assert.equal(fm.name, skill, `${skill}: frontmatter name`);
    assert.ok(fm.description && fm.description.length <= 200, `${skill}: description missing or over 200 chars`);
    assert.ok(md.split('\n').includes(GUARD), `${skill}: plan-mode guard missing or reworded`);
  }
});

test('every scripts/ path a SKILL.md names through ${CLAUDE_SKILL_DIR} exists', () => {
  const named = {};
  for (const skill of EXPECTED) {
    const md = read(SKILLS, skill, 'SKILL.md');
    named[skill] = [...new Set([...md.matchAll(/\$\{CLAUDE_SKILL_DIR\}\/((?:scripts|references)\/[\w./-]+)/g)].map((m) => m[1]))];
    for (const p of named[skill]) assert.ok(existsSync(join(SKILLS, skill, p)), `${skill} names ${p}, which does not exist`);
  }
  // The two skills with scripts must name them, or a renamed script would pass unnoticed.
  assert.deepEqual(named['customize-design'].sort(), ['scripts/contrast.mjs', 'scripts/scaffold.mjs']);
  assert.deepEqual(named['from-design-md'], ['scripts/contrast.mjs']);
  assert.ok(existsSync(join(SKILLS, 'align-design-md/references/drift-checklist.md')));
  assert.match(read(SKILLS, 'align-design-md/SKILL.md'), /references\/drift-checklist\.md/);
});

test('the marketplace version equals the newest CHANGELOG heading and plugin.json carries none', () => {
  const entry = JSON.parse(read(ROOT, '.claude-plugin/marketplace.json')).plugins.find((p) => p.name === 'design-system-tools');
  const newest = /^## v?(\d+\.\d+\.\d+)/m.exec(read(PLUGIN, 'CHANGELOG.md'))?.[1];
  assert.ok(newest, 'CHANGELOG.md has no ## X.Y.Z heading');
  assert.equal(entry.version, newest);
  const manifest = JSON.parse(read(PLUGIN, '.claude-plugin/plugin.json'));
  assert.equal('version' in manifest, false, 'a version in plugin.json would override the marketplace value');
  assert.equal(entry.description, manifest.description, 'marketplace and plugin.json descriptions differ');
});

test('the Astro Kit paths appear only inside a labelled example callout', () => {
  for (const skill of EXPECTED) {
    const lines = read(SKILLS, skill, 'SKILL.md').split('\n');
    let inCallout = false;
    lines.forEach((line, i) => {
      if (/^> \*\*Astro Kit example\.\*\*/.test(line)) inCallout = true;
      else if (!line.startsWith('>')) inCallout = false;
      if (/astro-basics|_design-tokens\.scss|starlight|project-docs/.test(line)) {
        assert.ok(inCallout, `${skill}/SKILL.md:${i + 1} names an Astro Kit path outside the callout`);
      }
    });
  }
});

// The skill-level suites live beside their scripts, outside tests/, so run-all.sh and CI only
// reach them through this test. Gut either script and this fails.
test('the skill-level node:test suites pass', () => {
  for (const file of [
    'customize-design/scripts/contrast.test.mjs',
    'customize-design/scripts/scaffold.test.mjs',
    'from-design-md/scripts/contrast.test.mjs',
  ]) {
    const r = spawnSync('node', ['--test', join(SKILLS, file)], { encoding: 'utf8' });
    assert.equal(r.status, 0, `${file}:\n${r.stdout}\n${r.stderr}`);
  }
});
