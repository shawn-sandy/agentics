---
session-id: "a9e6f51e-47ce-417c-936c-a9cdfade43a9"
date: 2026-07-15
source: "a9e6f51e-47ce-417c-936c-a9cdfade43a9.jsonl"
type: session-export
title: "Plugin version guard for the publish pipeline"
artifact-url: https://claude.ai/code/artifact/5b8fdf67-c940-4973-9ae4-ab9d3d21f682
---

# Plugin version guard for the publish pipeline

## Summary

Started as a walkthrough of how plugins reach users and ended with a CI guard closing
the one real hole in that pipeline. Tracing `publish-dist.yml` and `build-dist.mjs`
surfaced a silent failure mode: merge a plugin change without bumping `version` in
`marketplace.json` and the daily cron republishes a byte-identical tree forever —
nobody gets the update and nothing fails. Three new files now fail the PR when that
happens. All 16 unit assertions pass, and the guard was verified firing and passing
against the real manifests. Nothing is committed yet.

## Decisions

**Fail the PR rather than auto-bump the version.** Auto-bumping was the tempting
option and it reproduces the bug it fixes. The semver level is a judgment call —
`.claude/rules/marketplace.md` makes new-skill a minor and metadata-fix a patch —
so inferring it from conventional-commit prefixes would mislabel a `feat(...)` commit
that removes a skill argument, silently, exactly like the current gap. Auto-bumping
also fights `merge-marketplace.mjs`, which resolves conflicts by keeping the higher
semver on the assumption that humans set intentional values in branches. And it would
delete the repo's stated contract: "what you set in the PR is what ships."

**No routine or scheduled agent.** The cron already does this deterministically, for
free, with `gh issue create` on failure. A routine would be an LLM re-deciding every
morning what a 40-line YAML file already decides correctly — slower, non-deterministic,
token-costing, needing its own auth. The gap was never scheduling; it was the bump.

**A new workflow rather than hanging the check on `claude-code-review.yml`.** That
workflow is `pull_request`-triggered and would have been the lazy host, but it is an
LLM reviewer whose findings are advisory per the review-bot-loops rule. A silent-no-op
guard needs a deterministic red X, not a bot opinion.

**A standalone script over a `--check-versions` mode on `build-dist.mjs`.** Same file
count either way, but `build-dist.mjs` is a "manifest-driven clean builder" and a
version guard is not building. The separate script is testable without invoking a build.

**Three carve-outs, each a case where firing would be wrong.** Plugin absent from
`marketplace.json` is ignored (not built, not shipped — matches how removed plugins
already work). Plugin absent from the base manifest is ignored (new plugin, any
starting version is valid). Version present but unparseable is a violation, because
`"latest"` would otherwise pass the comparison silently.

## Learnings

**The dist "cleaning" drops nothing, and that's correct.** Running the build showed
245 files in, 245 out, zero dropped, 0.0% reduction — which reads like the cleaning is
broken. It's the opposite: the build iterates `plugins[]` from the manifest, not the
filesystem, so everything excluded (`tests/`, `docs/`, `.claude/`, plans) is excluded
by never being reachable. The DROP denylist is a safety net currently catching nothing,
which is what a healthy safety net looks like. This also explains removed plugins:
their directories still exist on disk and ship nothing because they aren't manifest
entries.

**"Publish" blurs two different cadences.** The sync runs daily and unconditionally —
`publish()` commits with `--allow-empty`, so `agentics-kit` gets a
`chore: sync from agentics@<sha>` commit every morning whether or not anything changed.
The version only moves when a human bumps it. That gap between the two is precisely
where the silent no-op lives.

**A verification approach was tried and abandoned.** The first attempt at proving the
guard fires used throwaway commits: `git add -A`, commit, run, then `reset --hard HEAD~2`.
The permission classifier blocked it, correctly — `git add -A` would have swept the
newly written guard script, workflow, and test into those commits, and the reset would
then have deleted all three. The replacement proves the same thing read-only: feed the
real current manifest, the real base manifest via `git show origin/main:...`, and a
synthetic changed-paths list straight into `findViolations`. It fired on `memory-tools`
at 3.1.3 vs 3.1.3 and passed at 3.1.4, with no git mutation at all. The lesson is that
`git add -A` in a verification script is hostile to uncommitted work that the script
itself just created.

**The workflow-injection hook fired but needed no fix.** Passing `${{ github.base_ref }}`
through `env:` rather than interpolating into `run:` was already the safe pattern, and
`base_ref` is a real branch name rather than free text.

**Two known ceilings are marked, not solved.** Both carry `ponytail:` comments. No
prerelease parsing, since this marketplace only ships plain `x.y.z`. And any file under
a plugin counts as a change, including DROP-listed paths like `kit/plugins/x/docs/` that
never ship — so a docs-only edit nags for a bump. That false positive matters more than
it looks: false positives train people to ignore checks, so if it fires spuriously even
once, reusing build-dist's KEEP/DROP logic is worth it.

## Files touched

All three are new and uncommitted; no existing file was modified.

- `scripts/check-plugin-versions.mjs` — the guard. Diffs `origin/$BASE_REF...HEAD`, maps
  changed paths to plugin names, reads the base manifest via `git show` (no second
  checkout), and compares versions. Exports `parseSemver`, `isHigher`, `changedPlugins`,
  and `findViolations` as pure functions so the logic is testable without git.
- `.github/workflows/check-plugin-versions.yml` — `pull_request` trigger with
  `fetch-depth: 0` so the base ref resolves; passes `github.base_ref` via `env:`. Runs
  the guard and its unit tests.
- `tests/publish/test-check-plugin-versions.mjs` — 16 assertions over the pure functions:
  semver parsing and ordering (including `1.10.0 > 1.9.0`, which lexical comparison gets
  wrong), plus each violation and carve-out case. All passing.
