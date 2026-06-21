---
name: write-guide
description: Writes developer guides on any project topic. Covers rules, tools, resources, plans, and changes for any reader. Use when the user asks to write, explain, or deep-dive a project topic as a guide.
version: 0.1.0
allowed-tools: Read, Glob, Grep, Bash, WebFetch, WebSearch, Write, Edit, AskUserQuestion, TodoWrite
---

# write-guide

Write a long-form developer guide that explains any project topic in depth — systems, rules,
concepts, tools, resources, plans, changes, or saved memories — for internal teammates or external
contributors alike. The output is a single Markdown file in `<plansDirectory>/guides/`, built to a fixed 12-section
skeleton and a strict tone, modeled on two canonical exemplars (a broad system explainer and a
narrow single-rule deep-dive).

This is a writing skill with a verification spine: every external URL, file path, and quoted
fact is checked against its source before it lands in the doc. A guide that ships an unverified
claim is a defect, not a draft.

## What this skill produces

- One Markdown file saved to a `guides/` subfolder inside the configured `plansDirectory` (e.g.
  `docs/plans/guides/`), named in `verb-target` kebab-case — e.g. `explain-memory-recall.md`,
  `review-bot-loop-discipline.md`, never `guide.md`.
- The file follows the 12-section skeleton in
  `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/skeleton.md`.
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
- **API reference docs** — these need a reference format (signatures, params, return types), not this narrative skeleton. Decline and say so.
- **Marketing copy or press releases** — out of scope; this skill writes developer-facing guides, not promotional content.
- **Blog posts** — use the `share-blog` skill instead.
- **Status reports, leadership updates, incident comms** — use the `internal-comms` skill instead.
- **Single-paragraph notes or commit messages** — too small for a guide; write the note inline.

If the request is ambiguous between a guide and one of the above, ask before drafting.

## Before you write: load the bundled references

Read all three before drafting. They are the authoritative spec for structure, voice, and the
style models — do not reconstruct them from memory:

1. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/skeleton.md` — the 12-section template, verbatim. Every guide follows it.
2. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/tone-rules.md` — tone rules and the mandatory discipline rules, each expanded with a worked example.
3. `${CLAUDE_PLUGIN_ROOT}/skills/write-guide/references/exemplars.md` — synopsis of the two exemplar docs (broad explainer vs. single-rule deep-dive) and which to model for a given topic.

## Workflow

Follow these steps in order.

1. **Clarify.** If the topic, the intended audience, or the save location is ambiguous, use
   `AskUserQuestion` with up to 3 batched questions. Skip this step entirely when the request is
   self-evident — do not add friction to a well-specified ask.

2. **Source.** Gather facts, in this priority order. Stop when you have enough to fill the
   skeleton; do not over-collect.
   - Current conversation — if the topic was just discussed, the freshest source is here.
   - Files the user named — `Read` them in full.
   - Memory files — read them, but treat their contents as frozen-in-time (see discipline rule 3).
   - Git history — `git log`, `git show`, `git blame` for the story of why something exists.
   - Code search — `Grep`/`Glob` for related symbols, configs, call sites.
   - External canonical docs — `WebFetch` only, verified URLs only (see discipline rule 1).

3. **Structure.** Map what you gathered onto the 12-section skeleton. Decide per section whether it
   genuinely applies. Omit the ones that do not — never emit an empty stub or a section padded with
   filler to look complete.

4. **Verify externals.** Fan out `WebFetch` calls in parallel for every external URL you intend to
   cite. Confirm each resolves (HTTP 200) and paste the canonical destination, not a redirector.

5. **Verify on-disk.** `Read` or `Grep` every file path, function name, line number, and
   frontmatter field before you cite it. A path that 404s or a function that was renamed is a
   defect.

6. **Write.** Draft the doc applying every tone rule. Lead each major section as the skeleton
   prescribes: bold thesis in §1, italic-blockquote diagnostic question in §6, paired do / do-NOT
   in §7, numbered carve-outs in §8.

7. **Cross-link.** Point upward to canonical external docs and sideways to sibling internal docs
   and relevant config files. Label per-user paths (`~/.claude/...`) and memory wikilinks
   (`[[name]]`) as per-user, not in this repo, whenever they appear (discipline rule 6).

8. **Name.** Choose a `verb-target` kebab-case filename that names the topic. Reject generic names
   like `guide.md`, `doc.md`, `notes.md`.

9. **Save.** Resolve the target directory in order: (1) `<plansDirectory>/guides/` if
   `plansDirectory` is configured — read it via Claude Code's settings precedence (project-local
   `.claude/settings.local.json` → project `.claude/settings.json` → global
   `~/.claude/settings.json`); (2) `docs/guides/` if that directory exists; (3) `docs/` at the
   repo root as a last fallback. Create the `guides/` subfolder if it does not exist. Honor an
   explicit user-specified path above all other resolution rules.

10. **Confirm.** Return the saved file as a clickable Markdown link plus a one-paragraph summary of
    what the doc covers and which exemplar archetype it follows.

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
- Every one of the 12 skeleton sections is either present and substantive, or deliberately omitted — no empty stubs.
- Every external URL was `WebFetch`-verified this session.
- Every cited path / symbol / frontmatter field was `Read` or `Grep`-confirmed this session.
- Primary sources are quoted verbatim, not paraphrased.
- Per-user paths and memory wikilinks carry the "per-user, not in this repo" disclaimer.
- The doc closes with a Quick reference (ASCII) and a Cross-references list.
