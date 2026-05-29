---
status: completed
type: standard
scope: plugins/code-review/skills/code-review-agent/
created: 2026-04-01
---

# Progressive Disclosure: Extract Review Checklist and Example

## Context

The code-review-agent SKILL.md scored 10/10 but the audit noted the body could benefit from progressive disclosure. At ~1,844 body words and 396 lines, it's within limits but front-heavy: the Review Checklist (lines 63-254, ~192 lines) and Example Review (lines 299-379, ~81 lines) dominate the file. Extracting these to `references/` keeps the SKILL.md focused on the workflow while Claude loads the detail on demand.

## Steps

### 1. Create `references/` directory

Create `plugins/code-review/skills/code-review-agent/references/`.

### 2. Extract Review Checklist to `references/review-checklist.md`

- Move lines 63-254 (the `## Review Checklist` section through end of `### 6. Breaking Changes & Regressions`) into `references/review-checklist.md`
- Add a TOC at the top (required since it's >=100 lines)
- In SKILL.md, replace the extracted section with a brief directive:
  ```
  ## Review Checklist

  Read [references/review-checklist.md](references/review-checklist.md) for the
  full six-dimension checklist. Apply each dimension to every file under review.
  ```

### 3. Extract Example Review to `references/example-review.md`

- Move lines 299-379 (the `## Example Review` section with the 4-backtick fenced block) into `references/example-review.md`
- In SKILL.md, replace with a directive:
  ```
  ## Example Review

  See [references/example-review.md](references/example-review.md) for a complete
  sample review demonstrating the expected output format.
  ```

### 4. Update Table of Contents in SKILL.md

- Update the TOC to reflect the new structure (checklist and example are now reference links, not inline sections)

### 5. Bump version (MINOR)

- `.claude-plugin/marketplace.json` — bump `code-review` from `3.0.2` to `3.1.0` (structural change adding references/, backward compatible)

## Files Modified

| Action | File |
|--------|------|
| Edit | `plugins/code-review/skills/code-review-agent/SKILL.md` |
| Create | `plugins/code-review/skills/code-review-agent/references/review-checklist.md` |
| Create | `plugins/code-review/skills/code-review-agent/references/example-review.md` |
| Edit | `.claude-plugin/marketplace.json` |

## Verification

1. Confirm SKILL.md body is <200 lines after extraction
2. Confirm both reference files have a TOC (required for >=100 lines; recommended for shorter)
3. Re-run `/skill-reviewer:reviewing-skills` — should remain 10/10 with folder structure upgraded from "Minimum" to "Standard"
4. Load plugin locally and test activation: `claude --plugin-dir ~/devbox/agentics/plugins/code-review`

## Next Steps (out of scope)

- Add a `references/review-format-template.md` if the Review Format section also grows
- Consider adding `scripts/` for automated complexity scoring
