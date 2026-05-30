#!/usr/bin/env node
// Git merge driver for .claude-plugin/marketplace.json
// Invoked by git as: node merge-marketplace.mjs %O %A %B
//   %O = base (common ancestor — may be /dev/null for new-file merges)
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

// 3-way field merge: where ours is unchanged from base, take theirs; ours wins on conflict.
// Handles arbitrary object shapes — version/plugins/removed are overridden by callers.
function mergeFields(base, ours, theirs) {
  const b = base ?? {};
  const eq = (x, y) => JSON.stringify(x) === JSON.stringify(y);
  const keys = new Set([...Object.keys(ours), ...Object.keys(theirs)]);
  const result = {};
  for (const k of keys) {
    if (!(k in ours)) {
      result[k] = theirs[k];                              // new in theirs — include
    } else if (!(k in theirs)) {
      result[k] = ours[k];                               // absent from theirs — keep ours
    } else if (eq(ours[k], b[k]) && !eq(theirs[k], b[k])) {
      result[k] = theirs[k];                             // ours unchanged, theirs updated — take theirs
    } else {
      result[k] = ours[k];                               // ours changed, or both same — keep ours
    }
  }
  return result;
}

try {
  // Base may be /dev/null (new-file merge) or empty — fall back to {} gracefully.
  let base = {};
  try {
    const raw = readFileSync(basePath, 'utf8');
    if (raw.trim()) base = JSON.parse(raw);
  } catch { /* base unavailable — ours-wins fallback for all field comparisons */ }

  const ours = JSON.parse(readFileSync(oursPath, 'utf8'));
  const theirs = JSON.parse(readFileSync(theirsPath, 'utf8'));

  // 3-way merge top-level fields; version/plugins/removed are overridden below.
  const merged = mergeFields(base, ours, theirs);

  // Top-level marketplace version — always take max.
  if (ours.version !== undefined || theirs.version !== undefined) {
    merged.version = semverMax(ours.version ?? '0.0.0', theirs.version ?? '0.0.0');
  }

  // Names that ours deliberately removed — don't let theirs resurrect them.
  const oursRemovedNames = new Set((ours.removed ?? []).map(r => r.name));

  // Merge plugins[] — ours order first, then append entries new in theirs.
  const basePlugins = new Map((base.plugins ?? []).map(p => [p.name, p]));
  const theirPlugins = new Map((theirs.plugins ?? []).map(p => [p.name, p]));

  merged.plugins = (ours.plugins ?? []).map(op => {
    const tp = theirPlugins.get(op.name);
    theirPlugins.delete(op.name); // remaining entries after map are new-in-theirs only
    if (!tp) return op;
    const bp = basePlugins.get(op.name) ?? {};
    const plugin = mergeFields(bp, op, tp);
    plugin.version = semverMax(op.version ?? '0.0.0', tp.version ?? '0.0.0');
    return plugin;
  });

  for (const tp of theirPlugins.values()) {
    if (!oursRemovedNames.has(tp.name)) {
      merged.plugins.push(tp);
    }
  }

  // Merge removed[] — union by name, ours order first.
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
