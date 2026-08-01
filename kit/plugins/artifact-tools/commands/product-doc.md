---
description: Publish a recap of this session or a pull request for the product team and stakeholders — features, fixes, decisions, and plan details
allowed-tools:
  - Skill
  - Read
  - Bash
---

# Product Doc

Write an artifact documenting this session — or a pull request — for the product
team and stakeholders to review.

Follow `${CLAUDE_PLUGIN_ROOT}/references/recap-core.md` for the whole workflow —
source modes and PR gathering, the blocking `security-scrub` gate, page build,
publishing, and the republish record. This file supplies only the framing.

Do not opt in to the core's diff budget. Read **Features** and **Bug fixes**
from the commit subjects and the changed-file list; the commit bodies say *why*,
which is the thing a stakeholder needs and a diff never carries.

## Audience

The product team and any non-engineering stakeholder — PM, design, support,
sales, leadership. Explain *what changed and why it matters*; keep code to what
a reader outside the codebase needs to follow the decision. Spell out internal
names and acronyms the first time they appear.

## Sections

In this order.

1. **Summary** — what this work was for and where it landed.
2. **Features** — what a user can now do that they could not before, or what
   behaves differently. One entry per feature: the capability, who it is for,
   and how to reach it (command, flag, URL, menu path).
3. **Bug fixes** — one entry per fix: the symptom someone would have hit, the
   cause in plain language, and what now happens instead. Note anything that was
   reported but *not* fixed, and why.
4. **Decisions** — with the reasoning behind each, including options weighed and
   rejected. Flag any decision still open or awaiting product input.
5. **Logic and behavior changes** — rules, defaults, limits, or edge-case
   handling that changed but that no feature or fix line already covers.
6. **Implementation plan details** — link or inline any plan file touched, with
   its current status, which steps closed, and what remains.
7. **Known gaps and follow-ups** — this command's open-items section: anything
   deferred, stubbed, or left unverified, so the product team is not surprised
   later.
8. **Files touched** — grouped by area, with a short note on why each changed.

## Destination and republish key

Favicon `📋`. Inbox stem `product-doc`, or `pr-<number>-doc` in PR mode.

This command writes `product-artifact-url:` and nothing else.

**Never write `artifact-url:`, `eng-artifact-url:`, or `team-artifact-url:`.**
Those belong to `session-artifact`, `eng-recap`, and `team-recap`, which share
this record. The first is the reviewer-first recap `session-artifact` publishes
from the same deterministic per-session file.
