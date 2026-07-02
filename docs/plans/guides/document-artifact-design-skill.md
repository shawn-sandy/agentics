# The artifact-design skill
A deep-dive into Claude Code's built-in design-guidance skill: what it is, where it actually lives, when it fires, and how it shapes every Artifact page Claude publishes.

> **Origin.** Written 2026-07-02 in response to a request for a guide "on the artifact-design skill or plugin." First finding: it is a **skill, not a plugin** — it is not in this marketplace, not under `kit/plugins/`, and not on disk under `~/.claude/` at all. Its `SKILL.md` text was inspected this session inside the compiled Claude Code binary (version 2.1.198). Because that text is Anthropic's, this guide **paraphrases** the skill's content and limits quotation to brief identifying fragments — it does not reproduce the skill body.

---

## Table of contents

1. [The thesis in one sentence](#1-the-thesis-in-one-sentence)
2. [What it is](#2-what-it-is)
3. [Why it exists](#3-why-it-exists)
4. [How it works structurally](#4-how-it-works-structurally)
5. [How it fires](#5-how-it-fires)
6. [Decision criteria: utilitarian vs. editorial](#6-decision-criteria-utilitarian-vs-editorial)
7. [Operational script](#7-operational-script)
8. [Boundaries — what it does NOT cover](#8-boundaries--what-it-does-not-cover)
9. [Interactions with related systems](#9-interactions-with-related-systems)
10. [Project-specific context (agentics repo)](#10-project-specific-context-agentics-repo)
11. [Maintenance and audit](#11-maintenance-and-audit)
12. [Verification protocol](#12-verification-protocol)

---

## 1. The thesis in one sentence

**artifact-design is a built-in Claude Code skill — shipped inside the CLI binary itself — that the Artifact tool requires Claude to load before writing any artifact page, so every page gets a deliberate, subject-specific design treatment instead of a recognizable AI-template default.** Everything below unpacks that sentence.

## 2. What it is

The skill's frontmatter declares the name `artifact-design` and the one-line description "Design guidance and fundamentals for Artifacts." — the same description shown in a session's available-skills list.

The body is roughly 8,000 characters of design instruction organized into four parts:

- **"Read the request first"** — calibrate the *treatment* (utilitarian vs. editorial), never whether to design at all.
- **"Fundamentals for every artifact"** — eleven bolded rules that apply to every page (typography, neutrals, layout, copy, CSS cascade hygiene, and the anti-AI-cliché rule).
- **"Process"** — sketch a compact token plan (color, type, layout) before writing code.
- **"When the request is editorial"** — a stance shift with five principles for pages that warrant a distinctive visual identity.

Where it lives is the unusual part. It is not a file you can open. It is embedded as a template literal in the compiled Claude Code executable — on this machine at `~/.local/share/claude/versions/2.1.198` *(per-machine path; the version segment changes with every release — not in this repo)*. In the same constants block, the binary names its sibling built-in skills:

```text
artifact-design, dataviz, code-review, code-walkthrough,
pr-explainer, verify, simplify, commit, pr, commit-push-pr
```

## 3. Why it exists

The skill's own text names the problem directly: AI-generated pages converge on a small set of recognizable looks, and the skill enumerates them so that unprompted design freedom is not spent on one of them. Paraphrasing its cliché inventory: a warm-cream ground with a serif display face and terracotta accent; near-black with a single acid-green or vermilion pop; broadsheet-style hairline rules over dense columns; a purple-to-blue gradient hero on white; Inter or Space Grotesk as the reflexive "safe" typeface; emoji as section markers; center-aligned everything; uniform large corner rounding; and the accent-bar-on-rounded-card pattern.

The rule attached to that list is precedence-aware: when the user asks for a specific visual direction — including one of these looks — "their words always win"; the prohibition only applies to unspent freedom.

The second motivation is environmental: Artifact pages run under a strict Content Security Policy that (per the Artifact tool's definition) "blocks requests to any external host" — CDN scripts, external stylesheets, webfonts, remote images. Several of the skill's rules exist specifically because naive HTML habits (linking a Google Fonts URL, loading a chart library from a CDN) silently fail in that sandbox.

## 4. How it works structurally

The skill is a calibration gate followed by layered guidance:

```text
Request arrives (Artifact tool about to be used)
  └─ Load artifact-design (mandatory per the tool definition)
       └─ "Read the request first" — pick a treatment
            ├─ Utilitarian (plan, memo, demo)
            │    └─ Fundamentals only: polished hierarchy,
            │       considered spacing, proper palette,
            │       no gigantic hero, limited flourishes
            └─ Editorial (landing page, game, keepsake app)
                 └─ Fundamentals
                    + design plan reviewed for genericness
                    + one deliberate aesthetic risk
```

The eleven fundamentals, paraphrased to their imperatives:

| Rule | Core instruction (paraphrase) |
|---|---|
| Honor what's already there | An existing design system wins; precedence runs user's words, then the project's system, then the skill's own choices |
| Ground it in the subject | One concrete subject and real content throughout — no lorem ipsum |
| Pair typefaces | Inline fonts as `@font-face` data URIs (the CSP blocks font CDNs); ~65-char measure; balanced heading wrapping |
| Choose neutrals | Pick the grey deliberately (hue-biased toward the accent) rather than defaulting to a pure mid-grey |
| Let layout do the spacing | Flex/grid with `gap`, not per-element margins; `overflow-x: auto` on wide content; tabular numerals for digit columns |
| Avoid AI-generated design | The cliché inventory in §3 |
| Build cleanly | Close every element, quote attributes, visible focus states, respect `prefers-reduced-motion`; Canvas/WebGL over hand-authored SVG paths |
| CSS rules | Watch selector specificity so generated classes don't cancel each other's spacing |
| Writing the copy | Copy is design material — name things by what users recognize, active voice, specific over clever |
| Structure is information | Numbered markers only when the content truly is a sequence |
| When it's a UI, not a document | Summary before detail; state encoded in form (pills, chips, stripes); semantic color is separate from the accent |

The body also contains a literal `<!-- dataviz-callout -->` placeholder comment between the fundamentals and the Process section — presumably substituted at load time to point at the sibling `dataviz` built-in when charts are in play (the substitution mechanism itself is unverified).

## 5. How it fires

Two activation paths:

1. **Mandated by the Artifact tool.** The tool's definition (Claude Code 2.1.198, captured this session) instructs that before writing the page, Claude "MUST load the `artifact-design` skill" to calibrate how much design investment the request warrants. Any session where Claude publishes an Artifact is supposed to load this skill first.
2. **Directly invocable.** It appears in the session's available-skills list, so Claude (or a skill that composes it) can load it via the Skill tool by name, even outside an Artifact flow — for example when writing a standalone HTML page where the same fundamentals apply.

What prevents it from firing: nothing suppresses it selectively, but it is scoped to page-building. Ordinary code edits, terminal output, and Markdown deliverables never trigger it. It also does not fire retroactively — a page written without it doesn't get re-audited.

## 6. Decision criteria: utilitarian vs. editorial

> *Is this page a working document the user will read once, or a thing they'll keep, share, or operate?*

The skill's opening section is the decision:

- **Utilitarian** — plans, memos, demos. Full craft, restrained treatment: real typographic hierarchy, considered spacing, and a proper palette, but no oversized hero and only limited flourishes.
- **Editorial** — landing pages, games, apps or tools the user will keep or share. The stance shifts to that of a client paying for a distinctive point of view, who has already rejected templated proposals.
- **Unsure** — the skill's explicit tiebreaker (quoted, its signature line): *"a well-composed page is never the wrong answer; an over-designed visual identity sometimes is."*

The framing throughout is that the calibration governs *treatment*, never *whether* to design — a doc deserves the same craft as a landing page, delivered more quietly.

## 7. Operational script

What to actually do when building an artifact under this skill:

- **Do** sketch the design plan first — a compact token system with 4–6 named hex values, typefaces for 2+ roles, and a one-or-two-sentence layout concept. **Do NOT** start writing HTML and let the palette emerge ad hoc.
- **Do** inline fonts as `@font-face` data URIs. **Do NOT** link a webfont URL — the CSP silently drops it and you ship the fallback face without knowing.
- **Do** lay out sibling groups with flex/grid and `gap`. **Do NOT** stack per-element margins that silently collapse or double.
- **Do** apply an existing design system when the project has one (CLAUDE.md, tokens file, component styles). **Do NOT** let the skill's guidance override the user's words or the project's system — precedence is fixed: user, project, then you.
- **Do** put wide tables/code/diagrams in their own `overflow-x: auto` container. **Do NOT** let the page body scroll horizontally.
- **Do**, for editorial work, review the design plan and revise any part that reads like the generic default you would produce for any similar page. **Do NOT** take that editorial license on a memo — restraint is the assignment there.
- **Do** spend boldness in one place and keep everything around it quiet. **Do NOT** scatter effects — the skill warns that extra animation is itself one of the tells of AI-generated design.

## 8. Boundaries — what it does NOT cover

1. **It is not a plugin.** It is not in `.claude-plugin/marketplace.json`, not under `kit/plugins/`, and cannot be installed, versioned, or forked the way this repo's plugins can. It ships and updates only with the Claude Code binary.
2. **It does not govern non-Artifact HTML by itself.** This repo's generated pages (plan documents, galleries, social cards) are produced by plugin skills with their own templates; artifact-design only fires when the Artifact tool is used, unless deliberately loaded.
3. **It is not a data-visualization spec.** Charts get one paragraph plus the `dataviz-callout` placeholder; the sibling built-in `dataviz` skill owns that territory.
4. **It does not audit or fix existing pages.** It is guidance applied at write time, not a linter.
5. **It does not decide *whether* to build an artifact.** The Artifact tool description owns that ("Use this when communicating visually would be clearer than terminal text"); the skill only calibrates how much design investment the page gets.

## 9. Interactions with related systems

- **The Artifact tool** — the mandating caller (§5). The tool also imposes the mechanical constraints the skill designs within: self-contained single file, strict CSP, responsive requirement ("the page body must never scroll horizontally" appears in both the tool definition and the skill's layout rule).
- **`dataviz`** — sibling built-in skill, referenced via the `<!-- dataviz-callout -->` placeholder.
- **Installable design plugins** — in this workspace, `frontend-design` and `impeccable` cover overlapping ground (distinctive UI, anti-generic aesthetics) but are marketplace plugins the user chose to install. artifact-design is the always-present floor; those are opt-in extensions. When both are loaded, the skill's own precedence rule resolves conflicts: the user's words, then the project's system, then defaults.
- **Public docs** — Claude Code's skills documentation at <https://code.claude.com/docs/en/skills> (verified HTTP 200 this session) describes the skill system and bundled skills generally, but does not mention `artifact-design` by name as of 2026-07-02. The binary is currently the only primary source for its content.

## 10. Project-specific context (agentics repo)

This repo generates a lot of HTML — plan documents from `plan-agent`, galleries, social cards from `social-media-tools`, prototypes under `docs/prototypes/`. None of that flows through the Artifact tool, so none of it is governed by artifact-design by default. The relevant local rule is the first fundamental: this repo's generators carry their own templates and token systems, and those count as "the project's existing system" — a session that *does* publish an Artifact about this repo should inherit their look rather than invent one.

## 11. Maintenance and audit

- The skill's content is version-locked to the Claude Code release. Every claim in this guide was verified against **2.1.198**; a later binary may revise the text (the skill's own wording frames the cliché list in §3 as a *current* snapshot, making it the most likely section to churn).
- There is no changelog for built-in skills. The only audit method is re-inspection and diff (see §12).
- Prune this guide if a future Claude Code release surfaces built-in skills as readable files or documents artifact-design publicly — at that point the primary source changes and the binary-inspection sections above become historical.

## 12. Verification protocol

Concrete checks that this guide's claims still hold:

1. **Confirm the version.** `claude --version` — if it no longer reports 2.1.198, treat this guide's claims as needing re-verification.
2. **Confirm the skill is still embedded.** *(Per-machine path — adjust the version segment.)*

   ```bash
   python3 -c "
   data = open('$HOME/.local/share/claude/versions/2.1.198','rb').read()
   i = data.find(b'---\nname: artifact-design')
   print('embedded at byte', i) if i > 0 else print('NOT FOUND')"
   ```

   Expected: an offset, not `NOT FOUND`.
3. **Confirm it still loads in a session.** Canned prompt: *"Load the artifact-design skill and describe its first sentence."* Expected response describes the design-lead-at-a-small-studio framing. Failure mode: the skill is missing from the available-skills list or the opening has changed — re-inspect and update this guide.
4. **Confirm the Artifact-tool mandate.** In any session with the Artifact tool available, the tool description should still contain "you MUST load the `artifact-design` skill." If that sentence is gone, §5's activation story is stale.

---

## Quick reference

```text
artifact-design — built-in skill, ships inside the Claude Code binary
│
├─ IS IT A PLUGIN?            No. Not installable, not in any marketplace.
├─ WHERE IS THE SOURCE?       Embedded in the CLI executable (no file on disk).
├─ WHEN DOES IT FIRE?         Mandatory before any Artifact tool call;
│                             also loadable by name via the Skill tool.
│
├─ FIRST DECISION             utilitarian (plan/memo/demo)  → restrained polish
│                             editorial (landing/game/app)  → distinctive identity
│                             unsure                        → well-composed page
│
├─ ALWAYS                     design plan first (4–6 hex, 2+ typefaces, layout)
│                             fonts as @font-face data URIs (CSP blocks CDNs)
│                             flex/grid + gap, not margins
│                             overflow-x: auto on wide content
│                             existing design system > skill defaults
│
├─ NEVER                      the AI-cliché looks (cream+terracotta, acid-green
│                             on black, purple-blue gradient hero, emoji
│                             headers, rounded-lg everywhere) — unless asked
│
└─ PRECEDENCE                 user's words → project's system → your choices
```

---

## Cross-references

- <https://code.claude.com/docs/en/skills> — Claude Code skills documentation (verified 2026-07-02; does not yet document artifact-design itself).
- [CLAUDE.md](../../../CLAUDE.md) — this repo's project instructions; counts as "the project's existing system" under the skill's precedence rule.
- Sibling guides in this folder: [document-implementation-plan-skill.md](document-implementation-plan-skill.md), [document-plan-review-team.md](document-plan-review-team.md).
- `~/.local/share/claude/versions/<version>` — the binary containing the embedded skill text *(per-machine path, not in this repo)*.
