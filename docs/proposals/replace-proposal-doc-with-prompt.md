---
status: proposal
type: refactor
created: 2026-07-27
repo-name: agentics
---

# Proposal: make `build-proposal` converge on a saved prompt instead of a proposal document

> A proposal for review, not an execution plan. It decides *should-we + what*;
> `/plan-agent:implementation-plan` owns *how*.

## TL;DR

`build-proposal` should stop treating `docs/proposals/<slug>.md` as its deliverable and
instead converge on a saved, copy-pasteable prompt under `docs/prompts/`, authored by
delegating to `write-prompt`. The idea is sound — a proposal and a `task` prompt are both
"structured context plus one instruction" — but it is currently **mechanically blocked**:
`write-prompt` carries `disable-model-invocation: true`, which blocks programmatic `Skill`
invocation, and unlike its two disabled siblings it has no `commands/` wrapper to re-open
that door. Unblocking costs one new 15-line file. The real work is a fifth `proposal`
prompt type, an interview-bypass path, and 12 assertions across two test files.

## Context

Two skills in `kit/plugins/plan-agent/skills/` produce documents:

- **`build-proposal`** (245-line `SKILL.md` + 4 references, 599 lines total) runs an
  8-step research loop and writes a living `docs/proposals/<slug>.md` that deepens each
  round. Its canonical output shape is a 13-section document defined in
  `references/artifact-shape.md`.
- **`write-prompt`** (287-line `SKILL.md` + 5 references, 751 lines total) runs a 7-phase
  interview-classify-draft pipeline and writes a write-once
  `docs/prompts/{type}-{slug}-{date}.md` built from one of four XML templates.

The four existing proposals total 638 lines; the four saved prompts total 293. Only 1 of
the 4 proposals actually matches the canonical 13-section shape.

The observation driving this proposal: `build-proposal`'s Step 8 already ends by emitting
a prompt — a hand-built one-line invocation string — and the skill spends an entire
paragraph (`SKILL.md:207-214`), duplicated in two other files, warning that getting that
string's grammar wrong misroutes `implementation-plan` into conversion mode. That is a
prompt-authoring problem being solved by hand, in prose, in triplicate. `write-prompt`
exists to solve exactly that class of problem.

## Core finding

> The refactor is conceptually sound but mechanically blocked, and the proof is a clean
> natural experiment already visible in the skill registry: `disable-model-invocation:
> true` blocks programmatic `Skill` invocation, and the only thing separating the two
> plan-agent skills that *can* be called from the two that *cannot* is the presence of a
> `commands/*.md` wrapper.

