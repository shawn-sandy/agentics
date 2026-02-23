# Plan: Move .claude-plugin to Project Root (Marketplace Refactor)

## Context

Current structure nests the marketplace manifest inside a `marketplace-data/` subdirectory — inconsistent with Claude Code docs which show `.claude-plugin/` at the **root** of the registered marketplace directory. Moving it makes `agentics/` itself the marketplace, fixes a latent `Path traversal not allowed` validator error (`../plugins/...` paths), and eliminates an unnecessary subdirectory.

**Before:**
```
agentics/
├── marketplace-data/
│   ├── .claude-plugin/
│   │   └── marketplace.json     ← source paths use ../plugins/...
│   └── README.md
└── plugins/
```

**After:**
```
agentics/
├── .claude-plugin/
│   └── marketplace.json         ← source paths use ./plugins/...
├── plugins/
└── tests/
```

---

## Steps

1. **Move `marketplace.json` to project root** (use `git mv` to preserve history)
   - `git mv marketplace-data/.claude-plugin/marketplace.json .claude-plugin/marketplace.json`

2. **Update source paths in `marketplace.json`** (also fixes path traversal validator error)
   - `"source": "../plugins/hello-world"` → `"source": "./plugins/hello-world"`
   - `"source": "../plugins/dev-tools"` → `"source": "./plugins/dev-tools"`
   - Also bump version: `"1.0.0"` → `"1.1.0"`

3. **Merge `marketplace-data/README.md` into root `README.md`** — usage/registration sections only; discard API speculation and troubleshooting boilerplate. Then delete `marketplace-data/` entirely.

4. **Update `CLAUDE.md`**
   - Registration command: `/plugin marketplace add ~/devbox/agentics/marketplace-data` → `/plugin marketplace add ~/devbox/agentics`
   - Three-Layer Structure: redefine layers as `plugins/` · `.claude-plugin/` · `tests/`
   - Remove all other `marketplace-data/.claude-plugin/` references

5. **Update root `README.md`** — fix any `marketplace-data/` path references for marketplace registration

---

## Files to Modify

| File | Change |
|------|--------|
| `marketplace-data/.claude-plugin/marketplace.json` | `git mv` → `.claude-plugin/marketplace.json`, update paths + bump version |
| `CLAUDE.md` | Update registration commands and directory structure |
| `README.md` | Update marketplace registration path references |
| `marketplace-data/README.md` | Merge usage sections into root README, then delete |

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
