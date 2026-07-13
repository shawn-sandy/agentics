---
status: in-progress
created: 2026-02-26
---

# Plan: Rename Non-Descriptive Plan Files

## Context

Plan files in `docs/plans/` use randomly generated names (e.g. `fuzzy-swimming-pearl.md`) that obscure their purpose. Renaming them to match their content makes the plans directory scannable and maintainable.

## Files to Keep (Already Descriptive)

- `fix-claude-md-stale-local-filename.md`
- `plugin-development-guide.md`
- `optimize-claude-md-optimizer-skill.md`
- `improve-skill-reviewer-plugin.md`

## Rename Operations

Use `git mv` to preserve git history.

| Current Name | New Name |
|---|---|
| `fuzzy-swimming-pearl.md` | `create-skill-reviewer-plugin.md` |
| `rippling-scribbling-otter.md` | `improve-claude-md-optimizer-accuracy.md` |
| `wiggly-floating-crayon.md` | `document-plugin-version-bump-process.md` |
| `floofy-wobbling-toucan.md` | `audit-planning-skills-skill.md` |
| `bubbly-purring-mccarthy.md` | `enhance-claude-md-optimizer-path-rules.md` |
| `zany-waddling-turtle.md` | `update-wcag-reviewer-to-2.2.md` |
| `peaceful-splashing-lake.md` | `create-path-rules-advisor-skill.md` |
| `concurrent-baking-volcano.md` | `fix-stale-commands-in-claude-md.md` |
| `reflective-brewing-glade.md` | `refactor-dev-tools-extract-standalone-plugins.md` |
| `sprightly-splashing-fog.md` | `update-wcag-reference-to-2.2.md` |
| `immutable-wobbling-elephant.md` | `create-hello-world-testing-docs.md` |
| `fizzy-noodling-waffle.md` | `fix-local-md-stale-filename-reference.md` |
| `clever-launching-coral.md` | `fix-claude-md-optimizer-skill-violations.md` |
| `snug-crunching-cat.md` | `add-claude-md-optimizer-skill-to-dev-tools.md` |
| `glittery-wishing-snail.md` | `optimize-plan-interview-skill.md` |
| `recursive-seeking-biscuit.md` | `enhance-readmes-with-setup-docs.md` |
| `robust-juggling-meerkat.md` | `create-dev-tools-skill-readmes.md` |
| `flickering-tumbling-iverson.md` | `register-wcag-reviewer-plugin.md` |
| `expressive-meandering-sonnet.md` | `implement-marketplace-api-service.md` |
| `enumerated-herding-muffin.md` | `fix-marketplace-json-location-in-claude-md.md` |
| `robust-swinging-stearns.md` | `cleanup-marketplace-json-unsupported-fields.md` |
| `purrfect-snacking-brooks.md` | `update-claude-md-plugin-list.md` |
| `melodic-dreaming-clover.md` | `move-claude-plugin-to-project-root.md` |
| `lucky-booping-yao.md` (this file) | `rename-plan-files-to-descriptive-names.md` |

## Steps

1. Run `git mv` for each of the 24 renames above (including this plan file itself)
2. Commit: `docs(plans): rename non-descriptive plan files to match purpose`

## Verification

- `ls docs/plans/` — confirm no random-word filenames remain
- `git status` — confirm all renames are staged
