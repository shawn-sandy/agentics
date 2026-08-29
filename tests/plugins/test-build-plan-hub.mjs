#!/usr/bin/env node
// The hub bundler's contract is what every publish-hub run depends on: one
// tabbed page embedding the rendered plan and each related document in its
// own <iframe srcdoc> panel, `&`/`"` escaped exactly once (the browser
// un-escapes srcdoc once — double-escaping renders entities as text, and
// escaping `<` would turn the whole document into text), a size cap that
// exits 1 naming the offending file so the skill can retry with --skip, and
// unreadable inputs that exit 1 naming the path.

import { existsSync, mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const BUNDLER = join(ROOT, 'kit', 'plugins', 'plan-agent', 'scripts', 'build-plan-hub.mjs');
const WRAPPER = join(ROOT, 'kit', 'plugins', 'plan-agent', 'bin', 'plan-agent-hub');
const TMP = mkdtempSync(join(tmpdir(), 'build-plan-hub-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) { console.log(`PASS: ${name}`); pass++; }
  else { console.log(`FAIL: ${name}${detail ? ` — ${detail}` : ''}`); fail++; }
}

const TITLE = 'Hub fixture plan';

// Quote-heavy on purpose: a raw `&`, a pre-escaped `&quot;`, single and
// double quotes in both attribute and script contexts.
const PROTO = `<!DOCTYPE html>
<html><head><title>Proto &amp; Friends</title></head>
<body data-x="a &quot;quoted&quot; value & raw amp">
<h1 id="msg">Loading...</h1>
<script>document.getElementById('msg').textContent = 'JS ran & said "hello"';</script>
</body></html>
`;

const SPEC = `---
status: todo
type: feature
created: 2026-08-26
repo: agentics
prototype: proto.html
design: https://example.com/canvas
---

# Plan: ${TITLE}

## Objective

Prove the hub bundler embeds a plan and its prototype into one tabbed page.

## Steps

1. Build the fixture. Why: something must exist. Verify: the file exists.

## Acceptance Criteria

- [ ] The hub contains both documents

## Verification

Open the hub and click both tabs.
`;

writeFileSync(join(TMP, 'proto.html'), PROTO);
writeFileSync(join(TMP, 'spec.md'), SPEC);
writeFileSync(join(TMP, 'extra.html'), '<!DOCTYPE html><html><body><p>companion page</p></body></html>\n');

const run = (args, opts = {}) => spawnSync('node', [BUNDLER, ...args], { encoding: 'utf8', cwd: TMP, ...opts });

// --- the happy path: plan + prototype + design link -------------------------

const built = run(['spec.md', '-o', 'hub.html']);
check('bundler exits 0 on a spec with a prototype: key', built.status === 0, built.stderr);
const hub = readFileSync(join(TMP, 'hub.html'), 'utf8');

check('hub carries the plan title', hub.includes(`<title>${TITLE}</title>`) && hub.includes(TITLE));

const panels = hub.match(/<section class="panel" id="panel-(\d+)"[^>]*>/g) || [];
check('plan and prototype land in separate tab panels', panels.length === 2 && hub.includes('id="panel-0"') && hub.includes('id="panel-1"'));
check('each panel embeds via iframe srcdoc', (hub.match(/srcdoc="/g) || []).length === 2);
check('tab bar lists Plan and Prototype', hub.includes('>Plan</button>') && hub.includes('>Prototype</button>'));

// Escaped exactly once: the raw `&` becomes `&amp;`, the pre-escaped
// `&quot;` becomes `&amp;quot;` — and neither is escaped a second time.
check('raw & escapes exactly once', hub.includes('value &amp; raw amp') && !hub.includes('value &amp;amp; raw amp'));
check('pre-escaped entity escapes exactly once', hub.includes('data-x=&quot;a &amp;quot;quoted&amp;quot;') && !hub.includes('&amp;amp;quot;'));
check('double quotes escape to &quot;', hub.includes(`said &quot;hello&quot;'`));
check('prototype markup keeps its script tag inside the panel', hub.includes(`<script>document.getElementById('msg')`));

// Round trip: decoding the srcdoc value once (the browser's un-escape) must
// reproduce the prototype byte-for-byte.
const srcdocs = [...hub.matchAll(/srcdoc="([^"]*)"/g)].map((m) => m[1]);
const decoded = srcdocs[1].replace(/&quot;/g, '"').replace(/&amp;/g, '&');
check('quote-heavy prototype survives the srcdoc round trip', decoded === PROTO, 'decoded srcdoc differs from the source prototype');

check('design: renders as an external-link tab, not an embed', hub.includes('tab-external" href="https://example.com/canvas"'));

// --- --extra and --skip -----------------------------------------------------

const withExtra = run(['spec.md', '-o', 'hub-extra.html', '--extra', 'extra.html']);
const hubExtra = withExtra.status === 0 ? readFileSync(join(TMP, 'hub-extra.html'), 'utf8') : '';
check('--extra adds a third panel', withExtra.status === 0 && (hubExtra.match(/srcdoc="/g) || []).length === 3 && hubExtra.includes('>Extra</button>'));

const skipped = run(['spec.md', '-o', 'hub-skip.html', '--skip', 'proto.html']);
check('--skip drops the named file and reports it', skipped.status === 0 && skipped.stdout.includes('skipped proto.html') && (readFileSync(join(TMP, 'hub-skip.html'), 'utf8').match(/srcdoc="/g) || []).length === 1);

// --- guard exits ------------------------------------------------------------

const missingSpec = run(['nope.md', '-o', 'x.html']);
check('missing spec exits 1 naming the path', missingSpec.status === 1 && missingSpec.stderr.includes('nope.md'));

const missingExtra = run(['spec.md', '-o', 'x.html', '--extra', 'gone.html']);
check('missing related file exits 1 naming the path', missingExtra.status === 1 && missingExtra.stderr.includes('gone.html'));

// The rendered plan (~95 KB) dwarfs the 300-byte prototype here, so the
// overflow message must blame the plan — a `--skip proto.html` hint would
// tell the user to drop a file whose removal cannot close the gap.
const overflow = run(['spec.md', '-o', 'x.html', '--max-bytes', '50000']);
check('overflow names the plan when the plan is the largest document', overflow.status === 1 && overflow.stderr.includes('spec.md') && !overflow.stderr.includes('--skip proto.html'));

writeFileSync(join(TMP, 'big.html'), `<!DOCTYPE html><html><body>${'x'.repeat(300000)}</body></html>\n`);
const overflowBig = run(['spec.md', '-o', 'x.html', '--extra', 'big.html', '--max-bytes', '150000']);
check('overflow names the largest related file with a --skip hint', overflowBig.status === 1 && overflowBig.stderr.includes('--skip big.html'));

const misuse = run([]);
check('no spec path is misuse (exit 2)', misuse.status === 2);

// A flag token must never be consumed as a value: `-o --skip` used to write
// a hub to a file literally named `--skip` and silently drop the flag.
const flagAsOutput = run(['spec.md', '-o', '--skip']);
check('flag-shaped -o value is misuse, not an output file', flagAsOutput.status === 2 && !existsSync(join(TMP, '--skip')));

const flagAsSkip = run(['spec.md', '-o', 'x2.html', '--skip', '--max-bytes']);
check('flag-shaped --skip value is misuse (exit 2)', flagAsSkip.status === 2);

const unknownFlag = run(['--bogus', 'spec.md', '-o', 'x3.html']);
check('unknown flag is misuse (exit 2), not a spec path', unknownFlag.status === 2);

// --- the bin wrapper --------------------------------------------------------

const viaWrapper = spawnSync(WRAPPER, ['spec.md', '-o', 'hub-wrapper.html'], { encoding: 'utf8', cwd: TMP });
check('bin/plan-agent-hub output is byte-identical to the .mjs', viaWrapper.status === 0 && readFileSync(join(TMP, 'hub-wrapper.html'), 'utf8') === hub);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
