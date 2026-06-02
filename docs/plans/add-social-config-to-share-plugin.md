---
title: Add SOCIAL.md Project Sharing Config
status: complete
plugin: social-media-tools
version: "2.5.0"
---

# Add SOCIAL.md Project Sharing Config

**Status:** complete
**Plugin:** social-media-tools
**Version:** 2.5.0 (minor bump — new skill added)

## Problem

Every share invocation asks for platform, tone, and content focus from scratch.
There is no project-level configuration to pre-populate sharing defaults or
guide content discovery.

## Solution

Introduce a `SOCIAL.md` convention — a file at the project root that all share
skills read for defaults:

- **Identity** — project name and tagline overrides
- **Defaults** — platform, tone, hashtags
- **Focus** — topics/areas to prioritize when scanning
- **Avoid** — paths/patterns to exclude from sharing
- **Audience** — target reader description
- **Examples** — reference posts for style

## Changes

| File | Change |
|------|--------|
| `references/social-config.md` | New — documents `SOCIAL.md` format |
| `skills/share-init/SKILL.md` | New — skill to analyze project and generate `SOCIAL.md` |
| `skills/social-share/SKILL.md` | Phase 0b loads `SOCIAL.md`; Phase 3 uses `DEFAULT_PLATFORM` |
| `skills/share-code/SKILL.md` | Phase 0b loads `SOCIAL.md`; Phase 1 uses defaults |
| `skills/share-project/SKILL.md` | Phase 0b loads `SOCIAL.md`; Phases 1 and 5 use defaults |
| `skills/share-scan/SKILL.md` | Step 0b loads `SOCIAL.md`; Step 2b filters avoids; Step 3 boosts focus areas |
| `CHANGELOG.md` | v2.5.0 entry |
| `.claude-plugin/plugin.json` | Added keywords |
| `.claude-plugin/marketplace.json` | Version bump + tags |
