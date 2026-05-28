---
status: completed
type: refactor
created: 2026-05-27
repo-name: agentics
---

# Plan: Convert plan-mode into a manual-invoke /plan-agent:author skill

> **Filename note (plan-mode §4):** this file's auto-generated name
> `revire-this-plan-mode-reflective-thacker.md` violates the `verb-target`
> convention. Step 1 renames it to
> **`convert-plan-mode-to-plan-agent-skill.md`**. It is left as-is here only so
> the harness can bind `ExitPlanMode` to this path during planning.

## Context

The `plan-mode` plugin (committed at `fc24ba7` as v0.1.0, on the unmerged branch
`feat/plan-mode-plugin-2026-05-27`) ships an **auto-activating** `authoring-plans`
skill (the full §0–§7 workflow), a bundled `SKELETON.md`, and a
`validate-plan-filename` hook.

The user wants to retire the *ambient* activation model — planning should happen
only on explicit invocation with a free-text objective (e.g.
`/plan-agent:author create a todo app for ravens`) — and rename the plugin to
`plan-agent`.

**Key finding that reshapes the approach.** An earlier draft assumed only a
*command* can take a free-text argument, so it proposed deleting the skill and
re-inlining the entire workflow into a new `commands/author.md`. That assumption
is wrong: a skill with **`disable-model-invocation: true`** is invoked
explicitly as `/<plugin>:<skill>` and reads the same **`$ARGUMENTS`**
placeholder a command does. This is already the pattern `git-agent` uses —
`branch-agent` is `disable-model-invocation: true`, declares `argument-hint`,
reads `$ARGUMENTS` (`kit/plugins/git-agent/skills/branch-agent/SKILL.md:48`),
and even bootstraps a deferred plan-mode tool via `ToolSearch`.

So instead of deleting and rebuilding, we **convert** the existing skill:

- **Rename the plugin** `plan-mode` → `plan-agent` (directory, `name`, install
  id, homepage, marketplace `source` path).
- **Rename the skill** `authoring-plans` → `author` so the explicit invocation
  reads `/plan-agent:author`.
- **Disable model invocation** (`disable-model-invocation: true`) — kills
  ambient activation; the skill runs only when explicitly invoked.
- **Accept a free-text objective + flags** via `$ARGUMENTS` and `argument-hint`.
- **Enter real plan mode** from inside the skill via `EnterPlanMode` (same
  read-only tools + `ExitPlanMode` gate as default plan mode).
- **Keep** the `validate-plan-filename` hook firing on `Write`/`Edit`.
- **Keep** the §0–§7 workflow body essentially as-is — only prepend an
  argument-parse + plan-mode-entry preamble and wire the flags into existing
  steps. `SKELETON.md` moves with the skill directory; no separate relocation.

**Decisions (confirmed via AskUserQuestion + follow-ups):** plugin folder renamed
to `plan-agent`; the explicit name is `author` → `/plan-agent:author`; use the
**skill + `disable-model-invocation`** model (not a separate command, not a
deleted skill); the filename hook stays.

**Breaking-change note.** Renaming the plugin, renaming the skill, and switching
the skill from auto to manual activation are MAJOR-type changes per
`marketplace.md`. The plugin is pre-1.0 and unreleased (unmerged branch), so this
plan bumps `0.1.0 → 0.2.0` with a BREAKING CHANGELOG note rather than forcing
1.0.0 (see Unresolved Questions).

## Objective

Rename `kit/plugins/plan-mode` → `kit/plugins/plan-agent`, rename its
`authoring-plans` skill → `author`, set `disable-model-invocation: true`, and add
`$ARGUMENTS`-based objective + flag parsing plus an `EnterPlanMode` entry — so the
§0–§7 workflow runs on explicit `/plan-agent:author <objective>` invocation
instead of ambient activation. Keep the filename hook intact and bump the plugin
to `0.2.0`.

## Steps

1. **Plan file hygiene.** Run
   `git mv docs/plans/revire-this-plan-mode-reflective-thacker.md docs/plans/convert-plan-mode-to-plan-agent-skill.md`
   and `git rm docs/plans/wobbly-bachman.md` (a 33-byte test artifact from commit
   `fc24ba7`).
   - *Why:* Both names violate the `verb-target` rule the plugin enforces;
     `create-plan-mode-plugin.md` already preserves the prior plan's content.
   - *Verify:* `ls docs/plans/ | grep -E 'revire-this|wobbly-bachman'` returns
     nothing; the renamed plan exists and the hook accepts its name (exit 0).

