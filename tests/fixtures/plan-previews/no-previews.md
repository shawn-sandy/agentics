---
status: in-progress
type: feature
created: 2026-10-13
repo: fixture
---

# Plan: Fixture plan without previews

## Objective

Prove a preview-less spec renders byte-for-byte as it did before previews existed.

## Context

A golden captured with the unmodified renderer. Contains `code`, **bold**, and a `<\/script>` mention in prose.

## Decisions

- The golden is captured before the renderer changes.
- `repo` and `created` are pinned so the bytes match on any machine.

## Files

- scripts/build-plan-html.mjs (modified) — renders the plan
- tests/fixtures/plan-previews/no-previews.html (new) — the golden

## Steps

1. [x] Write the fixture spec. Why: a golden needs an input. Verify: the file exists.
2. Render it with the unmodified renderer. Why: only output captured before the change is an honest baseline. Verify: the command exits 0.

## Tests

Tier 1 — This plan changes application code
- Objective: the golden matches. File: tests/plugins/test-plan-previews.mjs; Run: node tests/plugins/test-plan-previews.mjs

## Acceptance Criteria

- [x] The fixture spec exists
- [ ] The golden is byte-identical after the change

## Verification

Run the preview test file and expect the golden case to pass.

## Next Steps

- Add a second golden for a laned spec
  Lanes have their own byte-stability constraint.
  ```text
  Add a laned fixture next to no-previews.md and assert its render is byte-identical too.
  ```
