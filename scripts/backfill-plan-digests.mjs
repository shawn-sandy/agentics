#!/usr/bin/env node
/**
 * backfill-plan-digests.mjs — inject a spec-only markdown digest
 * (<script type="text/markdown" id="plan-digest">) into existing HTML plans
 * that lack one.
 *
 * Contract (see kit/plugins/plan-agent/skills/implementation-plan/SKILL.md,
 * "Machine-Readable Digest"):
 *   - The digest is the authored spec only: title, objective, context, files,
 *     steps (action/why/verify), tests, acceptance criteria, verification.
 *   - Status, checkbox, and progress state are never written into the digest,
 *     and no other byte of the plan is modified (insertion-only).
 *   - Literal closing-script sequences in content are guarded as <\/script>.
 *   - Idempotent: plans that already have a digest are skipped.
 *   - No partial digests: a plan is only injected when every expected section
 *     parses; otherwise it is skipped and reported with a reason.
 *
 * Usage: node scripts/backfill-plan-digests.mjs [--dry-run] [--dir <path>]
 *   --dry-run   report what would happen without writing any file
 *   --dir       plans directory (default: docs/plans relative to repo root)
 */

import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const DEFAULT_DIR = join(fileURLToPath(new URL('..', import.meta.url)), 'docs', 'plans');

// Matches only a real opening tag — a quoted one-liner containing the literal
// text "[^>]*" cannot match because the character class forbids ">".
const DIGEST_OPEN_RE = /<script[^>]*id="plan-digest"/;

export function hasDigest(html) {
  return DIGEST_OPEN_RE.test(html);
}

