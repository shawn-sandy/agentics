# GitHub Repository Setup

One-time configuration notes for this repository's CI workflows.

## Versioning is manual

Plugin `version` values in `.claude-plugin/marketplace.json` are bumped **manually in the PR** that changes a plugin (see `.claude/rules/marketplace.md`). There is no automatic post-merge version bump and no PR check that rejects manual edits, so no special branch-ruleset bypass is required for versioning.

> **Historical note:** This repo previously used an `auto-version-bump.yml` workflow (which pushed `ci(versions):` commits directly to `main`) plus a `version-guard.yml` PR check. Both were removed when versioning moved back to manual. If a branch-ruleset **bypass** for `github-actions[bot]` was added to let that workflow push to `main`, it is no longer needed and can be removed — unless another `contents: write` workflow relies on it.

## Workflow permissions

Verify **Settings > Actions > General > Workflow permissions** is set to **Read repository contents** (the default). Only workflows that explicitly declare `contents: write` in their `permissions:` block can push — this limits the blast radius of any bypass.

### Workflows in this repo that request elevated permissions

| Workflow | Permission | Notes |
|----------|------------|-------|
| `update-readme.yml` | `pull-requests: write` | Uses `claude-code-action` to open PRs rather than pushing directly to `main`. |

**If you add a new workflow with `contents: write`**, review whether it could inadvertently push to `main` without a PR. If it does, either scope it to a branch or run it under a dedicated App identity.

## Related Files

- `.claude-plugin/marketplace.json` — the registry whose `version` fields are bumped manually
- `.claude/rules/marketplace.md` — the versioning rules and bump table
- `scripts/merge-marketplace.mjs` — merge driver that keeps the higher semver when two branches bump the same plugin
