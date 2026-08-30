# Changelog

## 9.11.0 — finalize-plan reconciles the plan against what shipped (2026-08-30)

### Added

- **`finalize-plan` Step 3d reconciles the plan against the shipped commits.**
  Steps 3a–3c only ever asked one direction of the question — *was each planned
  thing built?* — so a plan whose implementation grew a file, a flag, or a
  different approach was marked completed while its published artifact still
  described only the scope imagined before the work started. 3d asks the other
  direction. It takes the commits that touched the spec (`git log --follow`,
  precise because plans are committed alongside the change they describe),
  falls back to the default-branch range when the spec commit has not landed yet,
  and sorts the changed paths against `## Files` and the 3a tokens into two new
  buckets: **shipped but unplanned** and **built differently**. Housekeeping
  paths — the spec itself, generated indexes, lockfiles, version bumps — are
  excluded, since they ship with every plan and say nothing about scope. 3d
  only observes; the buckets are reported in Step 4 before the user confirms.
- **`5c2` writes unplanned shipped work into `## Steps`** as an already-done
  `Unplanned: <what> — <why>` step. The step list is what a reader treats as
  the record of what was built, so work kept only in prose leaves the rendered
  plan under-reporting the change. In a phased spec these land under a trailing
  `### Phase: Unplanned` rather than at the end of the list, where they would
  drop into a phase that was never started and muddy 5a0's
  completable-versus-checkpointed gate; every step in that phase is `[x]`, so
  the gate ignores it. Runs even when the phase gate skipped 5c.
- **`5d2` writes a changed approach into `## Decisions`** — the settled-choices
  ledger a resumed session already reads so it does not re-litigate a closed
  question. Deliberately not the `## Completion Report`: every entry there
  renders with a red dot (`.report-list dt::before`), and work that shipped
  fine is not a defect.

### Fixed

- **5d's removal rule is now scoped to its own section.** "If every criterion
  was verified, remove the Completion Report and add nothing" described exactly
  the state a clean run with extra scope lands in, so the happy path was
  precisely where reconcile output would have been discarded.

### Notes

- No renderer change. All four reconcile buckets route to sections
  `build-plan-html.mjs` already parses, renders, and round-trips — a new
  `## What Shipped` section would have cost parse, render, digest,
  `extractSections`, and CSS, and the parser silently drops sections it does
  not know.
## 9.10.2 — hook count in the README matches dispatch.py (2026-08-30)

### Fixed

The plugin README's component table said `dispatch` "fans out to the six below"
and listed six children. `dispatch.py` fans out to seven: `render-plan-html` was
missing from the list, so the plugin README contradicted the root README, which
has said "all seven Write/Edit hooks" since the renderer hook landed. Added the
missing row and corrected the count.

The same table called `dispatch` "the plugin's only registered hook", which
contradicts this README's own hook inventory further down — `hooks.json`
registers two PostToolUse entries, the `Write|Edit|MultiEdit` dispatcher and the
`ExitPlanMode` stress-test nudge. It is the only registered *Write/Edit* hook;
the row now says so.

`dispatch.py`'s own module docstring had drifted the same way: it said "six
PostToolUse hooks" while the parenthetical immediately after it enumerated
seven. Docs only — no behaviour change.

The README's overview paragraph had drifted the same way in the other direction:
it said the plugin "ships two `PostToolUse` hooks" and then named filename
validation and the plans-index rebuild — the right count attached to the wrong
two. Those are children of `dispatch`; the two registrations in `hooks.json` are
the `Write|Edit|MultiEdit` dispatcher and the `ExitPlanMode` nudge. It now
describes the real shape.

Three more spots carried the same wrong count: the "Hook dispatch" section said
`hooks.json` registers "exactly one PostToolUse hook" and that registering "the
four hooks" separately spawned four interpreters (it is seven children under two
registrations), and the repository-layout tree repeated the one-registration
claim twice. All now match `hooks.json`.


## 9.10.1 — the build completion gate stops failing artifact-only plans (2026-08-25)

### Fixed

- **`scripts/build-plan-html.mjs` creates missing `-o` parent directories.**
  Both the `build` and `finalize-plan` references render an artifact-delivered
  plan to `"$SCRATCHPAD/<stem>.html"`, and `<stem>` always carries directories
  (`docs/plans/foo`), so the documented command died on an unhandled `ENOENT`
  stack trace before writing a byte — the artifact re-render recipe could not
  be run as written. `--check` still writes nothing, directories included.
- **`skills/build/references/completion-gates.md` Step 5.3 now points `--check`
  at the scratchpad render for an artifact-delivered plan.** The command was
  hardcoded to `-o "<stem>.html"`, which an artifact-only plan does not have —
  so every such plan failed its own completion gate on a spec whose `steps` and
  `criteria` rows both passed. Worse, the `html` row's remediation line names
  the one command `references/re-render.md` forbids: writing the sibling
  resurrects a file the author chose not to publish, and `build-index.sh` gives
  a sibling priority over the URL, so the plan's gallery card silently flips off
  the shared artifact onto a local path. `finalize-plan`'s
  `references/write-completions.md` already carried this carve-out; the two are
  meant to stay consistent and had drifted.
## 9.10.0 — artifact-published plans reach review, design, and prototype (2026-08-28)

### Fixed

Since 9.7.0 the local `<stem>.html` has been a `--file` opt-in and the claude.ai
artifact the default deliverable, so the ordinary shape of a plan on disk is a
`.md` spec carrying `artifact-url:` and nothing else. 9.9.0 taught the
completion path that shape. Three consumers still assumed a file:

- **`review-plan` could not see an artifact plan.** Step 1 discovered plans with
  `glob docs/plans/*.html`, and an artifact plan has no HTML — so running the
  reviewer bare did not fail, it silently reviewed the most recent
  *file*-published plan instead, which is the worse outcome. Discovery now
  unions the HTML glob with a spec-side scan carrying the same four guards the
  `finalize-plan` sweep uses: frontmatter-bounded matching (these plans are
  often *about* plan-agent, so a body line quoting `artifact-url:`
  false-matches a whole-file grep), a `# Plan:` gate that keeps session-export
  notes out, an `https?://[^/ ]` host requirement, and `done || true` so an
  empty result is not a `set -e` abort. An explicit `.md` path is accepted too —
  the same `.html` or `.md` token shape `finalize-plan` Step 1 already took,
  and the only path an artifact plan has to paste.
- **`review-plan` Step 7 resurrected the file the author chose not to publish.**
  The re-render wrote `<stem>.html` unconditionally, which flips the plan's
  gallery card off the artifact onto a local path and leaves the shared page
  stale — at exactly the moment it most needs updating, since a review is the
  state every other reader sees. Step 1 now records *where* the plan is
  published as a finding separate from the edit mode, and Step 7 branches on
  it: overwrite the sibling when one exists, otherwise render to the scratchpad
  and republish to the recorded `artifact-url:`. `Artifact` joins the skill's
  `allowed-tools` and the `agent-review-plan` subagent's `tools` — without it in
  both the republish would prompt mid-run, which in background mode (the only
  mode that subagent uses) means silently never happening.
- **`design` and `prototype` treated a spec as a raw idea.** Their first-token
  test recognized `.html` only, so a `.md` fell through to the final "otherwise
  the whole argument string is a raw idea" branch and the skill ran to
  completion having designed against a filename — no error, just a canvas about
  a path. Both now classify `.html` or `.md` as a plan path, and their
  spec-resolution steps read "the resolved plan's stem plus `.md`", which is
  already the resolved path itself when a spec was what came in.

`tests/plugins/test-artifact-plan-review.sh` pins all of it; the discovery
snippet was additionally run against fixtures covering a `javascript:` URL, a
hostless `https://`, a session-export `.md`, a body-only key mention, a spec
with a sibling, and an empty directory.

## 9.9.0 — completion state reaches artifact-published plans (2026-08-26)

### Fixed

- **`plan-status` now republishes an artifact-published plan.** A plan published
  to claude.ai is a spec carrying `artifact-url:` with **no** sibling
  `<stem>.html`, and that missing sibling is precisely the file-published signal
  `render-plan-html.py` uses to skip re-rendering. `plan-status` wrote `status:`
  into the frontmatter and stopped, so nothing ever updated the page — the spec
  read `completed` while the page everyone else opened still read `todo`. The
  new Step 8 renders to the scratchpad and calls `Artifact` with the recorded
  URL, updating the existing page in place; the whole spec goes with it, so the
  `[x]` step markers, `- [x]` criteria, and `## Completion Report` bullets land
  on the shared page together with the status. `Artifact` joins the skill's
  `allowed-tools` (without it the republish would prompt mid-run, which in a
  bulk pass means silently not happening). Bulk mode runs the same pass after
  its write stage and reports `republished: N` — its YAML prepend is a Bash
  subprocess write, which fires no PostToolUse hook at all.
- **`finalize-plan --all` can now see artifact plans.** Sweep discovery grepped
  `"$PLANS_DIR"/*.html` for a `todo`/`in-progress` `plan-status` meta tag, so a
  plan with no HTML on disk was never a candidate — the sweep skipped exactly
  the plans whose staleness was publicly visible. S1 adds a spec-side scan
  (`artifact-url:` present, no sibling `.html`, `status:` todo or in-progress)
  and unions the two lists; the sibling test keeps a plan from appearing twice.
- **Delivery stopped promising a file that does not exist.** Both `finalize-plan`
  delivery steps handed back `<stem>.html`; for an artifact plan that path is
  either absent or a scratchpad temp that dies with the session. They now send
  the `.md` and report the artifact URL.

The artifact scan carries three guards, each closing a distinct failure found
by reviewing the first cut of it:

- **Frontmatter-bounded matching.** Grepping the whole spec made a *completed*
  plan whose body documents plan-agent's own keys — a bare `status: todo` line
  inside `## Steps` — a sweep candidate. Reproduced against a fixture, and not
  hypothetical in a repo whose plans are about plan-agent. An `awk` extract
  reads only the frontmatter block, which is also less work than two
  whole-file greps.
- **`# Plan:` gate.** A non-spec `.md` carrying both keys entered the candidate
  list, and S4 resolves edit mode through Step 1 — which is instructed to STOP
  on a `.md` with no `# Plan:` heading, halting the sweep partway and leaving
  earlier plans written and later ones untouched.
- **`done || true`.** The loop's exit status is its last command, so a
  directory whose final spec did not match aborted the sweep under `set -e`,
  precisely when there was nothing to sweep.
- **A host is required.** `https?://` alone matched a truncated `https://`
  with nothing after it. Passing that to `Artifact` claims a *new* URL rather
  than updating the shared one, stranding the link people already have. Every
  eligibility rule now reads "an `http(s)` URL **with a host**", matching the
  gate `implementation-plan` Step 7b and `publish-hub` already applied.

S1 also now concatenates both lists into `candidates`, the name S2–S4 iterate;
without it the artifact list was discovered and then silently dropped. S4
records each republish outcome, which S5 was already told to report but nothing
captured.

Pinned by `tests/plugins/test-artifact-plan-completion.sh`, whose five guard
checks were each mutation-tested by deleting the guard and confirming the check
goes red — two of them initially matched the prose explaining a guard rather
than the guard itself, and stayed green when it was removed. `build` was
already correct — it routes through its own re-render subroutine — and is
unchanged.

## 9.8.0 — publish-hub bundles a plan and its related HTML into one artifact (2026-08-26)

### Added

- **`publish-hub` skill + `scripts/build-plan-hub.mjs` + `bin/plan-agent-hub`.**
  A plan's related HTML stayed local: the prototype and companion pages were
  unreachable from the shared plan URL. `/plan-agent:publish-hub` bundles the
  rendered plan, the `prototype:` file, and any `--extra` pages into one
  self-contained tab shell — each document isolated whole in an
  `<iframe srcdoc>` panel, `design:` as an external-link tab — and publishes
  it to a stable URL recorded as `hub-artifact-url:` in the spec frontmatter,
  never touching the plan's own `artifact-url:`. The bundler escapes `&`/`"`
  exactly once per srcdoc, caps output at 15 MB (under the 16 MB artifact
  limit), and on overflow exits 1 naming the largest embedded document — the
  related file to `--skip`, or the plan itself when nothing skippable would
  close the gap. Flag-shaped values (`-o --skip`) are misuse, never
  filenames. Pinned by `tests/plugins/test-build-plan-hub.mjs`.

## 9.7.1 — artifact-mode renders stop leaking local paths (2026-08-25)

### Fixed

- **`plan-path` stays repo-relative when the output lands outside the repo.**
  Default mode renders to the scratchpad before publishing, and
  `build-plan-html.mjs` relativized that against the cwd — stamping
  `../../../../../../../private/tmp/.../scratchpad/<stem>.html` into the
  `plan-path` meta tag and the "More ways to run this plan" drawer of a page
  whose whole point is being shared. An out-of-repo output now falls back to
  where the HTML belongs beside the spec. Pinned by
  `tests/plugins/test-build-plan-html.mjs`.
- **Step 5d no longer contradicts Step 7a.** 5d said to render `<stem>.html`
  beside the spec; 7a says default mode leaves the repo without one. Following
  the steps in order dropped an unwanted ~90 KB sibling into the plans
  directory — and by the skill's own rule that sibling then wins the gallery
  card over the artifact, silently bypassing the feature 9.7.0 added. 5d now
  defers the output path to Step 7a.

## 9.7.0 — the plans gallery cards artifact-only plans (2026-08-25)

### Added

- **`hooks/build-index.sh` walks `.md` specs alongside `.html` files.** A spec
  carrying an `http(s)` `artifact-url:` and no sibling `.html` is a plan
  published straight to claude.ai with nothing rendered locally, and until now
  it was invisible to the gallery. It is now carded by its artifact URL, in a
  new tab, with `rel="noopener"`, an `artifact-chip` in the meta row, and a
  visually-hidden "(opens on claude.ai)" note. A sibling `.html` always wins
  its stem: the file is the copy the author chose to keep.
- **Three gates before a spec is carded** — the URL exists, its scheme is
  `http(s)`, and the body carries the four sections `build-plan-html.mjs`
  refuses to render without. The scheme check keeps a hand-edited
  `javascript:` value out of an href that lands raw in a page people click; the
  section check keeps `docs/plans/sessions/` exports, which carry their own
  `artifact-url:`, out of the *plans* gallery.

### Changed

- **`/plan-agent:implementation-plan` publishes to a claude.ai artifact by
  default.** Step 7 renders the plan into the scratchpad, publishes it with
  `Artifact`, writes the returned URL into the spec as `artifact-url:`, and
  reports the link. The repo gets the `.md` spec and no generated HTML. Pass
  the new **`--file`** flag to also write and commit `<stem>.html` beside the
  spec; publishing happens either way, and the sibling wins the gallery card.
  If `Artifact` is unavailable the skill says so and falls back to file
  delivery rather than leaving the plan undelivered.
- **Re-publishing targets the same URL.** Step 7 re-reads the spec's
  frontmatter immediately before publishing, so a plan edited and re-delivered
  updates its existing page instead of stranding the link the user already
  shared. `build` and `finalize-plan` follow the same rule when they re-render
  after ticking steps or marking completion.
- **`artifact-url:` is parsed, not prefix-matched.** A `^https?://` test passes
  `https://` and `https:// host/x`; the second is not merely a dead card link,
  it lands verbatim in the republish prompt where an agent normalising the
  space away would publish to a host nobody named. The renderer uses `new
  URL()`, the gallery and the three `plans_count()` copies use `urlsplit` plus
  a whitespace check, and all six agree on what counts as a URL.
- **The renderer appends a republish clause to all three prompts.** When a spec
  carries an `http(s)` `artifact-url:`, the implement, goal, and workflow
  prompts each end by naming that URL and instructing a republish after the
  re-render — the only way a fresh-session agent learns the shared page exists.
  Non-`http(s)` values are dropped with a warning, as `design:` already was.
- **`render-plan-html.py` no longer creates a sibling that does not exist.** A
  missing `<stem>.html` is the signal that the plan lives at an artifact;
  rendering one resurrected the file its author chose not to publish. The
  gallery index is still rebuilt on those writes, since the card reads title,
  status, and step markers from the spec.
- **Every gallery card carries `data-local="<stem>"`**, the plan's
  plans-dir-relative path without its extension, and
  `scripts/merge-plans-index.mjs` keys its union on that instead of on `href`.
  Publishing changes an href, so an href-keyed merge saw one plan as two and
  grew a duplicate card on every such branch merge. Cards predating the
  attribute fall back to their href with a trailing `.html` stripped, which
  lands on the same stem — that is what makes the first merge after this
  change correct rather than doubling every card in a committed index.
- **`plans_count()` in `build-artifacts-index.sh`, `build-designs-index.sh`
  and `build-prototypes-index.sh` applies the same rule.** Each gallery topbar
  shows a PLANS tab count computed off the filesystem (the four generators run
  in arbitrary order, so reading a sibling index would report a stale one), so
  three counters that did not know about artifact-only plans disagreed with
  the plans page the moment the first one existed.
- **The "no plan files found — skipping" guard moved to the parsed entry
  list.** A plans directory holding only specs the gallery cannot link now
  leaves an existing `index.html` alone instead of blanking it.

## 9.6.1 — build checks the checkout is current before implementing (2026-08-23)

### Changed

- **`build` gains a stale-checkout guard** in its Step 1 pre-flight
  (`references/resolve-plan.md`), beside the existing dirty-tree guard and
  ahead of plans-directory resolution. A plan is written against a snapshot of the repo; implementing it
  from a checkout that predates that snapshot makes every premise in it suspect
  ("this file is unreferenced", "this helper does not exist yet") and produces
  work that is confidently wrong rather than obviously broken. It fetches,
  resolves the base branch from `refs/remotes/origin/HEAD` rather than
  hardcoding `origin/main`, and counts `HEAD..$BASE`. Non-zero stops and asks;
  it never updates the checkout on its own, since a rebase can conflict with
  uncommitted work. It is a guard, not a gate — a detached HEAD, a missing
  remote, or a failed fetch is reported and the build continues.
- **The guard lives in the reference, not the core.** `build/SKILL.md` sits at
  596 words against the 600-word ceiling in
  `tests/plugins/test-progressive-disclosure.sh`; a core is paid in full on
  every fire, so not even a one-line pointer fits. The core already delegates
  Steps 0-1 to `resolve-plan.md`, so the guard costs the core nothing.
- **The guard calls out worktrees explicitly.** A worktree can report a clean
  tree, an up-to-date upstream, and a branch that exists on origin while
  sitting many commits behind the default branch; none of those signals answer
  the question this step asks.


## 9.6.0 — build-feature becomes a product feature doc (2026-08-23)

### Added

- **`build-feature` now writes the product content a team needs to accept a
  feature, not just the split it breaks into.** The doc gains user stories
  with observable, binary acceptance criteria (including the unhappy path),
  goals whose baselines are researched rather than estimated, and a release
  and rollout table covering owner, target, flag, phases, rollback, and
  dependencies. Stories are drafted at Step 3, before the seams harden, so a
  seam no story crosses and a story no sub-feature delivers both surface as
  findings instead of shipping as a doc that reads consistent and is not.
- **Step 9 publishes the converged doc as a shareable claude.ai artifact.**
  The doc is rendered to a sibling `.html` first — markdown cannot set its own
  `<title>` — then published, verified by fetching the returned URL, and the
  URL recorded as `artifact-url:` in the doc's front-matter so later rounds
  republish to the same link instead of minting a new one. Publishing is the
  only step here a human cannot undo by editing a file, so it needs an
  explicit yes every run: a blanket "don't ask me anything" covers the
  feature's decisions, never this one. New `--publish` / `--no-publish` flags
  pre-answer the offer; `--publish` consents for that run only. A failed or
  unavailable publish costs nothing — the doc and prompts were the deliverable
  before the offer and still are.
- **Sub-feature entries carry paste-ready handoffs to planning, prototyping,
  and design**, with the prototype and design commands emitted only for
  entries that change something a user sees.
- **`prototype` now accepts `--from-prompt <path>`.** `build-feature` emits the
  flag on the prototype handoff for UI-bearing sub-features, but `prototype`
  had no `argument-hint` and classified only on the first token, so the flag
  and its path were swallowed as literal idea text and the prompt was silently
  dropped — the prototype got built from the objective sentence alone, without
  the acceptance criteria the handoff exists to carry. Step 1 now strips the
  flag from anywhere in the argument string (the handoff emits it *after* the
  objective) and reads the prompt for criteria, scope cuts, and UX and
  accessibility constraints, treating them as binding.
- `tests/plugins/test-build-feature.sh` — structural smoke test covering the
  frontmatter contract, the tier gate, the Step 8 hand-off, the Step 9 publish
  contract, and the product sections in the shape reference. Its assertions
  check contracts rather than the prose describing them: the Tier 0 check
  parses every emitted `implementation-plan` command and rejects any `.md` not
  preceded by `--from-prompt`; Step 9 is anchored on its four numbered moves
  and asserts render → publish → verify → record order, that each move carries
  its own mechanism, and that `Artifact` receives the rendered `.html`; the
  breakdown check requires rationale, size, and dependency order. A
  presence-only assertion passes happily next to a warning that contradicts the
  command beside it — which is how the Tier 0 handoff bug reached a commit.

### Changed

- **Tier 0 now writes a one-page doc instead of writing nothing.** It was
  routing straight to `implementation-plan` with no artifact, on the reasoning
  that a one-plan feature has nothing to split. True, but the split was never
  the only thing the doc carried: a plan says *how*, and nobody downstream
  re-derives *for whom* and *why not the other thing*. Tier 0 keeps Context,
  Problem and users, Stories, Scope, Risks, and Next step, and drops only the
  breakdown and its sub-feature prompts. Its handoff is
  `/plan-agent:implementation-plan <objective> --from-prompt <features-dir>/<slug>.md`
  rather than a bare `<idea>`: Tier 0 writes no prompt, so the doc is the only
  carrier for its stories, scope cuts, and risks. The doc rides behind the
  flag, never as a positional token — `implementation-plan` reads the first
  *positional* `.md` as a conversion source and would 1:1-map a doc that has
  no `Steps` section, and a prose `feature doc:` label does not make the path
  non-positional. README.md's Tier 0 line, which still described the old
  writes-no-artifact behavior, is corrected to match.
- **`implementation-plan`'s prompt-source mode accepts a Tier 0 feature doc.**
  `--from-prompt` was documented as naming a saved *proposal prompt*; it now
  names any context source — proposal prompt, sub-feature prompt, or feature
  doc — which is what makes the Tier 0 handoff above legal rather than a path
  that happens to parse. Behaviour was already right for the doc case (read
  for context, then draft normally, never transcribe); only the contract was
  too narrow. The section also now states why the flag matters: its value is
  excluded from the positional-`.md` scan, so it is the flag, not the prose,
  that keeps a context source out of conversion mode.
- **Sub-feature prompts now carry the acceptance criteria** alongside the
  goals, scope cuts, UX and accessibility notes, rollout constraints, and
  risks. The paste-ready command hands the planner the prompt and never the
  feature doc, so anything left out of the prompt is unrecoverable downstream
  — and the criteria are what the plan's own tests get written against.
## 9.5.0 — a design phase, so a plan can be seen before it is built (2026-08-21)

`prototype` answers *does this flow work* with a clickable file. `design`
answers the question that comes first — *what does this look like* — with a
multi-artboard canvas, and hands it back to the plan as a link.

### Added

- **`design` skill** — `/plan-agent:design <plan.html | idea | image |
  figma-url>`, or ambient activation on "design this plan" intent. It resolves
  the input, derives **one artboard per user-facing plan step** (uncapped; a
  step with no user-facing surface produces none), echoes the artboard list
  back for confirmation, then delegates *all* authoring and publishing to
  Claude Code's built-in `design` skill via `Skill(design)`. It reproduces
  none of the artboard file format, the seeding helper, the contract pin, or
  the capability roster — a copy of any of those rots the first time the
  built-in skill moves, and none of it is the part a planning plugin knows
  anything about. What it owns is the plan-shaped half: input resolution,
  step-to-artboard derivation, and writing the result back into the spec.
  Working artboards land under `docs/designs/<plan-slug>/`.
- **Two frontmatter keys on a plan spec.** `design:` is the published canvas
  Artifact URL — the renderer emits `<meta name="plan-design">` and a **View
  design** link in the header actions row. `design-dir:` is the repo-relative
  artboard directory (`docs/designs/<slug>`), which `build` reads as the
  visual spec and the drift hook reads to find the artboards. Two keys rather
  than one slug-derived path, so the pair survives a plan rename that a
  recomputed directory would not.
- **`design:` is modelled on the `issue:` block, not on `prototype:`.**
  `prototype:` relativizes a repo path with `path.relative()`; a canvas lives
  at a URL and there is nothing to relativize. Only `http(s)` is accepted:
  escaping leaves a scheme intact, so a spec carrying `design: javascript:...`
  — imported, or hand-edited — would otherwise render as an ordinary-looking
  anchor that runs on click. Anything else is dropped for both the meta tag
  and the link, with a warning on stderr.
- **`build-designs-index` hook child** — regenerates `docs/designs/index.html`
  on any write under `docs/designs/`, one card per canvas directory. Forked
  from `build-prototypes-index.sh`: same two run modes, same always-exit-0
  contract, so a gallery failure never blocks the write that triggered it.
- **`check-design-drift` hook child** — reports any user-facing plan step with
  no covering artboard. It deliberately does **not** compare local artboards
  against the published canvas: people editing the canvas in the GUI is the
  feature working, and a check that fires on that is noise, not signal. It is
  filename and heading comparison only — no network, no parse of the published
  canvas — because every `dispatch.py` child shares one deadline, so a slow
  child starves its siblings.
- **One definition of "user-facing", two consumers.** The skill's derivation
  rule and the drift check both apply the UI-signal keyword list `review-plan`
  Step 3b already uses (React, Vue, Svelte, Angular, `.tsx`, `.jsx`, `.css`,
  `.html`, `className`, `style`, Tailwind, button, modal, form, dialog,
  dropdown, page, component). Two lists would drift apart, and every
  housekeeping step would then read as permanent design drift.
- **`bin/plan-agent-designs-index`** — rebuilds the designs gallery (wraps
  `hooks/build-designs-index.sh`), alongside the existing
  `plan-agent-prototypes-index`.
- **Tests** — `tests/plugins/test-design-plan-link.mjs` (the renderer key,
  scheme rejection included), `tests/plugins/test-build-designs-index.sh`, and
  `tests/plugins/test-design-drift.sh`.

### Changed

- **`dispatch.py` gains a `docs/designs/` gate** alongside the existing
  prototypes gate, fanning out to the two new children on the shared deadline.
  Writes outside the gated paths are unaffected — it is the same cheap path
  check that already keeps the dispatcher off every unrelated file edit.
- **`implementation-plan` Step 8 asks a third question — "Want to see it
  before building?"** — with options `Prototype`, `Design canvas`, and `No`,
  gated on the `ui_signals_present` rule from `review-plan` Step 3b. A third
  *question* in the same `AskUserQuestion` call, never two more options: both
  existing option lists already sit at the 4-option cap, so there was nowhere
  to graft the choice on. This is also the first time the existing `prototype`
  skill is offered anywhere in the planning chain — until now it was reachable
  only by knowing the command existed.
- **`build` Step 2 reads the artboards under a spec's `design-dir:`** as the
  visual spec before implementing, when the key is present. A published canvas
  nobody opens during implementation is a picture, not a spec. Plans without
  the key are unchanged.

## 9.4.8 — plan-authoring skills name the mixed-request gate (2026-08-19)

### Changed

