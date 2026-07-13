---
name: refine-prompt
model: opus
description: "Builds structured AI prompts using Anthropic techniques. Interviews users, classifies prompt type, and delivers a copy-pasteable prompt. Use when the user asks to refine or build a prompt."
disable-model-invocation: true
argument-hint: "[intent or topic description]"
allowed-tools:
  AskUserQuestion, ToolSearch, Read, Write, Bash(git *), Bash(mkdir *)
---

# refine-prompt

Interview the user about their prompting need, classify the prompt type, apply
the applicable Anthropic best-practice techniques, and deliver a copy-pasteable,
well-structured AI prompt.

---

## Entry — Read $ARGUMENTS

On invocation via `/plan-agent:refine-prompt`, `$ARGUMENTS` contains the user's
initial intent or topic. If `$ARGUMENTS` is non-empty, use it to seed Phase 1
(Classify) and skip the "what do you need?" opener. If empty, ask: "What kind of
prompt do you need help crafting?"

---

## Phase 1 — Classify

Identify the prompt type from $ARGUMENTS or the user's stated need. Classify
into one of four types:

| Type           | When to use                                                                     |
| -------------- | ------------------------------------------------------------------------------- |
| **system**     | A system prompt or persona for an AI assistant, chatbot, or agent               |
| **task**       | A one-shot task instruction (refactor code, summarize document, translate text) |
| **creative**   | Creative writing, storytelling, tone generation, or style mimicry               |
| **analytical** | Research, analysis, comparison, or synthesis of information or documents        |

After classifying, apply the **technique matrix** — the set of Anthropic
best-practice layers that apply to this type:

| Prompt type | Applicable techniques                                                                                 |
| ----------- | ----------------------------------------------------------------------------------------------------- |
| system      | Role assignment, XML structure (`<instructions>`, `<constraints>`), output format, guardrails         |
| task        | Clarity/directness, XML structure (`<context>`, `<example>`), thinking/CoT scaffolding, output format |
| creative    | Role assignment, tone/voice instructions, context/motivation, output format, positive framing         |
| analytical  | Long-context patterns (`<document>`, `<quote>`), thinking/CoT, self-check, output format              |

If the input does not clearly match any single type, ask the user to clarify via
`AskUserQuestion` with the four types as options: "Which best describes what
you're building?" — then proceed with the chosen type.

Announce the classified type and selected technique matrix to the user in one
short sentence:

> "Classified as **task** prompt — I'll apply: clarity, XML context tags, CoT
> scaffolding, and output format."

---

## Phase 2 — Interview

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

Skip any layer whose type is not in the technique matrix for this prompt.

---

## Phase 4 — Draft

Assemble the final prompt by reading the relevant template from this skill's
references/ directory, substituting the structured Phase 3 output into the
template placeholders.

Template selection by type:

- system →
  `${CLAUDE_PLUGIN_ROOT}/skills/refine-prompt/references/system-prompt-template.md`
- task →
  `${CLAUDE_PLUGIN_ROOT}/skills/refine-prompt/references/task-prompt-template.md`
- creative →
  `${CLAUDE_PLUGIN_ROOT}/skills/refine-prompt/references/creative-prompt-template.md`
- analytical →
  `${CLAUDE_PLUGIN_ROOT}/skills/refine-prompt/references/analytical-prompt-template.md`

Read the template with the Read tool, resolving the path as
`${CLAUDE_PLUGIN_ROOT}/skills/refine-prompt/references/<type>-prompt-template.md`.
If `${CLAUDE_PLUGIN_ROOT}` is unavailable, fall back to a Glob search:
`Glob("**/plan-agent/skills/refine-prompt/references/<type>-prompt-template.md")`.

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

**Resolve the output directory** (first match wins):

1. Read `promptsDirectory` from `.claude/settings.json` (check project-level
   `.claude/settings.json` first, then `~/.claude/settings.json`). If the key is
   present and non-empty, strip any trailing slash and use that path as the
   output directory.
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

**Uniqueness guard:** before writing, check whether
`{resolved-directory}/{filename}` already exists. If it does, append `-2` to the
base name (before `.md`), then `-3`, etc., until the path is unique.

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

**Confirm to the user** in one line after saving:

> "Saved to `{resolved-directory}/{filename}`."
