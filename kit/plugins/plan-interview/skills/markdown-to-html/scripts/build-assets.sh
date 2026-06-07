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
# Exits non-zero if START or END marker is missing (prevents silent empty output).
extract() {
  local tag="$1"
  awk -v tag="$tag" '
    $0 ~ "<!-- BUILD-EXTRACT:" tag " START -->" { found=1; saw_start=1; next }
    $0 ~ "<!-- BUILD-EXTRACT:" tag " END -->"   { found=0; saw_end=1;   next }
    found { print }
    END {
      if (!saw_start || !saw_end) {
        printf "Error: missing or unclosed BUILD-EXTRACT markers for tag %s\n", tag > "/dev/stderr"
        exit 1
      }
    }
  ' "$SPEC" \
    | sed '/^```css$/d; /^```javascript$/d; /^```$/d'
}

# themes.css — all four body.theme-* rule sets
{
  echo "/* markdown-to-html v2.1.0 — generated from reference/html-spec.md */"
  extract "THEMES"
} > "$ASSETS/themes.css"

# scripts.js — savePDF + scroll-spy + step-completion
{
  echo "/* markdown-to-html v2.1.0 — generated from reference/html-spec.md */"
  extract "SAVE-PDF-JS"
  echo ""
  extract "SCROLL-SPY"
  echo ""
  extract "STEP-COMPLETION"
} > "$ASSETS/scripts.js"

echo "Built:"
echo "  $ASSETS/themes.css  ($(wc -l < "$ASSETS/themes.css") lines)"
echo "  $ASSETS/scripts.js  ($(wc -l < "$ASSETS/scripts.js") lines)"
