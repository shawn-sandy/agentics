// Pins the artifact title mechanism: only an HTML <title> sets an artifact's
// title. A Markdown source falls back to its filename, so any artifact-tools
// skill that publishes must publish HTML. The opposite claim shipped in 1.1.0
// and made every session recap title wrong; these assertions stop it returning.

import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PLUGIN = join(__dirname, '..', '..', 'kit', 'plugins', 'artifact-tools');
const read = (...p) => readFileSync(join(PLUGIN, ...p), 'utf8');

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

const titles = read('references', 'titles.md');

check(
  'titles.md states a Markdown source cannot set its own title',
  /Markdown source\s*\n?\s*cannot set its own title/i.test(titles.replace(/\*\*/g, '')),
);

check(
  'titles.md does not tell authors to set the title via frontmatter',
  !/as frontmatter `title:` for\s*\n?Markdown sources/i.test(titles),
);

check(
  'titles.md names the filename fallback',
  /falls back to the source's filename/i.test(titles),
);

const SKILLS = ['diff-artifact', 'plan-artifact', 'prompt-artifact', 'session-artifact'];

for (const s of SKILLS) {
  const body = read('skills', s, 'SKILL.md');
  check(`${s} points at the shared title rules`, body.includes('references/titles.md'));
}

const session = read('skills', 'session-artifact', 'SKILL.md');

check(
  'session-artifact publishes the HTML render, not the .md',
  /Publish the \*\*HTML\*\* path/.test(session),
);

check(
  'session-artifact no longer claims Markdown publishes directly',
  !/publishes the Markdown\s*\n?directly/.test(session),
);

check(
  'session-artifact requires url: on every republish',
  /required on every republish/i.test(session),
);

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
