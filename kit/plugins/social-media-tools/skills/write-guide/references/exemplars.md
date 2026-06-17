# Exemplars — the two style models

This skill is modeled on two real guides. They define the two archetypes every topic falls into:
a **broad system explainer** and a **narrow single-rule deep-dive**.

> **Where they live (read this first).** Both exemplar files are in the author's separate `513`
> repo, at `devbox/513/docs/claude-code-persistence-layer.md` and
> `devbox/513/docs/review-bot-loop-discipline.md`. They are **not** bundled with the
> social-media-tools plugin and are **not** in the agentics repo. A teammate who installs this
> plugin will not have them on disk. This synopsis is the portable substitute — it carries the
> structural lessons without depending on files only the author can open. (This is discipline rule
> 6 applied to the skill's own references: match the audience to the location.)

---

## Exemplar A — broad system explainer

**File:** `devbox/513/docs/claude-code-persistence-layer.md` (external; see disclaimer above).

**Subtitle:** "A developer guide to choosing between memory, skills, agents, and hooks — when each
fits, when each fails, and how to combine them."

**Shape.** Eleven sections that compare several peer mechanisms across one decision space:
a stack-at-a-glance overview → one section per mechanism (memory, skills, agents, hooks), each
opening with a bold thesis → a diagnostic-question section → a worked case study → anti-patterns →
maintenance → an ASCII quick-reference card → further reading with verified canonical URLs and a
per-user paths table.

**What to steal from it:**

- Lead every component section with a one-sentence bold thesis ("**Skills are for repeatable multi-step procedures with a stable shape.**").
- Compare peers with narrow tables ("when it fits" / "when it doesn't" per mechanism).
- Put the central decision in a diagnostic-question section: `> **Where does the failure happen, and who is in the best position to intervene at that point?**`
- Close with an ASCII quick-reference card and a Further-reading list whose external URLs are all verified.

**Model this archetype when** the topic is a whole subsystem, or a choice among several peer
mechanisms — "memory vs. skills vs. agents vs. hooks," "which cache layer," "how the build pipeline
fits together."

---

## Exemplar B — narrow single-rule deep-dive

**File:** `devbox/513/docs/review-bot-loop-discipline.md` (external; see disclaimer above).

**Subtitle:** "A guide to the `feedback-review-bot-loops` memory: what it covers, why it was saved,
how it fires, and how to apply it."

**Shape.** Uses all twelve skeleton sections exactly as named. §1 states the rule in one bold
sentence and adds "Everything in this guide unpacks the practical edges of that sentence." §2 quotes
the saved memory's YAML frontmatter and index-hook line verbatim. §3 tells the incident with
numbers (12 rounds, ~120K output tokens, ~10× the deliverable). §4 draws the loop as an ASCII
diagram. §6 opens with the diagnostic question and enumerates each case in sub-sections. §7 gives a
literal operational script paired with a "What NOT to do" list. §8 numbers the carve-outs. §9 covers
wikilink interactions with the per-user disclaimer. §10 ties it to the repo's CodeRabbit config. §11
covers update/prune/audit. §12 gives a manual smoke test with a canned prompt.

**What to steal from it:**

- One bold imperative in §1, then "Everything below unpacks that sentence."
- Quote the primary source (frontmatter, verdicts, config lines) verbatim in §2.
- Tell the originating incident with hard numbers in §3.
- Enumerate decision cases as labeled sub-sections under §6 (signals that activate / signals that override / looks-new-but-isn't / genuinely-new).
- Pair the literal "do" script with a "do NOT" list in §7, and number the exemptions in §8.
- Give §12 a copy-pasteable canned prompt and the expected vs. failure response.

**Model this archetype when** the topic is a single rule, memory, convention, or guardrail — "the
filename-rename rule," "why we stopped auto-incremental reviews," "the one-commit-per-change
convention."

---

## Picking an archetype

> *Is the topic one rule, or a whole system?*

| Topic is...                                              | Model        | Tell                                                    |
| ------------------------------------------------------- | ------------ | ------------------------------------------------------ |
| A single rule, memory, convention, or guardrail         | Exemplar B   | You can state it in one imperative sentence            |
| A subsystem or a choice among several peer mechanisms   | Exemplar A   | You need a comparison table of "when each fits"        |

When unsure, default to the 12-section skeleton in `skeleton.md` — it fits both archetypes; the
broad explainer simply renames and merges a few sections, while the single-rule deep-dive uses all
twelve as written.
