---
name: share-explanation
description: "Explains how any project file, component, or concept works. Reads source files and synthesizes developer-friendly principles, social copy, and a dark-mode card. Use when asked 'how does X work' or 'explain X'."
allowed-tools: Bash, Read, Glob, Grep, Write, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, SendUserFile
model: opus
---

# share-explanation

Answer **"how does X work"** questions about any file, component, function, or concept in the
current project — by reading the actual source files and synthesizing a structured
developer-friendly explanation. Then deliver the result the same way all other share-* skills do:
security scrub → platform-aware copy → dark-mode card → persistent save.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 0b — Config | Load `SOCIAL.md` for platform/tone defaults |
| 1 — Parse | Extract target name/concept and flags from `$ARGUMENTS` |
| 2 — Locate files | Map target to SKILL.md, reference docs, and scripts |
| 3 — Synthesize | Read files and build structured explanation |
| 4 — Scrub | `security-scrub` the full explanation (BLOCKED = hard stop) |
| 5 — Draft | Write content-first, platform-aware social copy |
| 5b — Reuse | Check `docs/media/social/` for an existing post on this target |
| 6 — Populate | Select template, substitute `{{VARIABLES}}` |
| 6b — Save | Persistent save to `docs/media/social/` |
| 7 — Screenshot | Serve HTML locally, Playwright screenshot |
| 8 — Deliver | Present explanation + copy + attach PNG + show saved path |

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/templates" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If no directory is found: output "Templates not found. Install the plugin or load it with
`--plugin-dir`." and **STOP**.

---

## Phase 0b — Load Project Sharing Config

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If `SOCIAL_CONFIG` is non-empty, `Read` it silently. Extract:
- `DEFAULT_PLATFORM` from `## Defaults` → `Platform:` line
- `DEFAULT_TONE` from `## Defaults` → `Tone:` line

---

## Phase 1 — Parse `$ARGUMENTS`

Extract:
- `TARGET_RAW` — all text that is not a `--flag`; the question or component name
  (e.g. `"how does the share-session skill work"`, `"security scrub pattern"`, `"share-scan"`)
- `PLATFORM` — from `--platform=<v>`; keep empty if absent
- `TONE` — from `--tone=<v>`; keep empty if absent

If `TARGET_RAW` is empty after parsing, ask once via `AskUserQuestion`:
"What component or concept would you like me to explain?" — stop if still empty.

---

## Phase 2 — Identify Target and Locate Files

**Establish project root** — run silently:

```bash
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$GIT_ROOT" ] && GIT_ROOT="$PWD"
```

`GIT_ROOT` is the search boundary for all lookups below. Never search outside it.

---

**Match priority — try each tier in order; stop at the first hit:**

### Tier 1 — Skill (SKILL.md)

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

### Tier 2 — Command file

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

### Tier 3 — Any source file by name

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

### Tier 4 — Function or symbol search

If still no match, grep the project for a function definition, class, or exported symbol
whose name contains any token from `TARGET_RAW`:

```bash
grep -rn --include="*.py" --include="*.js" --include="*.ts" --include="*.mjs" \
  -E "(def |function |class |export (function|const|class) )<token>" \
  "$GIT_ROOT" 2>/dev/null | \
  grep -v "archive\|node_modules\|\.git\|dist\|build" | head -10
```

Set `TARGET_TYPE=function`. Collect unique file paths from results as `SOURCE_FILES`.

### Tier 5 — Keyword/concept grep (last resort)

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

Derive a `TARGET_NAME` slug from `TARGET_RAW` for use in filenames:

```bash
TARGET_NAME=$(echo "$TARGET_RAW" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-\|-$//g' | cut -c1-30)
```

If nothing matched across all five tiers: output "Could not locate `<TARGET_RAW>` in the
project. Try the exact file name, function name, or a key term from the code." and **STOP**.

---

## Phase 3 — Read Files and Synthesize

Read `PRIMARY_FILE` (or each file in `SOURCE_FILES` for multi-file targets). For skill targets,
also read any reference files explicitly named in the SKILL.md body — do not bulk-read any
directory. For code targets (file, function, concept), read only the matched files; do not
speculatively read adjacent files.

Adapt the synthesis structure to `TARGET_TYPE`:

**For `skill` or `command` targets** — six sections:

1. **Core Purpose** — 1–2 sentences: what this component does and why it exists
2. **Activation Conditions** *(skills only)* — what user intent or trigger fires it; the
   frontmatter `description` field is the source of truth
3. **Workflow Phases** — numbered list, one line per phase: phase name + what it does
4. **Key Patterns** — bullet list of non-obvious conventions used
5. **Important Files** — `path/to/file — purpose` for each file the component reads or writes
6. **Invocation** — exact syntax with a brief usage example

**For `file`, `function`, or `concept` targets** — five sections:

