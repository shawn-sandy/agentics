# Let create-issue ingest plans and offer issue creation at plan completion

> Plans and issues only linked in one direction — an issue could seed a plan, but a finished plan could not become a tracked ticket. Now create-issue accepts a plan file as a source.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source keyword to `git-agent:create-issue` so a `.md` or `.html` plan file can be turned into a GitHub or GitLab issue — a token ending in `.md`/`.html` implies the source even without the explicit keyword.
- Created `references/plan-issue.md` with the body skeleton (Objective, Plan path, Steps checklist, Acceptance Criteria, Additional Context) and the `type:` → label mapping.
- Extended `implementation-plan` Step 8 to batch a second `AskUserQuestion` — "Create a tracking issue for this plan?" — and on yes invoke `git-agent:create-issue plan <spec path>`, recording the returned URL as the `issue:` frontmatter key.
- When `git-agent` is not installed, the tracking-issue prompt degrades to a one-line notice and the plan flow continues unblocked.
- Bumped `git-agent` to 3.12.0 and `plan-agent` to 2.22.0 in `marketplace.json`, with matching CHANGELOG entries, README updates, and `CLAUDE.md` plugin-table rows.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill instructions — plan source keyword, per-source mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue body skeleton and label mapping | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test — verifies plan source declaration, template routing, implementation-plan wiring, and version bumps | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation — plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history — v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — Step 8 batched tracking-issue question and handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — v2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — git-agent 3.12.0, plan-agent 2.22.0 | Modified |

## How it works

The `create-issue` skill already had four sources (`bug`, `feature`, `selection`, `session`) processed through a source-detect → draft → confirm → create pipeline. The plan adds a fifth: `plan`. The source is resolved in Phase 3 of the skill's workflow — a token ending in `.md` or `.html` implies `plan` even without the explicit keyword, so `/git-agent:create-issue docs/plans/my-feature.md` requires no source keyword at all.

Once the plan source is identified, the remaining argument is treated as a file path, resolved first as given and then by basename under the configured `plansDirectory` or `docs/plans/`. The resolved file (always the `.md` spec, even if `.html` was given) is read and mapped: the plan title becomes the issue title, Objective becomes Summary, Steps become a `- [ ]` task checklist (action text only — Why/Verify detail is dropped), Acceptance Criteria carry over as checklist items, and the frontmatter `type:` provides a label hint (`fix` → `bug`, `feature` → `enhancement`, etc.).

The body is assembled using `references/plan-issue.md` as the skeleton — this mirrors how every other source has its own template file. The skeleton adds a **Plan** field containing the repo-relative path to the spec, so the issue links back to its origin even without the `issue:` frontmatter key. The same `issue:` key is what the reverse path writes, closing the bidirectional link.

The reverse path lives in `implementation-plan` Step 8. That step already presents a four-option menu via `AskUserQuestion`. Because the four-option maximum was already reached, the tracking-issue choice rides as a second batched question in the same turn. On a `yes` answer the skill calls `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` and writes the returned issue URL back into the spec's frontmatter as `issue:`. If git-agent is not installed, the skill emits a one-line notice and continues — a missing cross-plugin dependency never blocks the plan flow.

The confirmation gate that guards every `create-issue` path is not bypassed for the plan source. The skill shows a preview of the drafted issue body before calling `gh` or `glab`, consistent with all other sources.

Version bumps follow the repo's manual-versioning rule: a new skill capability is a MINOR bump, so git-agent moves from 3.11.1 to 3.12.0 and plan-agent from 2.21.0 to 2.22.0. Both CHANGELOG entries, the README plan-source section, and the CLAUDE.md plugin-table rows were updated in the same change.

## How to use it

**Turn a plan into an issue:**

```bash
/git-agent:create-issue plan docs/plans/my-feature.md
# or, using the implicit path detection:
/git-agent:create-issue docs/plans/my-feature.md
```

**After confirming, an issue is filed with:**
- Title from the plan's H1 (without the `Plan:` prefix)
- Objective as Summary
- Steps as `- [ ]` checklist items
- Acceptance Criteria carried over
- Plan path cited in the body

**From inside `implementation-plan`:**

At Step 8, the skill asks: "Create a tracking issue for this plan?" — answer Yes to invoke `create-issue` automatically. The returned issue URL is written into the spec as `issue:` frontmatter.

**Verification:**

```bash
bash tests/plugins/test-create-issue-plan-source.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `620ffa8` | 2026-08-19 | docs: sync READMEs with marketplace; fix the dead version-guard hook (#581) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `ac94d70` | 2026-08-17 | fix(settings-sync): add plan-mode guard to backup and restore skills (#572) |
| `d7598ad` | 2026-08-17 | fix: screenshot output verification and plan Context completeness (#571) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `ab2f769` | 2026-08-17 | chore: make verification gates a self-enforcing authoring standard (#569) |
| `2fd715f` | 2026-08-17 | fix: redefine done as artifact + verification in five high-impact skills (#568) |
| `875b4c1` | 2026-08-17 | fix: close security-scrub coverage holes in sharing and backup skills (#567) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |
| `dbf3844` | 2026-08-14 | fix(plan-agent): add plan-mode guard to plan-status (#562) |
| `744f6e1` | 2026-08-14 | feat(git-agent): add scope guard PreToolUse hook (#560) |
| `c4860d1` | 2026-08-14 | feat: add --check mode to plan renderer for verifying HTML consistency (#556) |
| `c1e6e34` | 2026-08-14 | Run every ship pre-flight guard before reporting, not just the first (#555) |
| `9871dd9` | 2026-08-14 | Add build-fleet: ship a plan backlog in parallel, one worktree agent per plan (#554) |
| `a21acfb` | 2026-08-14 | Verify before asserting: merge guards, measured contrast ratios, review-finding reproduction (#552) |

_Showing 20 of N commits — run `git log` for the full history._

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
- Related docs: `kit/plugins/git-agent/README.md`, `kit/plugins/git-agent/CHANGELOG.md`
