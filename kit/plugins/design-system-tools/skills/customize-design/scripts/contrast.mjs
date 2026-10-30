#!/usr/bin/env node
/**
 * WCAG 2 contrast for a project's direction tokens, light and dark, read from whatever
 * file declares them: SCSS `direction-light` / `direction-dark` mixins, plain CSS under
 * `:root` and a dark scope, or a DESIGN.md frontmatter `colors:` map.
 *
 * Usage:
 *   contrast.mjs --tokens <file> [--pairs fg:bg,...] [--light-scope <text>] [--dark-scope <text>]
 *   contrast.mjs --design-md <DESIGN.md> [--pairs fg:bg,...]
 *   contrast.mjs '#fg:#bg' ['#fg:#bg' ...]
 *
 * A declaration `--name: value;` belongs to the theme of its enclosing blocks. Dark: a
 * mixin named `…-dark`, `prefers-color-scheme: dark`, or a class or attribute selector
 * containing "dark" (`.dark`, `.theme-dark`, `[data-theme="dark"]`, `[data-bs-theme=dark]`).
 * Light: a mixin named `…-light`, `:root`, `html`, or a class or attribute containing
 * "light". A `:not(...)` never decides (`:root:not([data-theme="dark"])` is light). A dark
 * ancestor wins over a light one, so `@media (prefers-color-scheme: dark) { :root { … } }`
 * is dark. `--light-scope` and `--dark-scope` replace those lists with one substring each.
 * Declarations under a block that is neither are ignored and named on stderr.
 *
 * With no `--pairs`, the eight text-on-ground pairs of the seven-token direction are
 * measured when `ink`, `ink-soft`, `island`, `island-bg`, `paper` and `paper-sunk` all exist.
 *
 * Exits 1 when a pair falls below 4.5:1 and 2 when something cannot be measured (a
 * missing token, an `hsl()`, `oklch()`, `var()` or translucent value, a malformed pair).
 * Ratios are floored to two decimals, so 4.499 never prints as a passing 4.50.
 * Only `node:` modules: the target project may have no node_modules.
 */
