---
type: proposal
intent: Build an opt-in git-agent-launcher mod, a pane that lists git-agent's skills and commands and fills the chosen one into the prompt, as the first of a set of mods that help users integrate the kit plugins.
techniques: Long-context grounding, XML structure, Comparison tables, Positive framing, Output format
created: 2026-10-09
status: converged
modified: 2026-10-09
generated-sha: a6ecef0ad2735d78a929164f27e912571eea4181c27b596182e7f28b31244569
---

# Proposal: Add Git Agent Launcher Mod

> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.

<tldr>
- Ship `kit/plugins/git-agent-launcher`, a Claude Code mod: `/git-agent-launcher` opens a pane listing every git-agent skill and command; pressing one fills `/git-agent:<name> ` into the prompt, and Enter runs it.
- Discovery is dynamic: `$.command.list()` filtered on `plugin === 'git-agent'`. No hard-coded list, so new git-agent skills appear without a launcher release.
- It is the first of a set of mods, one plugin per mod. Repo-aware "next step", a kit-wide launcher, and a plans pane are follow-on candidates, each its own proposal.
- The mod is small. The real work is repo tooling: no step runs `claude plugin validate`/`claude plugin test`, `build-dist.mjs` drops a top-level `types/`, and `build-readme-table.mjs` cannot see `hooks/hooks.json`.
- Phase 0 spike gates three unverified mechanics: `$.prompt.fill` in the Desktop Code tab, keyboard focus after a fill, and the `CommandInfo.name` format for plugin skills.
</tldr>

<context>
**The idea.** Help users integrate the kit plugins into their projects with a set of mods. The first one shows git-agent's skills so a user can trigger them with a click instead of remembering and typing `/git-agent:<name>`.

**What exists today.**

- git-agent 4.23.0 (`.claude-plugin/marketplace.json`, category `development`) exposes 13 slash entries: 8 skills under `kit/plugins/git-agent/skills/` (branch-agent, commit-agent, create-issue, merge, post-merge-cleanup, pr-agent, ship, ship-autonomous) and 5 commands under `commands/` (commit-bg, merge-bg, pr-bg, ship-bg, ship-ci-bg). Users type them; the typeahead lists them with descriptions. Inventory in Appendix A.
- Since 4.23.0 `commit-agent` commits and pushes without asking (commit 052d88c2). `pr-agent` pushes and opens a PR with no in-flow question. A one-click trigger therefore has outward consequences.
- Mods are Claude Code plugins whose `hooks/hooks.json` names a hooks module (`{ "modules": ["./register.tsx"] }`) exporting `register(on, options)`. They are on by default from Claude Code 2.1.287 in the terminal and 2.1.286 in the Desktop Code tab. They draw panes and the band above the prompt in the terminal and Desktop; in the VS Code chat panel, `claude -p`, and cloud sessions their hooks run but nothing draws. Mods are unsandboxed and run with the user's permissions (code.claude.com/docs/en/plugins/mods/overview).
- A mod installs like any plugin from a marketplace, and one plugin may hold a mod alongside skills and MCP servers.
- In this repo: no plugin in `kit/plugins/` uses `hooks/hooks.json` (git-agent, plan-agent, skill-reviewer point `plugin.json` `"hooks"` at a root `hooks.json`), and no doc mentions mods. The marketplace floor is "Claude Code 1.0.33+" (`CLAUDE.md:26`, `README.md:7`, `README.md:98`).
</context>

<finding>
Every piece a git-agent launcher needs is already an engine primitive — `$.command.list()` returns git-agent's 13 slash entries with their frontmatter descriptions and `plugin` name, a `Pane` draws them as `Button`s on both terminal and Desktop, and `$.prompt.fill` stages the chosen one in the prompt — so the mod is a thin view over a list that already exists, and its real costs sit in this repo's tooling, not in the mod.
</finding>

<comparison>
| Dimension | Standalone git-agent mod (chosen) | Standalone kit-wide launcher | Embed inside git-agent | Keep the current approach |
|---|---|---|---|---|
| Install step for users | One extra `/plugin install` | One extra `/plugin install` | None | None |
| Entries shown | 13 | 87 (67 skills + 20 commands across 12 plugins) | 13 | 13, via typeahead |
| Claude Code floor | 2.1.287 for this plugin only | 2.1.287 for this plugin only | Raises git-agent's floor for all its users | Unchanged (1.0.33) |
| Turn the launcher off alone | Disable this plugin | Disable this plugin | Only by disabling git-agent and its skills | n/a |
| Version churn from an early-access API | Own version line | Own version line | Every mod change bumps git-agent | None |
| Unverified mechanics | Fill on Desktop, focus after fill, name format | Same, plus grouping 87 entries | Same, plus `plugin.json` `"hooks": "./hooks.json"` vs required `hooks/hooks.json` | None |
| Widening to other plugins later | Change one filter | Already wide | Wrong home for non-git entries | n/a |
| Size | S–M | M | S plus path risk | 0 |

