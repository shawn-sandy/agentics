---
status: completed
created: 2026-05-14
type: artifact
---

# Plan: Optimize plan-to-html Skill Performance

## Objective

Reduce the time the `plan-to-html` skill takes to generate HTML output. The
main bottleneck is Step 5: the LLM must re-derive ~300 lines of CSS and ~60
lines of JavaScript from `html-spec.md` on every single run. Add a setup cache
and a background mode to eliminate interactive round-trips.

## Context

The skill has three sources of latency:

1. **Step 5 synthesis cost** — the LLM re-reads the 578-line `html-spec.md`
   spec and generates a ~500-800 line HTML file from scratch each run.
2. **Interactive prompts** — three `AskUserQuestion` calls (theme, overwrite,
   browser-open) block execution; `--theme` and `--no-open` already bypass two
   of them, but the overwrite check had no bypass.
3. **TodoWrite overhead** — seven todos are created on every run, even for
   one-line batch invocations.

## Steps

1. Add `--setup` flag (Step 0.5 in SKILL.md)  
   Writes pre-built `~/.claude/plan-to-html/themes.css` and `scripts.js` to
   disk. Future runs read these files directly, eliminating CSS/JS re-synthesis.

2. Add CSS/JS cache check to Step 5  
   Before generating HTML, glob-check whether cached files exist. If they do,
   read and embed verbatim; if not, fall back to deriving from html-spec.md.

3. Add `--background` flag (Step 1 flag parsing + Steps 3, 4, 6)  
   Fully non-interactive mode: auto-selects `default` theme, auto-overwrites
   existing output, implies `--no-open`. Eliminates all three blocking prompts.

4. Update `commands/plan-to-html.md`  
   Document all four flags (`--setup`, `--background`, `--theme`, `--no-open`)
   with usage examples.

5. Bump version to 1.20.0, update CHANGELOG.md, update marketplace.json.

## Verification

- `--setup` creates `~/.claude/plan-to-html/themes.css` and `scripts.js`
- Running the skill after `--setup` reads cached files (no CSS re-derivation)
- `--background` flag suppresses all three interactive prompts
- `--background --theme=developer` selects developer theme non-interactively
- Existing `--theme` and `--no-open` flags still work unchanged

## Performance Recommendations (future work)

The following improvements would yield further speedups but are out of scope
for this change:

- **Pre-built HTML template**: Store `reference/template.html` with `{PLACEHOLDER}`
  tokens. Step 5 reads the template and substitutes content rather than
  synthesizing the full document structure from scratch. Estimated 40-60%
  reduction in Step 5 generation time.
- **Split html-spec.md**: Move CSS/JS spec to separate `reference/styles.css`
  and `reference/scripts.js` files. The skill reads them directly instead of
  deriving from a spec document.
- **Skip TodoWrite in background mode**: Seven todo items add a round-trip on
  every run. Suppress them when `--background` is active.
- **Lazy reference reads**: Only read `html-spec.md` sections actually needed
  for the current plan (e.g., skip the Steps spec if the plan has no Steps
  section).
