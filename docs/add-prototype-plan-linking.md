# Make a plan and its prototype aware of each other

> Gives every plan a back-link to its prototype, persists the prototype's derived data model in both files, and adds a `PostToolUse` hook that flags when a prototype has drifted from its own model or from its plan's copy of it.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-prototype-plan-linking](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `prototype:` frontmatter field to plan specs pointing at the sibling prototype file
- Added `proto-source:` metadata reference in prototype HTML files pointing back at the plan
- Persisted prototype's derived data model in frontmatter of both files as `data-model:` block
- Added `PostToolUse` hook that runs after Write/Edit on prototype files (under `docs/prototypes/`), diffs the data models, and flags drift
- Bumped `plan-agent` with CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — `prototype:` field, data-model persistence | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | Hook script — PostToolUse drift detection | Created |
| `kit/plugins/plan-agent/hooks.json` | Hook wiring — PostToolUse entry | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

Plans and prototypes are companion documents: the plan describes what to build and the prototype is the working visual model. When they drift — the prototype evolves but the plan's data model copy doesn't update, or vice versa — the plan becomes a stale description of something different from the actual design.

The back-link (`prototype:` in the plan, `<meta name="proto-source">` in the prototype HTML) makes this relationship explicit and machine-readable. The hook reads the `data-model:` block from both files after any Write/Edit to a prototype file and computes a diff. A non-empty diff triggers a warning with the specific fields that diverged, giving the author an immediate signal rather than a delayed discovery.

The `data-model:` block is a structured YAML representation of the prototype's primary entities — the same information the prototype shows visually, extracted as named fields. Both files store the same copy; the hook treats either file as the source of truth and flags when they diverge.

## How to use it

In a plan frontmatter:
```yaml
prototype: docs/prototypes/my-feature.html
data-model:
  entities: [User, Post, Comment]
  primary-key: id (uuid)
```

The drift hook fires automatically on every Write/Edit — no manual invocation needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking](plans/add-prototype-plan-linking.md)