Correction to the option text shown at the approach gate: `disableAllHooks` already stops git-agent's three settings hooks today, so embedding adds no new coupling there. The real embed cost is that the launcher cannot be turned off without disabling git-agent.
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:
1. **Approach: standalone git-agent mod.** Chosen 2026-10-09 over a standalone kit-wide launcher, embedding inside git-agent, and keeping the typed commands, because it keeps the 2.1.287 floor and early-access API churn away from git-agent's users, lets users turn the launcher off alone, and widening it later is a one-line filter change.

Settled before this draft (repo rules and research):

2. **`version` lives only in `.claude-plugin/marketplace.json`.** `plugin.json` carries no `version`, so the plugin-authoring template's `"version": "0.1.0"` is dropped. The marketplace entry starts at `0.1.0`.
3. **Homepage** is `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/git-agent-launcher`; marketplace `category` is `development`, matching git-agent.
4. **Every mod file lives under `hooks/`.** `scripts/build-dist.mjs` keeps `hooks/` and silently drops any other top-level directory (keep list L27-41), so a top-level `types/` would vanish from dist. The mod uses no `$.state`, so it needs no `types/` contract at all.
5. **The mod reads nothing beyond the command list and the prompt box.** Its `claude plugin validate` report must list only the calls in Appendix B. No `$.fs`, `$.process`, `$.http`, or `$.model`.

Resolved in the 2026-10-09 review:

