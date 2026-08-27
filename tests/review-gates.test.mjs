// Static assertions for the review-gate hardening
// (docs/plans/harden-review-gates.md).
//
// The 2026-08-21 usage-insights report identified five defect classes that
// escaped every existing gate and were caught by PR review bots instead:
// pagination tie-breakers, unvalidated numeric parsing, stale derived state,
// timezone-dependent dates, and scripts that continue after a failure. It also
// found that "did CI dispatch at all?" was asked in only one skill, and that
// nothing verified checkout freshness before implementation.
//
// Each assertion below fails if its edit is reverted.
// Run: node tests/review-gates.test.mjs

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const PLUGINS = join(ROOT, 'kit', 'plugins');

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
 * Read a file under kit/plugins as UTF-8 text.
 *
 * @param {...string} parts - Path segments relative to kit/plugins.
 * @returns {string} File contents.
 */
function readPlugin(...parts) {
  return readFileSync(join(PLUGINS, ...parts), 'utf8');
}

/**
 * Case-insensitive substring test. The same defect class is sentence-cased as
 * a checklist bullet and lower-cased mid-sentence in the review prompt, and
 * forcing one casing on both would distort the prose rather than test it.
 *
 * @param {string} src - Text to search.
 * @param {string} needle - Substring to find.
 * @returns {boolean} True when src contains needle, ignoring case.
 */
function has(src, needle) {
  return src.toLowerCase().includes(needle.toLowerCase());
}

/**
 * Extract the contiguous blockquote lines from a markdown document — the
 * adversarial-review prompt is the only blockquote in both files that carry
 * it, so this isolates the prompt for an exact cross-file comparison.
 *
 * @param {string} src - Markdown source.
 * @returns {string} The blockquote lines, newline-joined.
 */
function blockquote(src) {
  return src
    .split('\n')
    .filter((l) => l.startsWith('> '))
    .join('\n');
}

// ── 1. The adversarial review names the escape-prone defect classes ─────────

// Substrings, not full sentences: an assertion locked to exact wording would
// fail on a harmless rephrase, which is noise rather than signal.
const DEFECT_CLASSES = [
  'tie-breaker',
  '`parseInt`/`Number()`',
  'derived state left stale',
  'timezone-dependent date anchors',
  'continue after a failed step',
];

const PR_AGENT = readPlugin('git-agent', 'skills', 'pr-agent', 'SKILL.md');
const SELF_REVIEW = readPlugin(
  'git-agent', 'skills', 'ship', 'references', 'self-review.md',
);

for (const cls of DEFECT_CLASSES) {
  check(`pr-agent Step 4.7 checks for: ${cls}`, has(PR_AGENT, cls));
  check(`ship self-review checks for: ${cls}`, has(SELF_REVIEW, cls));
}

// Two copies of one checklist drift the moment only one is edited. This is the
// assertion that catches that, so it must compare content, not just presence.
check(
  'the two adversarial-review prompts are byte-identical',
  blockquote(PR_AGENT) === blockquote(SELF_REVIEW) &&
    blockquote(PR_AGENT).includes('tie-breaker'),
);

// ── 2. The code-review checklist mirrors the same classes ──────────────────

const CHECKLIST = readPlugin(
  'code-review', 'skills', 'code-review-agent', 'references',
  'review-checklist.md',
);

check(
  'review-checklist has an Escape-Prone Classes subsection',
  CHECKLIST.includes('**Escape-Prone Classes:**'),
);

for (const cls of DEFECT_CLASSES) {
  check(`review-checklist covers: ${cls}`, has(CHECKLIST, cls));
}

// The subsection belongs to "Potential Bugs", not to the security section that
// follows it — placement is what makes the reviewer read it in context.
check(
  'Escape-Prone Classes sits inside section 2, before section 3',
  CHECKLIST.indexOf('### 2. Potential Bugs') <
    CHECKLIST.indexOf('**Escape-Prone Classes:**') &&
    CHECKLIST.indexOf('**Escape-Prone Classes:**') <
      CHECKLIST.indexOf('### 3. Security Vulnerabilities'),
);

// ── 3. merge distinguishes "never dispatched" from "passed" ────────────────

const MERGE = readPlugin('git-agent', 'skills', 'merge', 'SKILL.md');

check(
  'merge has a never-dispatched section',
  MERGE.includes('### When CI never dispatched'),
);
check(
  'merge reads the jobs array to detect a non-dispatch',
  MERGE.includes('--json jobs'),
);
check(
  'merge forbids reporting green when no job produced output',
  MERGE.includes('Never call a PR "CI green"'),
);
// It must not become a blocking gate — an external blocker is not a defect,
// and blocking on one would strand every merge during a billing outage.
check(
  'the never-dispatched rule is explicitly not a gate',
  MERGE.includes('This is **not** a gate'),
);
// Placement: inside Step 2, before the failure branch that ends it.
check(
  'never-dispatched sits inside Step 2',
  MERGE.indexOf('## Step 2: Readiness gate') <
    MERGE.indexOf('### When CI never dispatched') &&
    MERGE.indexOf('### When CI never dispatched') <
      MERGE.indexOf('## Step 3: Re-check, ask, then merge'),
);