`disable-model-invocation: true` prevents both ambient auto-activation and programmatic
invocation via the `Skill` tool
([skills.md L257-258, L626](https://code.claude.com/docs/en/skills.md)). Four plan-agent
skills carry the flag. Two of them — `deep-grill` and `documenting-plans` — have thin
command wrappers whose bodies do nothing but call `Skill(skill: "plan-agent:<name>")` at
line 13 of each file, and both appear in the live session registry. The other two —
`write-prompt` and `finalize-plan` — have no wrapper and do not appear. n=4, no
counterexamples. See *Appendix A*.

The second half of the finding is a shape mismatch that is real but tractable: a proposal
is "structured context plus one instruction," which is precisely what `task-prompt-
template.md` encodes. The templates are not the obstacle; the **capacity** is. The largest
real proposal is 326 lines against 10 `{{PLACEHOLDER}}` slots — roughly a 3x compression —
and a write-once prompt file has no home for the living-document lifecycle.

### Side-by-side

| Dimension | `build-proposal` today | `write-prompt` today |
|---|---|---|
| Artifact path | `docs/proposals/<slug>.md` | `docs/prompts/{type}-{slug}-{date}.md` |
| Output shape | 13 canonical sections (`artifact-shape.md`) | 4 frontmatter keys, H1, raw XML body |
| Frontmatter keys | `status`, `type`, `created`, `repo-name` | `type`, `intent`, `techniques`, `created` |
| Lifecycle | Living doc; deepens per round; `modified:` stamp; committed each round | Write-once; no `status`, no round concept |
| Largest real instance | 326 lines | 103 lines |
| Structure budget | Unbounded sections plus appendices | 10 slots (`task`), 36 distinct tokens across all 4 templates |
| Model pin | `claude-fable-5` | `opus` |
| Invocable via `Skill()` | Yes | **No** |
| Downstream consumer | None (documentation links only) | `artifact-tools:prompt-artifact` |

## Locked & resolved decisions

Resolved in the 2026-07-27 review:

1. **Unblock via a command wrapper.** Add `kit/plugins/plan-agent/commands/write-prompt.md`
   calling `Skill(skill: "plan-agent:write-prompt")`, mirroring `commands/deep-grill.md:13`
   and `commands/documenting-plans.md:13`. `disable-model-invocation: true` **stays** on
   `write-prompt`, preserving the deliberate suppression recorded at
   `kit/plugins/plan-agent/README.md:305` ("prompt" is too common a word in coding
   contexts). Rejected: deleting the flag; inlining write-prompt's logic into
   build-proposal.
2. **The prompt file is the living document.** `build-proposal` rewrites its
   `docs/prompts/` file in place each round, and the prompt frontmatter gains `status:` and
   `modified:`. Operating principle #9 ("the doc, not the chat, is the record") survives
   intact. Rejected: transcript-only round state.
3. **A fifth `proposal` prompt type.** New
   `write-prompt/references/proposal-prompt-template.md` carries Core finding, Locked
   decisions, Workstreams, Risks, and Roadmap as first-class slots rather than compressing
   them into `{{TASK_CONTEXT}}`. Rejected: reusing `task` (lossy — appendices, roadmap
   phasing, and risk tables have no slot).
4. **Dual-write during transition.** For the 6.0.0 release `build-proposal` writes **both**
   `docs/proposals/<slug>.md` and the `docs/prompts/` prompt; the proposal path is marked
   deprecated and removed in 6.1.0. The prompt is the **authoritative** deliverable from
   6.0.0 onward; the proposal doc is a deprecated mirror, not a second source of truth.
   Rejected: clean break; full removal.

Consequence of decision 4, recorded explicitly: dual-write means 6.0.0 does **not** deliver
"a prompt as the sole deliverable." That property arrives in 6.1.0. Every workstream below
is scoped accordingly.

## Workstreams

**WS1 — Unblock invocation.** *(S)*
Add `kit/plugins/plan-agent/commands/write-prompt.md`. Single file, no other changes.
Independently verifiable: after this lands, `write-prompt` appears in the session skill
registry. This is a prerequisite for every other workstream.

**WS2 — Extend `write-prompt` with the `proposal` type.** *(L)*
- New `references/proposal-prompt-template.md` with slots for the 13 canonical sections.
- Phase 1: fifth row in the type table and in the technique matrix.
- Phase 3: XML layer mapping for the new type.
- Phase 4: template-selection entry.
- Phase 7: `status:` and `modified:` frontmatter keys, and the in-place rewrite rule
  (round N+1 overwrites rather than tripping the `-2`/`-3` uniqueness guard).

**WS3 — Interview bypass.** *(M)*
`build-proposal` Step 5 already resolves decisions with the human; `write-prompt` Phase 2
would re-interview. Add a documented pre-gathered-answers path — the docs are silent on any
official pattern, so this is repo-local design. The likely shape: a flag or a structured
`$ARGUMENTS` convention that Phase 2 recognizes and skips on.

**WS4 — Rewire `build-proposal`.** *(M)*
- Step 6 dual-writes: proposal doc (deprecated) plus the prompt via `write-prompt`.
- Step 8 hands off the **prompt** path.
- `references/artifact-shape.md` gains the section-to-slot mapping (*Appendix B*) and its
  hardcoded `docs/proposals/<slug>.md` at line 102 is updated.
- `allowed-tools` already includes `Skill`; no frontmatter change needed.

**WS5 — Downstream: `prompt-artifact`.** *(M)*
`artifact-tools:prompt-artifact` globs `$PROMPTS_DIR/*.md` and hard-codes its library
filter chips to the four literal types. Add the fifth chip and make the frontmatter reader
tolerate `status:` and `modified:`. Without this, WS2 ships a visibly broken gallery.

**WS6 — Chain and tests.** *(L)*
- `build/SKILL.md` Step 1b: the "proposal path" becomes a prompt path; the dirty-tree
  exclusion (L100) and abandonment contract (L216-218) both need the new artifact.
- `tests/plugins/test-build-proposal.sh`: checks 10, 11, 14, 15 encode the old contract.
- `tests/plugins/test-build-skill.sh`: **runs in CI** — asserts the `build-proposal` call,
  the gate, and the "No proposal written" fall-through.
- New coverage for the `proposal` type and the command wrapper.

**WS7 — Docs and version.** *(M)*
`kit/plugins/plan-agent/README.md` (7 build-proposal lines, 6 write-prompt lines, plus the
Plugin Structure tree which omits `write-prompt/` entirely), root `README.md:451,470,473`,
`CLAUDE.md:38,81`, both CHANGELOGs, and `.claude-plugin/marketplace.json` **5.0.0 → 6.0.0**
(BREAKING: removes an artifact contract).

## Risks & tensions

1. **`Skill()` has no documented return value.** The docs are silent on whether a caller
   can read a callee's result; invocation is synchronous and shares the transcript, but
   `build-proposal` would have to recover the saved path by reading `write-prompt`'s
   Phase 7 confirmation line out of the transcript. This is the single most fragile seam in
   the design. `build/SKILL.md` already depends on the same informal contract for the
   proposal path (L179-193, never parsed or validated), so the precedent exists — but this
   adds a second link to that chain.
2. **Three-level skill nesting.** `build` → `build-proposal` → `write-prompt`. The docs are
   silent on any recursion or depth limit. Untested in this repo; today's deepest chain is
   two levels.
3. **Model bleed across the `Skill` boundary.** `build-proposal` pins `claude-fable-5`;
   `write-prompt` pins `opus`. plan-agent has prior history here — the CHANGELOG records a
   model-pinning pass at 3.x, and `chain-plan-authoring-into-build.md` carries a dedicated
   "Appendix C — Model bleed trace." Behavior when a fable-pinned skill invokes an
   opus-pinned one is unverified.
4. **Dual-write divergence.** Two artifacts per round, one authoritative. Decision 4 names
   the prompt as canonical, but nothing enforces it — a reader who opens the proposal doc in
   6.0.0 has no signal it is the deprecated copy unless the file says so. Mitigation: a
   deprecation banner written into the proposal doc itself.
5. **The test file is already red and unwired.** `tests/plugins/test-build-proposal.sh`
   check 12 fails on `main` and no workflow runs it
   (`docs/plans/wire-plugin-tests-into-ci.md:47`). Rewriting it against the new contract
   inherits a suite nobody is currently watching.
6. **An inbound relative link survives.**
   `docs/plans/merge-plan-interview-into-plan-agent.md:26` links `../proposals/…`.
   Dual-write keeps it resolving through 6.0.0; 6.1.0 must fix or drop it.
7. **Information loss is real even with a fifth template.** Two of the four existing
   proposals carry appendices (up to 4 in one file). Template slots are finite; appendix
   content needs either an explicit repeating slot or an accepted truncation rule.

### Incidental findings (surfaced, not in scope)

- `write-prompt/references/best-practices-reference.md` (119 lines) declares itself
  "consumed by the `write-prompt` skill", but **no phase in `SKILL.md` instructs reading
  it**. It is dead weight today.
- `docs/prompts/task-refactor-authentication-middleware-2026-06-04.md` wraps its body in a
  ` ```text ` fence, contradicting `SKILL.md:282` ("embed the prompt as plain text"). The
  other three do not. Existing corpus is already inconsistent.
- `write-prompt` is absent from the Plugin Structure tree in
  `kit/plugins/plan-agent/README.md:445-503`, which lists only 8 of 14 skill directories.
- The README describes write-prompt as a "six-phase pipeline" (L287-294); Phase 7 (Save) is
  missing from that list.

## Open questions

Decisions, not missing facts. All require a human call before or during planning.

1. **`status:` vocabulary for prompt frontmatter.** Reuse the plan lifecycle
   (`todo`/`in-progress`/`completed`) so `plan-status` tooling could someday apply, or a
   proposal-native vocabulary (`gathering`/`converged`)? The two carry different downstream
   promises.
2. **What does `--dir` mean during dual-write?** It currently overrides the proposals
   directory. Does it now target the prompts directory, the proposals directory, or split
   into two flags for one release?
3. **Is 6.1.0 automatic or gated?** Decision 4 sets the deprecation window at one release.
   Should removal ship on schedule, or wait on evidence that nothing depends on
   `docs/proposals/`?
4. **Appendix handling in the template.** Explicit repeating slot, a single catch-all
   `{{APPENDICES}}`, or an accepted truncation rule with a pointer to the transcript?

## Roadmap

**Phase 1 — Unblock and prove the seam.** *(S)*
WS1 alone. Land `commands/write-prompt.md`, confirm `write-prompt` becomes registry-visible
and `Skill()`-callable, and confirm the three-level nesting and model-pin questions (risks 2
and 3) empirically before building on top of them. This phase de-risks everything after it
and is independently shippable.

**Phase 2 — Build the target type.** *(L)*
WS2 plus WS5, together. The fifth type and `prompt-artifact`'s fifth chip must ship in the
same release or the library gallery is visibly broken. Depends on Phase 1.

**Phase 3 — Rewire and dual-write.** *(L)*
WS3, WS4, WS6. The interview bypass, `build-proposal`'s Step 6/Step 8 changes, `build`'s
Step 1b, and the two test files. Depends on Phase 2.

**Phase 4 — Ship 6.0.0.** *(M)*
WS7. Docs, both CHANGELOGs, marketplace bump. Depends on Phase 3.

**Phase 5 — Remove the proposal path (6.1.0).** *(M)*
Delete the dual-write branch, retire `docs/proposals/`, fix the inbound relative link
(risk 6). Gated on open question 3.

## Appendix A — The invocability natural experiment

Every plan-agent skill carrying `disable-model-invocation: true`, against whether a
`commands/` wrapper exists and whether the skill appears in the live session registry:

| Skill | Flag | `commands/` wrapper | In session registry |
|---|---|---|---|
| `deep-grill` | yes | `commands/deep-grill.md:13` | yes |
| `documenting-plans` | yes | `commands/documenting-plans.md:13` | yes |
| `write-prompt` | yes | none | **no** |
| `finalize-plan` | yes | none | **no** |

Twelve skills repo-wide carry the flag. `plan-agent:write-prompt` is the target of **zero**
`Skill(skill: ...)` call sites anywhere in the repo — the pattern has never been exercised
against it.

## Appendix B — Section-to-slot mapping (draft input for WS2)

The 13 canonical sections from `artifact-shape.md`, mapped onto the proposed fifth
template. This is the concrete artifact WS2 has to produce.

| Canonical section | Proposed slot | Notes |
|---|---|---|
| Front-matter | frontmatter keys | plus `status:`, `modified:` per decision 2 |
| Title + framing note | H1 + `<framing>` | framing note becomes a fixed line, not a slot |
| TL;DR | `{{TLDR}}` | Tier 2 only; omitted for Tier 1 |
| Context | `{{CONTEXT}}` | inside `<context>` |
| Core finding | `{{CORE_FINDING}}` | single load-bearing sentence |
| Side-by-side | `{{COMPARISON_TABLE}}` | markdown table passed through |
| Locked & resolved decisions | `{{LOCKED_DECISIONS}}` | repeating |
| Workstreams | `{{WORKSTREAMS}}` | repeating |
| Risks & tensions | `{{RISKS}}` | repeating |
| Open questions | `{{OPEN_QUESTIONS}}` | decisions only |
| Roadmap | `{{ROADMAP}}` | phased, S/M/L |
| Appendices | unresolved | see open question 4 |
| Next step | `{{CORE_INSTRUCTION}}` | the handoff becomes the prompt's instruction |

The last row is the load-bearing one: the proposal's *Next step* section and the prompt's
core instruction are the same thing. That is the structural reason the refactor is coherent
rather than a forced fit.

## Next step

The proposal is decision-complete at `docs/proposals/replace-proposal-doc-with-prompt.md`.
To turn it into an execution plan, run:

`/plan-agent:implementation-plan author an execution plan from the proposal at docs/proposals/replace-proposal-doc-with-prompt.md`

Lead with the objective, not a bare `.md` path — a bare path drops `implementation-plan`
into conversion mode and yields a plan whose steps restate proposal headings instead of
naming real actions. This skill decided *should-we + what*; planning owns *how*.
