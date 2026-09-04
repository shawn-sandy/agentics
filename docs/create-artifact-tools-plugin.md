# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Teams get live, shareable claude.ai pages for code diffs, working sessions, and implementation plans without leaving Claude Code, with a security scrub gate before every publish and a local-HTML fallback when publishing is unavailable.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Scaffolded `kit/plugins/artifact-tools/` with a valid `.claude-plugin/plugin.json` (no `version` key), `README.md`, and `CHANGELOG.md`.
- Authored `skills/diff-artifact/SKILL.md`: resolves a diff source (current branch vs default, commit range, or PR via `gh pr diff`), runs `social-media-tools:security-scrub` as a blocking gate, builds a self-contained annotated-diff HTML page with a sticky sidebar, per-hunk annotations, severity coding with a text legend, adaptive light/dark themes, and a cap-and-summarize policy to stay under the 16 MiB artifact cap.
- Authored `skills/session-artifact/SKILL.md` and bundled `scripts/export_session.py` (copied from `social-media-tools` to avoid cross-plugin coupling): locates the newest project transcript, extracts turns via the bundled script, writes a reviewer-first recap (Summary, Decisions, Learnings, Files touched), scrubs it, saves it under `{plansDirectory}/sessions/`, and publishes an HTML render.
- Authored `skills/plan-artifact/SKILL.md`: accepts a plan `.html` path, reads `artifact-url:` from the sibling `.md` spec's frontmatter to republish to the same URL across sessions, falls back to a fresh publish and writes the new URL back into the spec.
- Registered `artifact-tools` in `.claude-plugin/marketplace.json` at v1.0.0 (category `development`, tags: `artifacts`, `diff-review`, `session-recap`, `plan-publishing`).
- Wrote `tests/plugins/test-artifact-tools.sh` validating plugin structure, skill frontmatter, the bundled extractor, marketplace registration, and scrub-gate and fallback documentation.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest — name, description, keywords, homepage; no version key | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation — overview, features, installation, usage, structure | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release history — v1.0.0 initial entry | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Skill instructions — annotated diff walkthrough with scrub gate and fallback | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Skill instructions — session recap artifact with reviewer-first ordering | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor — standalone copy independent of social-media-tools | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Skill instructions — publish and republish plan HTML, stable URLs via artifact-url: | Created |
| `.claude-plugin/marketplace.json` | Marketplace manifest — artifact-tools registered at v1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test — validates manifest, skills, extractor, registration | Created |

## How it works

All three skills share one architectural decision: every published artifact writes its returned URL into the source file's frontmatter as `artifact-url:`. Without this, a new session mints a new page — teammates lose the link and the artifact gallery fragments. With it, republishing always hits the same URL as long as the spec file is committed alongside the published content.

`diff-artifact` is the only skill in the kit that generates content not already handled elsewhere. It resolves the diff source flexibly: branch vs default by default, a commit range as a two-SHA argument, or a PR number routed through `gh pr diff <n>` with a graceful fallback to branch mode when `gh` or the GitHub remote is unavailable. Before building the HTML page, it runs `social-media-tools:security-scrub` as a blocking gate — a diff published to `claude.ai` is external sharing, so the scrub is not advisory. The output page is self-contained: a sticky changed-files sidebar with add/del counts, per-hunk annotations, severity coding that pairs each color with a text label (critical / warn / note) plus a legend, and adaptive `prefers-color-scheme` palettes. Files beyond the per-file annotation budget render as one-line summary rows to stay under the 16 MiB artifact cap.

`session-artifact` avoids reading the raw JSONL into context — a transcript is far larger than the recap it produces. Instead it calls the bundled `artifact-export-session` bin wrapper, which skips tool results, sidechains, and system reminders, and writes a dated `.md` with frontmatter. The skill then rewrites that extraction into reviewer-first order: Summary leads (outcome first), Decisions follow (each with its rationale — a decision without why is unreviewable), then Learnings (approaches tried and abandoned, gotchas discovered), and finally Files touched. The recap is scrubbed before publish. The `.md` is the committed record that holds `artifact-url:`; the HTML is the render that carries the `<title>`.

`plan-artifact` is a thin publish wrapper because `plan-agent` already produces self-contained, CSP-compliant HTML. The skill reads `artifact-url:` from the sibling `.md` spec's frontmatter and passes it to the `Artifact` tool's `url` parameter when present, so republishing hits the same page. A first publish writes the new URL back into the spec's frontmatter. The skill warns never to hand-edit the plan HTML — `plan-agent`'s markdown-first rule means the `.md` spec is always the source of truth.

The bundled `export_session.py` is an intentional copy rather than a dependency on `social-media-tools`. The plan notes this trade-off explicitly: a small duplicate buys zero cross-plugin coupling — `artifact-tools` installs and works standalone regardless of install order.

The smoke test at `tests/plugins/test-artifact-tools.sh` follows the `test-save-artifact.sh` pattern: it asserts structural properties (valid JSON, no version key in plugin.json, required frontmatter in each SKILL.md, bundled extractor present, marketplace entry at 1.0.0) and documentation properties (scrub gate and fallback documented in diff and session skills). It exits non-zero if any assertion fails.

## How to use it

**Install the plugin:**

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install artifact-tools@agentics-kit
```

**Publish an annotated diff:**

```
/artifact-tools:diff-artifact
/artifact-tools:diff-artifact main..my-branch
/artifact-tools:diff-artifact 123   # PR number
```

**Publish a session recap:**

```
/artifact-tools:session-artifact
/artifact-tools:session-artifact ~/.claude/projects/my-project/session-id.jsonl
```

**Publish or republish a plan:**

```
/artifact-tools:plan-artifact docs/plans/my-feature.html
```

The first call writes `artifact-url:` into the sibling `.md` spec. Subsequent calls on the same spec republish to the same URL.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `710593d` | 2026-08-08 | feat(artifact-tools): add teach-artifact, the skill that teaches instead of recaps (#536) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
- Related docs: `kit/plugins/artifact-tools/README.md`, `kit/plugins/artifact-tools/CHANGELOG.md`
- Issue: https://github.com/shawn-sandy/agentics/issues/392
