# Platform Detection and CLI Auth Failures

Procedure detail for **Step 1: Pre-flight Guards**. Run this after the clean-tree,
detached-HEAD, and default-branch guards have passed.

## Detect platform

Run `git remote get-url origin`. Determine the platform from the URL:

- Contains `github.com` → **GitHub** (use the `gh` commands)
- Contains `gitlab.com` or `gitlab` → **GitLab** (use the `glab` commands)
- If unclear, check which CLI is available: try `gh --version` then
  `glab --version`. Use whichever is installed.
- If neither can be determined, ask the user which platform they use and
  **STOP**.

## CLI not available or not authenticated

For GitHub: run `gh auth status`. If `gh` is not installed or returns an auth
error, output:

```
GitHub CLI is required. Install it from https://cli.github.com/ and run `gh auth login`.
```

and **STOP**.

For GitLab: run `glab auth status`. If `glab` is not installed or returns an
auth error, output:

```
GitLab CLI is required. Install it from https://gitlab.com/gitlab-org/cli and run `glab auth login`.
```

and **STOP**.
