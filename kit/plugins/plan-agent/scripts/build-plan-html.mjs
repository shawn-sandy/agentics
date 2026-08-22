#!/usr/bin/env node
/**
 * build-plan-html.mjs — render a Markdown plan spec into a full styled HTML
 * plan (Phase 1 of the guideline-driven plan generation proposal).
 *
 * The write-side twin of extract-plan-spec.mjs: parseSpecMarkdown() (in
 * ./lib/plan-spec.mjs) reads the spec, this renderer stamps it through the
 * presentation shell (./lib/plan-shell.mjs) into the exact DOM contract the
 * extractor, finalize-plan, and the plans gallery depend on. The round-trip
 * property — extractSections(render(spec)) deep-equals the spec's sections —
 * is enforced by tests/plugins/test-build-plan-html.mjs.
 *
 * Everything derivable is derived, never authored: the implement/goal/
 * workflow prompts, the effort level, the file-tree markup, the criteria
 * count, and the sidebar nav (filtered to the sections present).
 *
 * Optional spec frontmatter (all keys optional):
 *   status | type | created | repo | effort | glance | workflow (true/false)
 *   prototype (repo-relative path to the plan's prototype HTML — renders the
 *   plan-prototype meta tag and the header "View prototype" link)
 *   design (the published design canvas's artifact URL — renders the
 *   plan-design meta tag and the header "View design" link)
 *   design-dir (repo-relative directory holding the plan's .dc.html artboards
 *   — read by the build skill and the drift hook, not rendered)
 *
 * Progress state travels in the spec too (Phase 3 of the proposal): `- [x]`
 * acceptance-criteria bullets render as checked inputs, a `[x]` marker after
 * a step number renders the completed step card (chip flips to done), and an
 * optional `## Completion Report` section fills the report block. The
 * completion checklist (cc1–cc3, all-complete) is derived from those plus
 * the status — tools flip state in the Markdown and re-render instead of
 * editing HTML attributes.
 *
 * `--check` verifies instead of writing (see runCheck below): the rendered
 * HTML on disk must be byte-identical to a fresh render, and a spec claiming
 * `status: completed` must actually carry `[x]` on every step and `- [x]` on
 * every criterion. It replaces the DOM-selector inspection the build skill's
 * completion gate used to prescribe — that gate named CSS selectors with no
 * way to evaluate them, so it was reached with `Grep` against the source
 * markup and reported drift that was not there.
 *
 * Usage: node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>] [--check]
 * Exit:  0 on success; 1 on missing/unparseable input or a failed --check;
 *        2 on misuse.
 */

