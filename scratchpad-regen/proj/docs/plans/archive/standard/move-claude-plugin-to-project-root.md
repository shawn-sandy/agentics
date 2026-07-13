---
status: in-progress
created: 2026-02-23
modified: 2026-02-26
---

# Plan: Move .claude-plugin to Project Root (Marketplace Refactor)

## Context

The current structure nests the marketplace manifest inside a `marketplace-data/` subdirectory:

```
agentics/marketplace-data/.claude-plugin/marketplace.json
```

The Claude Code docs ([plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)) show the `.claude-plugin/` folder at the **root** of the directory that gets registered as the marketplace. Moving it to the project root makes `agentics/` itself the marketplace — cleaner, no extra subdirectory, and consistent with the docs pattern.

**Before:**
```
agentics/
├── marketplace-data/
│   ├── .claude-plugin/
│   │   └── marketplace.json     ← source paths use ../plugins/...
│   └── README.md
└── plugins/
    ├── hello-world/
    └── dev-tools/
```

**After:**
```
agentics/
├── .claude-plugin/
│   └── marketplace.json         ← source paths use ./plugins/...
├── plugins/
│   ├── hello-world/
│   └── dev-tools/
└── tests/
```

---

## Steps

1. **Create `.claude-plugin/` at project root**
   - `mkdir agentics/.claude-plugin/`

2. **Move `marketplace.json` to project root**
   - Copy `marketplace-data/.claude-plugin/marketplace.json` → `agentics/.claude-plugin/marketplace.json`

3. **Update source paths in `marketplace.json`**
   - Change `"source": "../plugins/hello-world"` → `"source": "./plugins/hello-world"`
   - Change `"source": "../plugins/dev-tools"` → `"source": "./plugins/dev-tools"`

4. **Remove `marketplace-data/`**
   - Delete `marketplace-data/.claude-plugin/` (now empty)
   - Merge unique content from `marketplace-data/README.md` into root `README.md`, then delete `marketplace-data/` entirely

5. **Update `CLAUDE.md`**
   - Change registration command:
     - Old: `/plugin marketplace add ~/devbox/agentics/marketplace-data`
     - New: `/plugin marketplace add ~/devbox/agentics`
   - Update the Three-Layer Structure diagram and any other references to `marketplace-data/.claude-plugin/`

6. **Update root `README.md`**
   - Update any references to `marketplace-data/` path for marketplace registration

---

## Files to Modify

| File | Change |
|------|--------|
| `marketplace-data/.claude-plugin/marketplace.json` | Move to `.claude-plugin/marketplace.json`, update source paths |
| `CLAUDE.md` | Update registration commands and directory references |
| `README.md` | Update marketplace registration path references |
| `marketplace-data/README.md` | Merge relevant content into root README, then delete |

---

## Verification

```bash
# 0. Remove the old marketplace registration first
/plugin marketplace remove agentics-test

# 1. Validate the marketplace from the new location
claude plugin validate .

# 2. Register the marketplace from the new root
/plugin marketplace add ~/devbox/agentics

# 3. Install a plugin to confirm source resolution works
/plugin install hello-world@agentics-test
/plugin install dev-tools@agentics-test
```

---

## Interview Summary

### Key Decisions Confirmed

- **Re-registration** — Add `/plugin marketplace remove agentics-test` + re-add to the Verification section
- **File move strategy** — Use `git mv` to preserve `marketplace.json` blame/log history
- **Three-Layer Structure** — Redefine layers in `CLAUDE.md` as: `plugins/` (source code) · `.claude-plugin/` (marketplace manifest) · `tests/` (fixtures)
- **Version bump** — Bump `marketplace.json` from `1.0.0` → `1.1.0` to signal the structural change

### Open Risks & Concerns

- **Latent validation error** — `../plugins/...` source paths currently violate the `Path traversal not allowed` rule. The refactor fixes this, but it should be called out in the plan as a correctness fix, not just a housekeeping path update.
- **README merge ambiguity** — `marketplace-data/README.md` is ~457 lines covering API integration, curl examples, and troubleshooting. "Merge unique content" needs a clearer instruction: merge only usage/registration sections, and discard API-futures content.

### Recommended Next Steps

1. Add to Step 3: note that `./plugins/...` also resolves the existing `Path traversal not allowed` validator error
2. Add to Step 4: specify what to merge from `marketplace-data/README.md` — usage and registration sections only; discard API speculation and troubleshooting boilerplate
3. Add to Step 5 (file move): use `git mv` for the manifest move
4. Add to Step 6: bump `marketplace.json` version to `1.1.0`
5. Verification already updated with `/plugin marketplace remove agentics-test` before re-adding

