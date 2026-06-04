---
status: todo
created: 2026-05-28
repo-name: agentics
---

# Execution: share-selection for social-share router (LinkedIn / announce)

> This is a direct write-heavy **skill execution**, not a multi-file planning task.
> Per global plan-mode rules, skills with write operations run outside plan mode.
> This file exists only to give an approval surface for exiting plan mode.

## What will run

Invoke `social-media-tools:share-selection` against:

- **File:** `kit/plugins/social-media-tools/skills/social-share/SKILL.md`
- **Platform:** LinkedIn
- **Objective:** Announce / promote the new `social-share` router skill

## Pipeline (from the skill)

1. **Locate** templates dir + derive `PLUGIN_DIR`.
2. **Capture** — read the SKILL.md; it exceeds ~80 lines, so ask which region to
   feature on the card (`snippet-card` caps at 80 lines).
3. **Reuse check** — scan `docs/media/social/` for an existing matching post; offer reuse.
4. **Security scrub** — run `security-scrub` on the captured code (expect PASS for a SKILL.md).
5. **Draft** — LinkedIn announce copy (<=1500 chars, narrative, 2-4 hashtags, topic-matched follow CTA).
6. **Template** — non-diff source -> `snippet-card.html`, `LANGUAGE=markdown`.
7. **Populate + save** — fill `{{VARIABLES}}`, save HTML to `docs/media/social/`.
8. **Screenshot** — serve locally, Playwright full-page PNG to `~/.claude/tmp/`.
9. **Deliver** — LinkedIn copy in a fenced block + attach the PNG + show saved path.

## Verification

- A PNG card is produced and attached, no dangling HTTP server process remains.
- LinkedIn copy is <=1500 chars, announce tone, ends with a follow CTA.
- Saved HTML exists under `docs/media/social/`.
