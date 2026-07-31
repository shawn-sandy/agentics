#!/usr/bin/env node
/**
 * extract-plan-spec.mjs — print a plan's spec-only markdown on demand.
 *
 * Read-on-demand replacement for the embedded #plan-digest cache. The visible
 * plan DOM is the source of truth; this resolves the spec two ways:
 *   - embedded-first: a legacy plan that still carries a #plan-digest block is
 *     printed verbatim but UN-guarded (real </script>, clean markdown — so not
 *     byte-identical to the old awk one-liner, by design);
 *   - DOM-derive: every other plan is parsed from its visible sections.
 *
 * Either way the output is clean spec markdown. Shared parse logic lives in
 * ./lib/plan-spec.mjs.
 *
 * Usage: node scripts/extract-plan-spec.mjs <plan.html>
 * Exit:  0 on success; 1 on missing/unreadable/unparseable input; 2 on misuse.
 */

import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

import {
  buildDigest,
  extractNextSteps,
  extractSections,
  hasDigest,
  readEmbeddedDigest,
  unguardScriptClose,
} from './lib/plan-spec.mjs';

/** Resolve a plan's spec markdown: embedded-first, DOM-derive fallback. */
export function resolveSpec(html) {
  if (hasDigest(html)) {
    const embedded = readEmbeddedDigest(html);
    if (embedded) return embedded;
  }
  // DOM-derive. buildDigest guards closing-script sequences for embedding; a
  // read tool wants clean markdown, so un-guard before printing.
  return unguardScriptClose(buildDigest(extractSections(html), extractNextSteps(html)));
}

function main() {
  const file = process.argv[2];
  if (!file) {
    console.error('Usage: node scripts/extract-plan-spec.mjs <plan.html>');
    process.exit(2);
  }
  let html;
  try {
    html = readFileSync(file, 'utf8');
  } catch (err) {
    console.error(`extract-plan-spec: cannot read ${file}: ${err.message}`);
    process.exit(1);
  }
  let spec;
  try {
    spec = resolveSpec(html);
  } catch (err) {
    console.error(`extract-plan-spec: cannot derive spec from ${file}: ${err.message}`);
    process.exit(1);
  }
  process.stdout.write(spec.endsWith('\n') ? spec : `${spec}\n`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
