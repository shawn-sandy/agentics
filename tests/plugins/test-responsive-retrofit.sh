#!/usr/bin/env bash
set -euo pipefail

# Standing-invariant test for scripts/retrofit-responsive-plans.mjs
# (implements Step 4 of docs/plans/retrofit-responsive-plan-css.html).
#
# The retrofit injects a versioned <style id="plan-responsive-fix"> block into
# every self-contained HTML plan so already-shipped plans stop overflowing on
# narrow viewports. A one-time migration is not enough: a plan generated from a
# stale skeleton, or a skeleton that drifts from the script constant, would
# silently regress. These asserts pin three things permanently:
#   1. CORPUS  — every shipped plan under docs/plans/ carries the current block
#                (`--check` exits 0). This is the hero assertion.
#   2. SYNC    — the skeleton's embedded block is byte-identical to the script's
#                exported STYLE_BLOCK, so the two cannot diverge.
#   3. BEHAVIOUR — inject/replace/skip/error transitions, head-only scoping, and
#                deterministic (idempotent) output, exercised on fixtures and on
#                a throwaway copy of the real corpus.
#
# Detection and injection are HEAD-SCOPED: the plan document
# retrofit-responsive-plan-css.html embeds the literal block string inside its
# <body> machine-readable digest, so a whole-file match would falsely "skip" it.
# The head-only guarantee assert proves the injector never touches body markup.
#
# House style mirrors test-save-pdf.sh: bash + node/python3/grep/diff, ROOT via
# dirname, a FAILURES counter, a PASS/FAIL line per assert, exit 1 on any FAIL.
# Node is shelled out to the same way test-backfill-digest.mjs imports the
# script under test, except here the harness is bash so we use `node -e` /
# `node -p` with dynamic import().

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" # so `node scripts/...` and relative --dir paths resolve

SCRIPT="$ROOT/scripts/retrofit-responsive-plans.mjs"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLANS_DIR="$ROOT/docs/plans"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# Single temp workspace for every fixture + corpus-copy case; always cleaned up.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/responsive-retrofit.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "=== Responsive Retrofit Invariant Test ==="

# ── 0. Sanity: the script under test exists ───────────────────────────────────
# Every assertion below depends on it; surface a missing script as one clear
# failure rather than a cascade of opaque node errors.
echo "0. scripts/retrofit-responsive-plans.mjs exists..."
if [ -f "$SCRIPT" ]; then
  pass
else
  fail "scripts/retrofit-responsive-plans.mjs is missing (Step 1 not landed)"
  echo
  echo "$FAILURES assertion(s) failed."
  exit 1
fi

# Pull the public constants straight from the module so the test never hardcodes
# the block. These also assert the exact export names the contract promises.
STYLE_BLOCK="$(node -e "import('file://$SCRIPT').then(m=>process.stdout.write(m.STYLE_BLOCK))")"
CURRENT_VERSION="$(node -e "import('file://$SCRIPT').then(m=>process.stdout.write(String(m.CURRENT_VERSION)))")"
printf '%s' "$STYLE_BLOCK" > "$WORK/style-block.txt"

# ── 1. HERO / CORPUS — every shipped plan carries the current block ───────────
echo "1. --check exits 0 over the repo's real docs/plans/ (every shipped plan current)..."
if node "$SCRIPT" --check >/dev/null 2>&1; then
  pass
else
  fail "--check is nonzero: a shipped plan under docs/plans/ is missing the current block (run: node scripts/retrofit-responsive-plans.mjs)"
fi

# ── 2. SYNC GUARD — skeleton block === script's exported STYLE_BLOCK ──────────
echo "2. SKELETON.html embeds the script's STYLE_BLOCK byte-for-byte..."
if node -e "import('$SCRIPT').then(m=>{const fs=require('node:fs');const sk=fs.readFileSync('$SKELETON','utf8');process.exit(sk.includes(m.STYLE_BLOCK)?0:1)})"; then
  pass
else
  fail "SKELETON.html does not contain the script's STYLE_BLOCK verbatim (skeleton/script drift)"
fi

