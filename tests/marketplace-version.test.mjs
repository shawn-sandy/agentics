// Verifies the plan-agent version bump in .claude-plugin/marketplace.json
// for the review-plan findings walkthrough
// (docs/plans/add-review-findings-walkthrough.html).
// Run: node tests/marketplace-version.test.mjs
//
// EXPECTED tracks the current marketplace version. The plan document
// originally said 1.12.0, but was renumbered because main had already
// shipped plan-agent 2.0.0 — this change lands as 2.0.0 -> 2.1.0.
// Bump EXPECTED (and BASELINE) when plan-agent is next released.

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const MARKETPLACE = join(ROOT, '.claude-plugin', 'marketplace.json');

const EXPECTED = '2.1.0';
const BASELINE = '2.0.0'; // plan-agent version on main when this change landed

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

// Strictly-greater comparison on MAJOR.MINOR.PATCH semver strings.
function semverGt(a, b) {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) {
    if (pa[i] !== pb[i]) return pa[i] > pb[i];
  }
  return false;
}

const raw = readFileSync(MARKETPLACE, 'utf8');

let manifest = null;
try {
  manifest = JSON.parse(raw);
} catch {
  manifest = null;
}

check('marketplace.json: parses as JSON', manifest !== null);

const planAgent = manifest && Array.isArray(manifest.plugins)
  ? manifest.plugins.find((p) => p.name === 'plan-agent')
  : undefined;

check('marketplace.json: has a plan-agent plugin entry', Boolean(planAgent));

check(`plan-agent: version is ${EXPECTED}`,
  Boolean(planAgent) && planAgent.version === EXPECTED);

check(`semver: ${EXPECTED} is strictly higher than baseline ${BASELINE}`,
  semverGt(EXPECTED, BASELINE));

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
