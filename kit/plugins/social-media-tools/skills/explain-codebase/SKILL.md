---
name: explain-codebase
description: "Explains how plugin components work. Reads source files and synthesizes developer-friendly principles, social copy, and a dark-mode card. Use when asked 'how does X work' or 'explain X'."
allowed-tools: Bash, Read, Glob, Grep, Write, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, SendUserFile
---

# explain-codebase

Answer **"how does X work"** questions about any social-media-tools component — skills, commands,
or reference patterns — by reading the actual source files and synthesizing a structured
developer-friendly explanation. Then deliver the result the same way all other share-* skills do:
security scrub → platform-aware copy → dark-mode card → persistent save.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 0b — Config | Load `SOCIAL.md` for platform/tone defaults |
| 1 — Parse | Extract target name/concept and flags from `$ARGUMENTS` |
| 1c — Reuse | Check `docs/media/social/` for an existing post on this target |
| 2 — Locate files | Map target to SKILL.md, reference docs, and scripts |
| 3 — Synthesize | Read files and build structured explanation |
| 4 — Scrub | `security-scrub` the full explanation (BLOCKED = hard stop) |
| 5 — Draft | Write content-first, platform-aware social copy |
| 6 — Populate | Select template, substitute `{{VARIABLES}}` |
| 6b — Save | Persistent save to `docs/media/social/` |
| 7 — Screenshot | Serve HTML locally, Playwright screenshot |
| 8 — Deliver | Present explanation + copy + attach PNG + show saved path |

## Exit plan mode

`ExitPlanMode` is a deferred tool whose schema must be loaded before it can be called.
Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps
happen silently with no user-visible output. Only call this if currently in plan mode — skip
entirely if plan mode is already off.

**Error handling:** If `ExitPlanMode` returns `"You are not in plan mode"`, treat that as
**success** — continue immediately.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -d "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates" ] && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/templates"
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

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=explain
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Identify Target and Locate Files

**Skill name detection:** Check if any token in `TARGET_RAW` matches a directory name under
`$PLUGIN_DIR/skills/` (case-insensitive):

```bash
ls "$PLUGIN_DIR/skills/"
```

If matched, set:
- `TARGET_TYPE=skill`
- `TARGET_NAME=<matched-dir-name>` (e.g. `share-session`)
- `PRIMARY_FILE=$PLUGIN_DIR/skills/$TARGET_NAME/SKILL.md`

**Command name detection:** If a token matches a filename under `$PLUGIN_DIR/commands/`
(strip `.md` for comparison):
- `TARGET_TYPE=command`
- `TARGET_NAME=<matched-filename-without-.md>`
- `PRIMARY_FILE=$PLUGIN_DIR/commands/$TARGET_NAME.md`

**Reference/concept detection (fallback):** If no skill or command name matched, grep
`$PLUGIN_DIR/references/` and all SKILL.md bodies for the key terms in `TARGET_RAW`:

```bash
grep -ril "<key-terms>" "$PLUGIN_DIR/references/" "$PLUGIN_DIR/skills/"
```

Set `TARGET_TYPE=concept`. Collect the 3 most relevant result paths as `SOURCE_FILES`.

If nothing is found: output "Could not find a component matching `<TARGET_RAW>`. Available
skills: `$(ls $PLUGIN_DIR/skills/)`." and **STOP**.

---

## Phase 3 — Read Files and Synthesize

Read `PRIMARY_FILE` (or each file in `SOURCE_FILES` for concept targets). For skill targets,
also read any `$PLUGIN_DIR/references/` files that are explicitly named in the SKILL.md body —
do not read the entire `references/` directory.

Synthesize a structured explanation. Build `EXPLANATION_RAW` as plain text with six sections:

1. **Core Purpose** — 1–2 sentences: what this component does and why it exists
2. **Activation Conditions** *(skills only)* — what user intent or trigger fires it; the
   frontmatter `description` field is the source of truth
3. **Workflow Phases** — numbered list, one line per phase: phase name + what it does
4. **Key Patterns** — bullet list of non-obvious conventions used (e.g. security scrub gate,
   ExitPlanMode deferred-tool bootstrap, HTML-escape order, reuse-check, SOCIAL.md loading)
5. **Important Files** — `path/to/file — purpose` for each file the component reads or writes
6. **Invocation** — exact syntax with a brief usage example

Write concretely — real file names, real phase labels, real flag names. No filler.

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

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, Follow CTA
rule, and Default Per-Platform Copy Formats.

Ask for `PLATFORM` and `TONE` in a single `AskUserQuestion` if not already in `$ARGUMENTS`.

**Lead with insight, not process.** The hook should surface the most interesting or surprising
aspect of how the component works — not just "here's how X works."

Content guidance per platform:
- **LinkedIn**: hook on the key insight → 2–3 most important patterns → one-line invocation
  example → follow CTA
- **Twitter/X**: one sharp principle in ≤280 chars; invocation if space allows
- **Bluesky**: conversational, principle-first, same brevity as Twitter/X
- **Substack**: reflect on what the design reveals about the plugin's philosophy; patterns
  as supporting detail

---

## Phase 6 — Populate Template

**Select template based on target type:**
- `TARGET_TYPE=skill` or `TARGET_TYPE=command` → use `feature-card.html`
- `TARGET_TYPE=concept` → use `quote-card.html`

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/<selected-template>
TEMP_HTML=explain-share-card.html
SLUG_INPUT="explain-${TARGET_NAME}-${TODAY}"
TODAY=$(date '+%Y-%m-%d')
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
| `{{ATTRIBUTION}}` | Source file or pattern name (HTML-escaped) |
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
