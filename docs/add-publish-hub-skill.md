# Bundle a plan and its related HTML into one hub artifact

> Adds `plan-agent:publish-hub`, a skill that bundles a plan and its related HTML files (prototype, companion pages) into a single self-contained hub artifact on claude.ai, published to a stable URL recorded as `hub-artifact-url:` in the spec frontmatter.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` — the bundler: parses a plan spec, renders the plan HTML, collects related files from `prototype:` frontmatter and `--extra` arguments, and emits one theme-aware tabbed page embedding each document in an `<iframe srcdoc>` (plan tab first, `design:` as an external-link tab). Handles `&` and `"` escaping in srcdoc values and enforces a 15 MB size cap.
- Added `kit/plugins/plan-agent/bin/plan-agent-hub` — the bare-name PATH wrapper for the bundler, following the `bin/plan-agent-render` pattern.
- Added `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` — resolves the spec, runs the bundler to a scratchpad file, publishes to the existing `hub-artifact-url:` (stable URL republish), writes the returned URL back to the spec, verifies the published page contains the plan title, and delivers via `SendUserFile` on failure.
- Added `tests/plugins/test-build-plan-hub.mjs` — bundler contract test: tabs, srcdoc escaping, size guard, and exit codes.
- Updated `kit/plugins/plan-agent/README.md` components section and regenerated the root README Plugin Reference Table.
- Bumped `plan-agent` to `9.8.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Hub bundler | Created |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | Bin wrapper | Created |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Skill instructions | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Bundler contract test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `README.md` | Plugin Reference Table (generated) | Modified |

## How it works

Plans published as claude.ai artifacts since plan-agent 9.6 share a single URL, but a plan's related HTML (prototype, companion docs) stays local. The `publish-hub` skill bundles everything into one page so a single link shows both the plan and its prototype.

The hub uses `<iframe srcdoc>` panels — everything is inlined, nothing external is fetched, and the artifact CSP allows it. Each tab title comes from the embedded file's `<title>` element. The design canvas (`design:` frontmatter key) becomes an external-link tab since the CSP blocks framing external URLs and the canvas is already its own live artifact.

The `hub-artifact-url:` frontmatter key is separate from `artifact-url:` so that a plain plan republish from `implementation-plan` Step 7 or `artifact-tools:plan-artifact` cannot silently clobber the hub's stable URL. The skill reads the key on each run and passes it as `url` to update in place, so the link stays stable across republishes.

## How to use it

```
/plan-agent:publish-hub docs/plans/my-feature.md
```

Or invoke `/plan-agent:publish-hub` without arguments to pick from existing plans.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
