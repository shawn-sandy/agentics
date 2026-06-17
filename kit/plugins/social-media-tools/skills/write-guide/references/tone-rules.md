# Tone rules and discipline rules — expanded

Two rule sets govern every guide. **Tone rules** shape how the prose reads. **Discipline rules**
guarantee the prose is true. Tone is style; discipline is correctness. A guide can be well-written
and still be a defect if it ships an unverified claim.

Every example below is drawn from the two canonical exemplars (see `exemplars.md`).

---

## Tone rules

### 1. No emojis anywhere

Neither exemplar contains a single emoji. Headings, callouts, tables, and quick-reference cards are
all plain text. Emojis read as decoration; these docs are reference material.

### 2. Direct, declarative, imperative voice

Lead sections with a claim, not a hedge.

- Good: **"Memory exists to change how Claude behaves in future sessions, on rules and facts not derivable from the code itself."**
- Good: **"When a CI review bot re-fires on every push to a PR, stop iterating after the first substantive fix pass."**

Both open their section with a bolded, declarative thesis. No "this section will discuss," no "it
might be helpful to."

### 3. Italics for diagnostic questions; bold for term definitions

- A decision point is phrased as a question in an italic blockquote: `> *Is this finding a new blocking concern, or the same opinion re-expressed?*`
- A term being defined is bolded at first use: **`feedback` memory**, **the index (`MEMORY.md`)**, **progressive disclosure**.

Keep the two distinct: italics ask, bold defines.

### 4. One idea per bullet; never compound bullets

Split compound thoughts into separate bullets. From the exemplar's "what NOT to save" list, each
item is atomic:

- Code patterns derivable from the repo.
- Git history facts.
- Debugging recipes.

Not: "Code patterns, git history, and debugging recipes (since the commit message has the context)."

### 5. Tables max 4 columns; use rows for long data

Comparison tables stay narrow. The "memory vs. CLAUDE.md" table is 3 columns (dimension, memory,
CLAUDE.md); the four-memory-types table is 3 columns. When a comparison needs more than four
dimensions, split it into two tables or use a definition list — a 6-wide table stops being
scannable. Put long values in rows, not extra columns.

### 6. ASCII diagrams when flow is faster to read than prose

A loop or a file tree is clearer drawn than described:

```text
PR opens
  └─ Bot reviews → verdict + N findings
       └─ Claude addresses findings → push
            └─ Bot reviews fresh commit → new verdict + N' findings
                 └─ ... (repeat) ...
```

Use a diagram for flows, trees, and state transitions. Use prose for reasoning.

### 7. Distinguish "this repo" from "general" — never assume audience scope

State whether a fact is universal or local to one repo. The exemplar separates "this repo already
has a partial structural mitigation" (local) from "the same logic applies across other repos"
(general). A reader must always be able to tell which claims travel and which do not.

### 8. Label per-user paths as "per-user, not in this repo"

Any `~/.claude/...` path, and any `[[memory wikilink]]`, gets an explicit disclaimer. From the
exemplar: "These paths are per-user — they live under your home directory, not in the repo." And:
"A teammate cloning this repo won't have those files." Without the label, a teammate goes looking
for a file that was never committed.

### 9. Concrete over abstract: name files, quote verdicts, cite numbers

- Name the file: `~/.claude/projects/<project-id>/memory/feedback_review_bot_loops.md`.
- Quote the verdict: _"Approve with minor suggestions. LGTM otherwise."_
- Cite the number: "12 rounds," "~120K output tokens," "an order of magnitude greater than the deliverable."

Abstraction is the enemy of a reference doc. Every claim that can be made concrete, should be.

---

## Discipline rules (mandatory)

These are enforced. Breaking one makes the guide a defect, regardless of how well it reads.

### 1. Verify every external URL with WebFetch before pasting

Do not paste a URL from memory. `WebFetch` it; confirm it resolves (HTTP 200); if it redirects,
paste the canonical destination, not the redirector. The exemplars cite
`https://code.claude.com/docs/en/memory` and siblings as canonical references — each was a live,
resolving URL when written.

- Do: `WebFetch` the URL, then paste the final canonical address.
- Do NOT: paste a remembered or guessed URL, or a known redirector.

### 2. Verify every on-disk fact with Read or Grep before citing it

Paths, function names, line numbers, frontmatter fields — confirm each against the working tree.
The exemplar bakes this in as its own §2.9: "If the memory names a file path — check the file
exists. If the memory names a function or flag — `grep` for it."

### 3. Treat memory contents as frozen-in-time

A memory records what was true when it was written; "the codebase moves on." Re-verify any path,
symbol, or flag a memory names before repeating it in a guide. A memory is a lead to verify, not a
citation to trust.

### 4. Quote primary sources verbatim

Frontmatter, error messages, commit titles, verdicts, configs — reproduce them exactly. The
exemplar quotes the saved memory's YAML frontmatter character-for-character and the bot's verdict
phrases word-for-word. Paraphrase loses the exact string a reader needs to match against.

### 5. Mark uncertainty explicitly

If you cannot verify a fact, say so in the doc — "unverified," "could not confirm," "as of <date>."
Never invent a value to fill a gap. A guide that says "approximately, unverified" is honest; a guide
that fabricates a precise number is worse than one that omits it.

### 6. Match the doc's audience to its location

A committed `docs/` file is read by teammates who clone the repo and have no access to your
`~/.claude/`. The exemplar handles this with an explicit callout: "treat each linked name as a
pointer into your own memory store, to create if absent. (Automated reviewers that `find` under
`~/.claude` from a CI runner will report them missing for this reason.)" Link to per-user paths only
with that disclaimer attached.
