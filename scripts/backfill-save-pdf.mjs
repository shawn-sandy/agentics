#!/usr/bin/env node
/**
 * backfill-save-pdf.mjs — inject the Save as PDF button into existing HTML
 * plans that lack one.
 *
 * Contract (see kit/plugins/plan-agent/skills/implementation-plan/SKILL.md,
 * "HTML Output Requirements", and reference/SKELETON.html):
 *   - Button markup is inserted in the header immediately before the status
 *     badge (i.e. between the plan title and the badge).
 *   - The CSS block (with its own @media print hide and reduced-motion
 *     opt-out) is appended just before </style>; the savePDF() script is
 *     appended just before </body>. Both are self-contained, so no existing
 *     byte of the plan is modified (insertion-only).
 *   - Idempotent: plans that already contain save-pdf-btn are skipped.
 *   - No partial inserts: a plan is only updated when all three anchors
 *     (one status badge, one </style>, one </body>) resolve unambiguously;
 *     otherwise it is skipped and reported with a reason.
 *
 * Usage: node scripts/backfill-save-pdf.mjs [--dry-run] [--dir <path>] [--status <csv>]
 *   --dry-run   report what would happen without writing any file
 *   --dir       plans directory (default: docs/plans relative to repo root)
 *   --status    only touch plans whose plan-status is in this comma-separated
 *               list (e.g. --status todo or --status todo,in-progress);
 *               default: all statuses
 */

import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, basename } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const DEFAULT_DIR = join(fileURLToPath(new URL('..', import.meta.url)), 'docs', 'plans');

const BUTTON_MARKUP =
  '      <button class="save-pdf-btn" type="button" onclick="savePDF()"\n' +
  '              aria-label="Save this plan as PDF">Save as PDF</button>\n';

const CSS_BLOCK = `
  /* ── Save as PDF button (backfilled) ──────────────────────────── */
  .save-pdf-btn {
    display: inline-flex;
    align-items: center;
    gap: .4rem;
    padding: .4rem 1rem;
    font-size: .8rem;
    font-weight: 600;
    color: #fff;
    background: var(--accent, #2563eb);
    border: 1px solid var(--accent, #2563eb);
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
    line-height: 1.4;
    white-space: nowrap;
    flex-shrink: 0;
    margin-top: .15rem;
    transition: filter .15s, box-shadow .15s;
  }
  .save-pdf-btn:hover { filter: brightness(.85); box-shadow: 0 2px 6px rgba(0,0,0,.2); }
  .save-pdf-btn:active { filter: brightness(.75); }
  .save-pdf-btn:focus-visible { outline: 3px solid var(--accent, #2563eb); outline-offset: 2px; }
  @media (prefers-reduced-motion: reduce) { .save-pdf-btn { transition: none; } }
  @media print { .save-pdf-btn { display: none !important; } }
`;

const SCRIPT_BLOCK =
  '<script>\n' +
  '/* Save as PDF (native browser print dialog) — backfilled */\n' +
  'function savePDF() {\n' +
  '  window.print();\n' +
  '}\n' +
  '</script>\n';

export function hasButton(html) {
  return html.includes('save-pdf-btn');
}

export function planStatus(html) {
  const meta = html.match(/<meta name="plan-status" content="([^"]*)"/);
  if (meta) return meta[1];
  const attr = html.match(/<html[^>]*\bdata-status="([^"]*)"/);
  return attr ? attr[1] : null;
}

function countOccurrences(html, needle) {
  return html.split(needle).length - 1;
}

/**
 * Returns { html } on success or { reason } when the plan cannot be updated
 * unambiguously. Insertion-only: every existing byte is preserved.
 */
export function inject(html) {
  if (hasButton(html)) return { reason: 'already has save-pdf-btn' };

  const badgeAnchor = '<span class="status-badge"';
  if (countOccurrences(html, badgeAnchor) !== 1) {
    return { reason: `expected exactly 1 status badge, found ${countOccurrences(html, badgeAnchor)}` };
  }
  if (countOccurrences(html, '</style>') !== 1) return { reason: 'expected exactly 1 </style>' };
  if (countOccurrences(html, '</body>') !== 1) return { reason: 'expected exactly 1 </body>' };

  // The badge line carries its own indentation; insert the button on the
  // line above it. Walk back to the start of the badge's line so the markup
  // lands before the indentation, not inside it.
  const badgeIdx = html.indexOf(badgeAnchor);
  const lineStart = html.lastIndexOf('\n', badgeIdx) + 1;
  let out = html.slice(0, lineStart) + BUTTON_MARKUP + html.slice(lineStart);

  out = out.replace('</style>', `${CSS_BLOCK}</style>`);
  out = out.replace('</body>', `${SCRIPT_BLOCK}</body>`);
  return { html: out };
}

function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const dirIdx = args.indexOf('--dir');
  const dir = dirIdx !== -1 ? args[dirIdx + 1] : DEFAULT_DIR;
  const statusIdx = args.indexOf('--status');
  const statuses = statusIdx !== -1 ? args[statusIdx + 1].split(',').map((s) => s.trim()) : null;

  const files = readdirSync(dir)
    .filter((f) => f.endsWith('.html') && f !== 'index.html')
    .sort();

  let updated = 0, already = 0, filtered = 0;
  const skipped = [];

  for (const f of files) {
    const path = join(dir, f);
    const html = readFileSync(path, 'utf8');

    if (statuses && !statuses.includes(planStatus(html))) {
      filtered += 1;
      continue;
    }
    const result = inject(html);
    if (result.reason) {
      if (result.reason.startsWith('already')) already += 1;
      else skipped.push(`${f} — ${result.reason}`);
      continue;
    }
    if (!dryRun) writeFileSync(path, result.html);
    console.log(`${dryRun ? '[dry-run] would update' : 'updated'} ${f}`);
    updated += 1;
  }

  console.log(
    `\n${updated} updated, ${already} already had the button, ` +
    `${filtered} filtered by status, ${skipped.length} skipped`,
  );
  for (const s of skipped) console.log(`  SKIP ${s}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
