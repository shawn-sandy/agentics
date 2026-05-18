#!/usr/bin/env bash
# build-assets.sh — extracts tagged blocks from html-spec.md into assets/
# Usage: ./scripts/build-assets.sh
# Run from the markdown-to-html skill directory.
set -euo pipefail

SPEC="reference/html-spec.md"
ASSETS="assets"

if [[ ! -f "$SPEC" ]]; then
  echo "Error: $SPEC not found. Run from skills/markdown-to-html/." >&2
  exit 1
fi

mkdir -p "$ASSETS"

extract() {
  local tag="$1"
  local outfile="$2"
  awk "/<!-- BUILD-EXTRACT:${tag} START -->/{found=1;next} \
       /<!-- BUILD-EXTRACT:${tag} END -->/{found=0} \
       found" "$SPEC" \
    | sed '/^```css$/d; /^```javascript$/d; /^```$/d' \
    > "$outfile"
}

# themes.css — all four body.theme-* rule sets
extract "THEMES" "$ASSETS/themes.css"
echo "/* markdown-to-html v2.0.0 — generated from reference/html-spec.md */" \
  | cat - "$ASSETS/themes.css" > /tmp/mth_themes && mv /tmp/mth_themes "$ASSETS/themes.css"

# scripts.js — scroll-spy + step-completion IIFEs
{
  echo "/* markdown-to-html v2.0.0 — generated from reference/html-spec.md */"
  extract "SCROLL-SPY" /dev/stdout
  echo ""
  extract "STEP-COMPLETION" /dev/stdout
} > "$ASSETS/scripts.js"

echo "Built:"
echo "  $ASSETS/themes.css  ($(wc -l < "$ASSETS/themes.css") lines)"
echo "  $ASSETS/scripts.js  ($(wc -l < "$ASSETS/scripts.js") lines)"
