# Target Resolution Reference

Argument parsing plus the five-tier lookup that turns `TARGET_RAW` into a `TARGET_TYPE`, a
`TARGET_NAME`, and either a single `PRIMARY_FILE` or a `SOURCE_FILES` list.
Phases 1 and 2 of `share-explanation`.

## Phase 1 — Parse `$ARGUMENTS`

Extract:
- `TARGET_RAW` — all text that is not a `--flag`; the question or component name
  (e.g. `"how does the share-session skill work"`, `"security scrub pattern"`, `"share-scan"`)
- `PLATFORM` — from `--platform=<v>`; keep empty if absent
- `TONE` — from `--tone=<v>`; keep empty if absent

If `TARGET_RAW` is empty after parsing, ask once via `AskUserQuestion`:
"What component or concept would you like me to explain?" — stop if still empty.

## Phase 2 — Establish project root

Run silently:

```bash
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$GIT_ROOT" ] && GIT_ROOT="$PWD"
```

`GIT_ROOT` is the search boundary for all lookups below. Never search outside it.

---

**Match priority — try each tier in order; stop at the first hit:**

## Tier 1 — Skill (SKILL.md)

For each token in `TARGET_RAW`, check if it matches a skill directory name anywhere in
`$GIT_ROOT` (case-insensitive):

```bash
find "$GIT_ROOT" -path "*/skills/*/SKILL.md" -not -path "*/archive/*" \
  -not -path "*/.git/*" -type f 2>/dev/null | \
  awk -F/ '{print $(NF-1)"|"$0}' | grep -i "^<token>|" | head -1
```

If matched:
- `TARGET_TYPE=skill`
- `TARGET_NAME=<skill-dir-name>`
- `PRIMARY_FILE=<full-path>`

## Tier 2 — Command file

If no skill matched, check each token against command filenames in `$GIT_ROOT`:

```bash
find "$GIT_ROOT" -path "*/commands/*.md" -not -path "*/archive/*" \
  -not -path "*/.git/*" -type f 2>/dev/null | \
  awk -F/ '{name=$(NF); sub(/\.md$/,"",name); print name"|"$0}' | \
  grep -i "^<token>|" | head -1
```

If matched:
- `TARGET_TYPE=command`
- `TARGET_NAME=<basename-without-.md>`
- `PRIMARY_FILE=<full-path>`

## Tier 3 — Any source file by name

If still no match, search for any file whose base name (without extension) matches a token
in `TARGET_RAW` across all tracked files in `$GIT_ROOT`:

```bash
find "$GIT_ROOT" \
  -not -path "*/.git/*" -not -path "*/archive/*" -not -path "*/node_modules/*" \
  -not -path "*/__pycache__/*" -not -path "*/dist/*" -not -path "*/build/*" \
  -type f \( -name "*.md" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \
             -o -name "*.mjs" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | \
  awk -F/ '{name=$(NF); sub(/\.[^.]+$/,"",name); print name"|"$0}' | \
  grep -i "^<token>|" | head -3
```

Set `TARGET_TYPE=file`. Collect all matches as `SOURCE_FILES` (up to 3).

## Tier 4 — Function or symbol search

If still no match, grep the project for a function definition, class, or exported symbol
whose name contains any token from `TARGET_RAW`:

```bash
grep -rn --include="*.py" --include="*.js" --include="*.ts" --include="*.mjs" \
  -E "(def |function |class |export (function|const|class) )<token>" \
  "$GIT_ROOT" 2>/dev/null | \
  grep -v "archive\|node_modules\|\.git\|dist\|build" | head -10
```

Set `TARGET_TYPE=function`. Collect unique file paths from results as `SOURCE_FILES`.

## Tier 5 — Keyword/concept grep (last resort)

If nothing matched above, grep all text files in `$GIT_ROOT` for the key terms in
`TARGET_RAW`:

```bash
grep -ril "<key-terms>" "$GIT_ROOT" \
  --include="*.md" --include="*.py" --include="*.js" --include="*.ts" \
  --include="*.mjs" --include="*.sh" 2>/dev/null | \
  grep -v "archive\|node_modules\|\.git\|dist\|build" | head -5
```

Set `TARGET_TYPE=concept`. Collect up to 5 paths as `SOURCE_FILES`.

---

## Slug and no-match stop

Derive a `TARGET_NAME` slug from `TARGET_RAW` for use in filenames:

```bash
TARGET_NAME=$(echo "$TARGET_RAW" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-\|-$//g' | cut -c1-30)
```

If nothing matched across all five tiers: output "Could not locate `<TARGET_RAW>` in the
project. Try the exact file name, function name, or a key term from the code." and **STOP**.
