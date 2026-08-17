# PR/MR Detection, Base Branch, Issue Links, and Body Template

Procedure detail for **Step 6**, **Step 7**, **Step 7.5**, and **Step 8**. Run
these in the same strict order as the steps in `SKILL.md`.

## Step 6: Check for Existing PR/MR

For GitHub, run:

```
gh pr view --json state,url
```

For GitLab, run:

```
glab mr view --output json
```

If the result contains `"state":"OPEN"` (GitHub) or `"state": "opened"`
(GitLab), output: "Pushed to existing PR/MR: <url>" and **STOP**. Do not
create a duplicate. The new commit is already on the remote.

If the result contains `"state":"MERGED"` or `"state":"CLOSED"` (GitHub) or
`"state": "merged"` or `"state": "closed"` (GitLab), or if the command exits
non-zero (no PR/MR found), proceed to Step 7 and create a fresh PR/MR.

## Step 7: Detect Base Branch

Run:

```
git symbolic-ref refs/remotes/origin/HEAD
```

Strip the `refs/remotes/origin/` prefix to get the base branch name. If this
command fails, fall back to `main`, then `master` (try
`git rev-parse --verify main` to confirm existence before falling back).

## Step 7.5: Scan for Issue References

Look for plan files on this branch that link to GitHub or GitLab issues.

Run:
```
git diff --name-only <base>...HEAD -- 'docs/plans/*.html' 'docs/plans/**/*.html'
```

For each file listed, use `Grep` to search for the pattern `<meta name="plan-issue" content="` and extract the URL value. Collect all unique URLs found.

If any URLs are found, include a `## Linked Issues` section in the PR/MR body (Step 8) with one `Closes <url>` line per unique URL. If no plan files are found or none contain issue references, skip this section entirely.

## Step 8: Create Pull/Merge Request

Gather content:

```
git log <base>..HEAD --oneline
git diff <base>...HEAD --stat
```

**Title:** short summary of the branch's changes (≤ 70 characters), imperative
mood.

**Body:** use this structure:

```
## Summary
- <bullet 1>
- <bullet 2>

## Changes
<brief description of what changed and why>

## Test Plan
- [ ] <command or check a reviewer runs to verify this>

## Linked Issues
Closes <url>
```

**Test Plan rules:** this skill does not run tests, so list what a reviewer
should run (the project's test/lint commands, plus any manual step for
user-facing changes). If a check was actually run earlier in this session,
mark it `[x]` and name the result. **Never mark a box that was not verified** —
an unchecked box is honest, a false checkmark is not.

Omit the `## Linked Issues` section entirely if Step 7.5 found no issue references.

**Worked example** — the shape and honesty bar to match.

Title: `fix(gallery): escape HTML in card titles`

```markdown
## Summary
- Escape user-supplied card titles before they are interpolated into gallery HTML
- Add regression coverage for titles containing `<script>` and `&`

## Changes
Card titles flowed into the generated `index.html` unescaped, so a title
containing markup broke the gallery layout. `renderCard()` now routes every
title through `escapeHtml()` before interpolation.

## Test Plan
- [x] `node --test tests/gallery.test.mjs` — 14 passing, including the two new
  title-escaping cases
- [ ] Open `docs/media/index.html` in a browser and confirm a title containing
  `<b>` renders literally

## Linked Issues
Closes https://github.com/acme/widgets/issues/482
```

For GitHub, run:

```
gh pr create --title "<title>" --body "<body>"
```

For GitLab, run:

```
glab mr create --title "<title>" --description "<body>"
```

Output the PR/MR URL and **STOP**.
