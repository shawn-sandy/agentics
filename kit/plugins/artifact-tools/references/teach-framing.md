# The teaching frame

Loaded by the `teach-artifact` skill on top of `recap-core.md`. That file owns
source resolution, the blocking scrub gate, the page build, publishing, and the
republish record. This one owns the only thing separating a teaching page from
the three recaps reading the same two sources: what the page is *for*.

A recap answers **what changed**. This page answers **how this works**. The raw
material may be a week of commits, but the subject is the system, and a reader
who never saw the change should still finish the page understanding the thing.

## Section spine

One fixed list, both sources. Session mode and PR mode produce these headings in
this order — the raw material differs, the shape does not. Nothing here is
chosen per source, because a spine that moves per source cannot be compared
against `commands/team-recap.md`, and that comparison is what keeps this page
from quietly becoming a fourth recap.

1. **Mental model** — the paragraph that makes the rest readable: what this
   system is, what it is responsible for, and the one idea a reader has to hold
   to follow anything below. Earns a diagram by default.
2. **How it works today** — the moving parts and what each owns. Present tense,
   describing the system as it stands, never as it moved.
3. **One path end to end** — a single real path walked as an ordered list, each
   step naming the actual file, function, or command it passes through.
4. **Why it is built this way** — the obvious alternative, and why it lost. Not
   this week's decision log: the standing reasons the shape is the shape.
5. **Where to look next** — the two or three files to open first, and the
   question each one answers.

Every section is always kept — the exception `recap-core.md` allows a caller to
declare. A source that cannot fill one is a signal the subject is too thin to
teach: say so under the heading rather than dropping it, because a missing
section reads as a system with no such part.

**PR mode inherits no recap sections.** `recap-core.md` sorts unresolved review
threads into "the calling command's open-items section" and keeps a **Learnings**
heading in PR mode. This page declares neither, deliberately — open items and
dead ends are what a recap is for, and adding either heading would break the
fixed spine the reviewer test below depends on. Read both signals anyway and
spend them inside the spine: an unresolved thread arguing about how something
*should* work is evidence for **Why it is built this way**, and a resolved one
usually names the alternative that lost. If a thread carries nothing a reader
needs in order to understand the system, drop it — that is the correct outcome
here, not a gap. Never let it grow a heading of its own.

## Diagrams

Two rules, both departures from `recap-core.md`.

- **Mental model earns a diagram by default.** The core draws one only where
  structure, flow, or state actually changed. Invert that for this section
  alone: a page teaching a system that did not move this week is exactly the
  page most in need of a picture. Every other section keeps the core's stricter
  earned-diagram bar.
- **Every diagram carries a caption *and* a prose sentence.** The caption says
  what to look at; the sentence states the same relationship in words. That is
  not redundancy — the core's documented fallback ships diagram blocks as plain
  text whenever the browser pane is unavailable, so a relationship living only
  inside the image is a relationship that disappears on that path.

## The walkthrough

Section 3 is the one that fails quietly, so it gets its own rules.

- Ordered list, one step per hop. A prose paragraph hides the sequence, which is
  the whole payload.
- Every step names something greppable — a path, a function, a command. A step a
  reader cannot go look at teaches nothing.
- One path, walked whole. Two half-paths are a summary wearing a list's clothes.

## Reviewer test

Read the finished page's headings alone, with the prose covered. If they restate
`commands/team-recap.md`'s section list — at a glance, what changed, how it works
now, before and after, decisions, learnings, open items, files touched, glossary
— the draft has failed, and good prose underneath does not rescue it. Rewrite it
against the spine, or publish a `team-recap` and stop calling it a different page.

`tests/plugins/test-artifact-tools.sh` enforces the same comparison against the
spine in this file. The build guards the frame; this test guards the draft, which
the build cannot see.

## Extension seam

Version 1 accepts exactly two sources, both already owned by `recap-core.md`: the
session and the pull request. A third attaches at exactly one point — the mode
table in that file's **Source** section, which picks the first matching mode and
hands its output to an otherwise unchanged pipeline.

Three candidates, none implemented here:

- **A skill directory** (`kit/plugins/<plugin>/skills/<skill>/`) — raw material is
  the `SKILL.md`, its frontmatter, and every reference it links.
- **A rule file** (`.claude/rules/<name>.md`) — raw material is the rule and the
  paths it is scoped to.
- **A single source file** — raw material is that file plus its direct callers.

Each supplies raw material and nothing else. The spine, the diagram rules, the
walkthrough rules, and the gate all stay exactly as they are: adding a source is
one row in that mode table plus a gather step, never a second framing file.
