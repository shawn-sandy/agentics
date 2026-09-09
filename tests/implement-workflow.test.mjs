// Static + behavioural assertions for the plan-implement-lanes Workflow
// script (docs/plans/add-workflow-engine-escalation.md).
// Checks that kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs
// parses as a workflow body, exports the LANE_REPORT schema and an Implement
// phase, derives wave ordering from after: edges (skipping any lane named
// lead), returns mergeOrder, and documents its own selection gate in the
// header comment.
// Run: node tests/implement-workflow.test.mjs

import { existsSync, readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const SCRIPT = join(ROOT, 'kit', 'plugins', 'plan-agent', 'skills', 'build', 'references', 'implement-workflow.mjs');

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

check('references/implement-workflow.mjs exists', existsSync(SCRIPT));

if (existsSync(SCRIPT)) {
  const script = readFileSync(SCRIPT, 'utf8');

  const parsed = parsesAsWorkflowBody(script);
  check('references/implement-workflow.mjs parses as a workflow body', parsed.ok);
  if (!parsed.ok) console.log(`  ${parsed.error}`);

  // ── meta block ──────────────────────────────────────────────────────────

  check('script: exports a meta block naming plan-implement-lanes with an Implement phase',
    /export const meta\s*=/.test(script)
    && script.includes("name: 'plan-implement-lanes'")
    && script.includes("title: 'Implement'"));

  // ── Header documents its own selection gate ────────────────────────────
  // dispatch-lanes.md (the wiring lane) restates this rule in prose, but
  // tests only depends on script — so the header comment is the one place
  // this suite can check the gate without waiting on that lane.

  // Collapsed to single spaces so a phrase that happens to wrap across two
  // // -prefixed comment lines still matches a plain substring check.
  const prose = script.replace(/^\/\/ ?/gm, '').replace(/\s+/g, ' ');

  check('header: documents the workflow: always selector', prose.includes('workflow: always'));
  check('header: documents the --workflow flag selector', prose.includes('--workflow'));
  check('header: documents the 6-or-more-lanes selector', prose.includes('6 or more lanes'));
  check('header: documents the fewer-than-2-lanes sequential rule',
    /fewer than 2 lanes/i.test(prose));
  check('header: says the Workflow tool is probed, not version-asserted',
    /probes[\s\S]{0,160}Workflow tool is callable/i.test(prose) && prose.includes('never asserts a minimum'));

  // ── Forbidden APIs ───────────────────────────────────────────────────────
  // Date.now/Math.random/new Date() throw in a workflow, and require() has
  // no place in a script the runtime splices into an ESM-flavoured body.

  check('script: avoids Date.now/Math.random/new Date(/require(, which are unsafe in a workflow',
    !/Date\.now\(|Math\.random\(|new Date\(|require\(/.test(script));

  // ── Behavioural: run the script against a stubbed runtime ────────────────
  // The static checks above can't tell working after: ordering from broken —
  // every keyword they could grep for also appears in comments and variable
  // names. These execute the script with a controllable agent() stub and
  // observe when it is actually called, and with what options.

  /**
   * Execute the workflow script body with stubs standing in for the runtime
   * helpers. implement-workflow.mjs never calls pipeline/parallel/phase/
   * budget/workflow, so those are passed as inert placeholders.
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
    return body(runArgs, agentStub, async () => [], async () => [],
      (m) => logs.push(String(m)), () => {},
      { total: null, spent: () => 0, remaining: () => Infinity }, async () => {})
      .then((result) => ({ result, logs }));
  }

  /**
   * Build an agent() stub that records every call's options, in call order,
   * and can hold a named lane's call open until the test releases it — the
   * only way to prove a downstream lane's agent() call happens strictly
   * *after* its dependency's promise settles, not merely dispatched at the
   * same time.
   *
   * @param {{holdUntilReleased?: string[]}} [behavior] - Labels to pause on.
   * @returns {{stub: Function, calls: object[], release: (label: string) => void}}
   */
  function makeStub(behavior = {}) {
    const calls = [];
    const pending = new Map();
    const stub = async (_prompt, opts) => {
      calls.push(opts);
      if (behavior.holdUntilReleased?.includes(opts.label)) {
        await new Promise((resolve) => pending.set(opts.label, resolve));
      }
      return {
        lane: opts.label.replace(/^lane:/, ''),
        branch: 'b/' + opts.label,
        steps_done: ['1'],
        verify: '1: pass',
        files_changed: ['f.txt'],
        blocked: 'none',
      };
    };
    return { stub, calls, release: (label) => pending.get(label)?.() };
  }

  const base = { planPath: '/tmp/plan.md', planBranch: 'plan/x' };

  // ── Wave ordering: a dependent lane waits on its after: lane's promise ──
  const chain = makeStub({ holdUntilReleased: ['lane:a'] });
  const chainLanes = [
    { name: 'a', owns: ['x'], after: [], brief: 'do a' },
    { name: 'b', owns: ['y'], after: ['a'], brief: 'do b' },
  ];
  const pendingRun = runScript(script, { ...base, lanes: chainLanes }, chain.stub);

  // Let every already-resolvable microtask run (Promise.all([]), the .then
  // chains built by waveFor) without releasing 'a' — this is where an
  // eagerly-dispatched 'b' would show up.
  await new Promise((resolve) => setTimeout(resolve, 0));
  check('wave ordering: the dependent lane is not dispatched before its after: lane resolves',
    chain.calls.length === 1 && chain.calls[0].label === 'lane:a');

  chain.release('lane:a');
  const { result: chainResult } = await pendingRun;

  check('wave ordering: the dependent lane is dispatched once its after: lane resolves',
    chain.calls.length === 2 && chain.calls[1].label === 'lane:b');

  check('agent() call: passes isolation: worktree',
    chain.calls.length === 2 && chain.calls.every((c) => c.isolation === 'worktree'));

  check('agent() call: passes a LANE_REPORT schema requiring all six fields',
    chain.calls.every((c) => c.schema?.type === 'object'
      && Array.isArray(c.schema.required)
      && c.schema.required.length === 6
      && ['lane', 'branch', 'steps_done', 'verify', 'files_changed', 'blocked']
        .every((f) => c.schema.required.includes(f))));

  check('script: returns a mergeOrder array', Array.isArray(chainResult.mergeOrder));

  // ── A lane named lead is skipped ──────────────────────────────────────
  const withLead = makeStub();
  const leadLanes = [
    { name: 'a', owns: ['x'], after: [], brief: 'do a' },
    { name: 'lead', owns: [], after: ['a'], brief: 'do lead things' },
  ];
  const { result: leadResult } = await runScript(script, { ...base, lanes: leadLanes }, withLead.stub);

  check('script: never dispatches a lane named lead',
    withLead.calls.every((c) => c.label !== 'lane:lead'));
  check('script: omits lead from mergeOrder', !leadResult.mergeOrder.includes('lead'));
  check('script: omits lead from reports', !leadResult.reports.some((r) => r.name === 'lead'));

  // ── mergeOrder is topologically sorted, dependencies before dependents ──
  const diamond = makeStub();
  const diamondLanes = [
    { name: 'a', owns: [], after: [], brief: 'a' },
    { name: 'b', owns: [], after: ['a'], brief: 'b' },
    { name: 'c', owns: [], after: ['a', 'b'], brief: 'c' },
  ];
  const { result: diamondResult } = await runScript(script, { ...base, lanes: diamondLanes }, diamond.stub);

  check('script: mergeOrder places every after: dependency before its dependent',
    diamondResult.mergeOrder.indexOf('a') < diamondResult.mergeOrder.indexOf('b')
    && diamondResult.mergeOrder.indexOf('b') < diamondResult.mergeOrder.indexOf('c'));
}

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail > 0 ? 1 : 0);
