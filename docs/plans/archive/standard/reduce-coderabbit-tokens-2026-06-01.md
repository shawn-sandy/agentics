# Reduce CodeRabbit Token Consumption

## Context

CodeRabbit is consuming excessive tokens reviewing PRs. The repo is ~90% Markdown and JSON plugin metadata — not application code — yet CodeRabbit generates verbose reviews with full walkthroughs, summaries, and status tracking on every PR, including ephemeral `claude/*` session branches.

## Changes to `.coderabbit.yaml`

### 1. Collapse walkthrough (biggest per-review win)

`collapse_walkthrough: false` → `true`

Hides the file-by-file description table behind a `<details>` toggle. Still accessible but not generated inline.

### 2. Disable high-level summary

`high_level_summary: true` → `false`

The summary paragraph restates what the PR title already says. Redundant for a plugin metadata repo.

### 3. Disable review status

`review_status: true` → `false`

The progress-tracking section adds boilerplate to every review with no actionable value here.

### 4. Narrow auto-review to main only

Remove `feat/*`, `fix/*`, and `claude/*` from `base_branches`. Only auto-review PRs targeting `main`. Intermediate branches can get ad-hoc reviews via `@coderabbitai review`.

### 5. Add path filters for docs and non-reviewable files

Exclude plan docs, changelogs, media, generated HTML, images, and reference docs:

```yaml
path_filters:
  - "!**/*.lock"
  - "!**/node_modules/**"
  - "!**/.git/**"
  - "!docs/plans/**"
  - "!docs/media/**"
  - "!**/*.png"
  - "!**/*.html"
  - "!**/CHANGELOG.md"
  - "!kit/plugins/**/references/**"
```

Plugin SKILL.md, README.md, and command files under `kit/plugins/` remain reviewable.

### 6. Remove `docs/plans/**` path instruction

Since plan files are now excluded by path filters, this instruction will never fire. Remove it.

### 7. Narrow the `kit/plugins/**` path instruction

The broad `kit/plugins/**` glob matches all 215 files across 18 plugins. Split it into targeted entries:

- `kit/plugins/**/skills/**/SKILL.md` — check for `allowed-tools:` frontmatter
- Merge the CHANGELOG check into the existing `plugin.json` instruction

### 8. Set knowledge base scope to local

`scope: auto` → `scope: local` for both `learnings` and `issues`. Prevents cross-repo context accumulation.

## Final `.coderabbit.yaml`

```yaml
# yaml-language-server: $schema=https://coderabbit.ai/integrations/schema.v2.json
# CodeRabbit configuration for shawn-sandy/agentics
# Marketplace system for Claude Code plugins
# https://docs.coderabbit.ai/guides/configure-coderabbit

language: "en-US"

reviews:
  profile: "chill"
  request_changes_workflow: false
  high_level_summary: false
  poem: false
  review_status: false
  collapse_walkthrough: true

  auto_review:
    enabled: true
    drafts: false
    base_branches:
      - "^main$"

  path_filters:
    - "!**/*.lock"
    - "!**/node_modules/**"
    - "!**/.git/**"
    - "!docs/plans/**"
    - "!docs/media/**"
    - "!**/*.png"
    - "!**/*.html"
    - "!**/CHANGELOG.md"
    - "!kit/plugins/**/references/**"

  path_instructions:
    - path: ".claude-plugin/marketplace.json"
      instructions: |
        Flag if: `version` appears in a plugin.json instead of here, or `source.path` doesn't match an actual `kit/plugins/` directory.

    - path: "kit/plugins/**/.claude-plugin/plugin.json"
      instructions: |
        Flag if: `version` is set here (must be in marketplace.json only), or `homepage` doesn't point to the plugin's own directory. Also flag if the parent plugin directory is missing a CHANGELOG.md.

    - path: "kit/plugins/**/skills/**/SKILL.md"
      instructions: |
        Flag if: the SKILL.md file lacks an `allowed-tools:` frontmatter line.

    - path: "tests/**"
      instructions: |
        Flag if: `tests/fixtures/valid-plugin/` diverges from current plugin structure conventions.

  tools:
    markdownlint:
      enabled: false
    yamllint:
      enabled: false

  finishing_touches:
    docstrings:
      enabled: false

chat:
  auto_reply: false

knowledge_base:
  opt_out: false
  learnings:
    scope: local
  issues:
    scope: local
```

## File to modify

- `.coderabbit.yaml` (repo root) — replace contents with the config above

## Verification

1. Commit and push the updated `.coderabbit.yaml`
2. Open a test PR targeting `main` with a mix of plugin and docs changes
3. Confirm: no walkthrough table, no summary paragraph, no status section
4. Confirm: plan docs and changelogs get no review comments
5. Confirm: PRs targeting `claude/*` branches are not auto-reviewed
