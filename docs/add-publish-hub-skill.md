# Add publish-hub skill

> Adds a `publish-hub` skill to plan-agent that bundles all completed plan HTML files into a single tabbed artifact, accessed via a `hub-artifact-url:` key in plan frontmatter, using `<iframe srcdoc>` tabs.

<!-- generated:start -->

**Status:** Shipped 2026-08-26 **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` for generating the plan hub artifact.
- Created `kit/plugins/plan-agent/scripts/build-plan-hub.mjs`: bundles all completed plan HTML into a single artifact with `<iframe srcdoc>` tabs.
- Created `bin/plan-agent-hub` wrapper script.
- Added `hub-artifact-url:` key to plan frontmatter spec: stores the published hub URL so subsequent publishes update the same artifact.
- Created `tests/test-build-plan-hub.mjs`.
- Bumped plan-agent to 9.8.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Hub skill core | Created |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Hub bundler | Created |
| `bin/plan-agent-hub` | Wrapper script | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/` | hub-artifact-url spec | Modified |
| `tests/test-build-plan-hub.mjs` | Hub tests | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

`publish-hub` collects all `docs/plans/*.html` files and wraps them in a single-page artifact with a tab bar. Each plan gets one tab. The tab content is embedded via `<iframe srcdoc="...">` so each plan's styles and scripts are isolated from the hub shell and from each other — no CSS collisions between plans.

The `hub-artifact-url:` frontmatter key persists the published artifact URL. When `publish-hub` runs again, it reads this key from any plan's frontmatter, uses that URL to update the existing artifact in place, and writes the same URL back. This means the hub link doesn't change between publishes: anyone who bookmarked it sees the latest version automatically.

`build-plan-hub.mjs` is a separate bundler (not a wrapper around `build-plan-html.mjs`) because the hub has a fundamentally different output shape: one HTML file that references many plans, rather than one HTML file per plan.

## How to use it

```
/plan-agent:publish-hub
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
