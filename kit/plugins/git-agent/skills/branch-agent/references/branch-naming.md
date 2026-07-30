# Branch Name Resolution (Steps 2, 2a, 2b)

Bundled reference for the `branch-agent` skill. Covers resolving `$ARGUMENTS`
into a branch name, auto-generating a name from working-tree changes, and
appending the mandatory date suffix.

## Step 2: Resolve Branch Name

Read `$ARGUMENTS`.

**Case A — `$ARGUMENTS` is empty or whitespace-only:** Run
`git status --porcelain=v1`.

- **If output is empty** (clean working tree): output "Provide a branch name.
  Example: branch-agent feat/login-fix" and **STOP**.
- **If output is non-empty** (working tree has changes): auto-generate the
  branch name as described in Step 2a, then proceed to Step 2b.

**Case B — `$ARGUMENTS` contains spaces or reads as a descriptive phrase:**
Convert it to a human-readable slug — lowercase, replace spaces and special
characters with `-`, collapse consecutive dashes, strip leading/trailing
dashes. Keep the user's words whole; if the slug exceeds 60 characters, drop
trailing words (never chop mid-word). If a single word alone exceeds 60
characters (so no word boundary exists to trim at), hard-truncate that word
at 60 characters as a last resort. Example:
`"add allowed tools to skills"` → `"add-allowed-tools-to-skills"`. Use the
slug as the branch name and proceed to Step 2b.

**Case C — `$ARGUMENTS` is already a valid branch name** (no spaces): Use it
verbatim as the branch name. Do not slugify, abbreviate, or transform it.
Proceed to Step 2b.

## Step 2a: Auto-Generate Branch Name from Changes

Use this format: `<type>/<scope>-<description>` (or `<type>/<description>` if
the scope is omitted). Total length ≤ 60 characters — this reserves 11 chars
for the `-YYYY-MM-DD` suffix appended in Step 2b so the final branch name
stays within 72 chars.

**Type inference (first match wins):**

1. Only markdown / `docs/**` / `README*` changed → `docs`
2. Only test files (`**/test/**`, `**/tests/**`, `*.test.*`, `*_test.*`,
   `tests/fixtures/**`) → `test`
3. Only CI configs (`.github/workflows/**`, `.gitlab-ci.yml`, `.circleci/**`)
   → `ci`
4. Only build/dependency manifests (`package.json`, `pnpm-lock.yaml`,
   `Cargo.toml`, `pyproject.toml`, etc.) → `build`
5. Diff is pure renames/moves with no logic delta → `refactor`
6. New files added under source dirs → `feat`
7. Existing source files modified, diff < 20 lines → `fix`
8. Existing source files modified, diff ≥ 20 lines → `feat`
9. Otherwise → `chore`

**Scope inference:**

Run `git status --porcelain=v1` and group changed paths by their first path
segment. Pick the group with the most files and use that segment as `<scope>`.
If the top group contains ≤50% of changed files, OR more than 2 groups contain
files, **omit the scope** entirely (use `<type>/<description>`).

**Description inference:**

From the changed file basenames and `git diff --stat`, write the description
as a short verb-led phrase (3–7 words) that reads like a commit subject a
human would write: start with an imperative verb (`add`, `fix`, `update`,
`remove`, `rename`, `improve`, …) followed by what changed. Lowercase,
hyphen-separated, alphanumeric only. Strip non-alphanumeric characters;
collapse repeated hyphens; trim leading/trailing hyphens.

Readability rules:

- Use whole dictionary words — never abbreviate a word to save space
  (`validation`, not `valid` or `val`; `config`, not `cfg`)
- Prefer describing *what the change does* over listing filenames
- If the name runs long, drop the least important trailing words instead of
  shortening individual words

Examples:

| Change | Good | Bad |
|--------|------|-----|
| New login validation in `src/auth/` | `feat/src-add-login-form-validation` | `feat/src-login-form-valid` |
| Typo fixes across README files | `docs/fix-readme-typos` | `docs/rdme-typo-fx` |
| CI workflow updated to Node 22 | `ci/update-workflow-to-node-22` | `ci/wf-node22` |

**Validation:**

- Lowercase only; characters in `[a-z0-9/-]`; no leading/trailing hyphens
- Total length ≤ 60 chars (drop trailing description words to fit; never chop
  mid-word; never truncate the type or scope)
- Must contain a `/` separator after the type

If validation fails, regenerate once with `chore` as the type and a shortened
description. If it still fails, fall back to `chore/auto-branch` and proceed.

Output one line before continuing:

> Auto-generated branch name from working tree changes: `<branch>`

Then proceed to Step 2b.

## Step 2b: Append Date Suffix

Run:

```
date +%Y-%m-%d
```

Append the result to the resolved branch name with a `-` separator, producing
the final branch name: `<branch>-<YYYY-MM-DD>` (e.g. `feat/login-fix` →
`feat/login-fix-2026-04-17`). This always runs, regardless of whether the
name came from Case A, B, or C.

If the final name exceeds 72 characters, drop trailing words from the
description portion until it fits. Never chop mid-word, and never truncate
the date suffix, the type prefix, or the scope segment.

Use this date-suffixed name as `<branch>` for the rest of the flow. Proceed
to Step 3.
