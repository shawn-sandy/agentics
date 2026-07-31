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
 *
 * Progress state travels in the spec too (Phase 3 of the proposal): `- [x]`
 * acceptance-criteria bullets render as checked inputs, a `[x]` marker after
 * a step number renders the completed step card (chip flips to done), and an
 * optional `## Completion Report` section fills the report block. The
 * completion checklist (cc1–cc3, all-complete) is derived from those plus
 * the status — tools flip state in the Markdown and re-render instead of
 * editing HTML attributes.
 *
 * Usage: node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>]
 * Exit:  0 on success; 1 on missing/unparseable input; 2 on misuse.
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
  if (s.files) main.push('', shell.sectionCard('files', shell.fileTreeBlock(esc(repoName), fileTreeRows(s.files))));
  const stepCards = s.steps
    .map((st, i) => shell.stepCard(i + 1, { action: inline(st.action), why: inline(st.why), verify: inline(st.verify), done: Boolean(stepsDone[i]) }))
    .join('\n\n');
  main.push('', shell.sectionCard('steps', `      <div class="steps-list">\n\n${stepCards}\n\n      </div>`));
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
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '-o' || args[i] === '--output') {
      outPath = args[i + 1];
      i += 1;
    } else if (!specPath) {
      specPath = args[i];
    } else {
      specPath = null;
      break;
    }
  }
  if (!specPath || (outPath !== null && !outPath)) {
    console.error('Usage: node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>]');
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