# A reusable Node helper for the fixture cases. Reads a file, runs inject(),
# and prints the action to stdout; on inject/replace it also writes the new
# bytes back to the file (the CLI's job, reproduced here at unit granularity so
# we can assert determinism and head-only scoping precisely).
#   args: <file>
# stdout: the action word (inject|replace|skip|error)
inject_file() {
  node -e "
    import('file://$SCRIPT').then(m => {
      const fs = require('node:fs');
      const file = process.argv[1];
      const r = m.inject(fs.readFileSync(file, 'utf8'));
      if (r.action === 'inject' || r.action === 'replace') fs.writeFileSync(file, r.html);
      process.stdout.write(r.action);
    });
  " "$1"
}

# Count occurrences of the style id in a file. `|| true` swallows grep's exit 1
# on zero matches so a clean "0" count never trips `set -e` when assigned
# (e.g. IDX_BLOCKS=$(count_blocks index.html), where 0 is the expected result).
count_blocks() { { grep -o 'id="plan-responsive-fix"' "$1" || true; } | wc -l | tr -d ' '; }

# ── 3. FIXTURE: missing block → inject once, idempotent on a second run ───────
echo "3. missing block injected exactly once immediately before </head>; second run byte-identical..."
MISS="$WORK/missing.html"
printf '%s' '<!DOCTYPE html><html><head><meta charset="utf-8"><title>x</title></head>
<body><main><h1>Body untouched</h1></main></body></html>' > "$MISS"
act1="$(inject_file "$MISS")"
n="$(count_blocks "$MISS")"
# The injected block must sit directly before </head>: STYLE_BLOCK + one newline.
node -e "
  import('file://$SCRIPT').then(m => {
    const fs = require('node:fs');
    const html = fs.readFileSync('$MISS', 'utf8');
    const want = m.STYLE_BLOCK + '\n</head>';
    process.exit(html.includes(want) ? 0 : 1);
  });
" && placed=ok || placed=bad
cp "$MISS" "$WORK/missing.after1"
act2="$(inject_file "$MISS")"
if [ "$act1" = "inject" ] && [ "$n" = "1" ] && [ "$placed" = "ok" ] \
   && [ "$act2" = "skip" ] && diff -q "$WORK/missing.after1" "$MISS" >/dev/null; then
  pass
else
  fail "missing-block fixture: action1=$act1 (want inject), count=$n (want 1), placed=$placed, action2=$act2 (want skip), or second run not byte-identical"
fi

# ── 4. FIXTURE: data-version="0" → replaced with v1, no duplicate block ───────
echo "4. older data-version=\"0\" block replaced with v$CURRENT_VERSION, exactly one block remains..."
OLD="$WORK/old-version.html"
printf '%s' '<!DOCTYPE html><html><head><meta charset="utf-8">
<style id="plan-responsive-fix" data-version="0">
/* stale v0 block */
body { overflow: hidden; }
</style>
</head><body><p>keep me</p></body></html>' > "$OLD"
act="$(inject_file "$OLD")"
n="$(count_blocks "$OLD")"
# The swap must yield the current STYLE_BLOCK verbatim (multi-line, so checked
# via Node rather than grep) and drop the v0 marker entirely.
node -e "
  import('file://$SCRIPT').then(m => {
    const fs = require('node:fs');
    process.exit(fs.readFileSync('$OLD','utf8').includes(m.STYLE_BLOCK) ? 0 : 1);
  });
" && swapped=ok || swapped=bad
if [ "$act" = "replace" ] && [ "$n" = "1" ] && [ "$swapped" = "ok" ] \
   && grep -q 'data-version="'"$CURRENT_VERSION"'"' "$OLD" \
   && ! grep -q 'data-version="0"' "$OLD"; then
  pass
else
  fail "v0 fixture: action=$act (want replace), count=$n (want 1), swapped=$swapped, or version marker not updated"
fi

# ── 5. FIXTURE: current v1 block → skip, byte-identical ───────────────────────
echo "5. current v$CURRENT_VERSION block is skipped and left byte-identical..."
CUR="$WORK/current.html"
{ printf '%s' '<!DOCTYPE html><html><head><meta charset="utf-8">'; printf '\n'; \
  cat "$WORK/style-block.txt"; printf '\n</head><body><p>current</p></body></html>'; } > "$CUR"
cp "$CUR" "$WORK/current.before"
act="$(inject_file "$CUR")"
if [ "$act" = "skip" ] && diff -q "$WORK/current.before" "$CUR" >/dev/null; then
  pass
