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

/**
 * Turn the inline-Markdown spans back into their source markers. The exact
 * left-inverse of inline() in ../build-plan-html.mjs — the two are a matched
 * pair, and the render → extract → render fidelity test is what catches a
 * change to one that is missing from the other.
 *
 * Keyed on class="md" rather than the tag name because bare <code> carries
 * file-tree leaves and the implement/goal/workflow prompts. Those are already
 * plain text in the spec and must not acquire backticks on the way back.
 *
 * Runs before tag stripping, so the markers survive into the extracted text.
 */
const remark = (html) =>
  html
    .replace(/<code class="md">([\s\S]*?)<\/code>/gi, '`$1`')
    .replace(/<(strong|em) class="md">([\s\S]*?)<\/\1>/gi, (_, tag, body) => (tag.toLowerCase() === 'strong' ? `**${body}**` : `*${body}*`));

/** Strip tags and collapse whitespace to a single line of plain text. */
export function textOf(html) {
  const noSvg = remark(html.replace(/<svg[\s\S]*?<\/svg>/gi, ' '));
  const noTags = noSvg.replace(/<[^>]+>/g, ' ');
  return decodeEntities(noTags).replace(/\s+/g, ' ').trim();
}

/** Strip tags but keep paragraph boundaries as blank lines. */
export function blockTextOf(html) {
  const noSvg = remark(html.replace(/<svg[\s\S]*?<\/svg>/gi, ' '));
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

/**
 * The fence run opening or closing a code block, or null for a normal line.
 * CommonMark: a run closes only on the same character at >= the opening
 * length, so a Next Steps prompt quoting its own ```yaml block needs a longer
 * outer fence (````text) to survive — a naive open/closed toggle ends the
 * prompt at the inner fence and leaks its tail into the card description.
 */
const fenceRun = (line) => {
  const m = line.match(/^\s*(`{3,}|~{3,})/);
  return m ? m[1] : null;
};

/** Fold a fence run into the currently-open fence; null means "outside". */
const fenceStep = (open, run) => {
  if (open === null) return run;
  return run[0] === open[0] && run.length >= open.length ? null : open;
};

/** Longest backtick fence run inside `s` — 0 when it holds no fences. */
const longestFenceRun = (s) =>
  (String(s).match(/^\s*`{3,}/gm) || []).reduce((n, m) => Math.max(n, m.trim().length), 0);

// Humanized skeletons (plan-agent >= 2.17.0) place a one-line
// <p class="section-intro"> under each section heading. Intro copy is
// presentation-only chrome — strip it so extracted spec text stays pure.
// Attribute-agnostic on purpose: generated plans may add ids/classes to
// the intro <p>, and a missed match silently pollutes the spec.
const stripIntro = (inner) =>
  inner.replace(/<p\b[^>]*class="[^"]*\bsection-intro\b[^"]*"[^>]*>[\s\S]*?<\/p>/gi, ' ');

const stripHeading = (inner) => inner.replace(/<h2\b[\s\S]*?<\/h2>/i, ' ');

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

  const objectiveInner = innerByMarker(html, 'id="objective"', 'div');
  if (objectiveInner === null) fail('no objective element (id="objective")');
  // Defense against the one placement error the skill warns about: a
  // .plan-glance block mistakenly nested inside #objective must not leak
  // into the extracted objective.
  const stripGlance = (inner) =>
    inner.replace(/<section\b[^>]*class="[^"]*\bplan-glance\b[^"]*"[^>]*>[\s\S]*?<\/section>/gi, ' ');
  const objective = textOf(stripGlance(stripIntro(objectiveInner)).replace(/<div class="section-label">[\s\S]*?<\/div>/i, ' '));
  if (!objective) fail('objective is empty');

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

/**
 * Extract the Next Steps cards from a plan's HTML — the read-side twin of
 * plan-shell's nextStepsBlock(), and the reason a plan recovered from HTML
 * keeps its follow-ups. Returns the shape parseSpecMarkdown() puts on
 * `nextSteps` ({ items: [{ summary, desc, prompt }], prose }), or null when
 * the section is absent.
 *
 * Kept separate from extractSections() because nextSteps lives BESIDE
 * `sections` on the parse result — folding it in would break the
 * extract → digest → parse byte-stability the round-trip test asserts.
 */
export function extractNextSteps(html) {
  const sectionInner = innerByMarker(html, 'id="next-steps"', 'section');
  if (sectionInner === null) return null;

  const items = [];
  const listInner = innerByMarker(sectionInner, 'class="next-steps-list"', 'div');
  if (listInner !== null) {
    // Token match, not an exact-string marker: a wish-list card renders
    // class="next-step-item wish-item" (see plan-shell.mjs's .wish-item
    // styling), and an exact '"next-step-item"' marker misses every one of
    // those — the same [" ] pattern the step-card matcher above already uses.
    for (const card of allInnerByRe(listInner, /<details\b[^>]*class="next-step-item[" ][^>]*>/, 'details')) {
      const summaryInner = innerByMarker(card, '<summary', 'summary');
      const summary = summaryInner === null ? '' : textOf(summaryInner);
      if (!summary) continue;
      // <pre> holds the prompt verbatim — decode entities but keep newlines
      // and indentation, unlike textOf()'s single-line collapse. No tag
      // stripping: nextStepsBlock() escapes the prompt, so a renderer-built
      // card carries no markup here, and the one thing a regex strip would
      // find in a legacy hand-written card is placeholder text like
      // `<owner>/<repo>` that must survive into the spec.
      const preInner = innerByMarker(card, '<pre', 'pre');
      const prompt = preInner === null ? null : decodeEntities(preInner).replace(/\s+$/, '');
      const bodyInner = innerByMarker(card, 'class="next-step-prompt"', 'div') || '';
      const desc = blockTextOf(
        bodyInner
          .replace(/<p\b[^>]*>Paste this prompt into Claude[\s\S]*?<\/p>/i, ' ')
          .replace(/<pre\b[\s\S]*?<\/pre>/gi, ' ')
          .replace(/<button\b[\s\S]*?<\/button>/gi, ' '),
      );
      // A promptless card echoes its summary as the body; re-emitting that
      // would grow a duplicate description line on every round trip.
      items.push({ summary, desc: desc && desc !== summary ? desc : '', prompt });
    }
  }

  // Bullet-less prose renders as plain paragraphs above the card list.
  const prose = blockTextOf(
    stripIntro(stripHeading(sectionInner)).replace(/<div\b[^>]*class="[^"]*\bnext-steps-list\b[\s\S]*/i, ' '),
  );
  if (items.length === 0 && !prose) return null;
  return { items, prose: prose || null };
}

