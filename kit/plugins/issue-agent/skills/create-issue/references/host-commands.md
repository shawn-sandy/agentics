# Host Command Reference: `gh` vs `glab`

Use this table to look up the correct CLI flags per host. The most common mistake is using `--body` (GitHub) when `--description` (GitLab) is required.

## Issue create

| Action | GitHub (`gh`) | GitLab (`glab`) |
|--------|--------------|----------------|
| Create issue | `gh issue create` | `glab issue create` |
| Set title | `--title "..."` | `--title "..."` |
| Set body | `--body "..."` | `--description "..."` |
| Add labels | `--label "bug,p1"` | `--label "bug,p1"` |
| Assign user | `--assignee "@me"` | `--assignee "@me"` |
| Open in browser | `--web` | `--web` |
| Milestone | `--milestone "v1.0"` | `--milestone "v1.0"` |

## Issue view

| Action | GitHub (`gh`) | GitLab (`glab`) |
|--------|--------------|----------------|
| View issue in browser | `gh issue view <number> --web` | `glab issue view <id> --web` |
| View issue in terminal | `gh issue view <number>` | `glab issue view <id>` |

**Extracting the issue number from CLI output:**
- `gh issue create` returns the full URL, e.g. `https://github.com/owner/repo/issues/42`. Extract with: `grep -oE '[0-9]+$'`
- `glab issue create` returns a similar URL. Same extraction pattern applies.

## Issue list / search

| Action | GitHub (`gh`) | GitLab (`glab`) |
|--------|--------------|----------------|
| List open issues | `gh issue list` | `glab issue list` |
| Search by text | `--search "keyword"` | `--search "keyword"` |
| Filter by label | `--label "bug"` | `--label "bug"` |
| Limit results | `--limit 10` | `--per-page 10` |

## Auth and repo checks

| Action | GitHub (`gh`) | GitLab (`glab`) |
|--------|--------------|----------------|
| Check auth status | `gh auth status` | `glab auth status` |
| Log in | `gh auth login` | `glab auth login` |
| View current repo | `gh repo view` | `glab repo view` |

## Detecting GitLab self-hosted

If `git remote get-url origin` returns a URL that is not `github.com` and is not `gitlab.com`, it may be a self-hosted GitLab instance. `glab` works with self-hosted instances when configured via `glab config set --host <hostname>`. In this case, alert the user and suggest they verify `glab auth status` against their host.

## Common label conventions

| Intent | Typical label (GitHub) | Typical label (GitLab) |
|--------|----------------------|----------------------|
| Bug | `bug` | `bug` |
| Feature | `feature`, `enhancement` | `feature` |
| Needs investigation | `needs-investigation` | `needs-triage` |
| Docs | `documentation` | `documentation` |
| Low priority | `p3-low` | `priority::low` |
| High priority | `p1-high` | `priority::high` |
