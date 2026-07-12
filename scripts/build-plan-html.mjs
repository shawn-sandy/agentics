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
import { basename, relative, resolve } from 'node:path';
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

/** Multi-paragraph block text → <p>/<br> markup that blockTextOf inverts. */
function paragraphs(text, indent = '      ') {
  return text
    .split('\n\n')
    // No newline after <br>: blockTextOf maps <br> to \n and would keep a
    // literal newline too, doubling every single line break on re-extraction.
    .map((p) => `${indent}<p>${esc(p).replace(/\n/g, '<br>')}</p>`)
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
    const note = f.note ? ` <span class="file-note">${esc(f.note)}</span>` : '';
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
    if (tests.tier) parts.push(`      <div class="test-tier-label">${esc(tests.tier)}</div>`);
    parts.push(`      <div class="objective-test-card">${esc(tests.entries[0])}</div>`);
    if (tests.entries.length > 1) {
      const cards = tests.entries
        .slice(1)
        .map((e) => `        <div class="test-card">${esc(e)}</div>`)
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
    .map((e) => `            <dt>${esc(e.item)}</dt>\n            <dd>${esc(e.reason)}</dd>`)
    .join('\n');
  return `          <dl class="report-list">\n${rows}\n          </dl>`;
}

/**
 * Render a parsed spec ({ metadata, sections, progress }) to the full HTML
 * document. `fileName`/`planPath` locate the output for the source rows and
 * prompts. `progress` (optional) carries per-step/per-criterion done state
 * and completion-report entries; omitted state renders as not done.
 */
export function renderPlanHtml({ metadata = {}, sections, progress }, { fileName, planPath, today, repo } = {}) {
  const md = metadata;
  const s = sections;
  const stepsDone = (progress && progress.steps) || [];
  const criteriaDone = (progress && progress.criteria) || [];
  const report = (progress && progress.report) || [];

  const status = ['todo', 'in-progress', 'completed'].includes(md.status) ? md.status : 'todo';
  const type = md.type || 'feature';
  const created = md.created || today || new Date().toISOString().slice(0, 10);
  const repoName = md.repo || repo || 'repo';
  const file = fileName || 'plan.html';
  const path = planPath || file;

  const fileCount = new Set((s.files || []).map((f) => f.path)).size;
  const effort = ['low', 'medium', 'high'].includes(md.effort) ? md.effort : deriveEffort(s.steps.length, fileCount);
  const effortLabel = effort[0].toUpperCase() + effort.slice(1);

  const implement = `Read and implement all steps in the plan at ${path} — ${s.title}`;
  const goal = `Achieve this goal: ${s.title}. The plan at ${path} describes one approach — use it as reference, but optimize for the outcome`;
  const dirCount = new Set((s.files || []).map((f) => f.path.split('/')[0])).size;
  const wantsWorkflow = md.workflow === 'true' || (md.workflow !== 'false' && fileCount >= 5 && dirCount >= 3);
  const workflow = wantsWorkflow
    ? `Run a workflow to implement the plan at ${path} — ${s.title}. Brief subagents with the plan file at ${path}`
    : '';

  const main = [];
  main.push(shell.objectiveCard(esc(s.objective)));
  if (md.glance) main.push('', shell.glanceBlock(esc(md.glance)));
  main.push('', shell.implementRow(esc(implement)));
  main.push('', shell.moreWaysDrawer({
    goal: esc(goal),
    workflow: esc(workflow),
    file: esc(file),
    path: esc(path),
  }));
  const criteriaDoneCount = s.criteria.filter((_, i) => Boolean(criteriaDone[i])).length;
  main.push('', shell.progressBlock(criteriaDoneCount, s.criteria.length));
  if (s.context) main.push('', shell.sectionCard('context', paragraphs(s.context)));
  if (s.files) main.push('', shell.sectionCard('files', shell.fileTreeBlock(esc(repoName), fileTreeRows(s.files))));
  const stepCards = s.steps
    .map((st, i) => shell.stepCard(i + 1, { action: esc(st.action), why: esc(st.why), verify: esc(st.verify), done: Boolean(stepsDone[i]) }))
    .join('\n\n');
  main.push('', shell.sectionCard('steps', `      <div class="steps-list">\n\n${stepCards}\n\n      </div>`));
  if (s.tests) main.push('', shell.sectionCard('tests', testsBody(s.tests)));
  main.push('', shell.sectionCard('criteria', shell.criteriaListBlock(s.criteria.map((c, i) => ({ text: esc(c), done: Boolean(criteriaDone[i]) })))));
  main.push('', shell.sectionCard('verification', paragraphs(s.verification)));
  main.push('', shell.sectionCard('completion', shell.completionBlock({
    allStepsDone: s.steps.length > 0 && s.steps.every((_, i) => Boolean(stepsDone[i])),
    allCriteriaDone: s.criteria.length > 0 && criteriaDoneCount === s.criteria.length,
    statusCompleted: status === 'completed',
    reportHtml: report.length > 0 ? reportList(report) : '',
  })));
  main.push('', shell.footer({ created: esc(created), repo: esc(repoName) }));

  const navIds = shell.NAV_ENTRIES.map((e) => e.id).filter((id) => {
    if (id === 'context') return Boolean(s.context);
    if (id === 'files') return Boolean(s.files);
    if (id === 'tests') return Boolean(s.tests);
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
      implement: esc(implement),
      goal: esc(goal),
      workflow: esc(workflow),
    }),
    headerHtml: shell.header({
      title: esc(s.title),
      status: esc(status),
      effortLabel: esc(effortLabel),
      created: esc(created),
      repo: esc(repoName),
      type: esc(type),
    }),
    navHtml: shell.nav(navIds),
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

  const html = renderPlanHtml(parsed, {
    fileName: basename(outPath),
    planPath: parsed.metadata.path || relative(process.cwd(), resolve(outPath)),
    repo: defaultRepo(),
    today: created || undefined,
  });
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
