#!/usr/bin/env bash
set -euo pipefail
base="${1:?Usage: extract-plan-issues.sh <base-branch>}"
git diff --name-only "$base"...HEAD -- 'docs/plans/*.html' 'docs/plans/**/*.html' 2>/dev/null \
  | while IFS= read -r f; do
      sed -nE 's/.*<meta[[:space:]]+name="plan-issue"[[:space:]]+content="([^"]+)".*/\1/p' "$f" 2>/dev/null || true
    done \
  | sort -u
