# The skill-authoring rule

A guide to `.claude/rules/skill-authoring.md`: what it checks, when it fires, and how to satisfy it before saving any change under `skills/`.

> **Origin.** Written 2026-06-17 as the self-verification artifact for the `dev-explainer-doc` skill (in the `social-media-tools` plugin). The skill's smoke test calls for a guide about a rule in `.claude/rules/`; the originally-named `imports.md` does not exist in this repo, so this guide documents the real, present rule `skill-authoring.md` instead. It exists both to verify the skill produces a compliant 12-section doc and to be a genuinely useful reference for anyone editing a skill here.

---

## Table of contents

1. [The rule in one sentence](#1-the-rule-in-one-sentence)
2. [What it is](#2-what-it-is)
3. [Why it exists](#3-why-it-exists)
4. [How it works structurally](#4-how-it-works-structurally)
5. [How it fires](#5-how-it-fires)
6. [Decision criteria](#6-decision-criteria)
7. [Operational script — what to actually do](#7-operational-script--what-to-actually-do)
8. [Boundaries — what it does NOT cover](#8-boundaries--what-it-does-not-cover)
9. [Interactions with related systems](#9-interactions-with-related-systems)
10. [Project-specific context](#10-project-specific-context)
11. [Maintenance and audit](#11-maintenance-and-audit)
12. [Verification protocol](#12-verification-protocol)

---

## 1. The rule in one sentence

**Before saving any change to a `SKILL.md` or a bundled file under `skills/`, verify it against Anthropic's checklist for effective Skills.**

Everything below unpacks that sentence.

---

## 2. What it is

The rule is a path-scoped instruction file at `.claude/rules/skill-authoring.md`. Its frontmatter
scopes it to skill files and states its purpose:

```yaml
---
description: Verify SKILL.md changes against Anthropic's effective-skills checklist
paths:
  - "kit/plugins/**/skills/**"
---
```

The body opens with the binding instruction, quoted verbatim:

> Before saving changes to a `SKILL.md` (or any bundled file under `skills/`), verify the skill meets Anthropic's [checklist for effective Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills).

It then carries three things:

- **A checklist**, grouped into Core quality, Code and scripts (apply only if the skill bundles executable scripts), and Testing.
- **Frontmatter constraints**, quoted verbatim — the hard validation rules enforced by the skill runtime:

  > - `name`: lowercase kebab-case, ≤64 chars, no XML tags, no reserved words (`anthropic`, `claude`)
  > - `description`: non-empty, ≤1024 chars, third person, no XML tags

- **A deferred-tools note** for `ExitPlanMode` and similar tools, requiring both `ToolSearch` and the deferred tool in `allowed-tools`.

---

## 3. Why it exists

A skill's quality is invisible at author time and expensive at use time. A vague `description`
fails to trigger; a 600-line `SKILL.md` burns context on every invocation; an abstract example
leaves Claude guessing. None of these throws an error when you save — they degrade silently in
production. The rule moves that feedback to the moment of authoring.

It is scoped, not global, for cost reasons. A project rule without a `paths:` field loads into
every session unconditionally. By scoping to `kit/plugins/**/skills/**`, this checklist costs zero
context until Claude actually touches a skill file — the same progressive-disclosure logic the
checklist itself recommends for skills.

---

## 4. How it works structurally

`.claude/rules/` files with a `paths:` frontmatter field are conditional: they enter context only
when Claude reads a file matching the glob.

```text
Claude opens a file
  └─ Is its path under kit/plugins/**/skills/** ?
       ├─ yes → skill-authoring.md loads into context → checklist applies
       └─ no  → rule stays dormant, costs nothing
```

The checklist sorts into three groups, only two of which apply to a markdown-only skill:

| Group            | Applies when                          | Sample item                                  |
| ---------------- | ------------------------------------- | -------------------------------------------- |
| Core quality     | Always                                | "SKILL.md body is under 500 lines"           |
| Code and scripts | The skill bundles executable scripts  | "No 'voodoo constants' (all values justified)" |
| Testing          | Before sharing                        | "At least three evaluations created"         |

---

## 5. How it fires

The trigger is syntactic: the `paths` glob `kit/plugins/**/skills/**`. The rule loads when Claude
reads or edits any file under any plugin's `skills/` tree — a `SKILL.md`, a `reference/` file, a
bundled script.

What prevents it from firing:

- Editing a skill-adjacent file that sits outside the glob — for example a plugin's top-level `README.md` or `CHANGELOG.md`, which are not under `skills/`.
- Working in a repo that does not carry this rule. `.claude/rules/skill-authoring.md` is committed to this repo only; it does not travel to others.

---

## 6. Decision criteria

> *Does this change touch a `SKILL.md` or a bundled file under `skills/`?*

### 6.1 The rule applies

- You created or edited a `SKILL.md`.
- You added or changed a file under a skill's `reference/`, `templates/`, or `scripts/`.
- You changed a skill's frontmatter `name`, `description`, or `allowed-tools`.

Run the full Core quality checklist; add Code and scripts if the skill bundles executables.

### 6.2 The rule does not apply

- You edited a plugin `README.md`, `CHANGELOG.md`, or `marketplace.json` — outside the `skills/` glob.
- You edited a command (`commands/*.md`) or agent file — those have their own conventions.

### 6.3 Which checklist groups to run

- Markdown-only skill → Core quality + Testing.
- Skill with `scripts/` → Core quality + Code and scripts + Testing.

---

## 7. Operational script — what to actually do

Before you save a skill file:

- Do: read the checklist in `.claude/rules/skill-authoring.md` and walk every Core quality item.
- Do: confirm the `description` says both what the skill does and when to use it.
- Do: keep the `SKILL.md` body under 500 lines, pushing detail into one-level-deep `reference/` files.
- Do NOT: ship a `description` that only says what the skill does but not when to invoke it.
- Do NOT: inline long reference material into `SKILL.md` that belongs in a bundled file.
- Do NOT: leave `allowed-tools` implicit when the skill calls a deferred tool — list `ToolSearch` plus that tool.

When in doubt, the rule names its own escalation, quoted verbatim:

> Run `/skill-reviewer:reviewing-skills` on the skill for a scored audit against these criteria.

---

## 8. Boundaries — what it does NOT cover

1. **Non-skill files.** Commands, agents, hooks, and plugin metadata are out of scope; the glob excludes them.
2. **The runtime hard limits.** `name` ≤64 chars and `description` ≤1024 chars are enforced by the skill runtime regardless of this rule. The rule documents them; it does not implement them.
3. **The project's stricter description budget.** A separate rule, `.claude/rules/plugin-patterns.md`, sets a ≤200-char, three-part `description` convention — tighter than the 1024-char runtime cap. That budget is enforced by `/skill-reviewer:check-description`, not by this rule.
4. **Actually running evaluations.** The Testing group asks for three evaluations; the rule does not provide a runner. Evaluations are authored separately.

---

## 9. Interactions with related systems

- **`.claude/rules/plugin-patterns.md`** — the sibling rule covering the command/skill component patterns, the three-part `description` format, and the deferred-tools `allowed-tools` requirement. Read both together when authoring.
- **`skill-reviewer` plugin** — supplies the tooling this rule points to: `/skill-reviewer:reviewing-skills` (scored audit), `/skill-reviewer:check-description` (the ≤200-char budget), and `/skill-reviewer:auditing-allowed-tools` (permission audit against a transcript).
- **Deferred tools and `ToolSearch`** — the rule's `ExitPlanMode` note pairs with the harness convention that deferred tools must be loaded via `ToolSearch` before they are called.

---

## 10. Project-specific context

This guide is about a rule that exists only in this repo, and the distinction matters:

- `.claude/rules/skill-authoring.md` is **committed to this repo** and shared with everyone who clones it. It is team-facing.
- `~/.claude/rules/` (per-user, not in this repo) is a separate, machine-local rules directory under the author's home folder. Rules there apply to every project on that one machine and are never shared by cloning. Do not conflate the two: a teammate has this repo's `.claude/rules/`, but not your `~/.claude/rules/`.

Repo specifics that shape how the rule applies here:

- The glob targets `kit/plugins/**/skills/**`, matching the marketplace's plugin layout (11 plugins under `kit/plugins/`).
- The stricter ≤200-char description budget from `plugin-patterns.md` is the local house style; the 1024-char limit is the universal runtime ceiling.

---

## 11. Maintenance and audit

Update the rule when:

- Anthropic's [checklist for effective Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills) changes — re-sync the checklist items.
- The runtime frontmatter constraints change (for example a new reserved word) — update the verbatim block in §2.

Prune or rewrite it if the project's skill layout moves out from under `kit/plugins/**/skills/**`,
which would silently stop the rule from firing.

Audit by editing a skill file and confirming, via `/memory` or the session's loaded-rules list,
that `skill-authoring.md` is in context.

---

## 12. Verification protocol

### 12.1 Confirm the rule loads

Open any `SKILL.md` under `kit/plugins/*/skills/` and check the session's loaded rules. The rule
fires on path match; if it is absent, the file you opened is outside the glob.

### 12.2 Confirm the cross-references resolve

Both canonical links in this guide were `WebFetch`-verified on 2026-06-17:

- `https://code.claude.com/docs/en/skills` → "Extend Claude with skills" (HTTP 200).
- `https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices` → "Skill authoring best practices," with the `#checklist-for-effective-skills` anchor (HTTP 200).

### 12.3 Smoke test

Edit a skill `description`, then run:

> `/skill-reviewer:reviewing-skills`

**Expected:** a scored audit against the Core quality items in §2. **Failure signal:** if the
audit does not mention the checklist criteria, confirm the rule is present and the file is under
the `skills/` glob.

---

## Quick reference

```text
RULE
  .claude/rules/skill-authoring.md
  Verify every skills/ change against Anthropic's effective-skills checklist.

FIRES WHEN
  Claude reads/edits a file under kit/plugins/**/skills/**

CHECKLIST GROUPS
  Core quality      → always
  Code and scripts  → only if the skill bundles scripts/
  Testing           → before sharing

DO
  - description says what AND when
  - SKILL.md body < 500 lines
  - reference/ files one level deep
  - allowed-tools lists ToolSearch + any deferred tool

DO NOT
  - ship a what-only description
  - inline long reference material into SKILL.md
  - leave deferred tools out of allowed-tools

HARD LIMITS (runtime, not this rule)
  name        ≤ 64 chars, lowercase-kebab, no reserved words
  description ≤ 1024 chars, third person
  house style ≤ 200 chars (plugin-patterns.md, checked by check-description)

ESCALATE
  /skill-reviewer:reviewing-skills  → scored audit
```

---

## Cross-references

- [Extend Claude with skills](https://code.claude.com/docs/en/skills) — canonical Claude Code skills doc (verified).
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills) — the upstream checklist this rule enforces (verified).
- `.claude/rules/plugin-patterns.md` — sibling rule: component patterns, three-part description format, deferred-tools `allowed-tools`.
- `.claude/rules/skill-authoring.md` — the rule this guide documents.
