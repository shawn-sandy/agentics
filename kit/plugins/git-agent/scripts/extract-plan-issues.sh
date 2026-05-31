#!/usr/bin/env bash
set -euo pipefail
base="${1:?Usage: extract-plan-issues.sh <base-branch>}"
git diff --name-only "$base"...HEAD -- '*.html' 2>/dev/null \
  | while IFS= read -r f; do
      grep -oP '<meta\s+name="plan-issue"\s+content="\K[^"]+' "$f" 2>/dev/null || true
    done \
  | sort -u
