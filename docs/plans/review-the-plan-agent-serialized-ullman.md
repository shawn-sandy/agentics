---
status: todo
type: feature
created: 2026-05-28
repo-name: agentics
---

# Plan: Improve and Optimize plan-agent — Templates, Extensibility, and Granular Flags

## Context

The `plan-agent` plugin (v0.2.0) is a solid foundation with a well-structured Steps 0–7 workflow,
a reliable filename-validation hook, and a manual-invoke skill. However, three friction points
limit its usability in diverse team environments:

1. **Hook verb set is closed.** Users with domain-specific verbs (e.g. `onboard`, `publish`,
   `ingest`, `serialize`) get false-positive filename rejections and must edit Python source
   to add their verbs — a maintenance burden.

2. **One-size template.** Only `SKELETON.md` exists. ADRs, spike investigations, and
   minimal change-tracking notes all have different natural shapes; forcing them into the
   full plan structure creates unnecessary overhead.

3. **`--quick` is blunt.** The flag collapses two independent workflow stages (Step 1 Clarify and
   Step 5 Align) into a single binary toggle, and the auto-inference heuristic (≥8-word objectives
   treated as `--quick`) can surprise users. Teams often want one stage skipped but not both.

4. **No per-project frontmatter.** Teams that track `priority:`, `team:`, or `milestone:` have
   no path to inject those fields without writing a wrapper.

## Objective

Add hook extensibility, plan templates, granular skip-flags, and configurable frontmatter
to the `plan-agent` plugin — all without breaking the existing Steps 0–7 workflow or the
`plansDirectory` configuration contract used by other plugins.

## Steps

1. **Hook: add `_get_plan_agent_settings()` and thread custom sets into `classify_filename`.**
   - File: `kit/plugins/plan-agent/hooks/validate-plan-filename.py`
   - Add a `_get_plan_agent_settings()` function (after `_get_plans_dir()`) that reads
     `settings.get("planAgent", {})` from the same project-then-global cascade used by
     `_get_plans_dir()`. Returns `{}` on missing file or missing key; never merges both files
     (first-match-wins, matching the existing `plansDirectory` contract).
   - Update `classify_filename(stem)` signature to
     `classify_filename(stem, verbs=None, stop_words=None, placeholders=None)`, defaulting
     to the module-level constants when `None` — keeps the function testable without injection.
   - In `main()`, call `_get_plan_agent_settings()` once, build three effective sets:
     ```python
     cfg = _get_plan_agent_settings()
     effective_verbs = IMPERATIVE_VERBS | set(v.lower() for v in cfg.get("additionalVerbs", []))
     effective_stop = STOP_WORDS_2ND | set(w.lower() for w in cfg.get("additionalStopWords", []))
     effective_ph   = GENERIC_NAMES   | set(n.lower() for n in cfg.get("additionalPlaceholders", []))
     ```
   - Pass them to `classify_filename(stem, verbs=effective_verbs, stop_words=effective_stop, placeholders=effective_ph)`.
   - Update module docstring to document the three new `planAgent.*` settings keys.
   - *Why:* Users can extend validation without touching plugin source; the signature change
     is backwards-compatible (all new params are keyword-only with defaults).
   - *Verify:* Add `"planAgent": {"additionalVerbs": ["onboard"]}` to `.claude/settings.json`,
     run `echo '{"tool_input":{"file_path":"docs/plans/onboard-new-engineers.md"}}' | python3 kit/plugins/plan-agent/hooks/validate-plan-filename.py` and confirm exit 0. Remove the test entry.

2. **Create three new skeleton template files.**
   - Directory: `kit/plugins/plan-agent/skills/author/reference/`
   - `SKELETON-minimal.md` — frontmatter identical to `SKELETON.md`; sections: Context,
     Objective, Steps (same Why/Verify per-item format), Acceptance Criteria, Verification.
     Omit Next Steps and Unresolved Questions entirely. Add a comment `# Minimal template`.
   - `SKELETON-adr.md` — frontmatter with `status: proposed`, `type: docs`. Sections:
     Title, Status (`proposed | accepted | deprecated | superseded`), Context, Decision,
     Consequences, Alternatives Considered (at least two entries).
   - `SKELETON-spike.md` — frontmatter with `type: chore`. Sections: Goal (the question
     this spike answers), Time-box (`<N hours/days>`), Approach, Findings
     (`<TBD — fill in after investigation>`), Recommendation, Next Steps *(optional)*.
   - *Why:* Different work shapes have different natural structures; forcing spikes and ADRs
     into the full plan template wastes time and produces noise in optional sections.
   - *Verify:* `ls kit/plugins/plan-agent/skills/author/reference/` shows all four skeleton
     files. `grep -l "status: proposed" kit/plugins/plan-agent/skills/author/reference/` returns
     `SKELETON-adr.md`.