export function decodeEntities(s) {
  // Out-of-range numeric entities (e.g. &#x110000;) must not throw — a
  // RangeError here is not a ParseError, so it would abort the whole
  // backfill batch instead of skipping one file. Keep the raw entity text.
  const codePoint = (raw, n) => (Number.isInteger(n) && n >= 0 && n <= 0x10ffff ? String.fromCodePoint(n) : raw);
  return s
    .replace(/&#x([0-9a-fA-F]+);/g, (m, h) => codePoint(m, parseInt(h, 16)))
    .replace(/&#(\d+);/g, (m, d) => codePoint(m, parseInt(d, 10)))
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&');
}

/** Strip tags and collapse whitespace to a single line of plain text. */
export function textOf(html) {
  const noSvg = html.replace(/<svg[\s\S]*?<\/svg>/gi, ' ');
  const noTags = noSvg.replace(/<[^>]+>/g, ' ');
  return decodeEntities(noTags).replace(/\s+/g, ' ').trim();
}

/** Strip tags but keep paragraph boundaries as blank lines. */
export function blockTextOf(html) {
  const noSvg = html.replace(/<svg[\s\S]*?<\/svg>/gi, ' ');
  const withBreaks = noSvg.replace(/<\/(p|li|ul|ol|dl|dd)>/gi, '\n\n').replace(/<br\s*\/?>/gi, '\n');
  const noTags = withBreaks.replace(/<[^>]+>/g, ' ');
  const decoded = decodeEntities(noTags);
  return decoded
    .split('\n')
    .map((l) => l.replace(/[ \t]+/g, ' ').trim())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/** Guard literal closing-script sequences so they cannot end the digest block. */
export function guardScriptClose(s) {
  return s.replace(/<\/(script)/gi, '<\\/$1');
}

/**
 * From the opening tag that starts at `openIdx`, return the inner HTML of
 * that element by tracking same-tag-name nesting depth.
 */
function sliceBalanced(html, openIdx, tagName) {
  const openEnd = html.indexOf('>', openIdx);
  if (openEnd === -1) return null;
  const re = new RegExp(`<${tagName}\\b[^>]*>|</${tagName}>`, 'gi');
  re.lastIndex = openEnd + 1;
  let depth = 1;
  let m;
  while ((m = re.exec(html)) !== null) {
    depth += m[0][1] === '/' ? -1 : 1;
    if (depth === 0) return html.slice(openEnd + 1, m.index);
  }
  return null;
}

/** Find an element by a marker inside its opening tag and slice its inner HTML. */
function innerByMarker(html, marker, tagName) {
  const at = html.indexOf(marker);
  if (at === -1) return null;
  const openIdx = html.lastIndexOf('<', at);
  if (openIdx === -1) return null;
  return sliceBalanced(html, openIdx, tagName);
}

/** All inner-HTML slices for elements whose opening tag contains `marker`. */
function allInnerByMarker(html, marker, tagName) {
  const out = [];
  let from = 0;
  for (;;) {
    const at = html.indexOf(marker, from);
    if (at === -1) break;
    const openIdx = html.lastIndexOf('<', at);
    const inner = openIdx === -1 ? null : sliceBalanced(html, openIdx, tagName);
    if (inner !== null) out.push(inner);
    from = at + marker.length;
  }
  return out;
}

/** All inner-HTML slices for elements whose opening tag matches `openTagRe`. */
function allInnerByRe(html, openTagRe, tagName) {
  const out = [];
  const re = new RegExp(openTagRe.source, 'g');
  let m;
  while ((m = re.exec(html)) !== null) {
    const inner = sliceBalanced(html, m.index, tagName);
    if (inner !== null) out.push(inner);
  }
  return out;
}

class ParseError extends Error {}

/**
 * Extract the spec sections from a plan's HTML.
 * Required: title, objective, steps (each with action/why/verify),
 * acceptance criteria, verification. Optional when absent: context, files,
 * tests — but if their anchor exists and yields nothing, that is a parse
 * failure (no partial digests).
 */
export function extractSections(html) {
  const fail = (reason) => {
    throw new ParseError(reason);
  };

  const titleMatch = html.match(/<title>\s*(?:Plan:\s*)?([\s\S]*?)<\/title>/i);
  if (!titleMatch || !textOf(titleMatch[1])) fail('no <title>');
  const title = textOf(titleMatch[1]);

  const objectiveInner = innerByMarker(html, 'id="objective"', 'div');
  if (objectiveInner === null) fail('no objective element (id="objective")');
  const objective = textOf(objectiveInner.replace(/<div class="section-label">[\s\S]*?<\/div>/i, ' '));
  if (!objective) fail('objective is empty');

  const stripHeading = (inner) => inner.replace(/<h2\b[\s\S]*?<\/h2>/i, ' ');

  let context = null;
  const contextInner = innerByMarker(html, 'id="context"', 'section');
  if (contextInner !== null) {
    context = blockTextOf(stripHeading(contextInner));
    if (!context) fail('context section present but empty');
  }

  let files = null;
  const filesInner = innerByMarker(html, 'class="file-tree"', 'div');
  if (filesInner !== null) {
    files = [];
    let currentDir = null;
    // Two generations exist: directory <li class="file-dir"> followed by a
    // sibling <ul> of <code>-wrapped leaves, and an older one nesting the
    // <ul> inside the directory <li> with bare-text leaves. Chunking on each
    // <li> opening and reading only the chunk head (text before any nested
    // list or close) handles both.
    const chunks = filesInner.split(/(?=<li\b)/).slice(1);
    for (const chunk of chunks) {
      const tagEnd = chunk.indexOf('>');
      if (tagEnd === -1) continue;
      const attrs = chunk.slice(0, tagEnd);
      let head = chunk.slice(tagEnd + 1);
      const ulAt = head.indexOf('<ul');
      if (ulAt !== -1) head = head.slice(0, ulAt);
      const liClose = head.indexOf('</li>');
      if (liClose !== -1) head = head.slice(0, liClose);
      if (/file-dir/.test(attrs)) {
        currentDir = textOf(head);
        continue;
      }
      const noteInner = innerByMarker(head, 'class="file-note"', 'span');
      const note = noteInner === null ? '' : textOf(noteInner);
      const badge = head.match(/file-badge-(new|modified|deleted|generated)/);
      const code = head.match(/<code>([\s\S]*?)<\/code>/i);
      let path = code
        ? textOf(code[1])
        : textOf(head.replace(/<span\b[\s\S]*?<\/span>/gi, ' '));
      if (!path) continue;
      if (path.includes('/')) currentDir = null;
      else if (currentDir) path = currentDir.replace(/\/?$/, '/') + path;
      files.push({ path, badge: badge ? badge[1] : 'modified', note });
    }
    if (files.length === 0) fail('file-tree present but no file entries parsed');
  }

  const stepsInner = innerByMarker(html, 'id="steps"', 'section');
  if (stepsInner === null) fail('no steps section (id="steps")');
  // Match class="step-card" and class="step-card completed" but never
  // class="step-card-header" — the [" ] after the name excludes the hyphen.
  const stepCards = allInnerByRe(stepsInner, /<div\b[^>]*class="step-card[" ][^>]*>/, 'div');
  if (stepCards.length === 0) fail('steps section has no step cards');
  const steps = stepCards.map((card, i) => {
    const n = i + 1;
    let action = null;
    const chipText = innerByMarker(card, 'class="step-chip-text"', 'span');
    if (chipText !== null) {
      action = textOf(chipText);
    } else {
      const actionDiv = innerByMarker(card, 'class="step-action"', 'div');
      if (actionDiv !== null) action = textOf(actionDiv).replace(/^(todo|done)\s+/i, '');
    }
    if (!action) throw new ParseError(`step ${n} has no action text`);
    const whyInner = innerByMarker(card, 'class="step-why"', 'div');
    if (whyInner === null || !textOf(whyInner)) throw new ParseError(`step ${n} has no why text`);
    const verifyInner = innerByMarker(card, 'class="verify-body"', 'div');
    if (verifyInner === null || !textOf(verifyInner)) throw new ParseError(`step ${n} has no verify text`);
    return { action, why: textOf(whyInner), verify: textOf(verifyInner) };
  });

  let tests = null;
  const testsInner = innerByMarker(html, 'id="tests"', 'section');
  if (testsInner !== null) {
    const tierInner = innerByMarker(testsInner, 'class="test-tier-label"', 'div');
    const objectiveCard = innerByMarker(testsInner, 'class="objective-test-card"', 'div');
    const cards = allInnerByMarker(testsInner, 'class="test-card"', 'div');
    tests = {
      tier: tierInner === null ? null : textOf(tierInner),
      entries: [],
      prose: null,
    };
    if (objectiveCard !== null) tests.entries.push(textOf(objectiveCard));
    for (const card of cards) tests.entries.push(textOf(card));
    if (tests.entries.length === 0) {
      // Older generation: prose tests with no card markup — keep the whole
      // section text rather than dropping the plan.
      tests.prose = blockTextOf(stripHeading(testsInner));
      if (!tests.prose) fail('tests section present but no test cards or prose parsed');
    }
  }

  const criteriaInner = innerByMarker(html, 'id="criteria-list"', 'ul');
  if (criteriaInner === null) fail('no acceptance criteria list (id="criteria-list")');
  const criteria = [];
  const labelRe = /<label\b[^>]*>([\s\S]*?)<\/label>/gi;
  let label;
  while ((label = labelRe.exec(criteriaInner)) !== null) {
    const text = textOf(label[1]);
    if (text) criteria.push(text);
  }
  if (criteria.length === 0) fail('acceptance criteria list has no labelled items');

  const verificationInner = innerByMarker(html, 'id="verification"', 'section');
  if (verificationInner === null) fail('no verification section (id="verification")');
  const verification = blockTextOf(stripHeading(verificationInner));
  if (!verification) fail('verification section is empty');

  return { title, objective, context, files, steps, tests, criteria, verification };
}

/** Render the spec sections as the digest's markdown body (guarded). */
export function buildDigest(sections) {
  const lines = [];
  lines.push(`# Plan: ${sections.title}`);
  lines.push('');
  lines.push('> Authored spec only. Status and progress live in the <head> meta tags and');
  lines.push('> the live DOM, never in this block.');
  lines.push('');
  lines.push('## Objective');
  lines.push(sections.objective);
  if (sections.context) {
    lines.push('');
    lines.push('## Context');
    lines.push(sections.context);
  }
  if (sections.files && sections.files.length > 0) {
    lines.push('');
    lines.push('## Files');
    for (const f of sections.files) {
      lines.push(`- ${f.path} (${f.badge})${f.note ? ` — ${f.note}` : ''}`);
    }
  }
  lines.push('');
  lines.push('## Steps');
  sections.steps.forEach((s, i) => {
    lines.push(`${i + 1}. ${s.action} Why: ${s.why} Verify: ${s.verify}`);
  });
  if (sections.tests && (sections.tests.entries.length > 0 || sections.tests.prose)) {
    lines.push('');
    lines.push('## Tests');
    if (sections.tests.tier) lines.push(sections.tests.tier);
    for (const entry of sections.tests.entries) lines.push(`- ${entry}`);
    if (sections.tests.entries.length === 0 && sections.tests.prose) lines.push(sections.tests.prose);
  }
  lines.push('');
  lines.push('## Acceptance Criteria');
  for (const c of sections.criteria) lines.push(`- ${c}`);
  lines.push('');
  lines.push('## Verification');
  lines.push(sections.verification);
  return guardScriptClose(lines.join('\n'));
}

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
    '     Extract (first-match flag-and-exit):',
    `       awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\\/script>/{exit} f' <file>`,
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
