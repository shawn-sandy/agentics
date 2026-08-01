---
name: write-prompt
model: opus
description: "Builds structured AI prompts using Anthropic techniques. Interviews users, classifies prompt type, and delivers a copy-pasteable prompt. Use when the user asks to write, refine, or build a prompt."
disable-model-invocation: true
argument-hint: "[system|task|creative|analytical] <intent or topic description>"
allowed-tools:
  AskUserQuestion, ToolSearch, Read, Write, Bash(git *), Bash(mkdir *), Bash(awk *), Bash(shasum *)
---

# write-prompt

Interview the user about their prompting need, classify the prompt type, apply
the applicable Anthropic best-practice techniques, and deliver a copy-pasteable,
well-structured AI prompt.

---

## Entry — Read $ARGUMENTS

On invocation via `/plan-agent:write-prompt`, `$ARGUMENTS` contains the user's
initial intent or topic, optionally led by a type token (see Phase 1). If
`$ARGUMENTS` is non-empty, use it to seed Phase 1 (Classify) and skip the "what
do you need?" opener. If empty, ask: "What kind of prompt do you need help
crafting?"

---

## Phase 1 — Classify

**A leading type token wins.** If the first whitespace-delimited token of
`$ARGUMENTS` exactly matches one of the five type names below, that **is** the
type — do not re-infer it, and do not second-guess it against the rest of the
text. The remainder of `$ARGUMENTS` is the intent. This is how
`plan-agent:build-proposal` reaches the `proposal` type
(`args: "proposal --out … --answers-gathered …"`); the same convention is open
to the human for the four author-facing types.

Otherwise, identify the prompt type from `$ARGUMENTS` or the user's stated
need. Classify into one of five types:

| Type           | When to use                                                                     |
| -------------- | ------------------------------------------------------------------------------- |
| **system**     | A system prompt or persona for an AI assistant, chatbot, or agent               |
| **task**       | A one-shot task instruction (refactor code, summarize document, translate text) |
| **creative**   | Creative writing, storytelling, tone generation, or style mimicry               |
| **analytical** | Research, analysis, comparison, or synthesis of information or documents        |
| **proposal**   | A decision-complete proposal converging on a build instruction — normally invoked by `plan-agent:build-proposal`, not chosen by hand |

After classifying, apply the **technique matrix** — the set of Anthropic
best-practice layers that apply to this type:

| Prompt type | Applicable techniques                                                                                 |
| ----------- | ----------------------------------------------------------------------------------------------------- |
| system      | Role assignment, XML structure (`<instructions>`, `<constraints>`), output format, guardrails         |
| task        | Clarity/directness, XML structure (`<context>`, `<example>`), thinking/CoT scaffolding, output format |
| creative    | Role assignment, tone/voice instructions, context/motivation, output format, positive framing         |
| analytical  | Long-context patterns (`<document>`, `<quote>`), thinking/CoT, self-check, output format              |
| proposal    | Long-context grounding (`<context>`, `<finding>`, `<decisions>`), comparison tables, positive framing, output format |

### Confirm the type before Phase 2

The type is not cosmetic: it selects the technique matrix **and** the entire
question set Phase 2 asks. A wrong type means the wrong interview, and the
wrong interview is discovered only after the human has answered it. So settle
the type here, with exactly **one** `AskUserQuestion` — which of the two shapes
below fires depends on how confident the classification is.

**Skip both** — announce and go straight to Phase 2 — when either holds:

- **The type arrived as a leading token.** Confirming a choice the caller
  stated outright is friction, not a check.
- **`$ARGUMENTS` carries `--answers-gathered`.** That is the unattended caller
  path; a question there stalls a run nobody is watching.

**Unsure — the classification menu.** If the input does not clearly match any
single type, ask the user to clarify via `AskUserQuestion` with the four
author-facing types as options: "Which best describes what you're building?" —
then proceed with the chosen type. **Never offer `proposal` in that menu.** It
is a caller-driven type: reach it only when `$ARGUMENTS` names it explicitly.

**Confident — the confirmation gate.** Present the classified type and the
technique matrix it selects, then ask with two options:

- **Looks right** — proceed to Phase 2.
- **Change the type** — offer the four author-facing types and take the answer.

