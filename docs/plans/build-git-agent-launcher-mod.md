---
status: todo
type: feature
created: 2026-10-09
repo-name: agentics
artifact-url: https://claude.ai/artifact/TK9RsRYNsAC1iSLGnqj3qu
issue: https://github.com/shawn-sandy/agentics/issues/647
prototype: docs/prototypes/launch-git-agent-commands.html
design: https://claude.ai/artifact/RMNembyJJpjqPRS76GW7BS
design-dir: docs/designs/build-git-agent-launcher-mod
proto-model: {"entity":"Entry","fields":[{"name":"name","type":"string"},{"name":"kind","type":"string"},{"name":"description","type":"string"},{"name":"hotkey","type":"number"}],"action":"Add entry","successSignal":"Entries ready to stage"}
glance: The kit's first mod gives git-agent a clickable surface, so nobody has to remember thirteen /git-agent:<name> spellings — and because a press only stages text in the prompt, a misclick can never commit or push. Done when validate and test are green on both surfaces, the merge gate passes without touching verify.sh, and 0.1.0 is in the marketplace.
workflow: never
---

# Plan: Build the git-agent-launcher mod plugin

## Objective

Ship `kit/plugins/git-agent-launcher` 0.1.0: a Claude Code mod whose `/git-agent-launcher` command opens a pane listing every git-agent skill and command, where pressing an entry fills `/git-agent:<name> ` into the prompt for the user to run.

## Context

git-agent 4.23.0 exposes 13 slash entries (8 skills, 5 commands) that users must remember and type. Mods — Claude Code plugins whose `hooks/hooks.json` names a hooks module — can draw panes in the terminal and the Desktop Code tab, and every primitive the launcher needs already exists: `$.command.list()` returns the entries with descriptions and plugin names, a `Pane` draws them as `Button`s, and `$.prompt.fill` stages the chosen one. The mod is therefore a thin view; the real work is in this repo's tooling and docs.

