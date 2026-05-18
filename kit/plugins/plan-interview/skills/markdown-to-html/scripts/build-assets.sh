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

# Writes extracted block to stdout; callers redirect as needed.
extract() {
  local tag="$1"
  awk "/<!-- BUILD-EXTRACT:${tag} START -->/{found=1;next} \
       /<!-- BUILD-EXTRACT:${tag} END -->/{found=0} \
       found" "$SPEC" \
    | sed '/^```css$/d; /^```javascript$/d; /^```$/d'
}

# themes.css — all four body.theme-* rule sets
{
  echo "/* markdown-to-html v2.0.0 — generated from reference/html-spec.md */"
  extract "THEMES"
} > "$ASSETS/themes.css"

# scripts.js — scroll-spy + step-completion IIFEs
{
  echo "/* markdown-to-html v2.0.0 — generated from reference/html-spec.md */"
  extract "SCROLL-SPY"
  echo ""
  extract "STEP-COMPLETION"
} > "$ASSETS/scripts.js"

echo "Built:"
echo "  $ASSETS/themes.css  ($(wc -l < "$ASSETS/themes.css") lines)"
echo "  $ASSETS/scripts.js  ($(wc -l < "$ASSETS/scripts.js") lines)"
