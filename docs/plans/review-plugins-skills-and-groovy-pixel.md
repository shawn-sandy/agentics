# Plan: Disable model invocation on workflow-style plugin skills

## Context

Claude Code skills support a `disable-model-invocation: true` frontmatter
field that prevents Claude from auto-loading the skill based on its
description match. The skill remains fully invocable manually via
`/plugin:skill-name`, but it is no longer preloaded into subagent contexts
and won't fire on natural-language intent matching.

This is desirable for **deliberate workflow skills** — ones the user wants
to trigger explicitly (commit/PR/ship flows, autonomous TDD loops,
heavyweight analyzers, plan-interview workflows) — because:

1. Auto-firing such skills can surprise the user or override their intent.
2. Subagents shouldn't preload heavy workflow skills they'll never invoke;
   keeping them off the auto-loaded set keeps subagent context windows lean.
3. Each of the selected skills already has either a command wrapper
   (`commands/*.md`) or an obvious explicit invocation phrase.

Currently only `git-agent/skills/branch-agent/SKILL.md` sets this field.
After review of all 30 SKILL.md files under `kit/plugins/`, the user
selected nine additional skills to bring under the same convention.

## Objective

Add `disable-model-invocation: true` to the YAML frontmatter of nine
SKILL.md files across five plugins, then bump each plugin's version in
`.claude-plugin/marketplace.json` with matching CHANGELOG entries.

## Files to modify

### SKILL.md files (9)

- [kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md](../../kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md)
- [kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md](../../kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md)
- [kit/plugins/git-agent/skills/commit-agent/SKILL.md](../../kit/plugins/git-agent/skills/commit-agent/SKILL.md)
- [kit/plugins/git-agent/skills/pr-agent/SKILL.md](../../kit/plugins/git-agent/skills/pr-agent/SKILL.md)
- [kit/plugins/git-agent/skills/ship/SKILL.md](../../kit/plugins/git-agent/skills/ship/SKILL.md)
- [kit/plugins/plan-interview/skills/deep-grill/SKILL.md](../../kit/plugins/plan-interview/skills/deep-grill/SKILL.md)
- [kit/plugins/plan-interview/skills/documenting-plans/SKILL.md](../../kit/plugins/plan-interview/skills/documenting-plans/SKILL.md)
- [kit/plugins/react-perf-analyzer/skills/react-perf-analyzer/SKILL.md](../../kit/plugins/react-perf-analyzer/skills/react-perf-analyzer/SKILL.md)
- [kit/plugins/skill-reviewer/skills/optimizing-skill-descriptions/SKILL.md](../../kit/plugins/skill-reviewer/skills/optimizing-skill-descriptions/SKILL.md)

### Marketplace + changelogs (5 plugins)

- [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) — bump version of 5 plugin entries
- `kit/plugins/code-testing-agent/CHANGELOG.md`
- `kit/plugins/git-agent/CHANGELOG.md`
- `kit/plugins/plan-interview/CHANGELOG.md`
- `kit/plugins/react-perf-analyzer/CHANGELOG.md`
- `kit/plugins/skill-reviewer/CHANGELOG.md`

### Skills explicitly NOT changed (user decision)

- `plan-interview/plan-interview` — keep auto (user retains intent triggering)
- `plan-interview/plan-to-html` — keep auto
- `plan-interview/plan-status` — keep auto (auto-activation inside plan mode is the value prop)
- `code-simplifier/code-simplifier` — keep auto (no command wrapper; intent is clear)
- All other 16 skills audited — keep auto

## Steps

<ol>

<li>
<strong>Add <code>disable-model-invocation: true</code> to each of the 9 SKILL.md frontmatters.</strong>
Insert as a new line inside the existing <code>---</code> YAML block, after the
<code>allowed-tools</code> line and before the closing <code>---</code>. Do not change
<code>name</code>, <code>description</code>, or <code>allowed-tools</code>. Match the existing style
(boolean unquoted, no inline comment).
<br><em>Why:</em> Single mechanical change per file; consistent with the
already-disabled <code>branch-agent</code> skill's placement.
<br><em>Verify:</em> <code>grep -l "disable-model-invocation: true" kit/plugins/**/SKILL.md</code>
returns exactly 10 files (the 9 new + branch-agent), and <code>git diff</code>
shows only added lines in each frontmatter.
</li>

