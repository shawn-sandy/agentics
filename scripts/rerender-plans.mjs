#!/usr/bin/env node
/**
 * rerender-plans.mjs — re-render every committed plan HTML through the current
 * presentation shell.
 *
 * Why this exists: `scripts/lib/plan-shell.mjs` is the only thing that decides
 * what a rendered plan looks like, but the ~100 plans under docs/plans/ are
 * committed OUTPUT. A shell change reaches them only when someone next writes
 * that plan's spec, so a redesign otherwise lands as a site where the gallery
 * is new and every page behind it is old. Run this once after any shell change.
 *
 * It is presentation-only by construction. Two source paths, one guard each:
 *
 *   - A plan with a sibling `.md` is re-rendered FROM that spec, which is the
 *     documented source of truth and the same input the render hook uses.
 *     Guarded by `extractSections(new)` deep-equalling the parsed spec. If the
 *     committed HTML had drifted from its spec, the spec wins and the file is
 *     reported as a content change so it is never a silent one.
 *   - A plan with no `.md` is round-tripped through its own DOM:
 *     `extractSections` + `extractNextSteps` for the body, the `<head>` meta
 *     tags and the live DOM for everything the digest deliberately does not
 *     carry (status, dates, done markers — see the note in `buildDigest`).
 *     Guarded by `extractSections(new)` deep-equalling `extractSections(old)`
 *     AND every `plan-*` meta tag surviving byte-identical.
 *
 * A file that fails its guard is left exactly as it was and listed at the end.
 * Nothing is written unless its guard passed, so a partial run is still a
 * consistent tree.
 *
 * Usage:
 *   node scripts/rerender-plans.mjs [--dry-run] [--dir docs/plans]
 */

import assert from 'node:assert/strict';
import { readdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';

import { extractSections, extractNextSteps, parseSpecMarkdown } from './lib/plan-spec.mjs';
import { renderPlanHtml } from './build-plan-html.mjs';

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const dirAt = args.indexOf('--dir');
const PLANS_DIR = dirAt === -1 ? 'docs/plans' : args[dirAt + 1];

/* ── Readers for the state buildDigest deliberately leaves in the HTML ── */

const META_KEYS = ['status', 'effort', 'type', 'created', 'repo', 'prototype', 'issue'];

/** Same shape the three build-index.sh copies read. */
function metaTag(html, name) {
  const m = html.match(new RegExp(`<meta\\s+name="plan-${name}"\\s+content="([^"]*)"`));
  return m ? m[1] : '';
}

function decode(s) {
  return s
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');
}

/** The plain-language summary; it lives in the DOM, not in a meta tag. */
function glanceOf(html) {
  const m = html.match(/<section[^>]*class="[^"]*\bplan-glance\b[^"]*"[^>]*>[\s\S]*?<p>([\s\S]*?)<\/p>/i);
  return m ? decode(m[1].replace(/<[^>]+>/g, '')).trim() : '';
}

/** Per-step, per-criterion done state plus any completion-report entries. */
function progressOf(html) {
  const steps = [...html.matchAll(/<div class="step-card( completed)?"/g)].map((m) => Boolean(m[1]));
  const criteria = [...html.matchAll(/<input type="checkbox" id="ac\d+"( checked)?>/g)].map((m) => Boolean(m[1]));
  const report = [];
  const dl = html.match(/<dl class="report-list">([\s\S]*?)<\/dl>/);
  if (dl) {
    const dts = [...dl[1].matchAll(/<dt>([\s\S]*?)<\/dt>\s*<dd>([\s\S]*?)<\/dd>/g)];
    for (const m of dts) {
      report.push({
        item: decode(m[1].replace(/<[^>]+>/g, '')).trim(),
        reason: decode(m[2].replace(/<[^>]+>/g, '')).trim(),
      });
    }
  }
  return { steps, criteria, report };
}

/* ── Sweep ─────────────────────────────────────────────────────────── */

const files = readdirSync(PLANS_DIR)
  .filter((n) => n.endsWith('.html') && n !== 'index.html')
  .sort();

let rendered = 0;
const skipped = [];
const contentChanged = [];

for (const name of files) {
  const path = join(PLANS_DIR, name);
  const before = readFileSync(path, 'utf8');
  const mdPath = join(PLANS_DIR, `${basename(name, '.html')}.md`);
  const fromSpec = existsSync(mdPath);

  let spec;
  let expected;
  try {
    if (fromSpec) {
      spec = parseSpecMarkdown(readFileSync(mdPath, 'utf8'));
      expected = spec.sections;
    } else {
      const sections = extractSections(before);
      const metadata = Object.fromEntries(
        META_KEYS.map((k) => [k, metaTag(before, k)]).filter(([, v]) => v)
      );
      const glance = glanceOf(before);
      if (glance) metadata.glance = glance;
      spec = { metadata, sections, progress: progressOf(before), nextSteps: extractNextSteps(before) };
      expected = sections;
    }
  } catch (err) {
    skipped.push([name, `unreadable: ${err.message}`]);
    continue;
  }

  let after;
  try {
    after = renderPlanHtml(spec, {
      fileName: name,
      planPath: `${PLANS_DIR}/${name}`,
      repo: spec.metadata.repo || 'agentics',
      today: spec.metadata.created,
    });
  } catch (err) {
    skipped.push([name, `render failed: ${err.message}`]);
    continue;
  }

  /* Guard 1 — the spec the page carries must be unchanged. */
  try {
    assert.deepEqual(extractSections(after), expected);
  } catch {
    skipped.push([name, 'the re-rendered page extracts to a different spec']);
    continue;
  }

  /* Guard 2 — no meta tag the gallery reads may CHANGE value.
     Gaining one is allowed and reported: the oldest plans were rendered
     before `plan-effort` and `plan-issue` existed, and the current renderer
     always emits effort (deriving it from step and file counts when the spec
     declares none). Refusing that would mean never re-rendering them. */
  const overwritten = META_KEYS.filter(
    (k) => metaTag(before, k) && metaTag(before, k) !== metaTag(after, k)
  );
  if (overwritten.length && !fromSpec) {
    skipped.push([name, `meta tag(s) would change value: ${overwritten.join(', ')}`]);
    continue;
  }
  const gained = META_KEYS.filter((k) => !metaTag(before, k) && metaTag(after, k));
  if (gained.length) contentChanged.push([name, `gained meta tag(s): ${gained.join(', ')}`]);
  if (fromSpec) {
    if (overwritten.length) {
      contentChanged.push([name, `spec is newer than the HTML: ${overwritten.join(', ')}`]);
    }
    try {
      assert.deepEqual(extractSections(before), expected);
    } catch {
      contentChanged.push([name, 'committed HTML had drifted from its .md spec']);
    }
  }

  if (!dryRun && after !== before) writeFileSync(path, after);
  rendered += 1;
}

console.log(`${dryRun ? '[dry run] ' : ''}re-rendered ${rendered} of ${files.length} plans`);
if (contentChanged.length) {
  console.log(`\ncontent changed (spec-backed, spec wins) — ${contentChanged.length}:`);
  for (const [n, why] of contentChanged) console.log(`  ${n}: ${why}`);
}
if (skipped.length) {
  console.log(`\nleft untouched — ${skipped.length}:`);
  for (const [n, why] of skipped) console.log(`  ${n}: ${why}`);
}
