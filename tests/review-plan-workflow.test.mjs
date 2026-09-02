// Static assertions for the review-plan Workflow engine
// (docs/plans/replace-review-team-with-workflow.html).
// Checks that kit/plugins/plan-agent/skills/review-plan/SKILL.md no longer
// gates on the Agent Teams feature flag, that it drives the Workflow tool
// instead, and that the shipped workflow script parses.
// Run: node tests/review-plan-workflow.test.mjs

import { existsSync, readFileSync } from 'node:fs';
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
  /Workflow[^\n]*\bscript\b|`script`/.test(skill) && /`args`/.test(skill));

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

  check('script: verifies only high/critical severity by default',
    script.includes('critical') && script.includes('high'));

  check('script: supports --deep to lift the severity filter',
    script.includes('deep'));

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

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