2. **Rename the plugin directory.** Run
   `git mv kit/plugins/plan-mode kit/plugins/plan-agent`.
   - *Why:* The plugin is renamed to `plan-agent`; `git mv` preserves `--follow`
     history across the rename.
   - *Verify:* `git status` shows the directory renamed (not delete+add);
     `test -d kit/plugins/plan-agent && test ! -d kit/plugins/plan-mode`.

3. **Rename the skill directory** (inside the renamed plugin). Run
   `git mv kit/plugins/plan-agent/skills/authoring-plans kit/plugins/plan-agent/skills/author`.
   This moves both `SKILL.md` and `reference/SKELETON.md` together, keeping the
   skeleton one level deep — no separate relocation needed.
   - *Why:* A skill is invoked as `/<plugin>:<skill-name>`; the directory and
     `name` must be `author` to yield `/plan-agent:author`.
   - *Verify:* `test -d kit/plugins/plan-agent/skills/author`;
     `test -f kit/plugins/plan-agent/skills/author/reference/SKELETON.md`;
     the old `skills/authoring-plans` path no longer exists.

4. **Convert the skill's frontmatter** in
   `kit/plugins/plan-agent/skills/author/SKILL.md`:
   - `name: authoring-plans` → `name: author`.
   - Add `disable-model-invocation: true` (turns off ambient activation).
   - Add `argument-hint: "<objective> [--quick] [--type feature|fix|refactor|docs|chore] [--dir <path>] [--interview]"`.
   - Add `EnterPlanMode` to `allowed-tools` (it already lists `ToolSearch` and
     `ExitPlanMode`); final set:
     `Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite, ToolSearch, EnterPlanMode, ExitPlanMode`.
   - Rewrite `description` (three-part, ≤256 chars) to state it is an explicit
     plan-authoring command taking an objective — e.g. "Authors an implementation
     plan from a free-text objective. Enforces verb-target filenames, required
     structure, and writing style. Use by invoking `/plan-agent:author <objective>`."
   - *Why:* `disable-model-invocation` + `$ARGUMENTS` + `argument-hint` is the
     git-agent manual-invoke pattern; `EnterPlanMode` lets the skill flip the
     session into real plan mode.
   - *Verify:* `head -8 SKILL.md` shows `name: author`,
     `disable-model-invocation: true`, `argument-hint`, and `EnterPlanMode` in
     `allowed-tools`.

5. **Add an argument + plan-mode preamble to the skill body**, before the
   existing `## When to plan` section:
   - **`## Invocation & Arguments`** — Read `$ARGUMENTS`: trailing text is the
     objective; extract flags `--quick`, `--type <kind>`, `--dir <path>`,
     `--interview`. If the objective is empty, ask once via `AskUserQuestion`
     (or stop). **Smart defaults when a flag is absent:** infer `--type` from the
     leading verb (`create`/`add`/`build` → `feature`; `fix`/`repair` → `fix`;
     `refactor`/`rename`/`extract` → `refactor`; `document`/`docs` → `docs`; else
     `chore`); decide Clarify necessity by objective specificity (vague → keep
     Clarify; detailed → treat as `--quick`). Echo the resolved objective +
     effective flags.
   - **`## Enter plan mode`** — Deferred-tool bootstrap: `ToolSearch`
     `select:EnterPlanMode`, then call `EnterPlanMode` (skip if already in plan
     mode). Mirror the existing deferred-tool note already used for
     `ExitPlanMode`.
   - Then wire the flags into the existing §0–§7: §1 Clarify and §5 Align are
     skipped when `--quick` (or a detailed objective); §2 Create uses `--dir` to
     override directory resolution; §3 Frontmatter presets `type` from `--type`.
     Add a `--interview` note in §5/§6: if set, after writing the plan run
     `Skill(skill: "plan-interview:plan-interview", args: "<plan-path>")` (skip
     with a one-line note if that plugin is absent) before the final
     `ExitPlanMode`.
   - *Why:* Keeps the validated §0–§7 body intact while making it explicit-,
     argument-, and flag-driven; the preamble is additive, minimizing risk.
   - *Verify:* body contains `$ARGUMENTS`, `select:EnterPlanMode`,
     `select:ExitPlanMode`, the smart-default verb map, and the four flags; the
     §0–§7 workflow and Required Structure / Writing Style / Skeleton sections
     remain present; body is < 500 lines.

