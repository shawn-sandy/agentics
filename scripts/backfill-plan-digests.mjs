#!/usr/bin/env node
/**
 * backfill-plan-digests.mjs — inject a spec-only markdown digest
 * (<script type="text/markdown" id="plan-digest">) into existing HTML plans
 * that lack one.
 *
 * Parse/build logic lives in scripts/lib/plan-spec.mjs (shared with the
 * read-side scripts/extract-plan-spec.mjs). This file keeps only the
 * write-side injector and batch runner.
 *
 * Contract:
 *   - The digest is the authored spec only: title, objective, context, files,
 *     steps (action/why/verify), tests, acceptance criteria, verification.
 *   - Status, checkbox, and progress state are never written into the digest,
 *     and no other byte of the plan is modified (insertion-only).
 *   - Literal closing-script sequences in content are guarded as <\/script>.
 *   - Idempotent: plans that already have a digest are skipped.
 *   - No partial digests: a plan is only injected when every expected section
 *     parses; otherwise it is skipped and reported with a reason.
 *
 * Note: new plans no longer embed a digest — the extractor derives the spec
 * from the DOM on read. This injector is retained to backfill or re-seed
 * legacy embedded plans on demand.
 *
 * Usage: node scripts/backfill-plan-digests.mjs [--dry-run] [--dir <path>]
 *   --dry-run   report what would happen without writing any file
 *   --dir       plans directory (default: docs/plans relative to repo root)
 */

import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { buildDigest, extractSections, hasDigest, ParseError } from './lib/plan-spec.mjs';

// Re-export the shared parse helpers so existing importers keep resolving
// them from this module.
export { buildDigest, decodeEntities, extractSections, guardScriptClose, hasDigest } from './lib/plan-spec.mjs';

const DEFAULT_DIR = join(fileURLToPath(new URL('..', import.meta.url)), 'docs', 'plans');

const BODY_ANCHOR_RE = /<\/head>\s*<body[^>]*>/;

/** Insert the digest block immediately after <body>; insertion-only. */
export function injectDigest(html, digest) {
  const anchor = html.match(BODY_ANCHOR_RE);
  if (!anchor) throw new ParseError('no </head><body> anchor found');
  const block = [
    '',
    '',
    '<!-- ══════════════════════════════════════════════════════════════════',
    '     MACHINE-READABLE DIGEST (backfilled)',
    '     First element child of <body>. type="text/markdown" never renders',
    '     or runs. Spec only — no status/checkbox/progress state. Literal',
    '     closing-script sequences in the content are guarded as <\\/script.',
    '     Read on demand with:',
    '       node scripts/extract-plan-spec.mjs <file>',
    '     ══════════════════════════════════════════════════════════════════ -->',
    '<script type="text/markdown" id="plan-digest">',
    digest,
    '</script>',
  ].join('\n');
  const at = anchor.index + anchor[0].length;
  return html.slice(0, at) + block + html.slice(at);
}

/**
 * Backfill every top-level *.html plan in `dir` (index.html excluded;
 * subdirectories such as archive/ are never visited).
 */
export function runBackfill(dir, { dryRun = false } = {}) {
  const result = { injected: [], hasDigest: [], unparseable: [], failed: [] };
  let names;
  try {
    names = readdirSync(dir, { withFileTypes: true })
      .filter((e) => e.isFile() && e.name.endsWith('.html') && e.name !== 'index.html')
      .map((e) => e.name)
      .sort();
  } catch (err) {
    result.failed.push({ file: dir, reason: `cannot read directory: ${err.message}` });
    return result;
  }

  for (const name of names) {
    const file = join(dir, name);
    let html;
    try {
      html = readFileSync(file, 'utf8');
    } catch (err) {
      result.failed.push({ file: name, reason: `read error: ${err.message}` });
      continue;
    }
    if (hasDigest(html)) {
      result.hasDigest.push(name);
      continue;
    }
    let updated;
    try {
      const sections = extractSections(html);
      updated = injectDigest(html, buildDigest(sections));
    } catch (err) {
      if (err instanceof ParseError) {
        result.unparseable.push({ file: name, reason: err.message });
        continue;
      }
      throw err;
    }
    if (!dryRun) {
      try {
        writeFileSync(file, updated);
      } catch (err) {
        result.failed.push({ file: name, reason: `write error: ${err.message}` });
        continue;
      }
    }
    result.injected.push(name);
  }
  return result;
}

function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const dirFlag = args.indexOf('--dir');
  const dir = dirFlag !== -1 && args[dirFlag + 1] ? args[dirFlag + 1] : DEFAULT_DIR;

  const r = runBackfill(dir, { dryRun });
  console.log(`Backfill plan digests — ${dir}${dryRun ? ' (dry run)' : ''}`);
  console.log(`  injected: ${r.injected.length}`);
  for (const f of r.injected) console.log(`    + ${f}`);
  console.log(`  skipped (already has digest): ${r.hasDigest.length}`);
  for (const f of r.hasDigest) console.log(`    = ${f}`);
  console.log(`  skipped (could not fully parse — no partial digests): ${r.unparseable.length}`);
  for (const { file, reason } of r.unparseable) console.log(`    ! ${file}: ${reason}`);
  console.log(`  failed (I/O): ${r.failed.length}`);
  for (const { file, reason } of r.failed) console.log(`    x ${file}: ${reason}`);
  process.exitCode = r.failed.length > 0 ? 1 : 0;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
