# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ship a new `artifact-tools` plugin with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [create-artifact-tools-plugin](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Scaffolded `kit/plugins/artifact-tools/` with plugin manifest (no `version` key), README, and CHANGELOG.
- Authored `diff-artifact/SKILL.md`: annotated diff walkthrough with sticky sidebar, per-hunk margin annotations, severity labels with legend, adaptive light/dark theme, 16 MiB cap-and-summarize policy, blocking security-scrub gate, local-HTML fallback, and `artifact-url:` frontmatter write for cross-session republish.
- Authored `session-artifact/SKILL.md` plus a bundled `scripts/export_session.py` (copied from social-media-tools) so the plugin operates with no install-order dependency.
- Authored `plan-artifact/SKILL.md`: thin publish wrapper that reads `artifact-url:` from the sibling spec's frontmatter to republish to the same page across sessions.
- Registered `artifact-tools` in `.claude-plugin/marketplace.json` at 1.0.0.
- Wrote `tests/plugins/test-artifact-tools.sh`, a structural smoke test asserting manifest validity, required frontmatter, and marketplace registration.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest; no version key | Created |
| `kit/plugins/artifact-tools/README.md` | Overview, features, installation, usage, structure | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Annotated diff walkthrough artifact | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap artifact with learnings | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Publish and republish plan HTML | Created |
| `.claude-plugin/marketplace.json` | artifact-tools registered at 1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |

## How it works

Claude Code artifacts are self-contained pages published to a private claude.ai URL that update in place on republish. They carry hard constraints the skills had to respect: a strict Content Security Policy (no external requests — everything inlined), a 16 MiB rendered-size cap, single-page only (in-page anchors, no relative links), and `.html`/`.md` sources. The plugin was scaffolded first to establish the manifest structure; a `version` key was deliberately omitted from `plugin.json` because the version lives only in `marketplace.json` for relative-path plugins, and including one there silently overrides the marketplace value.

`diff-artifact` is the one genuinely new generator in the kit. It resolves the diff source — current branch vs default branch, a commit range argument, or a PR number via `gh pr diff <n>`, degrading gracefully to branch mode when gh or the GitHub remote is missing. It runs `social-media-tools:security-scrub` as a hard-stop blocking gate before any publish, then builds a self-contained annotated-diff HTML page: a sticky changed-files sidebar with add/del counts anchor-linked to each file section, per-hunk margin annotations, severity coding that pairs each color with a text label (critical/warn/note) plus a legend, and adaptive light/dark palettes via `prefers-color-scheme`. Files beyond the per-file annotation budget render as one-line summary rows so the page stays under 16 MiB. The skill writes the returned URL as an `artifact-url:` comment in `.claude/artifacts/` and falls back to `social-media-tools:save-artifact` on publish failure.

`session-artifact` locates the newest JSONL transcript for the project using the same lookup conventions as the social-media-tools export-session skill, then runs the bundled `scripts/export_session.py` to extract turns. The recap is written in reviewer-first order — Summary, Decisions (with rationale), Learnings (approaches tried and abandoned, gotchas discovered), Files touched — scrubbed, saved under `{plansDirectory}/sessions/`, and published as a `.md` file directly (Markdown renders as styled HTML at the lowest token cost). The bundled extractor was copied from social-media-tools so artifact-tools operates with no install-order dependency.

`plan-artifact` is a thin publish wrapper: it reads `artifact-url:` from the sibling `.md` spec's frontmatter and passes it to the `Artifact` tool's `url` parameter when present, republishing to the same page. When absent it publishes fresh and writes the new URL back into the spec frontmatter (the renderer preserves unknown keys). The live-update loop — republish after progress edits so viewers see steps check off at the same link — is documented in the skill body.

`test-artifact-tools.sh` validates plugin structure following the existing `test-save-artifact.sh` pattern: `plugin.json` is valid JSON without a `version` key, all three SKILL.md files exist with `name`, `description`, and `allowed-tools` frontmatter, the bundled `export_session.py` exists, and the marketplace entry is present at 1.0.0.

## How to use it

```bash
# Load the plugin
claude --plugin-dir ./kit/plugins/artifact-tools

# Publish an annotated diff of the current branch:
/artifact-tools:diff-artifact

# Publish a session recap from the newest transcript:
/artifact-tools:session-artifact

# Publish (or republish) an implementation plan:
/artifact-tools:plan-artifact docs/plans/<slug>.html

# Run the smoke test:
bash tests/plugins/test-artifact-tools.sh
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin](plans/create-artifact-tools-plugin.md)