6. **Repoint the hook's stderr citation.** In
   `kit/plugins/plan-agent/hooks/validate-plan-filename.py`, change any stderr
   text citing "authoring-plans" / "plan-mode.md §4" to reference the command
   instead (e.g. "plan-agent `/plan-agent:author` (§4)"). Leave all validation
   logic and `hooks.json` untouched (it uses `${CLAUDE_PLUGIN_ROOT}`, so the
   rename needs no path edit).
   - *Why:* Renaming the skill would otherwise leave the hook citing a component
     name that no longer exists.
   - *Verify:* `grep -n 'authoring-plans' kit/plugins/plan-agent/hooks/validate-plan-filename.py`
     returns nothing; the hook still exits 2 on a bad name, 0 on a valid one.

7. **Update `kit/plugins/plan-agent/.claude-plugin/plugin.json`.** Set
   `name: "plan-agent"`; rewrite `description` to describe the explicit
   `/plan-agent:author` skill + filename hook (drop "auto-activating"); update
   `homepage` to `.../kit/plugins/plan-agent`; refresh keywords (add `plan-agent`,
   `author`, `on-demand`). No `version` field.
   - *Why:* The manifest must reflect the new name and activation model.
   - *Verify:* `python3 -c "import json;d=json.load(open('kit/plugins/plan-agent/.claude-plugin/plugin.json'));print(d['name'], 'version' in d, 'plan-agent' in d['homepage'])"`
     prints `plan-agent False True`.

8. **Update `.claude-plugin/marketplace.json`.** In the former `plan-mode`
   entry: set `name: "plan-agent"`, `source.path: "kit/plugins/plan-agent"`,
   rewrite `description` to match plugin.json, bump `version` `0.1.0` → `0.2.0`,
   refresh tags (add `plan-agent`, `author`). Leave the top-level marketplace
   `version` at `3.8.0` (plugin count unchanged).
   - *Why:* Discovery/install resolve from this entry; the path and name must
     match the renamed directory.
   - *Verify:* `python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));p=[x for x in d['plugins'] if x['name']=='plan-agent'][0];print(d['version'], p['version'], p['source']['path'])"`
     prints `3.8.0 0.2.0 kit/plugins/plan-agent`; no `plan-mode` entry remains.

9. **Add a `0.2.0` CHANGELOG entry** in
   `kit/plugins/plan-agent/CHANGELOG.md` dated `2026-05-27`:
   **Changed (BREAKING)** — renamed the plugin `plan-mode` → `plan-agent`
   (install id is now `plan-agent@agentics-kit`) and the skill `authoring-plans`
   → `author`; switched the skill from auto-activating to explicit
   (`disable-model-invocation: true`), now invoked `/plan-agent:author
   <objective>`; **Added** — `$ARGUMENTS` objective + `--quick`/`--type`/`--dir`/
   `--interview` flags with objective-derived defaults, and `EnterPlanMode` entry.
   Note the hook is unchanged except its stderr citation.
   - *Why:* CHANGELOG entry is mandated by `marketplace.md`.
   - *Verify:* `grep -nE '0.2.0|BREAKING|plan-agent|author' CHANGELOG.md` matches.

10. **Rewrite `kit/plugins/plan-agent/README.md`.** Retitle to plan-agent;
    Features → the explicit `/plan-agent:author` skill (manual-invoke) + hook;
    Installation → `/plugin install plan-agent@agentics-kit`; Usage →
    `/plan-agent:author create a todo app for ravens` plus flag examples; Plugin
    Structure tree → `skills/author/` (with `reference/SKELETON.md`), `hooks/`;
    Components → document the skill (note `disable-model-invocation`, the
    arguments) and the hook.
    - *Why:* `plugin-patterns.md` requires the README to document the current
      name + component set with examples.
    - *Verify:* `grep -c 'plan-agent' README.md` ≥ 4; `grep -c 'authoring-plans' README.md`
      is 0; the tree shows `skills/author/` and the README shows
      `/plan-agent:author`.

11. **Update root `CLAUDE.md`.** Rename the `plan-mode` table row to `plan-agent`,
    keep Type `Skills + Hooks`, and note the explicit `/plan-agent:author`
    (manual-invoke, `disable-model-invocation`) skill + retained filename hook.
    The "17 plugins … v3.8.0" line is unchanged.
    - *Why:* `CLAUDE.md` is the canonical inventory; name and activation model
      changed.
    - *Verify:* `grep -n 'plan-agent' CLAUDE.md` matches the row; no stale
      `plan-mode` *plugin* row remains; the count/version line is unchanged.

## Acceptance Criteria

- [ ] `kit/plugins/plan-mode` no longer exists; `kit/plugins/plan-agent` exists
      with `skills/author/SKILL.md`, `skills/author/reference/SKELETON.md`, and
      `hooks/`.
