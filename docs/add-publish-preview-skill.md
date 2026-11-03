# Give a work-in-progress plan a public link before the pull request merges

> Adds a `publish-preview` skill to plan-agent that pushes the current plan to `docs/previews/<slug>.html` on `main` via the GitHub Contents API, giving it a live `github.io` URL before the pull request merges.

<!-- generated:start -->

**Status:** Not shipped (plan status: todo) **Plan:** [add-publish-preview-skill.md](plans/add-publish-preview-skill.md)
**Type:** feature

## What shipped

This plan was not completed. As of the plan file's last modification (2026-07-31) the status field reads `todo` and none of the implementation files exist in the repository:

- `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` — **missing**
- `tests/plugins/test-publish-preview.sh` — **missing**

The plan's acceptance criteria remain unchecked. No version bump was applied for this feature.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` | Skill — preflight, resolve, confirm, publish, verify, report, `--unpublish` | Missing |
| `kit/plugins/plan-agent/README.md` | Component table row and reference section | Not yet modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.3.0 entry | Not yet modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.2.0 → 7.3.0 | Not yet modified |
| `README.md` | Regenerated plugin reference table | Not yet modified |
| `tests/plugins/test-publish-preview.sh` | Structural smoke test | Missing |

## How it works

The design specified in the plan (not yet implemented):

Plans published through `implementation-plan` get a claude.ai artifact link, but GitHub Pages only deploys from `main`, so a plan on a feature branch has no public `github.io` URL until the pull request merges. The skill fills this gap using the GitHub Contents API (`gh api -X PUT`) to write the rendered plan HTML to `docs/previews/<slug>.html` on `main` directly, triggering the existing `deploy-pages.yml` workflow.

The preview path is outside `docs/plans/` by design: the gallery builder (`build-index.sh`) walks only the plans directory, so a preview file never generates a duplicate gallery card. Publishing to `main` outside the pull-request flow skips review and CI, so the skill asks for confirmation on every run and writes only under `docs/previews/`.

The skill preflight confirms GitHub Pages is enabled (`gh api repos/{owner}/{repo}/pages`) and stops with a referral to `plan-agent:setup-sites` if it is not. A `sha` precondition on the PUT prevents two concurrent sessions from clobbering each other. After writing, the skill polls the deployed URL for the plan title. `--unpublish` issues a `gh api -X DELETE` using the blob `sha`; the skill offers this automatically when the resolved plan's `status:` reads `completed`.

## How to use it

Not yet available. Once shipped the invocation will be:

```bash
/plan-agent:publish-preview                     # pick from plans directory
/plan-agent:publish-preview docs/plans/<slug>.md
/plan-agent:publish-preview --unpublish docs/plans/<slug>.md
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-publish-preview-skill.md](plans/add-publish-preview-skill.md)
- `kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md` — the claude.ai counterpart and the 403/409 fallback the skill would reference
- `.github/workflows/deploy-pages.yml` — the Pages workflow this skill relies on
