---
name: share-init
description: "Generates a SOCIAL.md project sharing config by analyzing the codebase. Use when asked to set up social sharing preferences or create a SOCIAL.md file."
allowed-tools: Bash, Read, Write, Glob, Grep, AskUserQuestion, ToolSearch, ExitPlanMode
---

# share-init

Analyze the current project and generate a `SOCIAL.md` file that configures
default sharing preferences for all social-media-tools skills.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `references/social-config.md` and derive `PLUGIN_DIR` |
| 1 — Check | Verify no existing `SOCIAL.md`; offer to update if found |
| 2 — Analyze | Extract project identity, tech stack, and content signals |
| 3 — Interview | Ask user for preferences not derivable from code |
| 4 — Generate | Write `SOCIAL.md` to project root |

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/references" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/references"
find ~/.claude/plugins -path "*/social-media-tools/references" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/references" -type d 2>/dev/null | head -1
```

Use the first non-empty result to derive `PLUGIN_DIR`. Read
`$PLUGIN_DIR/references/social-config.md` to understand the target format.

If not found: output "Plugin assets not found. Install the plugin or load it
with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Check for Existing Config

Resolve the project root — always write to the git toplevel so there is one
canonical config (matches the lookup in consuming skills):

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || PROJECT_ROOT="$PWD"
ls "$PROJECT_ROOT/SOCIAL.md" 2>/dev/null
```

If found:
- `Read` the existing file
- Use `AskUserQuestion`: "A SOCIAL.md already exists. What would you like to do?"
  Options: `Update it` (merge new analysis with existing), `Replace it` (start fresh),
  `Cancel`
- If `Cancel`: output "Keeping existing SOCIAL.md." and **STOP**.

---

## Phase 2 — Analyze Project

Extract signals from the codebase to pre-populate the config. Run silently:

### Identity

```bash
# Project name and description from manifest
cat "$PROJECT_ROOT/package.json" 2>/dev/null | grep -E '"name"|"description"' | head -2
cat "$PROJECT_ROOT/pyproject.toml" 2>/dev/null | grep -E '^name |^description ' | head -2
cat "$PROJECT_ROOT/Cargo.toml" 2>/dev/null | grep -E '^name|^description' | head -2
head -5 "$PROJECT_ROOT/go.mod" 2>/dev/null
```

Fallback: last segment of `$PROJECT_ROOT`.

### Tech stack

```bash
# Detect languages and frameworks
ls "$PROJECT_ROOT/package.json" "$PROJECT_ROOT/tsconfig.json" 2>/dev/null
ls "$PROJECT_ROOT/requirements.txt" "$PROJECT_ROOT/pyproject.toml" "$PROJECT_ROOT/setup.py" 2>/dev/null
ls "$PROJECT_ROOT/Cargo.toml" "$PROJECT_ROOT/go.mod" "$PROJECT_ROOT/Gemfile" 2>/dev/null
```

### Content signals

```bash
# Recent activity patterns
git -C "$PROJECT_ROOT" log --oneline -20 --format="%s" 2>/dev/null
head -40 "$PROJECT_ROOT/CHANGELOG.md" 2>/dev/null
head -20 "$PROJECT_ROOT/README.md" 2>/dev/null
```

Derive:
- `DETECTED_NAME` — project name
- `DETECTED_DESCRIPTION` — one-sentence description
- `DETECTED_STACK` — primary language/framework
- `DETECTED_TOPICS` — recurring themes from commit messages (features, fixes, docs, etc.)
- `DETECTED_HASHTAGS` — 3-5 relevant hashtags based on stack and domain

### Sensitive paths

```bash
# Paths that should never be shared
ls "$PROJECT_ROOT/.env" "$PROJECT_ROOT/.env."* 2>/dev/null
find "$PROJECT_ROOT" -type f \( -name 'credentials*' -o -name 'secrets*' -o -name '*.pem' -o -name '*.key' \) 2>/dev/null | head -20
cat "$PROJECT_ROOT/.gitignore" 2>/dev/null | head -30
```

Derive `DETECTED_AVOID` — list of paths/patterns to exclude.

---

## Phase 3 — Interview

Present analysis results and ask the user to confirm or adjust. Use a **single**
`AskUserQuestion` call with up to 4 questions:

1. **Platform**: "Which platform(s) do you primarily share on?"
   Options: `All sites (Recommended)`, `LinkedIn`, `Twitter/X`, `Bluesky`, `Substack`
   (multiSelect: false)
   Map selected label to canonical token before writing: `All sites` → `all`,
   `LinkedIn` → `LinkedIn`, `Twitter/X` → `twitter`, `Bluesky` → `bluesky`,
   `Substack` → `substack`

2. **Tone**: "What tone fits your audience?"
   Options: `Instructional / Educational (Recommended)`, `Professional`, `Technical`, `Conversational`
   (multiSelect: false)

3. **Audience**: "Who is your target audience?"
   Options: `Developers`, `Dev leads / architects`, `Product / design`, `General tech`
   (multiSelect: false)

Use the user's answers alongside detected values for the final config.

---

## Phase 4 — Generate SOCIAL.md

Write `$PROJECT_ROOT/SOCIAL.md` using the template below. Populate with detected
values and user answers. If updating an existing file, merge sections
intelligently — preserve user-written content, update detected values.

```markdown
# Social Sharing Config

Project-level defaults for the social-media-tools plugin.
Skills read this file to pre-populate platform, tone, and content preferences.

## Identity

- Project: <DETECTED_NAME>
- Tagline: <DETECTED_DESCRIPTION or user-provided>

## Defaults

- Platform: <user-selected platform>
- Tone: <user-selected tone>
- Hashtags: <DETECTED_HASHTAGS, comma-separated>

> **Note:** The teaching-first voice (Instructional Voice doctrine) applies
> regardless of the tone setting above. The tone only adjusts the *register* —
> how formally or casually the lesson is delivered. Every post leads with a
> concrete, applicable takeaway.

## Focus

<Bullet list of topics/areas derived from DETECTED_TOPICS and user input.
Example:>
- New features and releases
- Developer experience improvements
- Performance optimizations

## Avoid

<Bullet list from DETECTED_AVOID. Example:>
- .env files and environment configs
- Internal credentials or API keys
- Draft/WIP branches

## Audience

<Free-text from user's audience selection, expanded into a sentence.
Example:>
Developers and technical leads building with <stack>. Posts should
demonstrate practical value and include enough context for someone
unfamiliar with the project.

## Examples

<!-- Add example posts you like here. Skills use these as style references. -->
```

After writing, output:

```
Created SOCIAL.md — your sharing preferences are now configured.

The share skills (share-code, share-project, share-scan, etc.) will
automatically read this file for defaults. You can edit it anytime.
```

**STOP.** Do not invoke any share skills automatically.
