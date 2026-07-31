---
status: todo
type: feature
created: 2026-07-31
effort: medium
workflow: never
glance: A plan living on an open branch is invisible to everyone outside Claude, because GitHub Pages only publishes from the main branch — so stakeholders wait for the merge before they can watch progress. This adds one skill that pushes the plan you are working on right now to a public preview link, and takes it down once the plan is finished. We will know it worked when a plan on a feature branch answers with HTTP 200 at its preview URL about a minute after publishing.
---

# Plan: Give a work-in-progress plan a public link before the pull request merges

## Objective

Ship `plan-agent:publish-preview` — a skill that pushes the plan you are currently working on to a preview path on the `main` branch through the GitHub Contents API, so anyone holding the link watches the plan progress at `https://<owner>.github.io/<repo>/previews/<slug>.html` — or at `https://<owner>.github.io/previews/<slug>.html` in a root Pages repository named `<owner>.github.io` — while the branch is still open.

## Context

Two publishing routes already exist in this repo and neither covers mid-work sharing to a public site. `artifact-tools:plan-artifact` records an `artifact-url:` in the plan spec and republishes the same claude.ai page across sessions, which is the right tool whenever a claude.ai link is acceptable. `plan-agent:setup-sites` scaffolds GitHub Pages so everything under `docs/` deploys, and `.github/workflows/deploy-pages.yml` publishes on every push to `main` touching `docs/**`. The gap sits between them: Pages only deploys from `main`, so a plan on a feature branch has no public URL until the pull request merges. This skill closes that gap for the case where the audience cannot use a claude.ai link — an external stakeholder, a public roadmap, anyone who needs a plain `github.io` address.

Three decisions shaped the design and are settled, not open. **Previews live at `docs/previews/<slug>.html`, outside the plans directory.** The gallery builder walks only the plans directory — `kit/plugins/plan-agent/hooks/build-index.sh:87-88` is the `os.walk(plans_dir)` call and the exclusion list applied to it — so a preview outside that directory cannot produce a duplicate gallery card and needs no change to that hook; `.github/workflows/regen-plans.yml` filters on `docs/plans/**`, so it never fires either. Publishing to the plan's real path on `main` was rejected outright: the branch and `main` would both carry edited copies of the same generated HTML, guaranteeing a merge conflict on a file nobody should hand-resolve. **Previews stay link-only** — they are not listed in any gallery, because a public index of stale mid-work previews is worse than no index. **The write uses the GitHub Contents API, not a local checkout of `main`** — a `gh api -X PUT` needs no second working copy, survives a dirty working tree, and its `sha` precondition makes two sessions publishing the same plan fail loudly instead of silently clobbering one another.

Known risks, each with its mitigation. Writing to `main` outside the pull-request flow skips review and CI, so the skill asks for confirmation on every single run and every write it makes to `main` lands under `docs/previews/` — never source, never the plan's real path. A repository that never enabled Pages would otherwise take that write and never deploy it, leaving an orphan commit on `main`, so the preflight confirms Pages is on and sends the user to `plan-agent:setup-sites` before anything is written. A repository with branch protection rejects the write, so a 403 or 409 is reported plainly with `artifact-tools:plan-artifact` offered as the fallback rather than being worked around. Previews would otherwise accumulate on `main` forever, so the skill offers to remove one as soon as the plan's `status:` reads `completed`.

## Steps