**Nothing in Phase 2 may start before the type is settled** — not the first
question, not a provisional draft. Neither shape is satisfied by narration:
stating a conclusion on the way to acting on it reads as settled, and the
human's first real chance to object then arrives after a type-specific
interview they have already sat through.

**When `AskUserQuestion` is unavailable** (a non-interactive session), do not
block — Phase 2's interview is unavailable for the same reason, so waiting
would strand the run with nothing to wait for. Proceed, but surface what a
blocked gate would have caught: state the classified type, and list the Phase 2
answers you assumed in its place as a table the human can correct in one reply.
This is the documented degradation, not a workaround — never set
`--answers-gathered` yourself to reach it.

Announce the settled type and selected technique matrix to the user in one
short sentence:

> "Classified as **task** prompt — I'll apply: clarity, XML context tags, CoT
> scaffolding, and output format."

---

## Phase 2 — Interview

**Bypass — `--answers-gathered`.** When `$ARGUMENTS` carries this token, skip
Phase 2 entirely: run **zero** `AskUserQuestion` calls, and treat the content the
caller passed in as the gathered answers, feeding it straight to Phase 3. A
caller that has already interviewed the human — `plan-agent:build-proposal`
resolves every decision with them in its own Step 5 — would otherwise
double-interview on material it already holds. This is a repo-local `$ARGUMENTS`
convention, not a Claude Code feature; no upstream pattern exists for it.

Never set the token from inside this skill, and never infer it from a
content-rich invocation. An invocation without it interviews, however much
context it arrived with.

Gather context from the user using type-specific questions grounded in
Anthropic's "Add context to improve performance" principle. The key is to
extract the user's _why_, not just their _what_.

Use **AskUserQuestion** with a batched set of 2–3 essential questions determined
by the classified type:

**system prompt questions:**

- What is the assistant's persona, name, or role? (feeds Role technique)
- What tone and boundaries should it have — e.g. formal, concise, never discuss
  X? (feeds Constraints)
- _Why_ is this assistant being built — what user need or business problem does
  it solve? (feeds motivation context)

**task prompt questions:**

- What is the input the model will receive, and what should the output look
  like? (feeds Clarity + Output Format)
- Are there edge cases or failure modes the prompt must handle explicitly?
  (feeds CoT scaffolding)
- _Why_ is this task being automated — what would a bad output look like? (feeds
  motivation/context)

**creative prompt questions:**

- What style, voice, or tone should the output have — any reference works?
  (feeds Role + Tone)
- Who is the intended audience and what emotional response should the writing
  evoke? (feeds Context)
- What length and structure should the output have — a single paragraph,
  multiple stanzas, a scene? (feeds Output Format)
- _Why_ this piece — what makes it worth creating right now? (feeds motivation)

**analytical prompt questions:**

- What documents, data sources, or content will be passed to the model? (feeds
  Long-context patterns)
- What is the desired analysis depth — surface summary vs. deep comparison?
  (feeds CoT + Output Format)
- _Why_ does this analysis matter — what decision or action does it support?
  (feeds motivation)

After the first AskUserQuestion batch, ask: "Would you like to go deeper for a
more refined prompt? I can ask 2–3 follow-up questions." Only run a second
AskUserQuestion batch if the user confirms.

---

## Phase 3 — Structure

Apply the XML structural techniques selected by the technique matrix from Phase
1 to the gathered interview responses.

Map interview answers to XML layers:

- **Role assignment** (system + creative types): wrap persona/role answer in
  `<role>...</role>`
- **XML structure — instructions/constraints** (system type only): wrap
  instructions in `<instructions>...</instructions>`, constraints in
  `<constraints>...</constraints>`
- **Context block** (task + creative types): wrap background and audience
  context in `<context>...</context>`
- **Examples** (task type): prepare `<example>...</example>` slot with
  placeholder from interview answer
- **Thinking/CoT** (task + analytical types): add `<thinking>...</thinking>`
  scaffold before the main instruction
- **Document grounding** (analytical type): add
  `<document>{{DOCUMENT_CONTENT}}</document>` wrapper and quote-extraction
  instruction
- **Self-check** (analytical type): add a final "Before responding, verify..."
  clause
- **Proposal grounding** (proposal type): wrap the proposal's sections in their
  matching layers — `<context>`, `<finding>`, `<comparison>`, `<decisions>`,
  `<workstreams>`, `<risks>`, `<open-questions>`, `<roadmap>`, `<appendices>` —
  and carry the proposal's *Next step* through as the core instruction. Pass
  markdown tables and appendices through verbatim rather than summarizing them;
  they are the grounded evidence the prompt exists to carry.

