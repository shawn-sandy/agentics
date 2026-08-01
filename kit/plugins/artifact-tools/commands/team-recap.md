---
description: Publish a detailed, visual recap of this session or a pull request for the whole team — diagrams, before/after, decisions, and open items, readable by engineers and non-engineers alike
allowed-tools:
  - Skill
  - Read
  - Bash
---

# Team Recap

Write an artifact explaining what changed in this session — or in a pull request
— for **everyone on the team**: the engineer who will touch this code next and
the teammate who only needs to know what moved.

Follow `${CLAUDE_PLUGIN_ROOT}/references/recap-core.md` for the whole workflow —
source modes and PR gathering, the blocking `security-scrub` gate, page build,
publishing, and the republish record. This file supplies only the framing.

Do not opt in to the core's diff budget. Read **What changed** from the commit
subjects and the changed-file list. Draw a diagram only where the change list
shows structure or flow actually moved.

## Audience

Mixed, in one document — not two versions of it. Write so a non-engineer can
follow the *what* and *why* top-to-bottom without opening the code, while an
engineer still finds the file paths, function names, and rationale they need.

- Lead every section with the plain-language statement, then the technical
  detail. Never the reverse.
- Spell out every internal name, acronym, or repo-specific term the first time
  it appears, and collect them in the Glossary.
- Code appears only when it is the clearest way to say the thing — a config
  value, a signature that changed, a command someone will run.

## Sections

In this order.

1. **At a glance** — a stat strip (changes, files, decisions, open items), then
   two or three sentences on where the work landed.
2. **What changed** — one card per change: a plain-language title, who it
   affects (users, teammates, nobody yet), what is different now, and how to
   reach it (command, flag, path, URL).
3. **How it works now** — the mermaid section. Flow, sequence, or state diagrams
   for anything whose shape changed. Caption each one.
4. **Before and after** — a two-column table for changed behavior, defaults,
   limits, and edge-case handling. One row per rule, in the reader's words.
5. **Decisions** — each with its rationale *and* the options weighed and
   rejected. A rejected option is what stops the next person re-litigating it.
6. **Learnings** — what was tried and abandoned, and the gotchas found. Keep the
   heading and say so explicitly if the source produced none.
7. **Open items** — this command's open-items section: deferred, stubbed, or
   unverified work, each with enough context to pick up cold.
8. **Files touched** — grouped by area, one line each on why it changed.
9. **Glossary** — every term from the page that a new teammate would have to ask
   about, in one sentence each.

## Destination and republish key

Favicon `🧭`. Inbox stem `team-recap`, or `pr-<number>-recap` in PR mode.

This command writes `team-artifact-url:` and nothing else.

**Never write `artifact-url:`, `product-artifact-url:`, or `eng-artifact-url:`.**
Those belong to `session-artifact`, `product-doc`, and `eng-recap`, which share
this record.
