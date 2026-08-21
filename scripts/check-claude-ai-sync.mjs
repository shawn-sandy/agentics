#!/usr/bin/env node
// Warns when the claude.ai copies of this marketplace's plugins are behind the
// repo. Claude Desktop does NOT load plugins from ~/.claude/plugins/cache/ — it
// runs frozen claude.ai snapshots under
//   ~/Library/Application Support/Claude/local-agent-mode-sessions/<a>/<b>/rpm/
// each stamped in that folder's manifest.json with the date claude.ai last
// pulled the marketplace. A skill shipped after that date is invisible in
// Desktop while working fine in the terminal CLI, which reads only the local
// cache. installed_plugins.json reports the CLI's versions, not Desktop's, so
// it agrees with the repo even while Desktop is months behind.
//
// Advisory only — always exits 0. Nothing here is fixable from the repo; the
// remedy is refreshing the marketplace on claude.ai.
//
// Usage:
//   node scripts/check-claude-ai-sync.mjs           # prints OK when in sync
//   node scripts/check-claude-ai-sync.mjs --quiet   # silent when in sync (hook)

import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
const MARKETPLACE_REL = '.claude-plugin/marketplace.json';
const SESSIONS = join(
  homedir(),
  'Library/Application Support/Claude/local-agent-mode-sessions',
);

// ── Pure logic (exported for tests) ────────────────────────────────────────

// ponytail: one direction only — what the repo has and the snapshot lacks. A
// snapshot carrying a skill the repo deleted is the same staleness, but it is
// rare and the orphan check below already catches the version of it that bites
// (a whole removed plugin still loading). Add the reverse diff if that changes.
export function missingFrom(repo, snapshot) {
  const have = new Set(snapshot);
  return repo.filter((name) => !have.has(name)).sort();
}

// "Our" claude.ai marketplaces are the ones that carry at least one plugin we
// still ship. Anything else inside them is a plugin we removed from
// marketplace.json that keeps loading in Desktop until it is uninstalled on
// claude.ai — where it shadows and duplicates its replacement's skills.
//
// Derived rather than hardcoded so a renamed claude.ai marketplace still
// matches, and so unrelated installs (canva, marketing) never trip it.
export function findOrphans(manifestPlugins, shippedNames) {
  const ours = new Set(
    manifestPlugins
      .filter((p) => shippedNames.has(p.name))
      .map((p) => p.marketplaceId),
  );
  return manifestPlugins
    .filter((p) => ours.has(p.marketplaceId) && !shippedNames.has(p.name))
    .map((p) => p.name)
    .sort();
}

export function formatReport(stale, orphans) {
  const lines = [];

  for (const s of stale) {
    const parts = [];
    if (s.skills.length) parts.push(`skills ${s.skills.join(', ')}`);
    if (s.commands.length) {
      parts.push(`commands ${s.commands.map((c) => `/${c}`).join(', ')}`);
    }
    lines.push(
      `WARNING: claude.ai copy of ${s.name} is behind (synced ${s.syncedAt}) — missing ${parts.join('; ')}`,
    );
  }

  if (orphans.length) {
    lines.push(
      `WARNING: plugins removed from the marketplace are still installed on claude.ai — ${orphans.join(', ')}`,
    );
  }

  if (lines.length) {
    lines.push(
      'These load only in Claude Desktop. Refresh the marketplace on claude.ai; the repo and dist are already current.',
    );
  }
  return lines;
}

// ── filesystem plumbing ────────────────────────────────────────────────────

function subdirs(path) {
  try {
    return readdirSync(path, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name);
  } catch {
    return [];
  }
}

function commandNames(path) {
  try {
    return readdirSync(path)
      .filter((f) => f.endsWith('.md'))
      .map((f) => f.slice(0, -3));
  } catch {
    return [];
  }
}

// Several session trees can exist; the newest manifest is the live one.
function newestSnapshotDir() {
  let best = null;
  for (const a of subdirs(SESSIONS)) {
    for (const b of subdirs(join(SESSIONS, a))) {
      const dir = join(SESSIONS, a, b, 'rpm');
      const manifest = join(dir, 'manifest.json');
      if (!existsSync(manifest)) continue;
      const at = statSync(manifest).mtimeMs;
      if (!best || at > best.at) best = { at, dir, manifest };
    }
  }
  return best;
}

function main() {
  const quiet = process.argv.includes('--quiet');
  const snapshot = newestSnapshotDir();

  // No Desktop snapshots here: another OS, or the terminal CLI only. Nothing
  // to compare against, and nothing wrong.
  if (!snapshot) {
    if (!quiet) console.log('OK: no Claude Desktop plugin snapshots on this machine.');
    return;
  }

  let manifestPlugins;
  try {
    manifestPlugins = JSON.parse(readFileSync(snapshot.manifest, 'utf8')).plugins ?? [];
  } catch {
    if (!quiet) console.log('OK: Claude Desktop plugin manifest unreadable — skipping.');
    return;
  }

  const marketplace = JSON.parse(readFileSync(join(ROOT, MARKETPLACE_REL), 'utf8'));
  const shippedNames = new Set((marketplace.plugins ?? []).map((p) => p.name));

  const stale = [];
  for (const plugin of manifestPlugins) {
    if (!shippedNames.has(plugin.name)) continue;

    const repoDir = join(ROOT, 'kit/plugins', plugin.name);
    if (!existsSync(repoDir)) continue;
    const snapDir = join(snapshot.dir, plugin.id);

    const skills = missingFrom(
      subdirs(join(repoDir, 'skills')),
      subdirs(join(snapDir, 'skills')),
    );
    const commands = missingFrom(
      commandNames(join(repoDir, 'commands')),
      commandNames(join(snapDir, 'commands')),
    );

    if (skills.length || commands.length) {
      stale.push({
        name: plugin.name,
        syncedAt: String(plugin.updatedAt ?? '').slice(0, 10) || 'unknown',
        skills,
        commands,
      });
    }
  }

  const lines = formatReport(stale, findOrphans(manifestPlugins, shippedNames));
  if (lines.length) {
    console.log(lines.join('\n'));
  } else if (!quiet) {
    console.log('OK: claude.ai plugin copies match the repo.');
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
