---
name: plugin-manager
description: "Manages plugin entries in marketplace.json — add, remove, bump versions, and update metadata. Use when the user asks to list, add, remove, or bump a plugin."
allowed-tools: AskUserQuestion, Edit, Glob, Read, Write
---

## Overview

Manages individual plugin entries within an existing `marketplace.json` file. Handles listing, adding, removing, updating, and version bumping with changelog management.

Follow these steps, adapt as needed for context.

## When not to use

Does not create marketplace infrastructure from scratch — use marketplace-builder. Does not scaffold new plugins — use plugin-creator. Does not commit or push to git — suggests commit messages only.

---

## Step 0: Disambiguation

If the user's intent could mean marketplace infrastructure setup rather than entry management, clarify:

- **"set up a marketplace"** or **"create a marketplace"** — Redirect: "For creating marketplace infrastructure from scratch, use `marketplace-builder`. I manage entries in an existing marketplace."
- **"create a plugin"** — Redirect: "For scaffolding a new plugin, use `plugin-creator`. I manage marketplace registry entries."

If the user clearly wants to manage entries, proceed.

---

## Step 1: Locate Marketplace File

Search for `marketplace.json` in the current working directory only:

1. Use `Glob` to find `.claude-plugin/marketplace.json` in CWD
2. If not found, ask the user: "I couldn't find `.claude-plugin/marketplace.json` in the current directory. Can you provide the path?"
3. Do NOT traverse parent directories or search recursively

Once found, read the file and present a brief status:

> "Found marketplace `[name]` v[version] with [count] plugins."

---

## Step 2: Determine Operation

Infer the operation from user intent. If ambiguous, ask which operation they want:

### List

Present a formatted table of all plugins:

```
| Name | Version | Category | Description |
|------|---------|----------|-------------|
| ...  | ...     | ...      | ...         |
```

### Add

Add a new plugin entry. Gather required fields:

1. **name** — Plugin name (kebab-case, unique within marketplace)
2. **source** — Relative path to plugin directory (e.g., `./plugins/[name]`)
3. **version** — Semantic version (e.g., `1.0.0`)
4. **description** — Brief description
5. **category** — One of the standard categories (see `references/marketplace-schema.md`)
6. **tags** — Array of searchable terms

**Before adding:**
- Validate name uniqueness — if a plugin with the same name exists, warn and ask whether to update the existing entry instead
- Validate that the `source` path exists on disk using `Glob`

### Remove

1. Ask which plugin to remove (by name)
2. Show the entry that will be removed
3. Confirm with the user before deleting
4. Remove the entry from the `plugins` array

### Update

1. Ask which plugin to update and which fields to change
2. Show current values vs. proposed changes
3. Confirm before writing

### Bump Version

1. Ask which plugin to bump and the bump type: **patch**, **minor**, or **major**
2. Calculate the new version from the current version
3. Show the version change: `[old] → [new]`
4. Update the version in `marketplace.json`
5. Update or create `CHANGELOG.md` in the plugin's directory using [Keep a Changelog](https://keepachangelog.com/) format
6. **Suggest a commit message** (do NOT stage or commit):
   - Patch: `fix(plugins/[name]): bump version to [new]`
   - Minor: `feat(plugins/[name]): bump version to [new]`
   - Major: `feat(plugins/[name])!: bump version to [new]`

Refer to `references/marketplace-schema.md` for bump trigger rules.

---

## Step 3: Validate After Write

After any write operation (add, remove, update, bump):

1. Read the updated `marketplace.json`
2. Verify valid JSON (parse succeeds)
3. Verify no duplicate plugin names
4. Verify all `source` paths reference existing directories
5. Report any issues found

If validation fails, offer to fix the issue automatically.
