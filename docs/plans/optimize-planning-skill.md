---
status: todo
type: refactor
created: 2026-05-30
repo-name: agentics
---

# Plan: Optimize the plan-agent `planning` SKILL.md

> **Filename note:** the harness created this file as `abundant-jingling-pebble.md` (a random slug). Per the plan-agent §4 Rename rule it must be renamed to a `verb-target` name — `optimize-planning-skill.md` — before commit. The plan-agent skill normally emits HTML; this markdown form is a plan-mode constraint (only this `.md` file is editable during planning). Convert to HTML on commit if HTML parity is desired.

## Context

**Root cause (headline):** the `planning` skill opens with an `## Enter plan mode` section that calls `EnterPlanMode` and closes with `ExitPlanMode`. This **contradicts the skill's own "When to plan" rule** ("When a skill/slash-command requires write operations (filesystem, migrations), do not enter plan mode. Execute directly") — and authoring a plan file *is* a filesystem write. The handshake hands control to the harness plan-mode workflow, which overrides the skill's two core guarantees: it forces markdown output to a fixed random-slug path instead of the skill's `SKELETON.html` + `verb-target` filename. This session is the proof: invoking the skill produced `abundant-jingling-pebble.md` (markdown, random slug) and the `validate-plan-filename` hook rejected the name. The fix is to remove the plan-mode handshake so the skill writes its HTML plan directly and presents it.

A scored audit of `kit/plugins/plan-agent/skills/planning/SKILL.md` (run this session via `skill-reviewer:reviewing-skills`) graded it **7/10 — Good**, with four warnings and four suggestions. Direct verification against the plugin README and `reference/` skeleton files refined those findings:

- **Real and high-value:** the `--template` flag advertises `minimal|adr|spike` variants in `argument-hint` and §2, but only `default` is implemented. The three `SKELETON-*.md` variant files are **markdown with YAML frontmatter**, which directly violates the skill's own hard rule "**Always write HTML — never write markdown for plan output.**" The README (line 70) is already correct ("Reserved — only `default` is currently supported"); the SKILL.md contradicts both the README and itself.
- **Real:** an H1 (`# Plan Agent — Planning`) inside the body where best practices reserve H1 for the frontmatter `name`; a dead `TodoWrite` entry in `allowed-tools` that the workflow never uses (every listed tool risks a permission prompt); no stated freedom level for a process-critical sequential skill.
- **Refined down:** the audit's `$ARGUMENTS` warning is overstated — README line 195 documents `$ARGUMENTS` use and this session's own invocation proves substitution works for command-invoked skills. Since `planning` is `disable-model-invocation` (only ever invoked as `/plan-agent:planning`), `$ARGUMENTS` is correct here. At most this needs a one-line clarifying note.
- **Polish:** the description trigger describes invocation syntax rather than user intent and lacks a scope-exclusion line; the "Enter plan mode" section sits outside the §0–§7 numbering and a reader can miss it.

Goal: apply the verified fixes so the skill is internally consistent, free of dead/contradictory instructions, and scores higher on structure and discoverability — without changing the §0–§7 workflow behavior.

## Objective

Tighten `planning/SKILL.md` so its template story matches the README and the HTML-only rule, remove dead and hierarchy-violating content, state its freedom level, and sharpen the frontmatter description — leaving the seven-step planning workflow behaviorally unchanged.

## Files to modify

- `kit/plugins/plan-agent/skills/planning/SKILL.md` — primary target (frontmatter + body edits).
- `kit/plugins/plan-agent/skills/planning/reference/SKELETON-adr.md`, `SKELETON-minimal.md`, `SKELETON-spike.md` — delete (markdown variants that contradict the HTML-only rule); `SKELETON.html` is the only supported skeleton.
- `kit/plugins/plan-agent/CHANGELOG.md` — add an entry.
- `.claude-plugin/marketplace.json` — bump the `plan-agent` `version` (MINOR per repo convention: behavior-neutral content + removal of advertised flag values).

## Steps

1. **Resolve the `--template` inconsistency to match the README.** In `SKILL.md`: trim the `argument-hint` `--template` token to `default` only; in §2's flag list and the `## Skeleton` section, document `minimal|adr|spike` as "planned — not yet implemented"; state that `SKELETON.html` is the only supported skeleton. Then delete the three `SKELETON-*.md` variant files.
   - *Why:* The markdown variants violate the skill's "always write HTML" mandate and the flag advertises capability that does not exist; aligning to the already-correct README removes the contradiction at the source.
   - *Verify:* `grep -n "minimal|adr|spike" SKILL.md` shows only "planned"/reserved framing (no functional claim); `ls reference/` lists only `SKELETON.html`; README line 70 and SKILL.md now agree.

