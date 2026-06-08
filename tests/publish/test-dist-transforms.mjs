// Verifies that build-dist.mjs correctly rewrites URLs in the dist README
// and plugin.json files. Run after `node scripts/build-dist.mjs`.

import { readFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..');
const DIST = join(ROOT, 'dist');

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

if (!existsSync(DIST)) {
  console.error('No dist/ directory — run `node scripts/build-dist.mjs` first.');
  process.exit(1);
}

// ── README transforms ──────────────────────────────────────────────────────

const readme = readFileSync(join(DIST, 'README.md'), 'utf8');

// Changed: install / clone directions point to agentics-kit
check('README: Quick Start clone uses agentics-kit',
  readme.includes('git clone https://github.com/shawn-sandy/agentics-kit.git'));

check('README: Quick Start cd uses agentics-kit',
  readme.includes('\ncd agentics-kit\n'));

check('README: Install section marketplace add uses agentics-kit',
  readme.includes('/plugin marketplace add shawn-sandy/agentics-kit'));

check('README: settings.json repo uses agentics-kit',
  readme.includes('"repo": "shawn-sandy/agentics-kit"'));

check('README: heads-up note marketplace add uses agentics-kit',
  readme.includes('run `/plugin marketplace add shawn-sandy/agentics-kit`'));

// Preserved: dev-repo references that must NOT change
check('README: bug report URL still points to agentics',
  readme.includes('[GitHub Issue](https://github.com/shawn-sandy/agentics/issues/new)'));

check('README: Contributing JSON url still points to agentics',
  readme.includes('"url": "https://github.com/shawn-sandy/agentics.git"'));

check('README: Distribution section still mentions agentics as dev repo',
  readme.includes('`shawn-sandy/agentics` | Development workspace'));

// No raw agentics clone commands remain
check('README: no raw git clone to agentics.git',
  !readme.includes('git clone https://github.com/shawn-sandy/agentics.git'));

// ── plugin.json transforms ─────────────────────────────────────────────────

const PLUGIN_SAMPLE = join(DIST, 'kit', 'plugins', 'code-review', '.claude-plugin', 'plugin.json');

if (existsSync(PLUGIN_SAMPLE)) {
  const pjson = readFileSync(PLUGIN_SAMPLE, 'utf8');

  check('plugin.json: homepage points to agentics-kit',
    pjson.includes('"homepage": "https://github.com/shawn-sandy/agentics-kit/tree/'));

  check('plugin.json: repository points to agentics-kit',
    pjson.includes('"repository": "https://github.com/shawn-sandy/agentics-kit"'));

  check('plugin.json: no homepage pointing to plain agentics',
    !pjson.includes('shawn-sandy/agentics/tree/'));
} else {
  console.log('SKIP: code-review plugin.json not found in dist');
}

// ── Summary ────────────────────────────────────────────────────────────────

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