// A zero-byte `--log-failed` is not evidence that no job started. The
// 2026-08-14 measurement behind this rule only ever observed blocked runs with
// an EMPTY jobs array — it never measured a run whose jobs started and whose
// logs came back empty (retention expiry, an attempt mismatch, a transient API
// error). Reporting that case as "never dispatched — billing block" tells the
// user to ignore a real failure, so the jobs array, not the log size, has to
// carry the non-dispatch call.
//
// These assert the classification sentences themselves, not bare tokens: a
// token like `startedAt` would still be found if it survived only in a code
// comment while the rule reverted. Whitespace is collapsed first so rewrapping
// a paragraph does not fail the run.
const flat = (t) => t.replace(/\s+/g, ' ');
const MERGE_FLAT = flat(MERGE);
const CI_AUTOFIX_FLAT = flat(
  readPlugin(
    'git-agent', 'skills', 'ship-autonomous', 'references', 'ci-autofix.md',
  ),
);

check(
  'merge classifies ONLY an empty run list or empty jobs as non-dispatch',
  MERGE_FLAT.includes(
    '**never dispatched** only when the run list is empty or the `jobs` array is empty',
  ),
);
check(
  'merge classifies started-jobs-with-empty-log as logs unavailable',
  MERGE_FLAT.includes(
    'When jobs started and the log is empty, report **"CI failed — logs unavailable"**',
  ),
);
// The negative is the actual regression guard: the removed clause must not
// come back, in this file or the reference that drives ship-autonomous.
check(
  'merge no longer treats zero log bytes as a non-dispatch signal',
  !MERGE_FLAT.includes('every job failed') &&
    MERGE_FLAT.includes('**Log size never makes this call.**'),
);
check(
  'ci-autofix classifies ONLY an empty jobs array as external-blocker',
  CI_AUTOFIX_FLAT.includes(
    'Classify as `external-blocker` only when the **jobs array is empty**',
  ),
);
check(
  'ci-autofix refuses external-blocker for a started-jobs empty log',
  CI_AUTOFIX_FLAT.includes('Do not classify it as `external-blocker`') &&
    CI_AUTOFIX_FLAT.includes('logs unavailable'),
);
check(
  'ci-autofix no longer classifies all-failed-with-empty-logs as a blocker',
  !CI_AUTOFIX_FLAT.includes('when **every** job failed'),
);

// The run being classified must be the one belonging to this PR's head commit.
// `gh run list --branch` returns every recent run on the branch across commits
// AND workflows — on PR #607's own branch that was four runs from two
// workflows on a single SHA — so an unbound <run-id> can classify a different
// run than the failing check and reach the wrong verdict by a second route.
check(
  'merge binds the run list to the verified head commit',
  MERGE_FLAT.includes('--commit <headRefOid>'),
);
check(
  'merge tells the reader to pick the run by workflow, not arbitrarily',
  MERGE_FLAT.includes(
    'Pick the row whose `workflowName` matches the failing check',
  ),
);
// ci-autofix's fetch was unfiltered — `gh run list` with no --commit and no
// --branch returns failing runs from the WHOLE repo, so a concurrent PR's red
// run could be fetched and autofixed against. The classification above is only
// correct if it is classifying this PR's run.
check(
  'ci-autofix binds its log fetch to the PR head commit',
  CI_AUTOFIX_FLAT.includes('gh run list --commit "$(gh pr view'),
);

// ── 4. build checks checkout freshness before implementing ─────────────────

// The check lives in resolve-plan.md, not the core: build/SKILL.md sits at
// 596 words against a 600-word ceiling that exists because a core is paid in
// full on every fire, so not even a one-line pointer fits. The core already
// delegates Steps 0-1 to this reference, so it is read at the right moment.
const RESOLVE = readPlugin(
  'plan-agent', 'skills', 'build', 'references', 'resolve-plan.md',
);

check(
  'resolve-plan pre-flight has a stale-checkout guard',
  RESOLVE.includes('**Stale checkout → stop and ask.**'),
);
check(
  'the guard counts commits between HEAD and the base',
  RESOLVE.includes('git log "HEAD..$BASE" --oneline'),
);
// Hardcoding origin/main breaks every master/develop repo.
check(
  'the guard resolves the base branch instead of hardcoding it',
  RESOLVE.includes('refs/remotes/origin/HEAD'),
);
// Placement: inside the Step 1 pre-flight, ahead of plans-directory
// resolution — a premise check after the work starts is worth nothing.
check(
  'the guard sits in the pre-flight, before directory resolution',
  RESOLVE.indexOf('Pre-flight guard') <
    RESOLVE.indexOf('**Stale checkout → stop and ask.**') &&
    RESOLVE.indexOf('**Stale checkout → stop and ask.**') <
      RESOLVE.indexOf('Resolve the plans directory'),
);
// The core must stay under the progressive-disclosure ceiling that forced
// this placement; test-progressive-disclosure.sh owns the exact number.
const BUILD = readPlugin('plan-agent', 'skills', 'build', 'SKILL.md');
check(
  'build core did not absorb the freshness prose',
  !BUILD.includes('git log "HEAD..$BASE"'),
);

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
