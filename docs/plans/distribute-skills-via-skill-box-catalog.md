---
status: planned
created: 2026-06-12
---

# Plan: Distribute skills via a skill-box catalog (Option 3)

## Context

The repo distributes plugins through the Claude Code plugin marketplace
(`.claude-plugin/marketplace.json` → `scripts/build-dist.mjs` → published to
`agentics-kit` by `.github/workflows/publish-dist.yml`). The
[vercel-labs/skills](https://github.com/vercel-labs/skills) CLI (`npx skills`)
is a separate, cross-agent channel that installs individual **skills** (any
directory with a `SKILL.md` carrying `name` + `description`) into 70+ agents,
including Claude Code (`./.claude/skills/` or `~/.claude/skills/`).

That CLI discovers skills under a root `skills/` directory (flat
`skills/<name>/SKILL.md` or catalog `skills/<category>/<name>/SKILL.md`). This
repo nests skills at `kit/plugins/<plugin>/skills/<name>/SKILL.md`, too deep for
a bare repo-level install to find. **Option 3** closes that gap by having
`build-dist.mjs` emit a curated `skills/` catalog into `dist/`, which the
existing publish step copies to the `agentics-kit` root.

Decisions already made (do not re-litigate):

- **Catalog home:** `dist/` only → published to `agentics-kit`. Install surface
  is `npx skills add shawn-sandy/agentics-kit`. Source repo stays clean; no new
  workflow wiring.
- **Curation:** an explicit allowlist in `scripts/skill-catalog.json` plus a
  build-time lint guard — **not** a heuristic.
- **Layout:** catalog form `dist/skills/<plugin>/<skill>/…`, copying the whole
  skill directory (skill dirs carry `references/`, `assets/`, `scripts/`).

### Hard constraints discovered during investigation

- The skills CLI copies **only the skill directory** — no sibling `commands/`,
  `agents/`, or `hooks/`. Any skill whose `SKILL.md` body invokes a
  `/<plugin>:<command>`, spawns a plugin agent, or relies on a hook is broken
  when installed standalone. Curation must exclude these.
- A heuristic like "plugins with no `commands/` dir" is unreliable:
  `kit/plugins/issue-agent/skills/create-issue/SKILL.md` references a slash
  command despite issue-agent being skills-only.
- On the user's machine the CLI flattens installs to `.claude/skills/<name>/`,
  so cataloged skill **names** must be globally unique. They are today (no
  duplicate `SKILL.md` directory names across plugins) — the build must enforce
  this so a future collision fails the build, not the user's install.
- Skill dirs carry real payload (58 supporting files across `references/`,
  `assets/`, `scripts/`, `reference/`). The copy must take the whole dir.
- Frontmatter: every `SKILL.md` already has `name` + `description`. The extra
  `allowed-tools` key is Claude-specific and ignored by other agents — leave it.

## Changes

### 1. New curated allowlist — `scripts/skill-catalog.json`

```json
{
  "skills": [
    "memory-tools/agentic-memory-doctor",
    "memory-tools/path-rules-advisor",
    "wcag-compliance-reviewer/wcag-compliance-reviewer"
  ]
}
```

- Each entry is `"<plugin>/<skill>"` relative to `kit/plugins/<plugin>/skills/`.
- Starter shortlist must be confirmed before merge (see Open Questions). Only
  standalone-safe skills — verified to have no dangling command/agent/hook
  dependency — go in.

### 2. `scripts/build-dist.mjs` — add a `buildSkillCatalog()` pass

**File:** `scripts/build-dist.mjs`

- Add `SKILL_CATALOG_PATH = join(ROOT, 'scripts', 'skill-catalog.json')`.
- Add `parseFrontmatter(content)` helper — minimal YAML-frontmatter reader that
  extracts `name` and `description` (avoid a new dependency; the existing build
  has none).
- Add `assertNoDanglingRefs(ref, mdPath)` — scan the `SKILL.md` body for
  `/<word>:<word>` slash-command patterns and agent-spawn language; throw with
  the offending `ref` if found. (Guard against curation rot.)
- Add `buildSkillCatalog()`:
  1. Read `scripts/skill-catalog.json`.
  2. For each `"<plugin>/<skill>"`:
     - Resolve `src = kit/plugins/<plugin>/skills/<skill>`; throw if
       `SKILL.md` is missing.
     - Parse frontmatter; throw if `name` or `description` is absent.
     - Maintain a `Map<name, ref>`; throw on duplicate skill `name`.
     - Run `assertNoDanglingRefs`.
     - Copy the whole `src` dir to `dist/skills/<plugin>/<skill>/`, honoring
       `matchesDrop()` and reusing `copyFileMaybeTransform()` (keeps the
       `agentics` → `agentics-kit` URL rewrite consistent).
  3. Optionally write `dist/skills/README.md` — a human index listing each
     cataloged skill, its plugin, and description.
- Call `buildSkillCatalog()` at the end of `build()`, after the root-files pass.
- Extend `check()` to assert: `dist/skills/` exists, every leaf has a
  `SKILL.md`, names are unique, and no DROP patterns leaked into `dist/skills/`.

### 3. Tests

**File:** `tests/publish/smoke-clean-dist.sh`

- After the existing plugin-dir checks, assert `dist/skills/` exists and each
  expected `<plugin>/<skill>/SKILL.md` is present.

**File (new):** `tests/publish/test-skill-catalog.mjs`

- Mirrors `tests/publish/test-dist-transforms.mjs` style (pass/fail counter).
- Asserts: cataloged dir count matches `scripts/skill-catalog.json`; every
  `SKILL.md` has `name` + `description`; names are globally unique; no body
  contains a dangling `/<plugin>:<command>` ref.
- Wire it into `.github/workflows/publish-dist.yml` after the existing
  "Test dist transforms" step (run against the freshly built `dist/`).

### 4. README install instructions

**File:** `README.md` (dev copy; `transformReadmeForDist` rewrites it for dist)

- Add a short "Install skills with the `skills` CLI" section:
  - `npx skills add shawn-sandy/agentics-kit`
  - `npx skills add shawn-sandy/agentics-kit --skill <name> -a claude-code -y`
- The existing transform already rewrites `agentics` → `agentics-kit`, but
  author the lines with the dist URL so they read correctly in both repos.

### 5. Docs / rules

**Files:** `CLAUDE.md`, `.claude/rules/marketplace.md`

- Note the cross-agent skill-box channel alongside the plugin marketplace, and
  point to `scripts/skill-catalog.json` as the curation surface (what to edit
  when adding/removing an exported skill).

## Files Modified

- `scripts/skill-catalog.json` — **new** curated allowlist
- `scripts/build-dist.mjs` — `buildSkillCatalog()` pass + `check()` extension
- `tests/publish/smoke-clean-dist.sh` — assert catalog presence
- `tests/publish/test-skill-catalog.mjs` — **new** catalog validation test
- `.github/workflows/publish-dist.yml` — run the new test
- `README.md` — `npx skills add` instructions
- `CLAUDE.md`, `.claude/rules/marketplace.md` — document the channel
- This plan file

## Verification

1. `node scripts/build-dist.mjs` — confirm `dist/skills/<plugin>/<skill>/` is
   created for each allowlist entry, with `SKILL.md` and all support files.
2. `node scripts/build-dist.mjs --check` — passes (catalog present, names
   unique, no DROP leaks).
3. `bash tests/publish/smoke-clean-dist.sh` — passes with catalog assertions.
4. `node tests/publish/test-skill-catalog.mjs` — passes.
5. Negative checks: temporarily add a non-existent skill, a duplicate name, and
   a skill with a `/plugin:command` ref to `skill-catalog.json`; confirm the
   build throws on each, then revert.
6. Manual end-to-end (optional, post-publish): in a scratch dir,
   `npx skills add shawn-sandy/agentics-kit --skill agentic-memory-doctor -a claude-code -y`
   and confirm it lands in `.claude/skills/`.

## Open Questions

- **Starter shortlist.** Confirm which skills ship first. Likely-safe:
  `memory-tools/agentic-memory-doctor`, `memory-tools/path-rules-advisor`,
  `wcag-compliance-reviewer/wcag-compliance-reviewer`. Verify-then-add:
  `skill-reviewer/*`, `code-testing-agent/reviewing-tests`. Excluded unless
  reworded: `issue-agent/create-issue` (references a slash command).

## Next Steps (Out of Scope)

- A dev-repo catalog so `npx skills add shawn-sandy/agentics` (main repo) works
  — rejected for now (checks a generated artifact into source; needs a CI
  in-sync guard).
- `skills.json`/registry metadata beyond per-skill frontmatter.
- Auto-deriving the allowlist from a `distribution:` frontmatter key instead of
  a separate manifest.
