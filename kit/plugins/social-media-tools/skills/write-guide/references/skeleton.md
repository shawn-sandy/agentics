# Skeleton — the 12-section explainer template

Every guide this skill produces follows the structure below. Copy it as the starting shape, then
fill each section with verified, concrete content. **Omit a section only when it genuinely does not
apply** — never leave an empty stub, and never pad a section with filler to look complete.

The two exemplars map onto this skeleton exactly: a narrow single-rule deep-dive uses all twelve
sections as written; a broad system explainer may rename §1–§6 toward "overview / what it is / why
/ how it works / how it loads / the diagnostic question" and fold §7–§8 into an anti-patterns
section. The section *intent* is fixed; the section *title* flexes to the topic.

## The template (copy verbatim)

````text
# <Title>
<one-sentence subtitle describing scope>

> **Origin.** Where the doc came from — a session, an incident, a system audit. One paragraph.

---

## Table of contents
<numbered list, anchor links to every major section>

---

## 1. The rule / thesis / overview in one sentence
**Bold the imperative or claim.** Then: "Everything below unpacks that sentence."

## 2. What it is / What was saved
Concrete: file paths, frontmatter, verbatim quotes, exact code. Use ```yaml and ```text fences.

## 3. Why it exists / The incident / The motivation
Concrete numbers when known (round counts, token costs, line counts). Tell the *story* of why this is needed.

## 4. How it works structurally
ASCII diagrams for flows. Tables for comparisons. Pseudo-code for procedures.

## 5. How it fires / When it applies / The recall mechanism
What activates it, what can prevent it from activating.

## 6. Decision criteria
Open with the diagnostic question as an italic blockquote:
> *Is this X or Y?*
Followed by sub-sections enumerating each case.

## 7. Operational script — what to actually do
Literal phrasings when wording matters. Pair "do" with "do NOT".

## 8. Boundaries — what it does NOT cover
Explicit carve-outs. Numbered exemptions.

## 9. Interactions with related systems
Cross-references, wikilinks, paired rules.

## 10. Project-specific context (optional, omit if generic)
Repo-level configs or conventions that modify how this applies *here*.

## 11. Maintenance and audit
When to update, when to prune, how to verify the doc is still accurate.

## 12. Verification protocol
Concrete steps to check the doc's claims are still true. Smoke tests. Canned prompts.

---

## Quick reference
```text
<ASCII checklist or decision tree, ~20–30 lines>
```

---

## Cross-references
- External canonical docs (verified URLs)
- Sibling internal docs
- Relevant config files
````

## Section-by-section intent

| #  | Section                         | What it must deliver                                                            |
| -- | ------------------------------- | ------------------------------------------------------------------------------- |
| —  | Title + subtitle + Origin       | One-line scope, then a one-paragraph `> **Origin.**`/`> **Status.**` provenance callout |
| —  | Table of contents               | Numbered, anchor-linked to every major section                                  |
| 1  | Rule / thesis in one sentence   | A single **bold** imperative or claim, then "Everything below unpacks that sentence." |
| 2  | What it is / What was saved     | Verbatim paths, frontmatter, configs, code — quoted, not paraphrased            |
| 3  | Why it exists / The incident    | The story, with concrete numbers (rounds, tokens, lines) when known             |
| 4  | How it works structurally       | ASCII flow diagrams, comparison tables, pseudo-code                             |
| 5  | How it fires / When it applies  | What activates it and what can prevent activation                               |
| 6  | Decision criteria               | An italic-blockquote diagnostic question, then a sub-section per case           |
| 7  | Operational script              | Literal phrasings; every "do" paired with a "do NOT"                            |
| 8  | Boundaries                      | Numbered, explicit carve-outs of what the topic does not cover                  |
| 9  | Interactions                    | Cross-references, paired rules, wikilinks (with per-user disclaimer)            |
| 10 | Project-specific context        | Repo-level configs/conventions that change how this applies here — omit if generic |
| 11 | Maintenance and audit           | When to update, when to prune, how to confirm the doc is still accurate         |
| 12 | Verification protocol           | Concrete checks: smoke tests, canned prompts, "is this still true" steps        |
| —  | Quick reference                 | ~20–30 line ASCII checklist or decision tree                                    |
| —  | Cross-references                | Verified external docs, sibling internal docs, relevant config files            |