Skip any layer whose type is not in the technique matrix for this prompt.

---

## Phase 4 — Draft

Assemble the final prompt by reading the relevant template from this skill's
references/ directory, substituting the structured Phase 3 output into the
template placeholders.

Template selection by type:

- system →
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/system-prompt-template.md`
- task →
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/task-prompt-template.md`
- creative →
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/creative-prompt-template.md`
- analytical →
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/analytical-prompt-template.md`
- proposal →
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/proposal-prompt-template.md`

Read the template with the Read tool, resolving the path as
`${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/references/<type>-prompt-template.md`.
If `${CLAUDE_PLUGIN_ROOT}` is unavailable, fall back to a Glob search:
`Glob("**/plan-agent/skills/write-prompt/references/<type>-prompt-template.md")`.

Substitute all {{PLACEHOLDER}} values in the template with the structured
content from Phase 3, the interview answers from Phase 2, and the user's intent
from Phase 1. Remove any placeholder lines where the technique was not selected
by the matrix (e.g. remove `<thinking>` block for creative prompts).

Apply these writing rules from Anthropic's best practices:

- Use positive framing ("Do X" not "Don't do Y") per "Be direct about the
  desired output"
- Lead with the most important instruction
- Be specific about output format (length, structure, tone)
- Every instruction should be actionable and unambiguous

---

## Phase 5 — Recommend

Search the session's live tool registry for installed skills, agents, or
commands that match the user's intent — they may supersede the need for a custom
prompt entirely.

Use ToolSearch with 2–3 keyword queries derived from the user's intent and the
classified prompt type:

- Extract the core domain keywords from the interview (e.g. "code refactor",
  "summarize document", "chatbot system prompt")
- Run ToolSearch for each keyword phrase
- Deduplicate results, filter to skills/commands/agents only (not filesystem
  tools)
- Present the top 1–3 matches with: the invocation command, a one-sentence
  description, and a note on when it supersedes a custom prompt

If no relevant tools are found, skip the recommendation block silently.

---

## Phase 6 — Deliver

Present the assembled prompt in a fenced code block the user can copy-paste
directly. Include:

1. **A header line**: the classified type and techniques applied
2. **The prompt itself** in a fenced text block
3. **Recommendations** (from Phase 5) in a brief bulleted list below the block

Format:

````
**Prompt type:** task — techniques applied: Clarity, XML structure, CoT scaffolding, Output format

```text
[assembled prompt here]
```

**Installed tools that may achieve this directly:**
- /code-review — Reviews code for bugs and quality. Use when the refactoring goal is code quality rather than transformation.
````

After delivering, offer: "Want me to refine this further? I can add examples,
tighten the output format, or adjust the tone."

---

## Phase 7 — Save

After delivering the prompt in Phase 6, save it as a markdown file in the
resolved `prompts/` directory.

**Caller-supplied output path — `--out <path>`.** When `$ARGUMENTS` carries this
flag, write to exactly that path and **skip the rest of this phase's path
work entirely**: no directory resolution, no filename derivation, no 3–5 word
intent slug. `mkdir -p` the path's parent, then write. Report back the same path
byte-for-byte — do not normalize, re-slug, or re-date it.

This exists because a caller that derives its own path and a Phase 7 that
derives its own path will disagree. `build-proposal` names its file from a
`verb-target` slug under its own resolved directory; Phase 7 below would pick a
different directory and a different intent slug, and the caller would then hand
off, banner, and report a file that was never written. The caller dictates the
path so the two agree by construction rather than by coincidence.

**Resolve the output directory** (first match wins — `--out` skips this):

1. Read `promptsDirectory` using Claude Code's settings precedence — project-local
   `.claude/settings.local.json`, then project `.claude/settings.json`, then
   global `~/.claude/settings.json`. If the key is present and non-empty, strip
   any trailing slash and use that path as the output directory. All three
   readers of this key — this skill, `plan-agent:build-proposal`, and
   `artifact-tools:prompt-artifact` — must walk the same three files in the same
   order, or a prompt saved here becomes invisible to the gallery that publishes
   it.
2. Otherwise, anchor to the repo root: run `git rev-parse --show-toplevel` and
   join the result with `docs/prompts` (e.g. `$(git rev-parse --show-toplevel)/docs/prompts`).
   If `git rev-parse` fails (not a git repo), fall back to `docs/prompts` relative to `$PWD`.

**Create the directory** if it does not already exist:

```bash
mkdir -p "<resolved-directory>"
```

**Derive the filename:**

Build the filename from three parts joined with hyphens, all lowercase
kebab-case:

1. The classified prompt type from Phase 1 (e.g. `task`, `system`, `creative`,
   `analytical`)
2. A 3–5 word slug derived from the user's core intent (strip stop words;
   replace spaces with hyphens)
3. Today's date in `YYYY-MM-DD` format

Pattern: `{type}-{intent-slug}-{YYYY-MM-DD}.md`

Examples:

- `task-refactor-auth-middleware-2026-06-04.md`
- `system-customer-support-bot-2026-06-04.md`
- `analytical-compare-pricing-models-2026-06-04.md`

**The `proposal` type omits the date:** `proposal-{slug}.md`. A proposal prompt
is a living document that deepens over rounds, and a dated name would resolve to
a different file the moment a loop crosses midnight — writing a second file and
silently abandoning the first. The slug is the identity; `created:` and
`modified:` carry the dates. In practice this type arrives with `--out`, which
supersedes derivation altogether; the rule is stated so a bare invocation of the
type still lands on one file.

**Uniqueness guard (all types except `proposal`):** before writing, check whether
`{resolved-directory}/{filename}` already exists. If it does, append `-2` to the
base name (before `.md`), then `-3`, etc., until the path is unique.

**In-place rewrite (the `proposal` type only)** — replaces the uniqueness guard,
because a `-2` variant would fork the living document the type exists to
maintain. Before overwriting an existing file:

1. Read its frontmatter. No `generated-sha:` key → it was not written by this
   skill; ask via `AskUserQuestion` before touching it.
2. Compute the sha256 of the file's current body — every byte after the
   frontmatter's closing `---` — and compare it against the recorded
   `generated-sha:`.
3. **Equal** → the file is exactly what this skill last wrote. Overwrite in
   place, silently.
4. **Different** → the body was hand-edited since. Ask via `AskUserQuestion`
   whether to overwrite, and show what changed. Never clobber on your own
   judgement: the prompt file is the authoritative deliverable, so a lost hand
   edit is worse than the duplicate file this rule replaces.

```bash
# body hash — everything after the frontmatter's closing '---'
awk 'f{print} /^---$/{n++; if(n==2) f=1}' "$FILE" | shasum -a 256 | cut -d' ' -f1
```

The check is anchored to `generated-sha:` rather than to a git baseline on
purpose. `build-proposal` only *offers* to commit each round, so a previous round
is frequently uncommitted — against git, every rewrite would look hand-edited and
the confirmation would fire every single time, training the user to click through
it.

**Write the file** using the Write tool. The file content must be:

```
---
type: {classified type}
intent: {one-sentence summary of the user's stated goal}
techniques: {comma-separated list of techniques applied}
created: {YYYY-MM-DD}
---

# {Prompt type}: {intent slug, title-cased}

{the raw assembled prompt text from Phase 4 — substituted content, NOT the Phase 6 fenced display block; embed the prompt as plain text}
```

**The `proposal` type inserts a fixed framing line** between the H1 and the
assembled body — the template starts directly at `<tldr>`/`<context>`, and this
line is not a substituted slot, so it is not in the template file:

```
> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.
```

Without this line the reader has no signal that what follows is a proposal
rather than a ready-to-execute instruction — the same distinction
`build-proposal`'s own artifact shape makes with its framing block quote, which
this line is standing in for.

**The `proposal` type carries three more frontmatter keys**, written on every
round:

- `status:` — `gathering` while the loop is still open, `converged` once the
  proposal is decision-complete. The proposal-native vocabulary, not the plan
  lifecycle's `todo`/`in-progress`/`completed`.
- `modified:` — `YYYY-MM-DD` of this round. `created:` keeps the first round's
  date.
- `generated-sha:` — the sha256 of the body just written, computed with the
  command above **after** assembling the content and **before** the next round
  reads it back. Without it the drift check in the rewrite rule has no baseline.

**Confirm to the user** in one line after saving:

> "Saved to `{resolved-directory}/{filename}`."
