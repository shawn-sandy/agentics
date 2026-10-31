# Bundle a plan and its related HTML into one hub artifact

> Adds a `publish-hub` skill to `plan-agent` that bundles a plan and its related HTML files into a single self-contained hub artifact on claude.ai, published to a stable URL recorded as `hub-artifact-url:` in the spec frontmatter.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-publish-hub-skill](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` — bundles plan + prototype + companion HTML pages into one hub artifact
- Hub artifact published to claude.ai with a stable URL; `hub-artifact-url:` written to spec frontmatter for future re-publishes
- Related HTML files resolved from `prototype:` and `design:` frontmatter keys plus explicit `--extra` arguments; no directory scanning
- Bumped `plan-agent` with CHANGELOG entry and README update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Skill — hub artifact assembly and publish | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs | Modified |

## How it works

A plan lives as a Markdown spec with companion HTML files scattered across `docs/plans/`, `docs/prototypes/`, and `docs/artifacts/`. Sharing a plan means sending multiple links. The `publish-hub` skill consolidates these into one artifact page with navigation between all the related files.

The skill reads the plan's frontmatter to find related files: `prototype:` points at the prototype HTML, `design:` carries an external-link tab for the design artifact. Additional pages can be passed as `--extra <path>` arguments. Related files come only from these sources — the skill never scans for sibling files or uses `artifact-url:` as a file input (that key tracks the plain plan page artifact and is never touched by publish-hub). All discovered files are bundled into a multi-file artifact publish call.

The hub's `index.html` is generated with a plan summary, navigation cards for each related file, and embedded previews where the content type allows. After publishing, the skill writes `hub-artifact-url: <url>` back into the plan spec frontmatter so subsequent runs update the same artifact rather than creating a new one.

## How to use it

```
/plan-agent:publish-hub                  # bundle and publish current plan's hub
/plan-agent:publish-hub docs/plans/my-plan.md   # specific plan
```

The skill activates when the user asks to publish or share a plan with all its related files.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a3d5f89` | 2026-08-26 | feat(plan-agent): add publish-hub skill |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill](plans/add-publish-hub-skill.md)