/**
 * Parse a Markdown plan spec back into the sections object extractSections()
 * returns — the exact inverse of buildDigest(). Accepts an optional YAML-ish
 * frontmatter block (`key: value` lines only) whose fields are returned
 * separately as `metadata`; the digest's blockquote preamble is skipped.
 *
 * Returns { metadata, sections, progress, nextSteps }. Throws ParseError when a required
 * section (title, Objective, Steps, Acceptance Criteria, Verification) is
 * missing or malformed; optional sections (Context, Files, Tests) come back
 * null when absent, matching extractSections().
 *
 * `progress` carries completion state, kept out of `sections` so the
 * content round-trip (extract → digest → parse) stays byte-stable:
 *   - steps:    boolean per step, from an optional `[ ]`/`[x]` marker after
 *               the step number (`3. [x] Do the thing. Why: … Verify: …`);
 *   - criteria: boolean per criterion, from optional `- [ ]`/`- [x]` bullets
 *               in Acceptance Criteria (plain `- ` bullets parse as not done);
 *   - report:   entries from an optional `## Completion Report` section,
 *               one `- <item> — <reason>` bullet each, rendered into the
 *               #completion-report block (absent section → the default
 *               "No items to report" sentence).
 *
 * `nextSteps` carries an optional `## Next Steps` section, also kept out of
 * `sections` for round-trip stability: `{ items: [{ summary, desc, prompt }],
 * prose }` where each top-level `- ` bullet is an item (first line = summary,
 * first fenced code block = paste-ready prompt, other lines = desc) and
 * bullet-less content lands in `prose`. Null when the section is absent.
 */
