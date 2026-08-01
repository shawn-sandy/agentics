#!/usr/bin/env node
// The plans-index generator ships as three byte-identical copies:
//
//   docs/plans/build-index.sh                  — run by hand and in CI
//   scripts/build-plans-index.sh               — run by hand and in CI
//   kit/plugins/plan-agent/hooks/build-index.sh — run as the plugin hook
//
// Nothing but convention kept them in step, so an edit applied to one or two
// of them shipped a stale generator whose only symptom was a gallery that
// silently disagreed with itself depending on which entry point rebuilt it.
// This asserts the three hash identically and names the copy that drifted.

import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

const COPIES = [
  'docs/plans/build-index.sh',
  'scripts/build-plans-index.sh',
  'kit/plugins/plan-agent/hooks/build-index.sh',
];

console.log('=== build-index.sh copy parity ===\n');

const hashes = COPIES.map((rel) => {
  let body;
  try {
    body = readFileSync(join(ROOT, rel));
  } catch (e) {
    console.log(`FAIL: ${rel} is unreadable — ${e.message}`);
    process.exit(1);
  }
  return { rel, hash: createHash('sha256').update(body).digest('hex') };
});

// The first copy is the reference only because a list needs a head; any
// divergence is reported against it rather than blamed on it.
const [reference, ...rest] = hashes;
const drifted = rest.filter((c) => c.hash !== reference.hash);

if (drifted.length > 0) {
  console.log(`FAIL: build-index.sh copies diverged from ${reference.rel}`);
  console.log(`  ${reference.rel}  ${reference.hash.slice(0, 12)}`);
  for (const c of drifted) console.log(`  ${c.rel}  ${c.hash.slice(0, 12)}  <-- differs`);
  console.log('\nCopy one over the others so all three stay byte-identical.');
  process.exit(1);
}

console.log(`PASS: all ${COPIES.length} copies hash ${reference.hash.slice(0, 12)}`);
console.log('\n1 passed, 0 failed');
