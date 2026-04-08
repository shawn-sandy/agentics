# Plan: Fix issues found in git-agent `new-branch` review

> NOTE: This plan file should be renamed to something descriptive after
> approval (e.g., `fix-marketplace-trailing-comma-and-stale-plan.md`)
> per `.claude/rules/plan-hygiene.md`.

## Context

A review of the in-flight changes on `fix/sub-dir` (the new `new-branch`
skill on the `git-agent` plugin, version bump to `1.2.0`, README +
CHANGELOG updates, and the design plan) surfaced one critical bug and a
few smaller inconsistencies. None of them affect the skill body itself —
the `SKILL.md` is well structured. The problems are in the surrounding
metadata and documentation.

This plan corrects them so the branch is safe to commit and the
marketplace entry stays valid.

## Steps

### 1. Fix invalid JSON in `.claude-plugin/marketplace.json`

A trailing comma was added after the closing `}` of the
`agentic-plugin-dev` entry on line 228. JSON forbids trailing commas in
arrays — this will break marketplace validation and plugin discovery.

- File: [.claude-plugin/marketplace.json](/.claude-plugin/marketplace.json)
- Change: line 228 — replace `},` with `}`

### 2. Re-run marketplace.json validation locally

After step 1, verify the file parses cleanly:

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
```

The `.claude/settings.json` auto-validation hook should catch this on
the next Edit/Write — confirm it still triggers and is healthy. If the
hook is silent, that itself is a regression worth investigating.

### 3. Sync `plugin.json` description and keywords with `marketplace.json`

- File: [kit/plugins/git-agent/.claude-plugin/plugin.json](/kit/plugins/git-agent/.claude-plugin/plugin.json)
- Update `description` to match `marketplace.json`:
  `"Automated git workflow — create branches, commit with conventional messages, and create PRs"`
- Add `"branch"` to the `keywords` array so discovery surfaces the new
  capability. Final keywords array:
  `["git", "commit", "pr", "pull-request", "conventional-commits", "automation", "branch"]`

Keeps the two manifests aligned so plugin source reads correctly
standalone.

### 4. Repair the stale plan file (edit in place)

- File: [docs/plans/branch-from-origin-default-without-switching.md](/docs/plans/branch-from-origin-default-without-switching.md)
- Replace every `kit/plugins/dev-tools/` reference with
  `kit/plugins/git-agent/`. Specifically:
  - Line 6: `kit/plugins/dev-tools/skills/new-branch/SKILL.md` →
    `kit/plugins/git-agent/skills/new-branch/SKILL.md`
  - Line 48: same replacement in the "Files to modify" heading
  - Line 160: `kit/plugins/dev-tools/README.md` →
    `kit/plugins/git-agent/README.md`
  - Line 192: the `claude --plugin-dir ~/devbox/agentics/kit/plugins/dev-tools`
    verification command → `kit/plugins/git-agent`
- Remove the resolved "Unresolved questions" section entry (line 244
  onward) about the plan filename — the file has already been renamed
  to `branch-from-origin-default-without-switching.md`, so the question
  is moot.

### 5. Verify nothing else regressed

Run from the repo root:

```bash
# JSON parses
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null

# Plugin manifest parses
python3 -m json.tool kit/plugins/git-agent/.claude-plugin/plugin.json > /dev/null

# git-agent now lists three skills
ls kit/plugins/git-agent/skills/
# Expect: commit-agent  new-branch  pr-agent  ship  (or similar)
```

Then load the plugin locally and confirm the skill activates:

```bash
claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent
# In session: "create a new branch for testing the fetch change"
```

The end-to-end verification scenarios in the original plan
(`branch-from-origin-default-without-switching.md` §Verification) still
apply — clean tree happy path, dirty tree Proceed/Stop, conflicting
changes, stale `origin/HEAD`, pattern scan recommendation. Run them
once after fixes land.

## Files Modified

| File | Change |
|---|---|
| `.claude-plugin/marketplace.json` | Remove trailing comma on line 228 |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Sync description, add `branch` keyword |
| `docs/plans/branch-from-origin-default-without-switching.md` | Fix `dev-tools` → `git-agent` references; drop resolved question |

## Out of scope (Next Steps)

- **Auto-stash option in `new-branch`** — already noted in the original
  plan's Next Steps; defer until the simple Proceed/Stop flow has been
  exercised in practice.
- **Update local `<default>` after the fact** — likewise deferred per
  the original plan.
- **Investigate why the auto-validation hook didn't catch the trailing
  comma** — if step 2 reveals the hook is broken, file a follow-up.
- **Rename this plan file** to a descriptive name before commit, per
  `.claude/rules/plan-hygiene.md`.

## Unresolved questions

1. Should the rename of this plan file (from `dazzling-painting-token.md`
   to something descriptive) happen now as part of this fix, or be
   handled separately via `/plan-hygiene`?
