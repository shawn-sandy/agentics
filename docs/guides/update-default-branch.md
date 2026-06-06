# Update Default Branch Across GitHub Repos

> Session date: 2026-06-06

## Goal

Batch-update the default branch for GitHub repositories whenever they are updated.

## Options

### 1. Set Default for New Repos (GitHub Settings)

Go to **Settings > Repositories > Repository default branch** and set it to `main` (or your preferred name). All newly created repos will use that branch name automatically.

### 2. Batch-Update Existing Repos (CLI Script)

Use the GitHub CLI to find repos that don't match your preferred default and update them:

```bash
# List repos where default branch is not "main"
gh repo list --json name,defaultBranchRef --limit 100 | \
  jq -r '.[] | select(.defaultBranchRef.name != "main") | .name'

# Update default branch for a single repo
gh api -X PATCH "repos/YOUR_USERNAME/REPO_NAME" -f default_branch=main

# Batch update all repos
gh repo list --json name,defaultBranchRef --limit 100 | \
  jq -r '.[] | select(.defaultBranchRef.name != "main") | .name' | \
  while read repo; do
    echo "Updating $repo..."
    gh api -X PATCH "repos/YOUR_USERNAME/$repo" -f default_branch=main
  done
```

### 3. GitHub Action (Automated Enforcement)

Create a workflow that triggers on repository events to enforce the default branch name:

```yaml
name: Enforce Default Branch
on:
  repository_dispatch:
    types: [enforce-default-branch]
  workflow_dispatch:

jobs:
  update-default-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Update default branch
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh api -X PATCH "repos/${{ github.repository }}" \
            -f default_branch=main
```

### 4. Organization-Level Repository Rulesets

If you use a GitHub organization, you can create **repository rulesets** at the org level to enforce branch naming conventions and default branch settings across all repos.

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- `jq` installed for JSON processing (batch script option)
- Appropriate permissions on the repos you want to update

## Notes

- Changing the default branch does **not** rename or delete the old branch — it only changes which branch is shown by default and used as the base for PRs.
- Make sure the target branch (e.g., `main`) exists in each repo before setting it as default.
- For repos migrating from `master` to `main`, consider using `gh repo rename-branch` which also updates open PRs and branch protection rules.
