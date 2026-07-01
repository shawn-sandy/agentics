# Section library — the twelve sections guides are assembled from

Every guide this skill produces is assembled from the section library below: pick the sections the
topic needs, add, drop, reorder, or blend them freely, then fill each chosen section with verified,
concrete content. **Include a section only when it genuinely applies** — never leave an empty
stub, and never pad a section in to look complete.

The archetypes in `exemplars.md` are suggested starting subsets of this library, not molds. A
narrow rule deep-dive tends to use most sections close to how they are written here; broader or
differently-shaped topics (systems, tutorials, concepts, change recaps) rename, merge, drop, and
reorder sections to fit — e.g. renaming toward "overview / what it is / why / how it works" or
folding the operational script and boundaries into an anti-patterns section. The section *intent*
is stable; the section *title*, order, and presence flex to the topic.

## The library (a menu, not a required sequence)

The numbers below are catalog ids for referring to sections, not a mandatory order or count. The
opening frame (title, subtitle, provenance callout, table of contents) and the closing frame
(Quick reference, Cross-references) appear in every guide; the numbered body sections are the menu.

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
