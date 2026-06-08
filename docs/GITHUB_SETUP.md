# GitHub Repository Setup

One-time configuration steps required for CI workflows to function correctly.

## Branch Ruleset Bypass for Auto-Version-Bump

The `auto-version-bump.yml` workflow pushes version bump commits directly to `main` after a plugin change merges. This requires `github-actions[bot]` to bypass the branch ruleset's "Require a pull request before merging" rule.

### Why

The repo's branch ruleset requires all changes to `main` go through a pull request. The version bump workflow needs an exception because:

1. It runs *after* a merge to `main` (triggered by `push` to `main` on `kit/plugins/**`)
2. Creating a PR from a bot adds complexity and requires separate repo permissions
3. Direct push with loop guards is simpler and has fewer failure modes

### Loop Guards

Three mechanisms prevent infinite loops:

| Guard | Location | Effect |
|-------|----------|--------|
| `[skip ci]` in commit message | `auto-version-bump.yml` job `if:` | Skips the workflow entirely for CI-generated commits |
| `ci(versions):` prefix check | `auto-version-bump.yml` job `if:` | Redundant safety — also skips CI-prefixed commits |
| `cancel-in-progress: false` | `auto-version-bump.yml` concurrency | Prevents concurrent bump runs from racing |

### Configuration Steps

1. Go to **Settings > Rules > Rulesets**
2. Select the ruleset protecting `main` (or the one with "Require a pull request before merging")
3. Click **Bypass list** (or "Add bypass")
4. Add `github-actions[bot]` — select type **GitHub App** (not "Team" or "Repository role")
5. Set bypass mode to **Always** (scoped to this ruleset only — does not bypass other rulesets)
6. Save the ruleset
7. Verify **Settings > Actions > General > Workflow permissions** is set to **Read repository contents** (the default). Only workflows that explicitly declare `contents: write` in their `permissions:` block can push — this limits the blast radius of the bypass.

**Recommended:** If your ruleset bundles multiple rules (require PR, require status checks, require linear history), consider splitting "Require a pull request before merging" into its own ruleset so the bypass only exempts the bot from the PR requirement while preserving other protections like status checks.

### Verifying It Works

After configuring the bypass, merge any commit that touches `kit/plugins/**` (e.g. a CHANGELOG entry):

```bash
gh run list --workflow auto-version-bump.yml --limit 1
```

The workflow should complete successfully and push a `ci(versions): auto-bump plugin versions [skip ci]` commit to `main`.

### Security Considerations

The bypass applies to **all workflows** running as `github-actions[bot]`, not just `auto-version-bump`. Any workflow with `contents: write` could push directly to `main` once this bypass is configured.

Workflows in this repo with `contents: write`:

| Workflow | Risk | Mitigation |
|----------|------|------------|
| `auto-version-bump.yml` | Intended use of the bypass | Loop guards (`[skip ci]`, `ci(versions):`) prevent runaway commits |
| `update-readme.yml` | Uses `claude-code-action` with `pull-requests: write`; creates PRs rather than pushing directly | No direct push logic in the workflow — bypass is unused |

**Accepted tradeoff:** A dedicated GitHub App or PAT scoped to only the version-bump workflow would isolate the bypass, but adds operational complexity (secret rotation, app management, token exchange steps). For this repo's threat model — single maintainer, low contributor count — the `github-actions[bot]` bypass with documented audit is sufficient.

**If you add a new workflow with `contents: write`**, review whether it could inadvertently push to `main` without a PR. If it does, either scope it to a branch or consider migrating to a dedicated App identity.

### Related Files

- `.github/workflows/auto-version-bump.yml` — the version bump workflow
- `.github/workflows/version-guard.yml` — PR check that rejects manual version edits
- `scripts/auto-bump-version.mjs` — the bump logic (reads conventional commits, applies semver)
- `.claude-plugin/marketplace.json` — the file updated by the bump