2. **Fix the body heading hierarchy.** Change `# Plan Agent — Planning` (line 9) to `## Plan Agent — Planning`.
   - *Why:* Best practices reserve H1 for the frontmatter `name`; the body should start at H2 so heading levels are not skipped.
   - *Verify:* No `^# ` (single-hash) line remains in the body; the file's top heading is `## `.

3. **Prune `allowed-tools` to only what the plan-mode-free workflow uses.** After Step 6 removes the plan-mode handshake, delete `EnterPlanMode`, `ExitPlanMode`, and `ToolSearch` (only needed to load those deferred tools) from the frontmatter `allowed-tools` line. Also delete the never-used `TodoWrite`. Confirm whether `Grep` is referenced — if not, remove it. Target final set: `Read, Write, Edit, Glob, Bash, AskUserQuestion, Skill` (all referenced; `Skill` for `--interview`).
   - *Why:* Every declared tool can trigger a permission prompt; with plan mode gone, the deferred-tool machinery (`EnterPlanMode`/`ExitPlanMode`/`ToolSearch`) is dead weight, and `TodoWrite` was never invoked.
   - *Verify:* For each remaining tool, `grep` finds at least one referencing instruction in the body; `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, and `TodoWrite` are all absent.

4. **State the freedom level.** Add "Follow these steps exactly." at the top of the `## Workflow` section.
   - *Why:* For a process-critical sequential skill that enforces naming, HTML structure, and status sync, an explicit rigidity signal prevents Claude from skipping guardrails (default is "flexible").
   - *Verify:* The `## Workflow` section opens with the rigidity statement before step §0.

5. **Rewrite the frontmatter `description` for intent + scope.** Keep a capability statement, replace the invocation-syntax trigger with user-intent phrasing, and add a scope-exclusion sentence. Draft: `"Creates a structured, self-contained HTML implementation plan from a stated objective — enforcing verb-target filenames, required sections, and HTML metadata. Use when the user wants to turn an objective into a detailed plan via /plan-agent:planning. Does not review or modify existing plans — for that use plan-interview:plan-interview."`
   - *Why:* The description is what a reader scans in the command list; intent + scope communicates purpose and reduces collision risk. Safe to change because `disable-model-invocation` means no auto-activation behavior depends on the old wording.
   - *Verify:* `description` ≤1024 chars, third person, contains a "Use when…" clause, a capability statement, and a scope-exclusion sentence; re-running `skill-reviewer:reviewing-skills` scores Discoverability 2/2.

6. **Remove the plan-mode handshake (ROOT CAUSE).** Delete the entire `## Enter plan mode` section and the top "Deferred tools" callout. In §0 Assess, remove the `ToolSearch`→`ExitPlanMode` bootstrap and reword it to "if the request is trivial, apply the change directly without authoring a plan document." Delete the closing "Then use `ToolSearch` with `select:ExitPlanMode` and call `ExitPlanMode`…" line; replace it with: write the HTML plan file directly, then present its path and offer to open it. The `--interview` `Skill` call stays but no longer sits between two `ExitPlanMode` references. Net effect: the skill executes its write directly — honoring its own "When to plan → do not enter plan mode for write operations" rule — and keeps full control of HTML output and the `verb-target` filename.
   - *Why:* Calling `EnterPlanMode` cedes the skill's two core guarantees (HTML output, verb-target naming) to the harness, which forces markdown to a random-slug path. Removing the handshake is the only fix that restores the skill's output contract; folding the section in (the earlier idea) would preserve the bug.
   - *Verify:* `grep -n "EnterPlanMode\|ExitPlanMode" SKILL.md` returns nothing; a fresh `/plan-agent:planning <objective>` run writes a `.html` file with a `verb-target` name and never enters plan mode.

7. **Add a one-line `$ARGUMENTS` clarifying note (optional, low priority).** In the "Invocation & Arguments" section, note that `$ARGUMENTS` substitution works because this skill is command-invoked (`disable-model-invocation`), pre-empting the generic "skills can't use $ARGUMENTS" flag.
   - *Why:* Documents why the command-only construct is valid here, so future audits and editors don't "fix" a working mechanism.
   - *Verify:* The note appears once near the `$ARGUMENTS` reference; no behavioral change to argument parsing.

8. **Bump version + changelog.** Add a `CHANGELOG.md` entry summarizing the optimization and bump the `plan-agent` `version` in `.claude-plugin/marketplace.json` (MINOR — flag surface narrowed, skeleton variants removed).
   - *Why:* Repo convention requires a marketplace version bump + changelog entry for any skill/flag-surface change, committed with the change.
   - *Verify:* `marketplace.json` validates (auto-hook on save); CHANGELOG top entry matches the new version; new version string is `X.Y.0`.

