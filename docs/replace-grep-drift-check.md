# Replace grep-based drift check with a --check mode render

> Adds a `--check` mode to the plan renderer that replaces CSS-selector DOM inspection with byte-comparison and spec-consistency assertions, making the drift check deterministic and fast.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to `scripts/build-plan-html.mjs` (canonical) and synced to the plugin copy in `kit/plugins/plan-agent/scripts/`.
- `--check` renders the spec to memory, byte-compares against the file on disk, and for `status: completed` plans verifies all `[x]` steps and `- [x]` criteria are present.
- Prints a PASS/FAIL table (`html`, `steps`, `criteria` rows); exits 0 only when all rows pass.
- Replaced the build Step 5.3 CSS-selector DOM inspection in `completion-gates.md` and `finalize-plan/references/write-completions.md` with `--check` invocations.
- Extended `tests/plugins/test-build-plan-html.mjs` with `--check` coverage.
- Bumped plan-agent to `9.4.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/completion-gates.md` | Completion gates | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/references/write-completions.md` | Write completions | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Renderer test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The previous drift check used CSS-selector DOM inspection to verify that a rendered HTML plan matched its spec. This approach was fragile: selector changes in the renderer silently broke the check, and the check itself ran in a separate step that agents could skip.

The `--check` mode embeds the verification in the renderer itself. When called with `--check`, the renderer runs its full rendering pipeline against the spec, produces output in memory, and byte-compares it against the file on disk. A mismatch means the file was hand-edited or the renderer changed without a re-render — either way, the check fails.

For `status: completed` plans, `--check` also verifies spec consistency: every step must be `[x]` and every acceptance criterion must be `- [x]`. This catches plans marked completed in frontmatter but with unchecked steps in the body.

Determinism required fixing one subtle issue: the output path (from which the plan's canonical path is derived) must not be normalized away. The renderer now derives `plan-file` and `plan-path` from the output path argument rather than from any `os.path.basename` normalization, so two runs on the same file always produce identical bytes.

The PASS/FAIL table gives agents a structured signal: each row names what failed, so the fix is unambiguous. The `completion-gates.md` and `write-completions.md` references were updated to invoke `--check` directly, replacing prose instructions about what to grep for.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
