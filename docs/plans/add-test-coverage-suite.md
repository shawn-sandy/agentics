---
status: todo
created: 2026-06-09
---

# Add a real test suite + CI for the repo's executable code

## Context

This repo is a Claude Code plugin marketplace (mostly Markdown/JSON), but it
contains real executable logic that is largely untested. A coverage review on
2026-06-09 found:

- **Only `publish-dist.yml` runs any tests in CI** — and only 2 of them
  (`tests/publish/smoke-clean-dist.sh`, `tests/publish/test-dist-transforms.mjs`),
  and only on the publish path.
- `tests/pages/*`, `tests/demo/*`, `tests/fixtures/skill-description-hook/run.sh`,
  and the `merge-marketplace` fixtures are **never executed automatically** —
  there is no general test workflow and no top-level test runner.
- Several tests are *grep-the-source* assertions (`test-publish-fn.mjs`,
  `test-workflow-config.sh`) that check strings exist in source/YAML rather than
  executing behavior — they pass even when logic is broken and break on harmless
  refactors.
- `tests/fixtures/{valid,invalid}-plugin/` + their README describe a TypeScript
  marketplace API (`loadPlugin`, `validatePlugin`, vitest) that does not exist
  anywhere in the repo — orphaned fixtures backing no test.

### Executable code inventory (the real test targets)

| File | Lines | Tested today |
|---|---|---|
| `scripts/build-dist.mjs` | 488 | Partial — integration only, no unit cases for `matchesDrop`/`KEEP` |
| `scripts/merge-marketplace.mjs` | 102 | None — fixtures exist but nothing runs the driver |
| `kit/plugins/plan-agent/hooks/validate-plan-filename.py` | 215 | None — pure `classify_filename` is ideal for units |
| `kit/plugins/plan-agent/hooks/rebuild-plans-index.py` | 163 | None |
| `kit/plugins/plan-agent/hooks/build-index.sh` | 174 | None |
| `kit/plugins/wcag-compliance-reviewer/.../check_wcag.py` | 356 | None — largest logic surface |
| `kit/plugins/social-media-tools/scripts/session_usage.py` | 273 | None |
| `kit/plugins/skill-reviewer/.../session_tool_scan.py` | 167 | None |
| `kit/plugins/skill-reviewer/scripts/measure-description.sh` | — | Has a harness (`tests/fixtures/skill-description-hook/run.sh`) but not in CI |
| `kit/plugins/git-agent/.../extract-plan-issues.sh`, `find_free_port.py` | small | None |

## Goals

1. Every existing test runs on every PR (close the CI wiring gap).
2. The highest-risk untested logic gets real, behavior-level tests.
3. Replace grep-the-source pseudo-tests with execution tests, or delete them.
4. Resolve the orphaned `valid/invalid-plugin` fixtures (implement or remove).

Non-goal: 100% line coverage. Focus on logic with branches and regression risk.

## Phased Work

Each phase is independently shippable. Land P0 first; later phases can follow in
separate PRs.

### Phase 0 — Test runner + CI (highest value, lowest effort)

The suite mostly already exists; it just never runs on PRs.

**Create `tests/run-all.sh`:**
- Discover and run every `tests/**/*.test.sh` and `tests/**/test-*.{sh,mjs}`,
  plus the existing `tests/demo/run.sh` and
  `tests/fixtures/skill-description-hook/run.sh`.
- Skip suites that require a live server (e.g. `tests/pages/test-pages-smoke.sh`
  takes a base URL) unless an env flag is set — those stay deploy-only.
- Build `dist/` first (`node scripts/build-dist.mjs`) so the publish/transform
  tests have an artifact to assert against.
- Aggregate pass/fail and exit non-zero if any suite fails.

**Create `.github/workflows/test.yml`:**
- Triggers: `pull_request` and `push` to `main`.
- Sets up Node 20 and Python 3.11.
- Runs `bash tests/run-all.sh`.

**Acceptance:** opening a PR runs the whole suite; a deliberately broken
assertion fails the check.

### Phase 1 — High-risk untested logic

**1a. `merge-marketplace.mjs` execution test** (fixtures already exist)
- New `tests/merge/test-merge-marketplace.mjs`.
- Invoke the driver the way git does: `node scripts/merge-marketplace.mjs
  <base> <ours> <theirs>` against copies of
  `tests/fixtures/merge-marketplace/{base,ours,theirs}.json`, then diff the
  rewritten `ours` against `expected.json`.
- Add focused cases beyond the existing fixture: `semverMax` tie/higher/lower,
  `removed[]` union (theirs must not resurrect an ours-removed plugin),
  new-plugin-in-theirs append order, and a parse-error input (driver must exit 1
  and leave `ours` untouched).

