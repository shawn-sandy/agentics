---
name: plan-artifact
description: "Publishes an implementation plan as a claude.ai artifact. Republishes to the same URL across sessions so viewers watch steps check off live. Use when asked to publish or share a plan."
allowed-tools: Read, Edit, Glob, Skill, Artifact, AskUserQuestion, ToolSearch, ExitPlanMode
---

# plan-artifact

Publish a `plan-agent` HTML plan to claude.ai, and republish it to the *same*
URL as work progresses so viewers watch the steps check off at a link they
already have.

## Overview

`plan-agent` plans are already self-contained, CSP-compliant HTML, so there is no
generation work here. This skill's whole value is the **stable URL**: it records
the artifact URL in the plan spec's frontmatter so any later session republishes
to the same page instead of minting a new one.

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** —
skip this step entirely when not in plan mode. When calling: use `ToolSearch`
with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

## Step 1 — Resolve the plan

Accept a plan `.html` path. If none was given, `Glob` `docs/plans/*.html`
(excluding `index.html`) and ask via `AskUserQuestion`. Never guess.

Each plan HTML has a sibling `.md` spec — the same basename. The spec is the
source of truth; the HTML is generated from it.

> **Never hand-edit the plan HTML.** It is generated, and `plan-agent`'s
> markdown-first rule means the next rebuild overwrites your edit without
> warning. Edit the `.md` spec and let the plan rebuild.

## Step 2 — Read `artifact-url:` from the spec

Read the sibling `.md` spec's frontmatter:

```yaml
---
status: in-progress
type: feature
created: 2026-07-14
artifact-url: https://claude.ai/public/artifacts/abc-123
---
```

The renderer preserves unknown frontmatter keys, so `artifact-url:` survives
rebuilds. Two flows follow from whether it is present:

| Flow | Condition | Action |
|------|-----------|--------|
| **First publish** | no `artifact-url:` | publish fresh, then write the returned URL into the spec frontmatter |
| **Republish** | `artifact-url:` present | pass it to `Artifact`'s `url` parameter — updates the same page |

## Step 3 — Publish

`Artifact` is a deferred tool: use `ToolSearch` with `select:Artifact` first.

Publish the plan `.html` with a one-sentence `description` and the favicon `📄`.

Before publishing, check the generated `<title>` against
`${CLAUDE_PLUGIN_ROOT}/references/titles.md` — read it first. The plan HTML
arrives with a title already baked in by `plan-agent`, so this is a check, not an
authoring step. If it fails the rules, fix the **`.md` spec's title and rebuild**
— per Step 1, hand-editing the HTML is overwritten without warning.

Keep the title and favicon stable across republishes — they are how users find
the tab again.

On a **first publish**, `Edit` the spec's frontmatter to add the returned
`artifact-url:`. This is the step that makes every future republish hit the same
link — skip it and the next session silently mints a new page.

## Step 4 — The live-update loop

This is what makes plan publishing worth doing:

1. Publish once; share the URL with the team.
2. Do the work; update `status:` and check off steps in the `.md` spec.
3. Let the plan HTML rebuild, then run this skill again.
4. The same URL now shows current progress — no new link, no re-share.

Tell the user this explicitly on first publish, so they know to republish after
progress edits rather than re-sharing a new link.

## Step 5 — Fallback

If publishing fails (no claude.ai login, or publishing unavailable), the plan
HTML on disk is unchanged and remains the deliverable. Say plainly that
publishing did not happen and why, and offer two routes:

- `social-media-tools:save-artifact` — publishes into the repo's GitHub Pages
  artifacts gallery.
- The plans gallery — `docs/plans/index.html` already indexes the plan locally.

Never report a URL that was not returned by a successful publish.
