# How do I... plan-agent

Authoring, reviewing, implementing, and publishing implementation plans — from a vague idea through a rendered HTML plan to a shipped PR.

Install: `/plugin install plan-agent@agentics-kit`

## build

Implements a plan file that already exists.

- **Command** — `/plan-agent:build [<plan.md|plan.html>] [<objective>] [--type feature|fix|refactor|docs|chore] [--dir <path>]`
- **Say it instead** — "implement the plan in docs/plans/add-dark-mode.md"
- **What happens** — Resolves the plan (with no path it first chains into authoring one), sets `status: in-progress`, walks each step ticking the markdown spec and re-rendering the HTML, then runs the acceptance-criteria, end-to-end verification, and completion checklist gates.
- **Watch out** — The markdown spec is the source of truth: ticking a box in the browser is discarded on the next re-render, and the skill leaves everything uncommitted unless you ask it to commit.

## build-feature

Turns a committed feature idea into a team feature doc that splits into sub-feature plans.

- **Command** — `/plan-agent:build-feature <feature idea> [--dir <path>] [--tier 0|1|2]`
- **Say it instead** — "write a feature doc for bulk export and break it into plans"
- **What happens** — Frames the feature, confirms the ask, researches web and codebase in parallel, then writes `docs/features/<slug>.md` in place each round; at convergence it also writes one saved prompt per sub-feature under the prompts directory.
- **Watch out** — Tier 0 (already plan-sized) writes no artifact at all and just hands you the `/plan-agent:implementation-plan` command; the skill never writes code or the plans themselves, even when the request bundles the feature doc with building it.

## build-fleet

Ships a backlog of plans in parallel, one isolated worktree agent per plan.

- **Command** — `/plan-agent:build-fleet [<plan.md> ...] [--dir <path>] [--max N]`
- **Say it instead** — "implement all my todo plans in parallel"
- **What happens** — Collects `status: todo` specs (or the paths you name), makes you pick the fleet in a multi-select, then dispatches one background worktree agent per plan running `build` then `git-agent:ship-autonomous`, and reports a verified table of branches and PRs.
- **Watch out** — `--max` defaults to 3, a dirty working tree stops the run, and the fleet deliberately ends at green PRs — merging is yours via `/git-agent:merge`.

## build-proposal

Turns a vague idea into a decision-complete proposal that answers should-we.

- **Command** — `/plan-agent:build-proposal <idea> [--dir <path>] [--tier 0|1|2]`
- **Say it instead** — "should we adopt a DESIGN.md convention? think it through with me"
- **What happens** — Runs a human-steered loop — frame, confirm, research, split facts from decisions, resolve them with you — converging on one living saved prompt at `<prompts-dir>/proposal-<slug>.md` that is copy-pasteable into the planning layer.
- **Watch out** — Tier 0 ideas write no file by design (downstream `build` depends on that), and the skill stops at the proposal even when the request also asks to build: it never writes code or the implementation plan without your explicit go-ahead.

## deep-grill

Stress-tests a plan's decisions node by node with focused questions.

