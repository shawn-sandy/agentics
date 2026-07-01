# Archetypes — five non-binding starting points

Every archetype below is a **starting point, not a mold**: a suggested section set drawn from the
library in `skeleton.md`, plus a note on what to steal from it. Pick the closest one, then add,
drop, reorder, or blend sections freely to fit the topic. What never flexes is the spine —
provenance callout, Quick reference, Cross-references, the six discipline rules — and the depth
bar (≥1 verbatim-quoted primary source, ≥1 worked example per guide).

The first two archetypes are grounded in real exemplar guides; the other three are first-class
starting shapes for topics the originals never covered.

> **Where the exemplar files live (read this first).** The two exemplar files are in the author's
> separate `513` repo, at `devbox/513/docs/claude-code-persistence-layer.md` and
> `devbox/513/docs/review-bot-loop-discipline.md`. They are **not** bundled with the
> social-media-tools plugin and are **not** in the agentics repo. A teammate who installs this
> plugin will not have them on disk. This synopsis is the portable substitute — it carries the
> structural lessons without depending on files only the author can open. (This is discipline rule
> 6 applied to the skill's own references: match the audience to the location.)

---

## `system-explainer` — broad system explainer

**Exemplar file:** `devbox/513/docs/claude-code-persistence-layer.md` (external; see disclaimer above).

**Subtitle:** "A developer guide to choosing between memory, skills, agents, and hooks — when each
fits, when each fails, and how to combine them."

**Suggested section set.** A stack-at-a-glance overview → one section per mechanism (memory,
skills, agents, hooks), each opening with a bold thesis → a diagnostic-question section (§6) → a
worked case study → anti-patterns (a blend of §7 + §8) → maintenance (§11) → an ASCII
quick-reference card → further reading with verified canonical URLs and a per-user paths table.

**What to steal from it:**

- Lead every component section with a one-sentence bold thesis ("**Skills are for repeatable multi-step procedures with a stable shape.**").
- Compare peers with narrow tables ("when it fits" / "when it doesn't" per mechanism).
- Put the central decision in a diagnostic-question section: `> **Where does the failure happen, and who is in the best position to intervene at that point?**`
- Close with an ASCII quick-reference card and a Further-reading list whose external URLs are all verified.

**Start here when** the topic is a whole subsystem, or a choice among several peer mechanisms —
"memory vs. skills vs. agents vs. hooks," "which cache layer," "how the build pipeline fits
together." Then reshape freely: fold, rename, or drop any section the topic doesn't need.

---

## `rule-deep-dive` — narrow single-rule deep-dive

**Exemplar file:** `devbox/513/docs/review-bot-loop-discipline.md` (external; see disclaimer above).

**Subtitle:** "A guide to the `feedback-review-bot-loops` memory: what it covers, why it was saved,
how it fires, and how to apply it."

**Suggested section set.** Most of the library, close to as written — this is the densest shape.
§1 states the rule in one bold sentence and adds "Everything in this guide unpacks the practical
edges of that sentence." §2 quotes the saved memory's YAML frontmatter and index-hook line
verbatim. §3 tells the incident with numbers (12 rounds, ~120K output tokens, ~10× the
deliverable). §4 draws the loop as an ASCII diagram. §6 opens with the diagnostic question and
enumerates each case in sub-sections. §7 gives a literal operational script paired with a "What
NOT to do" list. §8 numbers the carve-outs. §9 covers wikilink interactions with the per-user
disclaimer. §10 ties it to the repo's CodeRabbit config. §11 covers update/prune/audit. §12 gives
a manual smoke test with a canned prompt.

**What to steal from it:**

- One bold imperative in §1, then "Everything below unpacks that sentence."
- Quote the primary source (frontmatter, verdicts, config lines) verbatim in §2.
- Tell the originating incident with hard numbers in §3.
- Enumerate decision cases as labeled sub-sections under §6 (signals that activate / signals that override / looks-new-but-isn't / genuinely-new).
- Pair the literal "do" script with a "do NOT" list in §7, and number the exemptions in §8.
- Give §12 a copy-pasteable canned prompt and the expected vs. failure response.

**Start here when** the topic is a single rule, memory, convention, or guardrail — "the
filename-rename rule," "why we stopped auto-incremental reviews," "the one-commit-per-change
convention." The deep-dive devices usually all fit; still drop any that don't.

---

## `how-to` — task-oriented tutorial

No exemplar file yet — this archetype exists because tutorials misfit the deep-dive devices: a
reader following steps needs prerequisites and a happy path, not an incident story or numbered
carve-outs.

**Suggested section set.** Goal in one sentence (§1, reworded as "what you'll have when done") →
prerequisites and starting state (§2) → the steps themselves, numbered, each with the command or
edit and its expected result (§7 reshaped as the core of the guide) → how to verify it worked
(§12) → troubleshooting/common failures (a blend of §5 + §8: what breaks and why) → where to go
next (§9).

**What to steal:**

- Number every step and pair each action with its observable result — "run X; you should see Y."
- State prerequisites explicitly up front, including versions and starting state.
- Make verification a first-class section: the reader must be able to tell they succeeded.
- Keep the worked example the spine of the doc — a tutorial that never shows real output fails the depth bar.

**Start here when** the reader's question is "how do I do X?" — setup guides, migration walkthroughs,
"add a new Y to Z" procedures. Drop the incident/motivation machinery unless the *why* genuinely
aids the *how*.

---

## `concept-explainer` — mental-model builder

No exemplar file yet — this archetype exists because concepts have no operational script or
carve-outs to enumerate; the deliverable is a mental model, not a procedure.

**Suggested section set.** The concept in one sentence (§1) → what it is, concretely (§2, with a
real example from this repo) → why it exists / what problem it solves (§3) → how it works
structurally (§4, diagrams and comparison tables earn their keep here) → how it relates to
neighboring concepts (§9, often as a comparison table) → common misconceptions (a reshaped §8:
"what it is NOT") → where you'll encounter it (§5).

**What to steal:**

- Anchor the abstraction immediately in a concrete, verified example — code, config, or output from the actual project.
- Use a "what it is NOT" section to fence the concept off from its lookalikes.
- Compare neighboring concepts in a table rather than prose.

**Start here when** the reader's question is "what *is* X?" — an architecture idea, a domain term,
a pattern the codebase relies on. Skip operational-script sections entirely unless the concept
carries a usage discipline.

---

## `change-recap` — what changed and why

No exemplar file yet — this archetype exists because change recaps are chronological: before/after
is the organizing axis, not rule/mechanism. (For generating the canonical documentation of a
completed plan file, use `plan-interview:documenting-plans` instead — this archetype is for
telling the story of a change to readers.)

**Suggested section set.** The change in one sentence (§1) → what it was before, verbatim (§2:
quote the old code/config/behavior) → why it changed (§3: the motivating incident, PR, or plan,
with numbers and links) → what it is now (§2 again, after-state, quoted) → what this means for
readers (§7 reshaped: "what you do differently now") → what did NOT change (§8) → follow-ups and
open edges (§11).

**What to steal:**

- Quote both the before and the after state verbatim — the diff is the primary source.
- Cite the motivating artifact (PR number, plan file, incident) with hard numbers.
- Give readers an explicit "what you do differently now" — a recap without behavioral consequence is a changelog entry, not a guide.
- Fence the blast radius: say plainly what is unaffected.

**Start here when** the topic is a shipped change, a migration that already happened, or a session
recap — "what the v3 hook rewrite changed," "how the plans gallery got its filters." Keep it
chronological; drop mechanism sections the change doesn't touch.

---

## Picking an archetype

> *What is the reader's question — how does this system fit together, what is this rule, how do I
> do this, what is this thing, or what changed?*

| Topic is...                                             | Archetype           | Tell                                                        |
| ------------------------------------------------------- | ------------------- | ----------------------------------------------------------- |
| A subsystem or a choice among several peer mechanisms    | `system-explainer`  | You need a comparison table of "when each fits"             |
| A single rule, memory, convention, or guardrail          | `rule-deep-dive`    | You can state it in one imperative sentence                 |
| A procedure the reader will follow step by step          | `how-to`            | Success is observable — the reader can tell they finished   |
| An idea, pattern, or term the reader must internalize    | `concept-explainer` | There is nothing to *run*, only something to *understand*   |
| A shipped change, migration, or session outcome          | `change-recap`      | Before/after is the natural organizing axis                 |

**Most-specific-wins.** When several rows fit, start from the most specific one — the narrowest
archetype whose tell clearly matches (a rule inside a system → `rule-deep-dive`; a tutorial about
a concept → `how-to`). This picks your *starting point* only, never a constraint: blend in sections
from any other archetype the topic needs. When none fits cleanly, skip the archetypes and assemble
directly from the section library in `skeleton.md` — the spine and depth bar still apply.
