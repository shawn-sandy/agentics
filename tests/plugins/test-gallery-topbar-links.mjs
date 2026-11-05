#!/usr/bin/env node
// Regression test: a gallery's topbar never links to a page that does not exist.
//
// Every plan-agent gallery generator substitutes the same five tab targets
// (Home, Plans, Prototypes, Artifacts, Social). A repo that only has
// docs/plans/ used to get four tabs pointing at index.html files nobody had
// built, so they 404ed. Each generator below is run in a temp project holding
// only its own collection, and every relative href in the output must resolve
// to a file on disk, while the page's own tab still renders as the current page.

import { mkdtempSync, mkdirSync, writeFileSync, copyFileSync, existsSync, readFileSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const HOOKS = join(ROOT, 'kit', 'plugins', 'plan-agent', 'hooks');
const TEMPLATES = join(ROOT, 'kit', 'plugins', 'plan-agent', 'templates');
const TMP = mkdtempSync(join(tmpdir(), 'gallery-topbar-'));
process.on('exit', () => rmSync(TMP, { recursive: true, force: true }));

const page = (title) =>
  `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>${title}</title></head><body><p>x</p></body></html>\n`;

const CASES = [
  {
    name: 'plans (hooks/build-index.sh)',
    script: join(HOOKS, 'build-index.sh'),
    seed: (p) => writeFileSync(join(p, 'docs', 'plans', 'only-plan.html'), page('Only plan')),
    out: 'docs/plans/index.html',
    currentTab: 'Plans',
  },
  {
    name: 'plans (scripts/build-plans-index.sh)',
    script: join(ROOT, 'scripts', 'build-plans-index.sh'),
    seed: (p) => writeFileSync(join(p, 'docs', 'plans', 'only-plan.html'), page('Only plan')),
    out: 'docs/plans/index.html',
    currentTab: 'Plans',
  },
  {
    name: 'prototypes',
    script: join(HOOKS, 'build-prototypes-index.sh'),
    seed: (p) => {
      mkdirSync(join(p, 'docs', 'prototypes'), { recursive: true });
      writeFileSync(join(p, 'docs', 'prototypes', 'only-proto.html'), page('Only prototype'));
    },
    out: 'docs/prototypes/index.html',
    currentTab: 'Prototypes',
  },
  {
    name: 'designs',
    script: join(HOOKS, 'build-designs-index.sh'),
    seed: (p) => {
      mkdirSync(join(p, 'docs', 'designs', 'only-canvas'), { recursive: true });
      writeFileSync(join(p, 'docs', 'designs', 'only-canvas', '01-home.dc.html'), page('Only canvas'));
    },
    out: 'docs/designs/index.html',
    currentTab: null, // the designs gallery has no tab of its own in the bar
  },
  {
    name: 'artifacts',
    script: join(HOOKS, 'build-artifacts-index.sh'),
    seed: (p) => {
      mkdirSync(join(p, '.claude', 'artifacts'), { recursive: true });
      writeFileSync(join(p, '.claude', 'artifacts', 'only-artifact.html'), page('Only artifact'));
    },
    out: 'docs/artifacts/index.html',
    currentTab: 'Artifacts',
  },
];

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log(`PASS: ${name}`);
    pass++;
  } else {
    console.log(`FAIL: ${name}${detail ? ` — ${detail}` : ''}`);
    fail++;
  }
}

for (const [i, c] of CASES.entries()) {
  const proj = join(TMP, `p${i}`);
  // docs/plans/ exists in every case: the designs and artifacts generators read
  // the plans count, and the plans generator exits early without it.
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  // A vendored template copy, so discovery never picks up an installed plugin.
  const tdir = join(proj, 'kit', 'plugins', 'plan-agent', 'templates');
  mkdirSync(tdir, { recursive: true });
  for (const t of ['plans-gallery.html', 'prototypes-gallery.html', 'designs-gallery.html']) {
    copyFileSync(join(TEMPLATES, t), join(tdir, t));
  }
  c.seed(proj);

  // HOME pinned to the temp project so the user-global ~/.claude/settings.json
  // plansDirectory cannot redirect the plans generator elsewhere.
  const r = spawnSync('bash', [c.script, proj], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, HOME: proj, CLAUDE_PLUGIN_ROOT: '' },
  });
  const outPath = join(proj, c.out);
  check(`${c.name}: writes ${c.out}`, r.status === 0 && existsSync(outPath), r.stderr);
  if (!existsSync(outPath)) continue;
  const html = readFileSync(outPath, 'utf8');

  check(`${c.name}: no unsubstituted {{HREF_*}} left`, !/\{\{HREF_/.test(html));

  const missing = [...html.matchAll(/href="([^"]*)"/g)]
    .map((m) => m[1])
    .filter((h) => h && !/^(?:[a-z]+:|#|\/\/)/i.test(h))
    .filter((h) => {
      const target = resolve(dirname(outPath), h.split(/[?#]/)[0]);
      // The page's own index is being written by this very run.
      return target !== outPath && !existsSync(target);
    });
  check(`${c.name}: every relative href resolves to a file`, missing.length === 0, `missing: ${missing.join(', ')}`);

  check(`${c.name}: brand mark is unlinked with no Home`, /<a class="mark">/.test(html));

  if (c.currentTab) {
    const cur = new RegExp(`<a href="index\\.html" aria-current="page">${c.currentTab}\\b`);
    check(`${c.name}: own tab still shown as the current page`, cur.test(html));
  }
}

// The other half: a collection that does exist keeps its tab. Without this, a
// generator that dropped every sibling tab would pass everything above.
{
  const proj = join(TMP, 'full');
  mkdirSync(join(proj, 'docs', 'plans'), { recursive: true });
  mkdirSync(join(proj, 'docs', 'prototypes'), { recursive: true });
  mkdirSync(join(proj, 'kit', 'plugins', 'plan-agent', 'templates'), { recursive: true });
  copyFileSync(join(TEMPLATES, 'plans-gallery.html'), join(proj, 'kit', 'plugins', 'plan-agent', 'templates', 'plans-gallery.html'));
  writeFileSync(join(proj, 'docs', 'plans', 'only-plan.html'), page('Only plan'));
  writeFileSync(join(proj, 'docs', 'index.html'), page('Home'));
  writeFileSync(join(proj, 'docs', 'prototypes', 'index.html'), page('Prototypes'));
  spawnSync('bash', [join(HOOKS, 'build-index.sh'), proj], {
    stdio: 'ignore',
    env: { ...process.env, HOME: proj, CLAUDE_PLUGIN_ROOT: '' },
  });
  const html = readFileSync(join(proj, 'docs', 'plans', 'index.html'), 'utf8');
  check('existing Home keeps its tab', /<a href="\.\.\/index\.html" >Home<\/a>/.test(html));
  check('existing Prototypes keeps its tab', /<a href="\.\.\/prototypes\/index\.html" >Prototypes/.test(html));
  check('brand mark links the existing Home', /<a class="mark" href="\.\.\/index\.html">/.test(html));
  check('missing Artifacts tab still dropped', !/>Artifacts</.test(html));
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
