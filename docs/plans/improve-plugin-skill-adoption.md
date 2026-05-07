# Plan: Plugin & Skill Usability / Adoption Improvements

## Context

The agentics marketplace now has 13 published plugins with 27+ skills, 6 agents, and 29 commands.
Initial stress-test review surfaced issues that quietly block adoption: skills that don't auto-activate due to poor description formatting, a stale README that hides new features from prospective users, excessive tags that dilute discoverability, and missing scope boundaries that confuse users about what a skill covers.

This plan addresses those issues in priority order — highest usability impact first.

---

## Objective

Improve plugin discoverability, correct skill activation triggers, and synchronize documentation so new users can confidently adopt and trust the marketplace.

---

## Steps

### Phase 1 — Fix Skill Activation Triggers (Highest Usability Impact)

The following 11 skills use multi-line YAML (`>` syntax) that buries the trigger phrase, or omit it entirely.
Claude uses the `description` field for intent matching; a buried trigger means the skill silently doesn't activate.

**Target skills:**
- `kit/plugins/agent-reviewer/skills/*/SKILL.md`
- `kit/plugins/code-simplifier/skills/*/SKILL.md`
- `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md`
- `kit/plugins/code-testing-agent/skills/running-tests/SKILL.md`
- `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`
- `kit/plugins/git-agent/skills/branch-agent/SKILL.md`
- `kit/plugins/git-agent/skills/ship/SKILL.md`
- `kit/plugins/plan-interview/skills/deep-grill/SKILL.md`
- `kit/plugins/plan-interview/skills/plan-interview/SKILL.md`

**1.1** — Read each skill's `description:` frontmatter and rewrite to a single-line string starting with `"Use when..."`.
Keep the `>` block syntax only if the rule requires multi-line; otherwise collapse to inline.

**1.2** — Add `"Does NOT cover..."` scope statements to skills that lack them:
- `kit/plugins/git-agent/skills/branch-agent/SKILL.md`
- `kit/plugins/git-agent/skills/ship/SKILL.md`
- `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md`

Use `kit/plugins/skill-reviewer` as the canonical reference for scope boundary format and placement.
These clarify limits so users stop triggering the wrong skill for adjacent tasks.

---

### Phase 2 — Sync README.md (Adoption Blocker)

The root `README.md` is the first thing a potential adopter sees.
Several items are stale per the `update-readme-with-current-plugin-data` plan already in `docs/plans/`.

**2.1** — Update the plugin table to match current `marketplace.json` versions:
- code-review: 3.1.0 → 3.2.0
- plan-interview: 1.12.0 → 1.14.5
- git-agent: 1.1.0 → 3.6.1

**2.2** — Add `code-simplifier` to the plugin table (completely absent from README despite being live in v3.2.0).

**2.3** — Add `agent-reviewer` to the plugin table if missing.

**2.4** — Add new capabilities per plugin that were shipped but not documented:
- plan-interview: `deep-grill`, `plan-hygiene`
- git-agent: `branch-agent`, `pr-agent`, `ship` skills

Format for each new capability entry: short paragraph describing what it does, followed by one example invocation.

---

### Phase 3 — Fix Discoverability / Metadata (Medium Impact)

**3.1** — Trim excessive tags on two plugins (current: 12 each; target: 6–8 most searchable):
- `skill-reviewer`: drop `running-tests`, `session-audit`, `claude-code` (redundant given context)
- `git-agent`: drop `subagents`, `background`, `slash-commands` (implementation details, not user search terms)

**3.2** — Update `CLAUDE.md` line that says `Marketplace Infrastructure — (Planned)`.
The marketplace is live and functional. Remove "(Planned)" qualifier so new contributors aren't confused.

---

### Phase 4 — Fix Agent YAML Consistency (Low Impact / Easy Win)


**4.1** — Convert `kit/plugins/plan-interview/agents/plan-documenter.md` `tools:` from YAML list format to inline CSV, matching all 5 other agents:

```yaml
# current (YAML list)
tools:
  - Read
  - Glob
  ...

# target (inline CSV like every other agent)
tools: Read, Glob, Grep, Bash, Write, Edit, TodoWrite, Skill, Agent
```

---

### Phase 5 — CHANGELOG + Version Bumps

Per `marketplace.md`, any change to skill content or plugin metadata requires a PATCH version bump and a CHANGELOG entry.