import { readFileSync, realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

export const FLOOR = 4.5;

/** Text-on-ground pairs the direction paints, foreground first, with where each one shows. */
export const PAIRS = [
  ['ink', 'paper', 'body copy'],
  ['ink-soft', 'paper', 'decks, eyebrows, captions'],
  ['island', 'paper', 'links, focus ring, Paper label on the primary button'],
  ['ink', 'paper-sunk', 'header band, cards, code blocks'],
  ['ink-soft', 'paper-sunk', 'captions on cards and in the header band'],
  ['island', 'paper-sunk', 'links in the header band and on cards'],
  ['island', 'island-bg', 'ghost button hover, active dashboard link'],
  ['ink', 'island-bg', '::selection'],
];

// A class or attribute selector whose name contains the word: `.dark`, `.theme-dark`,
// `[data-theme="dark"]`, `[data-bs-theme=dark]`. `:not(...)` groups are removed first.
// A Sass mixin whose name ends in -dark or -light (`direction-dark`, `legacy-palette-light`) too.
const DARK_SCOPES = [/@mixin\s+[\w-]*dark(?![\w-])/, /prefers-color-scheme:\s*dark/, /[.\[][^\]{]*?dark/];
const LIGHT_SCOPES = [/@mixin\s+[\w-]*light(?![\w-])/, /:root/, /(^|[\s,>+~])html(?![\w-])/, /[.\[][^\]{]*?light/];

/**
 * Drop block comments, and the Sass line comments that start a line or follow a `;`, `{` or
 * `}`, so a brace or declaration inside a comment can never open a scope or declare a token.
 * A `//` anywhere else is part of a value: `url(//cdn…)`, `url(https://…)`, a base64 data URI.
 */
export function stripComments(css) {
  return css
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/^[ \t]*\/\/.*$/gm, '')
    .replace(/([;{}])[ \t]*\/\/.*$/gm, '$1');
}

/**
 * Every `--name: value` declaration in `css`, assigned to a theme by its enclosing blocks:
 * `{ light: { name: value }, dark: { name: value } }`. A declaration under no themed block
 * is dropped and its block header pushed onto `ignored`. `scopes` holds a matcher per
 * theme: a RegExp list, or one substring.
 */
export function readThemes(css, scopes = {}, ignored = []) {
  const matches = (header, which) => {
    const m = scopes[which] ?? (which === 'dark' ? DARK_SCOPES : LIGHT_SCOPES);
    const h = header.replace(/:not\([^)]*\)/g, '');
    return typeof m === 'string' ? h.includes(m) : m.some((re) => re.test(h));
  };
  const themes = { light: {}, dark: {} };
  const stack = [];
  let buf = '';
  const flush = () => {
    const m = /^\s*--([\w-]+)\s*:\s*([\s\S]+?)\s*$/.exec(buf);
    buf = '';
    if (!m) return;
    // ponytail: a dark ancestor anywhere wins, then a light one; nesting deeper than that is not modelled
    const theme = stack.some((h) => matches(h, 'dark')) ? 'dark' : stack.some((h) => matches(h, 'light')) ? 'light' : null;
    if (theme) themes[theme][m[1]] = m[2];
    else if (stack.length && !ignored.includes(stack[stack.length - 1])) ignored.push(stack[stack.length - 1]);
  };
  for (const ch of stripComments(css)) {
    if (ch === '{') {
      stack.push(buf.replace(/\s+/g, ' ').trim());
      buf = '';
    } else if (ch === '}') {
      flush();
      stack.pop();
    } else if (ch === ';') {
      flush();
    } else {
      buf += ch;
    }
  }
  return themes;
}

/**
 * The `colors:` map of a DESIGN.md frontmatter as `{ name: value }`: the light theme.
 * CRLF, blank lines inside the map, trailing `# comments` and an unquoted `#hex` (a YAML
 * comment, strictly, but what people write) are all read.
 */
export function readDesignMd(markdown) {
  const front = /^---\n([\s\S]*?)\n---/.exec(markdown.replace(/\r\n?/g, '\n'));
  if (!front) throw new Error('DESIGN.md has no frontmatter');
  const lines = front[1].split('\n');
  const start = lines.findIndex((l) => /^colors:[ \t]*(#.*)?$/.test(l));
  if (start < 0) throw new Error('DESIGN.md frontmatter has no colors: map');
  const colors = {};
  for (const line of lines.slice(start + 1)) {
    if (/^\s*$/.test(line)) continue;
    if (!/^[ \t]/.test(line)) break;
    const m = /^[ \t]+([\w-]+):[ \t]*(?:'([^']*)'|"([^"]*)"|(#[0-9a-fA-F]{3,8})|([^#]*?))[ \t]*(?:#.*)?$/.exec(line);
    if (m) colors[m[1]] = (m[2] ?? m[3] ?? m[4] ?? m[5]).trim();
  }
  return colors;
}

function channels(color) {
  let m = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(color);
  if (m) {
    const hex = m[1].length === 3 ? [...m[1]].map((c) => c + c).join('') : m[1];
    return [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16));
  }
  m = /^rgb\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)\s*\)$/i.exec(color);
  if (m) {
    const rgb = m.slice(1).map(Number);
    // `!(n <= 255)` also catches NaN from a malformed number like `1.2.3`.
    if (rgb.some((n) => !(n <= 255))) throw new Error(`cannot measure "${color}": a channel is outside 0-255`);
    return rgb;
  }
  // ponytail: opaque hex and rgb() only; hsl()/oklch() conversion when a source uses them
  throw new Error(`cannot measure "${color}": use opaque hex or rgb(), or measure it by hand`);
}

