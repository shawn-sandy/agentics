---
status: todo
type: standard
---

# Create Skill-Authoring Rule

## Context

Skills in `kit/plugins/*/skills/**` are the main authoring surface in this repo, but the existing scoped rules in `.claude/rules/` don't cover Anthropic's official skill checklist. `plugin-patterns.md` touches on skill *structure* but skips quality/testing criteria. When someone edits a `SKILL.md`, we want the Claude Code harness to surface a concise checklist from [Anthropic's skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills) so the author catches issues while writing — not after a `skill-reviewer` audit.

## Objective

Add a new rule file `.claude/rules/skill-authoring.md` that activates whenever someone works inside a skill directory, presenting the upstream checklist inline and pointing to deeper auditing tools.

## Steps

1. **Create `.claude/rules/skill-authoring.md`** with this shape:
   - Frontmatter:
     - `description:` — one-liner, mirroring the style of `plan-hygiene.md`
     - `paths: ["kit/plugins/**/skills/**"]` — scopes activation to any file inside a skill directory (SKILL.md plus bundled `reference/`, `scripts/`, etc.)
   - Body sections:
     - `# Skill Authoring` — title
     - Short imperative lede: "Before saving changes to a SKILL.md…"
     - `## Checklist` — verbatim from the upstream best-practices page, split into three subsections:
       - `### Core quality` (10 items)
       - `### Code and scripts` (8 items — note: applies only if the skill bundles scripts)
       - `### Testing` (4 items)
     - `## Frontmatter constraints` — the hard validation rules from the docs (`name` ≤64 chars, lowercase kebab-case, no reserved words `anthropic`/`claude`; `description` ≤1024 chars, third person, non-empty)
     - `## When in doubt` — one-liner pointing to `/skill-reviewer:reviewing-skills` for a scored post-hoc audit
   - **Why:** Keeps the rule self-contained (matches `testing.md` / `plan-hygiene.md` style) so Claude doesn't need to fetch the URL mid-edit, but still cites the source link so the user can dive deeper.

2. **Verify the rule activates on skill edits** — open any `SKILL.md` under `kit/plugins/*/skills/` in a new Claude Code session and confirm the rule content appears in scoped context. The harness resolves `paths:` globs automatically; no config wiring needed.
   - **Why:** Confirms the glob is correct before we rely on it. The `.claude/rules/` folder is discovered automatically — no entry in `settings.json` is required.

3. **Leave `plugin-patterns.md` unchanged.** Its existing "Skill Pattern" subsection covers structural shape (file location, `allowed-tools`, progressive disclosure intro). The new rule covers *quality* criteria. They complement without overlapping.
   - **Why:** Editing `plugin-patterns.md` would mix two concerns (broader plugin architecture vs. skill-specific quality) and bloat a rule that's already ~107 lines.

4. **Commit** `.claude/rules/skill-authoring.md` with the plan file in the same commit, per the repo convention ("Always include the plan file in commits for plugin changes, even minor ones").

## Critical Files

- **Create:** `.claude/rules/skill-authoring.md`
- **Reference (do not modify):**
  - `.claude/rules/plan-hygiene.md` — closest shape analogue (has `description:` + `paths:` + short imperative body)
  - `.claude/rules/plugin-patterns.md` — existing skill-structure guidance; new rule must not duplicate its content
  - `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` — post-hoc audit skill the new rule should point to
  - `CLAUDE.md` (project) — states `.claude/rules/` contains "Detailed authoring patterns (scoped rules)"

## Verification

1. After writing, `cat .claude/rules/skill-authoring.md` — check frontmatter parses (no YAML errors) and `paths:` glob matches existing convention.
2. Start a fresh Claude Code session, open `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md`, and prompt: "what rules apply to this file?" — confirm the new rule is surfaced alongside `plugin-patterns.md`.
3. Open a file *outside* the scope (e.g., `kit/plugins/git-agent/commands/commit.md`) and confirm the new rule is **not** loaded — validates the glob doesn't over-match.
4. Line count: the finished rule should be under 60 lines. If it grows past that, move the checklist verbatim block into a linked reference file.

## Next Steps (out of scope)

- Mirror this rule for *agents* (`kit/plugins/**/agents/**`) if Anthropic publishes an equivalent agent-authoring checklist.
- Consider a pre-commit hook that auto-invokes `/skill-reviewer:reviewing-skills` on any staged `SKILL.md` — separate effort.
