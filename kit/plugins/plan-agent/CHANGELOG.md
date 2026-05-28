# Changelog

## 0.2.0 — 2026-05-27

### Changed (BREAKING)

- **Plugin renamed** `plan-mode` → `plan-agent`. Install id is now `plan-agent@agentics-kit`.
- **Skill renamed** `authoring-plans` → `author`. Explicit invocation is now `/plan-agent:author <objective>`.
- **Activation model changed**: `author` skill is now manual-invoke only (`disable-model-invocation: true`). It no longer auto-activates on planning intent — use `/plan-agent:author` explicitly.

### Added

- `$ARGUMENTS` parsing: reads a free-text objective plus flags (`--quick`, `--type`, `--dir`, `--interview`) from the invocation line.
- Smart `--type` inference from the leading verb of the objective when the flag is absent.
- Smart `--quick` inference for detailed, specific objectives.
- `EnterPlanMode` entry — the skill flips the session into real plan mode on invocation.
- `EnterPlanMode` added to `allowed-tools`.
- `--interview` flag: after the plan is written, optionally runs `plan-interview:plan-interview` before `ExitPlanMode`.

### Unchanged

- `validate-plan-filename` hook — logic, exit codes, and `hooks.json` registration are identical. Only the stderr citation was updated to reference `plan-agent` `/plan-agent:author`.
- Full §0–§7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full §0–§7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
