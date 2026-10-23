# Let `build` Author a Plan When None Is Specified

> Replaces `plan-agent:build`'s no-plan dead end with an entry into the existing proposal → plan → review → implement pipeline, triggered only from the slash command with an explicit objective parameter.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Added Step 1b to `build/SKILL.md`: a chain entry that delegates to `plan-agent:build-proposal` then `plan-agent:implementation-plan`, reachable only via the `/plan-agent:build <objective>` slash command, not ambient model invocation.
- Changed plan discovery from a silent pickup to an offer: bare `/plan-agent:build` with no objective presents at most three candidates ranked by `created:` date plus a "None of these — author a new plan" option, rather than silently adopting the most recent plan.
- Hoisted the dirty-working-tree precondition guard to run before any chain stage.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>] [--type …] [--sequential] [--workflow] [--max N] [--worker-model <alias>]`; a leading token is treated as an objective only when it has no `.md`/`.html` suffix and no `/`.
- Added `Skill` to `allowed-tools` and `model: opus` to frontmatter so the chain re-asserts the model on activation.
- Step 8's non-implementing exits (`Exit — I'll implement later`, `Run as workflow`) both terminate the outer chain without starting an in-session build.
- Updated `kit/plugins/plan-agent/README.md`: removed the "Implements a plan that already exists" opening, added a no-plan invocation example.
- Bumped `plan-agent` by a MAJOR version (argument format + discovery behaviour change) in `.claude-plugin/marketplace.json` with a CHANGELOG entry.
- Extended `tests/plugins/test-build-skill.sh` from 9 to 18 checks covering the chain entry, discovery offer, hoisted guard, exit-terminates-chain rule, pinned model, grammar rule, two surviving stop branches, and command-only scoping.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill contract — Step 1b chain, hoisted guard, grammar, model pin | Modified |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Extracted Step 1b chain logic | Created |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Argument grammar reference | Created |
| `tests/plugins/test-build-skill.sh` | Smoke test — extended to 18 checks | Modified |
| `kit/plugins/plan-agent/README.md` | Removed dead-end description, added chain usage | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` MAJOR version bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Entry for the no-plan chain | Modified |
| `CLAUDE.md` | `build` clause in the plugin table | Modified |

## How it works

Before this change, three situations caused `build` to stop: a named-but-missing path, an HTML-with-no-sibling-spec, and an empty plans directory. The empty-discovery branch printed "run `/plan-agent:implementation-plan` by hand" and stopped. This plan replaces only that third branch with a chain into the planning pipeline that already existed top-down.

The chain is scoped to the slash command. `$ARGUMENTS` is empty on the model-invocation path, so an ambient trigger would have to infer an objective from free text — and `build` is overloaded enough that "build a todo app", "build fails on CI", and "rebuild the index" would all match. Making the objective an explicit command parameter removes that class of false activations entirely. The ambient contract ("requires a plan that already exists — if there is no plan file, stop and route to `/plan-agent:implementation-plan`") survives unchanged, scoped to the model path.

When an objective is present, discovery is skipped entirely — the user has said what they want and unrelated `todo` specs in the repo are noise. The skill goes directly to Step 1b.

When no objective is present (bare `/plan-agent:build`), discovery runs as an offer: up to three candidates ranked newest-`created:` first, plus "None of these — author a new plan." The four-option ceiling matches `AskUserQuestion`'s render cap, and a suppressed count is stated when more exist.

Step 1b begins with an objective check: if the bare-`build` path reaches it via "None of these — author a new plan," it asks for an objective before doing anything else. Then a proposal-versus-direct gate decides whether to invoke `build-proposal` (which calls `implementation-plan` with the proposal document) or `implementation-plan` directly with the objective. The return path re-resolves the produced spec by path — never by discovery — to avoid offering the plan the user just watched being authored.

Step 8's exit handling was tightened during execution: `Implement now` was removed from Step 1b's return path because `Skill()` is synchronous and the nested build had already finished; `Exit` and `Run as workflow` both stop the outer chain and report the plan path. The dirty-tree guard was also fixed to exclude plan artifacts (`.md` and `.html` under the plans directory) so the guard does not fire on the spec and HTML that `implementation-plan` writes before calling back.

Two issues found during headless testing: (1) the `AskUserQuestion` fallback was unspecified, causing two different behaviors across headless runs — the skill now states the clean-stop fallback, guarded by check 18; (2) the misparse example in the grammar rule was corrected — a slash in the *first token* triggers the path-vs-objective misparse, not mid-sentence.

## How to use it

```text
/plan-agent:build add a health check endpoint
/plan-agent:build "add A/B testing for checkout"
/plan-agent:build
```

The first two forms enter the chain with an explicit objective. The third form presents any existing `todo` plans as candidates; choosing "None of these" prompts for an objective before proceeding.

Ambient text like "build a todo app" continues to require an existing plan and will not enter the chain.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