3. **SKILL.md: add `--template`, `--no-clarify`, `--no-align`, `--priority` flags.**
   - File: `kit/plugins/plan-agent/skills/author/SKILL.md`
   - Update `argument-hint` (line 6) to:
     ```
     "<objective> [--quick] [--no-clarify] [--no-align] [--type feature|fix|refactor|docs|chore] [--template default|minimal|adr|spike] [--dir <path>] [--priority low|medium|high|critical] [--interview]"
     ```
   - In the Invocation & Arguments section, **replace** the `--quick` bullet and smart-defaults
     paragraph with:
     - `--quick` — shorthand for `--no-clarify --no-align`; skips both Step 1 and Step 5.
     - `--no-clarify` — skip Step 1 Clarify only.
     - `--no-align` — skip Step 5 Align only.
     - `--template <name>` — plan skeleton variant: `default` (default), `minimal`, `adr`,
       `spike`. Controls which `SKELETON-<name>.md` is loaded in Step 2.
     - `--priority <level>` — write `priority: <level>` to frontmatter (`low`, `medium`,
       `high`, `critical`). Overrides `planAgent.extraFrontmatter.priority` if both present.
   - **Remove** the auto-`--quick` inference line (current line 32:
     `"--quick absent → treat as --quick if the objective is detailed and specific..."`)
     entirely. `--quick` and its component flags are opt-in only; they are never inferred.
   - *Why:* Teams frequently need one stage skipped but not both; removing auto-inference
     makes behavior predictable.
   - *Verify:* Read the updated SKILL.md; confirm line 32 no longer mentions auto-inference.

4. **SKILL.md: update Step 1, Step 2, Step 3, Step 5, and Skeleton sections to use new flags and templates.**
   - Step 1 "Clarify" skip condition: change `*(Skip entirely when --quick or when the objective is detailed.)*` → `*(Skip entirely when --quick or --no-clarify.)*`
   - Step 2 "Create": after "verb-target kebab-case filename", add: "Load the skeleton using the
     template rule in the **Skeleton** section."
   - Step 3 "Frontmatter": extend to add after `repo-name`:
     "After writing the standard fields, read `planAgent.extraFrontmatter` from
     `.claude/settings.json` (project first, then global). Append each key-value pair after
     `repo-name:`. If `--priority` was set, write `priority: <level>` (overwriting any
     `priority` from `extraFrontmatter`). Omit `priority:` entirely if neither source sets it."
   - Step 5 "Align" skip condition: change `*(Skip entirely when --quick.)*` → `*(Skip entirely
     when --quick or --no-align.)*`
   - "Skeleton" section (lines 80–83): replace the single-template instruction with a
     template-lookup rule:
     ```
     Copy the appropriate skeleton from `skills/author/reference/` based on `--template`:
     - `default` (or absent) → `SKELETON.md`
     - `minimal` → `SKELETON-minimal.md`
     - `adr` → `SKELETON-adr.md`
     - `spike` → `SKELETON-spike.md`

     Use `Glob` with pattern `**/plan-agent/skills/author/reference/SKELETON<suffix>.md`
     where `<suffix>` is empty for `default` and `-<name>` for others. This avoids
     accidentally loading the global `~/.claude/rules/reference/SKELETON.md`.
     ```
   - *Why:* The skill body must match the argument-hint or Claude will silently ignore the
     new flags. Explicit template lookup prevents ambiguity.
   - *Verify:* SKILL.md is under 120 lines total. Step 1, Step 5 conditions reference the new flags.
     Step 3 mentions `extraFrontmatter`. Skeleton section lists all four variant filenames.

5. **CHANGELOG.md: prepend 0.3.0 entry.**
   - File: `kit/plugins/plan-agent/CHANGELOG.md`
   - Prepend a `## 0.3.0 — 2026-05-28` section before the existing `## 0.2.0` block listing:
     - Added: hook extensibility (`additionalVerbs`, `additionalStopWords`, `additionalPlaceholders`)
     - Added: `--template default|minimal|adr|spike` with three new skeleton files
     - Added: `--no-clarify` and `--no-align` flags
     - Added: `--priority` flag and `planAgent.extraFrontmatter` config
     - Changed: `--quick` auto-inference removed; flag is now opt-in only
   - *Why:* CLAUDE.md requires plan files and CHANGELOG entries for every plugin change.
   - *Verify:* `head -5 kit/plugins/plan-agent/CHANGELOG.md` shows `0.3.0`.

