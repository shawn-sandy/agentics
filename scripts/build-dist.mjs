#!/usr/bin/env node
// Manifest-driven clean builder for the agentics marketplace.
// Reads .claude-plugin/marketplace.json plugins[], copies only KEEP-listed
// paths per plugin into OUT_DIR, drops anything matching the DROP denylist,
// and emits a clean root (marketplace.json sans removed[], slim README, LICENSE).
//
// Usage:
//   node scripts/build-dist.mjs              # build to dist/
//   node scripts/build-dist.mjs --list       # print active plugin names
//   node scripts/build-dist.mjs --check      # verify no DROP patterns leaked
//   # --publish / --dry-run: reserved (not yet implemented)

import { readFileSync, writeFileSync, mkdirSync, cpSync, statSync, readdirSync, rmSync, existsSync } from 'node:fs';
import { join, relative, basename, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

// ── Configuration ──────────────────────────────────────────────────────────

const ROOT = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
const OUT_DIR = join(ROOT, 'dist');
const MARKETPLACE_PATH = join(ROOT, '.claude-plugin', 'marketplace.json');
const PLUGINS_DIR = join(ROOT, 'kit', 'plugins');

const KEEP = new Set([
  '.claude-plugin',
  'commands',
  'skills',
  'agents',
  'hooks',
  'hooks.json',
  'templates',
  'references',
  'scripts',
  'README.md',
  'CHANGELOG.md',
  'LICENSE',
]);

const DROP_PATTERNS = [
  { test: (rel) => rel.startsWith('docs/') || rel === 'docs', label: 'docs/' },
  { test: (rel) => rel.endsWith('.local.md'), label: '*.local.md' },
  { test: (rel) => basename(rel) === '.DS_Store', label: '.DS_Store' },
  { test: (rel) => rel.endsWith('.png'), label: '*.png' },
  { test: (rel) => rel.startsWith('.playwright-mcp/') || rel === '.playwright-mcp', label: '.playwright-mcp/' },
];

// ── Helpers ────────────────────────────────────────────────────────────────

function loadManifest() {
  return JSON.parse(readFileSync(MARKETPLACE_PATH, 'utf8'));
}

function walkDir(dir) {
  const entries = [];
  if (!existsSync(dir)) return entries;
  for (const ent of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, ent.name);
    if (ent.isDirectory()) {
      entries.push(...walkDir(full));
    } else if (ent.isFile()) {
      entries.push(full);
    }
  }
  return entries;
}

function dirStats(dir) {
  const files = walkDir(dir);
  let bytes = 0;
  for (const f of files) bytes += statSync(f).size;
  return { count: files.length, bytes };
}

function formatBytes(b) {
  if (b < 1024) return `${b} B`;
  if (b < 1024 * 1024) return `${(b / 1024).toFixed(1)} KB`;
  return `${(b / (1024 * 1024)).toFixed(1)} MB`;
}

function matchesDrop(relPath) {
  for (const p of DROP_PATTERNS) {
    if (p.test(relPath)) return p.label;
  }
  return null;
}

// ── Build ──────────────────────────────────────────────────────────────────

