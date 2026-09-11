#!/usr/bin/env bash
set -euo pipefail
base="${1:?Usage: extract-plan-issues.sh <base-branch>}"
# Prints the ticket URL of every *completed* plan this branch touches; the PR
# skills turn each into a `Closes <url>` line. Both plan formats are read:
# artifact-delivered plans are a .md spec with no .html at all, and the PR that
# authors or checkpoints a plan touches the same file, so status gates the URL.
git diff --name-only "$base"...HEAD -- 'docs/plans/*.md' 'docs/plans/**/*.md' 'docs/plans/*.html' 'docs/plans/**/*.html' 2>/dev/null \
  | while IFS= read -r f; do
      case "$f" in
        *.md)
          # Frontmatter only: a plan body routinely quotes `issue:` in examples.
          awk '{ sub(/[[:space:]]+$/, "") }
               NR == 1 { if ($0 != "---") exit; next }
               $0 == "---" { exit }
               sub(/^status:[[:space:]]*/, "") { status = $0 }
               sub(/^issue:[[:space:]]*/, "") { issue = $0 }
               END { if (status == "completed") print issue }' "$f" 2>/dev/null || true
          ;;
        *.html)
          if grep -qE '<meta[[:space:]]+name="plan-status"[[:space:]]+content="completed"' "$f" 2>/dev/null; then
            sed -nE 's/.*<meta[[:space:]]+name="plan-issue"[[:space:]]+content="([^"]+)".*/\1/p' "$f" 2>/dev/null || true
          fi
          ;;
      esac
    done \
  | { grep -E '^https://[^[:space:]]+$' || true; } \
  | sort -u
