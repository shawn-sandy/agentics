---
status: todo
type: feature
created: 2026-05-27
repo-name: agentics
---

# Plan: Create plan-mode plugin

## Context

The user maintains a global Plan Mode rule at `~/.claude/rules/plan-mode.md`
(backed up at `shawn-sandy/claude-settings-backup/rules/plan-mode.md`). It is a
behavioral *rule* — always loaded into context — that defines the full planning
workflow (§0 Assess → §7 Status), the required plan structure, a writing style,
and a `verb-target` filename convention enforced by a `PostToolUse` hook
(`~/.claude/hooks/validate-plan-filename.py`). It also references a `SKELETON.md`
template and `/plan-status` for status automation.

The user wants this packaged as a distributable **plugin** in the `agentics-kit`
marketplace so installers — not just this machine — get the planning conventions
and the filename guardrail.

**Why a plugin can't be a 1:1 port.** Claude Code plugins ship only commands,
skills, agents, and hooks — none of which inject always-on text into context the
way `.claude/rules/*.md` does. So the rule splits into two halves:

| Source artifact | Plugin vessel | Fidelity |
|---|---|---|
| Workflow §0–§7 + Required Structure + Writing Style | **skill** `authoring-plans` (auto-activates on planning intent) | Partial — activates on intent, not "always during plan mode" |
| `reference/SKELETON.md` | bundled skill reference file | Full |
| `validate-plan-filename.py` (§4 enforcement) | **plugin hook** (`hooks/` script + `Write\|Edit` matcher) | Full |
| `/plan-status` (§7) | already exists as `plan-interview:plan-status` | Reuse via optional cross-plugin reference |

Per the user's decisions: a **new dedicated `plan-mode` plugin**, the rule as an
**auto-activating skill**, and **the filename hook ported in**.

## Objective

Create a new `kit/plugins/plan-mode/` plugin that ships the Plan Mode authoring
conventions as an auto-activating `authoring-plans` skill (with bundled
`SKELETON.md`) and ports `validate-plan-filename.py` as an automatic
`PostToolUse` hook, then register it in the `agentics-kit` marketplace.

## Steps

1. **Scaffold the plugin and manifest.** Create `kit/plugins/plan-mode/` with
   `.claude-plugin/plugin.json`. Match the field shape of
   `kit/plugins/plan-interview/.claude-plugin/plugin.json`: `name: "plan-mode"`,
   `description`, `author: {name: "Agentics Project"}`, `license: "MIT"`,
   `keywords`, `homepage:
   "https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/plan-mode"`,
   `repository`. **Do NOT add `version`** (lives in `marketplace.json` for
   relative-path plugins).
   - *Why:* The manifest is the only required plugin file; matching the existing
     shape keeps the marketplace consistent and avoids the `version`-in-both
     pitfall called out in `marketplace.md`.
   - *Verify:* `python3 -c "import json;json.load(open('kit/plugins/plan-mode/.claude-plugin/plugin.json'))"` exits 0 and the output has `name` but no `version`.