export function parseSpecMarkdown(md) {
  const fail = (reason) => {
    throw new ParseError(reason);
  };
  // Input is CLEAN spec markdown — the format extract-plan-spec.mjs prints
  // and authors write. A still-guarded digest must be un-guarded by the
  // caller first (guarding is deliberately non-injective, so doing it here
  // would corrupt spec text that legitimately contains a guarded sequence).
  let body = String(md).replace(/\r\n/g, '\n');

  const metadata = {};
  const fm = body.match(/^---\n([\s\S]*?)\n---\n?/);
  if (fm) {
    for (const line of fm[1].split('\n')) {
      const kv = line.match(/^([A-Za-z][\w-]*):\s*(.*)$/);
      if (kv) metadata[kv[1]] = kv[2].trim().replace(/^["']|["']$/g, '');
    }
    body = body.slice(fm[0].length);
  }

  // Line scan for the title and "## " section headings, masking fenced code
  // blocks so a spec whose prose quotes markdown (e.g. a ```text example
  // containing "## Context") is not chopped at the quoted heading.
  let titleText = null;
  const marks = [];
  let openFence = null;
  let offset = 0;
  for (const line of body.split('\n')) {
    const run = fenceRun(line);
    if (run) {
      openFence = fenceStep(openFence, run);
    } else if (openFence === null) {
      if (titleText === null) {
        const t = line.match(/^#\s+(?:Plan:\s*)?(.+)$/);
        if (t) titleText = t[1];
      }
      const h = line.match(/^##\s+(.+)$/);
      if (h) marks.push({ name: h[1].trim(), start: offset, end: offset + line.length });
    }
    offset += line.length + 1;
  }
  if (titleText === null || !titleText.trim()) fail('no "# Plan: <title>" heading');
  const title = titleText.replace(/\s+/g, ' ').trim();

  // Text before the first heading (the title line and the digest's
  // "> Authored spec only…" blockquote) is discarded.
  const chunks = {};
  marks.forEach((mark, i) => {
    const next = i + 1 < marks.length ? marks[i + 1].start : body.length;
    chunks[mark.name] = body.slice(mark.end, next);
  });

  // blockTextOf-style normalization: single-line collapse for inline values,
  // trimmed lines + collapsed blank runs for block values.
  const inline = (s) => s.replace(/\s+/g, ' ').trim();
  const block = (s) =>
    s
      .split('\n')
      .map((l) => l.replace(/[ \t]+/g, ' ').trim())
      .join('\n')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  const listItems = (s) =>
    s
      .split(/\n(?=- )/)
      .map((l) => l.trim())
      .filter((l) => l.startsWith('- '))
      .map((l) => inline(l.slice(2)));

  if (!('Objective' in chunks)) fail('no "## Objective" section');
  const objective = inline(chunks.Objective);
  if (!objective) fail('objective is empty');

  let context = null;
  if ('Context' in chunks) {
    context = block(chunks.Context);
    if (!context) fail('Context section present but empty');
  }

  let files = null;
  if ('Files' in chunks) {
    files = [];
    for (const item of listItems(chunks.Files)) {
      // Greedy path: badge is the LAST "(badge)" token before the optional
      // " — note", so paths containing spaces or parenthesised text survive.
      const fmatch = item.match(/^(.+)\s+\((new|modified|deleted|generated)\)(?:\s+—\s+(.*))?$/);
      if (!fmatch) fail(`unparseable Files entry: "${item}"`);
      files.push({ path: fmatch[1], badge: fmatch[2], note: fmatch[3] || '' });
    }
    if (files.length === 0) fail('Files section present but no entries');
  }

  // Optional checkbox marker carrying done-state; strip it before content
  // parsing so `sections` stays pure and return the flag separately.
  const takeCheckbox = (s) => {
    const box = s.match(/^\[([ xX])\]\s+/);
    return box ? { text: s.slice(box[0].length), done: box[1] !== ' ' } : { text: s, done: false };
  };

  if (!('Steps' in chunks)) fail('no "## Steps" section');
  const steps = [];
  const stepsDone = [];
  // Numbered items may wrap across lines in hand-written specs; fold
  // continuations into the item before splitting on the Why:/Verify: markers.
  const stepLines = chunks.Steps.split(/\n(?=\d+\.\s)/);
  for (const raw of stepLines) {
    const item = inline(raw);
    const numbered = item.match(/^\d+\.\s+(.*)$/);
    if (!numbered) continue;
    const { text: stepText, done: stepDone } = takeCheckbox(numbered[1]);
    const parts = stepText.match(/^(.*?)\s+Why:\s+(.*?)\s+Verify:\s+(.*)$/);
    if (!parts) fail(`step ${steps.length + 1} is missing its "Why:" or "Verify:" part`);
    const [action, why, verify] = parts.slice(1).map((p) => p.trim());
    // An empty part would render HTML that extractSections() rejects — fail
    // here, at authoring time, instead of breaking the round trip later.
    if (!action || !why || !verify) fail(`step ${steps.length + 1} has an empty action, "Why:", or "Verify:" part`);
    steps.push({ action, why, verify });
    stepsDone.push(stepDone);
  }
  if (steps.length === 0) fail('Steps section has no numbered steps');

  let tests = null;
  if ('Tests' in chunks) {
    const entries = listItems(chunks.Tests);
    const bare = block(chunks.Tests.split(/\n- /)[0]);
    if (entries.length > 0) {
      // buildDigest emits the tier as the only bare line above the entries.
      tests = { tier: bare ? inline(bare) : null, entries, prose: null };
    } else {
      // ponytail: tier-with-prose never occurs in committed plans (verified
      // over docs/plans/); if it ever does, fold the tier into prose here.
      const prose = block(chunks.Tests);
      if (!prose) fail('Tests section present but empty');
      tests = { tier: null, entries: [], prose };
    }
  }

  if (!('Acceptance Criteria' in chunks)) fail('no "## Acceptance Criteria" section');
  const criteria = [];
  const criteriaDone = [];
  for (const item of listItems(chunks['Acceptance Criteria'])) {
    const { text, done } = takeCheckbox(item);
    if (!text) fail(`acceptance criterion ${criteria.length + 1} is empty`);
    criteria.push(text);
    criteriaDone.push(done);
  }
  if (criteria.length === 0) fail('Acceptance Criteria section has no items');

  if (!('Verification' in chunks)) fail('no "## Verification" section');
  const verification = block(chunks.Verification);
  if (!verification) fail('Verification section is empty');

  // Optional `## Next Steps` — follow-ups rendered as collapsible cards with
  // paste-ready prompts. Items are top-level `- ` bullets: the bullet's first
  // line is the summary, an indented fenced code block inside the item is the
  // prompt, and any other indented lines are description prose. Bullet-less
  // content falls back to prose. Returned BESIDE `sections` (like `progress`)
  // so the extract → digest → parse round trip stays byte-stable.
  // `Out of Scope` is the other heading authors reach for; both used to be
  // matched case-sensitively against "Next Steps", so anything else was
  // silently discarded — a clean exit with the follow-ups missing.
  let nextSteps = null;
  const nsKey = Object.keys(chunks).find((k) => /^(?:next steps|out of scope)\b/i.test(k));
  if (nsKey !== undefined) {
    const text = chunks[nsKey].replace(/^\n+|\n+$/g, '');
    if (!text.trim()) fail('Next Steps section present but empty');
    // Split into top-level bullets, masking fenced blocks so a prompt line
    // that happens to start with "- " never starts a new item.
    const rawItems = [];
    const loose = [];
    let buf = null;
    let splitFence = null;
    for (const line of text.split('\n')) {
      if (splitFence === null && /^- /.test(line)) {
        buf = [line.slice(2)];
        rawItems.push(buf);
        continue;
      }
      const run = fenceRun(line);
      if (run) splitFence = fenceStep(splitFence, run);
      (buf || loose).push(line);
    }
    const items = rawItems.map((itemLines, i) => {
      const summary = inline(itemLines[0]);
      if (!summary) fail(`Next Steps item ${i + 1} has no summary line`);
      const descLines = [];
      const promptLines = [];
      let openFence = null;
      let promptDone = false;
      for (const line of itemLines.slice(1)) {
        const run = fenceRun(line);
        if (run) {
          const wasOpen = openFence !== null;
          const next = fenceStep(openFence, run);
          // A run too short to close the open fence is nested content (a
          // ```yaml block inside a ````text prompt) — keep the marker.
          if (wasOpen && next !== null) {
            (promptDone ? descLines : promptLines).push(line);
            continue;
          }
          openFence = next;
          if (wasOpen && next === null) promptDone = true;
          continue;
        }
        // Only the first fenced block is the prompt; later blocks keep their
        // text but lose the fence, as they always have.
        if (openFence !== null && !promptDone) promptLines.push(line);
        else descLines.push(line);
      }
      let prompt = null;
      if (promptLines.length > 0) {
        const indents = promptLines.filter((l) => l.trim()).map((l) => l.match(/^\s*/)[0].length);
        const cut = indents.length ? Math.min(...indents) : 0;
        prompt = promptLines.map((l) => l.slice(cut)).join('\n').replace(/\s+$/, '');
      }
      return { summary, desc: block(descLines.join('\n')), prompt };
    });
    const prose = block(loose.join('\n'));
    nextSteps = { items, prose: prose || null };
  }

  const report = [];
  if ('Completion Report' in chunks) {
    for (const item of listItems(chunks['Completion Report'])) {
      // Same em-dash separator the Files section uses: `- <item> — <reason>`.
      const rmatch = item.match(/^(.+?)\s+—\s+(.+)$/);
      if (!rmatch) fail(`unparseable Completion Report entry: "${item}" (want "- <item> — <reason>")`);
      report.push({ item: rmatch[1], reason: rmatch[2] });
    }
    if (report.length === 0) fail('Completion Report section present but no entries');
  }

  return {
    metadata,
    sections: { title, objective, context, files, steps, tests, criteria, verification },
    progress: { steps: stepsDone, criteria: criteriaDone, report },
    nextSteps,
  };
}

/**
 * The `## Next Steps` block as an array of markdown lines, leading blank line
 * included — `[]` when there is nothing to render. Factored out of
 * buildDigest() so resolveSpec() (extract-plan-spec.mjs) can splice
 * DOM-recovered follow-ups onto a legacy embedded digest that predates Next
 * Steps support, rather than only ever reaching this via a full sections
 * object.
 */
export function nextStepsMarkdown(nextSteps) {
  if (!nextSteps || (nextSteps.items.length === 0 && !nextSteps.prose)) return [];
  const lines = ['', '## Next Steps'];
  if (nextSteps.prose) lines.push(nextSteps.prose);
  const indent = (s) => s.split('\n').map((l) => (l ? `  ${l}` : ''));
  for (const it of nextSteps.items) {
    lines.push(`- ${it.summary}`);
    if (it.desc) lines.push(...indent(it.desc));
    if (it.prompt) {
      // Outrun any fence the prompt itself contains, so re-parsing the
      // digest reads the whole prompt back rather than stopping inside it.
      const fence = '`'.repeat(Math.max(3, longestFenceRun(it.prompt) + 1));
      lines.push(`  ${fence}text`);
      lines.push(...indent(it.prompt));
      lines.push(`  ${fence}`);
    }
  }
  return lines;
}

/**
 * Render the spec sections as the digest's markdown body (guarded).
 * `nextSteps` is optional and takes the parse-result shape — pass it (from
 * extractNextSteps()) or the follow-up cards vanish on the HTML round trip.
 */
export function buildDigest(sections, nextSteps = null) {
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
  lines.push(...nextStepsMarkdown(nextSteps));
  return guardScriptClose(lines.join('\n'));
}