1. Author `kit/plugins/plan-agent/skills/publish-preview/SKILL.md` with `name`, a description under 200 characters, and `allowed-tools: Bash, Read, Glob, AskUserQuestion, ToolSearch, ExitPlanMode`, carrying the plan-mode guard line verbatim as its first step. Why: the frontmatter is what makes the skill discoverable and keeps the user from being prompted for permission mid-run, and `tests/plugins/test-exitplanmode-guard.sh` greps for that exact guard string in every write-heavy skill. Verify: `grep -c "^name: publish-preview$" kit/plugins/plan-agent/skills/publish-preview/SKILL.md` prints 1 and `bash tests/plugins/test-exitplanmode-guard.sh` exits 0.
2. Write the skill body as six steps — preflight (GitHub `origin`, `gh auth status`, and `gh api repos/{owner}/{repo}/pages` to confirm Pages is enabled, deriving the apex URL for an `<owner>.github.io` repository and the `/<repo>/` prefix for every other repository the way `setup-sites` Step 1 does), resolve the plan HTML by argument or `Glob` plus `AskUserQuestion` and re-render it from the sibling markdown spec, a per-run `AskUserQuestion` confirmation, `gh api` GET for the existing blob `sha` then `PUT` to `docs/previews/<slug>.html` on `main`, a bounded poll of the deployed URL for the plan title, and a report that names the URL and calls it a preview on `main`. Why: each step closes a specific failure — an unrendered spec publishes a stale page, a missing `sha` clobbers a concurrent publish, a 201 from the API is not evidence the page rendered, a hardcoded `/<repo>/` segment 404s on a root Pages repository, and publishing into a repository where Pages was never enabled strands an undeployable commit on `main` that the poll can only time out on. Verify: `grep -c "gh api" kit/plugins/plan-agent/skills/publish-preview/SKILL.md` returns at least 4, the body names `docs/previews/`, `--unpublish`, and `artifact-tools:plan-artifact` as the 403/409 fallback, and it directs the user to `plan-agent:setup-sites` and stops before any write when the Pages check returns 404.
3. Add the `--unpublish` path to the same file — a `gh api -X DELETE` with the blob `sha`, offered automatically when the resolved plan's spec frontmatter reads `status: completed`. Why: without a removal path every preview ever published stays on `main` indefinitely, and the moment a plan completes is the one moment the skill can reliably tell that its preview is obsolete. Verify: the body documents both the manual `--unpublish` invocation and the automatic offer, and states that removal is confirmed like any other write.
4. Document the skill in `kit/plugins/plan-agent/README.md` — one row in the component table and one section matching the shape of the existing `setup-sites` section. Why: the plugin README is the reference a user reads before installing, and an undocumented skill is one nobody finds. Verify: `grep -c "publish-preview" kit/plugins/plan-agent/README.md` returns at least 2.
5. Bump `plan-agent` from 7.2.0 to 7.3.0 in `.claude-plugin/marketplace.json`, add a matching 7.3.0 entry to `kit/plugins/plan-agent/CHANGELOG.md`, then regenerate the root README table with `node scripts/build-readme-table.mjs`. Why: a new skill is a minor bump under this repo's semver rule, the CI version guard fails the pull request without it, and the root table is generated output that must never be hand-edited. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `git diff --stat README.md` shows the regenerated table rather than a manual edit.
6. Add `tests/plugins/test-publish-preview.sh`, modelled on `tests/plugins/test-setup-sites.sh`, asserting the skill file exists with correct frontmatter, that the body names `docs/previews/` and never writes to `docs/plans/`, that the confirmation and `--unpublish` paths are documented, and that the marketplace version is above the value on `main`. Why: every structural claim this plan makes about the skill should fail a test if a later edit breaks it, and the repo's convention is a shell smoke test per skill. Verify: `bash tests/plugins/test-publish-preview.sh` exits 0, and it exits non-zero when the string `docs/previews/` is temporarily removed from the skill body.

## Files

- kit/plugins/plan-agent/skills/publish-preview/SKILL.md (new) — the skill: preflight, resolve, confirm, publish, verify, report, plus `--unpublish`
- kit/plugins/plan-agent/README.md (modified) — component table row and reference section
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 7.3.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent 7.2.0 to 7.3.0
- README.md (generated) — regenerated plugin reference table
- tests/plugins/test-publish-preview.sh (new) — structural smoke test

## Tests

Tier 2 — This plan adds skill instructions, documentation, and metadata; no application source changes
- Objective: a work-in-progress plan reaches a public preview URL that the skill can also take down. File: tests/plugins/test-publish-preview.sh; Type: smoke; Asserts: the skill exists with `name: publish-preview` and a description at or under 200 characters, its body publishes to `docs/previews/` and never to `docs/plans/`, it carries the verbatim plan-mode guard, it documents the per-run confirmation, the `sha` precondition, the bounded deploy poll, `--unpublish`, and the `artifact-tools:plan-artifact` fallback on 403 or 409, and `plan-agent` is registered above the version on `main`; Run: bash tests/plugins/test-publish-preview.sh

## Acceptance Criteria