1. **Core Purpose** — what this code does and the problem it solves
2. **How It Works** — numbered steps describing the logic flow or algorithm
3. **Key Patterns** — non-obvious conventions, assumptions, or design choices
4. **Dependencies / Callers** — what calls this and what it depends on (from the source)
5. **Usage Example** — minimal concrete call or invocation

Write concretely — real file names, real function signatures, real variable names. No filler.

`SUMMARY_RAW` = full `EXPLANATION_RAW` text (passed to security scrub in Phase 4).

---

## Phase 4 — Security Scrub

Write `EXPLANATION_RAW` to a temp file:

```bash
mkdir -p ~/.claude/tmp
```

Write content to `~/.claude/tmp/scrub-input.txt`.

Invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line:
- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 5.
- `GATE RESULT: APPROVED` → proceed to Phase 5.
- Missing or unrecognized result → **STOP** and report error (treat as gate failure).

---

## Phase 5 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, and **Default Per-Platform
Copy Formats**.

Resolve `PLATFORM` and `TONE` concretely before prompting:

```bash
# PLATFORM and TONE were parsed from $ARGUMENTS in Phase 1
[ -z "$PLATFORM" ] && [ -n "$DEFAULT_PLATFORM" ] && PLATFORM="$DEFAULT_PLATFORM"
[ -z "$TONE" ]     && [ -n "$DEFAULT_TONE" ]     && TONE="$DEFAULT_TONE"
```

Only if either variable is still empty after applying the above, ask for both in a single `AskUserQuestion`.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from how this component works (a pattern, technique, or design
principle). The explanation is evidence for the lesson, not the headline.

Content guidance per platform:
- **LinkedIn**: hook on the key takeaway → 2–3 teachable patterns the reader can apply →
  one-line invocation example → learn-more CTA
- **Twitter/X**: one sharp teachable principle in ≤280 chars; invocation if space allows
- **Bluesky**: conversational, takeaway-first, same brevity as Twitter/X
- **Substack**: reflect on the teachable design principle and what the reader can apply;
  patterns as supporting detail

---

## Phase 5b — Reuse Check

Now that `TARGET_NAME` and `PLATFORM` are both resolved, check for an existing post:

```bash
FILE_PREFIX=explain
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 6 — Populate Template

**Select template based on target type:**
- `TARGET_TYPE=skill` or `TARGET_TYPE=command` → use `feature-card.html`
- `TARGET_TYPE=file` or `TARGET_TYPE=function` → use `feature-card.html`
- `TARGET_TYPE=concept` → use `quote-card.html`

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/<selected-template>
TEMP_HTML=explain-share-card.html
TODAY=$(date '+%Y-%m-%d')
# Normalize TARGET_NAME (or TARGET_RAW for concept targets) through the same slug pipeline
TARGET_SLUG="$(printf '%s' "${TARGET_NAME:-$TARGET_RAW}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//' | cut -c1-30)"
SLUG_INPUT="explain-${TARGET_SLUG}-${TODAY}"
```

Read `$PLUGIN_DIR/references/variables.md` for the variable reference.
Read `$PLUGIN_DIR/references/copy-panels.md` for `{{COPY_PANELS}}` markup and escaping.

### HTML-escape all values — MANDATORY

Apply in this exact order:
1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

### feature-card.html substitutions

| Template variable | Value |
|-------------------|-------|
| `{{TITLE}}` | `TARGET_NAME` (HTML-escaped; e.g. `share-session`) |
| `{{SUBTITLE}}` | Core Purpose sentence, ≤100 chars (HTML-escaped) |
| `{{BULLETS}}` | One `<li>…</li>` per Workflow Phase — HTML-escape each phase's **text**, wrap in `<li>`. No wrapping `<ul>`. |
| `{{BADGE}}` | `TARGET_TYPE` (HTML-escaped; `skill` or `command`) |
| `{{FOOTER_NOTE}}` | Invocation syntax (HTML-escaped; e.g. `/social-media-tools:share-session [--platform=]`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

### quote-card.html substitutions

| Template variable | Value |
|-------------------|-------|
| `{{QUOTE}}` | Most important Key Pattern principle, ≤200 chars (HTML-escaped) |
| `{{ATTRIBUTION}}` | Plugin or project name (HTML-escaped; e.g. `social-media-tools`) |
| `{{CONTEXT}}` | Pattern category (HTML-escaped; e.g. `Security pattern`, `Bootstrap pattern`) |
| `{{COPY_PANELS}}` | Copy panel HTML — see `references/copy-panels.md` |

Write the populated HTML to `~/.claude/tmp/explain-share-card.html`.

---

## Phase 6b — Persistent Save

Variables: `FILE_PREFIX=explain`, `SLUG_INPUT`, `TEMP_HTML=explain-share-card.html`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 7 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 8 — Deliver

Present the structured explanation in a fenced markdown block labeled `## Explanation`.

Present the social copy in a separate fenced block labeled `## Copy`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section for attaching
the PNG and reporting the saved path.
