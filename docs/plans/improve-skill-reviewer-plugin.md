# Plan: Improve Skill Reviewer Plugin

## Summary

Update the `skill-reviewer` plugin based on Anthropic's "The Complete Guide to Building Skills for Claude" (Jan 2026) and add a new `planning-skills` skill for designing and scaffolding new skills.

## Changes

### 1. Update `references/best-practices.md`

Add new sections based on the Anthropic guide:

- **Folder Structure** — kebab-case naming, case-sensitive `SKILL.md`, optional `scripts/`, `references/`, `assets/` subdirectories
- **Three-Level Progressive Disclosure** — Level 1 (frontmatter, always loaded), Level 2 (body, on activation), Level 3 (linked files, on demand)
- **Word Count Threshold** — add 5,000-word limit alongside the existing 500-line limit
- **Design Pattern Awareness** — Sequential/Pipeline, Orchestrator, Iterative/Refinement, Adaptive patterns
- **Skill Packs** — when multiple skills in one plugin is appropriate
- **New anti-patterns** — hardcoded absolute paths, exceeding 5,000 words without references, missing script permissions

### 2. Update `references/audit-steps.md`

Enrich existing 5 scoring dimensions:

- **Dimension 2 (Body Quality)** — add word count check (5,000 words)
- **Dimension 3 (Structure)** — add folder structure checks, three-level architecture verification
- **Dimension 4 (Anti-patterns)** — add new anti-patterns from guide
- **Step 2 metrics** — add word count and folder structure to report format

### 3. Update `reviewing-skills/SKILL.md`

- Update Step 2 to measure word count and check folder structure
- Update Quick Reference Checklist with new checks

### 4. New skill: `planning-skills`

Full skill planning workflow:

1. Determine what the user wants to build
2. Help choose a design pattern (Sequential, Orchestrator, Iterative, Adaptive)
3. Plan the folder structure (SKILL.md, scripts/, references/)
4. Draft YAML frontmatter (name + description with triggers)
5. Outline the SKILL.md body structure
6. Generate the scaffolding files on disk

Files:
- `skills/planning-skills/SKILL.md`
- `skills/planning-skills/references/design-patterns.md`

### 5. Version & Metadata

- Bump version: `1.0.1` → `1.1.0` (MINOR — new skill added)
- Update `plugin.json`, `marketplace.json`, `CHANGELOG.md`, `README.md`
