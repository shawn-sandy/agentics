---
status: in-progress
created: 2026-02-24
modified: 2026-02-26
---

# Plan: Register wcag-compliance-reviewer Plugin

## Context

The `wcag-compliance-reviewer` plugin exists with complete skill content (SKILL.md, reference files, Python checker script) but is missing the structural requirements to function as a proper Claude Code plugin. It has no `.claude-plugin/plugin.json` manifest, the SKILL.md is at the root instead of the expected `skills/<name>/SKILL.md` subdirectory, it is not registered in the marketplace, and it has no CHANGELOG.

## Critical Files

- `plugins/wcag-compliance-reviewer/SKILL.md` — move to `skills/wcag-compliance-reviewer/SKILL.md`
- `plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json` — create (missing)
- `plugins/wcag-compliance-reviewer/CHANGELOG.md` — create (missing)
- `plugins/wcag-compliance-reviewer/README.md` — update Installation section
- `.claude-plugin/marketplace.json` — add plugin entry

## Steps

1. Create `.claude-plugin/plugin.json` inside the plugin directory:

   ```json
   {
     "name": "wcag-compliance-reviewer",
     "version": "1.0.0",
     "description": "Review HTML/CSS and React/TypeScript code for WCAG 2.1 Level AA accessibility compliance",
     "author": { "name": "Agentics Project" },
     "license": "MIT",
     "keywords": ["accessibility", "wcag", "a11y", "wcag-2.1", "aria", "color-contrast", "screen-reader", "compliance-audit"],
     "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/wcag-compliance-reviewer",
     "repository": "https://github.com/shawn-sandy/agentics"
   }
   ```

2. Move all skill-related files into `skills/wcag-compliance-reviewer/` (no path changes needed in SKILL.md):
   - `SKILL.md` → `skills/wcag-compliance-reviewer/SKILL.md`
   - `references/` → `skills/wcag-compliance-reviewer/references/`
   - `scripts/` → `skills/wcag-compliance-reviewer/scripts/`

3. Append plugin entry to `.claude-plugin/marketplace.json` `plugins` array:

   ```json
   {
     "name": "wcag-compliance-reviewer",
     "source": "./plugins/wcag-compliance-reviewer",
     "version": "1.0.0",
     "description": "Review HTML/CSS and React/TypeScript code for WCAG 2.1 Level AA accessibility compliance",
     "category": "accessibility",
     "tags": ["accessibility", "wcag", "a11y", "wcag-2.1", "aria", "color-contrast", "screen-reader", "compliance-audit"]
   }
   ```

4. Create `CHANGELOG.md` documenting the 1.0.0 initial release.

5. Replace `README.md` lines 22–82 (Installation section) with marketplace-based install instructions. All stale content (`gitpick`, `shawn-sandy/acss`, `~/.claude/skills/`) is confirmed to be in this range only.

## Resulting Structure

```
plugins/wcag-compliance-reviewer/
├── .claude-plugin/
│   └── plugin.json                          (NEW)
├── skills/
│   └── wcag-compliance-reviewer/
│       ├── SKILL.md                         (MOVED from root)
│       ├── references/                      (MOVED from root)
│       │   ├── wcag-aa-guidelines.md
│       │   ├── common-violations.md
│       │   └── testing-guide.md
│       └── scripts/                         (MOVED from root)
│           └── check_wcag.py
├── README.md                                (Installation section updated)
└── CHANGELOG.md                             (NEW)
```

## Verification

```bash
# Confirm version sync
grep '"version"' plugins/wcag-compliance-reviewer/.claude-plugin/plugin.json .claude-plugin/marketplace.json

# Confirm skill and co-located files are in correct location
ls plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/

# Load plugin locally to test skill activation
claude --plugin-dir ~/devbox/agentics/plugins/wcag-compliance-reviewer
```

## Commit

```
feat(plugins/wcag-compliance-reviewer): add plugin manifest and register in marketplace at v1.0.0
```