import { execFileSync } from 'node:child_process';
import { readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { basename, posix, relative, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

import { parseSpecMarkdown, ParseError } from './lib/plan-spec.mjs';
import * as shell from './lib/plan-shell.mjs';

/** HTML-escape for both text and attribute contexts. */
export function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * esc() plus the three inline Markdown markers plan prose actually uses:
 * `code`, **bold**, *italic*. Without this every backtick and asterisk an
 * author wrote reached the page as a literal character — 85 of the 95 plans
 * in docs/plans/ rendered 3,000+ code spans as raw markdown.
 *
 * The `class="md"` on each emitted tag is load-bearing, not decoration: it is
 * what remark() in ./lib/plan-spec.mjs keys off to turn these spans back into
 * markers on extraction. Bare <code> is also emitted for file-tree leaves and
 * the implement/goal/workflow prompts, and those must NOT gain backticks when
 * read back. This function and remark() are a matched pair — the same split
 * paragraphs() and blockTextOf() already live on — so changing one marker
 * means changing both, and the round-trip test is what catches forgetting.
 *
 * Code spans are lifted out FIRST, behind a NUL sentinel, so a doubled-star
 * glob inside backticks can never be read as bold. UTF-8 can encode NUL, so
 * the sentinel is only unforgeable once the input's own NULs are dropped —
 * hence the strip on the way in. Dropping beats escaping-and-restoring: NUL
 * is not meaningful content in plan prose, so normalizing it away is safer
 * than carrying it through two passes. A softer delimiter would not do —
 * spaces around a bare index would turn "in 5 minutes" into a code span.
 *
 * Italic needs real flanking rules, not just a character blacklist. Bare
 * globs are common in plan prose, and a star attached to a word (the star in
 * product-reviewer-*.md) would otherwise pair with the star of the NEXT glob,
 * swallowing everything between them into one <em> — a 569-character span in
 * one committed plan, which the round-trip test could not see because
 * remark() faithfully restores both stars. So: the opening star must follow
 * whitespace or an opening bracket, the closing star must precede whitespace
 * or sentence punctuation, and the span may not begin or end with whitespace
 * or contain a slash. Bold needs none of this — its doubled delimiter makes
 * accidental pairing vanishingly rare, and real plans do use multi-word bold.
 *
 * Fenced blocks, links, and lists are deliberately not handled: no plan uses
 * them inside prose, and each would need its own inverse.
 */
export function inline(s) {
  const spans = [];
  const clean = String(s).replace(/\u0000/g, '');
  return esc(clean.replace(/`([^`]+)`/g, (_, c) => `\u0000${spans.push(c) - 1}\u0000`))
    .replace(/\*\*([^*]+)\*\*/g, '<strong class="md">$1</strong>')
    .replace(/(^|[\s([—])\*([^*/\s](?:[^*/]*[^*/\s])?)\*(?=$|[\s.,;:!?)\]—])/g, '$1<em class="md">$2</em>')
    .replace(/\u0000(\d+)\u0000/g, (_, i) => `<code class="md">${esc(spans[i])}</code>`);
}

/** Multi-paragraph block text → <p>/<br> markup that blockTextOf inverts. */
function paragraphs(text, indent = '      ') {
  return text
    .split('\n\n')
    // No newline after <br>: blockTextOf maps <br> to \n and would keep a
    // literal newline too, doubling every single line break on re-extraction.
    .map((p) => `${indent}<p>${inline(p).replace(/\n/g, '<br>')}</p>`)
    .join('\n');
}

/**
 * Effort buckets — same thresholds the implementation-plan skill mandates
 * (SKILL.md Step 2): Low ≤3 steps AND ≤2 distinct files; High ≥7 steps OR
 * ≥6 distinct files; Medium in between.
 */
export function deriveEffort(stepCount, fileCount) {
  if (stepCount >= 7 || fileCount >= 6) return 'high';
  if (stepCount <= 3 && fileCount <= 2) return 'low';
  return 'medium';
}

const FILE_BADGES = new Set(['new', 'modified', 'deleted', 'generated']);

/**
 * File-tree rows. Consecutive files sharing a directory render as a
 * .file-dir group with basename leaves — but only when the entry after the
 * run starts a path containing "/" (or the run is last): the extractor's
 * currentDir only resets on a slashed path, so a bare root file straight
 * after a group would be mis-joined on re-extraction.
 */
function fileTreeRows(files) {
  const dirOf = (p) => {
    const i = p.lastIndexOf('/');
    return i === -1 ? '' : p.slice(0, i);
  };
  const leafLi = (f, label, pad) => {
    const badge = FILE_BADGES.has(f.badge) ? f.badge : 'modified';
    const note = f.note ? ` <span class="file-note">${inline(f.note)}</span>` : '';
    return `${pad}<li><code>${esc(label)}</code> <span class="file-badge file-badge-${badge}">${badge}</span>${note}</li>`;
  };
  const rows = [];
  let i = 0;
  while (i < files.length) {
    const dir = dirOf(files[i].path);
    let j = i;
    while (j < files.length && dirOf(files[j].path) === dir) j += 1;
    const next = files[j];
    const cleanLeaves = files.slice(i, j).every((f) => /^[^\s/][^/]*$/.test(f.path.slice(dir.length + 1)));
    if (dir !== '' && j - i >= 2 && cleanLeaves && (!next || next.path.includes('/'))) {
      const leaves = files
        .slice(i, j)
        .map((f) => leafLi(f, f.path.slice(dir.length + 1), '            '))
        .join('\n');
      rows.push(
        `          <li class="file-dir"><svg class="icon" aria-hidden="true"><use href="#ic-folder"/></svg> ${esc(dir)}/
            <ul class="file-list">
${leaves}
            </ul>
          </li>`
      );
      i = j;
    } else {
      rows.push(leafLi(files[i], files[i].path, '          '));
      i += 1;
    }
  }
  return rows.join('\n');
}

function testsBody(tests) {
  if (tests.entries.length > 0) {
    const parts = [];
    if (tests.tier) parts.push(`      <div class="test-tier-label">${inline(tests.tier)}</div>`);
    parts.push(`      <div class="objective-test-card">${inline(tests.entries[0])}</div>`);
    if (tests.entries.length > 1) {
      const cards = tests.entries
        .slice(1)
        .map((e) => `        <div class="test-card">${inline(e)}</div>`)
        .join('\n');
      parts.push(`      <div class="test-list">\n${cards}\n      </div>`);
    }
    return parts.join('\n');
  }
  return paragraphs(tests.prose);
}

/**
 * Step cards in flat document order, wrapped in a .phase-group per
 * `### Phase:` heading. Every card stays a DESCENDANT of .steps-list, which is
 * what keeps `querySelectorAll('.step-card')` — the progress bar and the
 * completion checklist both read it — matching the full set.
 *
 * Steps outside any phase (a plan that starts phasing partway through) render
 * bare, exactly as they do today.
 */
function stepsBody(cards, phases) {
  const wrap = (blocks) => `      <div class="steps-list">\n\n${blocks.join('\n\n')}\n\n      </div>`;
  if (!phases || phases.length === 0) return wrap(cards);
  const blocks = [];
  let i = 0;
  for (const p of phases) {
    while (i < p.firstStep - 1) {
      blocks.push(cards[i]);
      i += 1;
    }
    blocks.push(shell.phaseGroup({
      name: esc(p.name),
      heading: inline(p.name),
      body: cards.slice(p.firstStep - 1, p.lastStep).join('\n\n'),
    }));
    i = p.lastStep;
  }
  while (i < cards.length) {
    blocks.push(cards[i]);
    i += 1;
  }
  return wrap(blocks);
}

/** `## Completion Report` entries → the dl.report-list markup finalize-plan
 * used to write by hand; replaces the default report-empty paragraph. */
function reportList(entries) {
  const rows = entries
    .map((e) => `            <dt>${inline(e.item)}</dt>\n            <dd>${inline(e.reason)}</dd>`)
    .join('\n');
  return `          <dl class="report-list">\n${rows}\n          </dl>`;
}

/**
 * Render a parsed spec ({ metadata, sections, progress, nextSteps }) to the
 * full HTML document. `fileName`/`planPath` locate the output for the source
 * rows; `mdPath` locates the Markdown spec — the implement/goal/workflow
 * prompts reference IT (a spec is ~10× smaller than the rendered HTML, and
 * progress updates are spec edits), falling back to `planPath` with `.html`
 * swapped for `.md`. `progress` (optional) carries per-step/per-criterion
 * done state and completion-report entries; omitted state renders as not
 * done. `nextSteps` (optional) renders as the collapsible Next Steps cards.
 */
/**
 * Enumerated frontmatter keys and their accepted values.
 *
 * `workflow: auto` is the heuristic — the state that used to be spelled by
 * omitting the key entirely, which left it unnamed and therefore untypeable.
 * `true`/`false` are the pre-7.0 spelling of `always`/`never` and stay
 * accepted so every committed spec keeps rendering.
 */
const ENUMS = {
  status: ['todo', 'in-progress', 'completed'],
  type: ['feature', 'fix', 'refactor', 'docs', 'chore'],
  effort: ['low', 'medium', 'high'],
  workflow: ['auto', 'always', 'never', 'true', 'false'],
};

/**
 * Read an enumerated key. Absent takes the caller's default; present but
 * unrecognized is a spec error.
 *
 * These keys used to fall back silently, which turned every near-miss into a
 * plan that rendered as something the author did not write: `status: complete`
 * rendered as `todo`, `workflow: yes` meant "no workflow", and `type:` took
 * any string at all and became a phantom filter chip in the gallery. Refusing
 * unknown input is an interface constraint, not a constraint on judgment —
 * a typo is not a decision to respect.
 *
 * Only an absent key defaults. `status:` with nothing after it is a present
 * key with an empty value — a half-finished edit or a template that never got
 * filled in, which is exactly the mistake worth catching, not a request for
 * the default.
 *
 * The frontmatter parser keeps everything after the colon, so a YAML inline
 * comment lands inside the value. That was harmless while these keys fell
 * back; once they became strict it turned `status: todo  # todo | ...` into a
 * hard error, and every enum line in the authoring docs is written that way.
 * Enum values are single tokens and can never contain `#`, so strip the
 * comment here rather than making hand-authored YAML illegal.
 */
function enumValue(md, key, fallback) {
  const raw = md[key];
  if (raw === undefined) return fallback;
  const value = raw.replace(/\s+#.*$/, '').trim();
  if (!ENUMS[key].includes(value)) {
    const shown = value === '' ? '(empty)' : raw;
    throw new ParseError(`${key}: ${shown} — expected one of ${ENUMS[key].join(', ')}`);
  }
  return value;
}

export function renderPlanHtml({ metadata = {}, sections, progress, nextSteps }, { fileName, planPath, mdPath, today, repo } = {}) {
  const md = metadata;
  const s = sections;
  const stepsDone = (progress && progress.steps) || [];
  const criteriaDone = (progress && progress.criteria) || [];
  const report = (progress && progress.report) || [];

  const status = enumValue(md, 'status', 'todo');
  const type = enumValue(md, 'type', 'feature');
  const created = md.created || today || new Date().toISOString().slice(0, 10);
  const repoName = md.repo || repo || 'repo';
  const file = fileName || 'plan.html';
  const path = planPath || file;

  const fileCount = new Set((s.files || []).map((f) => f.path)).size;
  const effort = enumValue(md, 'effort', null) || deriveEffort(s.steps.length, fileCount);
  const effortLabel = effort[0].toUpperCase() + effort.slice(1);

  const specPath = mdPath || (/\.html$/i.test(path) ? path.replace(/\.html$/i, '.md') : `${path}.md`);

  // `prototype:` is a repo-relative target (docs/prototypes/<slug>.html), but
  // the link is read from the rendered plan's own directory — which is not
  // always docs/plans/, since plansDirectory is configurable and can nest.
  // Relativize against the output dir rather than hard-coding ../prototypes/.
  const prototype = md.prototype || '';
  const prototypeHref = prototype
    ? posix.relative(posix.dirname(path.replace(/\\/g, '/')), prototype.replace(/\\/g, '/')) || basename(prototype)
    : '';

  // `issue:` is the tracking ticket's full URL — written by Step 0.5 when the
  // plan was seeded from an issue, or by Step 8 when one is created for it.
  // Rendered as a header link so the plan and its ticket stay reachable from
  // each other, and as a meta tag so the closing agent can find it.
  // Only http(s) is navigable. Escaping leaves a scheme intact, so a plan
  // carrying `issue: javascript:...` — imported, or hand-edited — would render
  // as an ordinary-looking anchor that runs on click. Drop anything else, tag
  // and link both: an unusable value is worse than an absent one.
  const issueRaw = (md.issue || '').trim();
  const issue = /^https?:\/\//i.test(issueRaw) ? issueRaw : '';
  if (issueRaw && !issue) console.warn(`  ! ${basename(path)}: ignoring non-http(s) issue: ${issueRaw}`);
  const issueNum = (issue.match(/(\d+)\/?$/) || [, ''])[1];
  const issueLabel = issueNum ? `Issue #${issueNum}` : 'Tracking issue';

  // `design:` is the published design canvas's artifact URL, written by
  // /plan-agent:design once the canvas exists. Rendered as a header link and a
  // meta tag so the plan and the picture of it stay reachable from each other.
  //
  // Modelled on `issue:` above, deliberately NOT on `prototype:`: a prototype
  // is a repo path that has to be relativized against the output directory,
  // while a canvas lives at a URL and must be emitted verbatim. Same http(s)
  // guard for the same reason — escaping leaves a scheme intact, so a spec
  // carrying `design: javascript:...` would otherwise render as an
  // ordinary-looking anchor that runs on click. Drop anything else, tag and
  // link both.
  //
  // `design-dir:` is deliberately NOT rendered. It names a local artboard
  // directory read by the `build` skill and by check-design-drift.py, both of
  // which read the Markdown spec directly; a meta tag would be a second copy
  // of a fact with no consumer.
  const designRaw = (md.design || '').trim();
  const design = /^https?:\/\//i.test(designRaw) ? designRaw : '';
  if (designRaw && !design) console.warn(`  ! ${basename(path)}: ignoring non-http(s) design: ${designRaw}`);

  // Every prompt ends with the same gate: verify, then record the outcome in
  // the spec. Without it an agent reports "done" on a plan still marked todo.
  //
  // The *check* clause is compressed — naming the three spec sections beats
  // spelling out how to walk each one. The *record* clause is not: it stays
  // explicit about `[x]` markers, `- [x]` criteria, and the re-render.
  //
  // Both were cut in 7.0.0 and both had to come back. The tick mechanics are
  // not "visible in the spec the agent has open" — an unfinished spec carries
  // bare numbered steps and bullets, so there is no `[x]` to copy, and the
  // rendered progress bar and step chips derive from those markers. And the
  // re-render is not reliably automatic: hooks.json does register
  // render-plan-html.py on PostToolUse writes, but editing a plan spec through
  // the Edit tool was observed leaving the sibling HTML untouched, so dropping
  // the instruction left the gallery stale. Only copyCmd() rebuilds a richer
  // prompt from live DOM; copyGoal()/copyWorkflow() copy this string verbatim,
  // so whatever is missing here is missing on two of the three paths.
  const verifyTail = `Verify against the plan's Tests, Verification, and Acceptance Criteria before reporting done. If everything passed, mark completion in ${specPath} — tick each step's [x] marker and each criterion's - [x], set status: completed — and re-render the HTML from the spec. If any check failed, leave status: in-progress and say which.`;

  // A root-level path has no directory segment, so bucket every one of them
  // under a single sentinel — otherwise each bare filename counts as its own
  // directory and four files in the repo root satisfy the 2-directory half of
  // the heuristic on their own.
  const dirCount = new Set((s.files || []).map((f) => (f.path.includes('/') ? f.path.split('/')[0] : ''))).size;
  const workflowMode = enumValue(md, 'workflow', 'auto');
  const wantsWorkflow = workflowMode === 'always' || workflowMode === 'true'
    || (workflowMode === 'auto' && fileCount >= 4 && dirCount >= 2);

  const implement = `Read and implement all steps in the plan at ${specPath} — ${s.title}. ${verifyTail}`;
  // Same gate as the workflow row: a plan too small to show that row must not
  // license fan-out the page never offers. Trailing license, not a leading
  // directive — "Run a workflow to achieve this goal" would fix the
  // decomposition before the agent is allowed to conclude the plan's
  // decomposition is wrong, which is the one freedom a goal prompt exists to
  // grant. Stated after the latitude, parallelism is a choice the outcome
  // licenses rather than a method chosen for the agent up front.
  const fanOut = wantsWorkflow ? ' Fan out across parallel subagents where that serves the outcome.' : '';
  const goal = `Achieve this goal: ${s.title}. The plan at ${specPath} describes one approach — use it as reference, but optimize for the outcome.${fanOut} ${verifyTail}`;
  const workflow = wantsWorkflow
    ? `Run a workflow to implement the plan at ${specPath} — ${s.title}. Brief subagents with the plan file at ${specPath}. Reserve a final verification phase for the lead agent, not a subagent. ${verifyTail}`
    : '';

  const main = [];
  // One goal panel: the glance is nested inside #objective, not stacked
  // beside it. extractSections() strips it back out of the objective.
  main.push(shell.objectiveCard(inline(s.objective), md.glance ? shell.glanceBlock(inline(md.glance)) : ''));
  main.push('', shell.implementRow(esc(implement)));
  main.push('', shell.moreWaysDrawer({
    goal: esc(goal),
    workflow: esc(workflow),
    file: esc(file),
    path: esc(path),
    md: esc(specPath),
  }));
  const criteriaDoneCount = s.criteria.filter((_, i) => Boolean(criteriaDone[i])).length;
  main.push('', shell.progressBlock(criteriaDoneCount, s.criteria.length));
  if (s.context) main.push('', shell.sectionCard('context', paragraphs(s.context)));
  if (s.decisions) main.push('', shell.sectionCard('decisions', shell.decisionsListBlock(s.decisions.map(inline))));
  if (s.files) main.push('', shell.sectionCard('files', shell.fileTreeBlock(esc(repoName), fileTreeRows(s.files))));
  const stepCards = s.steps
    .map((st, i) => shell.stepCard(i + 1, { action: inline(st.action), why: inline(st.why), verify: inline(st.verify), done: Boolean(stepsDone[i]) }));
  main.push('', shell.sectionCard('steps', stepsBody(stepCards, s.phases)));
  if (s.tests) main.push('', shell.sectionCard('tests', testsBody(s.tests)));
  main.push('', shell.sectionCard('criteria', shell.criteriaListBlock(s.criteria.map((c, i) => ({ text: inline(c), done: Boolean(criteriaDone[i]) })))));
  main.push('', shell.sectionCard('verification', paragraphs(s.verification)));
  main.push('', shell.sectionCard('completion', shell.completionBlock({
    allStepsDone: s.steps.length > 0 && s.steps.every((_, i) => Boolean(stepsDone[i])),
    allCriteriaDone: s.criteria.length > 0 && criteriaDoneCount === s.criteria.length,
    statusCompleted: status === 'completed',
    reportHtml: report.length > 0 ? reportList(report) : '',
  })));
  if (nextSteps) {
    const parts = [];
    if (nextSteps.prose) parts.push(paragraphs(nextSteps.prose));
    if (nextSteps.items.length > 0) {
      parts.push(shell.nextStepsBlock(nextSteps.items.map((it) => ({
        summary: inline(it.summary),
        desc: it.desc ? inline(it.desc) : '',
        // Verbatim: the prompt renders in a <pre> for the reader to copy and
        // paste into Claude. Markers there are content, not formatting.
        prompt: it.prompt ? esc(it.prompt) : '',
      }))));
    }
    main.push('', shell.sectionCard('next-steps', parts.join('\n')));
  }
  main.push('', shell.footer({ created: esc(created), repo: esc(repoName) }));

  const navIds = shell.NAV_ENTRIES.map((e) => e.id).filter((id) => {
    if (id === 'context') return Boolean(s.context);
    if (id === 'decisions') return Boolean(s.decisions);
    if (id === 'files') return Boolean(s.files);
    if (id === 'tests') return Boolean(s.tests);
    if (id === 'next-steps') return Boolean(nextSteps);
    return true;
  });

  return shell.page({
    status: esc(status),
    effort: esc(effort),
    title: esc(s.title),
    meta: shell.metaTags({
      status: esc(status),
      effort: esc(effort),
      type: esc(type),
      created: esc(created),
      repo: esc(repoName),
      file: esc(file),
      path: esc(path),
      md: esc(specPath),
      implement: esc(implement),
      goal: esc(goal),
      workflow: esc(workflow),
      prototype: prototype ? esc(prototype) : '',
      issue: issue ? esc(issue) : '',
      design: design ? esc(design) : '',
    }),
    headerHtml: shell.header({
      title: esc(s.title),
      status: esc(status),
      effortLabel: esc(effortLabel),
      created: esc(created),
      repo: esc(repoName),
      type: esc(type),
      prototypeHref: prototypeHref ? esc(prototypeHref) : '',
      issueHref: issue ? esc(issue) : '',
      issueLabel: esc(issueLabel),
      designHref: design ? esc(design) : '',
    }),
    // The rail links to #step-N; the action text is the same inline-rendered
    // HTML the card carries, so a step titled with `code` reads the same in
    // both places.
    navHtml: shell.nav(navIds, s.steps.map((st, i) => ({
      action: inline(st.action),
      done: Boolean(stepsDone[i]),
    }))),
    mainHtml: main.join('\n'),
  });
}

/* ── --check ──────────────────────────────────────────────────────── */

/** Row labels, in the order runCheck() always prints them. */
export const CHECK_ROWS = ['html', 'steps', 'criteria'];

const WINDOW = 40;
const LEAD = 10;

/**
 * First line at which two renderings diverge, with a WINDOW-character view of
 * each side anchored LEAD characters before the first differing column.
 *
 * Anchoring is the point. A plan's longest lines are the plan-implement and
 * plan-goal meta tags — several hundred characters of near-identical prompt
 * text — so two windows taken from column 0 would print the same 40 characters
 * twice and show the reader nothing. Returns null when the strings match.
 */
export function firstDiff(onDisk, rendered) {
  const a = onDisk.split('\n');
  const b = rendered.split('\n');
  for (let i = 0; i < Math.max(a.length, b.length); i += 1) {
    if (a[i] === b[i]) continue;
    // A file that simply ends early has no line here; '' makes the window
    // render as (empty) rather than throwing on undefined.
    const la = a[i] === undefined ? '' : a[i];
    const lb = b[i] === undefined ? '' : b[i];
    let col = 0;
    while (col < la.length && col < lb.length && la[col] === lb[col]) col += 1;
    const from = Math.max(0, col - LEAD);
    const view = (s) => {
      if (s === '') return '(no line — file ends here)';
      const head = from > 0 ? '…' : '';
      const tail = s.length > from + WINDOW ? '…' : '';
      return `${head}${s.slice(from, from + WINDOW)}${tail}`;
    };
    return { line: i + 1, column: col + 1, onDisk: view(la), rendered: view(lb) };
  }
  return null;
}

/**
 * The half of the old gate that never needed the HTML at all: whether a spec
 * claiming to be finished actually is. Evaluated on the parsed Markdown, and
 * skipped outright below `completed` — a todo plan with unchecked steps is
 * correct, not inconsistent.
 */
export function checkSpecConsistency(parsed) {
  const status = enumValue(parsed.metadata || {}, 'status', 'todo');
  if (status !== 'completed') {
    const note = `status: ${status} — consistency is asserted only for completed`;
    return { steps: { state: 'SKIP', detail: note }, criteria: { state: 'SKIP', detail: note } };
  }
  const steps = (parsed.sections && parsed.sections.steps) || [];
  const criteria = (parsed.sections && parsed.sections.criteria) || [];
  const stepsDone = (parsed.progress && parsed.progress.steps) || [];
  const criteriaDone = (parsed.progress && parsed.progress.criteria) || [];
  const openStep = steps.findIndex((_, i) => !stepsDone[i]);
  const openCriterion = criteria.findIndex((_, i) => !criteriaDone[i]);
  return {
    steps: openStep === -1
      ? { state: 'PASS', detail: `${steps.length}/${steps.length} steps marked [x]` }
      : { state: 'FAIL', detail: `step ${openStep + 1} is not marked [x]: "${steps[openStep].action}"` },
    criteria: openCriterion === -1
      ? { state: 'PASS', detail: `${criteria.length}/${criteria.length} criteria marked - [x]` }
      : { state: 'FAIL', detail: `criterion ${openCriterion + 1} is not marked - [x]: "${criteria[openCriterion]}"` },
  };
}

/** Freshness: the file on disk versus what this spec renders to right now. */
function checkHtmlFreshness(specPath, outPath, rendered) {
  let onDisk;
  try {
    onDisk = readFileSync(outPath, 'utf8');
  } catch {
    // Not a crash and not a diff — there is nothing to compare. Name the
    // command that fixes it, because "missing" without a remedy is what sends
    // a reader back to inspecting markup by hand.
    return {
      state: 'FAIL',
      detail: `${outPath} does not exist — run: plan-agent-render "${specPath}" -o "${outPath}"`,
    };
  }
  const d = firstDiff(onDisk, rendered);
  if (d === null) return { state: 'PASS', detail: `${outPath} matches a fresh render` };
  return {
    state: 'FAIL',
    detail: `${outPath} is stale — first difference at line ${d.line}, column ${d.column}`,
    lines: [`on disk:  ${d.onDisk}`, `rendered: ${d.rendered}`],
  };
}

/**
 * Print the fixed three-row table and return the process exit code. Rows are
 * always emitted in CHECK_ROWS order whatever the outcome, so a reader (and
 * the test) can find the property that broke without parsing prose. Writes
 * nothing to disk — that is the whole contract of --check.
 */
export function runCheck({ specPath, outPath, parsed, rendered, log = console.log }) {
  const rows = { html: checkHtmlFreshness(specPath, outPath, rendered), ...checkSpecConsistency(parsed) };
  log(`plan-agent-render --check ${specPath}`);
  for (const name of CHECK_ROWS) {
    const row = rows[name];
    log(`  ${name.padEnd(8)} ${row.state}  ${row.detail}`);
    for (const extra of row.lines || []) log(`             ${extra}`);
  }
  const tally = (state) => CHECK_ROWS.filter((n) => rows[n].state === state).length;
  const failed = tally('FAIL');
  log(`check: ${failed === 0 ? 'PASS' : 'FAIL'} (${tally('PASS')} passed, ${tally('SKIP')} skipped, ${failed} failed)`);
  if (failed > 0) log('Fix the spec and re-render. Never hand-edit the HTML.');
  return failed === 0 ? 0 : 1;
}

function defaultRepo() {
  try {
    const url = execFileSync('git', ['config', '--get', 'remote.origin.url'], { stdio: ['ignore', 'pipe', 'ignore'] })
      .toString()
      .trim();
    if (url) return url.replace(/\/+$/, '').split('/').pop().replace(/\.git$/, '');
  } catch {
    /* no git or no remote — fall through */
  }
  return basename(process.cwd());
}

function main() {
  const args = process.argv.slice(2);
  let specPath = null;
  let outPath = null;
  let check = false;
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '-o' || args[i] === '--output') {
      outPath = args[i + 1];
      i += 1;
    } else if (args[i] === '--check') {
      check = true;
    } else if (!specPath) {
      specPath = args[i];
    } else {
      specPath = null;
      break;
    }
  }
  if (!specPath || (outPath !== null && !outPath)) {
    console.error('Usage: node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>] [--check]');
    process.exit(2);
  }
  if (!outPath) outPath = specPath.replace(/\.md$/, '') + '.html';
  if (resolve(outPath) === resolve(specPath)) {
    console.error('build-plan-html: output path must differ from the input spec');
    process.exit(2);
  }

  let md;
  try {
    md = readFileSync(specPath, 'utf8');
  } catch (err) {
    console.error(`build-plan-html: cannot read ${specPath}: ${err.message}`);
    process.exit(1);
  }

  let parsed;
  try {
    parsed = parseSpecMarkdown(md);
  } catch (err) {
    if (err instanceof ParseError) {
      console.error(`build-plan-html: ${specPath} is not a valid plan spec: ${err.message}`);
      console.error('A spec needs "# Plan: <title>" plus ## Objective, ## Steps (numbered, with Why:/Verify:), ## Acceptance Criteria, and ## Verification.');
      process.exit(1);
    }
    throw err;
  }

  // Keep plan-created stable across re-renders: when the spec's frontmatter
  // omits `created`, reuse the existing sibling HTML's value instead of
  // stamping the wall clock on every regeneration.
  let created = parsed.metadata.created || null;
  if (!created) {
    try {
      const prev = readFileSync(outPath, 'utf8').match(/<meta name="plan-created" content="([^"]+)">/);
      if (prev) created = prev[1];
    } catch {
      /* no existing sibling — fall through to today */
    }
  }

  let html;
  try {
    html = renderPlanHtml(parsed, {
      fileName: basename(outPath),
      planPath: parsed.metadata.path || relative(process.cwd(), resolve(outPath)),
      mdPath: relative(process.cwd(), resolve(specPath)),
      repo: defaultRepo(),
      today: created || undefined,
    });
  } catch (err) {
    // Enumerated frontmatter is validated during render, so its errors surface
    // here rather than from parseSpecMarkdown above.
    if (err instanceof ParseError) {
      console.error(`build-plan-html: ${specPath} has invalid frontmatter — ${err.message}`);
      process.exit(1);
    }
    throw err;
  }
  // --check verifies and writes nothing. The render above is the comparison
  // baseline, and it went through the identical code path — including the
  // plan-created read-back — so a spec with no `created:` frontmatter does not
  // fail the check merely for having been rendered on an earlier day.
  if (check) {
    process.exit(runCheck({ specPath, outPath, parsed, rendered: html }));
  }

  writeFileSync(outPath, html);
  console.log(`build-plan-html: wrote ${outPath} (${html.length} bytes)`);
}

// realpath the argv entry: node resolves the entry module to its real path,
// so a symlinked scripts/ dir (e.g. a consumer project linking this repo)
// would otherwise never match and the CLI would silently do nothing.
const entry = (() => {
  try {
    return process.argv[1] ? pathToFileURL(realpathSync(process.argv[1])).href : null;
  } catch {
    return null;
  }
})();
if (entry === import.meta.url) {
  main();
}
