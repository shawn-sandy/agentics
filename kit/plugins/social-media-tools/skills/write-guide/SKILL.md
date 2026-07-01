---
name: write-guide
description: Writes developer guides on any project topic. Covers rules, tools, resources, plans, and changes for any reader. Use when the user asks to write, explain, or deep-dive a project topic as a guide.
version: 0.1.0
allowed-tools: Read, Glob, Grep, Bash, WebFetch, WebSearch, Write, Edit, AskUserQuestion, TodoWrite
---

# write-guide

Write a long-form developer guide that explains any project topic in depth — systems, rules,
concepts, tools, resources, plans, changes, or saved memories — for internal teammates or external
contributors alike. The output is a single Markdown file in `<plansDirectory>/guides/`, assembled
from a section library to fit the topic and written in a strict tone. Five archetypes (system
explainer, rule deep-dive, how-to/tutorial, concept explainer, change recap) offer non-binding
starting shapes.

This is a writing skill with a verification spine: every external URL, file path, and quoted
fact is checked against its source before it lands in the doc. A guide that ships an unverified
claim is a defect, not a draft.

## What this skill produces

- One Markdown file saved to a `guides/` subfolder inside the configured `plansDirectory` (e.g.
  `docs/plans/guides/`), named in `verb-target` kebab-case — e.g. `explain-memory-recall.md`,
  `review-bot-loop-discipline.md`, never `guide.md`.
- The file's body is assembled from the section library in
  `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/skeleton.md` — sections chosen, ordered,
  and blended to fit the topic.
- Concrete throughout: real file paths, verbatim frontmatter/configs/verdicts, cited numbers,
  ASCII diagrams for flows, tables for comparisons.

## When to use

Invoke when the user says any of:

- "Write a guide on X"
- "Document this rule"
- "Create a developer doc for X"
- "Explain X as a guide"
- "Deep-dive X"
- "Capture this session's lessons as a guide"
- "Write an explainer for X"

## When NOT to use

Do not invoke for these — redirect instead:

- **README updates** — suggest editing the existing `README.md` directly; do not produce a `docs/` guide.
- **API reference docs** — these need a reference format (signatures, params, return types), not this narrative section library. Decline and say so.
- **Marketing copy or press releases** — out of scope; this skill writes developer-facing guides, not promotional content.
- **Blog posts** — use the `share-blog` skill instead.
- **Status reports, leadership updates, incident comms** — use the `internal-comms` skill instead.
- **Single-paragraph notes or commit messages** — too small for a guide; write the note inline.
- **Plan-completion docs** — a change-recap guide tells the story of a change for readers; generating the canonical documentation for a completed plan file belongs to `plan-interview:documenting-plans`.

If the request is ambiguous between a guide and one of the above, ask before drafting.

## Before you write: load the bundled references

Read all three before drafting. They are the authoritative spec for structure, voice, and the
style models — do not reconstruct them from memory:

1. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/skeleton.md` — the section library: twelve documented section intents and devices to assemble a guide from. Pick what the topic needs.
2. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/tone-rules.md` — tone rules and the mandatory discipline rules, each expanded with a worked example.
3. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/exemplars.md` — five archetypes (system-explainer, rule-deep-dive, how-to, concept-explainer, change-recap), each a non-binding starting point, plus the picker for choosing one.

## Workflow

Follow these steps in order.

1. **Clarify.** If the topic, the intended audience, or the save location is ambiguous, use
   `AskUserQuestion` with up to 3 batched questions. Skip this step entirely when the request is
   self-evident — do not add friction to a well-specified ask.

2. **Source.** Gather facts, in this priority order. Stop when you have enough to fill the
   sections the topic needs; do not over-collect.
   - Current conversation — if the topic was just discussed, the freshest source is here.
   - Files the user named — `Read` them in full.
   - Memory files — read them, but treat their contents as frozen-in-time (see discipline rule 3).
   - Git history — `git log`, `git show`, `git blame` for the story of why something exists.
   - Code search — `Grep`/`Glob` for related symbols, configs, call sites.
   - External canonical docs — `WebFetch` only, verified URLs only (see discipline rule 1).

3. **Structure.** Map what you gathered onto the section library. Decide per section whether it
   genuinely applies. Omit the ones that do not — never emit an empty stub or a section padded with
   filler to look complete.

4. **Select a starting archetype.** Pick the closest of the five archetypes in `exemplars.md` as a
   starting point, then assemble the body from the section library to fit the topic — add, drop,
   reorder, or blend sections freely. The archetype is a starting shape, not a contract; deviate
   whenever the topic demands it.

5. **Verify externals.** Fan out `WebFetch` calls in parallel for every external URL you intend to
   cite. Confirm each resolves (HTTP 200) and paste the canonical destination, not a redirector.

6. **Verify on-disk.** `Read` or `Grep` every file path, function name, line number, and
   frontmatter field before you cite it. A path that 404s or a function that was renamed is a
   defect.

7. **Write.** Draft the doc applying every tone rule. Where a library section appears, use its
   device as the library prescribes: a bold thesis opening the rule/thesis section, an
   italic-blockquote diagnostic question opening decision criteria, paired do / do-NOT in the
   operational script, numbered carve-outs in boundaries.

8. **Cross-link.** Point upward to canonical external docs and sideways to sibling internal docs
   and relevant config files. Label per-user paths (`~/.claude/...`) and memory wikilinks
   (`[[name]]`) as per-user, not in this repo, whenever they appear (discipline rule 6).

9. **Name.** Choose a `verb-target` kebab-case filename that names the topic. Reject generic names
   like `guide.md`, `doc.md`, `notes.md`.

10. **Save.** Resolve the target directory in order: (1) `<plansDirectory>/guides/` if
   `plansDirectory` is configured — read it via Claude Code's settings precedence (project-local
   `.claude/settings.local.json` → project `.claude/settings.json` → global
   `~/.claude/settings.json`); (2) `docs/guides/` if that directory exists; (3) `docs/` at the
   repo root as a last fallback. Create the `guides/` subfolder if it does not exist. Honor an
   explicit user-specified path above all other resolution rules.

11. **Confirm.** Return the saved file as a clickable Markdown link plus a one-paragraph summary of
    what the doc covers, which archetype it started from, and how the shape deviated (if it did).

## Invariant spine (every guide)

Whatever shape the body takes, every guide carries the same spine: a provenance callout
(`> **Origin.**` or `> **Status.**`) up front, a body assembled from the section library, a closing
Quick reference (ASCII), and a Cross-references list — held to the six discipline rules below. The
enforced contract is this spine plus the depth bar (at least one verbatim-quoted primary source and
at least one worked example per guide) — never any fixed section sequence.

## Discipline rules (mandatory)

These are enforced, not advisory. A guide that breaks one is incomplete.

1. **Verify every external URL with `WebFetch` before pasting.** If a URL redirects, paste the
   canonical destination — never the redirector.
2. **Verify every on-disk fact** — path, function, line number, frontmatter field — with `Read`
   or `Grep` before citing it.
3. **Treat memory contents as frozen-in-time.** A memory names what was true when it was written.
   Re-verify against current state before citing it.
4. **Quote primary sources verbatim** — frontmatter, error messages, commit titles, verdicts,
   configs. Do not paraphrase a thing you can quote.
5. **Mark uncertainty explicitly.** Never invent a fact to fill a gap. Writing "unverified" is
   acceptable; fabrication is not.
6. **Match the doc's audience to its location.** A committed `docs/` file may be read by external
   contributors who clone the repo and have no access to your `~/.claude/`. Linking to per-user
   paths or `[[memory wikilinks]]` without the "per-user, not in this repo" disclaimer is a defect.
   When the guide is explicitly for an external audience, omit per-user paths entirely.

## Before delivering: self-check

Confirm all of the following before returning the file:

- The filename is `verb-target` kebab-case, not generic.
- The file opens with a title, a one-sentence subtitle, and a `> **Origin.**` (or `> **Status.**`) callout.
- Every section in the body earns its place: chosen from the section library because it fits the topic — no empty stubs, no section padded in to look complete, no section the topic needs missing.
- The depth bar is met: at least one primary source is quoted verbatim and at least one worked example appears in the guide.
- Every external URL was `WebFetch`-verified this session.
- Every cited path / symbol / frontmatter field was `Read` or `Grep`-confirmed this session.
- Primary sources are quoted verbatim, not paraphrased.
- Per-user paths and memory wikilinks carry the "per-user, not in this repo" disclaimer.
- The doc closes with a Quick reference (ASCII) and a Cross-references list.
