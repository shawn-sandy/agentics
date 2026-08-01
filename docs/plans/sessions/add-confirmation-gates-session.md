---
session-id: "b75e42eb-e311-4e43-b280-0b7c90f4031a"
date: 2026-08-01
source: "b75e42eb-e311-4e43-b280-0b7c90f4031a.jsonl"
type: session-export
title: "Confirmation gates and skill splits in plan-agent"
team-artifact-url: https://claude.ai/code/artifact/77ff7322-87cf-4c40-b3dc-a0767169b1ca
---

# Confirmation gates and skill splits in plan-agent

## At a glance

Six changes shipped to the `plan-agent` plugin, across nine files, on
[PR #508](https://github.com/shawn-sandy/agentics/pull/508). Two of them close a
class of bug where the tool quietly decided something on the user's behalf and
then spent real time and money acting on that decision. The other four are
housekeeping: the two largest instruction files were cut down so that routine
work stops paying to load detail it never reads.

The session started from one request — "always offer to publish the proposal" —
and the rest came out of actually running the tool and watching it misbehave.

## What changed

### 1. The proposal tool now confirms your ask before researching it

**Affects:** anyone running `/plan-agent:build-proposal`.

Before, it restated your idea and started researching in the same breath. Now it
stops, shows you the restated objective, and waits.

The bug this fixes was real and observed. Given this request:

> should we add a shared telemetry and usage-analytics layer across all 13
> plugins so we can see which skills and commands actually fire in real sessions

the tool restated it as the same thing **plus** "and let that data drive
keep/merge/cut decisions" — a goal nobody had mentioned. It then researched
against its own invention: 24–36 tool calls, a dispatched search agent, twenty-odd
file searches, all before the human saw a single word.

Two separate rules now prevent this. **Restate, do not enrich** forbids adding a
motive the human never stated ("if a motive seems missing, it is a clarifying
question, not a blank to fill"). **Step 1b** then presents the objective and waits
for *Looks right* or *Refine it*, capped at two refinement rounds.

Measured on the same request against the same 995-file repository: tool calls
before the human is asked anything went from 24–36 to **zero**.

### 2. Publishing a proposal is always offered, and never assumed

**Affects:** anyone running `/plan-agent:build-proposal` to completion.

Every finished proposal now gets one question: publish this as a shareable page,
yes or no? Nothing is published without an explicit yes.

The subtlety is what *cannot* turn the question off. A blanket "no further
questions" covers the proposal's own decisions, not this one — publishing is the
only step in the workflow a person cannot undo by editing a file, so it keeps its
own confirmation.

### 3. You can now name the prompt type directly

**Affects:** anyone running `/plan-agent:write-prompt`.

The first word of your request now sets the prompt type, if it is one of
`system`, `task`, `creative`, or `analytical`:

```bash
claude "/plan-agent:write-prompt creative a short bedtime story about a lighthouse keeper"
```

This convention already existed but was a private arrangement between two tools
and documented for exactly one type. It is now a user-facing feature for all of
them, advertised in the command's own argument hint.

Why it matters: the type is not cosmetic. It picks both the questions you get
asked and the techniques applied to the draft. Guess it wrong and you answer a
batch of wrong questions before the mismatch is visible. When no type is named
and the classifier is confident, a new gate asks *Looks right / Change the type*
before any of that starts.

### 4. Research actually runs in parallel

**Affects:** anyone running a deep (Tier 2) proposal — they wait less.

The instruction said to run the codebase search and the web research together.
In practice the tool ran them one after the other, with 21 sequential file
searches wedged in between.

The old wording prescribed one specific technique. The new wording permits either
route to concurrency and instead forbids the single setting that broke it. Result
on the same request: the code sweep now starts on turn 1 instead of turn 5, and
the first web fetch lands on turn 6 instead of turn 27.

### 5 and 6. The two biggest instruction files were cut down

**Affects:** teammates indirectly — every run of these tools gets cheaper.

`build-proposal` went 380 → 349 lines; `write-prompt` went 434 → 343 lines plus
three new reference files. Detail that only some runs need now loads only on
those runs.

## Before and after

| Behavior | Before | After |
|---|---|---|
| Restating your objective | Restated and researched in one message | Restated, then waits for confirmation |
| Inventing a motive you didn't state | Happened, unchecked | Explicitly forbidden |
| Tool calls before first human checkpoint | 24–36 | 0 |
| Publishing a finished proposal | Sometimes offered | Always offered, never assumed |
| "No further questions" | Suppressed the publish offer too | Covers proposal decisions only |
| Naming a prompt type | Inferred from your prose; explicit only for internal use | First word sets it, for all four public types |
| Confidently wrong type | Announced in passing, then acted on | Confirmed before the interview starts |
| Code sweep vs. web research | Sequential — turn 5, then turn 27 | Concurrent — turn 1 and turn 6 |
| Cost of a simple run | Full instruction file every time | Core only; detail loads on demand |

## Decisions

**A gate on the output of framing, not on vague input.**
The existing rule fired when the *input* looked underspecified. The observed
failure had clear input that got confidently embellished, so the rule never
fired. Gating the restatement instead catches both cases with one question, and
requires no judgment call about whether input was vague enough.

**Rejected:** tightening the existing "ask if underspecified" rule. It would not
have fired on the case that actually broke.

**The two gates behave differently on purpose.**
When the interactive question tool is unavailable, `build-proposal` blocks and
asks in plain text; `write-prompt` proceeds and states its assumptions as a
correctable table. This looks inconsistent and is deliberate: whether blocking is
right depends on what the *next* step costs. Blocking before a research fan-out
saves real money. Blocking before another question just deadlocks, because the
interview needs the same unavailable tool.

**Rejected:** one uniform rule for both. It was the first draft, and running it
proved it wrong — see Learnings.

**Forbid the broken setting rather than prescribe the fix.**
The parallel-research instruction originally named one technique. The re-run
achieved concurrency a different way and still passed. Prescribing only the
original route would have been a rule the tool doesn't follow, describing a fix
that wasn't the fix.

**Publishing keeps its own yes.**
Everything else in the workflow writes files a person can edit or delete.
Publishing sends a page outward. That asymmetry is why one blanket "stop asking
me things" covers the rest but not this.

**The test suite set the boundary for what could move.**
Each test extracts a single step's body and asserts against it — by design, "so a
rule cannot pass by living in the wrong phase." Anything a test pins had to stay
in the core. This is the existing *guards in the core, mechanics behind links*
principle encoded as CI, and it is why the directory-resolver script could move
but the precedence rules it implements could not.

**One layer kept in the core against that rule.** `write-prompt`'s
proposal-grounding layer stays put while its seven siblings moved. It passes
evidence through verbatim rather than shaping tone — behind a link it is a rule
that may never load, and the prompt silently loses the evidence it exists to
carry.

**Rejected:** moving all eight layers for consistency.

## Learnings

**Running the change is what caught the two real bugs; reading the diff would
not have.**

*The first publish-offer wording was broken.* "Ask every run" read as an ordinary
interview question, so a user saying "no further questions" suppressed it. The
instruction was loaded and read — it just lost to a blanket directive. Only
driving the tool end-to-end surfaced that.

*The first version of the type gate was unreachable.* It said: if the question
tool is unavailable, ask in plain text and wait. Two headless runs ignored it and
proceeded — and they were right to. The next step needs the same tool, so
blocking would strand the run waiting for something that can never arrive. The
instruction now documents the behavior the runs actually demonstrated.

An instruction describing behavior the tool won't take is worse than no
instruction: it reads as a guarantee during review and silently isn't one at
runtime.

**Progressive-disclosure work indicted the same session that did it.** The
audit that prompted the file trimming found the two largest files in the plugin
were the two this session had just added ~90 lines to.

**A skill's own tests can be the safest refactoring guide available.** Without
them, more would have moved and the tools would have been quietly weakened.

## Open items

- **Neither gate's interactive branch has been exercised.** Headless runs cannot
  answer an interactive question, so *Refine it* (`build-proposal`) and *Change
  the type* (`write-prompt`), plus the two-round refinement bound, are unverified.
  Both need a human-driven session.
- **The publish "yes" branch is undriven.** Answering yes publishes a real page
  outward with no dry run, so verification stopped at the question. The routing
  and permissions are confirmed; the page build itself is unexercised.
- **A deep (Tier 2) run has never been observed reaching the publish offer** — the
  re-run hit a 10-minute ceiling first. The offer is verified at Tier 1 only.
- **Duplicate work after the code sweep returns.** The re-run still made ~15 file
  searches that partly redid the dispatched agent's work. Separate weakness from
  the concurrency fix.
- **Two runs on one idea can fork the document.** Two Tier 1 runs picked different
  filename slugs for the same idea. Pre-existing, but the slug is the document's
  identity across rounds.
- **Both files remain well above the 57–95 line targets** set by the earlier
  splitting pass. The remainder is test-pinned contract; going lower means
  changing the tests' idea of what a guard is.
- **The source guidance was read through a summarizing fetch,** not the original
  text. Worth reading directly if a specific rule matters.

## Files touched

**Instruction files**

- `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` — the objective gate,
  the no-enrichment rule, the publish offer, the concurrency fix; trimmed
  380 → 349 lines.
- `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` — leading type token,
  type confirmation gate, non-interactive degradation; trimmed 434 → 343 lines.

**New reference files (loaded on demand)**

- `.../build-proposal/references/artifact-resolution.md` — the directory
  resolver, which runs once and only on runs that write something.
- `.../write-prompt/references/interview-questions.md` — the four type-specific
  question sets.
- `.../write-prompt/references/structuring-and-drafting.md` — seven generic
  layers and the drafting rules.
- `.../write-prompt/references/saving-prompts.md` — directory precedence and
  filename derivation.

**Metadata**

- `.claude-plugin/marketplace.json` — version 7.6.0 → 7.10.2.
- `kit/plugins/plan-agent/CHANGELOG.md` — six entries.
- `kit/plugins/plan-agent/README.md` — documents the core-plus-references shape.

## Merge conflict resolved

Main shipped a gallery redesign mid-session and claimed version 7.7.0, which this
branch had also used. The branch's six entries were renumbered to sit above it
(7.7.0–7.9.2 became 7.8.0–7.10.2) and the manifest bumped to match. Two different
changes sharing one version number is a defect, not a cosmetic clash — the
renumber is the fix.

## Glossary

- **Skill** — a Markdown instruction file that Claude Code loads to perform a
  task. The unit being edited throughout this session.
- **SKILL.md** — the file itself. Its entire contents load every time the skill
  runs; there is no partial load.
- **Progressive disclosure** — splitting a skill into a small always-loaded core
  plus reference files that load only when that run needs them.
- **Core / references** — the two halves of that split.
- **Gate** — a point where the tool stops and waits for a human answer before
  continuing.
- **Tier 0 / 1 / 2** — how deep a proposal run goes. Tier 0 answers directly and
  writes nothing; Tier 2 is a full research sweep.
- **Fan-out** — dispatching several research tasks at once.
- **Headless run** — Claude Code invoked non-interactively (`claude -p`). Cannot
  answer interactive questions, which is why the degradation paths matter.
- **`--answers-gathered`** — a flag one skill passes another to say "decisions are
  already made, skip the interview."
- **Merge driver** — a script that auto-resolves a specific file's merge
  conflicts. This repo has one that keeps the higher version number.
