# sample-design fixture

Raw pieces for `tests/plugins/test-design-drift.sh`. The test assembles them
into a throwaway project tree under `mktemp -d` rather than committing a nested
`docs/plans/` here — a second plans directory inside the repo would be swept up
by every tool that walks the real one.

- `matched-plan.md` — three user-facing steps plus one housekeeping step (a
  version bump). All three user-facing steps are covered by `artboards/`, and
  the housekeeping step is covered by nothing **by design**: it has no
  user-facing surface, so the skill derives no artboard for it and the drift
  check must not report it.
- `diverged-plan.md` — the same spec plus a fourth user-facing step (a settings
  dialog) that no artboard covers. This is the one case that must warn.
- `artboards/` — the three `.dc.html` artboards, named by the slug rule
  `check-design-drift.py` implements.
