# Let create-issue ingest plans and offer issue creation at plan completion

> Adds a `plan` source to `git-agent:create-issue` and an optional tracking-issue question to `implementation-plan` Step 8, closing the plan ↔ issue loop in both directions.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source to `create-issue/SKILL.md`: keyword parsing (a `.md` or `.html` token implies the source), resolution under the plans directory, and a per-source mapping (plan title → issue title; Objective → Summary; Steps → `- [ ]` checklist; Acceptance Criteria carried over; `type:` frontmatter → label hint; plan path cited in the body).
- Created `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton and `type:` → label mapping.
- Extended `implementation-plan` Step 8 with a batched second `AskUserQuestion`: "Create a tracking issue for this plan?" On yes, invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` and records the returned URL as `issue:` frontmatter; if git-agent is not installed, notes it and continues without blocking.
- Updated `git-agent` README with a plan source example; added CHANGELOG entries to both plugins.
- Bumped git-agent to **3.12.0** and plan-agent to **2.22.0** in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-create-issue-plan-source.sh` with checks asserting both skills are wired and versioned correctly.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill — `plan` source, keyword parsing, mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Template — plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test — wiring and version assertions | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history — v3.12.0 | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — Step 8 batched tracking-issue question | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history — 2.22.0 | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — both bumps | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

`create-issue` already supported four sources (bug, feature, selection, session) and routed each through its own template. The `plan` source was added as a fifth: a `.md` or `.html` token in the argument string implies `plan` without needing the keyword explicitly. Phase 3 of the skill's workflow maps plan sections into issue content: the plan title becomes the issue title, the Objective section becomes the body's Summary, the Steps list becomes a `- [ ]` checklist, and Acceptance Criteria are carried over verbatim. The `type:` frontmatter field hints at the GitHub/GitLab label. Phase 5 routes the `plan` source to `references/plan-issue.md` for template-driven body assembly.

`implementation-plan` Step 8 already carried up to four `AskUserQuestion` choices for what to do after a plan is authored. A batched second question ("Create a tracking issue for this plan?") was added as a separate prompt so the main Step 8 menu stays within the four-option limit. On a yes, the skill invokes `git-agent:create-issue` via `Skill()`, passing the spec path as the argument. The returned issue URL is written back into the spec's `issue:` frontmatter key and the spec is re-rendered — the same key that `implementation-plan` reads when ingesting an issue URL at Step 0.5, closing the bidirectional loop.

The integration is defensive: if git-agent is not installed, the skill prints a one-line notice and continues. The plan flow is never blocked by a missing cross-plugin dependency.

## How to use it

**Create an issue from a plan:**
```
/git-agent:create-issue plan docs/plans/add-dark-mode.md
/git-agent:create-issue docs/plans/add-dark-mode.md   # .md token infers the source
```

**After authoring a plan with `implementation-plan`**, Step 8 asks:
> "Create a tracking issue for this plan?"
Answering yes invokes `create-issue plan <spec path>` and records the URL as `issue:` in the frontmatter.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `417a9579` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `43a7fd92` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
