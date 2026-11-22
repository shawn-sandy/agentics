# Build the git-agent-launcher mod plugin

> The kit's first mod gives git-agent a clickable surface, so nobody has to remember thirteen /git-agent:<name> spellings — and because a press only stages text in the prompt, a misclick can never commit or push.

<!-- generated:start -->

**Status:** Shipped 2026-10-09 **Plan:** [build-git-agent-launcher-mod.md](plans/build-git-agent-launcher-mod.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent-launcher/`: the first mod plugin in the agentics kit. `plugin.json` without a `version` key (version lives only in marketplace.json); `hooks/hooks.json` with `{ "modules": ["./register.tsx"] }`; `hooks/register.tsx` registering `/git-agent-launcher`, opening a `focus: true, closeOnEscape: true` pane, listing git-agent entries filtered by `plugin === 'git-agent'`, filling `$.prompt.fill` on press, falling back to text listing when `isPlaced` is false.
- Added `hooks/register.test.ts`: six regression cases on both terminal and desktop surfaces (filter, fill on empty draft, draft preservation, isFilled-false toast, empty-list install line, isPlaced:false text fallback).
- Added `tests/plugins/test-mod-plugins.sh`: validates + tests every mod plugin; SKIPs below CLI 2.1.287.
- Updated `scripts/build-readme-table.mjs`: counts `hooks/hooks.json` modules as a `mod` component.
- Registered in `.claude-plugin/marketplace.json` at 0.1.0 (category `development`, tags `mod`, `launcher`, `pane`, `git-agent`).
- Added `docs/guides/how-to/git-agent-launcher.md` and updated floor notes in `README.md` and `CLAUDE.md` (Claude Code 2.1.287+).
- Fixed `scripts/build-dist.mjs`: drops engine-laid `.claude-plugin/types/` from dist; fixed `tests/publish/test-no-ignored-plugin-files.sh` to allow it; added `tests/publish/test-dist-drops-mod-types.mjs`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent-launcher/.claude-plugin/plugin.json` | Manifest (no version key) | Created |
| `kit/plugins/git-agent-launcher/hooks/hooks.json` | Module registration | Created |
| `kit/plugins/git-agent-launcher/hooks/register.tsx` | Pane, fill-on-press | Created |
| `kit/plugins/git-agent-launcher/hooks/register.test.ts` | Six regression cases | Created |
| `kit/plugins/git-agent-launcher/README.md` | Trust contract and floor | Created |
| `kit/plugins/git-agent-launcher/CHANGELOG.md` | 0.1.0 entry | Created |
| `tests/plugins/test-mod-plugins.sh` | Merge-gate mod validation | Created |
| `docs/guides/how-to/git-agent-launcher.md` | How-to guide | Created |
| `.claude-plugin/marketplace.json` | git-agent-launcher 0.1.0 | Modified |
| `scripts/build-readme-table.mjs` | Mod component counting | Modified |
| `README.md` | Generated table row, floor notes | Modified |
| `CLAUDE.md` | Floor note | Modified |
| `kit/plugins/README.md` | Plugin listed | Modified |
| `scripts/build-dist.mjs` | Drop engine-laid types | Modified |
| `tests/publish/test-no-ignored-plugin-files.sh` | Allow engine-laid types | Modified |
| `tests/publish/test-dist-drops-mod-types.mjs` | Pins the dist drop | Created |

## How it works

The launcher is a thin view over `$.command.list()`. On `/git-agent-launcher`, it opens a `focus: true` pane listing every git-agent skill and command filtered by `plugin === 'git-agent'`. Each entry is a `Button` with the unprefixed name (digit hotkeys 1–9 on the first nine) and a dim description.

A press reads the current prompt draft via `$.prompt.read()`, then calls `$.prompt.fill({ text: '/git-agent:<name> ' + draft, mode: 'replace' })`. A second press drops a leading `/git-agent:<name> ` from the existing draft before adding its own, so prompts do not stack. The pane stays open after a fill because Phase 0 found that the fill returns keyboard focus to the prompt box by itself.

Surfaces that cannot draw (`claude -p`, VS Code chat panel) receive a text listing of all 13 entries instead.

## How to use it

Requires Claude Code 2.1.287+ and git-agent installed:

```
/plugin install git-agent-launcher@agentics-kit
```

Then type `/git-agent-launcher` to open the pane. Press an entry to stage its command in the prompt. Press Enter to run it.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d9fdb0ba` | 2026-10-09 | feat: git-agent-launcher mod — clickable pane for all 13 git-agent skills (0.1.0) (#648) |

<!-- generated:end -->

## References

- Plan: [build-git-agent-launcher-mod.md](plans/build-git-agent-launcher-mod.md)