- **Command** — `/plan-agent:deep-grill [plan-file-path]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Resolves the plan (argument, open IDE file, `plansDirectory`, then `docs/plans/*.md`), extracts decision nodes into branches, asks a focused question per node with a recommended answer backed by codebase exploration, and ends with a summary of decisions, open questions, and recommended amendments.
- **Watch out** — It targets implementation plans only — pointed at a `SKILL.md` it stops — and it produces a summary, not edits to the plan.

## design

Publishes a design canvas for a plan, so it can be seen before it is built.

- **Command** — `/plan-agent:design <plan.html | one-line idea | image path | figma-url>`
- **Say it instead** — "design this plan" / "mock up the screens for this plan"
- **What happens** — Derives one artboard per user-facing plan step, echoes the list back for correction, then hands authoring and publishing to Claude Code's built-in `design` skill. Working artboards land under `docs/designs/<plan-slug>/`, and the published canvas URL plus that directory are written back as `design:` and `design-dir:` so the plan header gains a **View design** link and `build` reads the artboards as the visual spec.
- **Watch out** — Steps with no user-facing surface (a version bump, a test file) get no artboard by design, and the drift check never flags them; it also never compares your local artboards against the published canvas, so editing the canvas in the editor is expected, not drift. A plan with no UI signals warns in one line and proceeds rather than refusing.

## documenting-plans

Generates a prose reference doc from a completed plan.

- **Command** — `/plan-agent:documenting-plans [plan-file-path]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Parses the plan, resolves its file tokens to real paths, reads their exported surface plus a capped `git log`, then writes an evidence-backed `docs/<slug>.md` (offering Overwrite / Refresh / Cancel if it already exists).
- **Watch out** — Hard gate: the plan must be `status: completed` **and** 30+ days old, so run `plan-status` first.

## finalize-plan

Marks a plan completed after verifying the code actually shipped.

- **Command** — `/plan-agent:finalize-plan [plan-file.md|.html] [--all] [--dir <path>]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Scores codebase evidence per acceptance criterion, runs the objective-verification test, shows a findings table for confirmation, then writes `status`, `- [x]` criteria, step markers, and a `## Completion Report` into the spec and re-renders the HTML; `--all` sweeps every unmarked plan.
- **Watch out** — A phased spec with any unmarked step stays `in-progress` rather than completing, and the skill never commits, pushes, or implements.

## implementation-plan

Generates a self-contained HTML implementation plan from an objective, issue, or markdown source.

- **Command** — `/plan-agent:implementation-plan <issue-url|#n> | <plan.md> | <objective> [--file] [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--tdd|--no-tdd] [--from-prompt <path>] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]`
- **Say it instead** — "create an HTML plan for adding a dark mode toggle"
- **What happens** — Clarifies, aligns, and interviews (unless flagged off), authors a small markdown spec in the plans directory, renders it into the scratchpad, and publishes it as a claude.ai artifact — writing the returned URL back into the spec as `artifact-url:` and rebuilding the gallery so the card appears. The repo keeps the `.md` spec and no generated HTML; pass `--file` to also write and commit `<stem>.html` beside the spec and get both files back via `SendUserFile`.
- **Watch out** — Re-delivering a plan republishes to the same URL (Step 7 re-reads `artifact-url:` first), so never hand-edit either the rendered HTML or that key — every change is a spec edit plus a re-render. If `Artifact` is unavailable the skill says so and falls back to file delivery. The plan is the deliverable: even a request that bundles planning with building ("plan X and build it") ends at the delivered plan; implementation waits for your explicit approval (Step 8's `Implement now`).

## markdown-to-html

Converts any markdown file into a rich, self-contained HTML page.

- **Command** — `/plan-agent:markdown-to-html [file-path] [--theme=default|developer|document|minimal] [--mode=auto|plan|doc] [--background] [--no-open] [--async] [--list-themes]`
- **Say it instead** — "convert docs/plans/add-auth.md to HTML"
- **What happens** — Auto-detects plan mode versus doc mode, applies the chosen theme, and writes `<basename>.html` beside the source with inline styles and scripts, then offers to open it in the browser.
- **Watch out** — The source must be a `.md`/`.markdown` file inside the workspace (paths are `realpath`-checked); use `--background` or `--no-open` for batch runs that must not prompt.

## plan-status

Writes lifecycle status and type into a plan's YAML frontmatter.

- **Command** — `/plan-agent:plan-status [plan-file-path | directory] [--all] [--force]`
- **Say it instead** — "check whether this plan has been implemented and update its status"
- **What happens** — Pulls created/modified dates from `git log`, scores inline backtick tokens against the codebase into `todo` / `in-progress` / `completed`, classifies the type when completed, then asks before writing `status`, `type`, `created`, and `modified` — leaving all other frontmatter untouched.
- **Watch out** — It judges whether a plan shipped, not whether it is any good — use `review-plan` for that — and it writes nothing without your confirmation.

## plans-library

Builds and opens a filterable HTML gallery of every plan in the plans directory.

- **Command** — `/plan-agent:plans-library`
- **Say it instead** — "show me my plans gallery"
- **What happens** — Runs `plan-agent-plans-index` to write `index.html` in the resolved plans directory (in-progress first, then newest by `plan-created`), verifies the card count matches, and opens it in the browser. A `.md` spec with an `http(s)` `artifact-url:` and no sibling `.html` is carded by its artifact URL in a new tab, so plans published straight to claude.ai still appear.
- **Watch out** — `archive/` and `artifacts/` are excluded by design; a sibling `.html` always wins its stem over the artifact card. With nothing the gallery can link it leaves any existing `index.html` alone and points you at `/plan-agent:implementation-plan`.

## plans-open

Opens the existing plans gallery without rebuilding it.

- **Command** — `/plan-agent:plans-open`
- **Say it instead** — "reopen the plans gallery"
- **What happens** — Resolves the plans directory from `plansDirectory` (falling back to `docs/plans`) and opens `index.html` directly — no scanning, no writes.
- **Watch out** — If `index.html` does not exist yet it stops and tells you to run `/plan-agent:plans-library` first.

## prompt

Builds a structured AI prompt using Anthropic techniques and saves it.

- **Command** — `/plan-agent:prompt [intent or topic] [--out <path>] [--answers-gathered]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Classifies the prompt as system, task, creative, or analytical, applies that type's technique matrix, interviews you for the missing pieces, and writes the finished prompt to `--out` or the resolved prompts directory (`promptsDirectory`, else `docs/prompts`).
- **Watch out** — The fifth type, `proposal`, is reserved for `build-proposal` calling in with `--answers-gathered` and is never offered in the menu.

## prototype

Generates a runnable static-HTML prototype from a plan, idea, image, or Figma design.

- **Command** — `/plan-agent:prototype <plan.html | one-line idea>`
- **Say it instead** — "make a clickable prototype of this plan"
- **What happens** — Derives a deterministic data model (entity, typed fields, action, success signal), echoes it back for correction, then fills the bundled skeleton into one self-contained file under `docs/prototypes/` — inline CSS, vanilla JS, seed JSON, localStorage store, no build step.
- **Watch out** — An image input is read directly, but a Figma URL needs the Figma MCP server connected; without it the skill asks for a screenshot rather than guessing.

## publish-hub

Bundles a plan and its related HTML into one tabbed hub artifact at a stable URL.

- **Command** — `/plan-agent:publish-hub <plan.md> [--extra <path>]...` — omit the plan to pick from the plans directory
- **Say it instead** — "publish this plan and its prototype as one page"
- **What happens** — Runs `plan-agent-hub` to render the plan and embed each related document — the `prototype:` file, any `--extra` pages, `design:` as an external-link tab — in its own tab panel, publishes the bundle with `Artifact`, writes the returned URL back as `hub-artifact-url:`, then fetches the page to confirm the plan title actually rendered before reporting the link and its tabs.
- **Watch out** — Related files come only from the spec's `prototype:`/`design:` keys and explicit `--extra` paths, never from scanning the directory. The hub is a second artifact: the plan's own `artifact-url:` is never touched. Output is capped at 15 MB — on overflow the bundler names the largest embedded document so you can rerun with `--skip`, and when that is the plan itself there is nothing to drop.

## review-plan

Runs a plan-review Agent Team over an HTML plan and applies the improvements in place.

- **Command** — `/plan-agent:review-plan [plan.html] [--dir <path>]` (background variant: `/plan-agent:review-plan-bg <plan path>`)
- **Say it instead** — "review and improve this implementation plan"
- **What happens** — Spawns seven core reviewers (architecture, completeness, testability, risk, conventions, product, security) plus three UI-conditional ones (UX, accessibility, frontend) when UI signals are detected, synthesizes the findings, and edits the markdown spec then re-renders — or the HTML directly for legacy plans.
- **Watch out** — Hard-stops without Agent Teams: it needs Claude Code 2.1.32+ and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. It reviews plans, not code.

## setup-sites

Scaffolds GitHub Pages publishing into the current repo so `docs/` HTML reaches a public URL.

- **Command** — `/plan-agent:setup-sites`
- **Say it instead** — "set up GitHub Pages so my plans gallery is published"
- **What happens** — Preflights the git remote and `plansDirectory`, then idempotently writes four artifacts — the path-filtered Actions workflow, `.nojekyll`, `serve-docs.sh`, and a hub page — verifies them, and reports the live URL plus a created/skipped tally.
- **Watch out** — It never clobbers existing files and never commits or pushes; enabling Settings → Pages → Source = GitHub Actions is a one-time step it offers to do via `gh` or prints for you.

## Related commands

- `/plan-agent:fix <objective> [--dir <path>]` — the `build` chain typed as a fix; prepends `--type fix` so your own `--type` still wins.
- `/plan-agent:refactor <objective> [--dir <path>]` — the `build` chain typed as a refactor, same prepend rule.
- `/plan-agent:plan-maintenance [--archive] [--index] [--variants] [--all] [--background]` — archives completed plans (30+ days) as HTML under `docs/archive/<type>/`, regenerates the plans `README.md` index, and reviews variant/duplicate files, with a confirmation gate per sub-workflow.
