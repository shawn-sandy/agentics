#!/usr/bin/env node
// Fails a PR when a plugin's files changed but its marketplace.json version
// did not go up. Guards the silent no-op: without a version bump the daily
// publish-dist sync ships a byte-identical tree and nobody gets the update.
//
// Usage:
//   node scripts/check-plugin-versions.mjs        # BASE_REF env or 'main'

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

const ROOT = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
const MARKETPLACE_REL = '.claude-plugin/marketplace.json';

// ── Pure logic (exported for tests) ────────────────────────────────────────

// ponytail: no prerelease/build-metadata handling — this marketplace only ever
// ships plain x.y.z. Reach for a semver lib if that stops being true.
export function parseSemver(v) {
  const m = /^(\d+)\.(\d+)\.(\d+)$/.exec(String(v ?? '').trim());
  return m ? [Number(m[1]), Number(m[2]), Number(m[3])] : null;
}

export function isHigher(current, base) {
  const a = parseSemver(current);
  const b = parseSemver(base);
  if (!a || !b) return false;
  for (let i = 0; i < 3; i++) {
    if (a[i] > b[i]) return true;
    if (a[i] < b[i]) return false;
  }
  return false;
}

// ponytail: any file under a plugin counts as a change, including DROP-listed
// paths that never ship (e.g. kit/plugins/x/docs/). Worst case is a nag to bump
// on a docs-only edit. Reuse build-dist's KEEP/DROP here if that gets annoying.
export function changedPlugins(changedPaths) {
  const names = new Set();
  for (const p of changedPaths) {
    const m = /^kit\/plugins\/([^/]+)\//.exec(p);
    if (m) names.add(m[1]);
  }
  return names;
}

export function findViolations(changedPaths, currentManifest, baseManifest) {
  const byName = (manifest) =>
    new Map((manifest.plugins ?? []).map((p) => [p.name, p]));
  const current = byName(currentManifest);
  const base = byName(baseManifest);

  const violations = [];
  for (const name of [...changedPlugins(changedPaths)].sort()) {
    const cur = current.get(name);
    // Not in the manifest = not built, not shipped. Nothing to guard.
    if (!cur) continue;

    const prior = base.get(name);
    if (!prior) continue; // new plugin — any starting version is fine

    if (!parseSemver(cur.version)) {
      violations.push({ name, base: prior.version, current: cur.version, reason: 'unparseable version' });
    } else if (!isHigher(cur.version, prior.version)) {
      violations.push({ name, base: prior.version, current: cur.version, reason: 'version not bumped' });
    }
  }
  return violations;
}

// ── git plumbing ───────────────────────────────────────────────────────────

function git(args, opts = {}) {
  return execFileSync('git', args, { cwd: ROOT, encoding: 'utf8', ...opts }).trim();
}

function main() {
  const baseRef = process.env.BASE_REF || 'main';
  const base = `origin/${baseRef}`;

  const changed = git(['diff', '--name-only', `${base}...HEAD`])
    .split('\n')
    .filter(Boolean);

  const currentManifest = JSON.parse(readFileSync(join(ROOT, MARKETPLACE_REL), 'utf8'));
  const baseManifest = JSON.parse(git(['show', `${base}:${MARKETPLACE_REL}`]));

  const violations = findViolations(changed, currentManifest, baseManifest);

  if (violations.length === 0) {
    console.log('OK: every changed plugin has a higher version than ' + base);
    return;
  }

  console.error(`\nPlugin version guard failed (${violations.length}):\n`);
  for (const v of violations) {
    console.error(`  ${v.name}: files changed but version is ${v.current} (${base}: ${v.base}) — ${v.reason}`);
  }
  console.error(
    '\nBump each plugin\'s "version" in .claude-plugin/marketplace.json.' +
    '\nfix = patch, new command/skill/agent/hook = minor, removal or breaking change = major.' +
    '\nSee .claude/rules/marketplace.md.\n',
  );
  process.exit(1);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
