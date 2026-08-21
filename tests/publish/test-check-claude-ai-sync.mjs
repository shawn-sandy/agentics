import {
  findOrphans,
  formatReport,
  missingFrom,
} from '../../scripts/check-claude-ai-sync.mjs';

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

// ── missingFrom ────────────────────────────────────────────────────────────

check(
  'reports what the repo has and the snapshot lacks',
  JSON.stringify(missingFrom(['build', 'build-fleet', 'build-feature'], ['build'])) ===
    '["build-feature","build-fleet"]',
);

check('identical trees report nothing', missingFrom(['a', 'b'], ['b', 'a']).length === 0);

check(
  'a snapshot-only entry is not reported (one-directional by design)',
  missingFrom(['a'], ['a', 'removed-skill']).length === 0,
);

check('an empty snapshot reports every repo entry', missingFrom(['a', 'b'], []).length === 2);

// ── findOrphans ────────────────────────────────────────────────────────────

const shipped = new Set(['plan-agent', 'git-agent']);

const installed = [
  { name: 'plan-agent', marketplaceId: 'mk_agentics' },
  { name: 'git-agent', marketplaceId: 'mk_agentics' },
  { name: 'plan-interview', marketplaceId: 'mk_agentics' },
  { name: 'product-plans', marketplaceId: 'mk_agentics' },
  { name: 'canva', marketplaceId: 'mk_knowledge_work' },
];

check(
  'removed plugins in our marketplace are orphans, sorted',
  JSON.stringify(findOrphans(installed, shipped)) === '["plan-interview","product-plans"]',
);

check(
  'plugins from a foreign marketplace are never orphans',
  !findOrphans(installed, shipped).includes('canva'),
);

check(
  'a marketplace we ship nothing from is left alone entirely',
  findOrphans([{ name: 'canva', marketplaceId: 'mk_knowledge_work' }], shipped).length === 0,
);

check(
  'our marketplace is matched by id, not by name, so a rename still works',
  findOrphans(
    [
      { name: 'plan-agent', marketplaceId: 'mk_renamed' },
      { name: 'plan-interview', marketplaceId: 'mk_renamed' },
    ],
    shipped,
  ).length === 1,
);

// ── formatReport ───────────────────────────────────────────────────────────

check('a clean comparison produces no output at all', formatReport([], []).length === 0);

const staleReport = formatReport(
  [{ name: 'plan-agent', syncedAt: '2026-08-02', skills: ['build-feature'], commands: ['fix'] }],
  [],
);

check(
  'a stale plugin names itself, its sync date, and what is missing',
  staleReport[0].includes('plan-agent') &&
    staleReport[0].includes('2026-08-02') &&
    staleReport[0].includes('build-feature'),
);

check('missing commands are shown slash-prefixed', staleReport[0].includes('/fix'));

check(
  'a plugin missing only skills does not mention commands',
  !formatReport(
    [{ name: 'memory-tools', syncedAt: '2026-08-13', skills: ['implementing-insights'], commands: [] }],
    [],
  )[0].includes('commands'),
);

check(
  'orphans warn even when nothing is stale',
  formatReport([], ['plan-interview']).some((l) => l.includes('plan-interview')),
);

check(
  'the remediation line is appended exactly once',
  formatReport(
    [
      { name: 'a', syncedAt: '2026-01-01', skills: ['x'], commands: [] },
      { name: 'b', syncedAt: '2026-01-01', skills: ['y'], commands: [] },
    ],
    ['c'],
  ).filter((l) => l.includes('claude.ai')).length === 4,
);

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