- **`implementation-plan`, `build-proposal`, and `build-feature` each gain a
  mixed-request bullet in their existing Scope Constraint sections.** Usage
  analysis found Claude repeatedly drifting into implementation mid-planning,
  forcing the user to interrupt with "don't build anything, write an
  implementation plan first" — a request like "plan X and build it" was being
  read as one instruction. Each section now states it directly: a request
  that bundles planning with building still ends at the delivered
  plan/proposal/feature doc — deliver it, stop, and wait for the user's
  explicit approval (e.g. `implementation-plan` Step 8's `Implement now`)
  before any implementation begins; the original request is never that
  approval. The constraint already lived in global CLAUDE.md rules, but it
  belongs inside the plan-authoring skills so it loads exactly when planning
  starts. Prose only — no workflow, renderer, or hand-off seam change; skills
  that execute already-approved plans (`build`, `build-fleet`) are untouched.

## 9.4.7 — document the product, security, and frontend reviewers (2026-08-19)

### Fixed

- **The `review-plan` reviewer roster in README.md listed seven of ten
  reviewers.** `product` and `security` (core) and `frontend` (UI-conditional)
  joined the team in 8.2.0 when `product-plans` was folded in, but the roster
  list under "The skill spawns the following reviewers" was never updated.
  Every other line in the file — the overview, the skill section, the workflow
  steps, the sample output — already said ten reviewers, and the UI-signal
  paragraph directly below the list named `frontend` as one of the three
  spawned. The list was the only place still describing the pre-8.2.0 team.
  Docs only; no behavior change.


## 9.4.6 — build-feature: research fallback, Risks at Tier 1, verified precedents (2026-08-18)

Three fixes from the first real run of `build-feature`, which produced
`docs/features/composable-skill-chain.md` (#579). Each one is a gap the run
hit, not a speculative hardening.

### Fixed

- **Step 2 has a sequential fallback.** The step assumed `Agent` was
  available and gave no instruction for sessions that withhold it, so a run
  without subagents had to improvise. It now says to sweep internally with
  `Glob`/`Grep`/`Read` instead, report that research ran sequentially, and
  never treat a missing tool as licence to synthesize from memory. The
  parallelism was always an optimization; the grounding is the requirement.

### Changed

- **`Risks & tensions` joins the Tier 1 section subset.** Tier 1 previously
  kept only Context, Goals, Scope, and the breakdown. Risks is the one
  section that can say the feature might not work, so a short doc without it
  can only argue for its own conclusion — the failure mode a small feature is
  most prone to, not least. The reference now states why it is in the subset,
  and that a genuinely risk-free feature says so in one line rather than
  dropping the section. Touches `SKILL.md`'s tier table and
  `references/feature-doc-shape.md`.
- **Step 6 requires opening every precedent before citing it.** A breakdown
  entry that says "models `X`" makes a claim the downstream plan inherits
  unchecked. Step 2's *ground every claim* does not reach here — the citation
  is written two steps later, from memory of a filename that sounded right.
  In the #579 run the cited precedent turned out to assert entirely by grep
  and execute nothing, which resized that sub-feature S to M. The step now
  notes a precedent that fails to hold is the more valuable finding, since
  the sub-feature then has no model to copy.

## 9.4.5 — Context sections name the no-follow-up bar (2026-08-17)

(Authored as 9.4.2 on a branch that predated 9.4.3–9.4.4; ships as 9.4.5.)

### Changed

- **`implementation-plan` and `build-proposal` make the "no follow-up
  question" completeness bar explicit for `## Context`.** The guidance
  already required Context to be grounded in real files/specs rather than
  memory, and already routes settled-choices/resumption content to
  `## Decisions` (`implementation-plan`) or `Locked & resolved decisions`
  (`build-proposal`) — that split was already correct. This just states the
  underlying test in words: a reader with no prior context, including a
  future session after this one's context is cleared, should need no
  follow-up question to judge the plan or proposal.
- Touches `implementation-plan/guidelines/section-catalog.md`,
  `implementation-plan/reference/SKELETON.md`, and
  `build-proposal/references/artifact-shape.md`. No structural or behavioral
  change — prose only.

## 9.4.4 — four skills verify their own output (2026-08-17)

- **`markdown-to-html` gains a Step 5b output gate** modeled on
  plans-library's: a `python3` `html.parser` check asserting the doctype on
  line 1, `</html>` at EOF, skip-link + `<main id="main-content">`, one
  `<section>` per parsed `##` heading, and (plan mode) step-card count equals
  parsed step count — html-spec.md's "Required in every generated HTML file"
  list as the assertion set. A truncated Write or dropped section was
  previously reported as success. `Bash(python3 *)` added to allowed-tools so
  the gate runs prompt-free.
- **`build-fleet` verifies subagent self-reports** before ticking the fleet
  table: `gh pr view --json state,headRefName` per reported PR, unverifiable
  rows marked "unverified — reported by agent" — build-feature Step 8's
  delegation rationale, now applied where it was missing.
- **`prototype` asserts runtime state instead of screenshotting it**: Step 9
  requires zero console errors and the seed rows + summary badge present in
  the DOM with measured values (read via the same `mcp__claude-in-chrome__`
  family the skill already uses; `read_console_messages` and `read_page`
  added to allowed-tools). A silent `JSON.parse` throw previously shipped as
  a "done" prototype behind a blank-table screenshot.
- **`plan-status` executes the plan's own objective test** when the spec's
  `## Tests` carries a `Run:` command (mirroring finalize-plan Step 3c) and
  caps grep-derived status at `in-progress` on non-zero exit; the manual
  fallback drops `draft`, a value the renderer's status enum rejects.

## 9.4.3 — review-plan edits the spec, not the render (2026-08-17)

(9.4.2 was on a then-in-flight branch; its content later shipped as 9.4.5.)

- **`review-plan` detects spec vs legacy mode in Step 1** (spec mode when
  `<stem>.md` exists with a `# Plan:` heading, mirroring finalize-plan's
  `resolve-and-modes.md`). In spec mode, accepted improvements are applied to
  the markdown spec — mapped selector-by-selector to Objective, Acceptance
  Criteria, step Why/Verify lines, and Verification — and the plan is
  re-rendered with `plan-agent-render`. Previously every edit and the appended
  Team Review went into the rendered HTML, which the pipeline's own
  render-on-spec-write hook regenerates and silently discards; the skill was
  announcing "Plan updated in place" on work designed to be deleted.
- **The Team Review now survives re-renders** in spec mode: appended to the
  spec as a `## Team Review (timestamp)` section (report headings demoted to
  `###`), which the spec parser carries through rather than dropping.
- **Step 7 verifies and tallies**: after applying, the edited file is re-read
  and each accepted edit confirmed present; the announcement carries
  "applied N of M accepted edits; skipped: <targets>". In background mode a
  non-empty skipped list makes the report lead with `REVIEW INCOMPLETE` —
  previously a run that matched zero selectors still announced full success.
  `agent-review-plan` and the `review-plan-bg` dispatch carry the same tally.

## 9.4.1 — plan-status carries the plan-mode guard (2026-08-14)

### Fixed

- **`plan-status` exits plan mode before writing** — the skill's Step 7 writes
  lifecycle status and dates into a plan's YAML frontmatter with `Edit`, but it
  carried no guard, so invoking it inside plan mode blocked that write and
  stalled the workflow. It now carries the canonical line as its first step and
  declares `ToolSearch` and `ExitPlanMode` in `allowed-tools`.
- **`commands/plan-status.md` mirrors the new tools** — the command reads the
  SKILL.md by path and runs its steps inline under its own permissions, so the
  skill's `allowed-tools` has to be a subset of the command's.
- **Regression guard** — `plan-agent/skills/plan-status/SKILL.md` is now in the
  `WRITE_HEAVY` manifest of `tests/plugins/test-exitplanmode-guard.sh`.


## 9.4.0 — a deterministic render check replaces the grep drift gate (2026-08-14)

### Added

- **`plan-agent-render --check`** — verifies instead of writing. Three rows,
  always printed in the same order: `html` compares the file on disk against a
  fresh in-memory render and names the first differing line, column, and a
  40-character window of each side; `steps` and `criteria` read the spec's
  `[x]` and `- [x]` markers. Exit 0 only when nothing fails. Writes no files.
- **Consistency is gated on `status: completed`** — below that, the `steps` and
  `criteria` rows report `SKIP`, not `PASS`. A todo plan with unchecked steps
  is in its correct state, so asserting completeness there would fail every
  live plan.
- **Actionable failures** — a missing HTML file reports the exact
  `plan-agent-render … -o …` command that produces it rather than throwing, and
  an unchecked item is quoted verbatim so the offending step or criterion is
  identifiable without opening the spec.

### Changed

- **`build` Step 5.3 is one command instead of five CSS selectors.** The gate
  used to say "confirm the HTML matches the spec" and then name `.step-card`,
  criteria `checked` inputs, the three status representations, cc1–cc3, and
  `all-complete` as the evidence — with no mechanism for evaluating any of
  them. Handed selector names and no tool, the reader reached for `Grep`, which
  searches source markup rather than evaluating a selector: a selector defined
  in the stylesheet counted as a match, and a class the renderer emits
  conditionally did not. Both directions produced false drift and a wasted
  second verification pass. The selector paragraph is deleted, not merely
  supplemented, so there is nothing to fall back to.
- **`finalize-plan` Step 5e runs the same check**, keeping the two gates
  consistent as `completion-gates.md` instructs. Legacy mode — the HTML
  attribute surgery for plans that have no `.md` spec — still names the
  elements it edits, because those are edit targets rather than drift evidence.

### Why

The check was aimed at the wrong artifact. The HTML is *derived* from the spec
by a deterministic function this repo owns, so "is the HTML current?" is a
build-freshness question answered by one byte comparison, and "is a completed
spec internally consistent?" is a Markdown question that never needed the HTML
at all. Neither requires reading rendered markup.

Determinism was measured, not assumed: rendering an unchanged spec repeatedly
over one output path is byte-identical, and `plan-file`/`plan-path` are the
only fields that vary with the output path. They are deliberately **not**
normalized away — a comparison blind to them would pass an HTML file copied in
from another location, which is one of the stale states the check exists to
catch.


## 9.3.0 — build-fleet: ship a plan backlog in parallel (2026-08-14)

### Added

- **`build-fleet` skill** — `build` fanned out. `build` ships one plan on the
  current branch; `build-fleet` ships N plans on N branches, one subagent per
  plan. Command (`/plan-agent:build-fleet [<plan> ...] [--dir <path>]
  [--max N]`) or model-invocable on "ship the backlog in parallel" intent.
- **Dispatch-only by construction** — every step of the work is delegated to
  `plan-agent:build` and `git-agent:ship-autonomous` rather than restated, so
  the completion gates, browser verification, CI autofix, and review triage are
  inherited when those skills change.
- **Worktree isolation via the harness** — each agent runs with
  `isolation: "worktree"`, which creates the worktree and removes it if left
  unchanged. No `git worktree add` and no cleanup pass to get wrong.
- **Plan picker** — the fleet is chosen, not just approved: one `multiSelect`
  `AskUserQuestion` over the newest four candidates (`build`'s discovery sort),
  stating how many were suppressed. The ticked boxes are themselves the
  confirmation, because the question states that each selection opens one pull
  request — a second confirm-the-count question would ask about something the
  user just enumerated by hand. A deeper backlog ships a batch per run, a
  selection over `--max` trims to the newest and says what it dropped, and an
  explicit plan list skips the picker entirely.
- **Blast-radius guards** — a mandatory confirmation that names how many pull
  requests will open, `--max` defaulting to 3, `status: completed` plans
  excluded even when named explicitly, a dirty-tree stop (worktrees fork from
  the base branch, so uncommitted parent-tree work does not travel), and a
  headless run that cancels instead of defaulting.
- **Resolved base branch, never a hardcoded `main`** — Step 1 reads
  `git symbolic-ref --short refs/remotes/origin/HEAD` and carries the value
  into every agent prompt; an unset `origin/HEAD` asks rather than guessing.
  Caught by driving the skill against a `master`-only repo, where the earlier
  hardcoded `origin/main` killed all five agents on line 1 of their prompts.
- **`todo`-only discovery, documented as deliberate** — `build` also accepts
  `in-progress`; the fleet does not, because such a plan usually already has a
  branch and a half-finished tree that a second worktree would redo. Name it
  explicitly to override.
- **Stops at green** — the fleet ends at green PRs. A background agent cannot
  answer `ship-autonomous`'s merge gate, and auto-merging N sibling PRs is the
  one step in the chain with no cheap undo, so merging stays a human step via
  `/git-agent:merge`.


## 9.2.0 — build-feature: feature docs that split into plans (2026-08-12)

### Added

- **`build-feature` skill** — the sibling of `build-proposal` with a different
  seam: a proposal answers *should-we*; a feature doc answers *what are we
  building, and how does it split into plans?* Command
  (`/plan-agent:build-feature <feature idea> [--dir <path>] [--tier 0|1|2]`)
  or model-invocable on feature-doc / break-into-plans intent, with trigger
  phrases disjoint from both siblings.
- **Dual deliverable** — a team feature doc at `<features-dir>/<slug>.md`
  (`--dir` → `planAgent.featuresDirectory` → `docs/features/`; covers context,
  problem and users, goals with metrics, scope in/out, UX notes, risks) plus,
  only at convergence, one saved prompt per sub-feature at
  `<prompts-dir>/feature-<slug>-<sub-slug>.md` via `prompt`'s standard
  `--out`/`--answers-gathered` path — the `proposal` type stays exclusive to
  `build-proposal`, and prompts are never written per round because the
  breakdown can merge or split mid-loop.
- **Recommend-only breakdown** — each sub-feature carries a rationale, an
  S/M/L size, its dependency order, and a paste-ready
  `/plan-agent:implementation-plan … --from-prompt` command. The skill never
  invokes plan generation itself; a Tier 0 gate routes a plan-sized feature
  straight to `/plan-agent:implementation-plan` with no artifact written.
- **`references/feature-doc-shape.md`** — the canonical section order, the
  breakdown entry format (with the four-backtick fenced prompt skeleton), and
  the sizing guide. `tests/plugins/test-build-feature.sh` smoke-tests the
  frontmatter contract, the disjoint description, the dual-deliverable paths,
  and the recommend-only guarantee; the skill is added to the
  `test-exitplanmode-guard.sh` whitelist. `build-proposal` ships byte-identical.

## 9.1.1 — the plugin's hooks actually register (2026-08-10)

### Fixed

- **`hooks.json` was never read.** It sits at the plugin root, which is not a
  discovery path — the documented one is `hooks/hooks.json`. Measured with a
  controlled A/B: identical deliberately-corrupt JSON is reported by
  `claude plugin validate` at `hooks/hooks.json` ("At runtime this breaks the
  entire plugin load") and passes unread at the plugin root. `plugin.json` now
  declares `"hooks": "./hooks.json"` explicitly, which is the same mechanism by
  which plugins pointing at a non-standard hooks filename do fire.
- Consequence for this plugin: `hooks/dispatch.py` — and with it the plan HTML
  re-render, the filename validator, and the plans-index rebuild — was not
  running for installed users. The "re-render the HTML from the spec"
  instruction in generated plans stays load-bearing regardless, since the
  desktop app drops plugin hooks separately from this defect.
- Registration is unchanged otherwise: still exactly one `PostToolUse` entry
  pointing at `dispatch.py`, so the four hooks continue to share one interpreter
  and one timeout budget.

## 9.1.0 — the plan document reads as one system (2026-08-08)

The 7.5.0 shell fixed the contrast and the structure but left the page loud.
Six hues competed for the same eye — a violet accent, moss, a burnt-orange
signal, red, and two purples — over a warm cream ground that belonged to none
of them. `--mono` was doing four jobs at once: the 2.2rem headline, every
section heading, every structural label, and code. Prose was Georgia, so a
corpus carrying 3,000+ inline code spans rendered as a serif/mono collision on
every line. This is a presentation-only pass: no markup changed, no token was
added or retired, and `extractSections()` output is byte-identical.

### Changed

- **Three hues, not six.** `--purple` and `--wish-*` now resolve to the accent
  family, so the sixth and fifth hues are gone. What remains is one accent
  (indigo `#3730c4` / `#a8a2f5`) plus two semantic states — `--moss` for done,
  `--signal` for attention — and `--red` for failure. Every token name is
  unchanged; only the values moved.
- **A neutral that was chosen.** The warm cream `#fcfcfa` sat under a cool
  violet accent and read as a mismatch. Neutrals are now faintly indigo-biased
  (`--paper: #fbfbfd`, dark `#0f0f16`) so the ground and the accent belong to
  the same family. Every pair `tests/plugins/test-plan-redesign.mjs` measures
  still clears 4.5:1 in both palettes.
- **Two type roles, not three.** `--prose` resolves to `--ui`; `--mono` is
  demoted to code and data only. The title and the section headings are sans,
  carrying their emphasis through weight and tracking. No webfont: the CSP
  blocks font CDNs, and inlining a face as a data URI would add six figures of
  bytes to each of ~100 committed plan files.
- **Code spans stopped shouting.** `code.md` carried a fill *and* a border, so
  a paragraph with six of them read as a barcode. Tint only now, no border, a
  hair smaller than its surroundings.
- **The objective is a lead statement, not a slab.** The filled panel put
  saturated colour directly above the Implement row, opening every plan on two
  competing fills. One accent rule replaces it.
- **The Implement prompt is neutral-surfaced.** It was `--moss`, which means
  "done" everywhere else — a green call-to-action on an unstarted plan said the
  opposite of what it meant. Accent on the label, neutral behind the text.
- **State reads before controls.** The header action row orders status and
  effort first and pushes the buttons right, via CSS `order` rather than moving
  nodes the extractor and the gallery both walk.
- **Step actions are emphasised body, not headings.** At 600 across a full
  line, a twelve-step plan read as twelve headlines.
- **Reading text sits in `--ink`.** Section prose was `--ink-2`, one step back
  from the labels around it.

### Fixed

- **Prompt rows broke words mid-token.** Four rows carried
  `word-break: break-all`, which split `add-plan-phase-checkpoints.md` after
  `checkpoint` and `in-progress` after `in-progres`. All four now use
  `overflow-wrap: anywhere`, which only breaks a word when it cannot fit.
- **Files under a subdirectory rendered bold.** The nested `<ul>` is a child of
  the `font-weight: 600` directory row and inherited it, so half the file tree
  was bold for no reason.
- **Six divergent copies of the mono stack.** Rules hardcoded
  `"Fira Code"` variants instead of `var(--mono)`, so the file tree and the
  prompt rows could resolve to a different face than the rest of the page.

### Notes

- All 87 plans under `docs/plans/` that satisfy the plan DOM contract were
  re-rendered through the new shell with `scripts/rerender-plans.mjs`. The 12
  it reports as unreadable are review documents that already predated the 7.5.0
  shell; this release does not change them.


## 9.0.0 — build resolves its arguments by explicit precedence (2026-08-06)

`build` classified `$ARGUMENTS` by testing the **first positional token** for an
`.md`/`.html` suffix or a `/`. A path is one filesystem name, so that test was
never safe on prose: `/plan-agent:build A/B testing for checkout` read `A/B` as
a relative filename, failed to resolve it, and stopped — the objective became a
path. Separately, `--dir tmp/plans` with no plan named stripped to a bare
`build`, found exactly one open spec in that directory, and refused to adopt it,
because discovery was written as "an offer, never a silent pickup" and applied
that rule to a candidate set of size one.

Both are resolution defects, so resolution is now a numbered ladder that stops
at the first matching rule.

### Changed

- **Argument precedence is explicit and total** (`references/invocation.md`).
  Rule 0 strips `--dir`, `--type`, and `--continue` with their values, leaving a
  **rest string**; every later rule reads that, never raw `$ARGUMENTS`. Rule 1
  classifies the rest string as a path when it **names an existing file**, or
  failing that when it is a **single whitespace-free token** carrying an
  `.md`/`.html` suffix or a `/`. The shape test is what fixes the reported
  misparse; the existence test in front of it is what keeps a path that *does*
  contain a space from being caught by it (see the separate bullet below).
  Rule 2 takes everything else as a free-text objective, and **the whole rest
  string is the objective**, not its first token. Rule 3 handles an empty rest string. No
  rule falls through on failure: a missing path still stops rather than
  authoring a plan because of a typo.
- **A lone discovery candidate is adopted, not offered.** One match
  auto-selects and echoes why; several are offered capped at three plus
  `None of these — author a new plan` with the suppressed count; zero asks for
  an objective. The offer exists to prevent picking the wrong plan out of many,
  and a set with no ambiguity in it has nothing to prevent — that mismatch is
  what halted `--dir tmp/plans`.
- **Headless runs take a named default and log it** rather than stopping at
  every gate (`references/resolve-plan.md`). 8.x resolved the undefined-fallback
  bug by making *every* gate stop when `AskUserQuestion` is unavailable, which
  made headless runs useless. Each gate now carries a row in a defaults table —
  discovery at each cardinality, the proposal-versus-direct gate, the
  completed-spec precondition, the dirty-tree guard, and the phase checkpoint —
  taken and logged as `Assumption: <choice> — <why>`. **One exception stops:**
  multi-candidate discovery with nothing `in-progress`, where every candidate is
  equally plausible and picking wrong writes source for a plan the user never
  chose.
- **A single-token slash-bearing objective still classifies as a path** — `A/B`,
  `CI/CD`, `i18n/l10n` are indistinguishable from relative filenames. That stop
  now names the misparse and offers both repairs (add a suffix, or reword)
  instead of listing paths tried.
- **An existing file beats the shape test.** Rule 1 tests the complete rest
  string against the filesystem *before* the whitespace/suffix/slash shape
  test. Without that ordering a plans directory containing a space
  (`--dir "my plans"`) makes every real spec path — `my plans/add-foo.md` —
  fail the whitespace rule and fall to Rule 2, which authors a *new* plan into
  that same directory; `implementation-plan` Step 8's `Implement now` callback
  then re-enters with the new path and misclassifies it again, authoring
  without converging. The filesystem is ground truth, so `A/B testing for
  checkout` still reaches Rule 2 while `my plans/add-foo.md` resolves as a
  path.
- **A value-taking flag with no value is a named error.** `--dir` with nothing
  after it is "`--dir` requires a path"; `--type` with nothing after it names
  the valid set. Covers the flag-shaped-value case too — `--dir --continue`
  must not consume `--continue` as a directory.
  Both silent alternatives were live bugs: dropping the flag resolves the
  default plans directory while the user believes they overrode it, and leaving
  `--dir` in the rest string hands Rule 2 a one-token objective that authors an
  entire plan named after a flag. Caught by driving `/plan-agent:build --dir`
  headless, which did exactly the first of those.
- **The dirty-tree headless default is now deterministic on `git status
  --porcelain`.** Every remaining entry `??` → list them and proceed; any
  tracked file modified, added, renamed, or deleted → report and stop. The
  previous "only changes are plan artifacts, else stop" wording required a
  judgment call, and three headless runs against an identical untracked
  zero-byte file split two-to-one on it — the same undefined-fallback failure
  this release removes from the discovery gate, surviving at the dirty-tree
  gate. Stopping on stray logs and editor droppings also halts every headless
  run in a real repo for nothing.

### Added

- **Resolution test table** (`references/resolve-plan.md`) — eight rows, one per
  case the ladder must handle, each naming its rest string, the rule it takes,
  and the outcome. `tests/plugins/test-build-skill.sh` check 21 asserts every
  row's content and the ladder's `0 → 1 → 2 → 3` ordering, so a reverted rule
  leaves a row asserting the opposite of the prose above it and the suite goes
  red. Checks 11, 15, and 18 were rewritten against the new contract, each
  carrying a negative assertion that fails if the 8.x wording returns.

### Migration

Anything that passed a plan path or ran bare is unaffected. Two behaviours
change: a multi-word objective whose first word contains a `/` now authors a
plan instead of stopping, and a plans directory holding exactly one open spec
now builds it instead of asking. Pass the spec path explicitly to pin which plan
a bare `build` picks up.


## 8.7.0 — red-green-verify plans (2026-08-06)

A plan could name its tests and still be implemented in the wrong order: write
the feature, then write a test that passes against whatever got built. That
test proves the implementation matches itself, not the objective. Nothing in
the spec format forced the failure to come first.

The machinery to fix that already shipped in 8.6.0 — `### Phase:` groupings,
per-step `Verify:` markers, and `build` stopping at each boundary. This release
adds the guidance that uses them, so no parser, renderer, or `build` change was
needed.

### Added

- **`guidelines/red-green-verify.md`** — the RED/GREEN/VERIFY/SHIP phase shape.
  RED authors executable tests and demands the failure output as the `Verify:`
  line, failing *for the right reason* (a test that errors on a missing import
  has not gone red, it has not run). GREEN implements the minimum that passes,
  re-running after every edit, capped at **8 iterations** — the cap is written
  into the phase's last step, because a loop with no cap in the spec has
  nothing to stop it, and the step says report the exact blocker rather than
  success. VERIFY runs the full suite, lint, and typecheck where the project
  has one, then — **on UI plans only** — a live browser pass checking layout,
  touch targets ≥ 44×44px, and zero hydration warnings; a backend or library
  plan has no affected pages and omits the step. SHIP is entered only when the
  first three are green **and the user asked to ship**: `build` Step 6 commits
  only on request, and a SHIP phase that committed unconditionally would
  override that from inside the plan. Its PR body carries the RED failure
  output, the GREEN passing run, and the browser assertions as evidence.
- **UI work asserts on real DOM state, never screenshots.** RED adds a
  browser-verification step driving the browser MCP tools —
  `mcp__Claude_Browser__read_page` refs,
  `mcp__Claude_Browser__javascript_tool` computed styles,
  `mcp__Claude_Browser__read_console_messages`. Either connected surface
  works; `mcp__claude-in-chrome__*` exposes the same calls, and this
  plugin's `prototype` skill and `implementation-plan` Step 7 use that one.
  A screenshot is evidence for a human; it fails silently for an agent.
- **The foreground Node driver.** `&` and `nohup` are blocked by permissions,
  so a step saying "background the dev server, then curl it" cannot run. The
  guideline ships a driver shape instead: spawn the server as a child, poll
  until it answers, assert, `kill()` in a `finally`. Its exit code *is* the
  `Verify:` line.
- **`--tdd` / `--no-tdd`** — force or suppress the shape, skipping detection.

### Changed

- **Step 2 detects whether a plan requires the shape.** It applies when the
  steps touch application source *and* Step 0b found a test runner — the same
  Tier 1 signal Step 5c already classifies on, plus a way to actually run red.
  Tier 2 doc/plan/metadata work is skipped: there is nothing to fail, and a RED
  phase over a `grep -q` check is theatre. Genuinely close calls (Tier 1 with
  no runner, config-only edits, spikes) trigger one `AskUserQuestion` rather
  than a guess. `--quick` skips Step 0b entirely, so the runner signal was
  never established there: one cheap check stands in, and no hit means no RGV
  rather than an inference from nothing. `--tdd` overrides that — it forces the
  shape even with no runner, and RED's first step then stands the runner up so
  the added scope is visible in the plan instead of discovered mid-build.
- **Step 5c** now states that on a red-green-verify plan the `## Tests` bullets
  name the same files the RED steps author — the section is the catalogue, the
  phase is the schedule — so the two cannot drift into separate test lists.
- **`right-sizing.md`** gains a calibration row and a note that phases now have
  two unrelated uses: context budget (the Phased profile) and discipline (this
  shape). They cannot share one heading run — `### Phase: Parse` beside
  `### Phase: RED` leaves a reader unable to tell what a boundary means — so
  RGV wins the headings and the context seams live inside it. If that makes
  GREEN too large for one window, the objective was two plans.


## 8.6.0 — phase checkpoints and a Decisions ledger (2026-08-05)

A long *sequential* plan — step seven depending on a choice made in step two —
could not be implemented across more than one context window. `workflow` fans
out across subagents, which does nothing for a chain that cannot be split, and
`right-sizing.md` told the author a plan needing more than ten steps "is
probably two plans — split it" while offering no mechanism to split with. Two
optional spec sections and a checkpoint loop close that.

### Added

- **`### Phase: <name>` groupings inside `## Steps`.** Each heading groups the
  run of steps below it; the renderer wraps those step cards in
  `<div class="phase-group" data-phase="…">` under an `<h3>`. Numbering stays
  **flat and global** — phases group it, they never restart it — so adding
  phases to an already in-progress plan keeps every `[x]` marker valid and
  `build` still resumes at the first unmarked step rather than at a phase start.
  Carried at all four sites the format is bidirectional across:
  `parseSpecMarkdown`, `buildDigest`, `extractSections`, and the renderer.
  A heading with no steps under it is a spec error — it has nothing to anchor
  to and would vanish on the next round trip.
- **`## Decisions`** — the settled-choices ledger, one bullet per decision,
  rendered as a card after Context with its own sidebar nav entry. Distinct
  from `## Completion Report`, which records gaps rather than choices. This is
  what a resumed session reads instead of re-deriving — or contradicting — what
  an earlier context window already decided.
- **`build` treats each phase boundary as a checkpoint.** It implements one
  phase, runs that phase's `Verify:` lines, appends what the phase settled to
  `## Decisions`, re-renders, then offers `Compact and continue` (recommended),
  `Stop here — resume later`, or `Continue without compacting`. The compact
  branch **prints** the `/compact` command with focus instructions naming the
  spec path and the finished phase and then stops — `/compact` is a CLI
  built-in the user types, not a tool a skill can call. Compaction is safe
  mid-plan precisely because the durable state (step markers, `status:`, the
  ledger) lives in the spec rather than in the conversation.
- **`build --continue`** pushes straight through every boundary. A spec that
  declares no phases never stops and is unaffected by any of this.

### Changed

- **`finalize-plan` will not complete a checkpointed plan.** A spec carrying
  phase headings stays `in-progress` while any phase still holds an unmarked
  step, with each unfinished phase named as a `## Completion Report` bullet and
  the step-marking pass (5c) skipped. `build` stops at its first boundary by
  design, so this is the difference between a plan that finished and one that
  paused.
- **`right-sizing.md` gains a Phased profile** and no longer sends the author
  to a mechanism that does not exist. `section-catalog.md` documents both new
  sections; `implementation-plan/SKILL.md` lists them among what the renderer
  handles.

### Notes

- **Do not author a phase heading in a plan rendered by plan-agent < 8.6.0.**
  Older parsers fold a `###` line between two steps into the preceding step's
  `Verify:` text with no error raised.
- No new shared CSS. The plan stylesheet is emitted verbatim into every
  rendered plan, so one new rule would rewrite the bytes of every committed
  plan; phase and Decisions styling is local to the elements that use it.
  `tests/plugins/test-plan-phases.mjs` pins an unphased render to a sha256 to
  keep it that way.
- Parent/child plan files stay out of scope. Phase boundaries are shaped so
  they can be extracted into child files later.


## 8.5.1 — plans-library delegates to the gallery generator (2026-08-04)

### Fixed

- **`plans-library` no longer counts plans its own way.** The skill hand-executed
  `find "$PLANS_DIR" -maxdepth 1 -name "*.html"`, a second collection rule
  alongside the walk in `hooks/build-index.sh`. `-maxdepth 1` does keep
  `archive/` and `artifacts/` out, but it sees only the top level of the plans
  directory — so every plan filed in any other subdirectory vanished from the
  gallery the moment a user ran this skill, after the `rebuild-plans-index.py`
  PostToolUse hook had already rendered a card for it. Steps 1-5 now delegate to
  `hooks/build-index.sh`, the script that hook already runs, so there is one
  implementation and one total. **-159 lines**
- **Gallery order now matches its own subtitle.** The skill sorted purely
  newest-first while substituting the subtitle "in flight first, then newest".
  `build-index.sh` sorts in-progress plans ahead of the rest, so the page and its
  description finally agree
- **The delegated command can actually run.** It is invoked as the bare name
  `plan-agent-plans-index` via the new `bin/` wrapper, not through a plugin-root
  variable — the Bash tool refuses any command text carrying a shell expansion
  before permission rules are consulted, so the path spelling would have made the
  rewritten skill's only action dead on arrival. Check 11b of
  `tests/plugins/test-extractor-wiring.sh` pins the call site in command position

- **`plans-library` no longer claims it opened a browser it could not open.** The
  launch step ended in `|| true`, so a headless box — no `open`, no `xdg-open` —
  still got "opened in your browser". It now reports which happened, and still
  never fails the skill: the gallery is written and valid either way
- **`build-index.sh` reports the number of cards it wrote, not the number of files
  it found.** The card loop skips any plan it cannot open — a broken symlink, a
  file whose permissions changed between the walk and the read — but the total
  was taken from the pre-parse file list, so the page's own "N items" line, the
  topbar Plans tab, and the `wrote … (N items)` line all overstated by exactly
  the number dropped. Harmless while nothing compared them; now that
  `plans-library` checks its card count against that number, one unreadable file
  would have reported the gallery as a corrupt write and refused to open it

### Added

- **`bin/plan-agent-plans-index`** — bare-name entry point for
  `hooks/build-index.sh`, mirroring the existing `bin/plan-agent-prototypes-index`


## 8.5.0 — typed build entry points (2026-08-03)

### Added

- **`/plan-agent:fix` and `/plan-agent:refactor`.** Thin dispatchers over the
  `build` chain that prepend `--type fix` / `--type refactor`. They restate none
  of the workflow — the proposal gate, plan authoring, review, and the
  completion gates all remain `build`'s. The default is **prepended** precisely
  because `--type` resolves last-wins: `/plan-agent:fix task --type docs`
  expands to `--type fix task --type docs`, so the user's `docs` is last and
  wins. Appending would invert that and let the command's default silently beat
  an explicit override.
- **`build` accepts `--type <kind>`** and forwards it to `implementation-plan`
  on both Step 1b paths. Previously the plan type could only be inferred from
  the objective's leading verb, against a closed vocabulary — `clean up the
  token parser` produced `chore`, not `refactor`.
- **`implementation-plan` accepts `--from-prompt <path>`** — prompt-source
  mode. Reads a saved proposal prompt for context and authors a plan through the
  normal drafting workflow. Distinct from conversion mode: a proposal argues
  whether and what, a plan states how, so proposal headings are input rather
  than a step list to transcribe. When `--type` is absent, a source `type:` is
  used **only if it is already a valid plan type**; anything else falls through
  to leading-verb inference on the objective. No mapping table — the usual
  `--from-prompt` target is a saved prompt, and `prompt` stamps its own genre
  classifier there (`type: proposal` on every prompt `build-proposal` saves),
  which says nothing about the plan's type and would fail the render if carried
  across.

### Fixed

- **The proposal path no longer lands in conversion mode.** `build`'s chain
  handed the prompt path to `implementation-plan` as prose
  (`author an execution plan from the proposal prompt at <path>.md`), but the
  parser scans for the first non-flag `.md` token *anywhere* in the string, so
  the prompt was picked up as `$MD_SOURCE` and restructured into a plan whose
  steps restated proposal headings. The chain's prose guard against this
  ("never a bare `.md` first token") was unenforceable, since leading with prose
  did not stop the scan. The path now travels behind `--from-prompt`, where a
  flag value is not a positional token and the ambiguity cannot arise.
- **`build-proposal`'s Step 8 handoff carried the same bug** and is fixed the
  same way. The printed command a user copies by hand now reads
  `/plan-agent:implementation-plan <objective> --from-prompt <path>`. This is the
  path taken when someone runs `build-proposal` on its own rather than through
  the `build` chain, so fixing only the chain would have left the bug reachable.
- **The proposal path no longer types every plan as `chore`.** That same invoke
  led with the verb `author`, which matches no inference bucket. Plans authored
  through the proposal gate now take an explicit `--type`, the proposal's own
  frontmatter type, or the real objective's verb — in that order.


## 8.4.0 — implement in a fresh context window (2026-08-02)

### Added

- **`Implement now` asks where to implement.** Step 8's `Implement now` now
  opens a sub-choice — `This session` or `Fresh session` — mirroring the
  existing `Review the plan` foreground/background pattern rather than adding a
  fifth top-level option (`AskUserQuestion` caps at 4, and both menu variants
  are already full).
- **`Fresh session` hands off instead of building.** It sets the plan to
  `in-progress`, re-renders, prints the `plan-implement` prompt, and stops so
  the user can `/clear` and paste it into a clean context window. The handoff is
  lossless because the prompt names the markdown spec and the spec carries the
  whole plan — the planning conversation is not load-bearing after Step 8.
- **The skill states that it cannot clear its own context.** `/clear` is a
  client command the user types; no tool triggers it. The branch is written to
  print the instruction and stop, never to claim the context was cleared.


## 8.3.0 — the plan renderer is reachable again, via `bin/` (2026-08-02)

### Added

- **`bin/plan-agent-render`** and **`bin/plan-agent-prototypes-index`** — thin
  wrappers around `scripts/build-plan-html.mjs` and
  `hooks/build-prototypes-index.sh`. Claude Code adds every enabled plugin's
  `bin/` to the Bash tool's `PATH`, so skills invoke them by bare name with no
  path, no `${VAR}`, and no environment dependency. This is the only invocation
  shape a skill can actually run, and it is now the plugin's answer to "how does
  a bundled script get called at all". Each wrapper resolves its target through
  its own `dirname "$0"`, so it works from any install location — for a `#!`
  script the kernel passes the pathname given to `execve` (the absolute path the
  `PATH` lookup resolved) as the script argument, so `$0` is that absolute path
  and never the bare word typed. Verified identical under bash, zsh, and sh.

### Fixed

- **The four call sites 8.2.1 ledgered as known-broken now work.** All four
  spelled a Bash command as `node "${CLAUDE_PLUGIN_ROOT}/…"`, which the Bash
  tool refuses outright with "error: Contains expansion" before permission rules
  are consulted — verified on 2.1.220, unrunnable even for an agent holding
  unrestricted `Bash` and with a matching `--allowedTools` rule. The defect runs
  deeper than the guard: `CLAUDE_PLUGIN_ROOT` is a config-file substitution
  (`hooks.json`, MCP/LSP, monitors) and is **not exported into the Bash tool's
  environment**, so the command would have expanded to a bare `/scripts/…` even
  without the refusal. Sites fixed:
  - `skills/implementation-plan/SKILL.md` — the plan renderer, the plugin's
    most-used script. Every plan this skill wrote depended on the model
    improvising a path after the documented command was refused; that only ever
    resolved inside this repo, where `scripts/build-plan-html.mjs` happens to
    sit at the root.
  - `skills/build/SKILL.md` and `skills/finalize-plan/references/write-completions.md`
    — the shared re-render subroutine. Its `RENDERER=…` / `[ -f "$RENDERER" ] ||`
    fallback dance was doubly dead: the assignment carried an expansion too, and
    the fallback named a repo-local path no installed user has. Both now call
    `plan-agent-render` directly.
  - `skills/prototype/SKILL.md` — the manual prototypes-index rebuild, now
    `plan-agent-prototypes-index`. The wrapper defaults to the current directory
    (replacing the unrunnable `"${CLAUDE_PROJECT_DIR:-$PWD}"`, whose variable is
    likewise absent from the Bash tool's env) and closes stdin, so a manual run
    cannot block reading the PostToolUse payload the underlying script also
    accepts.
- **`scripts/build-dist.mjs` would have dropped `bin/` from the published
  tree.** It copies only KEEP-listed top-level entries, so wrappers that work
  from source would have been missing for every marketplace install — the same
  shape as 8.1.1's defect, where the extractor's library shipped but the
  extractor did not. `bin` is now on the allowlist; `cpSync` preserves the
  executable bit for these extensionless files.

### Tests

- `tests/plugins/test-extractor-wiring.sh`: **check 9 now scans every
  model-facing markdown file** in the plugin — `skills/`, `agents/`,
  `commands/` — minus whatever check 10 still ledgers, instead of just the
  review surface. The ledger became the single exclusion list, so emptying it
  later needs no edit to check 9, and the four files repaired here are now
  actively guarded against regressing to `${CLAUDE_PLUGIN_ROOT}`.
  `README.md` joins `CHANGELOG.md` in the exclusions, deliberately: its
  `node "$EXTRACTOR" …` snippet is correct precisely because it is prefaced
  "Run from your own shell, with a literal path" and sets `$EXTRACTOR` itself.
  A human shell has no expansion guard, and a false positive there is what
  would tempt the next author to loosen the pattern. Every real defect this
  check exists for lived in a model-facing file.
- **Check 10's ledger is updated, not deleted — it does not empty here.** It
  listed 8 sites across 6 files; the 4 fixed above are gone, leaving
  `skills/plans-library/SKILL.md:3` and `skills/plans-open/SKILL.md:1`. Those
  are a different defect class and out of scope: not bundled-script paths but
  multi-line snippets whose variables are set in the same shell block
  (`while IFS= read -r f` feeding `python3 - "$f"`,
  `python3 - "$PLANS_DIR/index.html" "$SOURCE_COUNT"`, and the
  `realpath`/`open` fallback chain). Local definition does not help — the guard
  is textual and rejects the command string before any shell sees it — so
  repairing them means extracting two inline heredoc scripts into `scripts/`
  with real CLIs. That is the gallery pipeline's own change, exactly as the
  renderer pipeline was.
- Two checks added for the wrappers: **check 11** asserts `plan-agent-render`
  exists, is executable, and reaches `build-plan-html.mjs` through its own
  `dirname "$0"` (exit 2 = the renderer's documented no-args usage code,
  unreachable unless that hop landed), plus the exec bit, clean syntax, and an
  existing target for the prototypes wrapper; **check 12** asserts `bin` is on
  the dist KEEP allowlist.


## 8.2.1 — reviewers stop documenting an extractor they cannot run (2026-08-02)

### Fixed

- **The reviewer spec-extraction path cannot work, and is now removed rather
  than described.** 8.1.1 anchored all 15 extractor call sites to
  `${CLAUDE_PLUGIN_ROOT}` to fix a cwd-relative path bug. That spelling is
  correct for a `Read` tool path — no shell is involved — and fatal for a Bash
  command: **Claude Code's Bash tool rejects any command whose text contains
  `${VAR}` or `$VAR` with `error: Contains expansion`**, because it cannot
  statically resolve the expansion. The refusal fires *before* permission rules
  are consulted, so the invocation is unrunnable by every agent at every
  permission level. 8.1.1 therefore did not restore the compute-on-read path it
  set out to restore — it replaced one silent fallback with another.
- **No `tools:` grant can fix it, so none was added.** All ten
  `plan-reviewer-*` agents declare `tools: Read, Glob, Grep, Bash(git *)`, which
  is genuinely enforced for markdown-defined agents (verified against 2.1.220:
  `git status` runs, `node --version` is refused with "This command requires
  approval"). But widening that grant would not have helped: a
  prefix rule such as `Bash(node "${CLAUDE_PLUGIN_ROOT}/scripts/extract-plan-spec.mjs":*)`
  can never match, because the expansion guard rejects the command before rule
  matching begins. A literal-path grant cannot ship either — the install path
  differs per machine. All ten reviewer briefs and all ten agent defs now instruct
  a plain `Read` of the plan HTML, which is what every review has actually been
  doing since the feature shipped.
- **Cost note, stated plainly:** this does not recover the ~10x per-reviewer
  token saving the README advertised — it removes a claim that was never true in
  practice. Run `extract-plan-spec.mjs` yourself with a literal path and paste
  the spec into the review to get that saving today.
- **Out of scope, deliberately left unfixed:** the same defect affects eight
  further call sites across six files, including `build-plan-html.mjs` (the
  plan renderer) in `implementation-plan`, `build`, `finalize-plan`,
  `prototype`, `python3` heredocs in `plans-library`, and `realpath` calls in
  `plans-library` and `plans-open`. Repairing the
  renderer pipeline is a separate change with its own design call. Check 10 of
  `tests/plugins/test-extractor-wiring.sh` pins that list so it can neither grow
  nor quietly shrink.

### Changed

- `tests/plugins/test-extractor-wiring.sh` checks 5, 6, and 9 were **inverted**.
  They previously *required* the broken wiring — check 9 mandated the
  `${CLAUDE_PLUGIN_ROOT}` anchoring that makes the command unrunnable. They now
  fail if a reviewer brief or agent def documents an invocation it cannot
  execute. Check 8, added in 8.1.1 to prove reachability, runs the extractor
  straight from bash rather than through Claude Code's Bash tool, so it proved
  the *file* loads and never that the *documented invocation* is executable —
  that gap is why the suite stayed green while the feature was dead. New check
  10 ledgers the four unfixed sites.
- `tests/plugins/test-agent-frontmatter.sh` now asserts the reviewer Bash grant
  is **exactly** `Bash(git *)`. It previously rejected bare `Bash` and tolerated
  any `Bash(...)`, so `Bash(node *)` would have passed while granting arbitrary
  writes via `node -e "require('fs').writeFileSync(...)"`. It covers all ten
  `plan-reviewer-*` agents.

## 8.2.0 — `review-plan` gains product, security, and frontend reviewers (2026-08-02)

### Added

- **Three reviewers fold the `product-plans` panel's unique roles into
  `review-plan`.** The panel covered PM, security, and frontend-engineering
  lenses that no plan reviewer had; the two skills otherwise overlapped only on
  UX and accessibility. New agents:
  - `plan-reviewer-product` (core) — user problem, scope sizing, falsifiable
    success criteria, load-bearing assumptions, rollout readiness.
  - `plan-reviewer-security` (core) — authn/authz, data handling, trust
    boundaries, secrets, dependency risk. Cites CWE/OWASP identifiers, and
    reports `Exposure: none` rather than manufacturing findings on plans with no
    security surface.
  - `plan-reviewer-frontend` (UI-conditional) — component boundaries, state
    placement, render cost, design-system alignment. Runs behind the same
    `ui_signals_present` gate as UX and accessibility.
- Spawn prompts in `references/role-prompts.md` and role sections in
  `references/output-template.md` for all three.

### Changed

- The roster is now **10 reviewers — 7 core + 3 UI-conditional** (was 7: 5 + 2).
  Step 3b and Step 4 announcements report the new counts.

## 8.1.1 — the spec extractor now ships with the plugin (2026-08-02)

### Fixed

- **`scripts/extract-plan-spec.mjs` was never shipped.** The plugin bundled
  `scripts/lib/plan-spec.mjs` — the library the extractor imports — but not the
  extractor itself, so the shared lib was orphaned in the published tree and no
  installed user could run the compute-on-read spec path. The review team fell
  back to reading full plan HTML on every run, costing roughly an order of
  magnitude more tokens per reviewer per cycle than the README advertises, with
  nothing surfacing the degradation. The extractor is now vendored alongside
  `build-plan-html.mjs` and `lib/`, and is covered by the byte-identity parity
  check in `tests/plugins/test-build-plan-html.mjs`.
- **Extractor invocations were not plugin-root anchored.** All 15 live call
  sites — the 7 reviewer briefs in `review-plan/references/role-prompts.md`, the
  7 `plan-reviewer-*` agent defs, and `prototype/SKILL.md` — invoked a bare
  `node scripts/extract-plan-spec.mjs`, which resolves against the user's cwd
  and therefore only ever resolved inside this repo. They now use
  `${CLAUDE_PLUGIN_ROOT}/scripts/extract-plan-spec.mjs`, matching every other
  shipped script in the kit. Generated plans are untouched — they stay
  self-contained and reference the plan by path, as before.
- **`tests/plugins/test-extractor-wiring.sh` could not catch either defect.**
  Its 7 checks grepped for the *string* `extract-plan-spec.mjs` in plugin docs,
  proving the wiring was described but never that it was reachable, so the suite
  stayed green throughout. Two checks added: check 8 runs the plugin's own copy
  and asserts the documented misuse exit code (2), which is only reachable once
  the file exists and its `./lib/plan-spec.mjs` import has resolved inside the
  plugin tree; check 9 fails on any unanchored invocation.


## 8.1.0 — `prompt` drafts for Claude 5 generation models (2026-08-01)

### Added

- **A Claude 5 generation calibration governs every draft.** `references/best-practices-reference.md`
  gains a section 0 built from [the new rules of context engineering](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models):
  the five then→now shifts (rules→judgment, examples→interface design,
  upfront context→progressive disclosure, repetition→one source,
  simple specs→rich references) and the four practices a drafted prompt should
  stop doing. Phase 3 reads it before choosing layers — the matrix still picks
  *which* layers apply, section 0 decides how much each one earns.
- **`tests/plugins/test-prompt-calibration.sh`** (objective test, 5 checks) —
  pins the link from the core, the shift rows and obsolete list, the
  single-source rule, both templates' optional slots, and the one-hop depth.

### Fixed

- **`references/best-practices-reference.md` was orphaned.** It shipped as the
  skill's technique catalog but no file in the skill linked it, so it never
  loaded on any run. Phase 3 now links it, and it is the single authoritative
  definition of the techniques the Phase 1 matrix names.

### Changed

- **Template slots are no longer quotas.** `system`'s `<constraints>` block and
  `task`'s `<example>` and `<thinking>` blocks are documented as optional, with
  an instruction to delete the block rather than fill it with an invented
  guardrail or filler reasoning step. Every slot still ships — what changed is
  that a draft no longer has to fill them.
- **Few-shot and chain-of-thought carry calibration notes.** Examples are for
  what an output contract cannot express; reasoning scaffolds are for when the
  *shape* of the reasoning matters, not as a generic "think step by step" at a
  model that already reasons before answering.
- **Phase 4 gains a calibration pass** over the assembled draft — cut duplicated
  instructions, drop scaffolding the interview never asked for, and swap prose
  for the higher-fidelity artifact where the interview produced one. The rules
  are stated once, in section 0; `structuring-and-drafting.md` points at them.


## 8.0.0 — `write-prompt` is now `prompt` (2026-08-01)

### Changed

- **BREAKING: the `write-prompt` skill and command are renamed to `prompt`.**
  Invoke as `/plan-agent:prompt` — `/plan-agent:write-prompt` no longer resolves.
  The skill directory moves to `skills/prompt/`, the wrapper to
  `commands/prompt.md`, and `build-proposal` Step 6 now delegates with
  `Skill(skill: "plan-agent:prompt", ...)`. Nothing about the seven phases, the
  five prompt types, the `--out` contract, or `--answers-gathered` changes; only
  the name does. The command still shadows the skill of the same name, so the
  wrapper keeps reading `skills/prompt/SKILL.md` by path rather than delegating.


## 7.10.3 — the two gates stop contradicting themselves (2026-08-01)

### Fixed

- **A confident type gate no longer needs a question it is forbidden to ask.**
  Phase 1 says the type is settled with *exactly one* `AskUserQuestion`, but the
  gate's **Change the type** branch then had to ask a second one to find out
  which type. The gate now offers four options — **Looks right** plus the three
  other author-facing types — so a change settles in the same call. Four
  author-facing types means the alternatives always fit the remaining three
  slots; there is nothing to spill into a follow-up.
- **Exhausting the refine bound is now a pass, not a deadlock.** Step 1b bounds
  refinement at two rounds and then uses the human's wording verbatim, while the
  next line forbade Step 2 until the gate returned "Looks right." A third
  **Refine it** satisfied neither instruction, so the run could prompt past its
  own advertised bound or stall instead of researching. The bound is now an
  explicit successful outcome of the gate.
- **A leading `proposal` token is honoured only with `--answers-gathered`.**
  Generalising the leading-token rule to all five types in 7.10.0 opened a path
  where a human types `proposal …` by hand and settles a type whose Phase 2
  question set does not exist — the caller is supposed to supply those answers.
  Typed alone it now falls through to the clarify menu. README's two claims that
  advertised `proposal` as a user-facing token are corrected to match.
- **Control flags are stripped before the intent is read.** Phase 1 called
  "the remainder of `$ARGUMENTS`" the intent, so the caller path — which always
  passes `--out` and `--answers-gathered` — leaked its own flags into the prompt
  body and the `intent` frontmatter.
- **`Glob` added to `allowed-tools`.** `references/structuring-and-drafting.md`
  names a `Glob` fallback for resolving a template when `${CLAUDE_PLUGIN_ROOT}`
  is unset; the skill could not follow its own instruction without a permission
  prompt.
- **A failed artifact publish no longer costs the handoff.** Step 8's publish is
  optional and runs last; an error there now reports and continues to the
  handoff, since the proposal saved in Step 6 is the deliverable.
- **Step 2 says when to collect the codebase agent's result.** "Never wait on
  it" governs the dispatch; 7.8.1 left it ambiguous whether the finding was ever
  gathered. Step 3 now collects before synthesizing, and a failed dispatch is
  reported rather than silently dropped — a synthesis missing the codebase half
  reads exactly like one that covered it.

## 7.10.2 — write-prompt split into a core plus references (2026-08-01)

### Changed

- **`write-prompt` is now a 343-line core plus three new reference files**,
  completing the split 7.6.0 applied to `build`, `finalize-plan`,
  `documenting-plans`, `plan-status`, and `setup-sites`. At 434 lines it had
  become the largest SKILL.md in the plugin — every line of it paid on every
  invocation, while a single run reads at most one of the four interview
  question sets and one of the five templates.

  | Moved | To | Lines |
  |-------|----|------:|
  | Phase 2's four type-specific question sets | `references/interview-questions.md` | 36 |
  | Phase 3's seven generic XML layers, Phase 4's path resolution and writing rules | `references/structuring-and-drafting.md` | 31 |
  | Phase 7's directory precedence, `mkdir -p`, and filename derivation | `references/saving-prompts.md` | 33 |

  **What stayed is what the tests pin, and they pin per phase** —
  `tests/plugins/test-write-prompt-proposal-type.sh` slices each phase body out
  of SKILL.md so "a rule cannot pass by living in the wrong phase." That made
  the boundary decision rather than taste: the `--out` contract, the
  living-document rules (`status:`/`modified:`/`generated-sha:`, in-place
  rewrite, the body-hash command), the proposal framing line, the
  clarify-menu exclusion, and the `--answers-gathered` bypass all remain in the
  core. So does Phase 3's **proposal grounding** layer — it carries evidence
  downstream rather than shaping tone, and a pass-through rule behind a link is
  a rule that may never load.

  Verified beyond the suite with a live `task`-type run: the core loaded
  `interview-questions.md`, `structuring-and-drafting.md`,
  `task-prompt-template.md`, and `saving-prompts.md` — and none of the other
  four templates.


## 7.10.1 — trim build-proposal's always-paid body (2026-08-01)

### Changed

- **The 26-line Python directory resolver moved to
  `references/artifact-resolution.md`.** It runs once, at Step 6, and only on a
  run that writes an artifact — but a SKILL.md body is paid in full on every
  invocation, so a Tier 0 run that answers a question and writes nothing was
  still carrying it. The precedence rules themselves stay in the core, with
  every token the resolver contract depends on (`--dir`, `promptsDirectory`,
  `planAgent.proposalsDirectory`, both `${PWD}` defaults, `mkdir -p`); only the
  script moved. This follows 7.6.0's split of five other skills into cores plus
  references, and its rule that a guard behind a link is a guard that may never
  load.

- **Three blocks added earlier in the 7.7–7.9 line lost their rationale
  essays** — Step 2's fan-out, Step 1b's gate, and Step 8's artifact offer.
  Every rule, prohibition, and named failure mode survives verbatim in
  imperative form; what went was the paragraph after each one re-explaining why
  it exists. The reasoning is preserved where it belongs, in the changelog
  entries that introduced them.

  Net: 380 → 349 lines, all 15 checks in `tests/plugins/test-build-proposal.sh`
  still passing.


## 7.10.0 — write-prompt takes an explicit type, and confirms an inferred one (2026-08-01)

### Added

- **A leading type token in `$ARGUMENTS` now pins the prompt type for all five
  types.** `/plan-agent:write-prompt creative a bedtime story about a
  lighthouse keeper` classifies as `creative` without inference. The convention
  already existed but was documented as a private arrangement for exactly one
  type — `build-proposal` reaches `proposal` by passing it as the first token —
  so the other four were reachable only by hoping the classifier read your
  prose correctly. `argument-hint` now advertises it. Bare intent text still
  works unchanged and still infers.

- **Phase 1 now confirms an inferred type before Phase 2 runs.** The type
  selects the technique matrix *and* the entire type-specific question set, so
  a wrong type means the wrong interview — discovered only after the human has
  answered it. The old design announced the classification in one line on the
  way to asking those questions, which reads as settled rather than as a
  checkpoint.

  Exactly one question fires, and which one depends on confidence: the
  pre-existing four-option menu when the input does not clearly match a type,
  or a new **Looks right / Change the type** gate when it does. Both are
  skipped when the type arrived as a leading token (confirming an explicit
  choice is friction) or when `--answers-gathered` is present (the unattended
  caller path, where a question stalls a run nobody is watching).

### Changed

- **The no-`AskUserQuestion` path is now documented rather than improvised.**
  A first attempt at this gate told the skill to ask in plain text and wait.
  Two headless runs showed why that is wrong here: Phase 2's interview needs
  the same tool, so blocking strands the run with nothing to wait for. Both
  runs sensibly ignored the instruction and proceeded. The shipped rule matches
  what they did — proceed, state the classified type, and list the assumed
  Phase 2 answers as a correctable table — with the standing prohibition on
  setting `--answers-gathered` from inside the skill left intact.

  This is deliberately *not* how `build-proposal`'s Step 1b behaves. There,
  blocking is right: the next step spends subagents and web fetches, and the
  loop is interactive by nature. Here the next step is itself a question.


## 7.9.0 — build-proposal confirms the objective before researching it (2026-08-01)

### Added

- **New Step 1b gate: the restated objective goes back to the human before any
  research starts.** The framed one-liner, its domains, and the tier are
  presented and confirmed with an `AskUserQuestion` (**Looks right** / **Refine
  it**) at Tier 1 and 2. Tier 0 has already answered and skips it. Refining is
  bounded at two rounds; past that the human's latest wording is used verbatim,
  because at that point they are faster at saying it than the skill is at
  guessing it.

  Two Tier 2 runs over a 995-file repo showed why one question here is worth
  it. Given the objective "add a shared telemetry and usage-analytics layer
  across all 13 plugins so we can see which skills and commands actually fire,"
  one run restated it as that *plus* "and let that data drive keep/merge/cut
  decisions" — a downstream purpose nobody had stated — then researched against
  it. The other silently widened the domain list and declared "no clarifying
  questions needed." In both, the restatement shipped in the **same message**
  that dispatched the `Explore` agent, so there was no point at which it could
  be corrected: the full fan-out ran against an unreviewed objective.

- **Step 1 now forbids enriching the restatement.** It may compress and it may
  name the surface, but every goal, motive, and success condition must be one
  the human actually stated. A missing motive is a clarifying question, not a
  blank to fill.

  This is deliberately a separate rule from the pre-existing "if the idea is
  underspecified, ask 2–3 clarifying questions." That one gates on *input*
  vagueness and so never fired on either observed failure — the input read as
  clear and was confidently embellished anyway. The gate checks the *output* of
  framing, which catches both shapes.


## 7.8.1 — build-proposal's Step 2 fan-out actually fans out (2026-08-01)

### Fixed

- **`build-proposal` Step 2 now names the mechanism that makes research
  concurrent, not just the intent.** The old line — "Launch the first external
  fetch and the first codebase agent together in a single turn so they run
  concurrently" — stated a goal and left the how implicit. A Tier 2 run over a
  995-file repo showed what that bought: the skill dispatched `Explore` with
  `run_in_background: false`, blocked on it, ran 21 sequential inline `Bash`
  greps, and only reached its first `WebFetch` on turn 27. Fully serial, with a
  subagent bolted on — paying the delegation cost for none of the overlap.

  The replacement gives both working shapes (batch the `Agent` and the first
  fetch as separate tool calls in one message, **or** let the agent run in the
  background while external research proceeds) and forbids the one thing that
  breaks either: passing `run_in_background: false` to the codebase agent. On
  the same idea and repo, the re-run dispatched `Explore` on turn 1 as an async
  agent and reached its first `WebFetch` on turn 6, with the sweep still in
  flight.

  Wording only — no tool, argument, or step changed, and Tier 0/1 are
  unaffected (they correctly never spawn the agent at all).


## 7.8.0 — build-proposal always offers the artifact (2026-08-01)

### Added

- **`build-proposal` Step 8 now asks, every converged run, whether to publish
  the proposal as a claude.ai artifact.** The prompt file was already the
  deliverable; sharing it meant knowing the artifact tooling existed and
  remembering to run it by hand. On yes the skill loads the bundled
  `artifact-design` skill to calibrate the page, then publishes with the
  `Artifact` tool (newly added to `allowed-tools`). On no it hands off to
  `implementation-plan` exactly as before — nothing is published without an
  explicit yes, and Tier 0 never reaches the offer since it writes no artifact.

  The offer is explicitly **not** suppressed by a blanket "no more questions"
  or by `--answers-gathered`. A headless run of the loop showed the first
  wording losing to exactly that: told "I have no further questions," the skill
  reached Step 8, recognized the offer, and skipped it — reporting "per your
  no-further-questions directive I skipped the publish-as-artifact prompt."
  Those directives cover the *proposal's* decisions; publishing is the one
  action the human cannot undo by editing a file, so it keeps its own yes.

## 7.7.0 — the galleries get the row layout and one shell (2026-08-01)

### Changed

- **The plans gallery is a row list, not a card grid.** 7.5.0 gave the gallery
  the prototype's palette but kept its 2-up cards, so the shipped page still
  did not look like the design that was signed off. Each plan is now one dense
  row — status glyph, title, `type · effort`, date — laid out as a grid on the
  anchor itself. Rows are bare anchors directly inside `#galleryGrid` with no
  `<li>` and no wrapper, because the merge driver splices over everything
  between the first and last card. Status is selected off `[data-status]`
  rather than the prototype's `.s-*` classes for the same reason: the driver
  matches the class attribute with its closing quote, so a second class in
  there would make every card invisible to a merge.
- **In-flight plans show real step progress.** Each card carries
  `data-steps-done` / `data-steps-total`, counted from the `step-card` markup
  in the plan's own rendered HTML — no new spec field. The `N / M steps` text
  is server-rendered and survives with JavaScript off; the segmented bar beside
  it is drawn at load time, so the generated markup stays two attributes and a
  span instead of a dozen `<i>` tags per card. The prototype's phase line is
  deliberately absent — phases do not exist yet.
- **One sticky topbar across all four galleries.** Home, Plans, Prototypes,
  Artifacts, and Social, each with a count read off disk (the four generators
  run in arbitrary order, so parsing a sibling index would report whichever one
  was stale), and `aria-current="page"` on the tab being generated. The bar
  declares an opaque `background` before its `color-mix` value — a browser
  without `color-mix` drops the second declaration, and a transparent sticky
  bar over scrolled text is unreadable.
- **Topbar counts and hrefs follow the resolved `plansDirectory`.** Each tab
  target is `os.path.relpath(target, output_dir)` rather than a fixed prefix,
  and the plans collection is read from the configured directory rather than
  an assumed `docs/plans` — a project that moves it used to get a wrong Plans
  count and tab links that resolved from the wrong depth.
- **The prototypes gallery moved onto the shared token set** — same palette,
  dark theme, pre-paint theme script, theme toggle, and row layout. It was
  still on the pre-7.5.0 palette including `--subtle: #9ca3af`, which measures
  2.5:1 and was a live WCAG AA failure, not a cosmetic gap.
- **The artifacts gallery renders rows without a glyph column.** Its cards
  carry `data-status=""`, and the stylesheet collapses the first column for
  those rather than rendering an empty one.

### Fixed

- **Every plans-index generator now reads `.claude/settings.local.json` first.**
  The resolvers checked project then global settings only, so a developer who
  pointed `plansDirectory` somewhere else in their local settings had the
  gallery written to, and counted from, a directory they were not using.
  `render-plan-html.py` and `check-prototype-drift.py` already used local →
  project → global; the index builders now match.
- **Every page's Plans tab counts plans the way the plans gallery does.** The
  artifacts and prototypes generators counted the plans directory with a flat
  `listdir` while the gallery itself walks subdirectories and skips `archive/`
  and `artifacts/`, so one nested plan made those two pages advertise a lower
  Plans total than the Plans page showed — two numbers for one collection reads
  as data loss.
- **The template-less fallback stylesheet matches the markup it emits.** When
  the plan-agent templates cannot be resolved, `build-index.sh` writes a bare
  page from an inline stylesheet — which still styled the card classes the row
  layout replaced. Without a `.sr-only` clip rule, every row's visually-hidden
  status text rendered as loose words beside its glyph.
- **Prototype titles no longer double-escape.** `get_title` returned the raw
  `<title>` text and the card escaped it again, so a prototype named
  `Tabs &amp; panels` rendered as `Tabs &amp;amp; panels` while its
  `data-title` held the unescaped form — the visible row and the search filter
  disagreed.
- **`.save-pdf-btn` no longer overrides its own font.** The rule set
  `font-family: var(--mono)` and then `font-family: inherit` six lines later,
  so the button rendered in the UI font while its twin, the theme toggle,
  rendered in mono. Takes effect for each plan on its next render.

### Removed

- **The grid/list view toggle.** It predates the redesign, appears in neither
  the prototype nor the plan, and was a second layout to style and keep
  accessible for a preference nobody asked for.

### Accessibility

- Each row's status glyph is `aria-hidden` with a visually-hidden text sibling,
  so a row announces `completed` / `in progress` / `todo` before its title. An
  `aria-label` on the anchor was rejected: it would override the row's own text
  and make the announced content diverge from the visible content.
- Every text token in the gallery stylesheets was measured against its own
  background in both themes; all clear 4.5:1. Two changes came out of that —
  the queued glyph dropped the prototype's `.5` opacity, and the current tab's
  count takes the accent colour (`--ink-3` on `--accent-soft` measured 4.46:1).
- The status segmented control wraps below 700px; its fourth button used to be
  clipped at 375px.

### Testing

- `tests/plugins/test-gallery-row-layout.mjs` — builds an index over a fixture
  plans directory and asserts the row markup, the step-count derivation
  (including that `step-card-header` is not counted), the announced status, the
  topbar, and every constraint the merge driver depends on, using `CARD_RE` and
  `COUNT_RE` read out of the driver's own source.
- `tests/plugins/test-build-index-parity.mjs` — asserts the three byte-identical
  `build-index.sh` copies still hash the same. They were kept in sync by
  convention with nothing enforcing it.

## 7.6.0 — five skills split into cores plus references (2026-08-01)

### Changed

- **`build`, `finalize-plan`, `documenting-plans`, `plan-status`, and
  `setup-sites` are now a small core plus `references/*.md`.** A SKILL.md body
  is paid in **full** every time the skill fires — there is no partial load —
  and an ordinary run reads maybe a quarter of it. `build`'s Step 1b was ~60
  lines of delegation contract charged to every invocation that named a plan
  and read by none of them. The mechanics moved behind links the core names;
  the trigger, the arguments, and every step heading stayed.

  | Skill | Before | After | Reference files |
  |-------|-------:|------:|----------------:|
  | `build` | 3,254 | 590 | 4 |
  | `finalize-plan` | 3,239 | 460 | 4 |
  | `documenting-plans` | 1,897 | 447 | 3 |
  | `plan-status` | 1,681 | 457 | 3 |
  | `setup-sites` | 1,498 | 461 | 3 |
  | **Total** | **11,569** | **2,415** | **17** |

  Section text moved verbatim, so no rule was reworded on the way out: every
  non-blank line of all five originals is still present in its skill
  directory. All seven guard phrases `keep-phrases.txt` pins to `build`
  stayed in the **core** — a guard behind a link is a guard that may never
  load. `build`'s re-render subroutine also stayed in the core, deliberately:
  every step calls it, so pulling it out would trade one always-paid block for
  five on-demand fetches of the same four lines.

### Removed

- The hand-maintained `## Table of Contents` in `documenting-plans` and
  `plan-status`. The linked step list in each core says the same thing once.

### Added

- **`tests/plugins/test-progressive-disclosure.sh`** — asserts each of the five
  cores is under 600 words, ships a `references/` dir, names no reference that
  does not exist, and leaves no reference on disk unnamed. Both link
  directions, because either one alone passes a split that is broken in the
  other. Wired into `check-plugin-versions.yml`.

### Fixed

- `test-build-skill.sh`, `test-finalize-all-flag.sh`, `test-setup-sites.sh`,
  `test-plan-ticket-closure.sh`, and `test-proposal-prompt-pipeline.sh` now
  resolve each pinned literal from whichever file in the skill directory
  carries it. Only the lookup changed — no assertion was deleted, weakened, or
  reworded, and `build` still has all 18 checks.


## 7.5.0 — rebuilt plan document and gallery design (2026-07-31)

### Added

- **A dark theme, with a toggle that survives a reload.** A small script in
  `<head>` applies the stored choice before first paint — a plan opened from
  `file://` has no server to stamp the attribute, and a flash of the wrong
  theme on every load is worse than no dark mode. A first visit with nothing
  stored follows `prefers-color-scheme`. The button is hidden by the print
  stylesheet.
- **A step rail in the sidebar.** `nav()` now emits one link per step
  alongside the section links, each carrying the step's action text and a
  visually-hidden `step N of M[, done]`. Every `.step-card` gained
  `id="step-N"` to link to. Below 720px the list collapses into a 44px
  disclosure rather than disappearing. The section anchors keep a bare `href`
  and nothing else, so nothing that reads them had to change.
- **Gallery grouping.** The generated indexes sort in-progress plans first and
  stamp each card with `data-month`; the gallery script builds the "In flight"
  band and the month headings at load time and rebuilds them on every filter
  change. Nothing is emitted between the cards, so `merge-plans-index.mjs`
  still splices the card region untouched.
- **`tests/plugins/test-plan-redesign.mjs`** — measures the contrast of every
  text token against every surface it renders on, in both palettes, plus the
  goal panel, the Verify line, the rail, and the gallery grouping.

### Changed

- **A new token set: `--paper` / `--panel` / `--sunk`, `--ink` / `--ink-2` /
  `--ink-3`, `--rule` / `--rule-soft`, `--accent` / `--accent-soft` /
  `--accent-line`, `--moss`, `--signal`, and the `--mono` / `--ui` / `--prose`
  type roles.** Structural labels speak in mono, body prose in serif. Status
  is carried by form (soft fill plus a rule) rather than white text on a solid
  hue, so one palette drives both themes.
- **One goal panel.** The At-a-glance block renders inside `#objective`
  instead of beside it — two sibling abstracts left a reader unable to tell
  which was authoritative. `extractSections()` already stripped a nested
  `.plan-glance`, so the extractor contract is unchanged.
- **`Verify:` is always visible.** It was behind a `<details>`; it is the one
  line a reader needs *while* executing a step. Still inside
  `<div class="verify-body">`.
- **The gallery controls.** Twenty always-on filter chips became a search
  field, a status segmented control carrying per-status counts, and a
  disclosure holding type and effort. A gallery whose cards carry no status
  (the artifacts library) hides the status control entirely.

### Fixed

- **`--subtle: #9ca3af` measured 2.5:1 on white** and styled the sidebar links
  and step chips, so every generated plan failed WCAG AA. Every text token now
  clears 4.5:1 against each surface it is used on, in both palettes, and a
  test measures it.
- **The scroll spy never cleared its active link.** The observer only reacted
  to intersecting entries, so the last match stayed highlighted forever. With
  one link per step a stale "you are here" marker is worse than none, so it
  now tracks what leaves the viewport too and clears when nothing intersects.
- **The progress bar no longer shimmers.** An animation running while nothing
  is happening reads as activity the page cannot vouch for.
- **The back-compat guard in `tests/plugins/test-build-plan-html.mjs`** compared
  whole rendered documents, so it failed on every deliberate markup change —
  making an intentional redesign indistinguishable from a regression. It now
  compares `extractSections()` output, which is what its own comment always
  said it protected, plus explicit assertions that the prototype feature does
  not leak into a spec without the key.


## 7.4.4 — out-of-scope items no longer vanish from rendered plans (2026-07-31)

### Fixed

- **The follow-ups heading is matched case-insensitively and accepts
  `## Out of Scope`.** `parseSpecMarkdown()` tested headings against
  `/^Next Steps\b/`, so `## Next steps` and `## Out of Scope` — the heading
  authors most often reach for — fell through to the unknown-heading path and
  were discarded with no warning and a clean exit 0. The plan rendered without
  its Next Steps cards and nothing said why.
- **Next Steps survives the HTML → spec round trip.** `extractSections()`
  returned no follow-up data and `buildDigest()` had no parameter to emit it,
  so any plan recovered from its HTML (no `.md` sibling) lost its follow-ups
  permanently — the next render dropped the cards. Adds `extractNextSteps()`,
  the read-side twin of plan-shell's `nextStepsBlock()`, and an optional
  second `buildDigest(sections, nextSteps)` argument; `extract-plan-spec.mjs`
  and `backfill-plan-digests.mjs` pass it.
- **A prompt containing its own code fence is no longer truncated.** Fence
  tracking was an open/closed toggle, so a `` ```yaml `` block inside a
  paste-ready prompt ended the prompt early and leaked its tail into the card
  description — and an odd number of nested fences could swallow every heading
  after the section. Fence runs now follow CommonMark: a run closes only on
  the same character at greater-or-equal length, so a prompt quoting fenced
  code needs a longer outer fence (` ````text `). `buildDigest()` sizes the
  fence it emits to outrun anything inside the prompt.
- **Angle-bracket placeholders in a prompt are no longer eaten.**
  `extractNextSteps()` ran the `<pre>` contents through a `<[^>]+>` tag strip,
  which deleted the `<owner>`/`<repo>`-style placeholders a paste-ready prompt
  depends on. The renderer escapes prompts, so a renderer-built card holds no
  markup there and the strip only ever destroyed real text. Removing it also
  clears a CodeQL incomplete-multi-character-sanitization alert.
- **A legacy embedded digest no longer masks DOM-visible follow-ups.**
  `resolveSpec()` returns an embedded `#plan-digest` block before ever looking
  at the DOM; 49 committed plans carry a digest backfilled before Next Steps
  round-tripping existed, so their frozen digest lacks the section even though
  the visible page still renders the cards. Extraction (and therefore a
  re-render sourced from it) silently dropped every one. `resolveSpec()` now
  detects a digest with no Next Steps heading and splices in the DOM-recovered
  follow-ups via the new shared `nextStepsMarkdown()` helper.
- **A wish-list card is no longer dropped by an exact-string class match.**
  `extractNextSteps()` matched the literal marker `class="next-step-item"`,
  which requires the closing quote immediately after the class name — missing
  every `class="next-step-item wish-item"` card the legacy renderer's
  `.wish-item` styling produces (67 occurrences across the committed corpus).
  Card matching now uses the same `class="next-step-item[" ]` token pattern
  the step-card matcher already relies on for the identical `step-card` /
  `step-card completed` distinction.
## 7.4.1 — harden the ticket link and the summary handoff (2026-07-31)

### Fixed

- **The `Tracking issue` fallback label never fired.** A ticket URL with no
  trailing number produced `Issue` rather than the documented fallback, because
  the label was built by trimming a trailing `#` off `Issue #` — leaving a
  truthy string that shadowed the template's `|| 'Tracking issue'`. The label
  is now chosen explicitly, and the test pins the exact string instead of
  asserting it is merely non-empty (which is what let this ship).
- **A non-`http(s)` `issue:` value rendered as a clickable anchor.** Escaping
  leaves a scheme intact, so an imported or hand-edited plan carrying
  `issue: javascript:...` produced an ordinary-looking tracking link that ran
  on click. Both the meta tag and the anchor are now emitted only for `http`
  and `https` values; anything else is dropped with a one-line warning.
- **The ticket summary was interpolated into a shell string.** Completion
  Report bullets routinely contain backticks naming a file or function, and
  `` `x` ``, `$(x)`, and `$VAR` all expand before `gh`/`glab` sees them —
  corrupting the comment in the ordinary case, and executing plan-supplied text
  in the worst one. Both skills now write the summary to a file and pass
  `--body-file` (GitHub) or `-m "$(cat <file>)"` (GitLab).
- **`finalize-plan --all` ran the ticket step twice.** The sweep loop said to
  run Step 5 with all sub-steps — which now includes Step 5f — and then to run
  Step 5f again for the batch, prompting per plan and acting twice on the same
  tickets. Step 5f is now explicitly excluded from the loop.
- **`finalize-plan` asked "Close it?" before knowing the final status.** The
  question sat above the status branch, so a plan that landed `in-progress`
  was still asked about closing and then never closed. Step 5f now determines
  the status first and only asks in the `completed` branch.
- **The ticket URL reached the CLI unvalidated and unquoted.** It is
  frontmatter, like the summary. Both skills now require `https://` and a
  `github.com`/GitLab host before invoking anything, quote the URL, and skip
  with a one-line report otherwise — previously any non-GitHub URL was assumed
  to be GitLab, firing `glab` at hosts it cannot serve. Any tracker may still
  be *linked*; only these two can be *closed*.


## 7.4.0 — completing a plan updates its linked ticket (2026-07-31)

### Added

- **`build` and `finalize-plan` now act on the plan's `issue:` link when they
  write the completion state.** A plan that lands `completed` offers to close
  the ticket (`gh issue close` / `glab issue close`) with a summary comment —
  filename, final status, `N/M` criteria checked, and every Completion Report
  bullet verbatim. Closure is always behind an explicit `AskUserQuestion`,
  since it is visible to everyone watching the ticket; `finalize-plan --all`
  asks once for the whole sweep. A plan that lands `in-progress` via the
  downgrade rule is never closed — the same summary is posted as a comment so
  the ticket shows where the work stopped. A missing CLI, failed auth, or
  failed command is reported in one line and the plan still completes.
  Covered by `tests/plugins/test-plan-ticket-closure.sh`, which asserts the
  rule in both skills — landing it in only one is the real failure mode.


## 7.3.0 — tracking issue asked first and rendered onto the plan (2026-07-31)

### Added

- **A spec's `issue:` key now renders.** The renderer emits a `plan-issue` meta
  tag and a header anchor to the ticket (labelled `Issue #<n>` when the URL ends
  in a number, `Tracking issue` otherwise). Applies to both paths that set the
  key: a plan seeded from an issue (Step 0.5) and a tracking issue created at
  Step 8. Previously the URL sat in the spec frontmatter and never reached the
  HTML, so a finished plan gave no hint which ticket to close. Plans without an
  `issue:` key render byte-identically to before. Covered by
  `tests/plugins/test-plan-issue-link.mjs`.

### Changed

- **`implementation-plan` Step 8 now orders the batched `AskUserQuestion` with
  the tracking-issue question first and the next-step (`Implement now` /
  `Run as workflow` / `Review` / `Exit`) question second.** The issue is already
  created before the next-step choice is acted on, so asking about it first
  matches the order things actually happen. No change to the options, the
  skip-when-`issue:`-is-set rule, or the handling of either answer.


## 7.2.0 — process-reminder imperatives pruned behind recorded baselines (2026-07-30)

### Changed

- **`build` and `implementation-plan` shed process scaffolding a Claude 5
  generation model infers from the surrounding step.** Removed: `build`'s Step 3
  aside "Spec edits only (see the source-of-truth rule above)", now that the
  `## Overview` source-of-truth paragraph carries it; `implementation-plan`'s
  "Follow these steps exactly."; and Step 4 `Rename`'s restatement of the
  kebab-case `verb-target` convention already given in Step 2's write
  instruction. The rename triggers, the "stale filename is a plan defect" rule,
  and the `validate-plan-filename` hook reference all stay.
- Every safety, scope, and irreversibility guard was kept — including
  `## Scope Constraint — Plans Only` in full, "This constraint is never lifted
  here", and "Never resolve a gate by picking for the user".

### Testing

- **Behavior baselines were recorded, committed, and independently reproduced
  *before* a single imperative was removed** (`ed6b854`). Both skills were run
  headless against fixed scenario inputs and reduced to structural manifests —
  files written, gates fired, refusals emitted, never prose wording. `build`
  walks its spec, promotes `status:` to `completed`, and creates only the file
  its plan names; `implementation-plan` writes a plan and leaves the source file
  its objective names byte-identical, with zero writes outside the plans dir.
  Both reproduced their manifests exactly after the prune.
- New gates: `tests/plugins/test-imperative-pruning.sh` (CI-wired, structural)
  and `tests/plugins/test-skill-behavior-baselines.sh` (local-only, exits 1
  rather than skipping when the `claude` CLI is absent).

## 7.1.0 — the auto workflow heuristic opts in at 4 files across 2 directories (2026-07-30)

### Changed

- `workflow: auto` now fires at **4+ files across 2+ top-level directories**,
  down from 5+ across 3+. The threshold gates two things at once — the
  workflow row and the goal prompt's `Fan out across parallel subagents where
  that serves the outcome.` license — so loosening it widens both together and
  keeps the page coherent: a plan is never told to parallelize on a page that
  offers no workflow row.
- Chosen over making the fan-out license unconditional. 19 of the 25 rendered
  plans carrying a goal row already qualified under the old threshold, so
  dropping the gate would have added the license only to the six smallest
  plans — exactly where spinning up subagents is worst value — while
  collapsing `GOAL_LABEL`/`GOAL_LABEL_PARALLEL` into one string that no longer
  distinguishes anything.
- `workflow: always` / `never` are unaffected, and remain the way to opt a
  plan in or out against the heuristic.
- A boundary test pins both halves of the condition: 4 files across 2 dirs
  opts in, while 3-across-2 and 4-in-1 stay out.

### Fixed

- Root-level files no longer each count as their own directory. `dirCount`
  derived the directory with `path.split('/')[0]`, which returns the whole
  filename for a bare path like `README.md`, so a plan touching only
  `README.md`, `package.json`, `LICENSE`, and `Makefile` scored four
  directories and satisfied the directory half of the heuristic on its own.
  Bare paths now bucket under one root sentinel. Pre-existing, but the 4-file
  threshold lowered the bar to trip it from five root files to four.
- The plugin README, the `document-implementation-plan-skill` guide, and the
  `implementation-plan-reference` artifact each described repetitive per-file
  changes, parallelizable steps, and adversarial review needs as *automatic*
  workflow triggers. Only the file/directory count is automatic; the rest need
  `--workflow` or `workflow: always`. All three now say so, and all three
  carried the stale 5-across-3 number.

## 7.0.1 — inline Markdown in plan prose renders as markup, not raw characters (2026-07-30)

### Fixed

- Plan prose now renders `` `code` ``, `**bold**`, and `*italic*` as real
  markup. Every prose field went through `esc()` alone, so the markers reached
  the page as literal characters — 85 of the 95 plans in `docs/plans/` showed
  3,000+ code spans as raw markdown, which is what made rendered plans read
  like unstyled source.
- `inline()` (renderer) and `remark()` (extractor) are a matched pair: spans
  are tagged `class="md"` so the extractor turns exactly those back into
  markers, leaving the bare `<code>` that carries file paths and the
  copyable implement/goal/workflow prompts untouched. The round-trip contract
  is unchanged, and the 83-plan corpus test proves it.
- Code spans are lifted out before bold/italic run, so a doubled-star glob
  inside backticks stays a path.
- Italic uses flanking rules, not a character blacklist: the opening star must
  follow whitespace or an opening bracket, the closing star must precede
  whitespace or sentence punctuation, and the span may not begin or end with
  whitespace or contain a slash. Without this, a star attached to a word
  (`product-reviewer-*.md`) paired with the star of the next glob and swallowed
  everything between them into one `<em>` — 569 characters in the worst
  committed plan. The round-trip test could not see it, because `remark()`
  faithfully restores both stars and only the rendered page was wrong.
- Source NULs are stripped before the code-span placeholder is inserted. The
  placeholder is NUL-delimited and UTF-8 can encode NUL, so prose carrying one
  could otherwise impersonate a placeholder and render as
  `<code class="md">undefined</code>`.

### Notes

- Committed plan HTML converges on the next render; no migration is needed,
  and no committed plan changed in this release.
- The back-compat guard now pins markup rather than bytes — presentation CSS
  is expected to evolve, and pinning stylesheet bytes would forbid every
  future visual fix.
- Not handled: fenced blocks, links, and lists inside prose. No plan uses
  them there, and each would need its own inverse in the extractor.

## 7.0.0 — enumerated frontmatter is validated, and the goal prompt licenses fan-out (2026-07-29)

Applies two rules from Anthropic's "The new rules of context engineering for
Claude 5 generation models" to the renderer: design the interface rather than
absorb bad input (Rule 2), and stop saying the same thing in two layers
(Rule 4). Also folds in the goal-prompt fan-out license that was staged as
6.1.0 — that version is rolled up here and never shipped on its own.

### Breaking

- **Unrecognized values for `status`, `type`, `effort`, and `workflow` now
  fail the render.** They used to fall back silently, so a near-miss rendered
  as something the author did not write: `status: complete` rendered as
  `todo`, `workflow: yes` meant "no workflow", and `type:` accepted any string
  at all and carried it into the gallery as a filter chip. The renderer now
  exits 1 naming the key and the accepted set. Two specs in this repo were
  already off-enum (`type: standard`, `type: enhancement`) and are corrected
  to `feature`. A consumer with off-enum frontmatter must fix it before their
  plans will render — hence the major bump, even though every rejected value
  was already producing a wrong plan.
- **A present-but-empty value is rejected too.** Only an absent key takes the
  default. `status:` with nothing after it is a half-finished edit or an
  unfilled template — the mistake most worth catching, and the one case where
  falling back would have quietly reintroduced the behaviour this change
  removes.
- **Inline YAML comments on the enumerated keys are stripped before
  validation.** The frontmatter parser keeps everything after the colon, so
  `status: todo  # todo | in-progress | completed` put the comment inside the
  value. Harmless while these keys fell back; a hard error once they went
  strict — and every enum line in the authoring docs is written that way.
  Enum values are single tokens, so the comment is stripped rather than
  hand-authored YAML being made illegal.
- **`workflow` gains `auto`/`always`/`never`.** `auto` names the heuristic —
  previously the unnamed state you got by omitting the key, which is what made
  `workflow: yes` degrade without a diagnostic. `true`/`false` remain accepted
  as the pre-7.0 spelling of `always`/`never`, so committed specs keep
  rendering unchanged.

### Changed

- **The verification gate's *check* clause is compressed; its *record* clause
  is not.** Naming the plan's Tests, Verification, and Acceptance Criteria
  replaces three sentences spelling out how to walk each one. The completion
  mechanics — `[x]` step markers, `- [x]` criteria, `status: completed`, and
  the re-render — stay explicit.

  An earlier cut of this release removed the record clause too, on the theory
  that the tick syntax was already visible in the spec and the re-render was
  the harness's job. Both were wrong. An unfinished spec carries bare numbered
  steps and bullets, so there is no `[x]` to copy, and the rendered progress
  bar and step chips derive from exactly those markers. And while `hooks.json`
  does register `render-plan-html.py` on PostToolUse writes, that registration
  is not honoured everywhere: in the Claude Code desktop app plugin `hooks.json`
  files are never wired up, so editing a plan spec there leaves the sibling HTML
  stale. The instruction is not redundant in practice. It matters most on the
  goal and workflow paths: only `copyCmd()` rebuilds a richer prompt from live
  DOM, while `copyGoal()` and `copyWorkflow()` copy this tail verbatim.
- **The goal prompt now licenses parallel subagents on plans that get a
  workflow row.** "Pursue as goal" produced `Achieve this goal: …` on every
  plan — a purely sequential instruction. The only prompt that requested
  parallelism was the sibling workflow row, so choosing outcome latitude meant
  giving up fan-out even on plans that clearly warranted it. On plans where the
  workflow row is emitted, the goal prompt now appends `Fan out across parallel
  subagents where that serves the outcome.` and its label reads "Pursue as goal
  — optimize for the outcome, in parallel".
- **The license trails the latitude; it does not lead the prompt.** An earlier
  cut of this change opened the prompt with `Run a workflow to achieve this
  goal:`. That inverted what a goal prompt is for: fan-out needs a fixed
  decomposition, while "the plan is only reference, optimize for the outcome"
  licenses rewriting that decomposition — so a leading directive forced the
  agent to commit to a work-list before it was allowed to judge the work-list
  wrong, and in practice the latitude became dead text. It also made the goal
  and workflow prompts open with four identical words, collapsing the visible
  difference between the drawer's two rows. Stating fan-out after the latitude
  keeps the prompt a goal and makes parallelism a choice the outcome licenses.
- **Prompt and label share one gate.** The fan-out sentence keys off the same
  `wantsWorkflow` check that emits the workflow row (`workflow: true`, or 5+
  files across 3+ top-level directories; `workflow: false` suppresses both).
  A plan too small to show a workflow row gets no fan-out license — the page
  can no longer offer orchestration it doesn't show. In `moreWaysDrawer` the
  label tracks the non-empty `workflow` argument rather than taking a
  parameter of its own, so the two cannot drift.

## 6.0.3 — the `Skill`-tool ban in the two wrappers now forbids only the self-named call (2026-07-29)

### Fixed

- **`/documenting-plans` contradicted itself.** Its note said "do **not** reach
  for the `Skill` tool here" without qualification, while its frontmatter
  declared `Skill` and the skill it runs inline asks for
  `plan-agent:plan-status` via that tool whenever a plan's status is not already
  `completed`. 6.0.2 confirmed that dependency — "keeps `Skill` because its body
  genuinely invokes `plan-agent:plan-status` through it" — but left the prose
  ban standing. The blanket ban invited the model to skip the status branch
  rather than error: a silent gap, not a crash. The note now forbids only the
  self-named call and names `plan-agent:plan-status` as permitted.
- **`/deep-grill` got the same rewording** for consistency. It was never a
  defect there — that command declares no `Skill` tool and its skill calls none.

## 6.0.2 — Convert `plan-status` and `markdown-to-html`, closing 6.0.1's gaps (2026-07-29)

### Fixed

- **`plan-status` converted to the same by-path shape as `deep-grill` and
  `documenting-plans` in 6.0.1.** It carried the identical shadowed
  `Skill(skill: "plan-agent:plan-status")` self-delegation and was tracked
  separately in that release rather than fixed. It now `Read`s
  `${CLAUDE_PLUGIN_ROOT}/skills/plan-status/SKILL.md` by path, with the same
  `Glob` fallback and inline shadowing note, worded to match its two siblings.
  Its stale `argument-hint` (advertising only `[plan-file-path]` while the
  skill accepts a directory, `--all`, and `--force`) is corrected in the same
  pass.

  **This closes 6.0.1's "Known limitation."** `documenting-plans` Step 2 asks
  for `plan-agent:plan-status` through the `Skill` tool, which the unconverted
  command shadowed — the call returned the wrapper's own stub rather than the
  skill. Now that the wrapper's own text redirects to a path `Read`, any
  caller reaching it through `Skill()` — a user, another skill, a background
  agent — follows that redirect and lands on the real workflow. Fixing the
  wrapper fixed every caller of it at once.

- **`markdown-to-html` was never touched in 6.0.1** and carried the same
  self-delegating `Skill(skill: "plan-agent:markdown-to-html")` shape as the
  other three. It now `Read`s its skill file by path; `allowed-tools` drops
  `Skill` (see Changed below) and keeps `Agent`, which the `--async` dispatch
  already used.

- **`markdown-to-html`'s `--async` dispatch had two independent bugs**, not
  one: it handed its background subagent the same shadowed `Skill()` call, and
  separately told that subagent to resume the workflow partway through, at
  Step 4. Both are fixed — the subagent now `Read`s the skill file and starts
  at Step 1. Starting late skipped Step 2, the only step that parses the
  source's frontmatter, sections, and steps content, so a fresh subagent
  (which shares none of the parent run's state) would have reached HTML
  synthesis with nothing parsed to render. Caught in review against the first
  draft of this fix, which corrected the shadowing but not the truncation.

### Changed

- **`allowed-tools` on both wrappers now mirrors the skill each one loads**,
  matching 6.0.1's rule for the other two. `documenting-plans` keeps `Skill`
  because its body genuinely invokes `plan-agent:plan-status` through it;
  `markdown-to-html` does **not** get `Skill` — its skill's only mention of the
  tool is inside the warning against calling it, never an actual invocation.

- **`tests/plugins/test-command-delegation.sh`**: `plan-status` moves from the
  `UNCONVERTED` list into `DELEGATORS` (bumping `MAX_LINES` to 16 to fit its
  longer `argument-hint`), gaining the same by-path, no-self-call, and
  allowed-tools-coverage checks as its two siblings. The allowed-tools
  extractor now handles a value wrapped onto its own indented line (the form
  `write-prompt.md` and `plan-status.md` both use), which a single-line-only
  regex would have silently skipped. Two new checks cover `markdown-to-html`
  specifically, since its real usage docs keep it out of `DELEGATORS`: the
  `--async` subagent prompt must say "Step 1" and must not say "Step 4" or
  hand over a `Skill()` call, and the command's `allowed-tools` must not grant
  `Skill` when the skill never uses it. All new assertions were verified to
  fail against the bugs they guard before passing on the fix.
## 6.0.1 — `/deep-grill` and `/documenting-plans` actually load their skills (2026-07-29)

### Fixed

- **Both commands were silent no-ops.** Each delegated with
  `Skill(skill: "plan-agent:<its-own-name>")`, but a command shadows a skill of
  the same name in the `Skill` namespace — the call returned the command file
  instead of `skills/<name>/SKILL.md`, so the skill body never entered context
  and the workflow ran on nothing. Measured with a headless probe
  (`claude -p --plugin-dir kit/plugins/plan-agent`): the `Skill()` form put **0**
  of `deep-grill`'s 3 `## ` headings and **0** of `documenting-plans`' 10 in
  context; reading `SKILL.md` by path put all 10 there.
- **Both now read `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` by path**, with
  a `Glob` fallback and an inline note explaining the shadowing so the next
  editor does not reintroduce the `Skill()` call. Each wrapper stays at 15 lines.
- **`allowed-tools` widened to match the skill each now runs inline** — each
  command now mirrors its skill's declared set exactly: `deep-grill` takes
  `Read, Glob, Grep, AskUserQuestion, TodoWrite`; `documenting-plans` takes
  `Read, Glob, Grep, Bash(git *), AskUserQuestion, Write, Edit, TodoWrite,
  Skill`. Under the old `allowed-tools: Skill` the skill's own tools would have
  been unreachable from the command.
- **`tests/plugins/test-command-delegation.sh` now enforces the by-path shape** —
  it requires each converted delegator to name `skills/<name>/SKILL.md`, rejects
  a self-named `Skill()` call, and requires the command's `allowed-tools` to
  cover every tool its skill declares. All three assertions were verified to
  fail against the code they guard. `plan-status` still uses the shadowed form
  and is tracked separately; it keeps the thin-delegator line and frontmatter
  guards in the meantime.

### Known limitation

- **`documenting-plans` Step 2 still bottoms out in the `plan-status`
  shadowing.** When a plan's frontmatter is not already `status: completed`, the
  skill asks for `plan-agent:plan-status` through the `Skill` tool — which
  `commands/plan-status.md` shadows, so the call returns that wrapper rather
  than the skill. Restoring `Skill` to the command's `allowed-tools` makes the
  branch *reachable*; it is fully fixed only when `plan-status` gets the same
  by-path treatment. Plans already marked `completed`, the documented input for
  this skill, never enter that branch.
- **Closes the follow-up 6.0.0 left open** — its `commands/write-prompt.md` entry
  noted that the same shadowing applied to these two commands and that they were
  not touched there. They are now, in the same by-path shape. One wording
  difference is deliberate: `write-prompt.md` spells the forbidden call out
  literally, while these two name the skill without the call syntax, because the
  delegation test greps for that literal string. Adding `write-prompt.md` to the
  test's `DELEGATORS` map would require rewording its note first.

## 6.0.0 — `build-proposal` converges on a saved prompt (2026-07-28)

### Breaking

- **The proposal deliverable is now a saved prompt.** `build-proposal` converges
  on `<prompts-dir>/proposal-<slug>.md`, authored by delegating to
  `write-prompt`, instead of hand-writing a proposal document. The legacy
  `<proposals-dir>/<slug>.md` copy is still written for this release, carrying a
  banner naming the prompt as authoritative; it is **removed in a future minor
  release**. (Originally slated for 6.1.0, a version that was folded into 7.0.0
  and never shipped.)
- **`--dir` now names the prompts directory**, not the proposals directory — the
  flag follows the authoritative artifact. The prompts directory resolves
  `--dir` → `promptsDirectory` → `${PWD}/docs/prompts/`, the same key
  `write-prompt` and `artifact-tools:prompt-artifact` read. The deprecated
  proposals root still resolves from `planAgent.proposalsDirectory`, but never
  from `--dir`.
- **`build`'s Step 1b chains a prompt path.** The proposal stage's reported
  artifact, the dirty-tree exclusion, and the abandonment contract all name the
  saved prompt; abandonment leaves both artifacts in place.

### Added

- **`commands/write-prompt.md`** — a 16-line wrapper that loads the skill body by
  path. `write-prompt` carries `disable-model-invocation: true`, which blocks
  *programmatic* `Skill()` invocation and not merely ambient activation, so the
  skill was uncallable by anything; the flag stays on, and the wrapper puts the
  name in the registry. **It does not delegate with
  `Skill(skill: "plan-agent:write-prompt")`** — the shape `commands/deep-grill.md`
  uses. The command *shadows* the skill of that name, so that call returns the
  wrapper itself and the seven phases never load. Measured: delegating that way
  put 0 `## Phase` headings in context; reading
  `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/SKILL.md` by path puts all 7 there.
  The wrapper carries the reason inline so the next author does not "fix" it back
  into a loop.

  > The same shadowing applies to `commands/deep-grill.md` and
  > `commands/documenting-plans.md`, which were not touched here.
- **A fifth `proposal` prompt type in `write-prompt`**, wired through Phases 1,
  2, 3, 4, and 7, with `references/proposal-prompt-template.md` carrying 11
  proposal-shaped slots. The proposal's *Next step* section maps onto the
  prompt's core instruction — the structural reason the two shapes fit. The type
  is never offered in the clarify menu; it is reached only when a caller names
  it.
- **A caller-supplied `--out <path>` contract.** When present it overrides Phase
  7's directory resolution *and* its 3–5 word intent-slug derivation entirely.
  Without it, `build-proposal` (verb-target slug, its own `--dir`) and
  `write-prompt` (intent slug, its own `promptsDirectory`) resolve **different**
  paths, so the handoff and the deprecation banner would name a file that was
  never written. `Skill()` has no documented return value, so the caller cannot
  read the path back — it dictates it instead.
- **A `--answers-gathered` bypass** for Phase 2. `build-proposal` resolves every
  decision with the human in its own Step 5; without the bypass `write-prompt`
  would interview them again for answers the caller is already holding.
- **Living-document frontmatter** on proposal prompts: `status:`
  (`gathering` | `converged`), `modified:`, and `generated-sha:`. Round two
  rewrites the same file **in place** rather than minting a `-2` variant, and
  asks first when the body's hash no longer matches `generated-sha:` — a hand
  edit. The check is anchored to the recorded hash rather than to git precisely
  because `build-proposal` only *offers* to commit each round, so an uncommitted
  previous round would otherwise be indistinguishable from a hand edit.
- **The filename omits the date for this type** — `proposal-<slug>.md`. A dated
  name would resolve differently the moment a loop crossed midnight, forking the
  living document in two. The slug is the identity; `created:` and `modified:`
  carry the dates.
- **A section-to-slot mapping table** in
  `build-proposal/references/artifact-shape.md`, mapping all 13 canonical
  proposal sections onto the template's slots.
- **`tests/plugins/test-proposal-prompt-pipeline.sh`** (objective test, 10
  checks) and **`tests/plugins/test-write-prompt-proposal-type.sh`** (unit, 10
  checks — including one that *executes* the documented drift-detection command
  and proves it discriminates a body edit from a `modified:` bump).

### Fixed

- **`artifact-shape.md` no longer teaches the conversion-mode trap.** Its line
  102 advertised `/plan-agent:implementation-plan docs/proposals/<slug>.md` — the
  bare-`.md` handoff `SKILL.md` forbids, which drops `implementation-plan` into
  conversion mode and yields a plan whose steps restate proposal headings. The
  test check that guards this now scans the whole skill directory rather than
  `SKILL.md` alone, which is why it went unnoticed.

### Preserved

- **Tier 0 still writes no artifact of either kind**, so `build`'s "No proposal
  written" fall-through keeps firing. **Tier 1** emits a prompt from the short
  slot subset (`{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{OPEN_QUESTIONS}}`,
  `{{CORE_INSTRUCTION}}`) and omits the rest rather than emitting empty headings.

## 5.0.2 — Collapse the plan-mode guard to one line (2026-07-28)

- **Eight skills reduced** — `build`, `build-proposal`, `finalize-plan`,
  `implementation-plan`, `plans-library`, `prototype`, `review-plan`, and
  `setup-sites` replace their `ExitPlanMode` preambles with the canonical
  one-line guard. `build-proposal` keeps its separate `WebSearch`/`WebFetch`
  bootstrap note, which is a different instruction.
- **`review-plan-bg` drops the guard entirely** — the command only dispatches
  `agent-review-plan`, which reaches `review-plan` and its own guard. `ToolSearch`
  and `ExitPlanMode` are removed from its `allowed-tools` accordingly.

## 5.0.1 — Document Step 8's tracking-issue offer in the README (2026-07-29)

### Changed

- **README now describes the Step 8 tracking-issue offer** — `implementation-plan` delegates to `git-agent:create-issue` with the plan as its source, records the issue URL as the spec's `issue:` frontmatter key, skips the question when `issue:` is already set, and continues with a one-line note when `git-agent` is not installed. The behavior was documented in the SKILL and the changelog but not the README, and outside those in the repo's root `CLAUDE.md`, which is being trimmed back to one line per plugin. Documentation only; no behavior change.

## 5.0.0 — `build` can author the plan it implements (2026-07-27)

### Added

- **Step 1b, the no-plan chain in `build`.** `/plan-agent:build` with no plan named no longer dead-ends with a routing message. It asks `Start with a proposal` / `Straight to plan authoring`, then delegates: `Skill("plan-agent:build-proposal")` → `Skill("plan-agent:implementation-plan")`, whose Step 8 menu already calls back into `build`. The proposal handoff leads with objective text naming the proposal path — a bare `.md` first token would drop `implementation-plan` into conversion mode and produce a plan whose steps restate proposal headings. `--dir` is not forwarded to `build-proposal`, which resolves its own directory.
- **Objective argument** — `/plan-agent:build add a health check endpoint`. The path-versus-objective test reads the **leading token only**, so a slash later in the string is harmless (`add A/B testing support` parses as an objective) but a slash in the first token misreads the whole argument as a path (`A/B testing for checkout`) — that stop message names the misparse instead of only listing paths tried.
- **Abandonment contract** — a proposal written before an aborted chain is left in place uncommitted and its path reported, never cleaned up.
- **A stated fallback for when `AskUserQuestion` is unavailable.** Every gate — discovery offer, objective prompt, proposal-versus-direct gate, preconditions — stops and reports the choice it would have offered, and never resolves itself by picking for the user. Found by running the skill headless: with the fallback undefined, one run adopted the lone discovery candidate "because it was the only one" (the exact silent pickup this release removes) while another stopped at the proposal gate — the same missing tool resolved two opposite ways.

### Changed

- **BREAKING — argument format.** `argument-hint` is now `[<plan.md|plan.html>] [<objective>] [--dir <path>]`.
- **BREAKING — argument-less discovery is an offer, not a pickup.** A single `todo` match used to be adopted silently; it is now offered alongside `None of these — author a new plan`. The offer is capped at three candidates with the suppressed count stated, because `AskUserQuestion` renders at most four options. With an objective supplied, discovery is skipped entirely — it selects on `status:` alone with no notion of subject, so a repo of unrelated `todo` specs would answer "a todo app" with a menu of noise.
- **The dirty-working-tree guard is hoisted** ahead of the chain. Left in the Step 1 preconditions it would have fired only after a full proposal loop and plan interview, matching `git-agent:ship-autonomous`'s guards-before-mutation order instead.
- **`model: opus` pinned** on `build`. A skill's `model:` override applies for the rest of the turn and does not unwind when the skill ends, so a chained run would otherwise leave the source-writing stage on whatever `implementation-plan` or `review-plan` last set.
- `Exit — I'll implement later` and `Run as workflow` at the chained Step 8 both terminate the **outer** chain.
- **`Implement now` is terminal too.** `Skill()` is synchronous, so the nested `build` has already finished by the time control returns; re-entering Step 1 would ask whether to redo work that just completed, or restart a run the user stopped with `Mark in-progress and stop`. The nested result is now reported as the chain's result. This overrides the proposal's Appendix A rows for the completed and partway cases.
- **The dirty-tree guard excludes plan artifacts.** The Step 8 callback re-enters `build` with the just-authored spec and HTML uncommitted, so the hoisted guard would have fired at exactly the post-interview moment the hoist exists to prevent — and headless, the new unavailable-question rule would have stopped the chain outright.
- **A Tier 0 proposal that writes no document falls through to the direct path** with the original objective, instead of calling `implementation-plan` with a proposal path that was never created. Step 8 is the only point at which the user is asked how to execute, so treating either as declining merely the inner offer would build work they just routed elsewhere.

### Notes

- **The chain is reachable only from the slash command.** The objective is a command parameter; typing "build a todo app" as plain text does not enter it. `build` is overloaded enough that an ambient trigger wide enough to catch that also catches "build fails on CI" and "build the docker image". The `description` frontmatter is therefore byte-identical, and the model path keeps its route-away contract verbatim.
- Two no-plan branches deliberately still stop: a named-but-missing path (chaining on a typo would author a whole plan) and an HTML-only legacy plan (which needs its spec reconstructed, not a new plan on top of it).
- The new `test-build-skill.sh` checks are **static** — they assert the chain is authored correctly, not that it executes. No harness here can drive a skill's interactive gates.

## 4.4.0 — A plan and its prototype know about each other (2026-07-26)

### Added

- **`prototype:` frontmatter key on plan specs.** A spec carrying a repo-relative `prototype:` path renders `<meta name="plan-prototype">` and a **View prototype** link in the plan header. The href is computed with `path.relative()` from the rendered plan's own output directory, so it resolves from a custom or nested `plansDirectory` — a hard-coded `../prototypes/` would have pointed at `custom/prototypes/` for a plan rendered under `custom/plans/`.
- **`proto-model:` frontmatter key**, and a matching `<script type="application/json" id="proto-model">` block in every generated prototype. Step 3 of `/plan-agent:prototype` derived a data model and then discarded it; it now survives in both files as compact single-line JSON (`entity`, `fields[{name,type}]`, `action`, `successSignal`), which is what makes drift detectable at all.
- **`check-prototype-drift.py`** (`PostToolUse`, a child of `dispatch.py`): compares a prototype's model against its own `<th data-field>` headers and form fields, and against its plan's copy. Warnings name both files, the diverging field, and what to re-run. Silent when there is nothing to compare; **always exits 0**.
- **Prototype chip on the plans gallery card** — a text-bearing `<span>`, never an `<a>`: the card is already wrapped in an anchor, and a nested one is invalid HTML that browsers silently unnest.
- `tests/plugins/test-prototype-plan-link.mjs` (objective) and `tests/plugins/test-prototype-drift.sh` (drift branches + dispatch fan-out).

### Changed

- **`/plan-agent:prototype` writes the link back** into the source plan's Markdown spec before the prototype HTML is written — plan path only, skipped for idea, image, and Figma inputs. When the sibling `.md` does not exist (most committed plans are legacy HTML), it skips the write-back, still generates the prototype, and prints how to materialize a spec. Materializing one as a side effect would silently rewrite a plan the user never asked us to touch.
- **`{{SOURCE_PLAN}}` is now a pinned contract**: the repo-relative path of the plan's Markdown spec on the plan path, empty otherwise. It was undefined free text that only ever fed the gallery card's display string; the drift hook resolves the owning plan from it.
- Both written values must stay on one line. The frontmatter parser is a naive line scanner — an embedded newline or bare `---` truncates the block and corrupts `status` and `created` for every consumer that re-scans it.

### Notes

- The drift check compares **structure, not intent**: a hand-edit that changes the rendered columns is caught; one that changes copy, styling, or seed values is not, and should not be.
- Detection runs one way only — prototype HTML against plan frontmatter. A hand-edited plan desyncs with no signal; plans are user-owned prose rather than generated output.
- The header link deliberately ships **no new CSS**. The shared style block is emitted into every plan, so a new rule would change the bytes of plans that have no prototype at all.

## 4.3.1 — Condense the marketplace description (2026-07-21)

### Changed

- **Marketplace description trimmed from 1,704 to 635 characters** (-63%). It had grown into a per-skill feature tour against a ~250-character average for the other 12 plugins; the per-command detail it carried is already documented here and in the README. All 14 skill names are retained — `test-build-skill.sh` check 9 treats the description as the discoverability surface for `/plugin` search and asserts every `skills/` directory appears by name, so shortening it is a copy-edit, never a delisting.
- **`CLAUDE.md` plugin-table row condensed** from 2,306 to 1,121 characters, bringing it in line with the other long rows instead of 2.5× the next-longest. Cut less aggressively than the marketplace copy on purpose: `CLAUDE.md` loads into context every session, so command names and behavioral constraints (`implementation-plan` never writes source files) earn their tokens where per-command mechanism prose does not.

No behavior changes — description and metadata only.

## 4.3.0 — `build` skill: implement a plan on its own (2026-07-20)

- New `build` skill (`/plan-agent:build [<plan>]`) implements an existing plan end-to-end: resolves the plan (argument, or the newest `todo`/`in-progress` spec), walks the steps, ticks the spec, and runs the acceptance-criteria, end-to-end-verification, and completion-checklist gates. It re-renders after every batch of spec edits, not only at the end, so the gallery never shows a stale status mid-run.
- Implementing no longer requires being inside `implementation-plan`'s Step 8 menu. A plan written three days ago is now buildable with one command instead of a copy-pasted prompt.
- `implementation-plan` Step 8 `Implement now` delegates to the new skill instead of carrying its own copy of the loop — the gates moved out of `implementation-plan` rather than being copied into `build`. (`finalize-plan` still applies equivalent completion rules to plans implemented outside this skill; the two are cross-referenced and must be changed together.) `implementation-plan`'s Scope Constraint is no longer lifted at all: every source-file write now happens in `build`.
- `status: completed` is written only after the end-to-end verification gate passes, not when the last acceptance criterion is checked — a plan no longer advertises itself as complete for the duration of the fix loop.
- `build` resolves an explicit plan path as given before falling back to basename lookup, so plans under `--dir` or an absolute path resolve; discovery skips `archive/` and asks when the newest plan is ambiguous.
- Preconditions before any write: refuses to silently re-implement a `completed` plan, resumes from the first unmarked step, and surfaces a dirty working tree. It no longer commits on its own.
- Fixed in `.gitignore`: the unanchored `build/` pattern (for root JS build output) matched the new skill directory at any depth and would have shipped a 4.3.0 release advertising a command whose file was never committed. Now anchored to `/build/`, with a `tests/plugins/test-build-skill.sh` check that fails if the skill is ever untracked again — wired into `check-plugin-versions.yml` so it gates pull requests, not just the nightly publish.

## 4.2.0 — Card-count check on the plans gallery (2026-07-19)

- `plans-library` now asserts, after writing `docs/plans/index.html`, that the file parses and its card count equals the number of plan files scanned. The failure mode it catches is silent card loss — an index that writes successfully with half the plans missing.
- On a mismatch the skill reports the index path, the card count, and the source count, then stops instead of opening a gallery it cannot vouch for.
- `plans-open` carries a one-line note recording that its output check lives in `plans-library`. It opens an existing gallery and generates nothing, so a check of its own would be theater; naming it stops a future audit from re-flagging it.

## 4.1.0 — Verification gate in every generated prompt (2026-07-18)

- The implement, goal, and workflow prompts now share one verification tail: run the objective test's **Run** command, walk the Verification section, confirm every acceptance criterion, then mark completion in the spec (`[x]` steps, `- [x]` criteria, `status: completed`) and re-render. A failed check leaves `status: in-progress` and names what failed.
- Workflow prompts reserve the final verification phase for the lead agent rather than a subagent.
- Authored `## Next Steps` prompts must carry their own verification instruction — they run in a fresh session with no plan behind them.
- The Copy-button prompt now names the objective test's **Run** command explicitly and refuses to mark the plan done on a failing check; `reference/SKELETON.html` was stale against `plan-shell.mjs` and is re-synced.
- New renderer test asserts all three prompts carry the verify-then-mark-completed gate.

## 4.0.1 — Always-runnable completion check (2026-07-18)

- Every objective-verification test now carries a **Run** command in both tiers. Tier 2 (docs/metadata) plans use a plain shell command (`grep -q`, `test -f`) instead of a test runner, so there is no longer a "nothing runnable" case.
- `implementation-plan`'s end-to-end gate no longer falls back to inspection-only for Tier 2 — a missing **Run** is authored on the spot, re-rendered, and run.
- `## Verification` must name a re-runnable command or a specific observable end state; "confirm it works" is rejected.
- `finalize-plan` derives and runs an objective check for older plans that lack one, reporting it as derived, instead of silently recording `n/a`.

## 4.0.0 — Merge `plan-interview` into `plan-agent` (2026-07-17)

**BREAKING:** the standalone `plan-interview` plugin is de-registered and deleted (source recoverable from git history). Its unique capabilities are now first-class `plan-agent` skills, commands, an agent, and a hook. The redundant overlap — the multi-round interview skill, product-plan routing, and HTML artifact generation — is **dropped** in favor of plan-agent's built-in Step 5b interview and the `review-plan` Agent Team.

If you had `plan-interview@agentics-kit` installed, uninstall it and ensure `plan-agent` is at 4.0.0 or later. Command and skill invocations move namespace as follows:

| `plan-interview:*` (old) | `plan-agent:*` (new) | Notes |
|--------------------------|----------------------|-------|
| `documenting-plans` | `documenting-plans` | skill + command + `plan-documenter` batch agent carried over |
| `markdown-to-html` | `markdown-to-html` | skill + command + assets/reference/scripts carried over |
| `plan-status` | `plan-status` | single-file behavior unchanged |
| `update-plan-status` | `plan-status <dir> --all` | bulk mode folded into `plan-status` as a directory/`--all`/`--force` flag; standalone command removed |
| `plan-maintenance` | `plan-maintenance` | command carried over |
| `deep-grill` | `deep-grill` | skill + command carried over (node-by-node decision walk, distinct from the `review-plan` team) |
| ExitPlanMode nudge hook | `hooks.json` `ExitPlanMode` PostToolUse matcher | reworded to point at the built-in Step 5b interview / `review-plan` |
| `plan-interview` (skill) | — | dropped; use the built-in Step 5b interview or `review-plan` |
| `plan-to-html` | — | dropped; `markdown-to-html` is the successor |
| `plan-hygiene` | — | dropped; the `validate-plan-filename` hook covers filename hygiene |
| `review-rename-plans` | — | dropped; the `validate-plan-filename` hook covers renames |

### Added

- **`documenting-plans`, `markdown-to-html`, `plan-status`, and `deep-grill` skills** plus the **`plan-maintenance`** and matching commands and the **`plan-documenter`** agent, all carried over from `plan-interview` with namespaces and intra-plugin links repointed to `plan-agent`.
- **Bulk plan-status** — `update-plan-status`'s directory batch mode is folded into `plan-status` as an `--all` / directory-argument path with summary-first bulk approval, six-group triage, and a hybrid write strategy.
- **ExitPlanMode nudge hook** — a new `PostToolUse` matcher in `hooks.json` reminds you to stress-test a freshly exited plan via the built-in interview or `review-plan`.

## 3.2.0 — Scope the reviewer agents and collapse the hooks into one dispatcher (2026-07-17)

### Fixed

- **The seven `plan-reviewer-*` agents were running with full tool access.** Each declared `allowed-tools: Read, Glob, Grep, Bash` — but `allowed-tools:` is the *skills* key. On an agent it is not recognised, so the restriction was silently discarded and seven agents whose whole job is to read a plan and report findings held Write, Edit, and unrestricted Bash against the repo. They now declare `tools: Read, Glob, Grep, Bash(git *)`, matching the `product-plans` reviewer cluster, which used the correct key and was correctly scoped all along. The file always *looked* right; only the live agent registry showed the difference.
- **`MultiEdit` bypassed the plan-filename gate.** `validate-plan-filename.py` was registered on `Write|Edit` only, so a badly-named plan written via `MultiEdit` slipped through. It is now reached on `Write|Edit|MultiEdit`.
- **Every file edit in every session spawned four hook processes** purely to discover the file was not a plan. The four `PostToolUse` entries are now a single `hooks/dispatch.py`, which checks the path against the plans directory before invoking any hook.
- **`build-index.sh` no longer walks the filesystem to find its templates.** `find_templates_dir()` searched all of `~/.claude/plugins` plus the project root on every plan write — unbounded work scaling with installed-plugin count and repo size. Templates now resolve against `$CLAUDE_PLUGIN_ROOT/templates` when running as a hook, then a fixed list of candidates anchored to the script's own location, and finally a fixed-depth glob of the installed plugin cache (`~/.claude/plugins/cache/*/plan-agent/*/templates`, newest version wins) — so a project that installed `plan-agent` rather than vendoring it still finds the real template when running the script standalone, instead of silently degrading to the inline fallback gallery. No filesystem walk on any path. Applied in lockstep to all three byte-identical copies: the bundled hook, `scripts/build-plans-index.sh`, and `docs/plans/build-index.sh`.

### Added

- **`hooks/dispatch.py`** — a single path-gated entry point for the plan hooks. The individual hook scripts still re-apply their own filters, so each remains safe to run standalone. The children share the dispatcher's one 60s `hooks.json` budget via a common deadline, since they now run sequentially in a single process rather than each holding an independent timeout; a child that would overrun is skipped with a note on stderr rather than letting the harness kill the dispatcher mid-fan-out. The path gate filters on extension only for plan writes — `build-prototypes-index.sh` gates on path alone, so filtering prototypes by extension would drop writes it would have acted on.

## 3.1.1 — Trim skill descriptions to budget (2026-07-16)

### Fixed

- `skills/prototype` (246 chars) and `skills/finalize-plan` (224) — descriptions brought within the 200-char total and 80-char first-sentence budget.
- `skills/build-proposal` — description restructured into the three-part format; it was a single 195-char sentence with no short first sentence, blowing the 80-char limit.

## 3.1.0 — Plan prompts require objective verification (2026-07-16)

### Changed

- **Implement, goal, and workflow prompts now end with an explicit verification instruction** — every generated plan's copy-paste prompt tells the implementing agent to verify the objective is met and every acceptance criterion and check passes before reporting done.
- **The implement button's rich prompt gained a verification step** — it now instructs the agent to run the plan's Verification and Tests sections end-to-end and confirm the objective works in the running application (fixing and re-verifying on failure) before setting `status: completed`.

## 3.0.0 — Rename `refine-prompt` skill to `write-prompt` (2026-07-14)

### Changed

- **BREAKING: renamed the `refine-prompt` skill to `write-prompt`** — invoke it as `/plan-agent:write-prompt [intent]` instead of `/plan-agent:refine-prompt`. The skill directory moved from `skills/refine-prompt/` to `skills/write-prompt/`, and its internal template/reference paths, description, and title were updated to match. Behavior, phases, and reference templates are unchanged. Update any saved commands, aliases, or docs that referenced the old `/plan-agent:refine-prompt` invocation.

## 2.22.1 — Per-skill model pinning (2026-07-13)

### Changed

- **Model frontmatter across skills and the background review agent** — reasoning-heavy skills now pin their model for the invocation turn: `implementation-plan` and `build-proposal` run on `claude-fable-5`; `review-plan`, `refine-prompt`, and `prototype` run on `opus`; `finalize-plan` runs on `sonnet`. The `agent-review-plan` background agent moves from `sonnet` to `opus` to match the foreground review path's synthesis step. The seven `plan-reviewer-*` agents stay on `sonnet`, and mechanical skills (`plans-library`, `plans-open`, `setup-sites`) inherit the session model. The override is turn-scoped and falls back to the session model if an org `availableModels` allowlist excludes the pinned model.

## 2.22.0 — Optional tracking-issue creation at the end of every plan (2026-07-13)

### Added

- **Step 8 tracking-issue question** — the end-of-plan `AskUserQuestion` now batches a second question: "Create a tracking issue for this plan on GitHub/GitLab?" Choosing yes invokes `git-agent:create-issue` with the new `plan <spec path>` source, which drafts the issue from the plan's objective, steps, and acceptance criteria behind its own confirmation gate. The created issue URL is recorded as the spec's `issue:` frontmatter key (the same key issue-seeded plans already carry) and the HTML is re-rendered. If the `git-agent` plugin is not installed, the skill notes it in one line and continues — issue creation never blocks the plan flow. The question is skipped entirely when the spec already carries an `issue:` key (issue-seeded plans, or a repeat pass through the menu) to avoid duplicating the backlog item and overwriting the existing link.

## 2.21.0 — Prompts reference the Markdown spec; Next Steps renders again (2026-07-13)

### Changed

- **Implement/goal/workflow prompts reference the `.md` spec, not the rendered HTML** — the derived prompts (`plan-implement`, `plan-goal`, `plan-workflow` meta tags plus their visible rows) now point at the plan's Markdown spec path. An implementing agent reads the ~5–10 KB spec instead of the 60–120 KB rendered page (~90% fewer tokens per read; the workflow prompt briefs *every* subagent with the file, so the saving multiplies), and lands progress where it lives. The renderer CLI passes the real spec path; `renderPlanHtml()` accepts an `mdPath` option and falls back to `planPath` with `.html` swapped for `.md`.
- **Copy-button prompt walks the markdown-first loop** — `buildImplementPrompt()` now instructs: read the spec (the HTML is a rendered view), tick `[x]` step markers and `- [x]` criteria bullets in the spec, set `status: completed` in the frontmatter, then re-render the sibling HTML so it shows every step and criterion complete — never hand-edit the HTML. This replaces the pre-markdown-first instructions that told agents to "mark it done in the plan" against the HTML file.

### Added

- **`## Next Steps` renders into the HTML plan again** — the section legacy hand-written plans carried (and the markdown-first renderer skipped) is back: each top-level `- ` bullet renders as a collapsible `details.next-step-item` card (summary line, optional description, paste-ready prompt in a `<pre>` with a `copyPrompt()` Copy-prompt button — the exact legacy markup, whose CSS/JS never left the shell); bullet-less content renders as paragraphs. Parsed by `parseSpecMarkdown()` into a `nextSteps` key kept beside `sections` (like `progress`) so the extract → digest → parse round trip stays byte-stable. Sidebar nav gains a filtered "Next steps" entry.
- **`plan-md` meta tag + Spec drawer row** — rendered plans expose the spec path as `<meta name="plan-md">` and a third Spec row (`id="plan-md"`) in the More-ways drawer's plan-source block.
- **Docs** — `section-catalog.md` gains a `## Next Steps` catalog entry (syntax + example) and drops it from the markdown-only group; `SKELETON.md` shows the bullet/fence syntax; SKILL.md documents the spec-path prompts, the `plan-md` meta tag, and the Next Steps cards.

## 2.20.0 — Markdown-first status and checkbox flows (Phase 3) (2026-07-12)

### Added

- **Progress state in the plan spec** — `parseSpecMarkdown()` now reads completion state from checkbox syntax and returns it as a separate `progress` key (content `sections` stay byte-stable, so the extract → digest → parse round-trip is untouched): `- [x]` / `- [ ]` bullets under `## Acceptance Criteria` carry per-criterion state (plain `- ` bullets parse as unchecked), an optional `[x]` marker after a step number (`3. [x] <action> Why: … Verify: …`) carries per-step state, and a new optional `## Completion Report` lifecycle section (`- <item> — <reason>` bullets) carries close-out findings.
- **Renderer derives all completion markup** — `build-plan-html.mjs` renders checked criteria inputs, completed step cards with `done` chips, a server-rendered initial progress bar (label, width, `aria-valuenow`), the completion checklist (cc1–cc3 `checked` plus the `all-complete` class, from all-steps-done + all-criteria-done + `status: completed`), and the `dl.report-list` Completion Report — the exact markup `finalize-plan` used to write by hand.

### Changed

- **`finalize-plan` goes md-first** — when the plan has a sibling `<stem>.md` spec, all completion writes are Markdown edits (frontmatter `status`, criteria checkbox flips per the user's choice, step `[x]` markers, a `## Completion Report` section for unverified criteria / evidence gaps / objective-test failures) followed by an explicit re-render via `build-plan-html.mjs`; it also reconciles transition-window drift (criteria checked in the HTML before this release are flipped into the spec). Accepts `.md` plan arguments alongside `.html`. Legacy plans without a spec keep the direct HTML attribute edits.
- **`implementation-plan` status gates edit the spec** — Step 6 and the Step 8 implement-now gates flip step/criterion state in the spec markdown and re-render instead of editing `checked` attributes, `.step-card` classes, and status attributes in the HTML; re-rendering is now lossless (progress re-renders from the spec), so the "re-rendering resets HTML progress state" caveat is gone. The completion-checklist gate verifies spec state and lets the renderer derive cc1–cc3/`all-complete`; gaps are recorded as `## Completion Report` bullets.
- **Frozen-string contracts retired** — nothing matches the `todo` step chip, the "No items to report — all requirements met." sentence, or the "Pursue as goal" label byte-for-byte anymore, so the exported `STEP_CHIP`/`STEP_CHIP_DONE`/`NO_ITEMS_REPORT`/`GOAL_LABEL` constants in `plan-shell.mjs` are demoted to internal presentation strings and the byte-for-byte test pin is replaced by behavioral progress-state assertions. The gallery keeps reading `plan-*` meta tags from rendered HTML unchanged.
- **`section-catalog.md` documents the state syntax** — checkbox bullets for Acceptance Criteria, the step `[x]` marker, and the `## Completion Report` lifecycle section; `SKELETON.md` starts criteria as `- [ ]` bullets.

## 2.19.0 — Guideline-driven plan authoring (Phase 2) (2026-07-12)

### Added

- **`skills/implementation-plan/guidelines/` library** — four guideline documents replacing the prescriptive markup rulebook, loaded via progressive disclosure (SKILL.md keeps a one-paragraph summary of each; the full file is read only when the step calls for it): `planning-principles.md` (falsifiable "done", what/why/verify per step, end-to-end verification, surfaced risks, explicit scope), `section-catalog.md` (each spec section's purpose, when it earns its place, and the exact syntax `build-plan-html.mjs` parses, plus the frontmatter key table), `right-sizing.md` (minimal / standard / deep depth profiles with a calibration table — where the `minimal`/`adr`/`spike` intent ships as guidance instead of extra HTML skeletons), and `writing-style.md` (tone, plain language, objective-vs-glance — moved out of the workflow doc).

### Changed

- **`SKILL.md` rewritten around the markdown-spec pipeline** — the agent now authors a ~5–10 KB Markdown plan spec (the source of truth, committed beside the HTML) and renders it with the bundled `scripts/build-plan-html.mjs`; the agent decides which optional sections a plan includes, at what depth, per the guidelines. Workflow Steps 0–8 (issue ingestion, explore, clarify, align, interview, tests, status gates, delivery, next-action menu) survive intact; a new Step 5d runs the renderer, and Step 8's "Edit the plan" edits the spec and re-renders instead of patching HTML. The Required Structure, HTML Output Requirements, Visual Components, Frozen Strings, File-Tree Auto-Generation, and skeleton-copying prose is gone — the renderer owns all of it mechanically. SKILL.md drops from 76 KB to ~26 KB.
- **`reference/SKELETON.md` is now the spec starter** — rewritten to the exact format `parseSpecMarkdown()` accepts (frontmatter keys, `# Plan:` title, `Why:`/`Verify:` step markers, `- path (badge) — note` file entries, tier line + test bullets), replacing the old humanized-headings fallback. `reference/SKELETON.html` remains for reference and its smoke tests but is no longer copied by the skill.
- **`--priority` and issue URLs land in the spec, not meta tags** — `priority:` and `issue:` are written as spec frontmatter keys (preserved in the markdown, not yet rendered as `plan-priority`/`plan-issue` meta tags); the seeding issue is also cited in the Context section. `planAgent.extraFrontmatter` pairs likewise go to spec frontmatter instead of extra `<meta>` tags.
- **Tests updated for the pipeline** — `test-goal-prompt.sh` asserts SKILL.md documents the derived goal-prompt contract (format + `plan-goal` meta + `copyGoal(this)`) rather than a `{goal-prompt}` placeholder; `test-resources-section.sh` asserts the Resources guidance lives in `guidelines/section-catalog.md` and the spec skeleton.

## 2.18.0 — Markdown-spec-to-HTML plan renderer (2026-07-12)

### Added

- **`scripts/build-plan-html.mjs` renderer CLI** (repo-level) — `node scripts/build-plan-html.mjs <spec.md> [-o <plan.html>]` renders a small Markdown plan spec into the full styled HTML plan, reproducing today's DOM contract (all `plan-*` meta tags, `#objective`, the implement row and more-ways drawer, `#steps` step cards, `#tests`, `#criteria-list`, `#verification`, the completion checklist) with all spec text HTML-escaped. Derived fields are computed, never authored: the implement/goal/workflow prompts, the effort level (same Low/Medium/High thresholds the skill uses), the file-tree markup, the criteria count, and a sidebar nav filtered to the sections present.
- **`parseSpecMarkdown()` in `scripts/lib/plan-spec.mjs`** — the inverse of `buildDigest()`: parses a spec (optional YAML frontmatter for metadata, then title/Objective/Context/Files/Steps with Why:/Verify:/Tests/Acceptance Criteria/Verification) into the same sections object `extractSections()` returns, so the extractor and renderer cannot drift apart.
- **`scripts/lib/plan-shell.mjs` presentation shell** — the SKELETON.html CSS, icon sprite, JavaScript behaviours, and frozen strings (`todo` step chip, "No items to report — all requirements met.", "Pursue as goal — optimize for the outcome") extracted into exported template functions holding style and layout only, never plan content.
- **`hooks/render-plan-html.py` regeneration hook** — PostToolUse on Write|Edit|MultiEdit: when a `# Plan:` Markdown spec inside the resolved plans directory is written, the sibling `.html` is re-rendered via `build-plan-html.mjs` — preferring the copy bundled with the plugin (`$CLAUDE_PLUGIN_ROOT/scripts/`), falling back to the consumer project's `scripts/build-plan-html.mjs`, and silently skipping when neither exists. Resolves `plansDirectory` with the skill's full settings precedence (project `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`, falling back to `docs/plans/`), and exits non-zero with the error on stderr when the renderer fails. After a successful render it rebuilds the plans gallery index best-effort, since the index hook skipped the `.md` write and a subprocess-written `.html` is not a tool event.
- **Bundled renderer** — `scripts/build-plan-html.mjs` plus `scripts/lib/plan-spec.mjs` and `scripts/lib/plan-shell.mjs` ship inside the plugin (byte-identical copies of the repo-root sources, pinned by a parity test) so normal marketplace installs get a working hook without vendoring the development repo.
- **`tests/plugins/test-build-plan-html.mjs`** — unit cases for `parseSpecMarkdown()`, CLI and hook integration cases, and the round-trip property: every committed plan in `docs/plans/` whose sections extract cleanly must survive extract → digest → parse → render → re-extract with a deep-equal sections object (59 plans at introduction; ≥10 required), plus frozen-string and zero-unfilled-placeholder assertions.

### Changed

- **Reduced-motion coverage in `reference/SKELETON.html` (and the extracted shell)** — `prefers-reduced-motion: reduce` now also disables smooth scrolling and the in-progress status-badge pulse, matching the reduced-motion handling the other animated elements already had.

## 2.17.0 — Humanized implementation-plan output (2026-07-09)

### Added

- **"At a glance" plain-language summary block** — generated plans now open with a short, jargon-free summary of what the plan does and why, rendered from a new `{at-a-glance}` placeholder as a `.plan-glance` block placed as a sibling immediately after `div#objective` (never nested inside it, so `extract-plan-spec.mjs` output stays pure). Written for a reader who was not in the planning session; the technical Objective remains unchanged.
- **"More ways to run this plan" drawer** — the secondary prompt rows are regrouped into a collapsed `details.plan-more-ways` drawer so **Implement** is the single visible action in the prompts area; the goal and workflow prompts and the plan-source File/Path rows live inside the drawer and expand on demand. All existing prompt ids, classes, and copy buttons are unchanged — this is purely a regrouping.
- **SKILL.md authoring rules + frozen-strings contract** — new writing guidance (sentence-case human headings, a one-line plain-language intro under each section heading, audience-first phrasing) plus an explicit contract listing the byte-for-byte strings and machine-readable hooks (ids, classes, `plan-*` meta tags, "Pursue as goal", `todo`/`done` step chips, the "No items to report — all requirements met." sentence) that generators must never alter.
- **`tests/plugins/test-humanized-skeleton.sh`** — smoke test pinning the humanized skeleton: presence of the at-a-glance block, the collapsed more-ways drawer, sentence-case headings, and all frozen strings/contract selectors.

### Changed

- **Section headings and intros humanized** — `reference/SKELETON.html` headings moved to sentence case with a one-line intro under each, and the markdown fallback `reference/SKELETON.md` was mirrored to the same humanized headings ("At a glance", "Definition of done", "Final check") — the markdown skeleton remains the lighter fallback and does not gain the HTML-only sections (Tests, Completion checklist, drawer).
- Minor bump rationale: the output format changed, but nothing was removed or renamed — all machine contracts (ids, classes, `plan-*` meta tags) consumed by the gallery, hooks, finalize-plan, and extract-plan-spec remain unchanged.

## 2.16.0 — Resources section in implementation plans (2026-07-09)

### Added

- **New opt-in Resources section in `implementation-plan` plans** — HTML plans can now embed the images, screenshots, and reference links used to create the plan, so readers can *illustrate* what the work is about and *verify* the implementation against the same material. Rendered as `section.card-resources#resources` (new `#ic-photo` icon) between Context and Files, with a `.resource-grid` of `.resource-figure` image cards (mandatory `alt` text + source-crediting `<figcaption>`) and a `.resource-links` list (each link paired with a `.resource-note`). Ships behind a removal comment like the other opt-in visuals — kept and filled only when the plan was informed by screenshots, mockups, diagrams, external docs, or a seeding issue; otherwise the section and its sidebar nav link are deleted.
- **`reference/SKELETON.html`** — added the `#ic-photo` symbol, `.resource-grid` / `.resource-figure` / `.resource-links` styles, the opt-in `#resources` section markup with fill templates, and the `#resources` sidebar nav link (auto-handled by the existing scroll-spy).
- **`SKILL.md`** — documented the section under Required Structure, HTML Output Requirements, and the Visual Components table, added a **Resources Capture** guide (when to capture, image portability/no-CDN rules, accessibility, HTML-escaping), and wired capture reminders into Step 0b Explore and Step 1 Clarify. The markdown fallback `reference/SKELETON.md` gained an optional `## Resources` section.

## 2.15.0 — Standalone Artifacts gallery (2026-07-08)

### Added

- **New `hooks/build-artifacts-index.sh` publisher** — copies every HTML file from the local inbox `.claude/artifacts/` into the deployed `docs/artifacts/` tree and builds `docs/artifacts/index.html`, a standalone Artifacts gallery reusing the shared `plans-gallery.html` template. Artifacts now have their own first-class section on the docs hub, separate from implementation plans.
- **`{{GALLERY_TITLE}}` placeholder in `templates/plans-gallery.html`** — the title and `<h1>` are now parametrized so the same template renders both the "Plans" and "Artifacts" galleries. `build-index.sh` substitutes `Plans`; `build-artifacts-index.sh` substitutes `Artifacts`.

### Changed

- **`build-index.sh` no longer renders artifacts.** The plans gallery is plans-only again: the `_is_artifact` / `_artifact_created` special-casing was removed and the `os.walk` prune now also skips an `artifacts/` subdirectory, so a stray `docs/plans/artifacts/` can never leak back into the plans list.
- **Template discovery prefers a project-local template.** `find_templates_dir` in both generators now prefers a `kit/plugins/plan-agent/templates` under the project root over the installed plugin cache, so a repo that vendors plan-agent renders its galleries from its own (authoritative) template.
- **Vendored plan builders kept in sync.** `scripts/build-plans-index.sh` (used by the `regen-plans.yml` CI workflow) and `docs/plans/build-index.sh` (the rebuild-hook fallback) are byte-for-byte copies of the hook; both were updated in lockstep so an automatic regeneration substitutes `{{GALLERY_TITLE}}` and never commits a gallery with the literal token.

### Fixed

- **`build-artifacts-index.sh` builds the gallery from the published tree, not just the inbox.** The inbox (`.claude/artifacts/`) is gitignored, so on a clean checkout it is empty; the publisher now renders cards from every artifact under `docs/artifacts/` (the committed set) after copying in any new inbox files, so saving a new artifact no longer unlinks already-published ones.

## 2.14.2 — Fix plans-gallery CSS regression (2026-07-07)

### Fixed

- **Restored the `prefers-reduced-motion: reduce` override in `templates/plans-gallery.html`** — the 2.14.1 template had reverted to an older variant that dropped the block, so every `plans-library` / `save-artifact` / index-hook rebuild silently removed it from `docs/plans/index.html`. Users requesting reduced motion no longer get smooth scrolling and transitions forced on them.
- **Fixed a sub-pixel `letter-spacing` typo on `.filter-chip`** — the reverted template emitted `letter-spacing: .04px` (effectively zero) instead of `0.04em`. Restored the `em` unit so filter chips render with their intended tracking.
- Both regressions came from `plans-gallery.html` drifting to a pre-Prettier 4-space variant that no longer matched the committed `docs/plans/index.html`; the template is now realigned so regenerating the gallery reproduces the committed output instead of downgrading it.

## 2.14.1 — Default plan-implementation model set to Fable (2026-07-07)

### Changed

- **`implementation-plan` now runs on Fable by default** — the skill's `model:` frontmatter changed from `opus` to `fable`. Both the `/plan-agent:implementation-plan` command and ambient model-invocation now generate plans with Fable unless overridden.

## 2.14.0 — Show saved artifacts in the plans gallery (2026-07-03)

### Added

- **Plans gallery now lists saved artifacts** — both gallery generators surface `.html` files in the plans directory's `artifacts/` subfolder (where `save-artifact` writes) as cards under a new **Artifact** type filter:
  - `plans-library` skill (manual `/plan-agent:plans-library`) scans `artifacts/` and renders artifact cards.
  - `build-index.sh` hook (auto-rebuild on every plan Write/Edit) classifies files under `artifacts/` as `type=artifact` instead of default `todo`/`untyped` plan cards, so the auto-generated gallery matches the new filter and does not misfile artifacts.
  - Artifacts carry no plan metadata, so cards show only a title, an `artifact` type chip, and the date parsed from the `<base>-YYYY-MM-DD.html` filename — no status/effort chips. Artifact links are prefixed with `artifacts/` (the subdirectory), and artifacts sort after plans, newest-first. Reuses the existing type-filter/search/count machinery (one CSS rule + one chip in `plans-gallery.html`).
- **Gallery count/copy reworded "plans" → "items"** in `plans-gallery.html` (header, footer, no-results, live count) since the gallery now mixes plans and artifacts.
- **`plans-library` no longer reports an empty library for artifact-only projects** — the Step 1 empty-state check now also considers `artifacts/`, so a project with saved artifacts but no top-level plans still builds a gallery.

## 2.13.1 — Trim finalize-plan skill description to budget (2026-07-02)

### Fixed

- **finalize-plan `description` frontmatter back under the 200-char budget** — the 2.13.0 description ran 207 chars, exceeding the three-part skill-description budget in `.claude/rules/plugin-patterns.md` (CodeRabbit nit on PR #366). Tightened the capability sentence ("ticks acceptance criteria; --all sweeps done-but-unmarked plans") to 188 chars while keeping all three parts: short label, capability including the `--all` sweep, and the `/plan-agent:finalize-plan` trigger. No behavior change.

## 2.13.0 — `--all` sweep flag on finalize-plan (2026-07-02)

### Added

- **Sweep mode for finalize-plan** — `/plan-agent:finalize-plan --all` finds plans that are implemented but never marked completed. Discovery selects files carrying a `<meta name="plan-status">` tag valued `todo` or `in-progress` across the plans directory (excluding `index.html` and `archive/`; non-plan HTML without the tag is never a candidate), then a cheap, non-interactive token-evidence pass scores each candidate (token-less plans score 0% instead of prompting); plans at 80%+ evidence are flagged as "done but not marked". A single two-question `AskUserQuestion` (multi-select plan picker + one criteria mode for the whole batch) replaces the per-plan confirmation, and the expensive per-criterion verification and objective-verification test run only on the selected plans before the status writes. All updated files are delivered in one `SendUserFile` call with a per-plan summary. `tests/plugins/test-finalize-all-flag.sh` pins the flag to the SKILL.md contract, README docs, and marketplace version.

## 2.12.2 — Fix invalid file-tree nesting in generated plans (2026-07-01)

### Fixed

- **Nested directory list is now a child of its directory `<li>`** — the implementation-plan File-Tree Auto-Generation instructions told the generator to emit a `<li class="file-dir">` heading *followed by* a sibling `<ul class="file-list">`, making the inner `ul` a direct child of the outer `ul` (invalid HTML — a `ul` may only contain `li` children; flagged by Copilot on PR #364). `SKILL.md`'s Grouping prose and Rendering pattern, plus the skeleton's row-template comment, now place the nested `ul` inside the directory `li`, and the skeleton CSS gains `.file-list li.file-dir > ul { flex-basis: 100%; }` so the nested list renders on its own row inside the flex `li`. Matches the hand-fixed markup in `docs/plans/add-dynamic-depth-and-mode-to-refine-prompt.html` (commit 371f812).

## 2.12.1 — Fix double-escaped titles in the plans gallery index (2026-07-01)

### Fixed

- **Idempotent title escaping in the gallery generator** — `hooks/build-index.sh` (and its vendored copy `scripts/build-plans-index.sh`) extracted card titles from each plan's `<title>` tag as already-encoded HTML and escaped them again on render, so titles containing entities (e.g. `&amp;`) came out as `&amp;amp;` on every regeneration (regressed in PR #362, previously hand-fixed in PR #241). `get_title` now unescapes on extraction so the pipeline holds plain text and `e()` escapes exactly once — regeneration is idempotent.

## 2.12.0 — Effort badge and filter in the plans gallery (2026-06-30)

### Added

- **Effort badge on plan cards** — the `plans-library` gallery now reads each plan's `<meta name="plan-effort">` tag and renders a colour-coded **Low / Medium / High** chip (green / amber / red) in the card badge row, alongside the existing status and type chips.
- **Effort filter** — a new **Effort** chip row (All / Low / Medium / High) joins the status and type filters in the toolbar. Plans with no `plan-effort` tag render with no badge and pass every effort filter, so older plans are never hidden. `plans-gallery.html` carries the new chip styles, filter row, and `data-effort` filter logic; `SKILL.md` Step 4 parses `plan-effort` and emits `data-effort` plus the conditional badge.

## 2.11.0 — Auto-derived effort level on plan HTML (2026-06-30)

### Added

- **Effort level on every plan** — the `implementation-plan` skeleton now renders an auto-derived **Low / Medium / High** effort level as a colour-coded header badge (green / amber / red), a chip in the meta row, and a `<meta name="plan-effort">` tag. The level is derived deterministically in Step 2 from the plan's step count, distinct files touched, and the Step 5b interview complexity tier — no flag, no author input. Colour is driven by a `data-effort` attribute on `<html>` (mirroring `data-status`), so it ships with zero new JavaScript. `SKILL.md` Step 2/3 and the HTML Output Requirements document the new field; `tests/test-effort-level.sh` asserts the skeleton carries the meta tag, the `.effort-badge` CSS variants, and the `data-effort` attribute.

## 2.10.1 — Portable checkbox state via HTML attributes (2026-06-30)

### Changed

- **Checkbox state now travels with the file** — the `implementation-plan` skeleton no longer persists acceptance-criteria ticks to `localStorage`. The `checked` attribute on each criterion `<input>` (and the `.completed` class on each `.step-card`) is the single portable source of truth, written into the file by the agent. A plan renders its true completion state on first paint on any machine, in any browser, and in git — no per-browser storage layer to diverge from. `SKILL.md` Step 6 and the Step 8 gates now instruct the agent to mark by adding the `checked` attribute and unmark by removing it, and the HTML Output Requirements forbid `localStorage` for checkbox state.

### Added

- **Portability smoke test** — `tests/test-checkbox-portability.sh` plus `tests/fixtures/checkbox-portability/fixture.html` assert the skeleton carries no browser-storage APIs and that the fixture's `checked` attributes and `.completed` class live in the file on disk.

## 2.10.0 — Prototype from images and Figma designs (2026-06-29)

### Added

- **Image & Figma inputs for `prototype`** — `/plan-agent:prototype` now accepts an image path (`.png`/`.jpg`/`.jpeg`/`.gif`/`.webp`/`.svg`) or a Figma URL in addition to a plan path or raw idea. For an image, the skill `Read`s the mockup/screenshot and infers the entity, fields (with types), action, and success signal from what the UI shows — no interview unless the image is ambiguous. For Figma, it loads the Figma MCP tools via `ToolSearch` (`get_screenshot` + `get_design_context`/`get_metadata`) and infers the model the same way; if no Figma MCP server is connected it asks the user to connect it or paste a screenshot rather than guessing from the URL. Steps 3–8 (derive model → write → index → preview) are unchanged.
- **Broader secret/PII scrub** — Step 7 now scrubs seed values from any external source (plan, image, or Figma), since mockups and screenshots frequently show real names, emails, and tokens.

## 2.9.0 — Static-HTML prototype generator (2026-06-29)

### Added

- **`prototype` skill** — `/plan-agent:prototype <plan.html | one-line idea>` (also model-invocable) turns a completed HTML plan or a raw idea into a runnable, framework-free static-HTML prototype under `docs/prototypes/`. The skill resolves the input (`.html` token → plan path; otherwise a raw idea that triggers a 3-question interview), derives a deterministic data model, echoes it back for confirmation, then fills a reusable skeleton. One self-contained file — inline CSS + vanilla JS, an inline JSON seed, and a per-prototype localStorage store — opens by double-click on `file://` and publishes to GitHub Pages.
- **Security & a11y baked into the skeleton** — `reference/PROTOTYPE-SKELETON.html` renders records via `textContent` (never `innerHTML`), HTML-escapes interpolated values at fill time, uses script-breakout-safe seed encoding, isolates storage per prototype via `{{STORE_KEY}}`, and ships labeled inputs, a semantic table, real buttons, visible focus, form validation, a confirm-guarded reset, an empty state, and an `aria-live` status region.
- **Prototypes gallery** — `hooks/build-prototypes-index.sh` (forked from `build-index.sh`) scans `docs/prototypes/*.html`, parses `proto-*` meta, and emits an escaped, newest-first `docs/prototypes/index.html` from `templates/prototypes-gallery.html`. A new `PostToolUse` hook entry auto-rebuilds it on prototype writes (scoped to `docs/prototypes/`, leaving the plans gallery untouched), and `docs/index.html` gains a Prototypes hub card.
- **Tests** — `tests/plugins/test-prototype-portability.sh` (objective smoke), `test-build-prototypes-index.sh` (gallery builder unit), and `test-prototype-persistence.mjs` (plain-Node store test with a localStorage shim, no jsdom), wired into `publish-dist.yml` by explicit path.

## 2.8.3 — Order plans gallery newest-first by created date, not mtime (2026-06-27)

### Fixed

- **Gallery ordering** — the plans gallery now sorts cards newest-first by each plan's `plan-created` metadata instead of filesystem modification time. A `git clone`/`checkout` resets every file's mtime to the same checkout time, so the previous `os.path.getmtime` sort in `docs/plans/build-index.sh` (and the `ls -t` step in the `plans-library` skill) produced an effectively random order. Both now sort by the embedded date descending (blank dates last, title ascending as a stable tiebreak).

## 2.8.2 — Persist plan checkbox state in HTML attributes, not localStorage (2026-06-23)

### Changed

- **HTML-attribute persistence** — the generated plan's acceptance-criteria checkboxes now persist their state in the document itself (the `checked` attribute on each `<input>`) instead of `localStorage`. The browser renders `checked` inputs natively on load, so the restore step is gone; toggling a box syncs the attribute, keeping the live DOM and any saved/committed copy of the file the single source of truth. This makes plan progress version-controllable and viewable identically across browsers, rather than living in per-browser `localStorage` invisible to git. Step completion (`.step-card.completed`) and the derived completion checklist were already DOM-backed and are unchanged.

## 2.8.1 — Standardize plans-directory resolution across all skills (2026-06-20)

### Fixed

- **Writer/reader directory mismatch** — `implementation-plan` resolved its output directory with vague prose ("the configured `plansDirectory` if set") that never named the read source or precedence and carried an extra "default Claude user plans folder" rung the reader skills lack. When a project set `plansDirectory` (e.g. `docs/planning`), it could write HTML to a different directory than `plans-library`/`plans-open` scan — so generated plans never appeared in the gallery.
- **`finalize-plan` latent bug** — `$PLANS_DIR` was used by the "most recent plan" search but never defined; it now resolves via the canonical snippet.

### Changed

- **One canonical resolution everywhere** — every plan-agent skill that resolves the plans (or proposals) directory now follows Claude Code's settings precedence: project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`, falling back to `${PWD}/docs/plans` (or `${PWD}/docs/proposals`). The vague-prose, project-only, and two-tier variants are gone, so the writer and every reader resolve the same directory. Touched: `implementation-plan`, `plans-library`, `plans-open`, `finalize-plan`, `build-proposal`, `setup-sites`, and the README artifact-dir description.
- **`setup-sites`** — updated the prose/comments describing the removed "Claude user plans folder (outside the repo)" fallback; the first plan now always lands in `${PWD}/docs/plans`.

## 2.8.0 — Compute-on-read plan spec extractor replaces the embedded digest (2026-06-20)

### Changed

- **Compute-on-read spec** — retired the embedded `#plan-digest` cache in favor of `scripts/extract-plan-spec.mjs`, which derives the spec from the visible plan DOM on demand. The visible DOM is now the single source of truth: no denormalized cache, no manual "refresh the digest" obligation, and no closing-script escaping contract on the write path. New plans embed nothing. Because each plan is a self-contained HTML file, the implement, goal, and workflow prompts it ships reference the plan **by path** (Claude reads the HTML directly) — no dependency on a repo-local script in the target repo, so generated plans work for any plugin user. The review team (`review-plan` SKILL, all seven reviewer briefs, and all seven `plan-reviewer-*` agent defs) reads via the extractor with a full-HTML fallback, and the `review-plan` "Pass 1b — Refresh the digest" pass is removed.
- **Backward compatible** — the extractor is embedded-first: legacy plans that still carry a `<script type="text/markdown" id="plan-digest">` block are read from it verbatim (un-guarded to clean markdown), so existing `docs/plans/*.html` are untouched. `scripts/backfill-plan-digests.mjs` is retained to re-seed legacy embedded plans.
- **Shared library** — the parse/build helpers (`hasDigest`, `decodeEntities`, `extractSections`, `buildDigest`, `guardScriptClose`, the new `unguardScriptClose`, and `readEmbeddedDigest`) moved to `scripts/lib/plan-spec.mjs`, shared by the write-side backfill and the read-side extractor.

### Added

- **`scripts/extract-plan-spec.mjs`** — CLI spec extractor: embedded-first, DOM-derive fallback; exits non-zero on missing/unparseable input.
- **`tests/plugins/test-extract-plan-spec.mjs`** — objective round-trip (embedded → un-guarded spec; digest-free → DOM-derived) plus unit coverage for resolution precedence, un-guarding without stopping early, the shared-lib import, and CLI exit codes.

### Caveat

- New plans embed no digest, so the old `awk '…id="plan-digest"…'` one-liner returns **empty** on them — use `node scripts/extract-plan-spec.mjs <plan>` instead.

### Notes

- `tests/plugins/test-plan-digest.sh` renamed to `tests/plugins/test-extractor-wiring.sh` and rewritten to assert extractor wiring; `tests/plugins/test-backfill-digest.mjs`'s real-corpus assertion scoped so committed digest-free plans don't fail the retained injector.

---

## 2.7.0 — setup-sites skill: scaffold GitHub Pages publishing into any repo (2026-06-18)

### Added

- **`setup-sites` skill** — `/plan-agent:setup-sites` (command **or** model-invocable) scaffolds the GitHub Pages deploy pipeline into the current repo so anything generated under `docs/` (plan galleries, social cards, any static HTML) reaches a public URL. It drops four idempotent artifacts — `.github/workflows/deploy-pages.yml` (SHA-pinned, path-filtered to `docs/**`), `docs/.nojekyll`, a parameterized landing hub `docs/index.html`, and `scripts/serve-docs.sh` for local preview — never clobbering files that already exist. The skill computes the live `https://<owner>.github.io/<repo>/` URL from the `origin` remote (handling user/org root sites), warns when `plansDirectory` points outside `docs/` (where Pages can't see it) and seeds `docs/plans/` (with a committed `.gitkeep`) when it's unset so the first generated plan lands inside `docs/` and deploys instead of falling back to the Claude user plans folder, prunes hub cards for galleries the repo doesn't use, and guides the one-time **Settings → Pages → Source → GitHub Actions** step (optionally via `gh` after confirmation). Closes the gap where the deploy pipeline existed only as hand-wired infrastructure in the agentics repo and could not be reused elsewhere.
- **Scaffold templates** — `templates/pages/{deploy-pages.yml,hub.html,serve-docs.sh}` ship the three file templates the skill copies; the hub carries `{{SITE_TITLE}}`/`{{SITE_TAGLINE}}`/`{{SITE_FOOTER}}` placeholders and `<!-- CARD:plans -->` / `<!-- CARD:social -->` prune markers.
- **Tests** — `tests/plugins/test-setup-sites.sh` guards the frontmatter contract, the three-part ≤200-char description, `allowed-tools`, body line count < 500, the seven-step workflow, all three templates (SHA-pinning + `.nojekyll` assertion + `docs/` upload in the workflow; card markers + placeholders + no absolute-root links in the hub), and a **dynamic** marketplace version check (plan-agent > `origin/main`).

---

## 2.6.0 — Outcome-driven goal prompt on every HTML plan (2026-06-18)

### Added

- **Goal prompt** — every generated plan now carries a third copy-paste prompt alongside the implement and workflow prompts: an *outcome-driven* prompt that frames the work as a goal to achieve (`Achieve this goal: … — use the plan as reference, but optimize for the outcome`) rather than steps to execute, giving the implementer latitude to deviate when a better path to the same outcome exists. Rendered as a collapsible `.plan-goal` `<details>` (purple accent) immediately below the implement row, mirrored in an always-present `<meta name="plan-goal">` tag, and computed in Step 2 from the same condensed objective + plan path + digest-extraction one-liner as the implement prompt. Unlike the workflow prompt it is **always present** — no flag, no complexity heuristic. Carries the same digest-extraction clause so the pursuing agent reads the spec digest, not the full ~21k styled HTML.

### Changed

- **`reference/SKELETON.html`** — adds the `.plan-goal` markup block, its CSS (reusing the existing `--purple` design tokens), the `copyGoal()` clipboard helper, and the `<meta name="plan-goal">` head tag. Hidden when `data-status="completed"` and suppressed in print, exactly like the implement and workflow rows.
- **`implementation-plan` SKILL.md** — Step 2 computes `{goal-prompt}`; Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among the always-present meta tags and document the always-present `.plan-goal` element.
- **Tests** — `tests/plugins/test-goal-prompt.sh` pins the goal prompt to the skeleton (meta tag, markup, `copyGoal()`, CSS, completed/print hiding) and the SKILL.md contract so the feature cannot silently regress.

---

## 2.5.1 — Backfill version + changelog for the #328 description optimization (2026-06-18)

### Changed

- **Skill descriptions optimized to the three-part ≤200-char format** — backfills the version bump and changelog entry that should have accompanied PR #328, which rewrote the `implementation-plan` and `refine-prompt` skill frontmatter `description:` fields to the canonical `[short ≤80 chars] [capability] Use when…` shape. No behavior change; metadata/discovery only.

---

## 2.5.0 — build-proposal skill: turn a vague idea into a decision-complete proposal (2026-06-18)

### Added

- **`build-proposal` skill** — `/plan-agent:build-proposal <idea>` (command **or** model-invocable) turns a half-formed idea into a decision-complete proposal. It codifies an 8-step research→decide→author loop (Frame → Fan out research → Synthesize core finding → Separate facts from decisions → Resolve decisions → Author artifact → Deepen → Converge & hand off), a **Tier 0/1/2 right-sizing gate** so small ideas never get a 10-section doc, and the canonical proposal-artifact shape. It writes a living `docs/proposals/<slug>.md` and stops at the planning handoff — the seam is "should-we + what" (build-proposal) vs. "how" (`implementation-plan`).
- **Artifact-dir resolver** — resolves the proposals directory `--dir` → `planAgent.proposalsDirectory` → `docs/proposals/` → default Claude user folder (mirroring how `implementation-plan` resolves `plansDirectory`) and `mkdir -p`s it at runtime. A committed `docs/proposals/.gitkeep` seeds the default root.
- **Ambient-activation discipline** — the three-part ≤200-char description triggers on idea / "should-we" / compare-and-align intent and shares **no trigger phrase** with `implementation-plan` (which owns "plan document / write a plan file"), so the two never collide on the model-invocation path.
- **References (progressive disclosure)** — `references/artifact-shape.md` (canonical section order + skeleton) and `references/operating-principles.md` (the ten operating principles + the relationship-to-existing-capabilities map, with `deep-research` wired as an **optional** delegate behind a WebSearch/WebFetch + Explore fallback — never a hard dependency).
- **Worked-example corpus** — two trimmed, real proposals ship flat under `references/` (`example-design-md-spec-alignment.md` — Tier 2; `example-proposal-builder-skill.md` — the recursive case), each stamped with its source URL + commit SHA/date as a built-in regression corpus.
- **Tests** — `tests/plugins/test-build-proposal.sh` guards the frontmatter contract, the three-part ≤200-char description, the no-trigger-overlap-with-implementation-plan rule, body line count < 500, reference + exemplar resolution, and a **dynamic** marketplace version check (plan-agent > `origin/main`, not a hardcoded 2.4.1).

---

## 2.4.1 — Responsive CSS retrofit for every HTML plan (2026-06-12)

### Added

- **`retrofit-responsive-plans.mjs`** — new idempotent injector (third in the `backfill-*.mjs` family alongside `backfill-plan-digests.mjs` and `backfill-save-pdf.mjs`) that wraps an 8-line responsive block as `<style id="plan-responsive-fix" data-version="1">` and inserts it immediately before `</head>` in existing `docs/plans/*.html`. Re-running is a no-op: plans already carrying the marked block are detected by id and skipped, so the script is safe to run repeatedly across the corpus. Supports `--dry-run` and `--dir` like its siblings.
- **`reference/SKELETON.html`** — the same responsive block is now embedded in the skeleton, so freshly generated plans are born responsive and never need a retrofit pass.
- **Tests** — `tests/plugins/test-responsive-retrofit.sh` stands guard over both halves: the injector's marked-block insertion and idempotency, and the skeleton shipping the block by default.

---

## 2.4.0 — Save as PDF button in every generated HTML plan (2026-06-12)

### Added

- **Save as PDF button** — `reference/SKELETON.html` now ships a `.save-pdf-btn` in the plan header between the title and the status badge. Clicking calls `savePDF()` → `window.print()`, opening the browser's native print dialog whose destination list includes "Save as PDF" on Chrome, Edge, Firefox, and Safari — no external dependencies. The button is hidden in `@media print` so it never appears in the exported PDF, honours `prefers-reduced-motion`, and carries an `aria-label` plus a visible focus ring.
- **Output contract** — the `implementation-plan` SKILL.md *HTML Output Requirements* now list the button as a required header element for both freshly drafted plans and markdown conversions, closing the gap where the feature shipped only in `plan-interview:markdown-to-html` (PR #272) while plans generated by this plugin's skeleton never received it.
- **Tests** — `tests/plugins/test-save-pdf.sh` pins the port: button placement between `.plan-title` and `.status-badge`, `type`/`onclick`/`aria-label` wiring, `savePDF()` calling `window.print()`, the `@media print` hide, the CSS class definition, and the SKILL.md contract.

---

## 2.3.0 — Machine-readable digest embedded in every HTML plan (2026-06-12)

### Added

- **`#plan-digest` block** — every generated plan now embeds a `<script type="text/markdown" id="plan-digest">` block as the first element child of `<body>`, holding a spec-only markdown rendition of the plan (objective, context, files, steps with why/verify, tests, acceptance criteria, verification). `type="text/markdown"` never renders or runs, so plans stay single self-contained files. Consumers read ~1–4k tokens of spec instead of ~21k tokens of styled HTML.
- **Digest contract** — new *Machine-Readable Digest* section in the `implementation-plan` SKILL.md: spec-only field list, explicit exclusions (status, checkbox, and progress state never enter the digest), an escaping contract (plain markdown, entities decoded, literal closing-script sequences guarded as `<\/script`), and the canonical flag-and-exit awk extractor. The extractor's opening rule is first-match-only (`!f`) so digest bodies that quote the opening tag are extracted intact — the failure mode was discovered by extracting this feature's own plan, whose objective quotes the tag.
- **Digest-first prompts** — the generated implement and workflow prompts now carry the extraction one-liner (`Start from the embedded digest: …` / `Brief subagents with the embedded digest: …`), and the skeleton's `buildImplementPrompt()` instruction list opens with the digest read plus a full-HTML fallback.
- **Digest-only reviewers** — all 7 `review-plan` reviewer briefs (`references/role-prompts.md`) and agent definitions now read the digest instead of the full HTML, with an explicit full-HTML fallback for plans that have no digest yet. The lead still reads the full HTML for Step 3b UI-signal scanning and Step 7 selector edits, and Step 7 gains a *Pass 1b — Refresh the digest* that regenerates the block after inline edits (update-in-place mode only).
- **Backfill script** — `scripts/backfill-plan-digests.mjs` injects digests into existing `docs/plans/*.html` (idempotent, insertion-only, `--dry-run`, `--dir`). Plans that cannot be fully parsed are skipped and reported — no partial digests. Backfilled 41 of 53 plans (including the markdown-conversion plan that landed via the 2.2.0 merge); the 11 reported skips are 8 `*-review.html` artifacts and 3 pre-skeleton-era plans, plus 1 plan that already carried a digest. A real-corpus test asserts the checked-in tree never ships a parseable plan without a digest.
- **Tests** — `tests/plugins/test-plan-digest.sh` (skeleton first-element-child assert, extraction edge cases including self-quoting digests, prompt clauses, reviewer briefs/defs, Step 7 refresh) and `tests/plugins/test-backfill-digest.mjs` (unit coverage for `hasDigest`/`guardScriptClose`/`extractSections`/`buildDigest` plus synthetic- and real-corpus integration with byte-preservation and idempotency asserts).

---

## 2.2.0 — Markdown plan conversion for implementation-plan (2026-06-12)

### Added

- **`$MD_SOURCE` detection** — `/plan-agent:implementation-plan <plan.md>` now recognizes a `.md` first token as a markdown plan source and enters conversion mode: the markdown file is the authoritative content for a new HTML implementation plan. Resolution tries the path as given, then the plan roots by basename, then the default branch (`git fetch` + fast-forward or `git show`) before falling back to an `AskUserQuestion` — the skill never invents content and presents it as a conversion.
- **Conversion mode defaults** — conversion implies `--no-clarify --no-align --no-interview` (a committed markdown plan is pre-validated content); sections map 1:1 to the HTML plan structure, frontmatter carries over (`created` preserved; `planned`/`todo` → `todo`, `in-progress` → `in-progress`, `completed`/`done` → `completed`), the output filename swaps the source extension to `.html` (still subject to the verb-target check), and Step 8 batches a keep-or-remove question for the source `.md`.
- **Docs** — README documents the `<plan.md>` argument and conversion semantics; the skill `description` and `argument-hint` advertise the conversion trigger so "convert docs/plans/foo.md into an HTML implementation plan" activates on the model path.

---

## 2.1.0 — Findings walkthrough and --skip-analysis flag for review-plan (2026-06-10)

### Added

- **Step 6b — Walkthrough & Analysis** — new `review-plan` workflow step inserted between synthesis (Step 6) and integration (Step 7). Instead of silently auto-applying every synthesized edit, the skill now offers an interactive walkthrough of the findings before anything is written into the plan.
- **Ask-first gate** — Step 6b opens with an `AskUserQuestion` gate offering `Walk through findings` (the default), `Apply all`, and `Review only`. Declining via `Review only` applies nothing but still appends the Team Review to the plan.
- **Per-finding triage** — during the walkthrough each finding is triaged `Accept` / `Modify` / `Reject`, batched at most 4 findings per prompt. `Modify` selections are deferred and collected into a single post-walkthrough edit pass instead of interrupting the walkthrough one finding at a time.
- **`--skip-analysis` flag** — bypasses the gate and the walkthrough entirely, preserving the previous auto-apply behavior in one shot.
- **`--triage-top <N>` flag** — individually triages only the `N` highest-risk findings and batch-accepts the rest, keeping the walkthrough short on large reviews.
- **Background mode implies `--skip-analysis`** — unattended `--background` runs never block on the gate or triage prompts.
- **Source / Rationale column and Triage Outcome subsection** — the synthesis template's (`references/output-template.md`) **Inline Edits to Apply** table gains a Source / Rationale column (originating reviewer plus why), with a Triage Outcome subsection placeholder beneath it for Step 7 Pass 2 to fill.
- **README documentation** — the plan-agent README now documents the `--skip-analysis` flag and the findings walkthrough.

### Changed

- **Step 7 Pass 1** — consumes `accepted_edits` when the walkthrough ran; the full-table fallback fires only for `--skip-analysis`, background mode, or the `Apply all` gate choice.
- **Step 7 Pass 2** — the appended Team Review now records triage outcomes (accepted / modified with revised content / rejected), and the Team Review is always appended even in review-only mode.

---

## 2.0.0 — Rename craft-prompt skill to refine-prompt (2026-06-10)

### Breaking

- **`craft-prompt` → `refine-prompt`** — the prompt-crafting skill is renamed to match its originating plan (`docs/plans/create-prompt-refiner-skill.html`). Invocation changes from `/plan-agent:craft-prompt` to `/plan-agent:refine-prompt`; the skill directory moves from `skills/craft-prompt/` to `skills/refine-prompt/`. Phases, interview flow, technique matrix, and templates are unchanged.

---

## 1.11.1 — Complete craft-prompt README documentation (2026-06-10)

### Fixed

- **README `craft-prompt` section** — the overview now hyperlinks [Anthropic's official Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) guide (previously mentioned with no URL); the usage block gains a Before/After example showing a vague request ("write me a prompt to summarize stuff") transformed into the structured XML-layered prompt the skill produces; and a technique-matrix table (mirroring `skills/craft-prompt/SKILL.md`) now maps each prompt type (`system`, `task`, `creative`, `analytical`) to the best-practices techniques it applies.

---

## 1.11.0 — Review option in the plan exit step (2026-06-09)

### Added

- **`Review the plan` option in Step 8 exit menu** — every freshly-generated plan now offers a one-click path to the `review-plan` Agent Team. Selecting it presents a foreground-or-background sub-choice: foreground runs `Skill(skill: "plan-agent:review-plan", args: "<path>")` in-session and loops back to the menu after the review completes; background dispatches `Skill(skill: "plan-agent:review-plan", args: "<path> --background")` and returns to the menu immediately. Agent-Teams-unavailable hard-stop is handled gracefully — guidance is relayed and the menu is restored without crashing the flow. Plan status stays `todo` throughout reviewing.
- **`--background` flag for `review-plan` skill** — when present, the skill requires an explicit plan path, skips all `AskUserQuestion` prompts, defaults to update-in-place mode, and is safe for unattended execution.
- **`/plan-agent:review-plan-bg <path>` command** — thin background dispatcher that validates the plan path argument, spawns `agent-review-plan` with `run_in_background: true`, and returns an ack immediately.
- **`agent-review-plan` background agent** — fire-and-forget agent that confirms the plan file exists, invokes the `review-plan` skill with `--background`, and reports the updated path on completion. Runs on Sonnet with a 30-turn cap.

### Changed

- **Adaptive menu swap in Step 8** — the `AskUserQuestion` tool is capped at 4 options. When a workflow prompt is present, `Edit the plan` yields its slot to `Review the plan`: `Implement now` / `Run as workflow` / `Review the plan` / `Exit`. Without a workflow prompt all four options are present: `Implement now` / `Review the plan` / `Edit the plan` / `Exit`.

---

## 1.10.1 — Stable plan-created sort in auto-rebuild hook (2026-06-08)

### Fixed
- `hooks/build-index.sh`: replaced `os.path.getmtime` sort with `plan-created` meta sort so the auto-rebuild hook produces the same date-descending order as the `plans-library` skill. Editing a plan no longer promotes it to the top of the gallery.

## 1.10.0 — End-to-end self-verification gate (2026-06-08)

### Added

- **End-to-end verification gate in the implement-now flow** (`implementation-plan` Step 8) — after the acceptance-criteria gate and before the completion-checklist gate, Claude now runs the plan's objective-verification test plus the Verification section's end-to-end steps as a holistic check. On failure it diagnoses, fixes the source, and re-verifies in a bounded loop (up to 3 attempts), then asks the user how to proceed if still failing.
- **Objective-verification test run in `finalize-plan`** (Step 3c) — finalize-plan now executes the `.objective-test-card` **Run** command as an end-to-end pass/fail signal, surfaces the result in the findings summary, warns before completing on failure, and records failures in the Completion Report.

### Changed

- Consolidated unreleased changelog entries.

---

## Unreleased — Remove review artifact emission from review-plan

### Removed

- **Step 8 (Artifact)** — the skill no longer emits a standalone `*-review.html` file. All review findings are now placed directly into the source plan via the collapsible `<details class="team-review">` block appended in Step 7.
- **`SendUserFile`** removed from `allowed-tools` — no separate file is delivered.

### Changed

- **Step numbering** — cleanup is now Step 8 (was Step 9); total workflow steps reduced from 9 to 8.

---

## v1.9.0 — 2026-06-06 — Agent Team–based plan review skill

### Added

- **`/plan-agent:review-plan` skill** — new skill that spawns a seven-reviewer Agent Team (5 core + 2 UI-conditional) to review implementation plans, synthesize findings, apply improvements in place, and emit shareable HTML review artifacts. Detects UI signals (React, Vue, Svelte, buttons, modals, forms, etc.) and conditionally runs UX and accessibility reviewers when present.
- **Seven reviewer agent definitions** under `agents/`:
  - **Core reviewers** (always spawned): `plan-reviewer-architecture`, `-completeness`, `-testability`, `-risk`, `-conventions`
  - **UI-conditional reviewers** (spawned when UI signals detected): `plan-reviewer-ux`, `-accessibility`
- **Reference files** under `skills/review-plan/references/`:
  - **`role-prompts.md`** — seven lens-specific spawn prompts for Agent Team briefing, with template placeholders for plan path substitution.
  - **`output-template.md`** — synthesis report structure with Executive Summary, Role-by-Role findings, Agreements/Conflicts, Highest-Risk Issues, and the critical **Inline Edits to Apply** table that maps each improvement to a concrete HTML target element and action.
- **Agent Teams support** — hard-gates on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and Claude Code ≥ 2.1.32; requires feature flag and version check before spawning.

### Changed

- **Plugin description** — updated marketplace.json and plugin.json descriptions to include the new `review-plan` skill alongside `implementation-plan`, `finalize-plan`, and `craft-prompt` skills.
- **Version bump** — from 1.8.0 to 1.9.0 (MINOR bump per marketplace.md — new skill added).

---

## v1.8.0 — 2026-06-06 — Mandatory Tests section in implementation plans

### Added

- **Tests section** — every generated plan now includes a Tests section between Steps and Acceptance Criteria with a two-tier depth model: Tier 1 (code-touching plans) includes unit, integration, E2E, and objective-verification tests; Tier 2 (non-code plans) includes only the objective-verification test.
- **Objective-verification test** — mandatory for both tiers, renders as a green hero card (`.objective-test-card`) before the test list. Asserts the plan's stated objective is accomplished.
- **Test badge CSS** — `.test-badge-unit` (blue), `.test-badge-integration` (amber), `.test-badge-e2e` (purple), `.test-badge-objective` (green) with design-token-based colors.
- **`#ic-beaker` SVG icon** — added to the icon sprite sheet for the Tests nav link and section heading.
- **Purple design tokens** — `--purple`, `--purple-bg`, `--purple-border` added to `:root` for E2E badge styling.
- **Step 5c** — new test-generation workflow step that classifies the tier from step content, generates the objective-verification test from the plan objective, and produces unit/integration/E2E test entries for Tier 1 plans.

### Changed

- **`implementation-plan` SKILL.md** — Required Structure now includes `tests`; HTML Output Requirements document the Tests section rendering; Step 5c added to the workflow between Interview and Status.
- **`SKELETON.html`** — nav sidebar includes Tests link; Tests section HTML with tier label, objective-test card, and test-list placeholders.

---

## v1.7.0 — 2026-06-06 — Copyable plan file name and relative path in HTML output

### Added

- **Plan source block** — every generated plan now renders a `.plan-source` block below the implement/workflow rows with two copyable rows: the plan **File** name (basename) and its relative **Path**, each with a Copy button. Gives users the plan's name and relative URL to paste into docs and prompts. Stays visible when the plan is `completed`; hidden in print.
- **`plan-file` and `plan-path` meta tags** — added `<meta name="plan-file">` and `<meta name="plan-path">` to the plan `<head>` for machine readability.
- **`copyPath()`** helper in `SKELETON.html` to copy either field to the clipboard (with `execCommand` fallback).

### Changed

- **`implementation-plan` SKILL.md** — Step 2 now computes `{plan-filename}` and `{plan-path}` placeholders; Step 3 frontmatter and the HTML Output Requirements document the new meta tags and the plan source block.

---

## v1.6.0 — 2026-06-06 — Auto-generate Files file-tree from plan steps

### Added

- **File-Tree Auto-Generation** — new subsection in `implementation-plan` SKILL.md that automatically extracts file references from drafted steps, classifies each as `new`/`modified`/`deleted`/`generated` based on action verbs, groups by directory, and populates `{file-tree-rows}` — eliminating manual file-tree construction.

### Changed

- **`implementation-plan` SKILL.md** — the Files section (`section.card-files#files`) is now auto-generated instead of opt-in. Updated the Visual Sections heading, HTML Output Requirements, Visual Components table/rules, and Skeleton instructions to reflect the new behavior. File-tree is always included when ≥1 file is referenced; only deleted for purely conceptual plans.

---

## v1.5.1 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/plan-agent` path instead of an author-specific home directory.

---

## v1.5.0 — 2026-06-05 — Add visual components (file-tree, diagrams, charts, tables) to plan template

### Added

- **`reference/SKELETON.html`** — four opt-in, pure-CSS visual components, each shipped as a `<body>` block behind a removal comment (kept and filled when relevant, deleted with its sidebar nav link otherwise):
  - **File-tree** (`.file-tree`) — a `Files to Modify` section (`section.card-files#files`, between Context and Steps) listing files with `file-badge-new` / `file-badge-modified` / `file-badge-deleted` / `file-badge-generated` badges.
  - **Flow / pipeline diagram** (`.pipeline`) and **comparison grid** (`.compare-grid`, with `compare-col-add` / `compare-col-neutral` / `compare-col-remove` variants) — a `Diagram` section (`section.card-diagram#diagram`). Ported and generalized from the hand-authored components in `docs/plans/build-clean-plugin-dist.html`.
  - **Bar chart** (`.bar-chart`) — horizontal bars sized by an inline `style="--val:NN%"` custom property; script-free, with a visible `.bar-value` and a descriptive container `aria-label`.
  - **Data table** (`.plan-table`) — accessible table styling requiring `<caption>` and `<th scope="col">` headers.
- New `:root` tokens (`--green-border`, `--amber-bg`, `--amber-border`, `--red`, `--red-bg`, `--red-border`) so all visuals theme consistently; new `#ic-folder` icon symbol; conditional `Files` and `Diagram` sidebar nav links.

### Changed

- **`implementation-plan` SKILL.md** — documented the visual components: added an *Optional visual sections* subsection to **Required Structure**, an opt-in/accessibility bullet to **HTML Output Requirements**, a new **Visual Components** reference section (per-component triggers + rules), and a note in **Skeleton** that unused visual blocks are removed like `.plan-workflow`. All visuals stay pure CSS / inline SVG (no CDN); the gallery scanner is unaffected (it reads only meta tags + `<title>`).

---

## v1.4.1 — 2026-06-04 — craft-prompt: save prompt output to file

### Changed

- **`craft-prompt` SKILL.md** — added **Phase 7 — Save**: after delivering the prompt in Phase 6, the skill saves it as a markdown file with a `{type}-{intent-slug}-{YYYY-MM-DD}.md` filename and YAML frontmatter (`type`, `intent`, `techniques`, `created`). Output directory resolution (first match wins): (1) `promptsDirectory` from `.claude/settings.json` (project then global); (2) `{git-root}/docs/prompts/` anchored via `git rev-parse --show-toplevel`; (3) `docs/prompts/` relative to `$PWD` if not in a git repo. Includes a uniqueness guard: appends `-2`, `-3`, etc. if the target file already exists.
- `allowed-tools` extended with `Write`, `Bash(git *)`, and `Bash(mkdir *)` for repo-root detection, directory creation, and file save.

---

## v1.4.0 — 2026-06-04 — Add craft-prompt skill

### Added

- **`/plan-agent:craft-prompt [intent]`** — new skill (`disable-model-invocation: true`) that interviews users about their prompting need and generates a copy-pasteable AI prompt grounded in Anthropic's official Claude Prompting Best Practices.
  - **Phase 1 — Classify**: identifies the prompt type (system, task, creative, analytical) and applies a technique matrix mapping each type to its applicable best-practice layers.
  - **Phase 2 — Interview**: uses `AskUserQuestion` with type-specific questions derived from the technique matrix; always asks the user's *why* (per "Add context to improve performance"); offers progressive depth on user opt-in.
  - **Phase 3 — Structure**: maps interview answers to XML layers — `<role>`, `<instructions>`, `<constraints>`, `<context>`, `<example>`, `<thinking>`, `<document>` — applying only the techniques selected for the classified type.
  - **Phase 4 — Draft**: reads the appropriate template from `references/` (`system-prompt-template.md`, `task-prompt-template.md`, `creative-prompt-template.md`, `analytical-prompt-template.md`) and substitutes structured content into placeholders.
  - **Phase 5 — Recommend**: uses `ToolSearch` to surface 1–3 installed skills/agents that may achieve the goal directly, with invocation syntax and rationale.
  - **Phase 6 — Deliver**: presents the assembled prompt in a fenced block with technique header and tool recommendations.
- **`references/best-practices-reference.md`** — distilled summary of all eight core techniques from Anthropic's Claude Prompting Best Practices guide, organized by technique name with actionable implementation notes and applied-in phase references.
- **`references/system-prompt-template.md`** — parameterized template with `<role>`, `<instructions>`, `<constraints>` XML structure plus placeholder guide and assembled example.
- **`references/task-prompt-template.md`** — parameterized template with `<context>`, `<example>`, `<thinking>` scaffolding, CoT steps, and output format section; includes realistic refactoring example.
- **`references/creative-prompt-template.md`** — parameterized template with role assignment, voice description, context block, and style requirements; positive framing throughout.
- **`references/analytical-prompt-template.md`** — parameterized template with `<document>` grounding, `<thinking>` CoT, quote-extraction instruction, self-check, and output format.

---

## v1.3.2 — 2026-06-04 — Revert sort-by-created-date to mtime

### Fixed

- **build-index.sh**: reverts gallery sort back to filesystem mtime (newest-modified first); removes the `plan-created` metadata sort introduced in v1.3.1.
- **plans-library SKILL.md**: Step 3 reverts to `xargs ls -t` mtime sort; removes the collect-then-sort-by-created-date instruction from Step 4.

---

## v1.3.0 — 2026-06-04 — Rich implementation prompt with plan context

### Changed

- **SKELETON.html**: `copyCmd()` now calls `buildImplementPrompt()` which builds a concise action-oriented prompt from the plan's live DOM state — includes the short implement prompt, a status summary with step/criteria progress counts, and numbered instructions directing the implementer to read the plan, implement todo steps, verify criteria, and complete the checklist directly in the plan file.
- **SKELETON.html**: workflow prompt row converted from a static `<div>` to an expandable `<details>` element — collapsed by default with summary "Run as workflow — launch parallel subagents", reducing visual clutter while keeping the workflow option accessible.
- **SKILL.md Step 2**: documented the new "Full implementation prompt (Copy behavior)" paragraph explaining the DOM-driven rich prompt.
- **SKILL.md flags**: added `--workflow` flag to force workflow prompt generation, bypassing the complexity heuristic.

---

## v1.2.0 — 2026-06-04 — Make implementation-plan model-invocable

### Changed

- **`implementation-plan` skill**: removed `disable-model-invocation: true` — the skill is now both command-invocable (`/plan-agent:implementation-plan <objective>`) and model-invocable (auto-activates on plan-document intent).
- **`implementation-plan` description**: rewritten to a narrow, artifact-scoped three-part trigger ("generate an HTML implementation-plan document … Use when the user asks to create a plan document, generate an HTML plan, or write a plan file") that avoids colliding with built-in Plan Mode.
- **`implementation-plan` Invocation & Arguments**: documents both activation paths — command (with `$ARGUMENTS` and flags) and model (derives objective from conversation context, runs full workflow by default).
- **README.md**: updated all `implementation-plan` sections to reflect dual-mode activation; `finalize-plan` manual-only status unchanged.

---

## v1.1.0 — 2026-06-03 — Add mandatory completion checklist and report to plans

### Added

- **SKELETON.html**: new "Completion Checklist" section between Verification and Next Steps with three `disabled` checkboxes — (1) all step TODOs marked as done, (2) all acceptance criteria verified and checked, (3) plan status updated to `completed`. Checkboxes auto-update via JavaScript based on DOM state. Amber border transitions to green when all conditions are met.
- **SKELETON.html**: new "Completion Report" sub-section inside the checklist. Initially shows "No items to report"; populated with a `<dl>` detailing each incomplete item and the reason it could not be completed when the plan is finalized with unresolved items.
- **SKELETON.html**: new `ic-clipboard-check` SVG icon symbol and sidebar nav entry for the Completion section.
- **SKILL.md**: `completion-checklist` added to the Required Structure list as a mandatory (never-optional) section.
- **SKILL.md Step 8**: new "Completion checklist gate" runs after the acceptance criteria gate — verifies all three completion requirements, checks them off, and populates the Completion Report with specific details for any items that could not be completed.
- **finalize-plan SKILL.md**: new Steps 5d (completion checklist checkboxes) and 5e (completion report population) handle the checklist during plan finalization, with defensive skip when the section doesn't exist in older plans.

---

## v1.0.1 — 2026-06-03 — Pin implementation-plan skill to Opus model

### Changed

- **`implementation-plan` skill**: added `model: opus` to frontmatter so the skill always runs on the latest Opus model regardless of the session's default model.

---

## v1.0.0 — 2026-06-02 — Rename `complete-plan` skill to `finalize-plan`

### Breaking Changes

- **`complete-plan` → `finalize-plan`**: the skill directory and invocation path have changed. Update any existing invocations from `/plan-agent:complete-plan` to `/plan-agent:finalize-plan`. Functionality is identical.

---

## v0.23.2 — 2026-06-02 — Fix plans-open trigger ambiguity

### Fixed

- **`plans-open` description**: restored "without a rebuild" qualifier to the trigger phrase so it no longer overlaps with `plans-library`'s "browse plans" trigger, preventing mis-routing of first-time or rebuild-needed gallery requests.

---

## v0.23.1 — 2026-06-02 — Optimize skill descriptions to three-part format

### Changed

- Rewrote `description` fields in `complete-plan`, `implementation-plan`, `plans-library`, and `plans-open` to the three-part format (short label ≤80 chars + capability sentence + trigger phrase, total ≤200 chars) for improved skill discoverability.

---

## v0.23.0 — 2026-06-01 — Rename `planning` skill to `implementation-plan`

### Changed

- **Renamed the `planning` skill to `implementation-plan`.** Invocation is now `/plan-agent:implementation-plan <objective>` (previously `/plan-agent:planning`). The skill directory moved from `skills/planning/` to `skills/implementation-plan/`; all behavior, arguments, and workflow steps are unchanged. Update any saved commands or aliases that referenced the old name.

---

## v0.22.0 — 2026-06-01 — Add acceptance criteria verification gate

### Changed

- **`planning` Step 8 "Implement now"** — added mandatory acceptance criteria gate after all steps are implemented. Each criterion is individually verified against the codebase before being checked off. Unverifiable criteria are flagged to the user; the plan stays `in-progress` unless all criteria are checked.
- **`complete-plan` Step 3** — new sub-step 3b maps implementation evidence to individual acceptance criteria, classifying each as `verified` or `unverified`.
- **`complete-plan` Step 4** — summary now shows per-criterion verification status and offers three completion options: check all, only auto-check verified, or cancel.
- **`complete-plan` Step 5b** — respects the user's Step 4 choice: checks only verified criteria when the user opts to auto-check verified only, and downgrades status to `in-progress` accordingly.
- **`complete-plan` Step 6** — delivery message reflects whether all criteria were verified or some remain open.

---

## v0.21.0 — 2026-06-01 — Add /workflows support for complex plans

### Added

- **Workflow prompt row** — complex plans now include a `<div class="plan-workflow">` element below the implement prompt with a "Run a workflow to implement the plan at …" prompt and copy button. Triggers Claude Code's `/workflows` runtime when pasted, launching parallel subagent orchestration for large-scale implementations.
- **`<meta name="plan-workflow">` tag** — machine-readable workflow prompt in the plan `<head>` for gallery extraction.
- **`copyWorkflow()` JS function** — dedicated clipboard handler for the `<code id="workflow-cmd">` element.
- **Step 8 "Run as workflow" option** — when a workflow prompt was generated, the post-planning prompt offers a fourth choice to launch a dynamic workflow instead of sequential implementation.

### Changed

- **SKILL.md Step 2 (Create)** — now assesses plan complexity to decide whether to generate a `{workflow-prompt}` alongside `{implement-prompt}`. Workflow prompts are generated when plans touch 5+ files across 3+ directories, involve repetitive per-file changes, include parallelizable steps, or require cross-checking.
- **SKILL.md Step 3 (Frontmatter)** — includes `<meta name="plan-workflow">` when a workflow prompt was generated.
- **SKILL.md next-steps** — next-step prompts can now use "Run a workflow to …" prefix for items that benefit from workflow orchestration.
- **SKELETON.html** — added `.plan-workflow` CSS (blue accent), HTML row with `{workflow-prompt}` placeholder, and `copyWorkflow()` JS function. Row is conditionally removed when no workflow prompt is generated.
- **CLAUDE.md** — fixed branch naming example from `add-reinvoke-prompt` to `add-implement-prompt`.

## v0.20.0 — 2026-06-01 — Add complete-plan skill

### Added

- **`/plan-agent:complete-plan [plan-filename.html]`** — new skill (`disable-model-invocation: true`) that reviews an HTML plan for codebase implementation evidence, presents a confirmation summary, then marks all acceptance-criteria checkboxes as checked, adds the `completed` class to every step card, and updates all three status representations (`<html data-status>`, `<meta name="plan-status">`, visible badge) to `completed`.

---

## v0.19.0 — 2026-06-01 — Replace reinvoke prompt with implement prompt

### Changed

- **Plan output** — the copy/paste prompt below the objective now generates an implementation prompt (e.g. `Read and implement all steps in the plan at docs/plans/add-dark-mode-toggle.html`) instead of a re-invoke command that re-runs the planning skill
- **SKELETON.html** — `.plan-reinvoke` CSS/HTML/JS renamed to `.plan-implement` with green accent styling; label changed from "Re-invoke" to "Implement"
- **Meta tag** — `<meta name="plan-reinvoke">` replaced with `<meta name="plan-implement">`
- **SKILL.md** — Steps 2, 3, and HTML Output Requirements updated; `{reinvoke-cmd}` placeholder replaced with `{implement-prompt}`; scope constraint reordered to prioritize `plansDirectory` setting over hardcoded `docs/plans`

## v0.18.2 — 2026-06-01 — Add ExitPlanMode error handling; planning workflow improvements

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success
- Remove auto-commit step from planning skill (step 6 removed)
- Add 'Edit the plan' option to post-planning prompt (step 8)

## v0.18.1 — 2026-06-01 — Fix reinvoke command: strip .html token before objective extraction

### Fixed

- **Argument parser — `.html` plan file detection**: A leading `.html` token (e.g. `add-dark-mode-toggle.html`) is now stripped from `$ARGUMENTS` before the objective is extracted, preventing the filename from polluting the objective when the re-invoke command is pasted verbatim. The stripped value is stored as `$PLAN_FILE`; when no remaining objective text exists, the plan's existing `<title>` tag is used as the objective fallback.

---

## v0.18.0 — 2026-06-01 — Add re-invoke prompt to every generated plan

### Added

- **Re-invoke prompt row** — every generated plan HTML now includes a `<div class="plan-reinvoke">` element immediately below the objective card. Shows the `/plan-agent:planning <filename> <short-objective>` command with a copy button so developers can resume or reference the plan without reconstructing the command.
- **`copyCmd()` JS function** — dedicated clipboard handler for the `<code id="reinvoke-cmd">` element, separate from the existing `copyPrompt()` which targets `<pre>` blocks.
- **`<meta name="plan-reinvoke">` tag** — machine-readable reinvoke command in the plan `<head>` for plans-library gallery extraction.

### Changed

- **`SKILL.md` Step 2 (Create)** — now instructs the model to compute `{reinvoke-cmd}` = `/plan-agent:planning <filename> <short-objective≤60chars>` and fill the skeleton placeholder.
- **`SKILL.md` Step 3 (Frontmatter)** — now requires `<meta name="plan-reinvoke" content="…">` alongside the other required meta tags.
- **`SKILL.md` HTML Output Requirements** — new bullet documents the reinvoke row as a required element.

### UX

- Reinvoke command text soft-wraps (`word-break: break-all`) for long objectives.
- Copy button is hidden via CSS when `data-status="completed"` — no copy affordance for plans that are done.
- Row is suppressed in `@media print`.

---

## v0.17.1 — 2026-06-01 — Minor wording corrections

### Fixed

- `planning` and `plans-library` skills: minor description wording corrections.

---

## v0.17.0 — 2026-05-31 — Add plans-open skill (open gallery without rebuild)

### Added

- **`plans-open` skill** — opens the existing `index.html` gallery directly without scanning plan files, parsing metadata, or writing any files. Resolves `plansDirectory` from settings (same as `plans-library`). If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

---

## v0.16.0 — 2026-05-31 — Fix Step 9 status sync and commit instructions

### Fixed

- **Step 9 `Implement now` — status sync**: Now updates all three status representations together (`<html data-status>`, `<meta name="plan-status">`, and visible badge text), mirroring Step 7's sync rules. Previously only `<meta name="plan-status">` was mentioned.
- **Step 9 `Implement now` — commit instruction**: Now explicitly commits source file changes together with the updated plan file. Previously only the plan file was mentioned, leaving source changes potentially uncommitted.
- **Step 9 `Exit` — state model clarity**: Clarifies that `todo` is the correct terminal state for an unimplemented plan and that no status update is needed on exit, resolving ambiguity with Step 7's `todo → in-progress → completed` progression.

---

## v0.15.0 — 2026-05-31 — Add issue ingestion to /plan-agent:planning

### Added

- **Issue reference detection** — `$ARGUMENTS` is now scanned for a GitHub/GitLab issue URL or bare `#n`/integer before flag parsing. When detected, the reference is stripped from the argument string and stored as `$ISSUE_REF`.
- **Step 0.5 — Issue Ingestion** — New workflow step that fires when `$ISSUE_REF` is set. Runs `gh issue view` (GitHub) or `glab issue view` (GitLab), maps `title` → objective, `body` → context block, `labels` → type hint, `url` → plan frontmatter. Falls back gracefully to plain-objective mode on any CLI error.
- **`<meta name="plan-issue">` tag** — Plans seeded from an issue reference now include the source issue URL in the HTML `<head>` for machine readability by the gallery index and downstream tooling.
- **`argument-hint` updated** — Now reads `<issue-url|#n> | <objective> [flags…]` to expose the new entry point at autocomplete time.

### Example

```
/plan-agent:planning https://github.com/shawn-sandy/agentics/issues/205
/plan-agent:planning #205
/plan-agent:planning #205 focus on the auth layer --quick
```

---

## v0.14.1 — 2026-05-31 — Fix MultiEdit path extraction and bundle build-index.sh

### Fixed

- **P2 — MultiEdit `file_path`**: `file_path` is a top-level key on `tool_input` for all tool types including `MultiEdit`; the previous code incorrectly read it from inside `edits[0]`, causing MultiEdit events to always produce an empty path and exit without rebuilding.
- **P1 — Bundle `build-index.sh` with plugin**: `docs/plans/build-index.sh` is not shipped inside the `plan-agent` plugin directory, so consumer projects that install via the marketplace had no rebuild script and the hook silently exited. Added `hooks/build-index.sh` (identical logic, accepts `PROJECT_ROOT` as `$1`) and updated the hook to prefer the bundled copy via `$CLAUDE_PLUGIN_ROOT`, falling back to a local `build-index.sh` in the plans directory for projects that have it.

---

## v0.14.0 — 2026-05-30 — Add PostToolUse hook to auto-rebuild plans index

### Added

- **`hooks/rebuild-plans-index.py`** — PostToolUse hook that fires on every `Write|Edit` to a non-`index.html` `.html` file inside the configured plans directory. Calls `docs/plans/build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.
- **`docs/plans/build-index.sh`** — self-contained shell entry point that regenerates `docs/plans/index.html` without Claude. Finds the `plans-gallery.html` template via the same plugin-discovery strategy as `plans-library`; falls back to a minimal embedded styled gallery if the template is unavailable.
- Registered `rebuild-plans-index.py` as a second `PostToolUse` entry in `hooks.json` with `Write|Edit` matcher and a 30-second timeout.

## v0.13.0 — 2026-05-31 — Add plans-library skill and gallery template

### Added

- **`plans-library` skill** — scans the configured `plansDirectory`, parses each plan's metadata, and writes a filterable HTML gallery (`index.html`) with status/type chips, title search, and grid/list views. Opened in the browser on completion.
- **`plans-gallery.html` template** — standalone gallery template with versioned cache path, JSON-safe title parsing, and an explicit `GENERATED_AT` timestamp.

### Fixed

- **`plans-library` xargs** — replaced `xargs ls -t` with `xargs -0 ls -t` (null-delimited) to handle plan paths that contain spaces.
- **`plans-library` template discovery** — versioned cached templates are now sorted by version descending (`sort -rV`) before `head -1`, making the selection deterministic when multiple cached versions exist.
- **`planning` Step 0 bootstrap wording** — clarified that the `ToolSearch(select:ExitPlanMode)` preflight runs as part of Step 0 (not before it); removed the contradictory "before any other action" phrase.
- **`planning` preflight echo** — moved the resolved-objective echo to after the Step 0 bootstrap so no user output precedes `ExitPlanMode`.

---

## v0.12.1 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) characters with plain text ("Step N", "Steps N–M") across SKILL.md, README.md, and CHANGELOG.md to fix rendering issues in terminals and markdown viewers.

---

## v0.12.0 — 2026-05-30 — Codebase exploration, Grep, and browser fallback

### Added

- **Step 0b Explore** — new codebase research step after the self-bootstrap and before Clarify. Uses `Glob`, `Grep`, and `Read` to build context on entry points, existing patterns, tests, and configuration before drafting steps. Exploration depth scales with plan scope. Skipped by `--quick`.
- **`Grep`** added to `allowed-tools` — enables first-class codebase symbol and pattern search without permission prompts during exploration and plan drafting.
- **Step 8 browser fallback** — when the browser MCP server is unavailable (headless/web environments), falls back to `SendUserFile` with the file path, ensuring plan delivery always works.

### Changed

- **Description tightened** — first sentence shortened to fit within the ≤80-char guideline.

---

## v0.11.2 — 2026-05-30 — Add scope constraint: plans only, no implementation

### Added

- **Scope Constraint section** — explicit rule block inserted before the Workflow prohibiting the skill from editing source files or applying any change described in the plan's steps. The plan is the deliverable; implementation is a separate, user-initiated step. Addresses a case where the skill implemented a fix rather than writing a plan for it.

---

## v0.11.1 — 2026-05-30 — Fix: self-bootstrap out of harness plan mode

### Fixed

- **Step 0 self-bootstrap** — Added unconditional `ExitPlanMode` call as the first step of the workflow. When the harness enters plan mode on "planning"-keyword commands it forces `.md` output to a random-slug path, overriding the skill's `.html` guarantee. Calling `ExitPlanMode` immediately exits harness plan mode so the skill writes directly to disk as designed. Root cause: v0.8.0 removed `ExitPlanMode` from `allowed-tools` but left no escape hatch for harness-triggered plan mode.
- **`allowed-tools`**: added `ExitPlanMode`, `WebFetch`, `WebSearch`, `SendUserFile`.

---

## v0.11.0 — 2026-05-30 — Add plans-library skill and web research tools

### Added

- **`plans-library` skill** — scans every HTML plan in the plans directory, parses `<meta>` tags (`plan-status`, `plan-type`, `plan-created`) and `<title>`, populates a gallery template, writes `docs/plans/index.html`, and opens it in the browser. Filterable by status (todo / in-progress / completed) and type (feature / fix / refactor / docs / chore) with a title search box. Excludes `index.html` and `archive/` subdirectory.
- **`templates/plans-gallery.html`** — self-contained gallery template (no external CSS/JS/CDN) with light theme; grid and list views; client-side filtering.
- **`WebFetch`, `WebSearch`, `SendUserFile`** added to `allowed-tools` — enables research during Clarify (verifying APIs, checking library versions) and delivers the finished plan file to the user in Step 8 Open.

---

## v0.10.0 — 2026-05-30 — Add built-in structured interview step

### Added

- **Step 5b Interview** — new standard workflow step between Align and Commit. Analyzes plan content to classify complexity (short/medium/complex), detects UI signals, then runs 1–3 interview rounds via `AskUserQuestion` with dynamically generated questions. Round 1 (Technical & Trade-offs) always runs; Round 2a (UI/UX) and 2b (Accessibility) run for medium+ plans or when UI signals are detected; Round 3 (Edge Cases) runs for complex plans only. Post-interview summary offers to update the plan HTML before committing.
- **`--no-interview` flag** — skips Step 5b Interview for pre-validated or time-critical plans.

### Changed

- **`--quick` expanded** — now shorthand for `--no-clarify --no-align --no-interview` (previously only `--no-clarify --no-align`).

### Removed

- **`--interview` flag** — the external delegation to `plan-interview:plan-interview` after Step 8 is replaced by the built-in Step 5b step. The `plan-interview` plugin remains available as a standalone deep-interview tool.

---

## v0.9.0 — 2026-05-30 — Add mandatory Step 8 Open step with browser verification

### Added

- **Step 8 Open** — new mandatory final workflow step that opens the committed plan in a browser to confirm it renders correctly. Steps: find a free port via `python3 -c "import socket…"`, start `python3 -m http.server <port>` in the background from the plan's parent directory, load browser tools via `ToolSearch`, navigate to `http://localhost:<port>/<plan-filename>`, take and send a screenshot, report the URL to the user, and leave the server running. Cannot be skipped.
- **`allowed-tools` expanded** — added `ToolSearch`, `mcp__claude-in-chrome__tabs_context_mcp`, `mcp__claude-in-chrome__tabs_create_mcp`, `mcp__claude-in-chrome__navigate`, and `mcp__claude-in-chrome__computer` so browser automation tools are pre-approved and never prompt mid-run.

---

## v0.8.0 — 2026-05-30 — Remove plan-mode handshake; tighten skill consistency

### Changed

- **Remove `EnterPlanMode`/`ExitPlanMode` handshake** — the skill now writes its HTML plan file directly instead of entering harness plan mode, restoring its two output guarantees: `verb-target` kebab-case filename and self-contained `.html` output. Root cause: `EnterPlanMode` handed control to the harness, which forced markdown to a random-slug path, contradicting the skill's own "no plan mode for write operations" rule.
- **`--template` flag**: trimmed to `default` only in `argument-hint`; `minimal`, `adr`, and `spike` are documented as planned but not yet implemented.
- **Skeleton variants deleted**: `reference/SKELETON-minimal.md`, `reference/SKELETON-adr.md`, `reference/SKELETON-spike.md` removed — they were markdown files and violated the "always write HTML" rule. `reference/SKELETON.html` remains the sole supported skeleton.
- **`allowed-tools`** pruned: `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, `TodoWrite`, and `Grep` removed (dead weight after plan-mode removal or unreferenced in body).
- **Heading hierarchy**: body H1 (`# Plan Agent — Planning`) lowered to H2.
- **Freedom level**: `## Workflow` opens with "Follow these steps exactly." to prevent guardrail-skipping on a process-critical sequential skill.
- **Frontmatter description**: rewritten with capability statement, user-intent trigger, and scope-exclusion sentence (≤1024 chars, third person).
- **`$ARGUMENTS` clarifying note**: added to `Invocation & Arguments` explaining why this command-only construct is valid here.

---

## v0.7.1 — README: correct --template flag docs; fix planAgent.extraFrontmatter key

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 0.7.0 — 2026-05-29

### Added

- **Copy prompt buttons**: each `<pre>` prompt block in the Next Steps (including Wish List items) and Unresolved Questions sections now has a "Copy prompt" button. Clicking copies the prompt text to the clipboard; the button shows "Copied ✓" for 2 seconds then reverts. Uses the Clipboard API with a textarea fallback for `file://` protocol. Hidden in print.
- `copyPrompt` global JS function added to `SKELETON.html` (outside the IIFE so inline `onclick` handlers can resolve it).
- `.copy-prompt-btn` CSS class: blue-accent pill matching the document design tokens; green `.copied` state mirrors existing completion colours.
- SKILL.md updated to mandate copy buttons on every prompt `<pre>` in generated plans and to warn against removing them when filling placeholders.

---

## 0.6.0 — 2026-05-29

### Added

- **Sticky sidebar navigation**: two-column layout (200px sidebar + content) with "On this page" section links; collapses to single-column on narrow viewports.
- **Scroll rail**: animated 3px progress indicator on the left edge of the sidebar tracks page scroll position in real time.
- **Scroll spy**: `IntersectionObserver`-powered active link highlighting (left-border indicator) in the sidebar as sections enter the viewport.
- **CSS step timeline**: vertical connector line with circle nodes on each step card; nodes turn green when all criteria are checked (via CSS `.step-card.completed`).
- **Step chips**: `<span class="step-chip">todo</span>` decorates each step action with a pill badge; turns green when the step card is marked complete.
- **localStorage persistence**: acceptance-criteria checkbox state saved to `localStorage` keyed by page title — survives page refresh.
- **Print styles**: sidebar, scroll rail, and step chips hidden in print; single-column layout.
- **Inline SVG icons**: Heroicons `<symbol>`/`<use>` pattern replaces emoji; zero external dependencies.
- **Pulsing in-progress dot**: status badge dot pulses when `data-status="in-progress"`; respects `prefers-reduced-motion`.
- **Accessibility baseline**: skip link, `aria-labelledby` on every section, `role="progressbar"` attributes, `aria-live="polite"` region for criteria announcements, `min-height: 44px` touch targets on nav links.
- **Tone guidance in SKILL.md**: writing-style addendum encouraging rallying-statement objectives and imperative-verb step actions.

### Changed

- `SKELETON.html`: professional document aesthetic — white page, white header with a single 3px blue accent stripe, "Implementation Plan" doc-type label above the plan title.
- Sections rendered as flat ruled document sections separated by `border-top` lines (no card shadows or rounded corners).
- `<div class="section-card">` elements converted to `<section>` with `id` and `aria-labelledby` for improved semantics.
- Step number badges simplified to a plain grey circle (no gradient).
- Criteria items styled as individual bordered rows.
- Progress bar thinned to 6px with a solid blue fill.
- `--radius: 4px` throughout for a sharper document feel.

---

## 0.5.0 — 2026-05-28

### Added

- **HTML output** (default): the `planning` skill now writes every plan as a self-contained `.html` file — no markdown, no external dependencies.
  - Rich layout: status badge, objective highlight card, numbered step cards with expandable *Verify* disclosures, interactive acceptance-criteria checkboxes with live progress bar, collapsible Next Steps and Unresolved Questions sections.
  - **Wish List subsection**: blue-sky / visionary ideas in `next-steps` are automatically labelled `🔭 Wish List` and rendered with a distinct dashed-border, muted-colour treatment so they read as non-committal aspirations.
  - Plan metadata stored in `<meta>` tags (`plan-status`, `plan-type`, `plan-created`, `plan-repo`) for machine readability.
  - Minimal inline JavaScript (progress bar on checkbox change); fully functional without JS.
- `reference/SKELETON.html`: new bundled HTML plan template replacing `SKELETON.md` — all required sections pre-wired with placeholders in `{curly braces}`.

### Changed

- **Step 2 Create**: plan filename extension changed from `.md` to `.html`.
- **Step 3 Frontmatter**: metadata now stored in HTML `<meta>` tags instead of YAML frontmatter.
- **Step 7 Status**: status updates now edit `<html data-status="…">` and the badge element instead of YAML.
- `validate-plan-filename.py` hook updated to accept both `.html` (primary) and `.md` (legacy) plan files; `_is_completed` now reads `<meta name="plan-status" content="completed">` for HTML files.

### Fixed (in this release)

- Status `<html data-status="…">` attribute is on the `<html>` element (not `<body>`); SKILL.md Step 7 and CHANGELOG wording corrected to match the skeleton.
- SKILL.md Step 7 now instructs updating **both** `<html data-status>` and `<meta name="plan-status">` so CSS badge colour and the hook's completion check stay in sync.
- SKILL.md Step 3 no longer mentions a redundant `<script type="application/json" id="plan-meta">` block; `<meta>` tags are the sole metadata channel.
- SKELETON.html `<ul class="next-steps-list">` changed to `<div>` — `<details>` and `<div>` are not valid `<ul>` children per HTML spec.
- SKILL.md HTML Output Requirements now mandates HTML-escaping all user-supplied placeholder values (`&`, `<`, `>`, `"`, `'`).
- SKILL.md frontmatter description updated from "plan-mode frontmatter" to "HTML metadata".
- SKILL.md Step 7 cross-plugin note clarifies that `plan-interview:plan-status` operates on `.md`/YAML only and should not be used for HTML plans until updated.
- README.md updated to reflect HTML output, `SKELETON.html`, `.html` hook firing, and HTML metadata (replacing YAML frontmatter references).

---

## 0.3.0 — 2026-05-28

### Added

- **Hook extensibility** — `validate-plan-filename.py` now reads `planAgent.additionalVerbs`, `planAgent.additionalStopWords`, and `planAgent.additionalPlaceholders` from `.claude/settings.json` (project first, then global). Domain-specific verbs and custom extensions can be merged with the hardcoded sets without editing the Python source.
- **Plan templates** (`--template default|minimal|adr|spike`) — three new skeleton variants: `SKELETON-minimal.md` (Context + Steps + Criteria only), `SKELETON-adr.md` (Architecture Decision Record), `SKELETON-spike.md` (time-boxed investigation). Template selected at Step 2 Create.
- **`--no-clarify` flag** — skips Step 1 Clarify independently of Step 5 Align.
- **`--no-align` flag** — skips Step 5 Align independently of Step 1 Clarify.
- **`--priority` flag** (`low|medium|high|critical`) — writes `priority:` to plan frontmatter without requiring settings config.
- **`planAgent.extraFrontmatter` config** — project or global `.claude/settings.json` can inject arbitrary key-value pairs (e.g. `team`, `milestone`) into every plan's YAML frontmatter after the standard fields.

### Changed (non-breaking)

- `--quick` is now purely opt-in. The previous heuristic that auto-applied `--quick` for objectives ≥ 8 words with concrete names has been removed. `--quick` is documented as shorthand for `--no-clarify --no-align`.
- `argument-hint` updated to include all new flags.
- `classify_filename()` signature now accepts optional `verbs`, `stop_words`, and `placeholders` parameters (all default to module-level constants — backwards-compatible).

## 0.2.0 — 2026-05-27

### Changed (BREAKING)

- **Plugin renamed** `plan-mode` → `plan-agent`. Install id is now `plan-agent@agentics-kit`.
- **Skill renamed** `authoring-plans` → `author`. Explicit invocation is now `/plan-agent:author <objective>`.
- **Activation model changed**: `author` skill is now manual-invoke only (`disable-model-invocation: true`). It no longer auto-activates on planning intent — use `/plan-agent:author` explicitly.

### Added

- `$ARGUMENTS` parsing: reads a free-text objective plus flags (`--quick`, `--type`, `--dir`, `--interview`) from the invocation line.
- Smart `--type` inference from the leading verb of the objective when the flag is absent.
- Smart `--quick` inference for detailed, specific objectives.
- `EnterPlanMode` entry — the skill flips the session into real plan mode on invocation.
- `EnterPlanMode` added to `allowed-tools`.
- `--interview` flag: after the plan is written, optionally runs `plan-interview:plan-interview` before `ExitPlanMode`.

### Unchanged

- `validate-plan-filename` hook — logic, exit codes, and `hooks.json` registration are identical. Only the stderr citation was updated to reference `plan-agent` `/plan-agent:author`.
- Full Steps 0–7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full Steps 0–7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
