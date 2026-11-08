# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships a new `artifact-tools` plugin with three skills that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages with a scrub gate before every publish and a local-HTML fallback.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/artifact-tools` with three skills: `diff-artifact` (annotated branch diff walkthrough), `session-artifact` (reviewer-first session recap), and `plan-artifact` (plan HTML republish).
- Every skill runs `social-media-tools:security-scrub` as a blocking gate before any publish; a `GATE RESULT: BLOCKED` or `CANCELLED` stops the skill entirely.
- `diff-artifact` produces a self-contained HTML page with a sticky changed-files sidebar, per-hunk margin annotations, severity coding with a text legend (critical/warn/note), adaptive light/dark palettes, and a cap-and-summarize policy so files beyond the annotation budget render as one-line summary rows — keeping the page under the 16 MiB artifact cap.
- `session-artifact` bundles its own `scripts/export_session.py` (copied from `social-media-tools`) so the plugin works with no cross-plugin install order dependency.
- `plan-artifact` reads `artifact-url:` from the plan spec's frontmatter and passes it to the `Artifact` tool's `url` parameter on republish, so the same claude.ai URL updates in place across sessions.
- All three skills write the returned `artifact-url:` back into the source file so future sessions can republish to the same link.
- Registered in `.claude-plugin/marketplace.json` at 1.0.0; `tests/plugins/test-artifact-tools.sh` provides structural smoke test coverage.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest (no version key) | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Annotated diff walkthrough skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan HTML publish/republish skill | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin overview and usage | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |
| `.claude-plugin/marketplace.json` | artifact-tools registered at 1.0.0 | Modified |

## How it works

**diff-artifact** resolves the diff source (current branch vs default, a commit range, or a PR number via `gh pr diff`) and runs `security-scrub` before building the page. The sticky sidebar lists every changed file with add/del counts as anchor links; each file section carries per-hunk margin annotations with severity labels. Files that would exceed the annotation budget are collapsed to one-line summary rows. The completed HTML is published via the `Artifact` tool, with the returned URL written as `artifact-url:` in an inbox file under `.claude/artifacts/`. On publish failure, the local HTML is kept and `social-media-tools:save-artifact` is offered as an alternative.

**session-artifact** locates the session transcript via JSONL path, explicit session ID, or the newest transcript for the project, then runs `export_session.py` to extract turns. The recap is structured in reviewer-first order: Summary, Decisions (with rationale), Learnings, Files touched. After scrubbing, it is saved under `{plansDirectory}/sessions/` as a `.md` file (so `artifact-url:` persists in frontmatter across sessions) and published as an artifact.

**plan-artifact** accepts a plan `.html` path (plan-agent output is already self-contained and CSP-compliant), reads `artifact-url:` from the sibling `.md` spec's frontmatter when present, and passes it as the `url` parameter to `Artifact` so republishing hits the same page. First-time publishes write the returned URL back into the spec frontmatter.

## How to use it

```
/artifact-tools:diff-artifact                    # current branch vs default
/artifact-tools:diff-artifact --pr 42            # specific PR
/artifact-tools:diff-artifact main..HEAD         # commit range

/artifact-tools:session-artifact                 # newest project transcript
/artifact-tools:session-artifact <path>          # explicit transcript path

/artifact-tools:plan-artifact docs/plans/my-plan.html  # publish or republish
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
- Related: [kit/plugins/artifact-tools/README.md](../kit/plugins/artifact-tools/README.md)
- Related: [kit/plugins/artifact-tools/CHANGELOG.md](../kit/plugins/artifact-tools/CHANGELOG.md)
