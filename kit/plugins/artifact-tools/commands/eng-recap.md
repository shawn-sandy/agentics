---
description: Publish an engineering recap of this session or a pull request — architecture, code paths, tradeoffs, learnings, tests, and review follow-ups, written for the engineer who touches this code next
allowed-tools:
  - Skill
  - Read
  - Bash
---

# Eng Recap

Write an artifact explaining what changed in this session — or in a pull request
— for **the engineer who has to touch this code next**: the person who will open
these files on a Monday with no memory of the work.

Follow `${CLAUDE_PLUGIN_ROOT}/references/recap-core.md` for the whole workflow —
source modes and PR gathering, the blocking `security-scrub` gate, page build,
publishing, and the republish record. This file is only the framing.

**Opt in to the diff budget** in `references/recap-core.md` — this command reads
the diff hunks, which its two siblings deliberately do not, because a changed
signature or a new error path is real signal here. **Architecture and code
paths** comes out of them.

## Audience

Engineers, and only engineers — the inverse of `team-recap`, which leads with
plain language and glosses every name. Do the opposite:

- **Lead with the technical fact**, then context if still needed.
- **Assume the vocabulary.** Repo terms, framework names, and internal acronyms
  are used directly, not glossed. There is no glossary.
- **Code appears freely** — signatures, config values, invariants, commands.
  It is often the shortest correct statement.

The reclaimed space is the point: what is not spent on translation goes to the
detail the next maintainer needs.

## Sections

In this order. **Learnings is always kept** — the one exception to the core's
omit-empty-sections rule, because dropping it reads as "no dead ends" rather
than "nobody wrote them down".

1. **At a glance** — a stat strip (changes, files, decisions, open items), then
   two or three sentences on where it landed.
2. **Architecture and code paths** — entry points, call flow, which module owns
   what, what to read first. This is what makes the recap worth opening at all.
3. **Decisions** — each with its rationale. A decision without its why is
   unreviewable.
4. **Tradeoffs and rejected options** — what was weighed and lost, and what it
   would take to revisit. This stops re-litigation of settled questions.
5. **Learnings** — what was **tried and abandoned**, and the gotchas found. A
   tradeoff was weighed; a learning was walked. Answer explicitly, including
   with "none for this source" — usually the case in PR mode.
6. **Tests and verification** — coverage added or changed, how it was verified,
   and — explicitly — what is knowingly untested.
7. **Review follow-ups and tech debt** — this command's open-items section:
   unresolved threads, TODOs, shortcuts, and known ceilings with upgrade paths.
8. **Files touched** — grouped by area, one line each on why it changed.

## Destination and republish key

Favicon `🔧`. Inbox stem `eng-recap`, or `pr-<number>-eng` in PR mode. Writes
`eng-artifact-url:` and nothing else.

**Never write `artifact-url:`, `product-artifact-url:`, or `team-artifact-url:`.**
Those belong to `session-artifact`, `product-doc`, and `team-recap`, which share
this record.