function build() {
  const manifest = loadManifest();
  const activePlugins = manifest.plugins ?? [];

  if (existsSync(OUT_DIR)) rmSync(OUT_DIR, { recursive: true });
  mkdirSync(OUT_DIR, { recursive: true });

  const summary = [];
  const allDropped = [];

  for (const plugin of activePlugins) {
    const pluginSrc = join(PLUGINS_DIR, plugin.name);
    if (!existsSync(pluginSrc)) {
      summary.push({ name: plugin.name, error: 'source directory not found' });
      continue;
    }

    const srcStats = dirStats(pluginSrc);
    const pluginDest = join(OUT_DIR, 'kit', 'plugins', plugin.name);
    mkdirSync(pluginDest, { recursive: true });

    const dropped = [];
    let destBytes = 0;
    let destCount = 0;

    const topEntries = readdirSync(pluginSrc, { withFileTypes: true });
    for (const ent of topEntries) {
      const entName = ent.name;
      if (!KEEP.has(entName)) {
        const entPath = join(pluginSrc, entName);
        if (ent.isDirectory()) {
          const subFiles = walkDir(entPath);
          for (const f of subFiles) {
            const rel = relative(pluginSrc, f);
            dropped.push({ path: `kit/plugins/${plugin.name}/${rel}`, reason: 'not in KEEP allowlist' });
          }
        } else {
          dropped.push({ path: `kit/plugins/${plugin.name}/${entName}`, reason: 'not in KEEP allowlist' });
        }
        continue;
      }

      const srcPath = join(pluginSrc, entName);
      const dstPath = join(pluginDest, entName);

      if (ent.isFile()) {
        const rel = entName;
        const dropLabel = matchesDrop(rel);
        if (dropLabel) {
          dropped.push({ path: `kit/plugins/${plugin.name}/${rel}`, reason: `DROP: ${dropLabel}` });
          continue;
        }
        cpSync(srcPath, dstPath);
        destBytes += statSync(dstPath).size;
        destCount++;
      } else if (ent.isDirectory()) {
        const srcFiles = walkDir(srcPath);
        for (const f of srcFiles) {
          const rel = relative(pluginSrc, f);
          const dropLabel = matchesDrop(rel);
          if (dropLabel) {
            dropped.push({ path: `kit/plugins/${plugin.name}/${rel}`, reason: `DROP: ${dropLabel}` });
            continue;
          }
          const dest = join(pluginDest, rel);
          mkdirSync(join(dest, '..'), { recursive: true });
          cpSync(f, dest);
          destBytes += statSync(dest).size;
          destCount++;
        }
      }
    }

    allDropped.push(...dropped);

    summary.push({
      name: plugin.name,
      src: srcStats,
      dest: { count: destCount, bytes: destBytes },
      droppedCount: dropped.length,
    });
  }

  // ── Clean root files ───────────────────────────────────────────────────

  const DIST_REPO_CANONICAL = 'https://github.com/shawn-sandy/agentics-kit.git';
  const cleanManifest = { ...manifest };
  delete cleanManifest.removed;
  cleanManifest.plugins = (cleanManifest.plugins ?? []).map(p => ({
    ...p,
    source: { ...p.source, url: DIST_REPO_CANONICAL },
  }));
  const rootMarketplace = join(OUT_DIR, '.claude-plugin');
  mkdirSync(rootMarketplace, { recursive: true });
  writeFileSync(
    join(rootMarketplace, 'marketplace.json'),
    JSON.stringify(cleanManifest, null, 2) + '\n',
  );

  const readmeSrc = join(ROOT, 'README.md');
  if (existsSync(readmeSrc)) cpSync(readmeSrc, join(OUT_DIR, 'README.md'));

  const licenseSrc = join(ROOT, 'LICENSE');
  if (existsSync(licenseSrc)) cpSync(licenseSrc, join(OUT_DIR, 'LICENSE'));

  // ── Print summary ──────────────────────────────────────────────────────

  printSummary(summary, allDropped);

  return { summary, allDropped };
}

// ── Summary printer ────────────────────────────────────────────────────────

function printSummary(summary, allDropped) {
  const SEP = '-'.repeat(78);

  console.log('\n' + SEP);
  console.log('  BUILD SUMMARY');
  console.log(SEP);

  const nameWidth = Math.max(
    'Plugin'.length,
    ...summary.map(s => s.name.length),
  );

  const header = [
    'Plugin'.padEnd(nameWidth),
    'Src Files'.padStart(10),
    'Src Size'.padStart(10),
    'Dist Files'.padStart(11),
    'Dist Size'.padStart(10),
    'Dropped'.padStart(8),
  ].join('  ');

  console.log(`\n  ${header}`);
  console.log(`  ${'─'.repeat(header.length)}`);

  let totalSrcBytes = 0;
  let totalDestBytes = 0;
  let totalSrcCount = 0;
  let totalDestCount = 0;
  let totalDropped = 0;

  for (const p of summary) {
    if (p.error) {
      console.log(`  ${p.name.padEnd(nameWidth)}  ${'ERROR: ' + p.error}`);
      continue;
    }

    totalSrcBytes += p.src.bytes;
    totalDestBytes += p.dest.bytes;
    totalSrcCount += p.src.count;
    totalDestCount += p.dest.count;
    totalDropped += p.droppedCount;

    const row = [
      p.name.padEnd(nameWidth),
      String(p.src.count).padStart(10),
      formatBytes(p.src.bytes).padStart(10),
      String(p.dest.count).padStart(11),
      formatBytes(p.dest.bytes).padStart(10),
      String(p.droppedCount).padStart(8),
    ].join('  ');

    console.log(`  ${row}`);
  }

  console.log(`  ${'─'.repeat(header.length)}`);

  const totals = [
    'TOTAL'.padEnd(nameWidth),
    String(totalSrcCount).padStart(10),
    formatBytes(totalSrcBytes).padStart(10),
    String(totalDestCount).padStart(11),
    formatBytes(totalDestBytes).padStart(10),
    String(totalDropped).padStart(8),
  ].join('  ');

  console.log(`  ${totals}`);

  const saved = totalSrcBytes - totalDestBytes;
  const pct = totalSrcBytes > 0 ? ((saved / totalSrcBytes) * 100).toFixed(1) : '0.0';
  console.log(`\n  Bytes saved: ${formatBytes(saved)} (${pct}% reduction)`);

  // ── Dropped paths ────────────────────────────────────────────────────

  if (allDropped.length > 0) {
    console.log(`\n  DROPPED PATHS (${allDropped.length})`);
    console.log(`  ${'─'.repeat(74)}`);
    for (const d of allDropped) {
      console.log(`  ✕ ${d.path}`);
      console.log(`    ${d.reason}`);
    }
  } else {
    console.log('\n  No paths dropped.');
  }

  console.log('\n' + SEP + '\n');
}