6. **Click action: fill the prompt.** Pressing an entry calls `$.prompt.fill` with `/git-agent:<name> ` followed by any existing draft (Appendix C); Enter runs it. Chosen over run-on-click and run-after-a-second-press because args can be typed, a misclick never commits and pushes, and no confirm state machine is needed. Propagates to: Workstream A (fill contract, `isFilled: false` fallback), Risks (Desktop fill, focus), Phase 0.
7. **Surface: a pane opened by a registered command.** `command.run` calls `$.ui.open({ id, title, focus: true, closeOnEscape: true })`. Not auto-opened, no band. Chosen over the shared band (every mod shares it; a tree replaces later mods' drawings) and an auto-opened pane (only placed from 144 columns). Because the user asks for it, the pane places at any width.
8. **v1 is a static list with no repo state.** No `git status` or `gh pr view`. A repo-aware "next step" becomes a later mod (Roadmap Phase 4).
9. **One plugin per mod.** The launcher is `kit/plugins/git-agent-launcher`; future mods are sibling plugins, each opt-in and each with its own `claude plugin validate` report for trust review. Chosen over one umbrella `kit-mods` plugin.
</decisions>

<workstreams>
### A — The mod (`kit/plugins/git-agent-launcher/`)

Files:

- `.claude-plugin/plugin.json`: `name`, `description`, `author`, `license`, `keywords`, `homepage`, `repository`. No `version`.
- `hooks/hooks.json`: `{ "modules": ["./register.tsx"] }`.
- `hooks/register.tsx`: the hooks module.
- `hooks/register.test.ts`: tests (Workstream B).
- `README.md`, `CHANGELOG.md`.

Behaviour:

- `session.start`: `$.command.register({ name: 'git-agent-launcher', description: 'Open a pane of git-agent skills and commands' })`. Register last in the hook, or wrap it in `try`, because a taken name throws and a throwing hook is skipped.
- `command.run` on `{ command: 'git-agent-launcher' }`: `$.ui.open(...)` per decision 7, then return `{}`. When `isPlaced` is false (no drawing surface, such as the VS Code chat panel or `-p`), return `{ text }` listing each `/git-agent:<name>` with its description instead.
- `ui.render` on `{ component: 'Pane' }` with `e.requestId` equal to the pane id:
  - Read `$.command.list()` and keep the entries where `plugin === 'git-agent'`, in the order the list returns them (the typeahead order). No ordering table.
  - Draw one row per entry: a plain `Button` (label = the name without the `git-agent:` prefix; digit hotkeys `1`-`9` on the first nine) and a dim `Text` with the description, wrapped to `e.props.bodyColumns`.
  - Empty state, when git-agent is not installed: a line naming the install command `/plugin install git-agent@agentics-kit`.
- `onPress`: `const { text } = await $.prompt.read()`, then `$.prompt.fill({ text: '/' + name + ' ' + text, mode: 'replace' })`. On `isFilled: false`, `$.ui.toast('Type /' + name + ' in the prompt')`. Close the pane after a successful fill if Phase 0 shows focus stays in the pane.

### B — Tests (`hooks/register.test.ts`, `claude plugin test`)

Each test loops over `['terminal', 'desktop'] as const`. The test's own hooks answer `command.list` and `prompt.fill`/`prompt.read` beneath the plugin. Cases, each failing if the behaviour regresses:

- Only `plugin === 'git-agent'` entries render; another plugin's entry in the mocked list does not.
- Pressing `commit-agent` with an empty draft fills exactly `/git-agent:commit-agent `.
- Pressing `commit-bg` with draft `fix typo in readme` fills `/git-agent:commit-bg fix typo in readme`, so the draft is kept.
- `isFilled: false` raises a toast naming the command.
- A list with no git-agent entries draws the install line.
- `command.run` with `isPlaced: false` returns text listing every git-agent entry.

### C — Repo tooling

- `scripts/verify.sh`: for each `kit/plugins/*/hooks/hooks.json` holding `modules`, run `claude plugin validate --strict <dir>` and `claude plugin test <dir>`. Print `SKIP (claude < 2.1.287)` when the CLI is absent or older, and treat that line as a skip, not a pass.
- `scripts/build-readme-table.mjs` (L34-40 reads only a root `hooks.json`): count a `hooks/hooks.json` `modules` entry as a component (`mod`), so the Plugin Reference Table does not show "none".
- Marketplace entry (copied from an existing entry, `source.path` `kit/plugins/git-agent-launcher`, `version` `0.1.0`, `category` `development`, specific tags such as `mod`, `launcher`, `pane`, `git-agent`), then re-run `node scripts/build-readme-table.mjs`.
- `.github/workflows` stay as they are. Runners have no `claude` CLI, so mod checks are local-only under the merge gate.

### D — Docs

- Plugin `README.md`: what it does, the requirements (Claude Code 2.1.287+ in the terminal, 2.1.286+ in Desktop; git-agent installed), the install command `/plugin install git-agent-launcher@agentics-kit`, where it draws and where it does not, and the expected `claude plugin validate` output (Appendix B) for trust review.
- Root `CHANGELOG.md`, `kit/plugins/README.md`, README `## Plugins` section, and `docs/guides/how-to/git-agent-launcher.md` (via the `docs-sync` skill where it covers them).
- Note in `CLAUDE.md` and `README.md` beside "1.0.33+" that mod plugins need 2.1.287+.
</workstreams>

<risks>
- **`$.prompt.fill` may not reach the Desktop prompt box.** Desktop runs the engine for a separate client, and `$.prompt.read()` documents `{ text: '', cursor: 0 }` "where the session draws no box". If Phase 0 shows `isFilled: false` on Desktop, fall back there to `$.ui.copy({ text, surface: e.surface })` plus a toast. If that is unacceptable, revisit decision 6 for Desktop only.
- **Focus after a fill.** A pane opened with `focus: true` holds the keyboard, so Enter may press the focused `Button` again instead of submitting the prompt. Mitigation: close the pane on a successful fill (`closeOnEscape` dialog semantics). Phase 0 decides.
- **Skill name format.** The proposal assumes `CommandInfo.name` for a plugin skill is `git-agent:<skill>` and that `plugin` is set. The types say `plugin` is set "when the engine knows". If `plugin` is missing for some entries, filter on the `git-agent:` name prefix instead.
- **Early-access surface.** The 2.1.293 declaration header reads "EARLY ACCESS: this surface may change between releases without notice", even though mods are on by default. `claude plugin validate --strict` and the tests in verify.sh are the drift alarm.
- **Behaviour below the floor.** What a pre-2.1.287 build does with a `modules` hooks.json is undocumented. The README states the floor. This is the main reason the mod is standalone rather than embedded.
- **No CI coverage.** GitHub Actions has no `claude` CLI and is often billing-blocked, so mod tests run only in local `verify.sh`.
- **Trust.** Mods are unsandboxed. The mod's call surface is deliberately tiny (Appendix B), so a reviewer can diff the `validate` output against it.
</risks>

<open-questions>
Decisions still owned by the human — surface them, do not answer them:
- **Command name.** Default: `/git-agent-launcher`, the same as the plugin, for discoverability. A shorter alternative such as `/git-launch` is easier to type but no longer matches the plugin name.
- **When to propose follow-on mods.** Draft the next proposal (repo-aware next step, kit-wide launcher, or plans pane) now, or after 0.1.0 has been dogfooded in this repo.
</open-questions>

<roadmap>
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 0 | Throwaway spike via `claude --plugin-dir`, not committed. Check that `$.command.list()` returns git-agent entries with `plugin`/`name` as assumed, that `$.prompt.fill` works in the terminal and the Desktop Code tab, and where focus lands after a fill. Stop condition: fill fails on Desktop and the copy fallback is rejected, then reopen decision 6. | S | — |
| 1 | Workstreams A and B: mod files and tests, `claude plugin validate --strict` clean, `claude plugin test` green on both surfaces | S | 0 |
| 2 | Workstreams C and D: verify.sh mod step, README-table mod component, marketplace entry, CHANGELOGs, READMEs, how-to guide, floor note | M | 1 |
| 3 | Release 0.1.0 and dogfood in this repo (desktop and terminal) | S | 2 |
| 4 | Follow-on mod candidates, each its own proposal: kit-wide launcher (widen the filter; 87 entries need grouping), repo-aware next-step band (`git status`, `gh pr view` via `$.process.run`), plan-agent plans pane (`docs/plans` status with build buttons) | — | 3 |
</roadmap>

<appendices>
Appendix A — git-agent entries the launcher lists (git-agent 4.23.0)

| Entry (`/git-agent:...`) | Kind | `argument-hint` | Outward effect | `AskUserQuestion` refs in body |
|---|---|---|---|---|
| branch-agent | skill | `[branch-name]` | Creates a branch from origin, no upstream | 1 |
| commit-agent | skill | — | Commits and pushes, no ask (4.23.0) | 2 |
| create-issue | skill | `[bug\|feature\|selection\|session\|plan] [title...]` | Opens an issue after confirming | 5 |
| merge | skill | — | Merges after a readiness gate and approval prompt | 2 |
| post-merge-cleanup | skill | — | Deletes merged branches and worktrees | 1 |
| pr-agent | skill | — | Pushes and opens a PR | 0 |
| ship | skill | — | Stages, commits, pushes, opens a PR | 1 |
| ship-autonomous | skill | — | Full pipeline with CI poll and gated merge | 6 |
| commit-bg | command | `[optional commit hint]` | Background commit | 0 |
| merge-bg | command | `[optional PR url or number]` | Background merge gate | 1 |
| pr-bg | command | `[optional PR title or context hint]` | Background push and PR | 0 |
| ship-bg | command | `[optional commit/PR hint]` | Background ship | 0 |
| ship-ci-bg | command | `[optional PR url or number]` | Background CI watch | 0 |

Four skills set `disable-model-invocation: true` (branch-agent, commit-agent, pr-agent, ship). A prompt fill becomes a user-typed run when the user presses Enter, so that flag does not block them.

Appendix B — the mod's call surface (the `claude plugin validate` contract)

- **Hooks:** `session.start`, `command.run` (answers its own command), `ui.render` (`Pane`).
- **Calls:** `command.register`, `command.list`, `ui.open`, `ui.resolve`, `prompt.read`, `prompt.fill`, `ui.toast`, and `ui.close` if Phase 0 requires it.
- **Nothing else.** A `validate` report naming `fs.*`, `process.*`, `http.*`, `model.*`, `session.*`, or `env.*` is a defect.

Appendix C — fill contract, worked examples

| Prompt draft before press | Entry pressed | Prompt box after |
|---|---|---|
| (empty) | commit-agent | `/git-agent:commit-agent ` |
| `fix typo in readme` | commit-bg | `/git-agent:commit-bg fix typo in readme` |
| `482` | merge-bg | `/git-agent:merge-bg 482` |
| (empty), `isFilled: false` | pr-agent | unchanged; toast `Type /git-agent:pr-agent in the prompt` |
</appendices>

Author an execution plan that delivers roadmap Phases 0 through 3: the Phase 0 spike, Workstreams A and B (the mod and its tests), then Workstreams C and D (repo tooling and docs), ending with the 0.1.0 release. Draft real, actionable steps that name the files each one touches; do not restate the headings above as steps. Treat the locked decisions as settled inputs. Make Phase 1 conditional on Phase 0's three checks, and carry Phase 0's stop condition into the plan verbatim. Carry the open questions into the plan's unresolved-questions section rather than answering them. Phase 4 (follow-on mods) is out of scope for this plan.

To start: `/plan-agent:implementation-plan Build the git-agent-launcher mod plugin --from-prompt docs/prompts/proposal-add-git-agent-launcher-mod.md`
