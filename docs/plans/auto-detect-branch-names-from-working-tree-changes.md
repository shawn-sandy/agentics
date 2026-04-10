# Plan: Auto-Detect Branch Names from Working Tree Changes

## Context

The `branch-agent` skill in `kit/plugins/git-agent` currently requires the user to
supply a branch name via `$ARGUMENTS`. If the argument is empty, the skill stops
with an error message ("Provide a branch name…"). This forces the user to invent
and type a name even when their working tree already contains the changes the
branch is meant to capture.

This change adds an **implicit auto-detection** path: when `$ARGUMENTS` is empty
**and** the working tree has uncommitted changes, the skill inspects those
changes and generates a branch name automatically following the same
conventional `<type>/<scope>-<description>` format used by `commit-agent`. The
branch is then created without an additional confirmation prompt, matching the
existing "fast path" behavior of the skill.

This removes friction in the common workflow: hack on `main`, realize you need
a branch, run `branch-agent` with no arguments, get a sensibly-named branch
created from `origin/<default>` with no upstream tracking.

---

## Files to Modify

| File | Change |
|------|--------|
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Add auto-detect logic to Step 2; update frontmatter `argument-hint`; update header description |
| `kit/plugins/git-agent/CHANGELOG.md` | Add a `## [Unreleased]` (or next minor) entry describing the new behavior |
| `.claude-plugin/marketplace.json` | Bump `git-agent` plugin `version` (MINOR — new behavior added to existing skill) |

No other files (plugin.json, README.md, other skills) need changes for the
core feature. README and plugin.json remain valid as-is, but the README's
`branch-agent` section should be updated to mention the new behavior.

| File (optional but recommended) | Change |
|---|---|
| `kit/plugins/git-agent/README.md` | Document the new empty-arg auto-detect behavior under the branch-agent section |

---

## Design

### Trigger

**Implicit** when `$ARGUMENTS` is empty or whitespace-only. No new flag, no
keyword. Existing non-empty behavior is unchanged — names are still used
verbatim, no transformation.

### Naming Format

`<type>/<scope>-<kebab-description>`

