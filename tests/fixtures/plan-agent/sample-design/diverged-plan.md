---
status: todo
type: feature
created: 2026-08-21
design: https://claude.ai/public/artifacts/abc123
design-dir: docs/designs/track-gym-workouts
---

# Plan: Track gym workouts

## Objective

Let a lifter log workouts and see progress.

## Steps

1. Add the workout log form with date and exercise fields.
   Why: logging is the core action. Verify: a submitted entry appears.

2. Build the dashboard page showing recent workouts.
   Why: the payoff surface. Verify: three seeded rows render.

3. Add a confirmation modal before deleting a workout.
   Why: deletion is destructive. Verify: cancelling keeps the row.

4. Bump the plugin version in marketplace.json.
   Why: a touched plugin without a bump fails the CI guard. Verify: the version guard exits 0.

5. Add the settings dialog for units and goals.
   Why: lifters work in kg or lb. Verify: switching units rewrites the table.

## Acceptance Criteria

- [ ] A workout can be logged and shows on the dashboard.

## Verification

Log a workout and reload.
