#!/usr/bin/env node
/**
 * WCAG 2 contrast for colour-token pairs, in every theme of a Design System tokens.json.
 *
 * Usage: node contrast.mjs <tokens.json> <fg:bg> [fg:bg ...]
 * Example: node contrast.mjs project/tokens.json ink:paper ink-soft:paper-sunk paper:island
 *
 * Ratios are floored to two decimals so 4.499 never prints as 4.50.
 */
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

/** Resolve a token to a colour string in one theme, following "{alias}" values. */
export function resolve(color, name, theme, seen = new Set()) {
  const token = color.tokens.find((t) => t.name === name);
  if (!token || seen.has(name)) throw new Error(`unknown or circular token: ${name}`);
  seen.add(name);
  const v = token.value;
  // A plain string, or a missing theme, falls back to the first theme's value.
  const s = typeof v === 'string' ? v : (v[theme] ?? v[color.themes[0].id]);
  if (s === undefined) throw new Error(`${name} has no value for ${theme} or ${color.themes[0].id}`);
  const alias = /^\{(.+)\}$/.exec(s);
  return alias ? resolve(color, alias[1], theme, seen) : s;
}

function channels(s) {
  let m = /^#([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(s);
  if (m) {
    const h = m[1].length === 3 ? [...m[1]].map((c) => c + c).join('') : m[1];
    return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
  }
  m = /^rgba?\(\s*([\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)\s*\)$/i.exec(s);
  if (m) {
    const c = m.slice(1).map(Number);
    // `!(n <= 255)` also catches NaN from a malformed number like `1.2.3`.
    if (c.some((n) => !(n <= 255))) throw new Error(`${s} has a channel outside 0-255`);
    return c;
  }
  // ponytail: opaque hex and rgb() only; add hsl()/oklch() conversion when a source uses them
  throw new Error(`cannot measure ${s} (translucent or non-hex/rgb): measure it by hand`);
}

const luminance = (s) => {
  const [r, g, b] = channels(s).map((v) => {
    v /= 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};

export function ratio(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return Math.floor(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [file, ...pairs] = process.argv.slice(2);
  if (!file || !pairs.length || pairs.some((p) => !/^[^:]+:[^:]+$/.test(p))) {
    console.error('usage: contrast.mjs <tokens.json> <fg:bg> [fg:bg ...]');
    process.exit(2);
  }
  const { color } = JSON.parse(readFileSync(file, 'utf8'));
  let failed = false;
  for (const pair of pairs) {
    const [fg, bg] = pair.split(':');
    const cells = color.themes.map(({ id }) => {
      try {
        const r = ratio(resolve(color, fg, id), resolve(color, bg, id));
        return `${id} ${r.toFixed(2)}:1${r < 4.5 ? ' (<4.5)' : ''}`;
      } catch (e) {
        failed = true;
        return `${id} ERROR ${e.message}`;
      }
    });
    console.log(`${fg} on ${bg}  ${cells.join('  ')}`);
  }
  process.exit(failed ? 1 : 0);
}
