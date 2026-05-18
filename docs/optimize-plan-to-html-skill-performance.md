# Optimize plan-to-html Skill Performance

> Adds a `--setup` cache that pre-builds CSS/JS assets and a `--background` flag for fully non-interactive execution, eliminating the main latency sources in the `plan-to-html` skill.

<!-- generated:start -->

**Status:** Shipped 2026-05-14  **Plan:** [optimize-plan-to-html-skill-performance.md](plans/optimize-plan-to-html-skill-performance.md)
**Type:** artifact

## What shipped

- Added `--setup` flag (Step 0.5 in SKILL.md) that writes pre-built `~/.claude/plan-to-html/themes.css` and `scripts.js` to disk, eliminating CSS/JS re-synthesis on every run (the main bottleneck was the LLM re-deriving ~300 lines of CSS and ~60 lines of JS from the 578-line `html-spec.md` spec on each invocation).
- Added CSS/JS cache check to Step 5: before generating HTML, the skill glob-checks whether the cached files exist; if they do, it reads and embeds them verbatim; if not, it falls back to deriving from `html-spec.md`.
- Added `--background` flag for fully non-interactive mode — auto-selects `default` theme, auto-overwrites existing output, and implies `--no-open`, eliminating all three blocking `AskUserQuestion` prompts.
- Updated `commands/plan-to-html.md` to document all four flags (`--setup`, `--background`, `--theme`, `--no-open`) with usage examples.
- Bumped the `plan-interview` plugin version to `1.20.0` and updated `CHANGELOG.md` and `marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/commands/plan-to-html.md` | Command wrapper | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

The `plan-to-html` skill converts Markdown plan files into styled HTML reports. Before this change, every run incurred three sources of latency: the LLM re-reading the full `html-spec.md` specification and synthesizing a fresh CSS/JS bundle from scratch; three sequential `AskUserQuestion` prompts (theme selection, overwrite confirmation, browser-open choice) that blocked execution; and seven `TodoWrite` calls on every invocation, including lightweight one-line batch runs.

The `--setup` flag addresses the most expensive source. When invoked, Step 0.5 runs once and writes two static asset files — `~/.claude/plan-to-html/themes.css` and `~/.claude/plan-to-html/scripts.js` — to the user's home directory. These files contain the complete pre-built CSS theme definitions and JavaScript the skill would otherwise derive from `html-spec.md` at runtime.

On subsequent runs, Step 5 performs a glob check for these cache files before entering the HTML generation path. If both files are present, their contents are read and embedded verbatim into the output HTML, skipping the spec-synthesis step entirely. If the cache is absent (first run without `--setup`, or after a cache clear), the skill falls back to the existing spec-derivation path — ensuring backward compatibility.

The `--background` flag addresses the interactive-prompt latency. When set, it collapses the three blocking questions: theme defaults to `default`, the overwrite check is bypassed (existing output is overwritten), and browser launch is suppressed. This makes the skill suitable for use in batch workflows, CI pipelines, or as a downstream action called by other skills — for example, as a final step in a plan-review workflow that wants to emit an HTML report without user interaction.

The existing `--theme` and `--no-open` flags continue to work unchanged as finer-grained controls. `--background` is additive: `--background --theme=developer` picks the developer theme non-interactively.

## How to use it

One-time setup to pre-build the CSS/JS cache:

```bash
# In a Claude Code session with the plan-interview plugin loaded:
/plan-interview:plan-to-html --setup
```

Normal use after setup (reads from cache, no spec re-derivation):

```bash
/plan-interview:plan-to-html docs/plans/my-plan.md
```

Non-interactive batch use:

```bash
/plan-interview:plan-to-html docs/plans/my-plan.md --background
/plan-interview:plan-to-html docs/plans/my-plan.md --background --theme=developer
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `eadc0ab` | 2026-05-14 | feat(plugins/plan-interview): add --setup cache and --background mode to plan-to-html, bump to v1.20.0 (#115) |

<!-- generated:end -->

## References

- Plan: [optimize-plan-to-html-skill-performance.md](plans/optimize-plan-to-html-skill-performance.md)