This plan executes the converged proposal at `docs/prompts/proposal-add-git-agent-launcher-mod.md` (Phases 0–3 of its roadmap; Phase 4's follow-on mods are out of scope). Its locked decisions are settled inputs — see Decisions below. Known risks and their mitigations: `$.prompt.fill` may not reach the Desktop prompt box (fall back to `$.ui.copy` plus a toast on that surface); a `focus: true` pane may hold the keyboard after a fill (mitigate by closing the pane on success); `CommandInfo.plugin` is only set "when the engine knows" (fall back to filtering on the `git-agent:` name prefix); the mod API is marked early access (`claude plugin validate --strict` plus the plugin tests are the drift alarm); and GitHub Actions has no `claude` CLI and is often billing-blocked, so mod checks run only in the local merge gate. The first three risks are exactly what Phase 0 measures before any committed file exists.

One correction to the proposal discovered during planning: its Workstream C added a mod stage to `scripts/verify.sh`, but that file caps repo-specific stages at three ("a fourth is the signal to add a verify.local.sh extension hook") and is a byte-identical duplicate of the verified-change skill asset, making every edit a two-file change. The mod checks instead ride `tests/run-all.sh`'s auto-discovery — see the Decisions entry.

## Decisions

- Standalone plugin, one plugin per mod — keeps the Claude Code 2.1.287 floor and early-access API churn away from git-agent's users, lets the launcher be disabled alone, and widening to other plugins later is a one-line filter change (proposal decisions 1 and 9, locked 2026-10-09).
- A press fills the prompt, never runs — commit-agent (since 4.23.0) and pr-agent push without asking, so a misclick must stay harmless; arguments can be typed after the fill, and Enter is what runs it (proposal decision 6).
- The surface is a pane opened by the registered `/git-agent-launcher` command with `focus: true` and `closeOnEscape: true` — no band, no auto-open; a pane the user asked for places at any terminal width (proposal decision 7).
- v1 is a static list with no repo state — no `git status`, no `gh pr view`; a repo-aware "next step" is a follow-on mod (proposal decision 8).
- No `version` key in plugin.json — a version there silently overrides the marketplace value; `.claude-plugin/marketplace.json` carries 0.1.0 alone (proposal decision 2).
- Every mod file lives under `hooks/` — `scripts/build-dist.mjs` copies only KEEP-listed paths and would drop a top-level `types/`; the mod uses no `$.state`, so it needs no types contract (proposal decision 4).
- The call surface is capped at `command.register`, `command.list`, `ui.open`, `ui.resolve`, `prompt.read`, `prompt.fill`, `ui.toast`, plus `ui.close` only if step 5 adopts it — a `claude plugin validate` report naming `fs.*`, `process.*`, `http.*`, `model.*`, `session.*`, or `env.*` is a defect (proposal decision 5 and Appendix B).
- Mod checks join the merge gate as `tests/plugins/test-mod-plugins.sh`, not a verify.sh stage — verify.sh caps repo-specific stages at three and is a byte-identical duplicate of `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh`, while `tests/run-all.sh` auto-discovers `tests/**/test-*.sh` and verify.sh already runs it as the unit stage (clarified with the user 2026-10-09; supersedes the proposal's Workstream C wording).
- Steps are grouped by the proposal's roadmap phases 0–3, not RED/GREEN/VERIFY/SHIP — the gating spike and its verbatim stop condition have no slot in that shape; Phase 1 still lands the six regression cases in the same phase as the behaviour they pin.
- Phase 1 is conditional on Phase 0's three recorded findings (name format, fill on Desktop, focus after fill); the findings are appended to this section before any Phase 1 file is created. The Desktop half of the spike is user-assisted — the user presses once in a Desktop Code tab and the report is recorded as the finding (interview, 2026-10-09).
- Interview-confirmed UI choices (2026-10-09): digit hotkeys 1–9 only (entries 10–13 reachable by focus and press), one flat list in `$.command.list()` order, descriptions wrapped in full to `bodyColumns`, and the pane close after a successful fill stays conditional on the Phase 0 focus finding.

## Files

- kit/plugins/git-agent-launcher/.claude-plugin/plugin.json (new) — manifest without a version key
- kit/plugins/git-agent-launcher/hooks/hooks.json (new) — `{ "modules": ["./register.tsx"] }`
- kit/plugins/git-agent-launcher/hooks/register.tsx (new) — command registration, pane, fill-on-press
- kit/plugins/git-agent-launcher/hooks/register.test.ts (new) — six regression cases on both surfaces
- kit/plugins/git-agent-launcher/README.md (new) — floor, prerequisite, install, trust contract
- kit/plugins/git-agent-launcher/CHANGELOG.md (new) — 0.1.0 entry
- tests/plugins/test-mod-plugins.sh (new) — validate + test every mod plugin, SKIP below CLI 2.1.287
- docs/guides/how-to/git-agent-launcher.md (new) — how-to guide
- .claude-plugin/marketplace.json (modified) — register the plugin at 0.1.0
- scripts/build-readme-table.mjs (modified) — count hooks/hooks.json modules as a `mod` component
- README.md (modified) — generated table row, Plugins section, floor notes at lines 7, 98, 256
- CLAUDE.md (modified) — floor note beside "1.0.33+" at line 26
- CHANGELOG.md (modified) — Unreleased/Added entry
- kit/plugins/README.md (modified) — plugin listed

## Steps

### Phase: 0 — Spike

1. Scaffold a throwaway launcher plugin in the session scratchpad (a plugin.json plus `hooks/hooks.json` naming a minimal register module that logs `$.command.list()` on `session.start`), run `claude --plugin-dir <scratchpad-dir>` inside this repo with git-agent installed, and record the exact `CommandInfo.name` format for git-agent's 13 entries and whether `plugin` is set on each. Why: the pane filter keys on `plugin === 'git-agent'` with a `git-agent:` name-prefix fallback, and the engine types only promise `plugin` "when the engine knows" — the filter must be chosen from observed output, not assumption. Verify: the observed names and plugin fields are appended to this spec's Decisions section as the Phase 0 findings.
2. Extend the spike with a `focus: true` pane whose button press calls `$.prompt.read()` then `$.prompt.fill`, exercise it in the terminal yourself, and gather the Desktop half user-assisted: stage the spike, ask the user to press the button once in a Desktop Code tab session, and record what they report for `isFilled` and where keyboard focus lands after a successful fill on each surface. Why: the proposal gates all of Phase 1 on these mechanics — they decide whether the pane closes itself after a fill and whether Desktop needs the `$.ui.copy` fallback — and the implementing session may have no Desktop surface of its own; the proposal's stop condition carries into this plan verbatim: "Stop condition: fill fails on Desktop and the copy fallback is rejected, then reopen decision 6." Verify: both findings are appended to the Decisions Phase 0 entry, and the spike directory is deleted without ever being committed.

### Phase: 1 — Mod and tests

3. Create `kit/plugins/git-agent-launcher/.claude-plugin/plugin.json` (name, description, author, license, keywords, homepage `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/git-agent-launcher`, repository — and no `version` key) and `kit/plugins/git-agent-launcher/hooks/hooks.json` holding `{ "modules": ["./register.tsx"] }`. Why: a plugin.json version silently overrides the marketplace value, and build-dist.mjs keeps only KEEP-listed paths, so the module must sit under `hooks/`. Verify: `claude plugin validate --strict kit/plugins/git-agent-launcher` parses the manifest and reports no version key.
4. Write the registration and command plumbing in `kit/plugins/git-agent-launcher/hooks/register.tsx`: on `session.start`, call `$.command.register({ name: 'git-agent-launcher', description: 'Open a pane of git-agent skills and commands' })` as the hook's last statement (a taken name throws, and a throwing hook is skipped); on `command.run` for that command, call `$.ui.open({ id, title, focus: true, closeOnEscape: true })` and return `{}` — or, when `isPlaced` is false (VS Code chat panel, `claude -p`), return `{ text }` listing every `/git-agent:<name>` with its description. Why: the pane is opt-in — opened only when asked, so it places at any width — and surfaces that cannot draw still get a usable text answer instead of silence. Verify: under `claude --plugin-dir ./kit/plugins/git-agent-launcher`, typing `/git-agent-launcher` opens a pane (body still empty at this step).
5. Write the pane body and press behaviour in the same `register.tsx`: on `ui.render` for the pane's `requestId`, read `$.command.list()`, keep the git-agent entries (the `plugin === 'git-agent'` filter, or the name-prefix fallback if Phase 0 found `plugin` unset) in list order, and draw one row per entry — a `Button` labelled with the unprefixed name (digit hotkeys 1–9 on the first nine) and a dim `Text` description wrapped to `e.props.bodyColumns`; when the filtered list is empty, draw a single line naming `/plugin install git-agent@agentics-kit`; on press, `await $.prompt.read()` then `$.prompt.fill({ text: '/git-agent:' + name + ' ' + draft, mode: 'replace' })`, raise `$.ui.toast('Type /git-agent:' + name + ' in the prompt')` when `isFilled` is false, and close the pane after a successful fill if Phase 0 showed focus staying in the pane. Why: fill-not-run is the locked safety decision — commit-agent and pr-agent have outward effects, so a misclick must never execute — and preserving the draft means typed arguments survive the press. Verify: pressing `commit-agent` over an empty prompt stages exactly `/git-agent:commit-agent `, and pressing `commit-bg` over the draft `fix typo in readme` stages `/git-agent:commit-bg fix typo in readme`.
6. Write `kit/plugins/git-agent-launcher/hooks/register.test.ts` covering, for both `'terminal'` and `'desktop'` surfaces, six regression cases: a non-git-agent entry in the mocked list never renders; an empty-draft press fills exactly `/git-agent:commit-agent `; a press over draft `fix typo in readme` fills `/git-agent:commit-bg fix typo in readme`; `isFilled: false` raises the toast naming the command; an empty filtered list draws the install line; and `command.run` with `isPlaced: false` returns text naming every git-agent entry. Why: the filter and the fill contract are the plugin's entire behaviour, and each case fails if that behaviour regresses — the test's own hooks answer `command.list`, `prompt.read`, and `prompt.fill` beneath the plugin. Verify: `claude plugin test kit/plugins/git-agent-launcher` exits 0, and temporarily inverting the empty-draft assertion makes it exit non-zero (restore it afterwards).

### Phase: 2 — Tooling and docs

7. Add `tests/plugins/test-mod-plugins.sh`: for every `kit/plugins/*/hooks/hooks.json` declaring `modules`, run `claude plugin validate --strict <plugin-dir>` and `claude plugin test <plugin-dir>`; when the `claude` CLI is absent, or a semver comparison of `claude --version` against 2.1.287 says it is older, print `SKIP (claude < 2.1.287)` and exit 0. Why: `tests/run-all.sh` auto-discovers `tests/**/test-*.sh` and `scripts/verify.sh` already runs it as the unit stage, so the mod checks join the merge gate with zero edits to the three-stage-capped, byte-identical-duplicated gate file — and the loop covers future mod plugins automatically. Verify: `bash tests/plugins/test-mod-plugins.sh` exits 0 with real validate/test output under a current CLI, and `PATH=/usr/bin:/bin bash tests/plugins/test-mod-plugins.sh` prints the SKIP line and exits 0.
8. Teach `countComponents()` in `scripts/build-readme-table.mjs` to also count each `hooks/hooks.json` `modules` entry as a `mod` component, alongside the existing root-`hooks.json` hook count. Why: the generated Plugin Reference Table would otherwise show "none" for a plugin whose only component is its mod. Verify: after regeneration, `node scripts/build-readme-table.mjs --check` exits 0, the git-agent-launcher row reads `1 mod`, and `git diff README.md` shows no other plugin's component counts changed.
9. Register the plugin in `.claude-plugin/marketplace.json` — copy an existing entry's shape with `source.path` `kit/plugins/git-agent-launcher`, `version` `0.1.0`, `category` `development`, and tags `mod`, `launcher`, `pane`, `git-agent` — then re-run `node scripts/build-readme-table.mjs`. Why: the marketplace references plugin sources by relative path, it is the only place a version lives, and the CI guard fails any PR whose touched plugin version does not exceed the base branch. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` passes and the README table shows git-agent-launcher at 0.1.0.
10. Write `kit/plugins/git-agent-launcher/README.md` and `CHANGELOG.md` (0.1.0): what the launcher does, the floor (Claude Code 2.1.287+ in the terminal, 2.1.286+ in the Desktop Code tab), the git-agent prerequisite, the install command `/plugin install git-agent-launcher@agentics-kit`, where it draws and where it falls back to text, and the expected `claude plugin validate` call surface — `command.register`, `command.list`, `ui.open`, `ui.resolve`, `prompt.read`, `prompt.fill`, `ui.toast`, plus `ui.close` only if step 5 adopted it — so a trust reviewer can diff the real report against the documented one. Why: mods are unsandboxed and run with the user's permissions; the deliberately tiny, documented call surface is the trust contract. Verify: every call named in the README appears in the actual `claude plugin validate --strict` output, and nothing in that output is missing from the README.
11. Update the shared docs: add the root `CHANGELOG.md` Unreleased/Added entry naming the plugin, its pinning test, and the table change; list the plugin in `kit/plugins/README.md` and the root README `## Plugins` section; write `docs/guides/how-to/git-agent-launcher.md` in the existing how-to shape; and beside every "1.0.33+" mention (README.md lines 7, 98, 256 and CLAUDE.md line 26) note that mod plugins need Claude Code 2.1.287+. Why: repo convention documents every release in the shared docs, and a user on an older CLI should learn the floor from the README rather than from a command that silently does nothing. Verify: `grep -n "2.1.287" README.md CLAUDE.md kit/plugins/git-agent-launcher/README.md docs/guides/how-to/git-agent-launcher.md` hits all four files and `node scripts/build-readme-table.mjs --check` still exits 0.

### Phase: 3 — Release and dogfood

12. Run the full merge gate `bash scripts/verify.sh` from the repo root, then dogfood the launcher on both drawing surfaces — in a terminal session and in the Desktop Code tab, open `/git-agent-launcher`, press an entry over an empty prompt and over a typed draft, confirm the staged text matches the proposal's Appendix C examples, and confirm that after the pane closes (Escape or post-fill close) keyboard focus is back in the prompt box so Enter runs the staged command without the mouse — and confirm the text-listing fallback in a surface with no drawing (`claude -p` or the VS Code chat panel). Why: this repo's merge gate rule accepts only a local verify.sh exit 0 as evidence, and the proposal's Phase 3 is seeing the launcher work where users will actually use it. Verify: verify.sh exits 0 with the mod test reported PASS (or its SKIP line recorded as a skip, not a pass), and the dogfood observations are written down for the PR's VERIFICATION section.
13. Commit every modified file — plugin, tests, tooling, docs, and this plan spec — in a single commit on this branch and open the PR with the VERIFICATION section filled from step 12. Why: 0.1.0 ships by merging the marketplace entry, the repo's rule is one commit with no remainder, and a red GitHub check is triaged as a possible billing block (`gh run view --log-failed`) before any code is blamed. Verify: the PR is open, its VERIFICATION section names what actually ran, and `node scripts/check-plugin-versions.mjs` passes against a fresh `origin/main`.

## Tests

Tier 1 — This plan changes application code
- Objective: pressing a launcher entry stages the command in the prompt instead of running it. File: kit/plugins/git-agent-launcher/hooks/register.test.ts; Type: smoke; Asserts: pressing commit-agent over an empty draft fills exactly `/git-agent:commit-agent ` on both the terminal and desktop surfaces; Run: claude plugin test kit/plugins/git-agent-launcher
- Unit: filter and fill contract. File: kit/plugins/git-agent-launcher/hooks/register.test.ts; Targets: the ui.render Pane handler and onPress; Key cases: non-git-agent entries excluded, draft preserved (`/git-agent:commit-bg fix typo in readme`), isFilled:false toast, empty-list install line, isPlaced:false text fallback
- Integration: merge-gate wiring for mod plugins. File: tests/plugins/test-mod-plugins.sh; Targets: claude plugin validate --strict and claude plugin test across every kit/plugins/*/hooks/hooks.json with modules; Key cases: real results under CLI ≥ 2.1.287, `SKIP (claude < 2.1.287)` with exit 0 when the CLI is absent or old

## Acceptance Criteria

- [ ] `claude plugin validate --strict kit/plugins/git-agent-launcher` exits 0 and its call report lists only command.register, command.list, ui.open, ui.resolve, prompt.read, prompt.fill, ui.toast (and ui.close if adopted) — nothing from fs, process, http, model, session, or env.
- [ ] `claude plugin test kit/plugins/git-agent-launcher` exits 0 with all six regression cases green on both the terminal and desktop surfaces.
- [ ] `bash tests/plugins/test-mod-plugins.sh` exits 0 — printing real validate/test results with a current CLI, and `SKIP (claude < 2.1.287)` without one.
- [ ] The README Plugin Reference Table shows git-agent-launcher at 0.1.0 with a `1 mod` component count, and `node scripts/build-readme-table.mjs --check` exits 0.
- [ ] `bash scripts/verify.sh` exits 0 while `git diff --name-only origin/main` lists neither `scripts/verify.sh` nor `kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh`.
- [ ] Phase 0's three findings (name format, fill on Desktop, focus after fill) are recorded in this spec's Decisions section before any Phase 1 file exists.
- [ ] A dogfood pass is recorded: the pane opens and a press stages the command in the prompt in both the terminal and the Desktop Code tab (or the documented Desktop fallback fires, per Phase 0), and a non-drawing surface gets the text listing.

## Verification

With a Claude Code CLI at 2.1.287 or later, run `claude plugin validate --strict kit/plugins/git-agent-launcher`, `claude plugin test kit/plugins/git-agent-launcher`, and `bash scripts/verify.sh` from the repo root — all three must exit 0, with the mod test visible inside the gate's unit stage output.

Then walk the launcher as a user: in a terminal session in this repo, type `/git-agent-launcher`, press `commit-agent` over an empty prompt and read exactly `/git-agent:commit-agent ` staged in the prompt box; type the draft `fix typo in readme`, open the pane again, press `commit-bg`, and read `/git-agent:commit-bg fix typo in readme`. After each press, close the pane (Escape or the post-fill close) and confirm keyboard focus is back in the prompt box, so Enter alone runs the staged command. Repeat the empty-draft press in the Desktop Code tab (or observe the documented fallback if Phase 0 ruled the fill out there). Finally run the command in a non-drawing surface (`claude -p` or the VS Code chat panel) and read the text listing of all 13 entries. Nothing may execute until Enter is pressed — at no point does a press alone commit, push, or open a PR.

## Next Steps

- Draft the next mod proposal once 0.1.0 has been dogfooded
  The proposal's Phase 4 names three candidates, each its own plugin and proposal; timing is an open question for the user.
  ```text
  In the agentics repo, run /plan-agent:build-proposal for the next kit mod,
  choosing among: a kit-wide launcher (widen the git-agent-launcher filter;
  87 entries need grouping), a repo-aware next-step band (git status / gh pr
  view via $.process.run), or a plan-agent plans pane (docs/plans status with
  build buttons). Ground it in kit/plugins/git-agent-launcher as the shipped
  reference mod, and verify the chosen draft converges before handing off to
  an implementation plan.
  ```

## Unresolved Questions

- Command name
  ```text
  In the agentics repo, the git-agent-launcher mod registers its command as
  /git-agent-launcher, matching the plugin name for discoverability; a shorter
  alternative such as /git-launch is easier to type but no longer matches the
  plugin name. Check how existing kit plugins name their commands relative to
  their plugin names, then recommend which name the launcher should register.
  ```
- When to propose follow-on mods
  ```text
  In the agentics repo, the git-agent-launcher proposal
  (docs/prompts/proposal-add-git-agent-launcher-mod.md, roadmap Phase 4) names
  three follow-on mod candidates: a kit-wide launcher, a repo-aware next-step
  band, and a plan-agent plans pane. Investigate whether drafting the next
  proposal now or after 0.1.0 has been dogfooded in this repo better fits how
  this kit has sequenced past releases, and recommend a timing.
  ```

## Resources

- docs/prompts/proposal-add-git-agent-launcher-mod.md — the converged proposal this plan executes; carries the locked decisions, the git-agent entry inventory (Appendix A), the call-surface contract (Appendix B), and the fill examples (Appendix C)
- code.claude.com/docs/en/plugins/mods/overview — mod availability, surfaces, and the unsandboxed trust model
- scripts/verify.sh (comment near line 166) — the three-stage ceiling and verify.local.sh escape hatch that redirected the proposal's Workstream C to tests/plugins/
- plugin-authoring skill (built into Claude Code) — the hooks-module contract the implementing session should load before writing register.tsx
