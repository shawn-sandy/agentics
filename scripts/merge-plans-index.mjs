#!/usr/bin/env node
// Git merge driver for the generated gallery indexes — docs/plans/index.html
// and docs/artifacts/index.html. Both are built from the same card markup
// (<a class="gallery-card">), so one driver serves both; .gitattributes points
// each at merge=plans-index. The name is historical: it predates the artifacts
// gallery and is kept so existing clones' git config keeps resolving.
// Invoked by git as: node merge-plans-index.mjs %O %A %B
//   %O = base (common ancestor — may be /dev/null for new-file merges)
//   %A = ours (current branch path — driver MUST write result here)
//   %B = theirs (incoming branch path)
// Exit 0 on success; exit 1 (file untouched) to fall back to a normal conflict.
//
// Why a card union instead of regenerating via docs/plans/build-index.sh:
// at merge-driver run time git has NOT yet updated the working tree with the
// incoming branch's files, and MERGE_HEAD is not readable yet (merge-ort runs
// drivers against in-memory trees before touching the worktree — verified
// empirically on git 2.50). Regenerating "from disk" inside the driver would
// therefore produce an index silently missing every incoming plan. The index
// is self-describing — each side's <a class="gallery-card"> blocks are its
// plan inventory — so the correct merge is a union of those blocks:
//   - ours' cards keep their order; theirs-only NEW cards are appended
//   - a card present in base but deleted on either side stays deleted
//   - when both sides carry a card, the side that changed it vs base wins
//     (ours wins ties and both-changed conflicts)
//   - the visible "N plans" count is patched; ours' chrome is kept otherwise
// Ordering and the generated-at timestamp may drift from a fresh rebuild —
// that is cosmetic and self-heals on the next plan write, when
// kit/plugins/plan-agent/hooks/rebuild-plans-index.py regenerates the file
// wholesale via docs/plans/build-index.sh.

import { readFileSync, writeFileSync } from 'node:fs';

const [,, basePath, oursPath, theirsPath] = process.argv;

const CARD_RE = /<a class="gallery-card"[\s\S]*?<\/a>/g;

// Parse gallery-card blocks into an ordered href → block map.
function parseCards(text) {
  const cards = new Map();
  for (const block of text.match(CARD_RE) ?? []) {
    const href = block.match(/href="([^"]*)"/)?.[1];
    if (href && !cards.has(href)) cards.set(href, block);
  }
  return cards;
}

try {
  // Base may be /dev/null (new-file merge) or empty — treat as no cards.
  let baseText = '';
  try { baseText = readFileSync(basePath, 'utf8'); } catch { /* ours-wins fallback */ }

  const oursText = readFileSync(oursPath, 'utf8');
  const theirsText = readFileSync(theirsPath, 'utf8');

  const base = parseCards(baseText);
  const ours = parseCards(oursText);
  const theirs = parseCards(theirsText);

  // Card regex matching neither side while the base had cards means the
  // generated markup changed shape — bail to a normal conflict.
  if (ours.size === 0 && theirs.size === 0) {
    if (base.size === 0) process.exit(0); // nothing card-like anywhere — keep ours
    throw new Error('no gallery-card blocks matched in either side');
  }

  // If ours has no cards but theirs does, theirs' chrome is the only one with
  // a card region to splice into — swap roles (union logic is symmetric).
  const [chromeText, primary, secondary] =
    ours.size > 0 ? [oursText, ours, theirs] : [theirsText, theirs, ours];

  const merged = [];
  for (const [href, block] of primary) {
    if (base.has(href) && !secondary.has(href)) continue; // deleted on the other side
    const other = secondary.get(href);
    if (other === undefined || other === block) {
      merged.push(block);                                  // unique to primary, or identical
    } else {
      const b = base.get(href);
      merged.push(block === b && other !== b ? other : block); // changed side wins; primary wins ties
    }
  }
  for (const [href, block] of secondary) {
    if (!primary.has(href) && !base.has(href)) merged.push(block); // new on the other side
  }

  // Splice the merged card list over the chrome's card region.
  const matches = [...chromeText.matchAll(CARD_RE)];
  const first = matches[0];
  const last = matches[matches.length - 1];
  const result =
    chromeText.slice(0, first.index) +
    merged.join('\n') +
    chromeText.slice(last.index + last[0].length);

  // Patch EVERY visible card count, not just the first. Both galleries render
  // the total twice — a header ("<p>48 plans …", "<p>12 items …") and a footer
  // ("<span>12 items</span>") — and the build script has a third embedded
  // fallback form ("&middot; 48 plans"). Patching one leaves the page showing
  // two different totals until the next regeneration, which reads as data loss
  // rather than the cosmetic drift it is; hence the /g and the <span> form.
  // The noun stays whitelisted rather than matched as \w+ so an unrelated
  // "<p>3 columns" in the chrome cannot be rewritten. Cosmetic; skips silently
  // when no pattern is present.
  const COUNT_RE = /(<p>|<span>|&middot;\s*)(\d+)(\s*(?:plans|items|artifacts)\b)/g;
  const counted = result.replace(COUNT_RE, (_m, pre, _n, post) => `${pre}${merged.length}${post}`);

  writeFileSync(oursPath, counted);
  process.exit(0);
} catch (e) {
  process.stderr.write(`merge-plans-index: ${e.message}\n`);
  process.exit(1);
}
