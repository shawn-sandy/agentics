// Static assertions for the review-plan findings walkthrough
// (docs/plans/add-review-findings-walkthrough.html).
// Checks that kit/plugins/plan-agent/skills/review-plan/SKILL.md documents
// the --skip-analysis and --triage-top flags, the Step 6b walkthrough, and
// the accepted_edits state variable. Run: node tests/review-plan-skill.test.mjs

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const SKILL = join(ROOT, 'kit', 'plugins', 'plan-agent', 'skills', 'review-plan', 'SKILL.md');

let pass = 0;
let fail = 0;

function check(name, cond) {
  if (cond) {
    console.log(`PASS: ${name}`);
    pass++;
  } else {
    console.log(`FAIL: ${name}`);
    fail++;
  }
}

const skill = readFileSync(SKILL, 'utf8');

// ── Flag tokens and walkthrough state ──────────────────────────────────────

check('SKILL.md: documents the --skip-analysis flag',
  skill.includes('--skip-analysis'));

check('SKILL.md: documents the --triage-top flag',
  skill.includes('--triage-top'));

check('SKILL.md: has a Step 6b heading',
  /^###\s+Step 6b/m.test(skill));

check('SKILL.md: tracks the accepted_edits state variable',
  skill.includes('accepted_edits'));

// ── Background mode section ────────────────────────────────────────────────
// Slice the file from "## Background mode" to the next "## " heading so the
// implied-flag assertion targets that section specifically.

const BG_HEADING = '## Background mode';
const bgStart = skill.indexOf(BG_HEADING);
let bgSection = '';
if (bgStart !== -1) {
  const rest = skill.slice(bgStart + BG_HEADING.length);
  const next = rest.search(/^## /m);
  bgSection = next === -1 ? rest : rest.slice(0, next);
}

check('SKILL.md: has a Background mode section', bgStart !== -1);

check('Background mode section: states --skip-analysis is implied',
  bgSection.includes('--skip-analysis') && /impli(?:ed|es)/i.test(bgSection));

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
