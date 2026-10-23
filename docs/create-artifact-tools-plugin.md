# Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

> Ships a new `artifact-tools` plugin with skills that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages, with a blocking secret-scrub gate and a local-HTML fallback.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
**Type:** feature

## What shipped

- Created the `kit/plugins/artifact-tools/` plugin directory with a manifest (`plugin.json`, no `version` key), `README.md`, and `CHANGELOG.md`.
- Added the `diff-artifact` skill: resolves a diff from branch, commit range, or PR number; runs a blocking `security-scrub` gate; builds one self-contained annotated-diff HTML page with a sticky file sidebar, per-hunk margin annotations, severity coding, adaptive light/dark themes, and a cap-and-summarize policy to stay under the 16 MiB artifact limit; publishes via `Artifact` and records the returned URL as `artifact-url:` in the source frontmatter; falls back to local HTML when publishing is unavailable.
- Added the `session-artifact` skill: locates the session transcript, extracts turns with a bundled `export_session.py` script (no cross-plugin dependency), produces a reviewer-first recap (Summary, Decisions, Learnings, Files), scrubs it, saves it under `{plansDirectory}/sessions/`, and publishes an HTML rendering.
- Added the `plan-artifact` skill: accepts an existing plan HTML path, reads `artifact-url:` from the sibling `.md` frontmatter to republish to the same URL across sessions, and writes the URL back on a first publish.
- Registered `artifact-tools` in `.claude-plugin/marketplace.json` at version 1.0.0.
- Added `tests/plugins/test-artifact-tools.sh` asserting manifest validity, skill structure, marketplace registration, and the scrub-gate and fallback requirements in the diff and session skills.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/.claude-plugin/plugin.json` | Plugin manifest — no `version` key | Created |
| `kit/plugins/artifact-tools/README.md` | Overview, features, installation, usage | Created |
| `kit/plugins/artifact-tools/CHANGELOG.md` | 1.0.0 entry | Created |
| `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` | Annotated diff walkthrough artifact | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/SKILL.md` | Session recap artifact with learnings | Created |
| `kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py` | Bundled transcript extractor | Created |
| `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` | Publish and republish plan HTML | Created |
| `.claude-plugin/marketplace.json` | Register artifact-tools at 1.0.0 | Modified |
| `tests/plugins/test-artifact-tools.sh` | Structural smoke test | Created |

## How it works

The core mechanic is the `artifact-url:` frontmatter key. Claude Code's `Artifact` tool mints a new URL if `file_path` changes between sessions, so the only way to republish to the same link is to pass the original `url` parameter explicitly. Each skill writes the returned URL into its source file's frontmatter on first publish; subsequent sessions read it back and pass it as `url` so viewers always land at the same link.

`diff-artifact` is the one genuinely new generator. It resolves the diff source — current branch vs default, a commit range, or a PR via `gh pr diff <n>` — then builds a self-contained HTML page. The page design follows the Claude artifact CSP constraint (no external requests, everything inlined): the changed-files sidebar with add/del counts, per-hunk margin annotations, and severity coding all use inline CSS. Files beyond the annotation budget are collapsed to one-line summary rows to keep the rendered size under the 16 MiB cap. A blocking `security-scrub` call runs before any publish, because a diff is external sharing.

`session-artifact` bundles its own `export_session.py` script rather than calling `social-media-tools:export-session`, so the plugin works standalone with no install-order dependency. The skill writes the recap `.md` under `{plansDirectory}/sessions/` as the committed record; the HTML is a render that holds the `<title>` the Markdown format cannot provide.

`plan-artifact` is deliberately thin: plan HTML from `plan-agent` is already self-contained and CSP-compliant, so the skill adds only the stable-URL plumbing. It never generates HTML itself.

The smoke test asserts the plugin's structure contracts — manifest valid with no `version` key, three skills present with required frontmatter, marketplace registration at 1.0.0, scrub gate and fallback documented in diff and session skills — so manifest drift and missing frontmatter are caught before a release rather than after an install.

Since shipping at 1.0.0, the plugin has grown to include `prompt-artifact` and `teach-artifact` skills, and the recap workflow was extracted into `references/recap-core.md` shared by three command files (see the `extract-recap-command-core` doc). The plugin reached 1.12.0 by 2026-08-07.

## How to use it

Install via `/plugin install artifact-tools@agentics-kit` or load locally with `claude --plugin-dir ./kit/plugins/artifact-tools`.

| Skill | Activation trigger | What it does |
|-------|--------------------|--------------|
| `diff-artifact` | "publish diff", "artifact from this branch", "diff artifact" | Annotated diff walkthrough for current branch or a PR |
| `session-artifact` | "share session recap", "session artifact", "publish this session" | Reviewer-first recap of the current session |
| `plan-artifact` | "publish plan", "plan artifact", "share this plan" | Publishes plan HTML to a stable URL |

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [create-artifact-tools-plugin.md](plans/create-artifact-tools-plugin.md)
