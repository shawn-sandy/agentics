// Static assertions for the review-plan Workflow engine
// (docs/plans/replace-review-team-with-workflow.html).
// Checks that kit/plugins/plan-agent/skills/review-plan/SKILL.md no longer
// gates on the Agent Teams feature flag, that it drives the Workflow tool
// instead, and that the shipped workflow script parses.
// Run: node tests/review-plan-workflow.test.mjs

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const REVIEW_PLAN = join(ROOT, 'kit', 'plugins', 'plan-agent', 'skills', 'review-plan');
const SKILL = join(REVIEW_PLAN, 'SKILL.md');
const SCRIPT = join(REVIEW_PLAN, 'references', 'review-workflow.mjs');
const ROLE_PROMPTS = join(REVIEW_PLAN, 'references', 'role-prompts.md');
const BG_AGENT = join(ROOT, 'kit', 'plugins', 'plan-agent', 'agents', 'agent-review-plan.md');

let pass = 0;
let fail = 0;

/**
 * Record a single assertion result, printing a PASS/FAIL line and
 * incrementing the matching counter for the final summary.
 *
 * @param {string} name - Human-readable description of the assertion.
 * @param {boolean} cond - Truthy when the assertion holds.
 */
function check(name, cond) {
  if (cond) {
    console.log(`PASS: ${name}`);
    pass++;
  } else {
    console.log(`FAIL: ${name}`);
    fail++;
  }
}

/**
 * Read the YAML frontmatter block from the top of a markdown file.
 * Returns an empty string when the file does not open with `---`, so a
 * caller's `.includes()` check fails rather than throwing.
 *
 * @param {string} text - Full file contents.
 * @returns {string} The frontmatter body, without its delimiters.
 */
function frontmatter(text) {
  if (!text.startsWith('---')) return '';
  const end = text.indexOf('\n---', 3);
  return end === -1 ? '' : text.slice(3, end);
}

const skill = existsSync(SKILL) ? readFileSync(SKILL, 'utf8') : '';

// ── The feature-flag gate is gone ──────────────────────────────────────────
// This is the objective. The whole point of the change is that a user with no
// experimental flag set can run a plan review, so any surviving mention of the
// env var means the gate is still somewhere in the workflow.

check('SKILL.md: no CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS gate remains',
  skill.length > 0 && !skill.includes('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'));

check('SKILL.md: no Agent Teams minimum-version stop remains',
  !/Agent Teams require Claude Code/i.test(skill));

// ── The Workflow tool is what replaced it ──────────────────────────────────

check('SKILL.md: lists Workflow in allowed-tools',
  /^allowed-tools:.*\bWorkflow\b/m.test(frontmatter(skill)));

// Asserted on the call's input names, not the bare word "Workflow" — the
// skill has always carried a "## Workflow" heading, so a substring check on
// the word alone passes before the change and can never fail.
check('SKILL.md: documents the Workflow call inputs (script + args)',
  /Workflow[^\n]*`?script`?|`script`[^\n]*Workflow/.test(skill) && /`args`/.test(skill));

check('SKILL.md: passes the script inline rather than by plugin-root path',
  skill.includes('review-workflow.mjs') && !skill.includes('${CLAUDE_PLUGIN_ROOT}'));

// ── The shipped script exists and parses ───────────────────────────────────
// A real parse, not a grep: a script with a syntax error throws at workflow
// launch with no useful message.
//
// It cannot be `node --check`. A workflow script is a hybrid the runtime
// builds, not a standard module: it carries module-level `export const meta`
// AND a top-level `return` that is only legal because the body is spliced
// into an async function. No single parser accepts both, and `node --check`
// rejects the return. So parse it the way the runtime does — strip the
// exports, hand the rest to the AsyncFunction constructor, which validates
// syntax (top-level await and return included) without executing a line.

const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;

/**
 * Parse a workflow script without running it.
 *
 * @param {string} source - Raw script contents.
 * @returns {{ok: boolean, error: string}} ok is false when syntax is invalid.
 */
