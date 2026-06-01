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

`ExitPlanMode` is a deferred tool whose schema must be loaded before it can be
called. Use `ToolSearch` with `select:ExitPlanMode` first, then call
`ExitPlanMode`. Both steps happen silently with no user-visible output. Only
call `ExitPlanMode` if currently in plan mode — skip this step entirely if plan
mode is already off.

**Error handling:** If `ExitPlanMode` returns the exact error `"You are not in plan mode"`,
treat that as **success** — plan mode was already off. Do not abort or surface the error
to the user; continue to the next step.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
ls ~/devbox/agentics/kit/plugins/social-media-tools/references 2>/dev/null && \
  echo "$HOME/devbox/agentics/kit/plugins/social-media-tools/references"
find ~/.claude/plugins -path "*/social-media-tools/references" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/references" -type d 2>/dev/null | head -1
```

Use the first non-empty result to derive `PLUGIN_DIR`. Read
`$PLUGIN_DIR/references/social-config.md` to understand the target format.

If not found: output "Plugin assets not found. Install the plugin or load it
with `--plugin-dir`." and **STOP**.

---

## Phase 1 — Check for Existing Config

```bash
ls "$PWD/SOCIAL.md" 2>/dev/null
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
cat package.json 2>/dev/null | grep -E '"name"|"description"' | head -2
cat pyproject.toml 2>/dev/null | grep -E '^name |^description ' | head -2
cat Cargo.toml 2>/dev/null | grep -E '^name|^description' | head -2
head -5 go.mod 2>/dev/null
```

Fallback: last segment of `$PWD`.

### Tech stack

```bash
# Detect languages and frameworks
ls package.json tsconfig.json 2>/dev/null
ls requirements.txt pyproject.toml setup.py 2>/dev/null
ls Cargo.toml go.mod Gemfile 2>/dev/null
ls *.sln *.csproj 2>/dev/null
```

### Content signals

```bash
# Recent activity patterns
git log --oneline -20 --format="%s" 2>/dev/null
head -40 CHANGELOG.md 2>/dev/null
head -20 README.md 2>/dev/null
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
ls .env .env.* 2>/dev/null
ls **/credentials* **/secrets* **/*.pem **/*.key 2>/dev/null
cat .gitignore 2>/dev/null | head -30
```

Derive `DETECTED_AVOID` — list of paths/patterns to exclude.

---

## Phase 3 — Interview

Present analysis results and ask the user to confirm or adjust. Use a **single**
`AskUserQuestion` call with up to 4 questions:

1. **Platform**: "Which platform(s) do you primarily share on?"
   Options: `All sites (Recommended)`, `LinkedIn`, `Twitter/X`, `Bluesky`
   (multiSelect: false)

2. **Tone**: "What tone fits your audience?"
   Options: `Professional (Recommended)`, `Technical`, `Conversational`, `Punchy`
   (multiSelect: false)

3. **Audience**: "Who is your target audience?"
   Options: `Developers`, `Dev leads / architects`, `Product / design`, `General tech`
   (multiSelect: false)

Use the user's answers alongside detected values for the final config.

---

## Phase 4 — Generate SOCIAL.md

Write `$PWD/SOCIAL.md` using the template below. Populate with detected values
and user answers. If updating an existing file, merge sections intelligently —
preserve user-written content, update detected values.

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