9. **Re-audit and rename the plan file.** Re-run `skill-reviewer:reviewing-skills` on the edited SKILL.md to confirm ≥9/10; rename this plan from `abundant-jingling-pebble.md` to `optimize-planning-skill.md` before commit.
   - *Why:* Closes the loop on the audit and satisfies the plan-agent §4 Rename rule (random slug → verb-target).
   - *Verify:* Audit grade is "Excellent" (9–10); plan file is named `optimize-planning-skill.md`; the `validate-plan-filename` hook passes on the new name.

## Acceptance Criteria

- [ ] `SKILL.md` `argument-hint` lists only `--template default`; `minimal|adr|spike` are described as planned/not-implemented.
- [ ] The three `reference/SKELETON-*.md` files are deleted; `reference/` contains only `SKELETON.html`.
- [ ] No H1 (`# `) heading remains in the SKILL.md body.
- [ ] `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, and `TodoWrite` are removed from `allowed-tools`; every remaining declared tool is referenced by at least one instruction.
- [ ] No `EnterPlanMode`/`ExitPlanMode` reference remains anywhere in `SKILL.md`; the `## Enter plan mode` section and "Deferred tools" callout are gone.
- [ ] A fresh `/plan-agent:planning <objective>` run writes a `verb-target` `.html` file directly and never enters harness plan mode.
- [ ] `## Workflow` states "Follow these steps exactly."
- [ ] The frontmatter `description` contains a capability statement, a user-intent "Use when…" trigger, and a scope-exclusion sentence; it stays ≤1024 chars and third-person.
- [ ] `marketplace.json` `plan-agent` version is bumped (MINOR) and a matching `CHANGELOG.md` entry exists.
- [ ] Re-running `skill-reviewer:reviewing-skills` scores ≥9/10 with no error- or warning-level findings.
- [ ] The §0–§7 workflow behavior is unchanged (no step added, removed, or reordered in a way that alters output).

## Verification

1. **Static read-through:** open the edited `SKILL.md` and confirm each acceptance-criteria checkbox by inspection (heading levels, `allowed-tools`, freedom-level line, description shape, template framing).
2. **Filesystem:** `ls kit/plugins/plan-agent/skills/planning/reference/` returns only `SKELETON.html`.
3. **Consistency cross-check:** diff the SKILL.md `--template` framing against README line 70 — they must now agree.
4. **Scored re-audit:** run `/skill-reviewer:reviewing-skills kit/plugins/plan-agent/skills/planning/SKILL.md` and confirm grade "Excellent" (≥9/10), Discoverability and Structure both 2/2, and a clean Regression Risk section (no BREAKING — `name` unchanged; description trigger change is non-breaking because the skill is `disable-model-invocation`).
5. **End-to-end smoke test:** run `/plan-agent:planning add a sample widget --quick` and confirm the skill still produces a valid HTML plan via `SKELETON.html` with no reference to the removed markdown skeletons and no permission prompt for `TodoWrite`.
6. **Hook check:** confirm `validate-plan-filename` passes on the renamed `optimize-planning-skill.md`.

## Next Steps *(optional)*

- Build real HTML template variants (delivers the `--template` feature instead of deprecating it):

  ```text
  In kit/plugins/plan-agent/skills/planning/reference/, create HTML skeleton variants SKELETON-minimal.html, SKELETON-adr.html, and SKELETON-spike.html modeled on the existing SKELETON.html (single self-contained file, inline CSS/JS, status badge, meta tags). Then update planning/SKILL.md §2 and the ## Skeleton section to load the matching SKELETON-<template>.html when --template is minimal|adr|spike, restore those values to argument-hint as functional, and bump the plan-agent version (MINOR) with a CHANGELOG entry. Verify each variant renders standalone in a browser and the validate-plan-filename hook still passes.
  ```

- Sweep sibling skills for the same dead-tool / heading issues:

  ```text
  Audit every SKILL.md under kit/plugins/*/skills/ for the two issues just fixed in plan-agent/planning: (1) tools listed in allowed-tools that no instruction in the body actually references, and (2) an H1 (single-hash) heading inside the body where H2 is expected. Report a table of file → issue → suggested fix. Do not edit anything yet.
  ```

## Unresolved Questions *(optional)*

- Whether to commit this plan as HTML (skill default) or markdown:

  ```text
  The plan-agent skill mandates HTML plan output, but this plan was authored as markdown because plan-mode restricts edits to a single .md file. Decide whether to (a) keep the committed plan as markdown for simplicity, or (b) regenerate it as a self-contained HTML file via the planning skill's SKELETON.html before commit. Recommend one, considering that docs/plans/ in this repo currently mixes both formats.
  ```
