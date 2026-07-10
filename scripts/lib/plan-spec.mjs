/**
 * plan-spec.mjs — shared parse/build helpers for the plan spec.
 *
 * One library, two consumers:
 *   - write-side: scripts/backfill-plan-digests.mjs injects an embedded
 *     #plan-digest into legacy plans (guarded, for safe embedding);
 *   - read-side: scripts/extract-plan-spec.mjs derives the spec on demand,
 *     embedded-first then DOM-derive, and UN-guards for clean output.
 *
 * The visible plan DOM (.objective-card, .step-card, #criteria-list,
 * #verification, …) is the single source of truth. buildDigest renders that
 * spec as markdown; extractSections reads it back out of the HTML. The only
 * embedding concern that leaks into this layer is the closing-script guard:
 * guardScriptClose for writing into a <script> block, unguardScriptClose for
 * reading it back out.
 */

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

/** Guard literal closing-script sequences so they cannot end a digest block. */
export function guardScriptClose(s) {
  return s.replace(/<\/(script)/gi, '<\\/$1');
}

/** Reverse guardScriptClose: turn guarded <\/script back into a real tag. */
export function unguardScriptClose(s) {
  return s.replace(/<\\\/(script)/gi, '</$1');
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

export class ParseError extends Error {}

/**
 * Read an embedded #plan-digest block (legacy plans) and return its markdown
 * UN-guarded — a real </script> in place of the stored <\/script guard — so
 * the output is clean spec markdown, not the raw embedded bytes. Returns null
 * when no real digest tag is present. Locating the tag with DIGEST_OPEN_RE
 * (not a naive indexOf) skips the awk one-liner that the guiding comment and
 * older Copy-button JS quote before the real block.
 */
export function readEmbeddedDigest(html) {
  const open = DIGEST_OPEN_RE.exec(html);
  if (!open) return null;
  const openEnd = html.indexOf('>', open.index);
  if (openEnd === -1) return null;
  // Stop at the first UNGUARDED closing tag; guarded <\/script has a backslash
  // and so cannot match '</script>'.
  const close = html.indexOf('</script>', openEnd + 1);
  if (close === -1) return null;
  return unguardScriptClose(html.slice(openEnd + 1, close)).trim();
}

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

  // Humanized skeletons (plan-agent >= 2.17.0) place a one-line
  // <p class="section-intro"> under each section heading. Intro copy is
  // presentation-only chrome — strip it so extracted spec text stays pure.
  const stripIntro = (inner) => inner.replace(/<p class="section-intro">[\s\S]*?<\/p>/gi, ' ');

  const objectiveInner = innerByMarker(html, 'id="objective"', 'div');
  if (objectiveInner === null) fail('no objective element (id="objective")');
  const objective = textOf(stripIntro(objectiveInner).replace(/<div class="section-label">[\s\S]*?<\/div>/i, ' '));
  if (!objective) fail('objective is empty');

  const stripHeading = (inner) => inner.replace(/<h2\b[\s\S]*?<\/h2>/i, ' ');

  let context = null;
  const contextInner = innerByMarker(html, 'id="context"', 'section');
  if (contextInner !== null) {
    context = blockTextOf(stripIntro(stripHeading(contextInner)));
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
      tests.prose = blockTextOf(stripIntro(stripHeading(testsInner)));
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
  const verification = blockTextOf(stripIntro(stripHeading(verificationInner)));
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
