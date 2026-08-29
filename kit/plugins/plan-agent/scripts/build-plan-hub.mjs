#!/usr/bin/env node
/**
 * build-plan-hub.mjs — bundle a plan spec and its related HTML documents into
 * one self-contained tabbed hub page, publishable as a single claude.ai
 * artifact (the publish-hub skill's engine).
 *
 * The artifact CSP forbids fetching anything external, so every related
 * document rides whole inside the hub: each one becomes an `<iframe srcdoc>`
 * panel — uniform isolation, so the plan's CSS/JS never collides with the
 * shell or a prototype, and prototypes keep their inlined JavaScript. The
 * plan itself is rendered through build-plan-html.mjs (spawned as a CLI so
 * its output is exactly what plan-agent-render produces), related documents
 * come from the spec's `prototype:` frontmatter key plus explicit --extra
 * paths, and a `design:` URL becomes an external-link tab — it is already
 * its own artifact, and the CSP blocks framing it anyway.
 *
 * srcdoc escaping is deliberately minimal: `&` then `"` only. The browser
 * un-escapes the attribute value once before parsing it as a document, so
 * escaping `<`/`>` (as esc() does) would turn the embedded markup into text.
 *
 * Usage: node scripts/build-plan-hub.mjs <spec.md> [-o <hub.html>]
 *          [--extra <path>]... [--skip <path>]... [--max-bytes <n>]
 * Exit:  0 on success; 1 on an unreadable spec/related file, a renderer
 *        failure, or a size-cap overflow (stderr names the offending file);
 *        2 on misuse.
 */

import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, isAbsolute, resolve } from 'node:path';
import { join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

import { ParseError, parseSpecMarkdown } from './lib/plan-spec.mjs';
import { esc } from './build-plan-html.mjs';

const RENDERER = fileURLToPath(new URL('./build-plan-html.mjs', import.meta.url));

// 15 MB by default — under the 16 MB artifact page limit, leaving headroom
// for the publish-time skeleton wrap.
export const DEFAULT_MAX_BYTES = 15 * 1024 * 1024;

/**
 * Escape a document for use as an `<iframe srcdoc>` attribute value.
 * `&` first (so existing entities double-escape and survive the browser's
 * single un-escape), then `"` (the only character that can end the
 * double-quoted attribute). Nothing else — see the header comment.
 */
export function escSrcdoc(s) {
  return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;');
}

/** Kebab/snake file stem → a human tab label ("plan-document-redesign" → "Plan document redesign"). */
export function tabLabel(path) {
  const stem = basename(path).replace(/\.[^.]*$/, '').replace(/[-_]+/g, ' ').trim();
  return stem ? stem[0].toUpperCase() + stem.slice(1) : basename(path);
}

/**
 * Assemble the hub page. `docs` is `[{ label, html }]` (plan first);
 * `designUrl` is an already-validated http(s) URL or ''.
 */
export function buildHubHtml({ title, docs, designUrl }) {
  const tabs = [];
  const panels = [];
  docs.forEach((doc, i) => {
    const on = i === 0;
    tabs.push(
      `<button class="tab" id="tab-${i}" role="tab" aria-selected="${on}" aria-controls="panel-${i}" tabindex="${on ? 0 : -1}">${esc(doc.label)}</button>`,
    );
    panels.push(
      `<section class="panel" id="panel-${i}" role="tabpanel" aria-label="${esc(doc.label)}"${on ? '' : ' hidden'}>
      <iframe title="${esc(doc.label)}" srcdoc="${escSrcdoc(doc.html)}"></iframe>
    </section>`,
    );
  });
  const designTab = designUrl
    ? `<a class="tab tab-external" href="${esc(designUrl)}" target="_blank" rel="noopener">Design &#8599;</a>`
    : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<style>
  :root {
    --bg: #f4f6f9;
    --panel: #ffffff;
    --text: #1c2430;
    --muted: #5b6675;
    --line: #d9dee6;
    --accent: #2563eb;
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) {
      --bg: #10151c;
      --panel: #171e27;
      --text: #e6ebf2;
      --muted: #9aa7b5;
      --line: #2a3441;
      --accent: #7aa2f7;
    }
  }
  :root[data-theme="dark"] {
    --bg: #10151c;
    --panel: #171e27;
    --text: #e6ebf2;
    --muted: #9aa7b5;
    --line: #2a3441;
    --accent: #7aa2f7;
  }
  * { box-sizing: border-box; }
  html, body { height: 100%; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--text);
    font: 15px/1.4 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    display: flex;
    flex-direction: column;
  }
  header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex-wrap: wrap;
    padding: 0.5rem 0.75rem 0;
    border-bottom: 1px solid var(--line);
  }
  .hub-title {
    font-size: 0.85rem;
    font-weight: 600;
    color: var(--muted);
    margin: 0 0.5rem 0.5rem 0;
    max-width: 40ch;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .tabs { display: flex; gap: 0.25rem; flex-wrap: wrap; }
  .tab {
    appearance: none;
    background: none;
    border: 0;
    border-bottom: 2px solid transparent;
    color: var(--muted);
    font: inherit;
    padding: 0.4rem 0.75rem;
    cursor: pointer;
    text-decoration: none;
  }
  .tab[aria-selected="true"] {
    color: var(--text);
    border-bottom-color: var(--accent);
  }
  .tab:hover, .tab:focus-visible { color: var(--text); }
  main { flex: 1; min-height: 0; }
  .panel { height: 100%; }
  .panel iframe {
    display: block;
    width: 100%;
    height: 100%;
    border: 0;
    background: var(--panel);
  }
</style>
</head>
<body>
<header>
  <p class="hub-title">${esc(title)}</p>
  <nav class="tabs" role="tablist" aria-label="Plan documents">
    ${tabs.join('\n    ')}
    ${designTab}
  </nav>
</header>
<main>
  ${panels.join('\n  ')}
</main>
<script>
  (function () {
    var tabs = Array.prototype.slice.call(document.querySelectorAll('[role="tab"]'));
    function select(tab) {
      tabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute('aria-selected', on ? 'true' : 'false');
        t.tabIndex = on ? 0 : -1;
        document.getElementById(t.getAttribute('aria-controls')).hidden = !on;
      });
      tab.focus();
    }
    tabs.forEach(function (t, i) {
      t.addEventListener('click', function () { select(t); });
      t.addEventListener('keydown', function (e) {
        var d = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
        if (d) select(tabs[(i + d + tabs.length) % tabs.length]);
      });
    });
  })();