2. **Write `skills/authoring-plans/SKILL.md`** — the rule as a skill. Frontmatter:
   `name: authoring-plans`; three-part `description` per `plugin-patterns.md`
   (≤80-char short desc + capability + "Use when the user drafts, structures, or
   writes an implementation plan"); `allowed-tools: Read, Write, Edit, Glob,
   Grep, Bash, AskUserQuestion, TodoWrite, ToolSearch, ExitPlanMode`. Body =
   the full content of `plan-mode.md`: **When to plan**, **Workflow §0–§7**,
   **Required Structure**, **Writing Style**, **Skeleton** (point to
   `reference/SKELETON.md`, one level deep). Adapt three references for the
   plugin context: (a) §4 cites the bundled hook
   `${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py` instead of the
   `~/.claude/` path; (b) §7 references `plan-interview:plan-status` as an
   *optional* cross-plugin helper (no hard dependency); (c) add the deferred-tool
   bootstrap note required by `skill-authoring.md` — "`ExitPlanMode` is deferred;
   `ToolSearch` with `select:ExitPlanMode` before calling it."
   - *Why:* The skill body *is* the behavioral rule; the `description` is what
     makes it activate on planning intent, the closest plugin analogue to an
     always-on rule. The deferred-tool note prevents a mid-skill permission
     prompt (`skill-authoring.md`).
   - *Verify:* `head -8 SKILL.md` shows valid frontmatter with `name`,
     `description`, `allowed-tools`; body contains all of Workflow §0–§7, Required
     Structure, Writing Style; body is < 500 lines.

3. **Add `skills/authoring-plans/reference/SKELETON.md`.** Copy the plan skeleton
   verbatim from `~/.claude/rules/reference/SKELETON.md` (Context, Objective,
   Steps with per-step *Why*/*Verify*, Acceptance Criteria, Verification, Next
   Steps, Unresolved Questions).
   - *Why:* §2/§Skeleton of the rule tells authors to copy this as the starter for
     every plan; bundling it keeps the reference one level deep from `SKILL.md`
     (skill-authoring rule).
   - *Verify:* The file exists, begins with `# Plan: <title>`, and contains the
     `## Steps` and `## Acceptance Criteria` sections.

4. **Port `hooks/validate-plan-filename.py`.** Copy the script from
   `~/.claude/hooks/validate-plan-filename.py` (pure Python-3 stdlib — portable
   as-is) with these adaptations: (a) in `_get_plans_dir()`, read the **project**
   `.claude/settings.json` (cwd-relative) for `plansDirectory` first, then fall
   back to `~/.claude/settings.json`, then the existing `docs/plans` default — so
   the hook honors the installer's *current* project config, not their global
   one; (b) update the stderr citation from "plan-mode.md §4" to "plan-mode
   plugin authoring-plans (§4)" so the message is self-consistent for installers.
   Keep the exit-2 `PostToolUse` contract, the `status: completed` skip, the
   `verb-target` `classify_filename()` logic, and the verb/stop-word lists intact.
   - *Why:* The validation logic is the whole value; only the settings-path
     resolution is machine-specific and must be generalized for distribution.
   - *Verify:* Hook exits 2 for bad filenames, exits 0 for valid ones (tested with
     absolute paths as the harness sends them).

5. **Create `hooks.json`** registering the hook as `PostToolUse` matcher
   `Write|Edit` with command `python3 "${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py"`
   and `timeout: 5`, mirroring the `${CLAUDE_PLUGIN_ROOT}` pattern used in
   `kit/plugins/skill-reviewer/hooks.json`.
   - *Why:* `hooks.json` is how a plugin registers event hooks;
     `${CLAUDE_PLUGIN_ROOT}` is the only portable way to reference the bundled
     script path across install locations.
   - *Verify:* `python3 -c "import json;json.load(open('kit/plugins/plan-mode/hooks.json'))"` exits 0; the command string contains `${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`.

6. **Write `README.md` and `CHANGELOG.md`.** README follows the
   `plugin-patterns.md` structure (Overview, Features, Installation, Usage,
   Plugin Structure tree, Components) documenting the `authoring-plans` skill and
   the filename hook, and noting the optional `plan-interview:plan-status`
   pairing. `CHANGELOG.md` gets an initial `0.1.0` entry.
   - *Why:* `plugin-patterns.md` requires every plugin to ship a structured
     README; the CHANGELOG entry is mandated by `marketplace.md`'s versioning
     procedure.
   - *Verify:* Both files exist; README has the six required sections; CHANGELOG
     has a `0.1.0` heading dated `2026-05-27`.

7. **Register in `marketplace.json`.** Add a `plan-mode` entry to the `plugins`
   array (`source: git-subdir`, `url:
   "https://github.com/shawn-sandy/agentics.git"`, `path:
   "kit/plugins/plan-mode"`, `version: "0.1.0"`, `category: "productivity"`,
   relevant `tags`). Bump the top-level marketplace `version` `3.7.0` → `3.8.0`
   (adding a plugin = MINOR).
   - *Why:* A plugin is only discoverable/installable once registered; the
     metadata version bump records the marketplace change per `marketplace.md`.
   - *Verify:* `python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print(d['version'], len(d['plugins']), [p['name'] for p in d['plugins'] if p['name']=='plan-mode'])"` prints `3.8.0 17 ['plan-mode']`.

8. **Update root `CLAUDE.md`.** Change "16 plugins in the marketplace
   (`agentics-kit` v3.7.0)" → "17 plugins … v3.8.0" and add a `plan-mode` row to
   the Reference Implementations table (Type: Skills + Hooks; note: auto-activating
   plan-authoring conventions + automatic `verb-target` filename hook).
   - *Why:* `CLAUDE.md` is the canonical plugin inventory; leaving it stale
     contradicts the "always update docs" project convention.
   - *Verify:* `grep -c "plan-mode" CLAUDE.md` ≥ 1 and the count/version line reads
     "17 plugins" / "v3.8.0".

## Acceptance Criteria

- [x] `kit/plugins/plan-mode/` exists with `.claude-plugin/plugin.json` (has
      `name`, no `version`), `skills/authoring-plans/SKILL.md`,
      `skills/authoring-plans/reference/SKELETON.md`,
      `hooks/validate-plan-filename.py`, `hooks.json`, `README.md`, `CHANGELOG.md`.
- [x] The `authoring-plans` skill carries the complete Plan Mode workflow
      (§0–§7), Required Structure, and Writing Style, and references its bundled
      `SKELETON.md`.
- [x] The hook rejects non-`verb-target` plan filenames (exit 2) and passes valid
      ones (exit 0), skipping `status: completed` plans, with `plansDirectory`
      resolved from the project's `.claude/settings.json` first.
- [x] `marketplace.json` lists `plan-mode` at `0.1.0`, total 17 plugins, metadata
      version `3.8.0`, and remains valid JSON.
- [x] Root `CLAUDE.md` reflects 17 plugins / v3.8.0 with a `plan-mode` table row.
- [x] No existing plugin (especially `plan-interview`) is modified.

## Verification

1. **Static validation:** run the per-step `Verify` commands; all manifests parse
   as JSON and the SKILL.md frontmatter is well-formed.
2. **Hook behavior (end-to-end):**
   - Bad name with absolute path → exit 2 with rename message.
   - Valid `verb-target` name → exit 0, silent.
   - `status: completed` plan with bad name → exit 0 (skip).
3. **Live plugin load:** `claude --plugin-dir ./kit/plugins/plan-mode`, then
   confirm the `authoring-plans` skill is listed and the `Write|Edit` hook is
   registered; write a badly-named file under `docs/plans/` and confirm the hook
   surfaces the rename feedback.
4. **Skill quality gate:** run `/skill-reviewer:reviewing-skills` on
   `authoring-plans` and address any blocking findings.

## Next Steps *(optional)*

- Add a `/plan-mode` explicit command alongside the auto-activating skill:
  ```text
  In kit/plugins/plan-mode, add commands/plan-mode.md that loads the authoring-plans
  conventions on demand (for cases where the skill doesn't auto-activate). Reuse the
  same SKELETON reference. Bump plan-mode to 0.2.0 (MINOR) in marketplace.json, add a
  CHANGELOG entry, and update the README Features section.
  ```

- Reconcile overlap with plan-interview's filename tooling:
  ```text
  The plan-mode plugin's validate-plan-filename hook (automatic) and
  plan-interview's /plan-hygiene command (manual, interactive) both enforce
  verb-target plan filenames. Audit for conflicting or duplicated behavior when both
  plugins are installed, and document in both READMEs how they complement each other
  (hook = instant per-write feedback; plan-hygiene = bulk cleanup + rename + HTML
  regeneration).
  ```