**1b. `classify_filename` unit tests** (`validate-plan-filename.py`)
- New `tests/plan-agent/test-validate-filename.py` (stdlib `unittest`, no deps).
- Import `classify_filename` and cover each failure branch: non-kebab, hex
  suffix, `-agent-<hex>` suffix, trailing date, placeholder name, non-verb first
  token, stop-word second token, plus valid happy-path cases.
- Cover the settings-injection path (`additionalVerbs` / `additionalStopWords` /
  `additionalPlaceholders`) by passing custom sets.

**1c. `build-dist.mjs` unit cases**
- New `tests/publish/test-build-unit.mjs`.
- Export or test-import the pure helpers (`matchesDrop`, `transformReadmeForDist`,
  `transformPluginJsonForDist`) and assert: docs/png/.local.md/.DS_Store/
  .playwright-mcp are dropped; KEEP entries survive; transforms rewrite only the
  intended URLs and leave preserved dev-repo refs intact; `transformPluginJson`
  throws on JSON corruption.
- May require a tiny refactor to make helpers importable (guard the CLI dispatch
  at the bottom behind an `import.meta.url === ...` main check). Keep this
  refactor minimal and behavior-preserving.

### Phase 2 — Larger logic surfaces

**2a. `check_wcag.py` fixture tests**
- New `tests/wcag/` with small `.html` / `.tsx` / `.css` fixtures, each crafted
  to trip exactly one rule (missing alt, label-less input, low-contrast hint,
  etc.) plus a clean file that yields zero issues.
- Assert the emitted `Issue` rule + severity per fixture (the script can emit
  JSON — drive it via that).

**2b. Plans-gallery generation** (`rebuild-plans-index.py` / `build-index.sh`)
- Feed the existing `tests/fixtures/plan-agent/*.html` sample plans into the
  index builder in a temp dir; assert the generated `index.html` contains the
  expected entries and is well-formed.

### Phase 3 — Cleanup / debt

**3a. Replace grep-the-source pseudo-tests**
- `tests/publish/test-publish-fn.mjs` and the `test-workflow-config.sh` pair
  assert strings exist in source/YAML. Either convert to real behavior tests
  (e.g. parse the YAML and assert structure) or delete them once Phase 0/1 cover
  the behavior. Do not keep both.

**3b. Resolve orphaned fixtures**
- `tests/fixtures/{valid,invalid}-plugin/` + `tests/fixtures/README.md` reference
  a TypeScript marketplace API that does not exist. Decide with the maintainer:
  either (a) wire them to the actual `validate-plugin` skill logic, or (b) remove
  the fixtures and trim the README to reflect what is really tested. Default
  recommendation: remove, since no consumer exists.

## Files to Create / Modify

**Create:**
- `tests/run-all.sh`
- `.github/workflows/test.yml`
- `tests/merge/test-merge-marketplace.mjs`
- `tests/plan-agent/test-validate-filename.py`
- `tests/publish/test-build-unit.mjs`
- `tests/wcag/` (fixtures + `test-check-wcag.py`)
- `tests/plan-agent/test-build-index.sh` (gallery generation)

**Modify (minimal, behavior-preserving):**
- `scripts/build-dist.mjs` — guard CLI dispatch so helpers are importable
- `tests/fixtures/README.md` — trim once 3b is decided
- Delete or rewrite `tests/publish/test-publish-fn.mjs`,
  `tests/publish/test-workflow-config.sh`, `tests/pages/test-workflow-config.sh`
  per 3a

## Acceptance Criteria

- [ ] `bash tests/run-all.sh` runs locally and exits non-zero on any failure.
- [ ] A `test.yml` workflow runs the suite on every PR and on push to `main`.
- [ ] `merge-marketplace.mjs` is executed (not grepped) against fixtures + the
      added edge cases.
- [ ] `classify_filename` has a unit test covering every failure branch.
- [ ] `build-dist.mjs` pure helpers have unit cases for drop/keep + transforms.
- [ ] `check_wcag.py` has at least one fixture per asserted rule.
- [ ] No remaining grep-the-source "tests"; orphaned plugin fixtures resolved.

## Notes / Open Questions

- Confirm CI runners may install Python 3.11 (the hooks target py3) — the
  GitHub-hosted `ubuntu-latest` image ships it, so no extra setup expected.
- `tests/pages/test-pages-smoke.sh` is an HTTP smoke test against a deployed
  URL; keep it gated to the deploy workflow, not the PR suite.
- Keep all new tests dependency-free (Node built-ins + Python stdlib + bash) to
  match the repo's no-`package.json` convention.
</content>
</invoke>
