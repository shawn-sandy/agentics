### Step 5 — Type classification _(only when status resolves to `completed`)_

Infer content type from the plan's filename, H1 heading, and first 200 words
of body text. Apply the first matching rule:

| Signal | Inferred type |
|--------|---------------|
| Filename starts with `fix-`, `bugfix-`, or H1/body contains "bug", "fix", "patch", "regression" | `fix` |
| Filename starts with `refactor-`, `restructure-`, `simplify-`, or H1/body contains "refactor", "restructure", "simplify" | `refactor` |
| Filename starts with `document-`, `add-docs-`, `update-readme-`, or H1/body contains "documentation", "readme", "guide", "changelog" | `docs` |
| Filename starts with `bump-`, `rename-`, `update-version-`, `cleanup-`, or H1/body contains "chore", "housekeeping", "version bump", "rename" | `chore` |
| Default (no strong signal or filename starts with `add-`, `create-`, `implement-`, `build-`) | `feature` |

If the file already has a valid content type (`feature`, `fix`, `refactor`,
`docs`, `chore`), keep it.
