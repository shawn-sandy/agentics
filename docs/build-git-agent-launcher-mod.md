# Build the git-agent-launcher mod plugin

> Ships `kit/plugins/git-agent-launcher` 0.1.0, the kit's first mod: a Claude Code pane listing every git-agent skill and command, where pressing an entry fills its slash command into the prompt without running it.

<!-- generated:start -->

**Status:** Shipped 2026-10-10  **Plan:** [build-git-agent-launcher-mod.md](plans/build-git-agent-launcher-mod.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent-launcher` as a standalone Claude Code mod plugin (requires Claude Code 2.1.287+).
- `/git-agent-launcher` command opens a `focus: true` pane listing all 13 git-agent skills and commands; pressing an entry stages `/git-agent:<name> ` in the prompt (fill-not-run safety decision — a misclick can never commit or push).
- Draft-preserving fill: a press prepends the command to any existing draft, dropping a leading `/git-agent:` prefix if one was already staged.
- Text-listing fallback for non-drawing surfaces (`claude -p`, VS Code chat panel) when `isPlaced` is false.
- Added `tests/plugins/test-mod-plugins.sh` — validates and tests every mod plugin in the kit; prints `SKIP (claude < 2.1.287)` when the CLI is absent or old.
- Registered the plugin in `.claude-plugin/marketplace.json` at 0.1.0 with tags `mod`, `launcher`, `pane`, `git-agent`.
- Updated `scripts/build-readme-table.mjs` to count `hooks/hooks.json` modules as `mod` components.
- Added `tests/publish/test-dist-drops-mod-types.mjs` to pin that `build-dist.mjs` drops the engine-laid `.claude-plugin/types/` folder.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent-launcher/.claude-plugin/plugin.json` | Plugin manifest (no version key) | Created |
| `kit/plugins/git-agent-launcher/hooks/hooks.json` | Hooks module declaration | Created |
| `kit/plugins/git-agent-launcher/hooks/register.tsx` | Command registration, pane, fill-on-press | Created |
| `kit/plugins/git-agent-launcher/hooks/register.test.ts` | Six regression cases on both surfaces | Created |
| `kit/plugins/git-agent-launcher/README.md` | Floor, prerequisite, install, trust contract | Created |
| `kit/plugins/git-agent-launcher/CHANGELOG.md` | 0.1.0 entry | Created |
| `tests/plugins/test-mod-plugins.sh` | Validate + test every mod plugin | Created |
| `docs/guides/how-to/git-agent-launcher.md` | How-to guide | Created |
| `.claude-plugin/marketplace.json` | Plugin registered at 0.1.0 | Modified |
| `scripts/build-readme-table.mjs` | Counts hooks modules as `mod` component | Modified |

## How it works

A Phase 0 spike confirmed the exact format `$.command.list()` returns for git-agent entries: all 13 entries carry `plugin: 'git-agent'`, which the pane uses as its sole filter (the name-prefix fallback proposed in the design was dropped). The `session.attach`/`session.detach` hooks track drawing surfaces by `clientId` so a session that loses its last client falls back to the text listing.

`register.tsx` registers the `/git-agent-launcher` command on `session.start`. When the command runs, it calls `$.ui.open({ focus: true, closeOnEscape: true })`; when `isPlaced` is false it returns a text listing of every `/git-agent:<name>` with its description instead.

The pane body reads `$.command.list()` on each `ui.render`, filters by `plugin === 'git-agent'`, and draws one `Button` row per entry — the unprefixed name as label (digit hotkeys 1–9 on the first nine entries), description text wrapped to `bodyColumns`. An empty filtered list draws a single install hint.

On press, the handler calls `$.prompt.read()`, strips any leading `/git-agent:<name> ` from the existing draft, then calls `$.prompt.fill({ text: '/git-agent:' + name + ' ' + cleanDraft, mode: 'replace' })`. When `isFilled` is false, a toast names the command. The pane stays open after a fill (Phase 0 showed the fill hands focus back automatically).

Phase 0 also confirmed the Desktop composer accepts `$.prompt.fill` despite the types' `no_composer` note, so no `$.ui.copy` fallback was needed.

`tests/plugins/test-mod-plugins.sh` runs `claude plugin validate --json` (failing on errors, ignoring the missing-version warning that the repo's no-version rule makes permanent) and `claude plugin test` for each `kit/plugins/*/hooks/hooks.json`.

> See [CHANGELOG v0.1.0](../kit/plugins/git-agent-launcher/CHANGELOG.md) for the authoritative feature list.

## How to use it

Install the plugin from the agentics marketplace:

```
/plugin install git-agent-launcher@agentics-kit
```

Then open the launcher:

```
/git-agent-launcher          # opens the pane (terminal or Desktop)
```

Press any entry to stage its slash command. Press a second entry over an existing draft to swap commands while preserving your typed arguments.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |

<!-- generated:end -->

## References

- Plan: [build-git-agent-launcher-mod.md](plans/build-git-agent-launcher-mod.md)
- Related: [kit/plugins/git-agent-launcher/README.md](../kit/plugins/git-agent-launcher/README.md)
- Related: [docs/guides/how-to/git-agent-launcher.md](guides/how-to/git-agent-launcher.md)
