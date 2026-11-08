# Let `build` author a plan when none is specified

> Replaces `plan-agent:build`'s no-plan dead end with a pipeline entry that walks proposal → plan → review → implement without re-invoking anything.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
**Type:** feature

## What shipped

- Added a `Step 1b` chain entry to `build/SKILL.md` that enters the proposal → `implementation-plan` → review → implement pipeline when no plan argument is supplied via the slash command (command-only; ambient activation unchanged).
- Changed discovery from a silent pickup to a ranked offer (newest-`created:` first, capped at three candidates plus "None of these — author a new plan"), gated on objective-absence so an explicit objective bypasses discovery entirely.
- Widened the argument grammar to `[<plan path>] [<objective>] [--dir <path>]`; a leading token is treated as an objective only when it has no `.md`/`.html` suffix and no `/`.
- Hoisted the dirty-working-tree precondition above all chain stages so it fires before any proposal loop begins.
- Pinned `model: opus` in `build/SKILL.md` frontmatter to give the source-writing stage a deterministic model across chained skill calls.
- Specified abandonment contract: a proposal written before an abort is left in place uncommitted and its path is reported.
- Defined termination behaviour for every non-implementing Step 8 choice (`Exit` and `Run as workflow` both stop the outer chain).
- Extended `tests/plugins/test-build-skill.sh` with new checks for chain entry, discovery offer, hoisted guard, model pin, grammar rule, and two surviving stop branches.
- Updated `kit/plugins/plan-agent/README.md` and `CLAUDE.md` to describe the no-plan chain; bumped plan-agent to a MAJOR version (5.0.0).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions — chain entry, discovery offer, guard hoist, model pin | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `tests/plugins/test-build-skill.sh` | Smoke test suite | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version (plan-agent MAJOR bump) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `CLAUDE.md` | Root plugin table | Modified |

## How it works

Before this change, every no-plan code path in `build/SKILL.md` ended with a stop and a manual instruction. The plan replaces only the empty-discovery branch with a delegation chain; the named-but-missing-path branch and the HTML-with-no-sibling-spec branch continue to stop, so a typo never authors a plan.

Discovery runs only when no objective was supplied (bare `/plan-agent:build`). It ranks candidates newest-`created:` first, shows at most three, and always appends "None of these — author a new plan." When an objective is present, discovery is skipped entirely — an unrelated backlog of `todo` specs is noise, and `AskUserQuestion` can't render an unbounded option list anyway.

The chain itself lives in Step 1b. It first asks for an objective when the user reached it via "None of these," then presents a proposal-versus-direct gate. The proposal path invokes `plan-agent:build-proposal` and then `plan-agent:implementation-plan`; the direct path invokes `implementation-plan` alone. On return, the produced spec is resolved by path, not by re-running discovery.

A skill's `model:` override applies for the rest of the turn and does not unwind when the skill ends. Without the `model: opus` pin, a chained run would leave the source-writing stage on whatever model `review-plan` or `implementation-plan` last declared. The pin re-asserts on every `build` activation.

The step 1b return path explicitly names the two non-implementing Step 8 choices. `Exit — I'll implement later` stops with the plan at `status: todo`; `Run as workflow` stops because `implementation-plan` has already emitted the workflow prompt. Without this rule, `build` would implement work the user just routed elsewhere.

The scope is deliberately narrow: the chain is reachable only from the `/plan-agent:build` slash command. `$ARGUMENTS` is empty on the model-invocation path, and the verb `build` is overloaded enough that any ambient trigger catching "build a todo app" also catches "build fails on CI."

## How to use it

Activate by invoking the slash command. The objective is a command parameter.

```
/plan-agent:build                                # bare — discovery offer or chain via None of these
/plan-agent:build add a health check endpoint    # objective — skips discovery, enters chain
/plan-agent:build docs/plans/my-feature.md       # existing plan — existing behaviour, no chain
```

The model-invocation path (ambient activation) is unchanged: it requires a plan that already exists and routes to `/plan-agent:implementation-plan` when there is none.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5764be8` | 2026-11-05 | fix(plan-agent): drop gallery tabs whose page does not exist (9.22.1) (#670) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `58f14cd` | 2026-10-30 | feat(design-system-tools): add customize-design and align-design-md skills (0.3.0) (#666) |
| `cc28a20` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `82227d6` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `6a6cf33` | 2026-09-28 | feat(design-system-tools): add plugin with from-design-md skill (0.1.0) (#643) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |

_Showing 20 of N commits — run `git log` for the full history._

<!-- generated:end -->

## References

- Plan: [add-plan-authoring-to-build.md](plans/add-plan-authoring-to-build.md)
- Related: `docs/proposals/chain-plan-authoring-into-build.md` — the proposal this plan executes
