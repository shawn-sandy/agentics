# Add Issue References from Plan Files to PR Descriptions

## Context

The plan-agent plugin already captures GitHub/GitLab issue URLs when plans are seeded from issues, storing them as `<meta name="plan-issue" content="<url>">` in HTML plan files. However, the git-agent plugin — which creates PRs — never reads this metadata. This means the issue-to-PR link is broken: users seed plans from issues but the resulting PRs don't reference or auto-close those issues.

This change bridges that gap so PRs created via git-agent automatically include `Closes <url>` lines when the branch contains plan files with issue references.

## Approach: Branch-Scoped Plan Discovery

Before generating the PR body, scan for plan files committed on the current branch (vs the base branch) that contain `<meta name="plan-issue"` tags. Extract all unique issue URLs and append `Closes <url>` lines to the PR body. This is best-effort — if no plan files or no issue refs are found, the PR body is unchanged.

## Files to Modify

All 4 PR-creating files in `kit/plugins/git-agent/`:

| File | Component | PR creation step |
|------|-----------|-----------------|
| `skills/pr-agent/SKILL.md` | Foreground skill | Step 5 |
| `agents/agent-pr.md` | Background agent | Step 5 |
| `skills/ship/SKILL.md` | Combined skill | Step 8 |
| `agents/agent-ship.md` | Background agent | Step 8 |

`skills/ship-autonomous/SKILL.md` delegates to `pr-agent`, so it inherits the change automatically.

Additionally:
- `CHANGELOG.md` — new entry for the feature
- `.claude-plugin/marketplace.json` — version bump (minor: new feature)

## Implementation Details

### 1. Shared script: `scripts/extract-plan-issues.sh`

Create a new script at `kit/plugins/git-agent/scripts/extract-plan-issues.sh` that encapsulates the issue-scanning logic. All 4 PR-creating files call this script instead of duplicating the logic.

**Script behavior:**
- Accepts one argument: the base branch name
- Runs `git diff --name-only <base>...HEAD -- '*.html'` to find HTML files changed on the branch
- For each file, extracts `<meta name="plan-issue" content="...">` URLs via `grep`
- Deduplicates URLs
- Outputs one URL per line to stdout (empty output = no issues found)
- Exits 0 always (best-effort — never blocks PR creation)

```bash
#!/usr/bin/env bash
set -euo pipefail
base="${1:?Usage: extract-plan-issues.sh <base-branch>}"
git diff --name-only "$base"...HEAD -- '*.html' 2>/dev/null \
  | while IFS= read -r f; do
      grep -oP '<meta\s+name="plan-issue"\s+content="\K[^"]+' "$f" 2>/dev/null || true
    done \
  | sort -u
```

### 2. PR body template update

The body template adds a conditional `## Linked Issues` section:

```markdown
## Summary
- <bullet 1>
- <bullet 2>

## Changes
<brief description of what changed and why>

## Linked Issues
Closes <url-1>
Closes <url-2>
```

The `## Linked Issues` section is only included when the script outputs one or more URLs. When no issue refs are found, omit the section entirely — no empty heading.

### 3. Per-file changes

Each file gets a new sub-step that calls the shared script, plus an update to the body template instructions.

**`skills/pr-agent/SKILL.md`** — Insert "Step 4.5: Scan for Issue References" between Step 4 (Push) and Step 5 (Create PR). Step 4.5 runs:
```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/extract-plan-issues.sh" <base>
```
Update Step 5 to note: if Step 4.5 returned URLs, append `## Linked Issues` with a `Closes <url>` line per URL. No `allowed-tools` change needed — `Bash(git *)` doesn't cover the script, but `Bash(gh *)` and `Bash(glab *)` are shell-glob patterns; the skill also has `Grep` and `Read`. Actually, `Bash(git *)` restricts Bash to `git` commands only. We need to add `Bash(bash *)` or use a more permissive pattern. Simpler: inline the logic directly (grep piped through git diff) under existing `Bash(git *)` since `git diff` is the entry point.

**Revised approach for pr-agent and ship (restricted Bash):** Instead of calling a script, inline the two commands as a single `git diff ... | xargs grep ...` pipeline. The script exists for agent-pr and agent-ship (which have unrestricted `Bash`).

For **pr-agent** and **ship** (restricted `Bash(git *)`):
- Step instructions say: "Run `git diff --name-only <base>...HEAD -- '*.html'` to list HTML files changed on this branch. For each file listed, use `Grep` to search for `<meta name="plan-issue" content="` and extract the URL. Collect unique URLs."
- This uses `Bash(git diff ...)` + `Grep` tool — both already allowed.

For **agent-pr** and **agent-ship** (unrestricted `Bash`):
- Step instructions say: "Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/extract-plan-issues.sh <base>` to collect issue URLs from plan files on this branch."

**Summary of changes per file:**

| File | New step | Mechanism | Tools change? |
|------|----------|-----------|--------------|
| `skills/pr-agent/SKILL.md` | Step 4.5 | `git diff` + `Grep` tool | No |
| `agents/agent-pr.md` | Step 4.5 | Shared script | No |
| `skills/ship/SKILL.md` | Step 7.5 | `git diff` + `Grep` tool | No |
| `agents/agent-ship.md` | Step 7.5 | Shared script | No |

### 4. Edge cases

- **No plan files on branch:** `git diff --name-only` returns nothing → skip section
- **Plan files without issue refs:** grep finds no `<meta name="plan-issue">` → skip section
- **Multiple plan files with the same issue:** deduplicate URLs
- **Non-standard plan directory:** branch diff is path-agnostic — finds all `.html` files changed on the branch
- **GitLab issues:** `Closes <url>` syntax works for both GitHub and GitLab
- **Plan committed on main before branching:** not captured (by design — branch-scoped only)

## Versioning

- Bump git-agent from `3.9.3` → `3.10.0` (minor: new feature added to existing skills)
- Update `.claude-plugin/marketplace.json` version for `git-agent` entry
- Add CHANGELOG entry documenting the feature

## Interview Decisions

- **Discovery scope:** Branch diff only — no fallback to directory scan. Plans committed on main before branching are intentionally excluded.
- **Linking keyword:** `Closes` (auto-closes the issue when the PR merges).
- **Deduplication:** Shared script (`scripts/extract-plan-issues.sh`) for agents with unrestricted Bash; inline `git diff` + `Grep` for skills with restricted `Bash(git *)`.

## Verification

1. Create a plan from an issue: `/plan-agent:planning #<issue-number>`
2. Verify the plan file contains `<meta name="plan-issue" content="...">`
3. Make changes and use any PR creation path (`/git-agent:pr-agent`, `/git-agent:ship`, etc.)
4. Verify the PR body includes `## Linked Issues` with `Closes <url>`
5. Verify that when no plan-issue meta exists, the section is omitted
6. Verify that duplicate issue URLs across multiple plan files are deduplicated
