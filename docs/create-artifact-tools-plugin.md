# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships a new `artifact-tools` plugin with three skills that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created `artifact-tools` plugin at `kit/plugins/artifact-tools/` with three skills: `diff-artifact`, `session-artifact`, and `plan-artifact`.
- `diff-artifact` generates an annotated diff walkthrough HTML page — sticky file sidebar, per-hunk margin annotations, severity coding with labels (critical/warn/note), adaptive light/dark palettes — with a blocking security-scrub gate before every publish.
- `session-artifact` exports session JSONL to a Markdown recap in reviewer-first order (Summary, Decisions, Learnings, Files), scrubs it, and publishes via the Artifact tool.
- `plan-artifact` wraps existing plan HTML for publish/republish, reading `artifact-url:` from frontmatter for stable cross-session URLs.
- All skills write the returned Artifact URL back into source frontmatter as `artifact-url:` and offer a local-HTML fallback when publishing is unavailable.
- Registered `artifact-tools` at 1.0.0 in `.claude-plugin/marketplace.json`.
- Shipped `tests/plugins/test-artifact-tools.sh` as a structural smoke test.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Changelog | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Diff walkthrough skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan publish/republish skill | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |

## How it works

The plugin centralizes artifact publishing for the three content types teams share most. `diff-artifact` and `session-artifact` each run `social-media-tools:security-scrub` as a blocking gate before any publish — the scrub returns a structured `GATE RESULT` and the skill stops on anything other than `APPROVED`. `plan-artifact` does not run this gate: plan HTML is authored in-session and published directly, relying on the `plan-agent` authoring flow rather than a post-hoc scrub.

`diff-artifact` is the only genuinely new generator: it resolves a diff from the current branch, a commit range, or a PR number (`gh pr diff <n>`), annotates each hunk with severity-coded margin notes, and emits a single self-contained HTML page within the 16 MiB artifact cap via a cap-and-summarize policy for large files.

`session-artifact` bundles its own `export_session.py` (copied from `social-media-tools:export-session`) so there is no cross-plugin install-order dependency. The extractor processes the newest project JSONL transcript and produces a reviewer-first Markdown recap saved under `{plansDirectory}/sessions/`.

`plan-artifact` is deliberately thin: plan HTML from `plan-agent` is already CSP-compliant and self-contained, so the skill only handles the URL lifecycle — first publish writes `artifact-url:` into the `.md` spec's frontmatter, subsequent republishes read it and pass it as the `url` parameter so viewers see updates at a stable link.

The `artifact-url:` frontmatter key is the cross-session persistence mechanism for all three skills. Without it, each session would mint a new page and the old URL would go stale.

## How to use it

```
/artifact-tools:diff-artifact                  # current branch vs default
/artifact-tools:diff-artifact --pr 42          # PR diff
/artifact-tools:session-artifact               # newest project transcript
/artifact-tools:plan-artifact docs/plans/my-plan.html
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `174d0efc` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `6d6bfeb3` | 2026-08-26 | feat(artifact-tools): add diff-artifact, session-artifact, plan-artifact skills (1.0.0) — bulk commit |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
- Related: [fix-artifact-title-mechanism.md](fix-artifact-title-mechanism.md), [extract-recap-command-core.md](extract-recap-command-core.md)
