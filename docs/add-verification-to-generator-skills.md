# Give the HTML-generating and publishing skills a check they can run

> Adds a runnable output check to nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done", covered by suites in `tests/plugins/`.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-verification-to-generator-skills](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Added runnable verification steps to nine HTML-generating/publishing skills across `plan-agent`, `artifact-tools`, and `social-media-tools`
- Each skill now runs its own output check after generation: file existence check, DOM invariant assertions via `grep`, or HTTP status verification for published artifacts
- Created test suites in `tests/plugins/` covering each skill's verification contract
- Covered skills include: `plan-to-html`, `plan-artifact`, `diff-artifact`, `session-artifact`, `save-artifact`, `share-session`, `share-selection`, `share-code`, and `markdown-to-html`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/markdown-to-html/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/plan-agent/skills/plan-to-html/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/artifact-tools/skills/save-artifact/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/social-media-tools/skills/share-session/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/social-media-tools/skills/share-selection/SKILL.md` | Skill — verification step | Modified |
| `kit/plugins/social-media-tools/skills/share-code/SKILL.md` | Skill — verification step | Modified |
| `tests/plugins/test-verification-gates-skills.sh` | Smoke test — verification contract presence | Created |

## How it works

Before this change, all nine skills reported success when they finished writing the output file or calling the publish API. None re-read the file to confirm it existed with the expected content, checked DOM invariants, or verified the publish actually succeeded.

The fix pattern is the same for each: after the write or publish step, add a bounded verification that confirms the output is correct. For file-generating skills, this is a `Glob` check that the file exists followed by `grep` assertions on one or two DOM invariants (title tag, expected container class). For publishing skills, this queries the published artifact's URL and checks for HTTP 200 with the expected content type. Either way, the skill reports `VERIFIED` on success and `FAILED (reason)` on failure, rather than assuming success.

The test suites in `tests/plugins/` grep each SKILL.md for the verification step and its `VERIFIED`/`FAILED` outcome markers, confirming the contract cannot be silently removed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills](plans/add-verification-to-generator-skills.md)
