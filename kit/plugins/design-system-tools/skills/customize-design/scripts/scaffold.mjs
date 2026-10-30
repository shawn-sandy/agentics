#!/usr/bin/env node
/**
 * Scaffold the seven-token direction for a project that has no design tokens yet, so that
 * customize-design has something to rebrand.
 *
 * Usage: scaffold.mjs --accent <#hex> [--out <dir>] [--name <name>] [--design-md <path>]
 *   --accent     the brand colour (required)
 *   --out        where tokens.css goes (default src/styles)
 *   --name       the design system's name (default: the current folder's name)
 *   --design-md  where the starter spec goes (default DESIGN.md in the current directory)
 *
 * The light accent is the brand colour darkened toward black in 2% steps until it clears
 * 4.5:1 on paper, on sunk paper and on its own wash. The dark accent is the brand colour
 * lightened toward white until it clears 4.5:1 on the dark paper, sunk paper and wash.
 * The wash is the ORIGINAL brand colour at 8% over each theme's paper, so a colour too light
 * for text still shows as itself behind hover fills. The neutrals are the OnCue values.
 *
 * Never overwrites: an existing tokens.css or DESIGN.md stops the run before anything is
 * written. Exits 2 on a bad option or an existing file. Only `node:` modules.
 */
import { existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { FLOOR, PAIRS, ratio, report } from './contrast.mjs';

const TEMPLATES = fileURLToPath(new URL('../templates/', import.meta.url));

export const NEUTRALS = {
  light: { ink: '#000000', 'ink-soft': '#606060', paper: '#ffffff', 'paper-sunk': '#f0f0f0', rule: '#dedede' },
  dark: { ink: '#f2f2f2', 'ink-soft': '#a3a3a3', paper: '#111111', 'paper-sunk': '#1c1c1c', rule: '#2e2e2e' },
};

const toRgb = (h) => {
  const x = h.length === 4 ? [...h.slice(1)].map((c) => c + c).join('') : h.slice(1);
  return [0, 2, 4].map((i) => parseInt(x.slice(i, i + 2), 16));
};
const toHex = (rgb) => `#${rgb.map((v) => Math.round(Math.min(255, Math.max(0, v))).toString(16).padStart(2, '0')).join('')}`;
/** `a` mixed `t` (0..1) of the way toward `b`. */
export const mix = (a, b, t) => toHex(toRgb(a).map((v, i) => v + (toRgb(b)[i] - v) * t));

/** Step `brand` toward `toward` in 2% steps until `ok(candidate)`; `steps` is how many it took. */
function derive(brand, toward, ok) {
  for (let steps = 0; steps <= 50; steps += 1) {
    const value = mix(brand, toward, steps * 0.02);
    if (ok(value)) return { value, steps };
  }
  throw new Error(`could not derive an accent from ${brand} that clears ${FLOOR}:1`);
}

/** The seven tokens per theme derived from one brand colour, plus how far each accent moved. */
export function deriveTokens(brand) {
  const out = {};
  const steps = {};
  for (const [theme, toward] of [['light', '#000000'], ['dark', '#ffffff']]) {
    const n = NEUTRALS[theme];
    const wash = mix(n.paper, brand, 0.08);
    const grounds = [n.paper, n['paper-sunk'], wash];
    const accent = derive(brand, toward, (c) => grounds.every((g) => ratio(c, g) >= FLOOR));
    out[theme] = { ...n, island: accent.value, 'island-bg': wash };
    steps[theme] = accent.steps;
  }
  return { ...out, steps };
}

function fill(template, values) {
  const text = template.replace(/\{\{([\w-]+)\}\}/g, (m, key) => {
    if (!(key in values)) throw new Error(`template placeholder ${m} has no value`);
    return values[key];
  });
  return text;
}

function parseArgs(argv) {
  const opts = {};
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (!/^--(accent|out|name|design-md)$/.test(a)) throw new Error(`unknown option "${a}"`);
    if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
    opts[a.slice(2)] = argv[i + 1];
    i += 1;
  }
  if (!/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(opts.accent ?? '')) throw new Error('--accent needs an opaque hex colour such as #185c53');
  // The name lands unquoted in YAML and inside a CSS comment: letters, digits, space, . & ' - only.
  if (opts.name !== undefined && !/^[\w][\w .&'-]*$/.test(opts.name)) throw new Error("--name may hold letters, digits, spaces and . & ' - only");
  return opts;
}

const USAGE = 'usage: scaffold.mjs --accent <#hex> [--out <dir>] [--name <name>] [--design-md <path>]';

export function main(argv, cwd = process.cwd()) {
  try {
    const opts = parseArgs(argv);
    const brand = opts.accent.toLowerCase();
    const outDir = resolve(cwd, opts.out ?? 'src/styles');
    const tokensPath = join(outDir, 'tokens.css');
    const designPath = resolve(cwd, opts['design-md'] ?? 'DESIGN.md');
    const name = opts.name ?? basename(cwd);
    for (const p of [tokensPath, designPath]) {
      if (existsSync(p)) throw new Error(`${p} already exists; nothing was written. Move it aside or rebrand it with customize-design.`);
    }

    const tokens = deriveTokens(brand);
    const values = { name, brand, date: new Date().toISOString().slice(0, 10), 'tokens-path': relative(dirname(designPath), tokensPath) };
    for (const theme of ['light', 'dark']) {
      for (const [k, v] of Object.entries(tokens[theme])) values[`${k}-${theme}`] = v;
      values[`ratios-${theme}`] = PAIRS.map(([fg, bg]) => `${fg}/${bg} ${ratio(tokens[theme][fg], tokens[theme][bg]).toFixed(2)}`).join(', ');
    }
    values['ratio-table'] = PAIRS.map(([fg, bg, where]) =>
      `| ${fg} on ${bg} | ${ratio(tokens.light[fg], tokens.light[bg]).toFixed(2)}:1 | ${ratio(tokens.dark[fg], tokens.dark[bg]).toFixed(2)}:1 | ${where} |`,
    ).join('\n');

    const css = fill(readFileSync(join(TEMPLATES, 'tokens.css'), 'utf8'), values);
    const md = fill(readFileSync(join(TEMPLATES, 'DESIGN.md'), 'utf8'), values);
    mkdirSync(outDir, { recursive: true });
    mkdirSync(dirname(designPath), { recursive: true });
    writeFileSync(tokensPath, css);
    writeFileSync(designPath, md);

    const moved = (theme, verb) =>
      tokens.steps[theme]
        ? `${verb} ${brand} by ${tokens.steps[theme]} steps of 2% to ${tokens[theme].island} so it reads ${FLOOR}:1 in ${theme}; the wash keeps the original.`
        : `${brand} already reads ${FLOOR}:1 in ${theme}, so it is the ${theme} accent as is.`;
    console.log(`Wrote ${tokensPath}\nWrote ${designPath}\n${moved('light', 'Darkened')}\n${moved('dark', 'Lightened')}\n`);
    console.log(report({ light: tokens.light, dark: tokens.dark }, PAIRS).lines.join('\n'));
    return 0;
  } catch (error) {
    console.error(`${error.message}\n${USAGE}`);
    return 2;
  }
}

// Compared as real paths: `import.meta.url` is already resolved, `argv[1]` may be a symlink.
if (process.argv[1] && fileURLToPath(import.meta.url) === realpathSync(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}
