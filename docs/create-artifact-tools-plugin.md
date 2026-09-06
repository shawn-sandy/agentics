# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships the `artifact-tools` plugin with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages with a scrub gate and a local-HTML fallback. _(Initial v1.0.0 release; the current plugin has five skills.)_

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Scaffolded `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (name, description, author, license, keywords, homepage pointing at the plugin directory, no `version` key), `README.md`, and `CHANGELOG.md` (1.0.0 entry).
- Authored `skills/diff-artifact/SKILL.md`: resolves the diff source (current branch vs default branch; commit range argument; or PR number via `gh pr diff <n>` with degradation to branch mode when `gh` or GitHub remote is missing), runs `social-media-tools:security-scrub` as a blocking hard-stop gate, builds one self-contained annotated-diff HTML page (sticky changed-files sidebar with add/del counts, per-hunk margin annotations, severity coding with text labels and legend, adaptive light/dark palettes, cap-and-summarize policy for the 16 MiB artifact cap), publishes via the `Artifact` tool, saves locally with the returned URL as `artifact-url:`, and on publish failure keeps local HTML and offers `social-media-tools:save-artifact`.
- Authored `skills/session-artifact/SKILL.md` plus a bundled `skills/session-artifact/scripts/export_session.py` (copied from social-media-tools so the plugin works standalone with no install-order dependency): locates the session transcript via JSONL lookup conventions, writes the recap in reviewer-first order (Summary, Decisions with rationale, Learnings, Files touched), scrubs it, saves under `{plansDirectory}/sessions/` with `artifact-url:` frontmatter, and publishes the `.md` directly as an artifact _(HTML publish was added in a later patch; see fix-artifact-title-mechanism)_.
- Authored `skills/plan-artifact/SKILL.md`: accepts a plan `.html` path, reads `artifact-url:` from the sibling `.md` spec's frontmatter and passes it to the `Artifact` tool's `url` parameter when present (republishing to the same page), otherwise publishes fresh and writes the new URL back into the spec frontmatter.
- Registered `artifact-tools` in `.claude-plugin/marketplace.json` at version 1.0.0 (source `git-subdir`, category `development`, tags: `artifacts`, `diff-review`, `session-recap`, `plan-publishing`) with a matching 1.0.0 CHANGELOG entry.
- Wrote `tests/plugins/test-artifact-tools.sh`: asserts `plugin.json` is valid JSON without a `version` key, all three SKILL.md files exist with required frontmatter, the bundled `export_session.py` exists, the marketplace entry is at 1.0.0, and the diff and session skill bodies contain the scrub gate, cap-and-summarize, and fallback wording.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest; no version key | Created |
| `kit/plugins/artifact-tools/README.md` | Overview, features, installation, usage, structure | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Annotated diff walkthrough artifact skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap artifact skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor (copied from social-media-tools) | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan HTML publish and republish skill | Created |
| `.claude-plugin/marketplace.json` | artifact-tools registered at 1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |

## How it works

The design is anchored in two hard constraints from the claude.ai artifacts platform: a strict Content Security Policy (no external requests — everything must be inlined), and a 16 MiB rendered-size cap. Every generated page must be self-contained, and large diffs must be handled with a cap-and-summarize policy rather than inline embedding.

The one mechanic that drives cross-session continuity is the `artifact-url:` frontmatter key. Updating an artifact from a later session requires its URL — without it, a new session mints a new page. Each skill writes the returned URL into the source file's frontmatter so any future session can republish to the same link. For `plan-artifact`, the URL goes into the sibling `.md` spec's frontmatter; for `session-artifact`, it goes into the saved session file under `{plansDirectory}/sessions/`.

`diff-artifact` is the only skill that generates genuinely new content. It resolves the diff source, builds a structured HTML walkthrough with a sticky sidebar, per-hunk annotations, and severity labels paired with text so the legend is accessible without color alone, then publishes. The scrub gate from `social-media-tools:security-scrub` is blocking — a publish is external sharing, and findings halt execution with no override. The cap-and-summarize policy keeps pages under the 16 MiB cap by rendering files beyond the per-file annotation budget as one-line summary rows rather than full diffs.

`session-artifact` bundles its own `export_session.py` rather than depending on `social-media-tools:export-session`. This trades a small duplication for zero cross-plugin coupling — a user who installs only `artifact-tools` gets a fully working skill without needing to install `social-media-tools` first or in any particular order. The recap format is reviewer-first: Summary, then Decisions with rationale, then Learnings (approaches tried and abandoned, gotchas discovered), then Files touched. Publishing the `.md` directly as an artifact costs the fewest tokens because Markdown renders as styled HTML at the artifact runtime.

`plan-artifact` is a thin publish wrapper. Plan HTML from `plan-agent` is already self-contained and CSP-compliant, so the skill's entire value is stable URLs across sessions. First publish writes `artifact-url:` into the spec's frontmatter; any later session reads it and passes it to the `Artifact` tool's `url` parameter so republishing hits the same page.

## How to use it

```bash
# Load the plugin locally
claude --plugin-dir ./kit/plugins/artifact-tools

# Install from the marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install artifact-tools@agentics-kit
```

**Publish an annotated diff:**

```
diff-artifact                    # current branch vs default
diff-artifact --pr 42            # pull request #42
diff-artifact main..feature-x    # commit range
```

**Publish a session recap:**

```
session-artifact                 # newest transcript for this project
session-artifact <session-id>    # specific session
```

**Publish a plan page:**

```
plan-artifact docs/plans/my-plan.html    # first publish writes artifact-url:
plan-artifact docs/plans/my-plan.html    # second publish republishes to same URL
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| _(feature commit not isolated in available git log scope)_ | | |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
