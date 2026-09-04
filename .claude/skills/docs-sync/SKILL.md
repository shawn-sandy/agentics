---
name: docs-sync
description: Syncs README.md, the how-to guides under docs/guides/how-to/, and CHANGELOG.md with the plugin releases merged since the last docs sync. Use when asked to update the quick docs, sync the docs, or refresh the how-to guides.
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(git log:*), Bash(git show:*), Bash(git diff:*), Bash(node scripts/build-readme-table.mjs:*), Bash(jq:*)
---

# Docs sync

Plugins under `kit/plugins/` change in their own PRs. Three documents describe
them from the outside and drift unless someone re-reads each release:

- `README.md` — the `## Plugins` skill tables and the generated Plugin Reference Table
- `docs/guides/how-to/<plugin>.md` — the "quick docs": one four-part entry per skill
- `CHANGELOG.md` — the root `## [Unreleased]` section, one bullet per release

This skill edits those three files and nothing else. It never commits.
Locally, ship the result with `/git-agent:ship`; in CI,
`.github/workflows/update-docs.yml` commits and opens the PR. Either way the
commit subject must start with `docs: sync` — that prefix is the anchor the
next run searches for.

## Step 1 — Find the window

Find the last sync commit, then list everything after it:

```bash
git log -1 --format='%h %ad %s' --date=short --grep='^docs: sync'
git log --format='%h %ad %s' --date=short <that sha>..HEAD
```

Run them as two plain commands, substituting the sha yourself — no `$(...)`,
because the allowed-tools rules match on the `git log` prefix. No sync commit
at all means a shallow clone: **STOP** and say so. An empty second list means
the docs are current: report `Docs already current — nothing since <sha>` and
**STOP** without editing anything. Every commit listed is a change the docs
may not describe yet — most are plugin releases; Step 2 says what to do with
the rest.

## Step 2 — Read each release from its source of truth

For each commit, oldest first:

1. `git show --stat --format='%B' <sha>` — the message names the plugin(s) and version(s).
2. `git show <sha> -- .claude-plugin/marketplace.json` — the version bump.
3. The plugin's `kit/plugins/<name>/CHANGELOG.md` entry for that version — what
   changed and why. This is the source of truth; the commit message summarises it.
4. `git show <sha> -- 'kit/plugins/<name>/skills/*/SKILL.md'` — a changed
   `argument-hint`, `description`, `disable-model-invocation`, step, gate, or gotcha.

A commit that changes no plugin behaviour (tests only, a README fix, a gallery
re-render) still earns a CHANGELOG bullet when a user would notice the result
— the merge gate passing again, a doc that was wrong — and is otherwise
skipped. Say which in the report.

## Step 3 — How-to guides

Open `docs/guides/how-to/<plugin>.md` for each affected plugin. Every skill
entry has exactly four bullets — **Command**, **Say it instead**, **What
happens**, **Watch out** — and the guide ends with `## Related commands`
(plus `## Related agents` when a shipped agent changes what a caller sees).

- Change an entry only where a stated fact is now wrong, or a new behaviour
  changes what the user sees: a flag, a step, a gate, a failure mode, a
  fallback. Do not rephrase text that is still true.
- **Command** must match the skill's `argument-hint` verbatim.
- A skill with `disable-model-invocation: true` keeps
  `Not available; this skill is command-only (\`disable-model-invocation: true\`).`
  as its **Say it instead** line.
- Add an entry for a new skill in the same shape; remove the entry for a
  deleted skill; rename on a rename.
- Every guide carries the same install line:
  `Install: \`/plugin marketplace add shawn-sandy/agentics\`, then \`/plugin install <name>@agentics-kit\``

If a skill was added or removed, fix that plugin's count and the total in the
README `## How-To Guides` table.

## Step 4 — README.md

1. `node scripts/build-readme-table.mjs` regenerates the Plugin Reference
   Table. Never hand-edit that table — `scripts/verify.sh` runs it with `--check`.
2. In the `## Plugins` section, touch the affected plugin's tables only when a
   skill, command, agent, or hook was added, removed, or renamed, or its
   one-line description no longer matches how it activates. Fold a changed
   fact into the plugin's intro paragraph in one clause; do not rewrite prose.
3. Keep the two plugin counts — the bold line under the title and the
   Overview table — equal to `jq '.plugins | length' .claude-plugin/marketplace.json`.

## Step 5 — CHANGELOG.md

Under `## [Unreleased]`, add one bullet per release to **Added**, **Changed**,
**Fixed**, or **Removed**, newest first within its section, in the house style:

```
- **<What changed, in the user's terms> (<plugin> <version>)** — <the problem, then what it does now; name the files or flags a reader would go looking for> (#<PR>)
```

First search `CHANGELOG.md` for the version string (Grep tool) — a release
whose own PR already added its entry is skipped, not duplicated. Take the substance from the plugin
changelog entry, not from the commit subject.

## Step 6 — Report

Print a table: commit, plugin and version, files changed — or
`skipped — <reason>`. Then `git diff --stat`. Do not commit.