- [ ] `bash tests/plugins/test-publish-preview.sh` exits 0
- [ ] `bash tests/plugins/test-exitplanmode-guard.sh` exits 0 with the new skill present
- [ ] `bash tests/plugins/test-description-budget.sh` exits 0, confirming the description fits the 200-character budget
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 7.3.0
- [ ] Running the skill on a plan from a feature branch returns a `docs/previews/<slug>.html` URL that answers HTTP 200 and contains the plan title
- [ ] Running the skill a second time on the same plan updates that same URL and creates no second file on `main`
- [ ] Running the skill with `--unpublish` removes the file and the URL then answers HTTP 404
- [ ] The commit the skill creates on `main` touches only paths under `docs/previews/`, leaving `docs/plans/` and `docs/plans/index.html` on `main` byte-identical
- [ ] Re-rendering the plan before publishing changes `docs/plans/<slug>.html` on the feature branch only, as a normal spec-then-render edit the user commits with the plan

## Verification

Run the whole loop against a real plan. From a feature branch holding an in-progress plan, invoke the skill, confirm the write when prompted, and watch it report a URL under `https://<owner>.github.io/<repo>/previews/`. Confirm `gh run list --workflow=deploy-pages.yml --limit 1` shows a run triggered by the preview commit, then `curl -s <url> | grep -q "<plan title>"` exits 0. Edit the plan spec, re-render, and publish again: the reported URL is unchanged, and `gh api repos/<owner>/<repo>/contents/docs/previews --jq 'length'` still counts one file for that plan.

Then confirm the isolation this design depends on. `git fetch origin && git show --stat origin/main` lists the preview commit with no path under `docs/plans/`, and the plans gallery at `docs/plans/index.html` contains no card pointing at `docs/previews/`. The re-render in step two is expected to change `docs/plans/<slug>.html` on the feature branch — that is the ordinary spec-then-render edit the user commits with the plan, and the isolation being verified here is that it never reaches `main` through this skill. Finally run `--unpublish` and confirm `curl -s -o /dev/null -w '%{http_code}' <url>` returns 404 once the removal deploys.

## Next Steps

- Teach `finalize-plan` to unpublish automatically
  When a plan is closed out, the preview is obsolete by definition — the removal offer could move there instead of waiting for the next `publish-preview` run.
  ```text
  In the agentics repo (~/devbox/agentics), extend kit/plugins/plan-agent/skills/finalize-plan/SKILL.md so that when it sets a plan's status to completed it checks whether a preview exists at docs/previews/<slug>.html on the main branch (gh api repos/{owner}/{repo}/contents/docs/previews/<slug>.html) and, if so, offers to remove it via the same confirmed gh api -X DELETE path that plan-agent:publish-preview uses. Bump the plan-agent minor version in .claude-plugin/marketplace.json, add a CHANGELOG.md entry under kit/plugins/plan-agent/, and extend tests/plugins/test-publish-preview.sh to assert finalize-plan references the preview path. Verify by running bash tests/plugins/test-publish-preview.sh and confirming it exits 0.
  ```
- Wish list: record the preview URL in the plan spec
  A `preview-url:` frontmatter key would let the plan page link to its own public copy, mirroring how `artifact-url:` works today.
  ```text
  In the agentics repo (~/devbox/agentics), add an optional preview-url frontmatter key to plan specs that kit/plugins/plan-agent/skills/publish-preview/SKILL.md writes after a successful first publish, mirroring how artifact-tools:plan-artifact records artifact-url. Confirm scripts/build-plan-html.mjs preserves unknown frontmatter keys across a re-render before relying on it. Bump the plan-agent minor version in .claude-plugin/marketplace.json and add a CHANGELOG.md entry. Verify by adding preview-url to a test spec, running node scripts/build-plan-html.mjs on it twice, and confirming the key survives both renders.
  ```

## Unresolved Questions

- Protected `main` in other repositories. This plan reports a 403 or 409 and falls back to `artifact-tools:plan-artifact`. Whether the skill should instead open a tiny pull request containing only the preview file is a real alternative, but it trades a one-second publish for a merge someone has to approve, so it is deliberately out of scope here.

## Resources

- docs/guides/publish-docs-to-github-pages.md — the repo's own reference for how `docs/` reaches a public URL
- .github/workflows/deploy-pages.yml — deploys on pushes to `main` touching `docs/**`; the trigger this skill relies on
- kit/plugins/plan-agent/hooks/build-index.sh:87-88 — the `os.walk(plans_dir)` call and its exclusion list, confirming the gallery only ever scans the plans directory
- kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md — the claude.ai counterpart, and the fallback when the Contents API write is refused
- GitHub Contents API, create-or-update file contents — the `sha` precondition behaviour this plan depends on
