// Loading a mod from a folder you own (`claude --plugin-dir`, hot reload) makes
// the engine lay its API types beside it in `.claude-plugin/types/`, including
// `claude-code-mcp/index.d.ts`, which names this machine's connected MCP tools.
// git never ships it (the folder carries its own `*` .gitignore), but
// build-dist walks the working tree and KEEPs `.claude-plugin`, so only a
// DROP pattern stops a local dist build from publishing it.
//
// build-dist.mjs runs on import, so its DROP_PATTERNS array is evaluated from
// source and its predicates are exercised directly.

import { readFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const src = readFileSync(join(ROOT, 'scripts', 'build-dist.mjs'), 'utf8');
const start = src.indexOf('const DROP_PATTERNS = [');
const end = src.indexOf('\n];', start) + 3;
const DROP_PATTERNS = new Function('basename', `${src.slice(start, end)}\nreturn DROP_PATTERNS;`)(basename);
const dropped = (rel) => DROP_PATTERNS.some((p) => p.test(rel));

let fail = 0;
function check(name, cond) {
  console.log(`${cond ? 'PASS' : 'FAIL'}: ${name}`);
  if (!cond) fail++;
}

check('engine API types are dropped', dropped('.claude-plugin/types/claude-code/index.d.ts'));
check('engine MCP tool types are dropped', dropped('.claude-plugin/types/claude-code-mcp/index.d.ts'));
check("the types folder's own .gitignore is dropped", dropped('.claude-plugin/types/.gitignore'));
check('plugin.json still ships', !dropped('.claude-plugin/plugin.json'));
check('the hooks module still ships', !dropped('hooks/register.tsx'));
check("a plugin's own hooks/types folder still ships", !dropped('hooks/types/index.d.ts'));

if (fail > 0) process.exit(1);
