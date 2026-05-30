#!/usr/bin/env node
// Git merge driver for .claude-plugin/marketplace.json
// Invoked by git as: node merge-marketplace.mjs %O %A %B
//   %O = base (common ancestor path)
//   %A = ours (current branch path — driver MUST write result here)
//   %B = theirs (incoming branch path)
// Exit 0 on success; exit 1 (file untouched) on any parse or semver error.

import { readFileSync, writeFileSync } from 'node:fs';

const [,, basePath, oursPath, theirsPath] = process.argv;

function semverMax(a, b) {
  if (!/^\d+\.\d+\.\d+$/.test(a) || !/^\d+\.\d+\.\d+$/.test(b)) {
    throw new Error(`invalid semver (expected X.Y.Z): '${a}' vs '${b}'`);
  }
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if (pa[i] > pb[i]) return a;
    if (pa[i] < pb[i]) return b;
  }
  return a; // equal — keep ours
}

try {
  const base = JSON.parse(readFileSync(basePath, 'utf8'));
  const ours = JSON.parse(readFileSync(oursPath, 'utf8'));
  const theirs = JSON.parse(readFileSync(theirsPath, 'utf8'));

  const merged = { ...ours };

  // Top-level marketplace version
  if (ours.version !== undefined || theirs.version !== undefined) {
    merged.version = semverMax(ours.version ?? '0.0.0', theirs.version ?? '0.0.0');
  }

  // Merge plugins[] — ours order first, then append entries new in theirs
  const theirPlugins = new Map((theirs.plugins ?? []).map(p => [p.name, p]));
  const seenNames = new Set();

  merged.plugins = (ours.plugins ?? []).map(op => {
    seenNames.add(op.name);
    const tp = theirPlugins.get(op.name);
    if (!tp) return op;
    return { ...op, version: semverMax(op.version, tp.version) };
  });

  for (const tp of (theirs.plugins ?? [])) {
    if (!seenNames.has(tp.name)) {
      merged.plugins.push(tp);
    }
  }

  // Merge removed[] — union by name, ours order first
  const removedNames = new Set((ours.removed ?? []).map(r => r.name));
  merged.removed = [
    ...(ours.removed ?? []),
    ...(theirs.removed ?? []).filter(r => !removedNames.has(r.name)),
  ];

  writeFileSync(oursPath, JSON.stringify(merged, null, 2) + '\n');
  process.exit(0);
} catch (e) {
  process.stderr.write(`merge-marketplace: ${e.message}\n`);
  process.exit(1);
}
