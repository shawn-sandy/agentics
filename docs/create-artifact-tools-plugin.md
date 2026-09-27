# Create the artifact-tools plugin

> Publish branch diffs, session recaps, and implementation plans as live claude.ai artifact pages — with a blocking secret-scrub gate, local-HTML fallback, and stable URLs across sessions.

<!-- generated:start -->

**Status:** Shipped 2026-07-14 **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created the `artifact-tools` plugin at `kit/plugins/artifact-tools/` with plugin manifest, README, and CHANGELOG
- Added `diff-artifact` skill — produces an annotated diff walkthrough as a self-contained HTML artifact with a sticky changed-files sidebar, per-hunk reviewer notes, severity coding, and adaptive light/dark theme
- Added `session-artifact` skill — extracts transcript turns into a Summary, Decisions, and Learnings recap and publishes it as a claude.ai artifact
- Added `plan-artifact` skill — publishes an existing plan HTML file and republishes to the same URL across sessions by reading `artifact-url:` from the spec frontmatter
- Bundled `export_session.py` alongside `session-artifact` so the plugin requires no cross-plugin install-order dependency on `social-media-tools`
- Wired every skill through a blocking `security-scrub` gate before any publish; added a local-HTML fallback for Pro-plan sessions where sharing is unavailable
- Registered `artifact-tools` at version 1.0.0 in `.claude-plugin/marketplace.json`
- Added `tests/plugins/test-artifact-tools.sh` structural smoke test

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/artifact-tools/README.md` | Plugin overview and usage | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Version history | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Annotated diff artifact skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap artifact skill | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Plan publish skill | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration at 1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |

## How it works

Claude Code artifacts are self-contained pages published to a private `claude.ai` URL that update in place on republish. They carry hard CSP constraints — no external requests, everything inlined — a 16 MiB rendered-size cap, and single-page only. Publishing requires a claude.ai Pro or higher login; sharing beyond the author requires Team/Enterprise, so the local-HTML fallback is not an edge case.

The central URL-stability mechanic: updating an artifact from a later session requires its URL. Each skill writes the returned URL into the source file's frontmatter as `artifact-url:` (or a skill-specific variant) so any future session can republish to the same link rather than minting a new page.

`diff-artifact` resolves the diff source — current branch versus the default branch, a commit range argument, or a PR number via `gh pr diff` — then scrubs it, builds one HTML page with a sticky changed-files sidebar and per-hunk annotations, and publishes. Files beyond the annotation budget render as one-line summary rows to stay under the 16 MiB cap. On publish failure it keeps the local HTML and offers `social-media-tools:save-artifact`.

`session-artifact` locates the session transcript (explicit path or session ID, or the newest project transcript), runs the bundled `export_session.py` to extract turns, writes a reviewer-first recap (Summary, Decisions, Learnings, Files touched), scrubs it, and publishes. The script is bundled beside the skill rather than imported from `social-media-tools` to eliminate any install-order dependency.

`plan-artifact` is a thin publish wrapper. It reads `artifact-url:` from the sibling plan spec's frontmatter and passes it to the `Artifact` tool's `url` parameter when present, republishing to the same page. On a first publish it writes the new URL back into the spec. The skill never modifies the plan HTML itself — plan-agent's markdown-first rule stays intact.

Every skill runs `social-media-tools:security-scrub` as a blocking gate before any publish. A SCRUB RESULT with findings stops the skill hard; there is no override path. This ensures that sharing via a claude.ai URL — which is external distribution — cannot happen without a secret check.

The plugin manifest has no `version` key. For relative-path plugins the version lives only in `.claude-plugin/marketplace.json`; a version in `plugin.json` would silently override it.

## How to use it

```bash
# Load the plugin locally
claude --plugin-dir ./kit/plugins/artifact-tools

# Publish a diff
/artifact-tools:diff-artifact

# Publish a session recap
/artifact-tools:session-artifact

# Publish or republish a plan
/artifact-tools:plan-artifact docs/plans/my-plan.html
```

Install from the marketplace:

```text
/plugin install artifact-tools@agentics-kit
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
