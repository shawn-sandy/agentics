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
  extractNextSteps,
  extractPreviews,
  extractSections,
  hasDigest,
  nextStepsMarkdown,
  readEmbeddedDigest,
  specMarkdown,
} from './lib/plan-spec.mjs';

// Plans backfilled before Next Steps round-tripping (plan-agent < 7.4.3)
// carry an embedded digest with no Next Steps section, even when the visible
// DOM has one — the digest was frozen at backfill time and never regenerated.
// Matches nextStepsMarkdown()'s own heading, case-insensitively per the same
// heading-matching rule parseSpecMarkdown() uses.
const DIGEST_HAS_NEXT_STEPS_RE = /^##\s*(?:next steps|out of scope)\b/im;

/** Resolve a plan's spec markdown: embedded-first, DOM-derive fallback. */
export function resolveSpec(html) {
  // A page with previews always derives from the DOM: an embedded digest is
  // guarded, and the guard is non-injective, so a preview's <\/script> would
  // come back as a real closing tag.
  if (hasDigest(html) && !extractPreviews(html)) {
    const embedded = readEmbeddedDigest(html);
    if (embedded) {
      if (DIGEST_HAS_NEXT_STEPS_RE.test(embedded)) return embedded;
      // Splice in the DOM-visible follow-ups a stale digest predates, rather
      // than silently returning a spec that is missing a whole section.
      return embedded + nextStepsMarkdown(extractNextSteps(html)).join('\n');
    }
  }
  // DOM-derive. specMarkdown, not an un-guarded buildDigest: guarding is
  // non-injective, and a preview that writes <\/script> inside its own script
  // would come back as a real closing tag.
  return specMarkdown(extractSections(html), extractNextSteps(html), extractPreviews(html));
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