- **`<type>`** — Mirror the conventional commit types `commit-agent` already
  uses: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`,
  `ci`, `build`. Inferred from the file paths and diff content of the
  uncommitted changes. Default to `chore` when nothing more specific applies.
- **`<scope>`** — The most-changed top-level directory in the working tree
  (same heuristic as `commit-agent`). Omit the scope segment entirely if the
  changes span more than two top-level directories.
- **`<kebab-description>`** — A short (≤5 words) lowercase, hyphen-separated
  summary derived from the changed files / diff hunks. Strip non-alphanumeric
  characters; collapse repeated hyphens; trim trailing hyphens.

**Total length cap:** 60 characters. Truncate the description segment (not the
type or scope) at a word boundary if needed.

### Type Inference Heuristics

Apply in order; first match wins:

1. Only `*.md`, `docs/**`, or `README*` changed → `docs`
2. Only test files (`**/test/**`, `**/tests/**`, `*.test.*`, `*_test.*`,
   `tests/fixtures/**`) changed → `test`
3. Only CI config changed (`.github/workflows/**`, `.gitlab-ci.yml`,
   `.circleci/**`) → `ci`
4. Only build/dependency manifests changed (`package.json`, `pnpm-lock.yaml`,
   `Cargo.toml`, `pyproject.toml`, etc.) → `build`
5. Diff contains only deletions/moves with no behavior change signal →
   `refactor`
6. New files added under source directories → `feat`
7. Changes to existing source files → `fix` if diff is small (<20 lines), else
   `feat`
8. Fallback → `chore`

These heuristics are documented inline in the skill so Claude can apply them
consistently during execution.

### Scope Inference

Run `git status --porcelain=v1` to enumerate modified paths. Group by first
path segment, count files per group, pick the group with the highest count.
If the top group has ≤50% of files OR there are >2 groups with files, omit
the scope.

### Description Inference

From the changed file basenames and (if needed) `git diff --stat` output,
synthesize 2–5 keywords describing the change. Lowercase, join with hyphens.

### Example

Changes detected:
```
M  kit/plugins/git-agent/skills/branch-agent/SKILL.md
M  kit/plugins/git-agent/CHANGELOG.md
```

Inference:
- Top-level group: `kit` (2/2 files) → scope `kit/plugins/git-agent` (collapse
  to most-specific shared prefix? — see Open Decision below)
- Type: only existing source files modified, small diff → `feat` (new
  capability being added)
- Description: derived from `branch-agent` + `auto-detect` → `auto-detect-branch-names`

Result: `feat/git-agent-auto-detect-branch-names`

---

## SKILL.md Changes (Concrete)

### Frontmatter

Update `argument-hint`:

```yaml
argument-hint:
  Branch name (optional). If omitted and the working tree has uncommitted
  changes, the name is auto-generated from those changes using the
  `<type>/<scope>-<description>` convention.
```

### Step 2 Rewrite

Replace the current Step 2 ("Resolve Branch Name") with:

```markdown
## Step 2: Resolve Branch Name

Read `$ARGUMENTS`.

**Case A — `$ARGUMENTS` is non-empty:** Use it verbatim as the branch name.
Do not slugify, abbreviate, or transform it. Skip to Step 3.

**Case B — `$ARGUMENTS` is empty or whitespace-only:** Run
`git status --porcelain=v1`.

- **If output is empty** (clean working tree): output "Provide a branch name.
  Example: branch-agent feat/login-fix" and **STOP**.
- **If output is non-empty** (working tree has changes): auto-generate the
  branch name as described in Step 2a, then proceed to Step 3.

## Step 2a: Auto-Generate Branch Name from Changes

Use this format: `<type>/<scope>-<description>` (or `<type>/<description>` if
scope is omitted). Total length ≤ 60 characters.

**Type inference (first match wins):**

1. Only markdown / `docs/**` / `README*` changed → `docs`
2. Only test files (`**/test/**`, `*.test.*`, `*_test.*`, `tests/fixtures/**`)
   → `test`
3. Only CI configs (`.github/workflows/**`, `.gitlab-ci.yml`) → `ci`
4. Only build/dependency manifests (`package.json`, `pnpm-lock.yaml`,
   `Cargo.toml`, `pyproject.toml`, etc.) → `build`
5. Diff is pure renames/moves with no logic delta → `refactor`
6. New files added under source dirs → `feat`
7. Existing source files modified, diff < 20 lines → `fix`
8. Existing source files modified, diff ≥ 20 lines → `feat`
9. Otherwise → `chore`

**Scope inference:**

Group changed paths by their top-level directory. Pick the group with the
most files. Use it as `<scope>`. If the top group contains ≤50% of changed
files, OR more than 2 groups contain files, **omit the scope**.

**Description inference:**

From the changed file basenames and `git diff --stat`, extract 2–5 keywords
that describe the change. Lowercase, hyphen-separated, alphanumeric only.

**Validation:**

- Lowercase only; characters in `[a-z0-9/-]`; no leading/trailing hyphens
- Total length ≤ 60 chars (truncate the description segment at a word
  boundary)
- Must contain a `/` separator after the type

If validation fails, regenerate once with `chore` type and a shortened
description. If it still fails, fall back to `chore/auto-branch` and proceed.

Output one line before continuing:

> Auto-generated branch name from working tree changes: `<branch>`

Then proceed to Step 3.
```

### Header Description (line 16)

Append a sentence:

> When called with no argument and the working tree has uncommitted changes,
> the branch name is auto-generated from those changes.

---

## Reused Existing Code / Conventions

- **Type vocabulary** — pulled directly from `commit-agent`'s SKILL.md
  (`feat | fix | docs | refactor | test | chore | perf | style | ci | build`)
  to keep the two skills consistent. Path:
  `kit/plugins/git-agent/skills/commit-agent/SKILL.md`
- **Scope heuristic (most-changed top-level dir)** — borrowed from
  `commit-agent`'s scope-derivation rule, same file
- **Default-branch detection chain** — already implemented in Step 3 of
  `branch-agent`, unchanged
- **`git status --porcelain=v1`** — standard porcelain output already familiar
  to other git-agent skills
- **`AskUserQuestion`** is *not* used (per user decision: auto-create without
  prompt). It can be removed from `allowed-tools` in the frontmatter if no
  other step uses it — verify and drop if unused.

---

## Open Decision (low-risk, defaulting)

**Scope granularity:** Should `<scope>` be the literal top-level directory
(e.g. `kit`) or a more specific descendant prefix (e.g. `kit/plugins/git-agent`)?

**Default for this plan:** Use only the **first path segment** (`kit`) — same
as `commit-agent`'s behavior — for consistency and brevity. If users ask for
deeper scopes later, that's a follow-up enhancement.

---

## Verification

End-to-end manual checks (run after editing the skill):

1. **Clean tree, empty arg → error path**
   - In a clean repo: invoke `branch-agent` with no argument
   - Expect: original "Provide a branch name…" message and no branch created
2. **Dirty tree, empty arg → auto-name path**
   - Make a small markdown edit in `kit/plugins/git-agent/`
   - Invoke `branch-agent` with no argument
   - Expect: a branch named like `docs/git-agent-<keywords>` is created from
     `origin/<default>`, no upstream tracking, no commit made, working-tree
     edits preserved
3. **Dirty tree, explicit name → unchanged behavior**
   - With dirty tree, invoke `branch-agent feat/my-name`
   - Expect: branch created as `feat/my-name` verbatim, no auto-detection
4. **Detached HEAD / no origin / not a repo** — guards in Step 1 still fire
   before Step 2 runs
5. **Type inference smoke tests** — repeat #2 for each scenario:
   - Only `*.md` changed → `docs/...`
   - Only `**/tests/**` changed → `test/...`
   - Only `.github/workflows/**` changed → `ci/...`
   - Mixed source change spanning 3+ top-level dirs → scope omitted
6. **Length cap** — synthesize a long change set; verify the resulting branch
   name is ≤ 60 chars and ends on a word boundary
7. **Marketplace validation** — `.claude/settings.json` auto-validates
   `marketplace.json` after edit; confirm no JSON errors after the version
   bump

## Versioning

- **Bump:** MINOR (new behavior on an existing skill, no breaking change to
  existing arg semantics)
- Update `version` in `.claude-plugin/marketplace.json` for the `git-agent`
  entry
- Add a `CHANGELOG.md` entry under `kit/plugins/git-agent/`:
  - `### Added` — auto-detect branch names from working tree changes when
    `branch-agent` is invoked with no argument
- Commit message: `feat(kit/plugins/git-agent): auto-detect branch names from changes`
- Per project convention, include this plan file in the same commit