**5.1** — For each plugin with files modified in Phases 1–4, add a PATCH entry to `kit/plugins/<name>/CHANGELOG.md`:
- `agent-reviewer` — description rewrite
- `code-simplifier` — description rewrite
- `code-testing-agent` — description rewrite (3 skills)
- `git-agent` — description rewrite + scope boundaries
- `memory-tools` — scope boundary addition
- `plan-interview` — description rewrite + agent tools format fix
- `skill-reviewer` — tag trim
- `git-agent` — tag trim (already listed; single entry covers both)

**5.2** — Bump `version` (PATCH) in `.claude-plugin/marketplace.json` for each affected plugin.

**5.3** — Commit message should follow the `fix(kit/plugins/<name>): bump version to X.Y.Z` convention per `marketplace.md`.

---

## Files to Modify

| File | Change |
|------|--------|
| `kit/plugins/*/skills/*/SKILL.md` (11 files) | Rewrite `description:` trigger phrases |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Add scope boundary |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Add scope boundary |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Add scope boundary |
| `README.md` | Version sync + add missing plugins + new capabilities |
| `.claude-plugin/marketplace.json` | Trim tags for skill-reviewer + git-agent |
| `CLAUDE.md` | Remove "(Planned)" from marketplace infrastructure line |
| `kit/plugins/plan-interview/agents/plan-documenter.md` | Convert tools YAML list → inline CSV |

---

## Out of Scope (Next Steps)

- Test fixture expansion (valid-with-commands, invalid-bad-json, etc.) — tracked separately
- Splitting large skills (plan-interview at 475 lines) — requires deeper content review
- Removing personal paths from `.claude/settings.json` — separate security/privacy cleanup
- CHANGELOG enforcement rule — low signal-to-noise on this repo size

---

## Verification

1. Load each modified plugin: `claude --plugin-dir ./kit/plugins/<name>`
2. Test 2–3 activation prompts per modified skill — confirm the skill triggers without explicit invocation
3. Run `jq . .claude-plugin/marketplace.json` — confirm valid JSON after tag edits
4. Run `grep -rn "^description:" kit/plugins/*/skills/*/SKILL.md | grep -v "Use when"` — any output means a missed description rewrite
5. Open `README.md` — verify code-simplifier appears in table and versions match marketplace.json
6. Confirm `CLAUDE.md` no longer says "(Planned)"

---

## Unresolved Questions

None — scope is clear. Ready to implement on approval.

---

## Interview Summary

### Key Decisions Confirmed

- **Phase 1 approach**: Read-then-edit each of the 11 SKILL.md files individually — preserves plugin-specific nuance, catches edge cases per skill
- **README depth**: Short paragraph + example invocations per new capability (deep-grill, plan-hygiene, branch-agent, etc.) — more useful for new users than a one-liner
- **Tag trim criterion**: Remove implementation-detail tags (`subagents`, `background`, `slash-commands`, `running-tests`, `session-audit`) — not what users would search
- **Scope statement format**: Mirror the convention used by `skill-reviewer` as the canonical reference

### Plan Naming

| Element | Current | Issue | Resolved |
|---------|---------|-------|----------|
| Filename | `review-the-project-and-humming-turing.md` | "humming-turing" is random — unrelated to content | Renamed to `improve-plugin-skill-adoption.md` ✓ |
| H1 Heading | `# Plan: Plugin & Skill Usability / Adoption Improvements` | Descriptive and aligned | No change needed |

### Open Risks & Concerns

1. **Activation verification gap** — "Test 2–3 prompts per skill" is the entire quality gate for Phase 1. Without concrete example prompts or pass/fail criteria per skill, a rewrite can pass verification and still silently fail in production.
2. **Missing CHANGELOG + version bumps** — Six or more plugins will have content or metadata changes. Per `marketplace.md`, these require CHANGELOG entries and PATCH version bumps. The plan has no mention of this.
3. **README format spec not in plan** — Chosen depth (short paragraph + examples) isn't captured in Phase 2 steps. Implementer reading cold won't know the format.
4. **No canonical scope statement reference** — Phase 1.2 says to match existing conventions but doesn't name a reference skill.

### Recommended Amendments Before Implementation

1. Update Phase 1.2 — name `skill-reviewer` as the canonical reference for scope statement format
2. Update Phase 2 — add: "Each new capability entry = short paragraph + one example invocation"
3. Add Phase 5 — CHANGELOG + version bump: for each modified plugin, add a PATCH CHANGELOG entry and bump version in `marketplace.json`
4. Strengthen Verification step 3 — add grep check: `grep -rn "^description:" kit/plugins/*/skills/*/SKILL.md | grep -v "Use when"` — any output indicates a missed rewrite

### Simplification Opportunities

None — the plan is appropriately scoped with no over-engineering.