function luminance(color) {
  const [r, g, b] = channels(color).map((v) => {
    const c = v / 255;
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** WCAG 2 contrast of two opaque colours, floored to two decimals. */
export function ratio(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return Math.floor(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
}

/**
 * One line per pair with every theme's ratio; `failed` is true if any is under 4.5:1.
 * `themes` is `{ light: {name: value}, dark: {…} }`; a theme with no tokens is skipped.
 */
export function report(themes, pairs) {
  const present = Object.entries(themes).filter(([, tokens]) => Object.keys(tokens).length);
  let failed = false;
  const lines = pairs.map(([fg, bg, where = '']) => {
    const cells = present.map(([theme, tokens]) => {
      for (const name of [fg, bg]) {
        if (!tokens[name]) throw new Error(`--${name} is not declared for the ${theme} theme`);
      }
      const value = ratio(tokens[fg], tokens[bg]);
      if (value < FLOOR) failed = true;
      return `${theme} ${value.toFixed(2)}${value < FLOOR ? ' FAIL' : ''}`;
    });
    return `${`${fg} on ${bg}`.padEnd(24)} ${cells.map((c) => c.padEnd(16)).join('')}${where}`.trimEnd();
  });
  return { lines, failed };
}

function parseArgs(argv) {
  const opts = { bare: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i];
    if (/^--(tokens|design-md|pairs|light-scope|dark-scope)$/.test(a)) {
      if (argv[i + 1] === undefined) throw new Error(`${a} needs a value`);
      opts[a.slice(2)] = argv[i + 1];
      i += 1;
    } else if (/^[^:]+:[^:]+$/.test(a)) {
      opts.bare.push(a.split(':'));
    } else {
      throw new Error(`"${a}" is not an option or a fg:bg pair`);
    }
  }
  return opts;
}

const USAGE = `usage: contrast.mjs --tokens <file> [--pairs fg:bg,...] [--light-scope <text>] [--dark-scope <text>]
       contrast.mjs --design-md <DESIGN.md> [--pairs fg:bg,...]
       contrast.mjs '#fg:#bg' ['#fg:#bg' ...]`;

export function main(argv) {
  const out = [];
  let failed = false;
  // Exit 1 means a pair measured under 4.5:1, so anything that stops a measurement
  // (an unreadable colour, a missing token, a bad option) exits 2 instead of throwing.
  try {
    const opts = parseArgs(argv);
    if (opts.tokens && opts['design-md']) throw new Error('pass --tokens or --design-md, not both');
    let themes;
    if (opts.tokens) {
      const scopes = {};
      if (opts['light-scope']) scopes.light = opts['light-scope'];
      if (opts['dark-scope']) scopes.dark = opts['dark-scope'];
      const ignored = [];
      themes = readThemes(readFileSync(opts.tokens, 'utf8'), scopes, ignored);
      if (ignored.length) {
        console.error(`warning: declarations under ${ignored.map((h) => `"${h}"`).join(', ')} are neither light nor dark and were ignored; name the scope with --light-scope or --dark-scope`);
      }
    } else if (opts['design-md']) {
      themes = { light: readDesignMd(readFileSync(opts['design-md'], 'utf8')) };
    }
    if (themes) {
      if (opts.bare.length) throw new Error(`a file takes token pairs through --pairs, not bare #fg:#bg\n${USAGE}`);
      let pairs = opts.pairs ? opts.pairs.split(',').map((p) => p.split(':')) : [];
      const found = [...new Set(Object.values(themes).flatMap((t) => Object.keys(t)))];
      if (!found.length) throw new Error('no --name: value declarations found under a light or dark scope; pass --light-scope and --dark-scope');
      if (!pairs.length) {
        const needed = [...new Set(PAIRS.flatMap(([fg, bg]) => [fg, bg]))];
        if (needed.every((n) => found.includes(n))) pairs = PAIRS;
        else {
          const list = found.map((n) => `--${n}`).join(', ') || 'none';
          throw new Error(`no --pairs given and the direction tokens are not all declared.\nFound: ${list}\n${USAGE}`);
        }
      }
      if (pairs.some((p) => p.length < 2 || p.length > 3 || !p[0] || !p[1])) throw new Error(`--pairs takes fg:bg,fg:bg\n${USAGE}`);
      const result = report(themes, pairs);
      failed = result.failed;
      out.push(...result.lines);
    } else if (opts.bare.length) {
      for (const [fg, bg] of opts.bare) {
        const value = ratio(fg, bg);
        if (value < FLOOR) failed = true;
        out.push(`${fg} on ${bg}: ${value.toFixed(2)}${value < FLOOR ? ' FAIL' : ''}`);
      }
    } else {
      throw new Error(USAGE);
    }
  } catch (error) {
    console.error(error.message);
    return 2;
  }
  console.log(out.join('\n'));
  if (failed) {
    console.log(`\nA pair is under ${FLOOR}:1. Large text (24px+) and non-text marks need only 3:1.`);
    return 1;
  }
  return 0;
}

// Compared as real paths: `import.meta.url` is already resolved, `argv[1]` may be a symlink.
if (process.argv[1] && fileURLToPath(import.meta.url) === realpathSync(process.argv[1])) {
  process.exit(main(process.argv.slice(2)));
}
