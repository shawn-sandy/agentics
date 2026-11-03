# Let create-issue Ingest Plans and Offer Issue Creation at Plan Completion

> Plans and issues only linked in one direction — an issue could seed a plan, but a finished plan could not become a tracked ticket. Now create-issue accepts a plan file as a source and implementation-plan offers issue creation at the end of every plan run.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source keyword to the git-agent `create-issue` skill, with automatic inference from `.md`/`.html` file tokens, mapping plan sections (title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over) and routing through a new `references/plan-issue.md` body skeleton.
- Created `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body template and `type:` frontmatter → label mapping, filling the gap left by four existing source templates that cover none of the plan-shaped body format.
- Extended `implementation-plan` Step 8 with a batched "Create a tracking issue?" question that invokes `git-agent:create-issue plan <spec path>` on yes, records the returned URL as the spec's `issue:` frontmatter key, and re-renders; gracefully degrades with a one-line notice when git-agent is not installed.
- Bumped git-agent to 3.12.0 and plan-agent to 2.22.0, added CHANGELOG entries to both, and updated the README and CLAUDE.md plugin-table mentions.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill — `plan` source keyword, path inference, per-source mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Template — plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test — wiring and version check | Created |
| `kit/plugins/git-agent/README.md` | Plugin docs — plan source with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Authoring skill — Step 8 batched tracking-issue question | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent 3.12.0, plan-agent 2.22.0 | Modified |
| `CLAUDE.md` | Repo docs — plugin table rows for both plugins | Modified |

## How it works

`implementation-plan` already supported issue-to-plan ingestion: Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key. The `issue:` key therefore already carries a bidirectional meaning — it was simply never written from the plan side.

The `create-issue` skill's Phase 3 (source parsing) was extended to recognize a `plan` keyword alongside the existing four: bug, feature, selection, and session. A `.md` or `.html` file token implies the plan source automatically so users can type `/git-agent:create-issue docs/plans/my-plan.md` without spelling out `plan`. Phase 5 (template selection) routes `plan` inputs to the new `references/plan-issue.md` template. The mapping is explicit in the skill so drafts are deterministic: plan title → issue title, Objective → Summary section, numbered Steps → `- [ ]` checklist, Acceptance Criteria carried verbatim, `type:` frontmatter mapped to a label hint, and the plan path cited in the body.

`implementation-plan` Step 8 already used `AskUserQuestion` at its four-option maximum, so the tracking-issue choice rides as a second batched question alongside the existing ones. On a yes answer, the skill invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, writes the returned issue URL as the `issue:` frontmatter key, and re-renders the plan HTML. If git-agent is not installed, the skill prints a one-line notice and continues — a cross-plugin dependency must never block the plan flow.

The smoke test `test-create-issue-plan-source.sh` asserts: the `plan` source keyword is documented in create-issue SKILL.md and routes to `references/plan-issue.md` (which exists); implementation-plan SKILL.md invokes `git-agent:create-issue` with a `plan` argument in Step 8; and marketplace.json reports both bumped versions. This is a Tier 2 test (skill markdown and templates only, no application source files change).

## How to use it

From any plan completion, answer yes when Step 8 asks "Create a tracking issue?". The issue is drafted from the plan's content and the confirmation gate appears before any `gh`/`glab` call.

To invoke directly:

```bash
/git-agent:create-issue plan docs/plans/<slug>.md
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
