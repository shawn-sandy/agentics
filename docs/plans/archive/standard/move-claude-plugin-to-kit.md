# Plan: Move `.claude-plugin/` Back to `kit/`

## Context

Commit `fe3b4e5` moved `kit/.claude-plugin/marketplace.json` to the repo root for marketplace discovery. This plan reverses that move to keep `kit/` self-contained as a distributable marketplace subtree. Registration commands will change to point at `kit/` so Claude Code finds `.claude-plugin/` at the root of the registered path.

## Steps

### 1. Move the file

```bash
mkdir -p kit/.claude-plugin
git mv .claude-plugin/marketplace.json kit/.claude-plugin/marketplace.json
```

No changes to `marketplace.json` contents — `source.path` values are relative to git repo root.

### 2. Update `.claude/settings.json` (line 17)

- `jq empty .claude-plugin/marketplace.json` → `jq empty kit/.claude-plugin/marketplace.json`

### 3. Update `CLAUDE.md`

- **Line 18:** `.claude-plugin/marketplace.json` → `kit/.claude-plugin/marketplace.json`
- **Lines 23-28:** Restructure the directory tree:
  ```
  kit/                  → Self-contained marketplace subtree
  kit/.claude-plugin/   → Marketplace metadata (marketplace.json)
  kit/plugins/          → Plugin source code (what users install)
  ```
- **Line 40:** `/plugin marketplace add shawn-sandy/agentics` → `/plugin marketplace add shawn-sandy/agentics/kit`
- **Line 51:** `.claude-plugin/marketplace.json` → `kit/.claude-plugin/marketplace.json`
- **Line 67:** Update settings.json description to reference new path

### 4. Update `.claude/rules/marketplace.md`

- **Line 5:** `.claude-plugin/marketplace.json` → `kit/.claude-plugin/marketplace.json`
- **Line 51:** `.claude-plugin/marketplace.json` → `kit/.claude-plugin/marketplace.json`
- **Line 62:** Already says `kit/.claude-plugin/` — no change needed

### 5. Update `CONTRIBUTING.md` (line 25)

- `.claude-plugin/marketplace.json` → `kit/.claude-plugin/marketplace.json`

### 6. Update `README.md`

- **Line 11:** `/plugin marketplace add shawn-sandy/agentics` → `/plugin marketplace add shawn-sandy/agentics/kit`
- **Lines 61-62:** Already show `kit/.claude-plugin/` — no change needed (stale refs now correct)
- **Line 443:** Already says `kit/.claude-plugin/marketplace.json` — no change needed
- **Line 448:** `/plugin marketplace add shawn-sandy/agentics` → `/plugin marketplace add shawn-sandy/agentics/kit`
- **Line 499:** Already says `kit/.claude-plugin/marketplace.json` — no change needed

### 7. Update `CLAUDE.local.md`

- `/plugin marketplace add ~/devbox/agentics` → `/plugin marketplace add ~/devbox/agentics/kit`

### 8. Update memory

- Update `MEMORY.md` architecture section: `.claude-plugin/` → `kit/.claude-plugin/`

## Files Modified

| File | Change |
|------|--------|
| `.claude-plugin/marketplace.json` | `git mv` to `kit/.claude-plugin/marketplace.json` |
| `.claude/settings.json` | Hook path update |
| `CLAUDE.md` | 5 path references + structure diagram + registration command |
| `.claude/rules/marketplace.md` | 2 path references |
| `CONTRIBUTING.md` | 1 path reference |
| `README.md` | 2 registration commands |
| `CLAUDE.local.md` | 1 registration command |
| `MEMORY.md` | Architecture note |

## Files NOT Changed

- `marketplace.json` contents (source paths are repo-relative)
- Individual plugin `plugin.json` files
- Plugin skill/reference files (generic `.claude-plugin/` guidance for any project)
- `docs/plans/` historical files
- `tests/fixtures/` READMEs (generic references)

## Verification

```bash
# 1. Validate JSON at new location
jq empty kit/.claude-plugin/marketplace.json

# 2. Confirm old location removed
test ! -d .claude-plugin && echo "Old directory removed"

# 3. Test marketplace registration
/plugin marketplace add ~/devbox/agentics/kit

# 4. Test plugin install
/plugin install code-review@agentics-kit
```

## Commit Message

```
refactor: move .claude-plugin back to kit/ subtree

Reverses fe3b4e5 to keep kit/ self-contained as a distributable
marketplace subtree. Registration commands now point to kit/ subdir.
```

## Next Steps

- Verify `--sparse` flag support in Claude Code for remote registration via `shawn-sandy/agentics/kit`
- Consider whether remote GitHub marketplace registration supports subdirectory paths
