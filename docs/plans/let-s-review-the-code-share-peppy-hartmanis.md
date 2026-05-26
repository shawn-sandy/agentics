# Plan: code-share skill review and optimization

## Context

The `code-share` plugin (`kit/plugins/social-media-tools`) was released at v0.1.0. The user wants to review the skill and find opportunities to improve and optimize it for sharing project code/changes on social media. Reviewing against the authoring checklist in `.claude/rules/skill-authoring.md` and reference patterns in `.claude/rules/plugin-patterns.md` surfaced several concrete gaps.

---

## Issues Found

| # | Issue | Impact |
|---|-------|--------|
| 1 | No `README.md` in plugin root | Required by `plugin-patterns.md`; plugin can't be documented |
| 2 | Skill description is 281 chars — exceeds ≤160 char budget | Activation matching is less precise; verbose descriptions dilute signal |
| 3 | Phase 1 asks the user for content before reading the project | User must manually describe what they want to share; wastes a round-trip |
| 4 | `$PLUGIN_DIR` used in Phase 5a but never assigned — it's derived from `TEMPLATES_DIR` | Could cause a confusing runtime error ("variable not set") |
| 5 | `version: 0.1.0` in SKILL.md frontmatter | Non-standard field; version belongs only in `marketplace.json` |
| 6 | No explicit STOP boundary after Phase 6 | Reference implementations (git-agent) always include one |
| 7 | CHANGELOG entry mentions "fallback embedded template specs" but skill just STOPs on missing templates | Inaccurate changelog |

---

## Recommended Changes

### 1. Add `README.md` to plugin root

Create `kit/plugins/social-media-tools/README.md` following the required structure from `plugin-patterns.md`:
- Overview (one paragraph)
- Features table (skill name, trigger phrases, output)
- Installation (marketplace and `--plugin-dir` commands)
- Usage examples (three scenarios: diff, feature, quote)
- Plugin structure (directory tree)
- Template variable quick-reference (link to `references/variables.md`)

### 2. Rewrite skill description to ≤160 chars (two-sentence format)

**Current (281 chars):**
> "Use when the user wants to create, draft, or generate a social media post (LinkedIn, Twitter/X, Bluesky) with a styled visual card. Also triggers on: 'write a LinkedIn post', 'tweet about this', 'social card for this change', 'post about this release'. Generates platform-aware copy and a dark-mode card image via Playwright screenshot."

**Proposed (155 chars):**
> "Generates social media copy and a dark-mode card image for LinkedIn, Twitter/X, or Bluesky. Use when asked to write a post, tweet, or share a code change."

### 3. Add project context auto-detection to Phase 1

Before calling `AskUserQuestion`, the skill should try to gather content from the project automatically. Insert this step at the start of Phase 1:

```
**Step 1a — Auto-detect content context (before asking)**

Run these commands silently and use results to pre-populate inputs:

```bash
# Recent diff stat — suggests diff-card if non-empty
git diff HEAD~1 --stat 2>/dev/null | head -20

# Recent commits — suggests feature-card if version bump or feat: prefix
git log --oneline -5 2>/dev/null

# CHANGELOG — use most recent entry as content if present
head -30 CHANGELOG.md 2>/dev/null
```

If any context is found:
- Auto-select content type (diff stat → `diff-card`, feat: commit or CHANGELOG bump → `feature-card`)
- Summarise what was found in a single sentence before the question block
- Only ask for platform and tone (not content — you already have it)

If no context is found, ask all three inputs (platform, content type, tone) via `AskUserQuestion`.
```

### 4. Fix `$PLUGIN_DIR` in Phase 5a

Phase 5a currently says:
> "`PLUGIN_DIR` is the parent of `templates/` found in Phase 3."

But never assigns the variable. Change to derive it explicitly:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
python3 "$PLUGIN_DIR/scripts/find_free_port.py"
```

Add this derivation as the first line of Phase 5a.

### 5. Remove `version` from SKILL.md frontmatter

Remove the `version: 0.1.0` line from the frontmatter. Version is tracked in `marketplace.json` only (per project conventions).

### 6. Add STOP boundary after Phase 6

Append to end of Phase 6:

```
**STOP.** Do not run further git commands, open browsers, or take any action beyond delivering the copy and card image.
```

### 7. Fix CHANGELOG entry

Change the inaccurate bullet:
- Before: `Fallback embedded template specs when plugin directory is not resolvable`
- After: `Fallback message with HTML path when Playwright screenshot is unavailable`

### 8. Version bump

All changes are additive improvements with no breaking changes → **PATCH** bump `0.1.0 → 0.1.1`.

Files to update:
- `.claude-plugin/marketplace.json` (code-share version field)
- `kit/plugins/social-media-tools/CHANGELOG.md` (add v0.1.1 entry)

---

## Files to Modify

| File | Change |
|------|--------|
| `kit/plugins/social-media-tools/README.md` | **Create** — full README |
| `kit/plugins/social-media-tools/skills/code-share/SKILL.md` | Description rewrite, Phase 1 context sourcing, Phase 5a fix, remove version, add STOP |
| `kit/plugins/social-media-tools/CHANGELOG.md` | Fix inaccurate bullet; add v0.1.1 entry |
| `.claude-plugin/marketplace.json` | Bump version to 0.1.1 |

---

## Verification

1. Load plugin locally: `claude --plugin-dir ./kit/plugins/social-media-tools`
2. Say: "write a LinkedIn post about today's changes" — skill should auto-detect git diff without asking for content type
3. Say: "tweet about this" with no project context — skill should ask all three inputs
4. Verify generated copy fits within platform character limits (printed count in Phase 6)
5. Confirm PNG card is attached via `SendUserFile`
6. Run `/skill-reviewer:reviewing-skills` on the updated SKILL.md for a scored audit