</script>
</body>
</html>
`;
}

function usage() {
  console.error(
    'Usage: node scripts/build-plan-hub.mjs <spec.md> [-o <hub.html>] [--extra <path>]... [--skip <path>]... [--max-bytes <n>]',
  );
}

function main() {
  const argv = process.argv.slice(2);
  let specPath = null;
  let outPath = null;
  let maxBytes = DEFAULT_MAX_BYTES;
  const extras = [];
  const skips = [];
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (a === '-o' || a === '--output') outPath = argv[(i += 1)];
    else if (a === '--extra') extras.push(argv[(i += 1)]);
    else if (a === '--skip') skips.push(argv[(i += 1)]);
    else if (a === '--max-bytes') maxBytes = Number(argv[(i += 1)]);
    else if (a.startsWith('-')) specPath = undefined; // unknown flag → misuse
    else if (specPath === null) specPath = a;
    else specPath = undefined; // second positional → misuse
  }
  // A dash-leading value is a flag the user forgot to give a value to, never
  // a filename — without this, `-o --skip` silently wrote the hub to a file
  // literally named `--skip` and dropped the flag.
  const flagLike = (v) => typeof v === 'string' && v.startsWith('-');
  if (
    !specPath ||
    flagLike(outPath) ||
    extras.includes(undefined) ||
    extras.some(flagLike) ||
    skips.includes(undefined) ||
    skips.some(flagLike) ||
    outPath === '' ||
    !Number.isFinite(maxBytes) ||
    maxBytes <= 0
  ) {
    usage();
    process.exit(2);
  }
  if (!outPath) outPath = specPath.replace(/\.md$/, '') + '-hub.html';
  if (resolve(outPath) === resolve(specPath)) {
    console.error('build-plan-hub: output path must differ from the input spec');
    process.exit(2);
  }

  let md;
  try {
    md = readFileSync(specPath, 'utf8');
  } catch (err) {
    console.error(`build-plan-hub: cannot read ${specPath}: ${err.message}`);
    process.exit(1);
  }

  let parsed;
  try {
    parsed = parseSpecMarkdown(md);
  } catch (err) {
    if (!(err instanceof ParseError)) throw err;
    console.error(`build-plan-hub: ${specPath} is not a parseable plan spec — ${err.message}`);
    process.exit(1);
  }
  const { metadata, sections } = parsed;

  // Render the plan through the sibling renderer CLI so the Plan tab is
  // byte-for-byte what plan-agent-render emits (same defaults, same guards).
  const tmp = mkdtempSync(join(tmpdir(), 'plan-hub-'));
  let planHtml;
  try {
    execFileSync('node', [RENDERER, specPath, '-o', join(tmp, 'plan.html')], { stdio: ['ignore', 'ignore', 'inherit'] });
    planHtml = readFileSync(join(tmp, 'plan.html'), 'utf8');
  } catch {
    console.error(`build-plan-hub: rendering ${specPath} failed`);
    process.exit(1);
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }

  // Related documents: the `prototype:` key (a repo-relative path) plus each
  // --extra. Non-absolute paths resolve against the cwd first — the repo
  // root in normal use — then against the spec's directory, so fixture specs
  // sitting beside their prototypes keep working.
  const specDir = dirname(resolve(specPath));
  const locate = (p) => {
    const candidates = isAbsolute(p) ? [p] : [resolve(p), resolve(specDir, p)];
    return candidates.find((c) => existsSync(c)) || null;
  };
  const skipSet = new Set(skips.flatMap((p) => [p, ...(isAbsolute(p) ? [p] : [resolve(p), resolve(specDir, p)])]));
  const isSkipped = (p) => skipSet.has(p) || skipSet.has(locate(p) || p);

  const related = [];
  const wanted = [];
  if (metadata.prototype) wanted.push({ path: metadata.prototype, label: 'Prototype' });
  for (const p of extras) wanted.push({ path: p, label: tabLabel(p) });
  for (const w of wanted) {
    if (isSkipped(w.path)) {
      console.log(`build-plan-hub: skipped ${w.path}`);
      continue;
    }
    const at = locate(w.path);
    if (at === null) {
      console.error(`build-plan-hub: cannot read ${w.path}: no such file`);
      process.exit(1);
    }
    let html;
    try {
      html = readFileSync(at, 'utf8');
    } catch (err) {
      console.error(`build-plan-hub: cannot read ${w.path}: ${err.message}`);
      process.exit(1);
    }
    related.push({ ...w, html, escapedBytes: Buffer.byteLength(escSrcdoc(html)) });
  }

  // Same guard shape as the renderer's issue:/design: keys — a non-http(s)
  // design is warned about and dropped, never framed or linked.
  const designRaw = (metadata.design || '').trim();
  const designUrl = /^https?:\/\//i.test(designRaw) ? designRaw : '';
  if (designRaw && !designUrl) console.warn(`  ! ${basename(specPath)}: ignoring non-http(s) design: ${designRaw}`);

  const docs = [{ label: 'Plan', html: planHtml }, ...related];
  const hub = buildHubHtml({ title: sections.title, docs, designUrl });

  const total = Buffer.byteLength(hub);
  if (total > maxBytes) {
    // Compare the plan's own escaped size too — naming a small related file
    // when the plan is the real bulk would send the skill's --skip retry
    // chasing bytes that cannot close the gap.
    const planEscaped = Buffer.byteLength(escSrcdoc(planHtml));
    const biggest = related.length > 0 ? related.reduce((a, b) => (b.escapedBytes > a.escapedBytes ? b : a)) : null;
    if (biggest && biggest.escapedBytes > planEscaped) {
      console.error(
        `build-plan-hub: output is ${total} bytes, over the ${maxBytes}-byte cap — largest embedded file: ${biggest.path} (${biggest.escapedBytes} bytes escaped); rerun with --skip ${biggest.path}`,
      );
    } else {
      console.error(
        `build-plan-hub: output is ${total} bytes, over the ${maxBytes}-byte cap — the rendered plan itself is the largest embedded document (${planEscaped} bytes escaped; ${specPath}); shrink the plan or raise --max-bytes`,
      );
    }
    process.exit(1);
  }

  writeFileSync(outPath, hub);
  console.log(`build-plan-hub: wrote ${outPath} (${total} bytes, ${docs.length + (designUrl ? 1 : 0)} tabs)`);
}

// Entry gate mirrors build-plan-html.mjs: run the CLI only when executed
// directly, so importing escSrcdoc/buildHubHtml has no side effects.
const entry = (() => {
  try {
    return process.argv[1] ? pathToFileURL(realpathSync(process.argv[1])).href : null;
  } catch {
    return null;
  }
})();
if (entry === import.meta.url) {
  main();
}