6. **README.md: update flags table, add templates table, add planAgent config section.**
   - File: `kit/plugins/plan-agent/README.md`
   - In the flags table: add rows for `--no-clarify`, `--no-align`, `--template`, `--priority`.
   - Update the `--quick` row to clarify it is shorthand for `--no-clarify --no-align`.
   - Remove the smart-defaults note about 8-word objectives.
   - After the flags table, add an "Available templates" sub-table:
     | Template | Format | Best for |
     |---|---|---|
     | `default` | Full Steps 0–7 plan | Multi-step features, refactors |
     | `minimal` | Context + Steps + Criteria | Simple fixes, well-understood changes |
     | `adr` | ADR (Context / Decision / Consequences) | Architecture decisions |
     | `spike` | Goal / Time-box / Findings | Investigations, time-boxed research |
   - Add a "Plugin configuration (`planAgent.*`)" sub-section under "Plans directory" with a
     JSON example showing all four keys: `additionalVerbs`, `additionalStopWords`,
     `additionalPlaceholders`, `extraFrontmatter`.
   - *Why:* Plugin docs are the discoverable reference for new users; undocumented config is
     functionally invisible.
   - *Verify:* README has the templates table and planAgent config example.

7. **Marketplace: bump plan-agent version to 0.3.0.**
   - File: `.claude-plugin/marketplace.json`
   - Change `"version": "0.2.0"` to `"version": "0.3.0"` in the `plan-agent` entry.
   - *Why:* Version in `marketplace.json` is the authoritative install version for this
     relative-path plugin (CLAUDE.md convention: do NOT set version in `plugin.json`).
   - *Verify:* `grep -A2 '"name": "plan-agent"' .claude-plugin/marketplace.json` shows `0.3.0`.

## Acceptance Criteria

- [ ] `validate-plan-filename.py` accepts filenames whose leading verb is in `planAgent.additionalVerbs` from project `.claude/settings.json`
- [ ] `classify_filename` signature has optional `verbs`, `stop_words`, `placeholders` params — existing call `classify_filename(stem)` still works unchanged
- [ ] Three new skeleton files exist: `SKELETON-minimal.md`, `SKELETON-adr.md`, `SKELETON-spike.md`
- [ ] SKILL.md `argument-hint` lists all new flags; no auto-`--quick` inference in skill body
- [ ] Step 1 skip condition references `--no-clarify`; Step 5 references `--no-align`
- [ ] Step 3 documents `planAgent.extraFrontmatter` read and `--priority` override
- [ ] Skeleton section in SKILL.md maps all four `--template` values to their file
- [ ] CHANGELOG.md has a `0.3.0` entry at the top
- [ ] marketplace.json `plan-agent` entry shows `"version": "0.3.0"`
- [ ] `plansDirectory` top-level key contract is unchanged (other plugins read it directly)

## Verification

1. Run the hook manually with a test filename using an extended verb:
   ```bash
   echo '{"tool_input":{"file_path":"docs/plans/onboard-new-engineers.md"}}' \
     | python3 kit/plugins/plan-agent/hooks/validate-plan-filename.py
   ```
   Without settings: expect exit 2 (verb not in default set). With `"planAgent":{"additionalVerbs":["onboard"]}` in `.claude/settings.json`: expect exit 0.

2. Confirm all skeleton files exist and are valid Markdown:
   ```bash
   ls kit/plugins/plan-agent/skills/author/reference/
   # SKELETON.md  SKELETON-adr.md  SKELETON-minimal.md  SKELETON-spike.md
   ```

3. Invoke `/plan-agent:author --template adr decide on database ORM strategy` in a test session — confirm the resulting plan has ADR sections (Status, Decision, Consequences) and no Steps section.

4. Invoke `/plan-agent:author --no-clarify add payment webhook handler` — confirm Step 1 is skipped but Step 5 Align is still run.

5. Invoke a 10-word objective without `--quick` — confirm Step 1 Clarify is NOT auto-skipped.

6. Set `"planAgent":{"extraFrontmatter":{"team":"engineering"}}` in `.claude/settings.json`, invoke `/plan-agent:author add caching layer` — confirm `team: engineering` appears in the written plan frontmatter after `repo-name:`.

## Next Steps *(optional)*

- Add a `/plan-agent:list` command:
  ```text
  Add a slash command `/plan-agent:list [--status todo|in-progress|completed]` to the plan-agent plugin.
  The command should search the configured plansDirectory (reading plansDirectory from .claude/settings.json
  with the same cascade as the hook), find all .md files there, read their frontmatter `status` field,
  and print a grouped table grouped by status. Each row: filename, status, created date, type.
  Filter by --status if provided. Write to kit/plugins/plan-agent/commands/list.md.
  ```

- Publish a `planAgent.defaultTemplate` setting:
  ```text
  Add a `planAgent.defaultTemplate` setting to validate-plan-filename.py's settings reader and document it
  in the SKILL.md. When set (e.g. "minimal"), the skill uses that template unless --template is explicitly
  provided. This lets teams that always use ADRs avoid typing --template adr every time.
  ```
