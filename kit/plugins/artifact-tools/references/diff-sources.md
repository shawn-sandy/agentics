# Resolving the diff source

Loaded by `diff-artifact` Step 1.

## Pick the first mode that matches the user's argument

| Mode | Trigger | Command |
|------|---------|---------|
| **Branch** (default) | no argument | `git diff <default-branch>...HEAD` |
| **Range** | `abc123..def456` | `git diff <range>` |
| **PR** | `#42` or a PR URL | `gh pr diff 42` |

Resolve the default branch rather than assuming `main`:

```bash
DEFAULT_BRANCH=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git diff "${DEFAULT_BRANCH}...HEAD"
```

## PR-mode degradation

PR mode needs both the `gh` CLI and a GitHub remote. When either is missing, do
not fail and do not merely report it — say so plainly and **actually produce the
branch diff**. Every degradation path must still end with a diff on disk:

```bash
DIFF_FILE="<scratchpad>/diff.patch"

use_pr=0
if [ -n "${PR:-}" ]; then
  if gh auth status >/dev/null 2>&1 &&
     git remote get-url origin 2>/dev/null | grep -qi 'github\.com'; then
    use_pr=1
  else
    echo "PR mode unavailable (gh missing/unauthenticated, or origin is not GitHub) — using branch mode"
  fi
fi

if [ "$use_pr" = 1 ]; then
  gh pr diff "$PR" > "$DIFF_FILE" || { echo "gh pr diff failed — using branch mode"; use_pr=0; }
fi
[ "$use_pr" = 1 ] || git diff "${DEFAULT_BRANCH}...HEAD" > "$DIFF_FILE"
```

If `$DIFF_FILE` is empty, tell the user there is nothing to publish and stop.
