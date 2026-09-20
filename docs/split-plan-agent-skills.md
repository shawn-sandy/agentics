# Stop paying 10,776 words for guidance nobody reads yet

> Five plan-agent skills bill 10,776 words of context every time they fire, and an ordinary run reads maybe a quarter of it — Step 1b's 60-line no-plan contrac...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Write `tests/plugins/test-progressive-disclosure.sh` covering the five skill directories, asserting each `SKILL.md` i...
- Wire the new test into `.github/workflows/check-plugin-versions.yml` as a step named "Test skill progressive disclosu...
- Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve...
- Update `tests/plugins/test-build-skill.sh` so its `flatten`/`sed` section extractors search `SKILL.md` and every `ref...
- Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `ref...
- Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditio...
- Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `refere...
- Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/sc...
- Bump `plan-agent` from `7.5.0` to `7.6.0` in `.claude-plugin/marketplace.json` (never adding a `version` key to `kit/...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | reduced to trigger, arguments summary, step names, the re... | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | command vs model activation, flag parsing, objective-vers... | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Step 0 exit-plan-mode, the dirty-tree pre-flight guard, A... | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Step 1b in full: objective check, proposal-versus-direct ... | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Steps 3, 4, 5 and the spec-is-source-of-truth rules they ... | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Step 1 argument parsing, plans-directory precedence, spec... | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | the `--all` flow, S1 through S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Steps 2, 3a, 3b, 3c and the Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Step 5 spec mode and legacy mode, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Steps 0-2: todos, plan resolution priority order, complet... | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Steps 3-7: parse plan, derive slug, inspect shipped files... | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | the Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Steps 0-4 and Steps 6-7: resolution, git dates, frontmatt... | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | the directory / `--all` seven-stage flow with its triage ... | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Step 5's signal-to-type table and the keep-existing-type ... | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Steps 1-3: git/remote URL derivation, `plansDirectory` sa... | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Step 4's four idempotent artifacts and the hub placeholde... | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Steps 5-7: Pages source enablement, verification block, d... | Created |
| `tests/plugins/test-progressive-disclosure.sh` | objective test: word ceiling plus link integrity in both ... | Created |
| `tests/plugins/test-build-skill.sh` | section extractors resolve headings across SKILL.md and r... | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | same, for the `--all` sweep assertions | Modified |
| `tests/plugins/test-setup-sites.sh` | same, for the scaffold assertions | Modified |
| `.github/workflows/check-plugin-versions.yml` | new step running `tests/plugins/test-progressive-disclosu... | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` version 7.5.0 to 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 entry | Modified |

## How it works

Split the five monolithic `plan-agent` skills — `build`, `finalize-plan`, `documenting-plans`, `plan-status`, `setup-sites` — into a SKILL.md core under 600 words holding trigger, arguments, and step names, with the mechanics moved to `references/<topic>.md` files loaded on demand.

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes progressive disclosure (Rule 3) the load-bearing rule for skill authoring: move detailed guidance out of the always-loaded body into references the model pulls when it needs them, and split long skills into multiple files. A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load, no lazy paragraph. A measured audit of this repo found 17 SKILL.md files over 1,200 words shippin...

The implementation proceeded through these steps: Write `tests/plugins/test-progressive-disclosure.sh` covering the five skill directories, asserting each `SKILL.md` i...; Wire the new test into `.github/workflows/check-plugin-versions.yml` as a step named "Test skill progressive disclosu...; Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve...; Update `tests/plugins/test-build-skill.sh` so its `flatten`/`sed` section extractors search `SKILL.md` and every `ref...; Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `ref....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
