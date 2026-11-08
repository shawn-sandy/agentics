# Let create-issue ingest plans and offer issue creation at plan completion

> Adds a `plan` source to `git-agent:create-issue` so a plan file can be turned into a GitHub/GitLab issue, and extends `implementation-plan` Step 8 to offer issue creation when a plan completes.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added the `plan` source keyword to `kit/plugins/git-agent/skills/create-issue/SKILL.md`: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and a mapping of plan sections to issue fields (plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in body).
- Created `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton and label mapping.
- Extended `implementation-plan` Step 8 with a batched second `AskUserQuestion` — "Create a tracking issue for this plan?" — that invokes `git-agent:create-issue plan <spec path>` on yes, records the returned URL as the spec's `issue:` frontmatter key, and re-renders; degrades gracefully with a one-line notice when git-agent is not installed.
- Bumped git-agent to 3.12.0 and plan-agent to 2.22.0 in `.claude-plugin/marketplace.json`; added CHANGELOG entries to both plugins; updated README and CLAUDE.md plugin-table mentions.
- Added `tests/plugins/test-create-issue-plan-source.sh` asserting the two skills are wired together and both versions are bumped.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword, per-source mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Objective-verification smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 batched tracking-issue question and handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 3.12.0, plan-agent 2.22.0 | Modified |
| `CLAUDE.md` | Plugin table rows for both plugins | Modified |

## How it works

Before this change, `implementation-plan` could ingest an issue (Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key), but the reverse path did not exist. A drafted plan could not become a tracked ticket without hand-writing one.

The `create-issue` skill in `kit/plugins/git-agent/skills/create-issue/SKILL.md` already supported four sources (bug, feature, selection, session) and routed each through a dedicated template under `references/`. The `plan` source follows the same routing: a `.md` or `.html` token in the argument is enough to imply the source, so the user can type `/git-agent:create-issue docs/plans/my-feature.md` without the `plan` keyword.

The body skeleton in `references/plan-issue.md` maps the structured plan sections into the issue shape: the plan's Objective becomes the issue Summary, the Steps list becomes a `- [ ]` checklist, and Acceptance Criteria carry over verbatim. The `type:` frontmatter field suggests a label; the plan path is cited at the bottom so the issue can be traced back to its source.

In `implementation-plan`, the Step 8 next-action menu already sits at the `AskUserQuestion` four-option maximum. The tracking-issue question therefore rides as a second batched question: after the user picks their implementation path, they are asked whether to create a tracking issue. On yes, the skill invokes `git-agent:create-issue plan <spec path>`, records the returned URL as `issue:` in the spec's frontmatter, and re-renders. A missing git-agent plugin degrades to a one-line notice; the plan flow is never blocked.

The same `issue:` frontmatter key carries the link in both directions: an issue that seeded a plan records its own URL in the spec's `issue:` key (Step 0.5), and a plan that birthed an issue records the resulting issue URL in the same key.

## How to use it

```
/git-agent:create-issue plan docs/plans/add-dark-mode.md   # explicit source keyword
/git-agent:create-issue docs/plans/add-dark-mode.md        # .md token implies plan source
/git-agent:create-issue docs/plans/add-dark-mode.html      # .html token also works
```

The tracking-issue question appears automatically at the end of every `/plan-agent:implementation-plan` run via the Step 8 batched question.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
- Changelog: `kit/plugins/git-agent/CHANGELOG.md` — v3.12.0 entry; `kit/plugins/plan-agent/CHANGELOG.md` — v2.22.0 entry