// ── --list ─────────────────────────────────────────────────────────────────

function listPlugins() {
  const manifest = loadManifest();
  for (const p of manifest.plugins ?? []) {
    console.log(p.name);
  }
}

// ── --check ────────────────────────────────────────────────────────────────

function check() {
  if (!existsSync(OUT_DIR)) {
    console.error('No dist/ directory found. Run the build first.');
    process.exit(1);
  }

  const allFiles = walkDir(OUT_DIR);
  const violations = [];

  for (const f of allFiles) {
    const rel = relative(OUT_DIR, f);
    const dropLabel = matchesDrop(rel);
    if (dropLabel) {
      violations.push({ path: rel, pattern: dropLabel });
      continue;
    }

    const parts = rel.split('/');
    if (parts[0] === 'kit' && parts[1] === 'plugins' && parts.length > 3) {
      const withinPlugin = parts.slice(3).join('/');
      const dropInPlugin = matchesDrop(withinPlugin);
      if (dropInPlugin) {
        violations.push({ path: rel, pattern: dropInPlugin });
      }
    }
  }

  if (violations.length > 0) {
    console.error(`CHECK FAILED: ${violations.length} denylisted path(s) in dist/\n`);
    for (const v of violations) {
      console.error(`  ✕ ${v.path}  (matched ${v.pattern})`);
    }
    process.exit(1);
  }

  console.log('CHECK PASSED: no denylisted paths in dist/');
  process.exit(0);
}

// ── publish ────────────────────────────────────────────────────────────────

function publish() {
  if (!existsSync(OUT_DIR)) {
    console.error('No dist/ directory found. Run the build first.');
    process.exit(1);
  }

  const distUrl = process.env.DIST_REPO_URL;
  if (!distUrl) {
    console.error('DIST_REPO_URL environment variable is not set.');
    process.exit(1);
  }

  const token = process.env.DIST_REPO_TOKEN;
  const authUrl = token
    ? distUrl.replace('https://', `https://x-access-token:${token}@`)
    : distUrl;

  const tmpDir = join(ROOT, '.dist-checkout');

  try {
    if (existsSync(tmpDir)) rmSync(tmpDir, { recursive: true });

    execFileSync('git', ['clone', '--depth=1', authUrl, tmpDir], { stdio: 'inherit' });
    const trackedFiles = execFileSync('git', ['ls-files'], { cwd: tmpDir, encoding: 'utf8' })
      .trim()
      .split('\n')
      .filter(f => f.length > 0);
    for (const f of trackedFiles) {
      rmSync(join(tmpDir, f), { force: true });
    }

    for (const ent of readdirSync(OUT_DIR, { withFileTypes: true })) {
      const src = join(OUT_DIR, ent.name);
      const dst = join(tmpDir, ent.name);
      cpSync(src, dst, { recursive: true });
    }

    const sha = execFileSync('git', ['rev-parse', '--short', 'HEAD'], { cwd: ROOT }).toString().trim();

    execFileSync('git', ['config', 'user.email', 'github-actions[bot]@users.noreply.github.com'], { cwd: tmpDir });
    execFileSync('git', ['config', 'user.name', 'github-actions[bot]'], { cwd: tmpDir });
    execFileSync('git', ['add', '-A'], { cwd: tmpDir });
    execFileSync('git', ['commit', '--allow-empty', '-m', `chore: sync from agentics@${sha}`], { cwd: tmpDir });
    execFileSync('git', ['push'], { cwd: tmpDir });

    console.log(`Published: agentics@${sha} -> ${distUrl}`);
  } finally {
    if (existsSync(tmpDir)) rmSync(tmpDir, { recursive: true });
  }
}

// ── CLI ────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

if (args.includes('--list')) {
  listPlugins();
} else if (args.includes('--check')) {
  check();
} else if (args.includes('--publish')) {
  publish();
} else if (args.includes('--dry-run')) {
  console.error('--dry-run is not yet implemented.');
  process.exit(1);
} else {
  build();
}
