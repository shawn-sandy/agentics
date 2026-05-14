---
status: todo
type: feature
created: 2026-05-14
---

# Plan: Add --async Flag to plan-to-html for True Background Execution

## Context

The `plan-to-html` skill currently runs synchronously on the main thread. Even with the existing `--background` flag (non-interactive foreground mode used by batch callers like `plan-hygiene` and `review-rename-plans`), the main thread is blocked until HTML generation completes.

The user wants to free the main thread — invoking `plan-to-html` and immediately returning while HTML generation continues asynchronously. This requires spawning a background `Agent` that re-invokes the skill with all flags pre-set, so the main session can continue working.

The existing `--background` flag must be preserved as-is: batch callers depend on it for non-interactive foreground execution and need to wait for the HTML before their next step.

## Objective

Add a `--async` flag to `plan-to-html` that, after resolving the plan file and (if needed) asking for the theme in the foreground, spawns a background `Agent` to perform HTML generation, then returns immediately.

## Steps

1. **Add `Agent` to `allowed-tools` in `SKILL.md` frontmatter** — the skill currently cannot call the `Agent` tool, which is required to spawn a background agent. — *Why:* tool calls not listed in `allowed-tools` are blocked by the harness. — *Verify:* open `skills/plan-to-html/SKILL.md` and confirm `Agent` appears in the `allowed-tools` line.

2. **Parse `--async` in Step 1 of the skill** — extend the flag-parsing block alongside `--theme`, `--no-open`, `--background`, and `--setup` to also detect `--async`. Store as a boolean. — *Why:* all flag parsing is consolidated in Step 1 so later steps can branch on it. — *Verify:* re-read Step 1 and confirm `--async` is documented in the flag table.

3. **Handle theme resolution before spawning in Step 3** — if `--async` is set and no `--theme` was provided, ask the theme `AskUserQuestion` in the foreground (same four options as today) before spawning the agent, so the background agent receives a fully-resolved `--theme=<value>` argument. If `--theme` is already present, skip the prompt. — *Why:* the background agent cannot prompt the user; all interactive decisions must be resolved on the main thread first. — *Verify:* the condition tree reads: `if --async and no --theme → prompt now; if --async and --theme → skip prompt; else (no --async) → existing behavior unchanged`.

4. **Add async dispatch block after theme resolution** — immediately after theme is known (step 3), if `--async` is set: call `Agent(run_in_background: true, description: "plan-to-html background conversion", prompt: "Invoke Skill(skill: 'plan-interview:plan-to-html', args: '<resolved-path> --theme=<theme> --no-open --background') to convert the plan to HTML non-interactively.")`. Then output `"Background conversion started: <resolved-path> (theme: <theme>)"` and stop — do not proceed to steps 5–7. — *Why:* the `general-purpose` sub-agent has `Skill` in its tool set, so re-invoking the skill with `--background` (non-interactive foreground mode) inside the agent gives complete, correct HTML generation without duplicating any logic. The `--async` flag is absent from the agent's invocation, preventing recursive spawning. — *Verify:* invoke the skill with `--async`; the main thread returns in seconds with the "Background conversion started" message; the HTML file appears once the agent finishes.

5. **Document `--async` in `commands/plan-to-html.md`** — add `--async` to the flags reference table alongside `--theme`, `--no-open`, `--background`, and `--setup`. — *Why:* the command file is the user-facing reference for all flags. — *Verify:* open `commands/plan-to-html.md` and confirm `--async` is listed with a one-line description.

6. **Update CHANGELOG.md with a v1.22.0 entry** — add a `[1.22.0] - 2026-05-14` section documenting the new flag. — *Why:* this is a minor version bump (new capability, no breaking changes). — *Verify:* `CHANGELOG.md` has a `1.22.0` entry that mentions `--async` and background agent spawning.

7. **Bump version to 1.22.0 in `marketplace.json`** — update the `plan-interview` entry's `"version"` field. — *Why:* marketplace version must match the CHANGELOG entry to keep plugin discovery accurate. — *Verify:* `.claude-plugin/marketplace.json` shows `"version": "1.22.0"` for `plan-interview`.

## Verification

1. Run `/plan-to-html <path-to-any-plan.md> --async` — confirm the main thread returns within a few seconds with `"Background conversion started: ..."`.
2. Run `/plan-to-html <path-to-any-plan.md> --async --theme=developer` — confirm no theme prompt appears and the background agent starts immediately.
3. After the background agent completes, confirm the `.html` file is present and valid (open in browser or check file size > 0).
4. Run `/plan-to-html <path-to-any-plan.md> --background` (existing flag) — confirm behavior is unchanged: non-interactive, synchronous, main thread blocked until done.
5. Verify that `plan-hygiene` and `review-rename-plans` commands still work correctly (they use `--no-open --background`, not `--async`).

## Next Steps

### Phase 2: Propagate `--async` to Callers

Three places in the plugin invoke `plan-to-html` and could benefit from background execution:

1. **`plan-interview` skill Step 2** — after a rename, it offers to generate HTML via `Skill(skill: "plan-interview:plan-to-html", args: "<path> --no-open")`. Add `--async` to this invocation so the rename workflow returns immediately. — *Why:* the rename itself is already done; HTML generation is a nice-to-have side effect, not a blocking dependency. — *Verify:* run a plan rename via `plan-interview`; confirm HTML appears asynchronously without blocking the next step.

2. **`plan-interview` skill Step 6** — the post-summary HTML offer uses the same args pattern. Add `--async` here too. — *Why:* the interview is complete at this point; the user should not wait for HTML before receiving the summary. — *Verify:* complete a `plan-interview` run; confirm the HTML offer resolves in the background.

3. **`review-rename-plans` command Step 5** — invokes `plan-to-html` per renamed file. Add `--async` to allow the rename loop to continue without waiting for each file's HTML. — *Why:* batch rename speed is the priority; HTML generation is a trailing artifact. — *Verify:* rename multiple plans via `review-rename-plans`; confirm all HTML files appear after the command completes rather than blocking each rename.

Update CHANGELOG with a `v1.23.0` entry and bump `marketplace.json` to match.

### Phase 3: Settings-Based Default for Always-Async

Allow users to configure `plan-to-html` to always spawn a background agent without passing `--async` on every call:

1. **Define a settings key** — `plan-to-html.async: true` in `.claude/settings.json` (project-level) or `~/.claude/settings.json` (global). — *Why:* users who always want background execution should not have to remember the flag. — *Verify:* settings key is documented in `commands/plan-to-html.md`.

2. **Read the setting in Step 1** — after parsing explicit flags, check `jq '.["plan-to-html"].async' ~/.claude/settings.json` (and project-level equivalent). If `true` and `--async` is not already set, treat it as if `--async` was passed. — *Why:* explicit flag always takes precedence; the setting is a fallback default. — *Verify:* set the key in global settings, invoke the skill without `--async`, confirm background mode activates.

3. **Update CHANGELOG** with a `v1.24.0` entry (MINOR bump — new capability, no breaking changes) and bump `marketplace.json`.