function parsesAsWorkflowBody(source) {
  try {
    new AsyncFunction('args', 'agent', 'pipeline', 'parallel', 'log', 'phase', 'budget', 'workflow',
      source.replace(/^export /gm, ''));
    return { ok: true, error: '' };
  } catch (err) {
    return { ok: false, error: String(err) };
  }
}

check('references/review-workflow.mjs exists', existsSync(SCRIPT));

if (existsSync(SCRIPT)) {
  const script = readFileSync(SCRIPT, 'utf8');

  const parsed = parsesAsWorkflowBody(script);
  check('references/review-workflow.mjs parses as a workflow body', parsed.ok);
  if (!parsed.ok) console.log(`  ${parsed.error}`);

  // Guards the transform above: if the script ever stops carrying the two
  // hybrid features, the AsyncFunction parse is no longer the right check and
  // this test is quietly validating something weaker than it claims.
  check('script: is the hybrid shape the runtime splices (export + top-level return)',
    /^export const meta/m.test(script) && /^return \{/m.test(script));

  check('script: exports a meta block with both phases',
    /export const meta\s*=/.test(script)
    && script.includes("title: 'Review'")
    && script.includes("title: 'Verify'"));

  check('script: reuses the shipped reviewer agents via agentType',
    script.includes('agentType') && script.includes('plan-reviewer-'));

  check('script: pipelines review into verify rather than barriering',
    script.includes('pipeline('));

  // Severity filtering, --deep, and the unverified log are asserted
  // behaviourally below by running the script — a substring check on
  // 'critical'/'high'/'deep' passes on the schema enum and the comments alone,
  // so it stays green even if MUST_VERIFY or the flag wiring is broken.

  check('script: logs how many findings went unverified',
    /log\([^)]*unverified/i.test(script));

  check('script: avoids Date.now/Math.random, which throw in a workflow',
    !/Date\.now\(|Math\.random\(|new Date\(\)/.test(script));
}

// ── The orphaned reference file is gone ────────────────────────────────────
// agentType supplies each lens from the shipped agent definition, so the
// hand-written spawn prompts have no remaining caller.

check('references/role-prompts.md is deleted', !existsSync(ROLE_PROMPTS));

check('SKILL.md: no longer references role-prompts.md',
  !skill.includes('role-prompts'));

// ── The background agent can still reach the tool ──────────────────────────
// agent-review-plan invokes a skill that now calls Workflow. Without the grant
// the background path fails at runtime, which no prose assertion would catch.

const bgAgent = existsSync(BG_AGENT) ? readFileSync(BG_AGENT, 'utf8') : '';

check('agent-review-plan.md: grants the Workflow tool',
  /^tools:.*\bWorkflow\b/m.test(frontmatter(bgAgent)));

// ── Behavioural: run the script against a stubbed runtime ──────────────────
// The substring checks above cannot tell a working severity filter from a
// broken one — every keyword they look for also appears in the schema enum and
// the comments. These run the script instead, with stubs matching the
// documented runtime contract, and assert what actually comes back.

/**
 * Faithful stand-in for the runtime's `parallel`: a barrier that resolves a
 * rejected thunk to null rather than rejecting the whole call.
 *
 * @param {Array<() => Promise<any>>} thunks - Work to run concurrently.
 * @returns {Promise<any[]>} One slot per thunk; null where it rejected.
 */
const stubParallel = (thunks) =>
  Promise.all(thunks.map((t) => Promise.resolve().then(t).catch(() => null)));

/**
 * Faithful stand-in for the runtime's `pipeline`: each item runs every stage
 * independently, with no barrier between stages. A stage that throws drops
 * that item to null and skips its remaining stages.
 *
 * @param {any[]} items - Work items.
 * @param {...Function} stages - Stage callbacks, called (prev, item, index).
 * @returns {Promise<any[]>} One result per item.
 */
const stubPipeline = (items, ...stages) =>
  Promise.all(items.map(async (item, i) => {
    let acc = item;
    for (const stage of stages) {
      try {
        acc = await stage(acc, item, i);
      } catch {
        return null;
      }
    }
    return acc;
  }));

/**
 * Execute the workflow script body with stubs.
 *
 * @param {string} source - Raw script contents.
 * @param {object} runArgs - Value exposed to the script as `args`.
 * @param {Function} agentStub - Stands in for `agent(prompt, opts)`.
 * @returns {Promise<{result: any, logs: string[]}>} The script's return value.
 */
function runScript(source, runArgs, agentStub) {
  const logs = [];
  const body = new AsyncFunction(
    'args', 'agent', 'pipeline', 'parallel', 'log', 'phase', 'budget', 'workflow',
    source.replace(/^export /gm, ''),
  );
  return body(runArgs, agentStub, stubPipeline, stubParallel, (m) => logs.push(String(m)),
    () => {}, { total: null, spent: () => 0, remaining: () => Infinity }, async () => {})
    .then((result) => ({ result, logs }));
}

const REVIEWERS = [
  { key: 'architecture', agentType: 'plan-agent:plan-reviewer-architecture' },
  { key: 'testability', agentType: 'plan-agent:plan-reviewer-testability' },
];

/** One finding per severity, so the filter has something to discriminate on. */
const FOUR_SEVERITIES = {
  assessment: 'ok',
  findings: [
    { target: 'a', action: 'edit', content: 'c', rationale: 'r', severity: 'critical' },
    { target: 'b', action: 'edit', content: 'c', rationale: 'r', severity: 'high' },
    { target: 'c', action: 'edit', content: 'c', rationale: 'r', severity: 'medium' },
    { target: 'd', action: 'edit', content: 'c', rationale: 'r', severity: 'low' },
  ],
};

if (existsSync(SCRIPT)) {
  const source = readFileSync(SCRIPT, 'utf8');
  const base = { planPath: '/tmp/plan.md', reviewers: REVIEWERS };

  // Counts the verify calls so the severity filter is measured, not inferred.
  const countingAgent = (counter, verdict = { refuted: false, reason: 'holds' }) =>
    async (_prompt, opts) => {
      if (opts.phase === 'Review') return FOUR_SEVERITIES;
      counter.n++;
      return verdict;
    };

  // ── Severity filter ──
  const dflt = { n: 0 };
  const { result: r1 } = await runScript(source, base, countingAgent(dflt));

  // 2 reviewers x 4 findings = 8; only critical+high earn a skeptic = 4.
  check('behaviour: default verifies only critical and high (4 of 8)', dflt.n === 4);
  check('behaviour: default leaves the other 4 findings unverified',
    r1.stats.unverified === 4 && r1.stats.verified === 4);
  check('behaviour: every finding survives when nothing is refuted',
    r1.stats.surviving === 8 && r1.stats.total === 8);
  check('behaviour: only high/critical carry a verdict',
    r1.findings.filter((f) => f.verdict !== null)
      .every((f) => ['critical', 'high'].includes(f.severity)));

  // ── --deep lifts the filter ──
  const deep = { n: 0 };
  const { result: r2 } = await runScript(source, { ...base, deep: true }, countingAgent(deep));

  check('behaviour: --deep verifies every finding (8 of 8)', deep.n === 8);
  check('behaviour: --deep leaves nothing unverified',
    r2.stats.unverified === 0 && r2.stats.deep === true);

  // ── A refuted finding is dropped before synthesis ──
  const { result: r3 } = await runScript(source, base,
    countingAgent({ n: 0 }, { refuted: true, reason: 'already handled' }));

  check('behaviour: refuted findings are dropped, unverified ones kept',
    r3.stats.refuted === 4 && r3.stats.surviving === 4);
  check('behaviour: no surviving finding is marked refuted',
    r3.findings.every((f) => !f.verdict?.refuted));

  // ── A dead reviewer is reported, not silently counted as clean ──
  // Regression: stage 2 used to coalesce a null lens to [], which is truthy,
  // so lensesLost could never be non-zero and a crashed lens rendered
  // identically to one that ran and found nothing.
  const { result: r4, logs: l4 } = await runScript(source, base, async (_p, opts) => {
    if (opts.phase === 'Review') {
      return opts.label === 'review:testability' ? null : FOUR_SEVERITIES;
    }
    return { refuted: false, reason: 'holds' };
  });

  check('behaviour: a dead reviewer is counted as lost',
    r4.stats.lensesLost === 1 && r4.stats.reviewersRun === 1);
  check('behaviour: a dead reviewer is announced to the user',
    l4.some((m) => /reviewer\(s\) failed/i.test(m)));
  check('behaviour: only the surviving lens contributes findings',
    r4.stats.total === 4 && r4.findings.every((f) => f.reviewer === 'architecture'));

  // ── A crashed verifier is not reported as "below threshold" ──
  // Regression: a failed verify agent resolved to null, which was
  // indistinguishable from "never sent", so the run told the user to re-run
  // with --deep — advice that cannot fix a broken verifier.
  const { result: r5, logs: l5 } = await runScript(source, base, async (_p, opts) => {
    if (opts.phase === 'Review') return FOUR_SEVERITIES;
    return null; // every skeptic dies
  });

  check('behaviour: a crashed verifier is tracked separately from unverified',
    r5.stats.verifierFailed === 4 && r5.stats.unverified === 4);
  check('behaviour: a crashed verifier does not count as verified',
    r5.stats.verified === 0);
  check('behaviour: a finding whose verifier died is kept, not dropped',
    r5.stats.surviving === 8);
  check('behaviour: the crashed-verifier log does not blame the severity filter',
    l5.some((m) => /verifier failed/i.test(m) && /--deep will not help/i.test(m)));

  // ── Guard rails ──
  let threw = '';
  await runScript(source, { reviewers: REVIEWERS }, async () => FOUR_SEVERITIES)
    .catch((e) => { threw = String(e); });
  check('behaviour: a missing planPath fails loudly', /planPath is required/.test(threw));

  threw = '';
  await runScript(source, { planPath: '/tmp/p.md', reviewers: [] }, async () => FOUR_SEVERITIES)
    .catch((e) => { threw = String(e); });
  check('behaviour: an empty reviewer roster fails loudly', /reviewers is empty/.test(threw));
}

// ── The reviewer agents describe the contract they are actually called under ──
// agentType reuse makes each callee's own prompt part of the caller's contract.
// These files told the model to call SendMessage with a prose template — an
// Agent Teams leftover that survived the engine swap, unfollowable (none of
// them grant SendMessage) and silent about the fields the schema requires.

const AGENTS_DIR = join(ROOT, 'kit', 'plugins', 'plan-agent', 'agents');
const reviewerFiles = existsSync(AGENTS_DIR)
  ? readdirSync(AGENTS_DIR).filter((f) => f.startsWith('plan-reviewer-') && f.endsWith('.md'))
  : [];

check('ten plan-reviewer agent definitions are present', reviewerFiles.length === 10);

const stillProse = [];
const missingFields = [];

for (const file of reviewerFiles) {
  const body = readFileSync(join(AGENTS_DIR, file), 'utf8');
  const grants = /^tools:.*\bSendMessage\b/m.test(frontmatter(body));

  // A positive instruction to use it. The rewritten section names SendMessage
  // only to forbid it, so match the instruction, not the bare word.
  if (/call `?SendMessage`? with/i.test(body) && !grants) stillProse.push(file);

  // The schema's field names must appear, or the lens is told nothing about
  // the shape it has to produce.
  if (!['target', 'action', 'content', 'rationale', 'severity']
    .every((f) => body.includes(`\`${f}\``))) missingFields.push(file);
}

check(`no reviewer agent instructs an ungranted SendMessage${stillProse.length ? ` (${stillProse.join(', ')})` : ''}`,
  reviewerFiles.length === 10 && stillProse.length === 0);

check(`every reviewer agent documents the schema fields it must return${missingFields.length ? ` (${missingFields.join(', ')})` : ''}`,
  reviewerFiles.length === 10 && missingFields.length === 0);

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
