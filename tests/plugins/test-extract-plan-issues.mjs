#!/usr/bin/env node
/**
 * Regression test for git-agent's plan-ticket scan (extract-plan-issues.sh).
 *
 * The PR skills write one `Closes <url>` line per URL this script prints, and
 * GitHub closes those tickets when the PR merges. It used to read only
 * `docs/plans/*.html`, so an artifact-delivered plan — a `.md` spec with no
 * rendered sibling — never closed its ticket (#626 stayed open after its plan
 * shipped). It must also never close a ticket for a plan that is not done: the
 * PR that authors a plan touches the very same file.
 *
 *   1. Completed plans on the branch yield their ticket, `.md` or `.html`.
 *   2. Plans that are not completed, or untouched by the branch, yield nothing.
 *   3. Only a frontmatter `issue:` counts, and only an https URL is printed.
 *   4. A branch with no plan changes exits 0 with no output.
 *
 * Run: node tests/plugins/test-extract-plan-issues.mjs
 */

import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const SCRIPT = join(ROOT, 'kit', 'plugins', 'git-agent', 'bin', 'git-agent-extract-plan-issues');
const url = (n) => `https://github.com/acme/widgets/issues/${n}`;

let passed = 0;
function ok(name, fn) {
  try {
    fn();
    passed += 1;
    console.log(`  PASS ${name}`);
  } catch (err) {
    console.error(`  FAIL ${name}`);
    console.error(`       ${err.message}`);
    process.exitCode = 1;
  }
}

const spec = (status, issue, body = '') =>
  `---\nstatus: ${status}\ntype: fix\n${issue ? `issue: ${issue}\n` : ''}---\n\n# Plan: test\n${body}`;

const html = (status, issue) =>
  `<!doctype html>\n<html lang="en" data-status="${status}">\n<head>\n` +
  `<meta name="plan-status" content="${status}">\n<meta name="plan-issue" content="${issue}">\n` +
  `</head>\n<body></body>\n</html>\n`;

const dir = mkdtempSync(join(tmpdir(), 'extract-plan-issues-'));
const git = (...args) => {
  const r = spawnSync('git', args, { cwd: dir, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`git ${args.join(' ')}: ${r.stderr}`);
};
const write = (files) => {
  for (const [path, body] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, path)), { recursive: true });
    writeFileSync(join(dir, path), body);
  }
};
const scan = (base) => {
  const r = spawnSync('bash', [SCRIPT, base], { cwd: dir, encoding: 'utf8' });
  return { status: r.status, stderr: r.stderr, lines: r.stdout.split('\n').filter(Boolean) };
};

try {
  git('init', '-q', '-b', 'main');
  git('config', 'user.email', 'test@example.com');
  git('config', 'user.name', 'test');
  write({ 'docs/plans/shipped-earlier.md': spec('completed', url(10)) });
  git('add', '-A');
  git('commit', '-q', '-m', 'base');
  git('checkout', '-q', '-b', 'feature');

  write({
    'docs/plans/artifact-done.md': spec('completed', url(1)),
    'docs/plans/nested/done.md': spec('completed', url(2)),
    'docs/plans/wip.md': spec('in-progress', url(3)),
    'docs/plans/draft.md': spec('todo', url(4)),
    'docs/plans/legacy-done.html': html('completed', url(5)),
    'docs/plans/legacy-todo.html': html('todo', url(6)),
    'docs/plans/pair.md': spec('completed', url(7)),
    'docs/plans/pair.html': html('completed', url(7)),
    'docs/plans/body-only.md': spec('completed', '', `\n\`\`\`yaml\nissue: ${url(8)}\n\`\`\`\n`),
    'docs/plans/unsafe.md': spec('completed', '$(touch pwned)'),
    // The renderer normalizes CRLF (scripts/lib/plan-spec.mjs), so such a spec is valid.
    'docs/plans/crlf-done.md': spec('completed', url(11)).replace(/\n/g, '\r\n'),
    'docs/plans/no-frontmatter.md': `# Notes\nstatus: completed\nissue: ${url(12)}\n---\n`,
  });
  git('add', '-A');
  git('commit', '-q', '-m', 'plans');

  const r = scan('main');

  ok('a completed .md plan saved with CRLF line endings yields its ticket', () =>
    assert.ok(r.lines.includes(url(11)), `got: ${r.lines.join(', ')}`));
  ok('a .md file with no frontmatter block is ignored', () =>
    assert.ok(!r.lines.includes(url(12)), 'body lines were read as frontmatter'));

  ok('exits 0', () => assert.equal(r.status, 0, r.stderr));
  ok('a completed .md plan with no .html sibling yields its ticket', () =>
    assert.ok(r.lines.includes(url(1)), `got: ${r.lines.join(', ')}`));
  ok('a completed .md plan in a nested directory yields its ticket', () =>
    assert.ok(r.lines.includes(url(2)), `got: ${r.lines.join(', ')}`));
  ok('a completed legacy .html plan still yields its ticket', () =>
    assert.ok(r.lines.includes(url(5)), `got: ${r.lines.join(', ')}`));
  ok('in-progress and todo .md plans never yield a ticket', () => {
    assert.ok(!r.lines.includes(url(3)), 'in-progress spec closed its ticket');
    assert.ok(!r.lines.includes(url(4)), 'todo spec closed its ticket');
  });
  ok('a todo .html plan never yields a ticket', () =>
    assert.ok(!r.lines.includes(url(6)), 'todo html closed its ticket'));
  ok('a plan the branch did not touch is not scanned', () =>
    assert.ok(!r.lines.includes(url(10)), 'base-branch plan closed its ticket'));
  ok('a .md spec and its .html sibling yield one line', () =>
    assert.equal(r.lines.filter((l) => l === url(7)).length, 1));
  ok('an issue: line outside the frontmatter is ignored', () =>
    assert.ok(!r.lines.includes(url(8)), 'body text was read as frontmatter'));
  ok('every printed line is an https URL', () =>
    assert.deepEqual(r.lines.filter((l) => !/^https:\/\/\S+$/.test(l)), []));
  ok('prints exactly the completed plans touched by the branch', () =>
    assert.deepEqual(r.lines, [url(1), url(2), url(5), url(7), url(11)].sort()));

  const none = scan('feature');
  ok('a branch with no plan changes exits 0 with no output', () => {
    assert.equal(none.status, 0, none.stderr);
    assert.deepEqual(none.lines, []);
  });
} finally {
  rmSync(dir, { recursive: true, force: true });
}

console.log(`\n${passed} passed${process.exitCode ? ', with failures' : ''}`);
