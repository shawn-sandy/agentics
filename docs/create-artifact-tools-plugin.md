# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships a new `artifact-tools` plugin with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages, with a scrub gate before every publish and a local-HTML fallback.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [create-artifact-tools-plugin](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools/` plugin registered in marketplace at v1.0.0
- `diff-artifact` skill: reads `git diff <base>...HEAD`, scrubs for secrets, publishes as a styled diff artifact on claude.ai
- `session-artifact` skill: reads the session transcript JSONL, extracts conversational turns, publishes a recap artifact
- `plan-artifact` skill: reads an implementation plan spec, publishes the rendered HTML as an artifact
- Shared scrub gate across all three skills: `security-scrub` checks for secrets before any publish; local-HTML fallback when claude.ai is unavailable
- Created `tests/plugins/test-artifact-tools.sh` covering frontmatter, republish keys, PR-mode preflight

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/` | Plugin directory | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill — diff artifact | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill — session recap artifact | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill — plan artifact | Created |
| `kit/plugins/artifact-tools/skills/security-scrub/SKILL.md` | Skill — shared scrub gate | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — artifact-tools v1.0.0 | Modified |

## How it works

Each skill reads its source material (diff, transcript JSONL, or plan spec), passes it through the shared `security-scrub` skill that scans for secrets and credentials using the pattern library in `references/scrub-rules.md`, and publishes the result as a claude.ai artifact with a stable URL.

The `session-artifact` skill is the shared pipeline that `product-doc`, `team-recap`, `eng-recap`, and `teach-artifact` all delegate to for extraction. It reads `~/.claude/projects/<slug>/<session>.jsonl`, filters to user and assistant turns, strips harness injections, and builds the HTML document. All four recap commands use this extraction pipeline and add only their own framing on top.

Republish keys (`artifact-url:`, `product-artifact-url:`, etc.) are stored in the session record so subsequent runs update the same artifact rather than creating a new one. The `test-artifact-tools.sh` check 7 maintains a key collision map asserting that each command owns a unique key.

## How to use it

```
/artifact-tools:diff-artifact            # publish current branch diff as artifact
/artifact-tools:session-artifact         # publish session recap as artifact
/artifact-tools:plan-artifact            # publish current plan as artifact
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin](plans/create-artifact-tools-plugin.md)