else
  fail "current-block fixture: action=$act (want skip) or file was modified"
fi

# ── 6. FIXTURE: index.html → untouched by the CLI ─────────────────────────────
echo "6. index.html in a --dir run is left untouched..."
IDXDIR="$WORK/idxdir"
mkdir -p "$IDXDIR"
printf '%s' '<!DOCTYPE html><html><head><title>gallery</title></head><body>not a plan</body></html>' > "$IDXDIR/index.html"
printf '%s' '<!DOCTYPE html><html><head><title>plan</title></head><body><main>p</main></body></html>' > "$IDXDIR/a-plan.html"
cp "$IDXDIR/index.html" "$WORK/index.before"
node "$SCRIPT" --dir "$IDXDIR" >/dev/null 2>&1 || true
if diff -q "$WORK/index.before" "$IDXDIR/index.html" >/dev/null \
   && [ "$(count_blocks "$IDXDIR/index.html")" = "0" ] \
   && [ "$(count_blocks "$IDXDIR/a-plan.html")" = "1" ]; then
  pass
else
  fail "index.html was modified (or the sibling plan was not injected) by a --dir run"
fi

# ── 7. FIXTURE: no </head> → reported and never written ───────────────────────
echo "7. a fixture with no </head> is reported as error/skip and never modified..."
NOHEAD="$WORK/no-head.html"
printf '%s' '<!DOCTYPE html><html><body><p>fragment with no head close</p></body></html>' > "$NOHEAD"
cp "$NOHEAD" "$WORK/no-head.before"
act="$(inject_file "$NOHEAD")"
if [ "$act" = "error" ] && diff -q "$WORK/no-head.before" "$NOHEAD" >/dev/null; then
  pass
else
  fail "no-</head> fixture: action=$act (want error) or file was modified"
fi

# ── 8. HEAD-ONLY GUARANTEE — output identical to input from <body onward ──────
echo "8. injector output is byte-identical to input from the first '<body' onward..."
# Uses a fixture that embeds the literal block string INSIDE its body (the exact
# trap the real plan document sets): detection must ignore the body copy, inject
# into the head, and leave every body byte — including that decoy — untouched.
if node -e "
  import('file://$SCRIPT').then(m => {
    const input =
      '<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>t</title></head>\n' +
      '<body><main aria-label=\"keep\"><p>decoy: <style id=\"plan-responsive-fix\" data-version=\"1\"></p>' +
      '<pre>x &amp; y</pre></main></body></html>';
    const r = m.inject(input);
    if (r.action !== 'inject') { console.error('expected inject, got ' + r.action); process.exit(1); }
    const cut = (s) => s.slice(s.indexOf('<body'));
    if (cut(r.html) !== cut(input)) { console.error('body bytes changed'); process.exit(1); }
    if (!r.html.includes(m.STYLE_BLOCK + '\n</head>')) { console.error('block not before </head>'); process.exit(1); }
    process.exit(0);
  });
"; then
  pass
else
  fail "injector altered body markup, or did not inject into the head, on a body-decoy fixture"
fi

