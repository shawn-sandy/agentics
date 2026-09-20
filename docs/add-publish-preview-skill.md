# Give a work-in-progress plan a public link before the pull request merges

> A plan living on an open branch is invisible to everyone outside Claude, because GitHub Pages only publishes from the main branch — so stakeholders wait for...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-publish-preview-skill.md](plans/add-publish-preview-skill.md)
**Type:** feature

## What shipped

- Author `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` with `name`, a description under 200 characters, and...
- Write the skill body as six steps — preflight (GitHub `origin`, `gh auth status`, and `gh api repos/{owner}/{repo}/pa...
- Add the `--unpublish` path to the same file — a `gh api -X DELETE` with the blob `sha`, offered automatically when th...
- Document the skill in `kit/plugins/plan-agent/README.md` — one row in the component table and one section matching th...
- Bump `plan-agent` from 7.2.0 to 7.3.0 in `.claude-plugin/marketplace.json`, add a matching 7.3.0 entry to `kit/plugin...
- Add `tests/plugins/test-publish-preview.sh`, modelled on `tests/plugins/test-setup-sites.sh`, asserting the skill fil...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` | the skill: preflight, resolve, confirm, publish, verify, ... | Created |
| `kit/plugins/plan-agent/README.md` | component table row and reference section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.3.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.2.0 to 7.3.0 | Modified |
| `README.md` | regenerated plugin reference table | Modified |
| `tests/plugins/test-publish-preview.sh` | structural smoke test | Created |

## How it works

Ship `plan-agent:publish-preview` — a skill that pushes the plan you are currently working on to a preview path on the `main` branch through the GitHub Contents API, so anyone holding the link watches the plan progress at `https://<owner>.github.io/<repo>/previews/<slug>.html` — or at `https://<owner>.github.io/previews/<slug>.html` in a root Pages repository named `<owner>.github.io` — while the .

Two publishing routes already exist in this repo and neither covers mid-work sharing to a public site. `artifact-tools:plan-artifact` records an `artifact-url:` in the plan spec and republishes the same claude.ai page across sessions, which is the right tool whenever a claude.ai link is acceptable. `plan-agent:setup-sites` scaffolds GitHub Pages so everything under `docs/` deploys, and `.github/workflows/deploy-pages.yml` publishes on every push to `main` touching `docs/**`. The gap sits between...

The implementation proceeded through these steps: Author `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` with `name`, a description under 200 characters, and ...; Write the skill body as six steps — preflight (GitHub `origin`, `gh auth status`, and `gh api repos/{owner}/{repo}/pa...; Add the `--unpublish` path to the same file — a `gh api -X DELETE` with the blob `sha`, offered automatically when th...; Document the skill in `kit/plugins/plan-agent/README.md` — one row in the component table and one section matching th...; Bump `plan-agent` from 7.2.0 to 7.3.0 in `.claude-plugin/marketplace.json`, add a matching 7.3.0 entry to `kit/plugin....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-publish-preview-skill.md](plans/add-publish-preview-skill.md)
