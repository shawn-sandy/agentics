#!/usr/bin/env node
// Regenerates the "## Plugin Reference Table" block in README.md from
// .claude-plugin/marketplace.json (name/version/category) plus a component
// count derived from each plugin's directory under kit/plugins/.
//
// Usage:
//   node scripts/build-readme-table.mjs           # rewrite the table in README.md
//   node scripts/build-readme-table.mjs --check   # exit 1 if README is out of date

import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
const README = join(ROOT, 'README.md');
const HEADING = '## Plugin Reference Table';

// Count rules mirror how the table has always been hand-maintained:
// commands/agents = .md files in that directory; skills = subdirectories
// holding a SKILL.md; hooks = wired command entries in hooks.json (NOT files
// in hooks/, which may include helper scripts a hook never invokes).
function countComponents(dir) {
  const mdFiles = (sub) => {
    const p = join(dir, sub);
    return existsSync(p) ? readdirSync(p).filter((f) => f.endsWith('.md')).length : 0;
  };

  const skillsDir = join(dir, 'skills');
  const skills = existsSync(skillsDir)
    ? readdirSync(skillsDir).filter((f) => existsSync(join(skillsDir, f, 'SKILL.md'))).length
    : 0;

  let hooks = 0;
  const hooksJson = join(dir, 'hooks.json');
  if (existsSync(hooksJson)) {
    const parsed = JSON.parse(readFileSync(hooksJson, 'utf8'));
    for (const matchers of Object.values(parsed.hooks ?? {})) {
      for (const matcher of matchers) hooks += (matcher.hooks ?? []).length;
    }
  }

  return { command: mdFiles('commands'), skill: skills, agent: mdFiles('agents'), hook: hooks };
}

function formatComponents(counts) {
  const parts = Object.entries(counts)
    .filter(([, n]) => n > 0)
    .map(([label, n]) => `${n} ${label}${n === 1 ? '' : 's'}`);
  return parts.length ? parts.join(', ') : 'none';
}

function renderTable() {
  const marketplace = JSON.parse(readFileSync(join(ROOT, '.claude-plugin', 'marketplace.json'), 'utf8'));
  const rows = marketplace.plugins.map((p) => {
    const counts = countComponents(join(ROOT, 'kit', 'plugins', p.name));
    const link = `[${p.name}](./kit/plugins/${p.name}/README.md)`;
    return `| ${link} | ${p.version} | ${p.category} | ${formatComponents(counts)} |`;
  });

  return [
    '| Plugin | Version | Category | Components |',
    '|--------|---------|----------|------------|',
    ...rows,
  ].join('\n');
}

// Replace everything between the heading and the next horizontal rule.
function rewrite(readme, table) {
  const start = readme.indexOf(HEADING);
  if (start === -1) throw new Error(`"${HEADING}" heading not found in README.md`);

  const bodyStart = start + HEADING.length;
  const end = readme.indexOf('\n---', bodyStart);
  if (end === -1) throw new Error('No closing "---" found after the Plugin Reference Table heading');

  return `${readme.slice(0, bodyStart)}\n\n${table}\n${readme.slice(end)}`;
}

const current = readFileSync(README, 'utf8');
const updated = rewrite(current, renderTable());

if (process.argv.includes('--check')) {
  if (current !== updated) {
    console.error('README.md Plugin Reference Table is out of date.');
    console.error('Run: node scripts/build-readme-table.mjs');
    process.exit(1);
  }
  console.log('README.md Plugin Reference Table is up to date.');
} else {
  writeFileSync(README, updated);
  console.log(current === updated ? 'README.md already up to date.' : 'README.md Plugin Reference Table updated.');
}
