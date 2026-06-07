#!/usr/bin/env node
// auto-bump-version.mjs — CI-only plugin version bumper
//
// Reads the git history of the HEAD commit to determine which plugins
// had source files changed and what semver bump to apply, then updates
// marketplace.json in place.
//
// USAGE:
//   node scripts/auto-bump-version.mjs [--dry-run] [--registry <path>]
//
// BUMP RULES:
//   1. Any plugin whose source files changed in the merge gets a bump.
//   2. Bump type is derived from conventional commit scopes:
//        fix(kit/plugins/<name>):  → PATCH
//        feat(kit/plugins/<name>): → MINOR
//        feat(kit/plugins/<name>)!: or BREAKING CHANGE → MAJOR
//   3. Commits scoped to a specific plugin only affect that plugin.
//   4. Unscoped commits default to PATCH for all affected plugins.
//   5. Multiple commits touching the same plugin → highest bump wins.
//
// ENVIRONMENT:
//   PUSH_BEFORE   — pre-push SHA (github.event.before); covers rebase/ff merges
//   PUSH_AFTER    — post-push SHA (github.event.after)
//   GITHUB_OUTPUT — GitHub Actions output file (set automatically by Actions)

import { readFileSync, writeFileSync, appendFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const registryIdx = args.indexOf('--registry');
const registryPath = registryIdx !== -1 ? args[registryIdx + 1] : '.claude-plugin/marketplace.json';

// ── Semver helpers ───────────────────────────────────────────────────────────

function semverBump(version, type) {
  if (!/^\d+\.\d+\.\d+$/.test(version)) {
    throw new Error(`invalid semver: '${version}'`);
  }
  const [major, minor, patch] = version.split('.').map(Number);
  switch (type) {
    case 'major': return `${major + 1}.0.0`;
    case 'minor': return `${major}.${minor + 1}.0`;
    case 'patch': return `${major}.${minor}.${patch + 1}`;
    default: throw new Error(`unknown bump type: '${type}'`);
  }
}

const BUMP_RANK = { patch: 0, minor: 1, major: 2 };

function higherBump(a, b) {
  return (BUMP_RANK[b] ?? 0) > (BUMP_RANK[a] ?? 0) ? b : a;
}

// ── Conventional commit parser ───────────────────────────────────────────────

function parseConventionalCommit(line) {
  const match = line.match(/^(\w+)(?:\(([^)]*)\))?(!)?\s*:\s*(.+)/);
  if (!match) return null;
  const [, type, scope, bang, description] = match;
  return { type, scope: scope || null, breaking: !!bang, description };
}

function scopeToPluginName(scope, plugins) {
  if (!scope) return null;
  // Full path: kit/plugins/code-review
  if (plugins.find(p => p.source?.path === scope)) {
    return plugins.find(p => p.source?.path === scope).name;
  }
  // Plugin name: code-review
  if (plugins.find(p => p.name === scope)) {
    return scope;
  }
  // Path suffix: plugins/code-review
  const suffixMatch = plugins.find(p => p.source?.path?.endsWith('/' + scope));
  if (suffixMatch) return suffixMatch.name;
  return null;
}

function commitToBumpType(parsed, hasBreakingBody) {
  if (parsed.breaking || hasBreakingBody) return 'major';
  if (parsed.type === 'feat') return 'minor';
  return 'patch';
}

// ── Git helpers ──────────────────────────────────────────────────────────────

const ZERO_SHA = '0000000000000000000000000000000000000000';

function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8' }).trim();
}

function getParentCount() {
  const line = git('rev-list', '--parents', '-1', 'HEAD');
  return line.split(' ').length - 1;
}

// Resolve the diff range for this push.
// In CI, PUSH_BEFORE..PUSH_AFTER covers all commits in the push — including
// rebase/fast-forward merges with multiple single-parent commits.
// Locally, falls back to HEAD^1 (merge) or HEAD~1 (linear).
function getDiffRange() {
  const before = process.env.PUSH_BEFORE;
  const after = process.env.PUSH_AFTER;
  if (before && after && before !== ZERO_SHA) {
    return { from: before, to: after };
  }
  const parentCount = getParentCount();
  const from = parentCount > 1 ? 'HEAD^1' : 'HEAD~1';
  return { from, to: 'HEAD' };
}

function getChangedFiles() {
  const { from, to } = getDiffRange();
  try {
    return git('diff', '--name-only', from, to).split('\n').filter(Boolean);
  } catch {
    return [];
  }
}

function getCommitMessages() {
  const { from, to } = getDiffRange();
  try {
    const raw = git('log', '--format=---COMMIT_SEP---%n%B', `${from}..${to}`);
    return raw.split('---COMMIT_SEP---').map(m => m.trim()).filter(Boolean);
  } catch {
    return [];
  }
}

