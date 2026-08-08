---
name: teach-artifact
description: "Publishes a teaching page as a claude.ai artifact. Explains how the system behind a session or a pull request actually works, scrubs, then publishes. Use when asked to publish an explainer."
allowed-tools: Bash, Read, Write, Edit, Skill, Artifact, WebFetch, AskUserQuestion, ToolSearch, ExitPlanMode
---

# teach-artifact

Publish a page that **teaches how the thing works** to someone who was not here,
sourced from the same two places the recap commands read: this session, or a
pull request.

## Overview

The kit already has four ways to publish a page and every one of them reports —
what changed, what was decided, what is open. This is the fifth, and it inverts
the question: the change is only the raw material, the subject is the system, and
the reader is someone who has to understand it rather than review it.

Everything mechanical is borrowed. `${CLAUDE_PLUGIN_ROOT}/references/recap-core.md`
owns source resolution and PR gathering, the blocking scrub gate, the page build,
publishing, and the republish record — unchanged. This skill supplies framing
only, and `${CLAUDE_PLUGIN_ROOT}/references/teach-framing.md` supplies the rest of it.

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Workflow

Read `references/recap-core.md` and follow it end to end. Two overrides:

1. **Opt in to the diff budget** in that file. Teaching how something works needs
   the real signatures and error paths, which commit bodies never carry — the same
   reason `eng-recap` opts in and the other two recaps deliberately do not. The cap
   is 20 files; past it, take paths from `--name-only` and report how many files
   were summarized rather than read.
2. **Take the sections from `references/teach-framing.md`,** not from the core's
   omit-empty default. That file's spine is fixed for both sources and every one of
   its sections is always kept. It also overrides the core's two PR-mode section
   rules — this page has no open-items section and no **Learnings** heading for
   review threads to land in, and that file says where their signal goes instead.

## Audience

Someone competent who has never seen this system — a new teammate, or the same
teammate in six months. Not a reviewer: they are not checking your work, they are
trying to hold the thing in their head.

- **Explain the system, not the changelog.** Present tense throughout. "The hook
  fires on every plan write" teaches; "we added a hook" reports.
- **Assume general skill, not local vocabulary.** Framework names pass without
  gloss; every repo-specific name is defined the first time it appears.
- **Code appears where it is the shortest true statement** — a signature, a config
  value, a command someone will run.

## Sections

`references/teach-framing.md` — the five-part spine, the two diagram rules, the
walkthrough rules, and the reviewer test that keeps this page distinct from
`team-recap`. Read it before writing a line of the page.

## Scrub before publishing (blocking gate)

The core's gate is this skill's gate, and it runs before anything ships. Run
`social-media-tools:security-scrub` over the drafted page via the `Skill` tool —
a teaching page quotes source files and command output more freely than a recap
does, since that quoting is the teaching.

- `GATE RESULT: BLOCKED` → **hard stop.** No publish, no override. Report the
  masked findings and stop.
- `GATE RESULT: CANCELLED` → the user declined. Stop.
- `GATE RESULT: APPROVED` → continue.

If `security-scrub` is unavailable, say the scan could not run and ask via
`AskUserQuestion` before continuing — never skip the gate silently.

## Publish

Only after `APPROVED`. Load the publish tool with `ToolSearch` using
`select:Artifact`, then publish per the core's Destination section, favicon
stable across republishes. On publish failure the drafted page is still the
deliverable: report its path and say publishing did not happen, and why.

## Destination and republish key

Favicon `📘`. Inbox stem `teach-artifact`, or `pr-<number>-teach` in PR mode.

This skill writes `teach-artifact-url:` and nothing else. All five writers share
one record — per session in session mode, per PR number in PR mode — so reusing
a sibling's key republishes this page over theirs:

- **Never write `artifact-url:`** — `session-artifact`'s.
- **Never write `product-artifact-url:`** — `product-doc`'s.
- **Never write `team-artifact-url:`** — `team-recap`'s.
- **Never write `eng-artifact-url:`** — `eng-recap`'s.