- [ ] `skills/author/SKILL.md` frontmatter has `name: author`,
      `disable-model-invocation: true`, `argument-hint`, and `EnterPlanMode` +
      `ExitPlanMode` + `ToolSearch` in `allowed-tools`.
- [ ] The skill no longer auto-activates on planning intent; it runs only when
      invoked as `/plan-agent:author`.
- [ ] `/plan-agent:author create a todo app for ravens` parses the objective,
      infers `type: feature`, enters real plan mode, runs §0–§7, and produces a
      `verb-target`-named plan the hook accepts.
- [ ] `--quick`, `--type`, `--dir`, `--interview` are honored; omitted flags use
      objective-derived defaults.
- [ ] The `validate-plan-filename` hook still exits 2/0 correctly; its stderr no
      longer cites `authoring-plans`.
- [ ] `plugin.json` `name` is `plan-agent` (no `version`); `marketplace.json`
      lists `plan-agent` at `0.2.0` with `source.path: kit/plugins/plan-agent`,
      top-level `3.8.0`, valid JSON, and no `plan-mode` entry.
- [ ] README, CHANGELOG (`0.2.0`, BREAKING), and root `CLAUDE.md` reflect the
      renamed plugin and the manual-invoke `author` skill with the hook retained.
- [ ] No stale `plan-mode` *plugin* / `authoring-plans` references remain
      (distinct from the generic plan-mode concept and the global
      `~/.claude/rules/plan-mode.md`).
- [ ] Stray `revire-this-…` and `wobbly-bachman.md` removed; this plan lives at
      `convert-plan-mode-to-plan-agent-skill.md`.

## Verification

1. **Static validation:** run each step's `Verify` command — manifests parse,
   the directory renames show in `git status`, `skills/author/SKILL.md` and
   `skills/author/reference/SKELETON.md` exist, no `skills/authoring-plans`.
2. **Stale-reference sweep:**
   `grep -rn 'plan-mode\|authoring-plans' kit/plugins/plan-agent .claude-plugin/marketplace.json CLAUDE.md`
   surfaces only intentional mentions of the generic plan-mode concept — not the
   old plugin/skill names.
3. **Hook regression:** pipe an absolute bad path → exit 2 with the repointed
   citation; a good `verb-target` path → exit 0; a `status: completed` plan with
   a bad name → exit 0 (skip).
4. **Live plugin load:** `claude --plugin-dir ./kit/plugins/plan-agent`; confirm
   `/plan-agent:author` is invokable and the skill does **not** auto-activate on
   a casual "draft a plan…" message (because `disable-model-invocation: true`).
5. **End-to-end:** run `/plan-agent:author create a todo app for ravens` — confirm
   it echoes the resolved objective + inferred `type: feature`, calls
   `EnterPlanMode` (read-only + approval gate), runs §0–§7, and writes a
   `verb-target`-named plan accepted by the hook (exit 0).
6. **Flag checks:** `/plan-agent:author --quick --type fix patch the login
   redirect` skips Clarify/Align and presets `type: fix`; `--dir tmp/plans …`
   writes there; `--interview …` runs the interview before `ExitPlanMode` (or
   notes the plugin is absent).

## Next Steps *(optional)*

- Optional auto-activating companion:
  ```text
  In kit/plugins/plan-agent, evaluate whether to add a SECOND, thin
  auto-activating skill (no disable-model-invocation) that only nudges the user
  toward /plan-agent:author when it detects planning intent — without running the
  full workflow itself. Keep the heavy workflow in the manual `author` skill.
  Weigh this against the user's goal of removing ambient activation entirely;
  recommend for or against, and if for, draft the minimal description-only skill.
  ```

- Migration note for v0.1.0 users:
  ```text
  Add a short "Migrating from plan-mode 0.1.0" subsection to the plan-agent
  README explaining that the plugin was renamed plan-mode -> plan-agent, the
  skill was renamed authoring-plans -> author and no longer auto-activates
  (disable-model-invocation), and planning is now triggered explicitly via
  /plan-agent:author <objective>. Note the filename hook is unchanged. Keep it to
  a few lines.
  ```

## Unresolved Questions *(optional)*

- Version number for a pre-1.0 rename + activation change:
  ```text
  The plugin is renamed (plan-mode -> plan-agent), its skill is renamed
  (authoring-plans -> author), and the skill switches from auto to manual
  activation — all breaking/MAJOR per marketplace.md — while still pre-1.0 and
  unreleased. Recommend whether to ship as 0.2.0 (pre-1.0 minor carrying breaking
  changes, current plan) or jump to 1.0.0 to signal the new identity. Apply the
  choice consistently in marketplace.json and CHANGELOG.md.
  ```
