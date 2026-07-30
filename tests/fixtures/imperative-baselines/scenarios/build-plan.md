---
status: todo
type: chore
created: 2026-07-30
effort: low
glance: A one-step fixture plan that creates hello.txt in the repository root; it works when the file exists and reads exactly "hi".
workflow: false
---

# Plan: Create the hello.txt marker file

## Objective

Create a single file `hello.txt` in the repository root containing the one line `hi`, so a plan-execution baseline has a fixed, trivially verifiable outcome.

## Context

This plan is a fixture for the behavioral baseline harness. It exists so `plan-agent:build` can be run headless against an input that never changes, producing one predictable file write. It is deliberately the smallest valid plan: one step, one file, no dependencies, no tooling.

## Files

- hello.txt (new) — the marker file, containing the single line `hi`

## Steps

1. Create `hello.txt` in the repository root containing the single line `hi`. Why: the marker file is the whole deliverable, and a fixed one-line body keeps the baseline byte-stable. Verify: `test "$(cat hello.txt)" = hi` exits 0.

## Tests

- Tier 2 (non-source marker file only) — Objective: proves `hello.txt` exists and holds exactly `hi`; Type: smoke; Run: `test -f hello.txt && test "$(cat hello.txt)" = hi`

## Acceptance Criteria

- [ ] `hello.txt` exists in the repository root.
- [ ] `hello.txt` contains exactly the line `hi`.

## Verification

Run `test -f hello.txt && test "$(cat hello.txt)" = hi`; expected result is exit 0.
