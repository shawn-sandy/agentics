#!/usr/bin/env bash
# Smoke test for scripts/merge-plans-index.mjs, the union merge driver shared by
# docs/plans/index.html and docs/artifacts/index.html.
#
# The artifacts gallery was wired to this driver after a real conflict: two
# branches each added a recap card and git could not auto-merge the regenerated
# index. These checks cover the union itself plus the count patch, which had to
# learn the artifacts gallery's noun ("items") alongside the plans one.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRIVER="$REPO_ROOT/scripts/merge-plans-index.mjs"
FAILURES=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass() { echo "  ok   — $1"; }
fail() { echo "  FAIL — $1"; FAILURES=$((FAILURES + 1)); }

card() { printf '<a class="gallery-card" href="%s">%s</a>' "$1" "$2"; }

# Build a gallery page shaped like the real ones: a header count, a decoy the
# driver must not touch, the cards, then the footer count the generated
# galleries also carry. The footer is the reason the patch has to be global.
page() {
  local noun="$1" count="$2"; shift 2
  printf '<html><body><p>%s %s</p><p>3 columns</p>\n' "$count" "$noun"
  for c in "$@"; do printf '%s\n' "$c"; done
  printf '<footer><span>%s %s</span></footer></body></html>\n' "$count" "$noun"
}

run_driver() { node "$DRIVER" "$1" "$2" "$3" >/dev/null 2>&1; }

echo "test-merge-gallery-index"

# ---------------------------------------------------------------------------
# 1–4. Artifacts gallery: each side adds one card to a shared base.
# ---------------------------------------------------------------------------
page items 1 "$(card old.html Old)"                            > "$WORK/base.html"
page items 2 "$(card old.html Old)" "$(card ours.html Ours)"   > "$WORK/ours.html"
page items 2 "$(card old.html Old)" "$(card theirs.html Them)" > "$WORK/theirs.html"

if run_driver "$WORK/base.html" "$WORK/ours.html" "$WORK/theirs.html"; then
  pass "driver exits 0 on a two-sided add"
else
  fail "driver exited non-zero on a two-sided add"
fi
RESULT="$(cat "$WORK/ours.html")"

grep -q 'href="ours.html"'   <<<"$RESULT" && pass "keeps our card"     || fail "dropped our card"
grep -q 'href="theirs.html"' <<<"$RESULT" && pass "unions their card"  || fail "dropped their card"

# The count patch is the part that had to learn "items" — a driver that only
# knows "plans" leaves this at 2 while three cards are rendered.
grep -q '<p>3 items</p>' <<<"$RESULT" \
  && pass "patches the artifacts count to the merged total" \
  || fail "count not patched to 3 items (got: $(grep -oE '<p>[0-9]+ items</p>' <<<"$RESULT" || echo none))"

# The noun whitelist exists so unrelated numbers in the chrome survive.
grep -q '<p>3 columns</p>' <<<"$RESULT" \
  && pass "leaves non-count numbers in the chrome alone" \
  || fail "rewrote an unrelated number in the chrome"

# Both galleries render the total twice. Patching only the header leaves the
# page contradicting itself, which reads as lost cards rather than stale chrome.
grep -q '<span>3 items</span>' <<<"$RESULT" \
  && pass "patches the footer count as well as the header" \
  || fail "footer count left stale (got: $(grep -oE '<span>[0-9]+ items</span>' <<<"$RESULT" || echo none))"

# ---------------------------------------------------------------------------
# 5. A card deleted on one side stays deleted (not resurrected by the union).
# ---------------------------------------------------------------------------
page items 2 "$(card keep.html Keep)" "$(card gone.html Gone)" > "$WORK/b2.html"
page items 1 "$(card keep.html Keep)"                          > "$WORK/o2.html"
page items 2 "$(card keep.html Keep)" "$(card gone.html Gone)" > "$WORK/t2.html"

# The exit status matters here: a driver that crashes leaves o2.html untouched,
# which already lacks gone.html, so the grep below would "pass" on a dead driver.
if ! run_driver "$WORK/b2.html" "$WORK/o2.html" "$WORK/t2.html"; then
  fail "driver exited non-zero on the deletion merge"
elif grep -q 'href="gone.html"' "$WORK/o2.html"; then
  fail "resurrected a card deleted on our side"
else
  pass "keeps a deleted card deleted"
fi

# ---------------------------------------------------------------------------
# 6. Plans gallery still works — the driver's original job.
# ---------------------------------------------------------------------------
page plans 1 "$(card p1.html One)"                        > "$WORK/b3.html"
page plans 2 "$(card p1.html One)" "$(card p2.html Two)"  > "$WORK/o3.html"
page plans 2 "$(card p1.html One)" "$(card p3.html Tre)"  > "$WORK/t3.html"

if ! run_driver "$WORK/b3.html" "$WORK/o3.html" "$WORK/t3.html"; then
  fail "driver exited non-zero on the plans merge"
elif grep -q 'href="p3.html"' "$WORK/o3.html" && grep -q '<p>3 plans</p>' "$WORK/o3.html"; then
  pass "plans gallery still unions and counts"
else
  fail "regressed the plans gallery"
fi

# ---------------------------------------------------------------------------
# 7. Unrecognizable markup falls back to a normal conflict rather than
#    silently writing a page with no cards.
# ---------------------------------------------------------------------------
printf '<html><body><p>1 items</p><div class="something-else">x</div></body></html>\n' > "$WORK/b4.html"
cp "$WORK/b4.html" "$WORK/o4.html"
cp "$WORK/b4.html" "$WORK/t4.html"
printf '<html><body><p>1 items</p>%s</body></html>\n' "$(card real.html R)" > "$WORK/b4.html"

if run_driver "$WORK/b4.html" "$WORK/o4.html" "$WORK/t4.html"; then
  fail "exited 0 when card markup vanished — should fall back to a conflict"
else
  pass "falls back to a normal conflict when markup shape changes"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "test-merge-gallery-index: all checks passed"
  exit 0
fi
echo "test-merge-gallery-index: $FAILURES check(s) failed"
exit 1
