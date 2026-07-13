# docs/plans/ -- Plan Lifecycle & Retention Policy

## Directory Layout

- `docs/plans/` -- Active plans (HTML preferred, some legacy .md)
- `docs/plans/archive/` -- Retired plans, organized by type (`standard/`, `fix/`, `docs/`, `enhancement/`)
- `docs/guides/` -- Generated developer documentation
- `docs/plans/index.html` -- Filterable gallery of active HTML plans

## Status Vocabulary

Only three values are permitted: `todo`, `in-progress`, `completed`. No other values allowed.

## Plan Lifecycle

1. New plan created -- `status: todo`
2. Work begins -- `status: in-progress`
3. Work done -- `status: completed`
4. After review -- `git mv` to `archive/<type>/`

## Six-Month Retention Rule

Plans with `status: completed` AND `created` date older than 6 months are eligible for archival.
A periodic review should check for eligible plans and move them to the appropriate archive subdirectory.

As of 2026-06-04, no plans qualify. The oldest was created 2026-01-19 (cutoff: 2025-12-04).

## Keep vs Archive

**Keep:** active work, reusable architecture decisions, design patterns, ongoing initiatives.

**Archive:** shipped one-off fixes, stale/abandoned plans, vague/incomplete drafts, superseded plans.

## HTML Format

Active plans should use HTML format (implementation-plan template).
The plans gallery at `index.html` only indexes `.html` files -- legacy `.md` plans are not surfaced in the gallery.