<li>
<strong>Bump MINOR versions in <a href="../../.claude-plugin/marketplace.json">marketplace.json</a> for the 5 affected plugins.</strong>
<ul>
<li><code>code-testing-agent</code>: 3.3.0 → 3.4.0</li>
<li><code>git-agent</code>: 3.6.2 → 3.7.0</li>
<li><code>plan-interview</code>: 1.15.0 → 1.16.0</li>
<li><code>react-perf-analyzer</code>: 1.2.0 → 1.3.0</li>
<li><code>skill-reviewer</code>: 1.8.0 → 1.9.0</li>
</ul>
<em>Why:</em> Per <a href="../../.claude/rules/marketplace.md">marketplace.md</a>,
every visible behavior change requires a version bump and CHANGELOG entry.
<br><em>Verify:</em> <code>jq '.plugins[] | select(.name | IN("code-testing-agent","git-agent","plan-interview","react-perf-analyzer","skill-reviewer")) | {name, version}' .claude-plugin/marketplace.json</code>
shows the new versions, and the post-Write hook auto-validates marketplace.json syntax without errors.
</li>

<li>
<strong>Add a CHANGELOG entry to each of the 5 plugins.</strong>
Format: top-of-file entry under the bumped version, one bullet per affected
skill, plain language like
"<code>disable-model-invocation: true</code> on <code>&lt;skill&gt;</code> — manual invocation only via <code>/&lt;plugin&gt;:&lt;skill&gt;</code>; no longer auto-triggers on intent match."
<br><em>Why:</em> Installers updating across versions need to understand that
intent-based triggering has been removed for these skills.
<br><em>Verify:</em> <code>head -20</code> of each CHANGELOG shows the new entry
matching the new version; entry mentions the specific skill(s) touched in
that plugin (not all 9).
</li>

<li>
<strong>Sanity-check skill activation by reloading the marketplace.</strong>
Run <code>/plugin marketplace add ~/devbox/agentics</code> (or refresh if already added) and confirm the disabled
skills are still listed under <code>/plugin</code> commands but no longer appear in
the user-invocable skills section of a new session's system reminder for
intent-style triggers.
<br><em>Why:</em> The whole point of the change is the activation-behavior
shift — must be empirically confirmed, not just assumed from the frontmatter
diff.
<br><em>Verify:</em> In a fresh Claude Code session, the
<code>&lt;system-reminder&gt;</code> skills list either omits these skills or labels
them as disabled; manually invoking <code>/git-agent:commit-agent</code> still works.
</li>

<li>
<strong>Commit and ship.</strong>
Single commit covering all 9 SKILL.md edits + marketplace.json + 5 CHANGELOGs + this plan file. Conventional message:
<code>feat(kit/plugins): disable model invocation on workflow skills</code>.
<br><em>Why:</em> Per <a href="../../CLAUDE.md">CLAUDE.md</a>: always include the plan
file in commits for plugin changes.
<br><em>Verify:</em> <code>git log -1 --stat</code> shows exactly one commit with 16
files changed (9 SKILL.md + 1 marketplace.json + 5 CHANGELOG + 1 plan);
working tree clean.
</li>

</ol>

## Verification

End-to-end confirmation that the plan succeeded:

- `grep -rL "disable-model-invocation" kit/plugins/code-testing-agent/skills/tdd-{fix,loop}/SKILL.md kit/plugins/git-agent/skills/{commit-agent,pr-agent,ship}/SKILL.md kit/plugins/plan-interview/skills/{deep-grill,documenting-plans}/SKILL.md kit/plugins/react-perf-analyzer/skills/react-perf-analyzer/SKILL.md kit/plugins/skill-reviewer/skills/optimizing-skill-descriptions/SKILL.md`
  returns nothing (all 9 contain the field).
- `jq '[.plugins[] | select(.version != null)] | length' .claude-plugin/marketplace.json` returns the expected total count and the 5 bumped plugins show new versions.
- Each touched CHANGELOG.md has a fresh entry referencing the new version.
- Starting a fresh Claude Code session in this repo no longer lists the 9 skills among auto-triggerable skills, but they remain accessible via `/plugin:skill-name`.
- `git status` is clean post-commit; the plan file is included in the same commit.

## Next steps (out of scope)

- Audit the remaining 4 UNCLEAR skills from the original review
  (`commit-agent` etc. were resolved; but `plan-interview/plan-status`'s
  command wrapper may want to be re-evaluated if plan-mode auto-activation
  proves redundant).
- Consider adding a lint check in `.claude/settings.json` Write hook that
  flags new SKILL.md files which lack `disable-model-invocation` AND have a
  command wrapper of the same name.
- Document the auto-vs-manual convention in `.claude/rules/plugin-patterns.md` so future skill authors pick the right default.

## Unresolved Questions

None — version-bump tier confirmed as MINOR.
