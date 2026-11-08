# Replace build's grep drift check with a deterministic render check

> Add `--check` mode to `plan-agent-render` that byte-compares a plan's HTML against a fresh in-memory render and asserts a `completed` spec is internally consistent, eliminating the grep-based DOM inspection that produced false drift signals.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to `scripts/build-plan-html.mjs`: renders the spec to a string, byte-compares against the existing output file, and reports the first differing line with its line number and context.
- Extended `--check` with spec-consistency assertions — evaluated on the parsed Markdown only when `status: completed` — verifying every numbered step has `[x]` and every acceptance criterion is `- [x]`.
- Made `--check` print a fixed PASS/FAIL table (rows: `html`, `steps`, `criteria`) with exit 0 only when every row passes; missing output file reports FAIL naming the render command rather than crashing.
- Re-copied the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` to restore byte-identity.
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 as a single `--check` command, deleting the five-selector DOM paragraph.
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md`.
- Bumped plan-agent to 9.4.0 (plan specified 9.3.0 but PR #554 had shipped that by ship time).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Canonical renderer — `--check` mode: render to memory, compare, assert spec consistency | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy (held by parity assertion) | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Build skill reference — Step 5.3 rewritten as single `--check` command | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Finalize skill reference — same gate replacement | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — `--check` documented in renderer section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 9.3.0 → 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — determinism, check-mode, missing-HTML, consistency, in-progress-skip cases | Modified |

## How it works

The 2026-08-14 usage report identified grep-as-verification as the single largest source of wasted passes. `completion-gates.md` Step 5.3 instructed the model to confirm five CSS selectors, but selectors defined in the stylesheet matched even when the renderer hadn't conditionally emitted the class — both false-positive and false-negative directions were observed.

The root cause was conflating two properties. "Is the HTML current?" is a build-freshness question answered by byte comparison — the renderer is deterministic at a fixed output path. "Is a `completed` spec internally consistent?" is a Markdown question answered by parsing the spec directly. Neither requires reading rendered markup.

Determinism was established first: rendering the same spec twice over the same output path was verified byte-identical. The `plan-file` and `plan-path` meta tags are derived from the output path and differ when the path differs — these were deliberately not normalized out of the comparison, because that would let `--check` pass an HTML file copied in from another location.

`--check` was implemented in the canonical `scripts/build-plan-html.mjs` (the file the tests import), not the bundled copy. It renders the spec to a string, compares against the on-disk file, and reports the first differing line. For a `status: completed` spec, it additionally checks that every step carries `[x]` and every acceptance criterion is `- [x]`. A `status: in-progress` spec skips the consistency rows rather than failing them.

Both `completion-gates.md` and `write-completions.md` now invoke `--check` with a single command. The five-selector paragraph was deleted; a non-zero exit names the failing property, and the fix is always in the spec, never the HTML.

> See [CHANGELOG v9.4.0](kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## How to use it

The `--check` flag is added to the existing renderer CLI:

```bash
# Verify a plan's HTML is current and (if completed) internally consistent
plan-agent-render docs/plans/my-plan.md -o docs/plans/my-plan.html --check

# Example PASS output
html      PASS
steps     PASS
criteria  PASS
All checks passed.

# Example FAIL output (stale HTML)
html      FAIL (line 142 differs)
Expected: <span class="step-status done">10 / 10</span>
Actual:   <span class="step-status done">9 / 10</span>
```

Skills invoke `--check` automatically at Step 5.3 of `plan-agent:build` and in `plan-agent:finalize-plan`'s completion gate.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 9.4.0 entry