# ── 9. INTEGRATION — real corpus copy: inject all, --check, idempotent, strip ─
echo "9. real docs/plans/ copy: first run injects every non-index plan, --check passes, second run is a no-op..."
CORPUS="$WORK/corpus"
mkdir -p "$CORPUS"
# A shallow copy of just the HTML plan files (no archive/, no subdirs needed).
cp -R "$PLANS_DIR/." "$CORPUS/"
# How many non-index plans should be touched on a from-scratch run? Strip any
# pre-existing head block from each copy so the corpus is in the pre-fix state,
# regardless of whether Step 2 has already backfilled the working tree.
EXPECTED="$(node -e "
  import('file://$SCRIPT').then(m => {
    const fs = require('node:fs');
    const path = require('node:path');
    const dir = '$CORPUS';
    let count = 0;
    for (const name of fs.readdirSync(dir)) {
      if (!name.endsWith('.html') || name === 'index.html') continue;
      const file = path.join(dir, name);
      let html = fs.readFileSync(file, 'utf8');
      // Remove a head-scoped block if present, leaving any body decoy intact.
      const headEnd = html.search(/<\/head>/i);
      if (headEnd !== -1) {
        const head = html.slice(0, headEnd);
        const stripped = head.replace(/<style id=\"plan-responsive-fix\"[\s\S]*?<\/style>\n?/i, '');
        if (stripped !== head) { html = stripped + html.slice(headEnd); fs.writeFileSync(file, html); }
      }
      count += 1;
    }
    process.stdout.write(String(count));
  });
")"

# First run over the stripped copy must succeed and leave nothing missing.
node "$SCRIPT" --dir "$CORPUS" >/dev/null 2>&1 || true
INJECTED="$(node -e "
  const fs=require('node:fs'); const path=require('node:path'); const dir='$CORPUS';
  let n=0;
  for (const name of fs.readdirSync(dir)) {
    if (!name.endsWith('.html') || name==='index.html') continue;
    const head = fs.readFileSync(path.join(dir,name),'utf8').split(/<\/head>/i)[0];
    if (head.includes('id=\"plan-responsive-fix\"')) n+=1;
  }
  process.stdout.write(String(n));
")"
IDX_BLOCKS="$(count_blocks "$CORPUS/index.html")"

# Snapshot the whole tree, run again, and require a byte-identical no-op.
SUM1="$(find "$CORPUS" -type f -name '*.html' | sort | xargs shasum | shasum | awk '{print $1}')"
node "$SCRIPT" --dir "$CORPUS" >/dev/null 2>&1 || true
SUM2="$(find "$CORPUS" -type f -name '*.html' | sort | xargs shasum | shasum | awk '{print $1}')"

if node "$SCRIPT" --check --dir "$CORPUS" >/dev/null 2>&1 \
   && [ "$INJECTED" = "$EXPECTED" ] && [ "$EXPECTED" -gt 0 ] \
   && [ "$IDX_BLOCKS" = "0" ] && [ "$SUM1" = "$SUM2" ]; then
  pass
else
  fail "corpus run: injected=$INJECTED of expected=$EXPECTED non-index plans, index blocks=$IDX_BLOCKS (want 0), --check post-run nonzero, or second run not byte-identical (sum1=$SUM1 sum2=$SUM2)"
fi

# ── 10. INTEGRATION — stripping one file makes --check fail and name it ───────
echo "10. stripping the block from one corpus file makes --check exit 1 and name that file..."
VICTIM="$(node -e "
  const fs=require('node:fs'); const path=require('node:path'); const dir='$CORPUS';
  const f=fs.readdirSync(dir).find(n=>n.endsWith('.html') && n!=='index.html');
  process.stdout.write(f||'');
")"
if [ -z "$VICTIM" ]; then
  fail "no non-index plan found in the corpus copy to strip"
else
  node -e "
    const fs=require('node:fs'); const p='$CORPUS/$VICTIM';
    let h=fs.readFileSync(p,'utf8');
    const he=h.search(/<\/head>/i);
    const head=h.slice(0,he).replace(/<style id=\"plan-responsive-fix\"[\s\S]*?<\/style>\n?/i,'');
    fs.writeFileSync(p, head + h.slice(he));
  "
  OUT="$(node "$SCRIPT" --check --dir "$CORPUS" 2>&1 || true)"
  RC=0; node "$SCRIPT" --check --dir "$CORPUS" >/dev/null 2>&1 || RC=$?
  if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "$VICTIM"; then
    pass
  else
    fail "--check did not exit nonzero (rc=$RC) or did not name the stripped file $VICTIM"
  fi
fi

# ── 11. INTEGRATION — --dry-run writes nothing ────────────────────────────────
echo "11. --dry-run reports would-inject files but writes nothing..."
DRY="$WORK/dry"
mkdir -p "$DRY"
printf '%s' '<!DOCTYPE html><html><head><title>dry</title></head><body><main>x</main></body></html>' > "$DRY/dry-plan.html"
SUMB="$(shasum "$DRY/dry-plan.html" | awk '{print $1}')"
node "$SCRIPT" --dry-run --dir "$DRY" >/dev/null 2>&1 || true
SUMA="$(shasum "$DRY/dry-plan.html" | awk '{print $1}')"
if [ "$SUMB" = "$SUMA" ] && [ "$(count_blocks "$DRY/dry-plan.html")" = "0" ]; then
  pass
else
  fail "--dry-run modified a file (it must only report)"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All responsive-retrofit assertions passed."
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