// Read the marketplace.json from before this push to identify new plugins.
function getBaseRegistry(registryPath) {
  const { from } = getDiffRange();
  try {
    return JSON.parse(git('show', `${from}:${registryPath}`));
  } catch {
    return null;
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────

try {
  const registry = JSON.parse(readFileSync(registryPath, 'utf8'));
  const changedFiles = getChangedFiles();
  const commitMessages = getCommitMessages();

  if (changedFiles.length === 0) {
    console.log('No file changes detected.');
    process.exit(0);
  }

  // Step 1: Map changed files to plugins
  const affectedPlugins = new Set();
  for (const file of changedFiles) {
    for (const plugin of registry.plugins) {
      const srcPath = plugin.source?.path;
      if (srcPath && file.startsWith(srcPath + '/')) {
        affectedPlugins.add(plugin.name);
      }
    }
  }

  if (affectedPlugins.size === 0) {
    console.log('No plugin source changes detected.');
    process.exit(0);
  }

  // Step 1b: Exclude newly added plugins — preserve their initial version
  const baseRegistry = getBaseRegistry(registryPath);
  const basePluginNames = new Set((baseRegistry?.plugins ?? []).map(p => p.name));
  for (const name of [...affectedPlugins]) {
    if (!basePluginNames.has(name)) {
      console.log(`  ${name}: new plugin — skipping (initial version preserved)`);
      affectedPlugins.delete(name);
    }
  }

  if (affectedPlugins.size === 0) {
    console.log('No existing plugins require a version bump.');
    process.exit(0);
  }

  // Step 2: Parse commit messages for per-plugin bump types
  // pluginBumps tracks the highest bump type per plugin
  const pluginBumps = new Map();
  for (const name of affectedPlugins) {
    pluginBumps.set(name, 'patch'); // default
  }

  for (const message of commitMessages) {
    const lines = message.split('\n');
    const subjectLine = lines[0] || '';
    const bodyText = lines.slice(1).join('\n');
    const hasBreakingBody = /BREAKING[\s-]CHANGE\s*:/i.test(bodyText);
    const parsed = parseConventionalCommit(subjectLine);

    if (!parsed) continue;

    const scopedPlugin = scopeToPluginName(parsed.scope, registry.plugins);
    const bumpType = commitToBumpType(parsed, hasBreakingBody);

    if (scopedPlugin && affectedPlugins.has(scopedPlugin)) {
      // Scoped commit — apply only to the named plugin
      pluginBumps.set(scopedPlugin, higherBump(pluginBumps.get(scopedPlugin), bumpType));
    } else if (!scopedPlugin) {
      // Unscoped commit — apply to all affected plugins
      for (const name of affectedPlugins) {
        pluginBumps.set(name, higherBump(pluginBumps.get(name), bumpType));
      }
    }
    // Scoped to a non-affected plugin → ignore
  }

  // Step 3: Apply bumps
  const bumped = [];
  for (const plugin of registry.plugins) {
    const bumpType = pluginBumps.get(plugin.name);
    if (!bumpType) continue;

    const oldVersion = plugin.version;
    const newVersion = semverBump(oldVersion, bumpType);
    plugin.version = newVersion;
    bumped.push({ name: plugin.name, from: oldVersion, to: newVersion, type: bumpType });
  }

  if (bumped.length === 0) {
    console.log('No plugins require a version bump.');
    process.exit(0);
  }

  // Step 4: Bump top-level marketplace version (highest individual bump type)
  const oldMarketplaceVersion = registry.version;
  let marketplaceBump = 'patch';
  for (const b of bumped) {
    marketplaceBump = higherBump(marketplaceBump, b.type);
  }
  registry.version = semverBump(registry.version, marketplaceBump);

  // Step 5: Report
  console.log(`Marketplace: ${oldMarketplaceVersion} → ${registry.version}`);
  for (const b of bumped) {
    console.log(`  ${b.name}: ${b.from} → ${b.to} (${b.type})`);
  }

  if (dryRun) {
    console.log('\n[dry-run] No files written.');
    process.exit(0);
  }

  // Step 6: Write
  writeFileSync(registryPath, JSON.stringify(registry, null, 2) + '\n');
  console.log(`\nUpdated ${registryPath}`);

  // Step 7: Set GitHub Actions outputs
  if (process.env.GITHUB_OUTPUT) {
    const summary = bumped.map(b => `${b.name} ${b.from} → ${b.to}`).join(', ');
    appendFileSync(process.env.GITHUB_OUTPUT, `bumped=true\n`);
    appendFileSync(process.env.GITHUB_OUTPUT, `summary=${summary}\n`);
    appendFileSync(process.env.GITHUB_OUTPUT, `count=${bumped.length}\n`);
  }

} catch (e) {
  console.error(`auto-bump-version: ${e.message}`);
  process.exit(1);
}
