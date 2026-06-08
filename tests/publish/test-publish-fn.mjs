import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..', '..');
const src = readFileSync(join(ROOT, 'scripts', 'build-dist.mjs'), 'utf8');

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

check("execSync import", src.includes("from 'node:child_process'"));
check("publish() defined", src.includes('function publish()'));
check("DIST_REPO_URL read", src.includes('DIST_REPO_URL'));
check("DIST_REPO_TOKEN read", src.includes('DIST_REPO_TOKEN'));
check("x-access-token injection", src.includes('x-access-token'));
check("git clone depth", src.includes('--depth=1'));
check("allow-empty commit", src.includes('--allow-empty'));
check(".dist-checkout cleanup", src.includes('.dist-checkout'));
check("stub removed", !src.includes('are not yet implemented'));

console.log(`\n${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
