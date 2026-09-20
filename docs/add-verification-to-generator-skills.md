# Give the HTML-generating and publishing skills a check they can run

> Nine skills generate HTML or publish it to a live URL and then report success without ever looking at the output, so a blank artifact is indistinguishable fr...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
**Type:** feature

## What shipped

- Add a render assertion to the four `artifact-tools` skills by appending a step after each publish that fetches the re...
- Add an index assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file par...
- Leave `plans-open` functionally alone but add a one-line note to its SKILL.md recording that its output check lives i...
- Add a diff-back check to `agentic-memory-doctor` and `path-rules-advisor` that, after rewriting CLAUDE.md or a rules...
- Add suites to `tests/plugins/` for steps 1, 2, and 4 following the existing naming and shape, with each asserting tha...
- Bump `version` in `.claude-plugin/marketplace.json` for `artifact-tools`, `plan-agent`, `social-media-tools`, and `me...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | fetch-back render assertion after publish | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | card-count assertion against source count | Modified |
| `kit/plugins/plan-agent/skills/plans-open/SKILL.md` | one-line note on why its check lives in plans-library | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | card-count assertion against source count | Modified |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | diff-back and parse check before reporting success | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | diff-back and parse check before reporting success | Modified |
| `tests/plugins/test-generator-skills-verify-output.sh` | the objective-verification test | Created |
| `tests/plugins/test-index-card-count.mjs` | unit test for the card-count assertion | Created |
| `tests/plugins/test-memory-doctor-guard.sh` | integration test for the memory guard | Created |
| `tests/plugins/test-artifact-render-check.sh` | E2E test for the publish and fetch-back flow | Created |
| `.claude-plugin/marketplace.json` | MINOR bumps for the four plugins touched | Modified |

## How it works

Add a runnable output check to the nine skills that generate or publish HTML without one, so each closes its own verification loop instead of reporting success on "looks done", and cover them with suites in the existing `tests/plugins/` harness.

Claude Code's best-practices guide opens with its strongest claim: "Claude stops when the work looks done. Without a check it can run, 'looks done' is the only signal available, and you become the verification loop: every mistake waits for you to notice it." A survey of the 13 marketplace plugins on 2026-07-16 read all 59 SKILL.md files and found roughly two dozen with no check step. That aggregate is approximate and deliberately not load-bearing here: it came from a keyword scan, which cannot d...

The implementation proceeded through these steps: Add a render assertion to the four `artifact-tools` skills by appending a step after each publish that fetches the re...; Add an index assertion to `plans-library` and `media-library` that, after writing `index.html`, confirms the file par...; Leave `plans-open` functionally alone but add a one-line note to its SKILL.md recording that its output check lives i...; Add a diff-back check to `agentic-memory-doctor` and `path-rules-advisor` that, after rewriting CLAUDE.md or a rules ...; Add suites to `tests/plugins/` for steps 1, 2, and 4 following the existing naming and shape, with each asserting tha....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-verification-to-generator-skills.md](plans/add-verification-to-generator-skills.md)
