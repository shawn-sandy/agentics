---
status: completed
modified: 2026-05-28
type: feature
created: 2026-05-28
repo-name: agentics
---

# Plan: Add `issue-agent` plugin (create GitHub/GitLab issues from any context)

## Context

Developers frequently surface bugs, feature ideas, or TODOs mid-session — in a
code selection, in conversation, or while debugging — but filing them as
trackable issues means leaving the flow and hand-writing the report. The repo
has **no** in-repo issue-creation tooling: the only existing pieces are loose
user-global commands (`~/.claude/commands/github-{issue,bug,feature}.md`) that
are GitHub-only, take positional arguments, and crucially **cannot ingest a
selection or the session transcript** — context comes solely from
`$ARGUMENTS`, the codebase, and the environment.

This plan packages a new first-class plugin, `issue-agent`, into
`kit/plugins/`. Its differentiator is multi-source context ingestion (selection,
session, bug, feature, freeform) and dual-host support (GitHub via `gh`, GitLab
via `glab`, auto-detected from the remote). Decisions confirmed with the user:
**GitHub + GitLab**, **one multi-source skill**, **manual-invoke only**
(`disable-model-invocation: true` — creating real issues is an external action
that warrants explicit invocation), plugin domain-named **`issue-agent`** with
the skill action-named **`create-issue`** (per the repo's domain-container
naming convention).

## Objective

Ship a new `issue-agent` plugin containing a single manual-invoke
`create-issue` skill that drafts and opens a GitHub or GitLab issue from a
selection, the session, a bug, or a feature description — with a confirmation
gate before any issue is created — and register it in the marketplace.

## Steps

1. **Create the plugin skeleton.** Make `kit/plugins/issue-agent/` with
   `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`,
   `skills/create-issue/SKILL.md`, and `skills/create-issue/references/`.
   - *Why:* The repo's fixed layout (a skill is always
     `skills/<name>/SKILL.md`; shared assets under `references/`) must be
     matched exactly or Claude Code won't discover the skill.
   - *Verify:* `ls -R kit/plugins/issue-agent` shows the four files plus the
     `references/` dir; `plugin.json` has `name: issue-agent` and **no**
     `version` field (version lives only in `marketplace.json`).

2. **Write `plugin.json`.** Copy the field set used by `git-agent`: `name`,
   `description`, `author: { "name": "Agentics Project" }`, `license: "MIT"`,
   `keywords` (e.g. `issue`, `ticket`, `bug`, `feature`, `github`, `gitlab`,
   `gh`, `glab`), `homepage`
   (`https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/issue-agent`),
   `repository`.
   - *Why:* Consistency with every other plugin manifest; homepage must point
     at the plugin subdir per `CLAUDE.md` convention.
   - *Verify:* `cat plugin.json | python3 -m json.tool` parses; `name` matches
     the directory; no `version` key present.

3. **Write `skills/create-issue/SKILL.md`.** Frontmatter:
   - `name: create-issue`
   - `description:` three-part, ≤200 chars, e.g. *"Drafts and opens a GitHub or
     GitLab issue from a selection, the session, a bug, or a feature. Detects
     the host and confirms before creating. Use when the user asks to file,
     open, or create an issue or ticket."*
   - `allowed-tools: Bash(gh *), Bash(glab *), Bash(git *), AskUserQuestion, Read, Grep, Glob`
   - `disable-model-invocation: true`
   - `argument-hint: "[bug|feature|selection|session] [title or description]"`

   Body workflow (imperative, progressive-disclosure):
   1. **Detect host** — `git remote get-url origin`; `github.com` → use `gh`,
      `gitlab.com` (or self-hosted GitLab) → use `glab`. If neither resolves,
      `AskUserQuestion` for the host.
   2. **Pre-flight** — run the host CLI's auth check (`gh auth status` /
      `glab auth status`) and repo check (`gh repo view` / `glab repo view`).
      Stop with guidance if the CLI is missing or unauthenticated (suggest the
      user run `! gh auth login` / `! glab auth login`).
   3. **Resolve source & type** — parse `$ARGUMENTS` for an explicit source
      (`selection`/`session`/`bug`/`feature`) and title. If absent or
      ambiguous, `AskUserQuestion` (batched) for source + issue type.
      - *selection*: treat the supplied/pasted text as the seed.
      - *session*: synthesize from the current conversation (the bug found or
        feature discussed).
      - *bug*: also gather env (`node --version`, `npm --version`, OS, recent
        `git log`), reproduction, expected vs actual.
      - *feature*: user-story + acceptance-criteria shape.
   4. **Gather repo context** — read `CLAUDE.md`, `Grep` related files, run a
      dedup check (`gh issue list` / `glab issue list`) and surface near-matches.
   5. **Draft** — populate the matching `references/` template; title prefix
      (`[BUG]`/`[FEATURE]`) or conventional title; suggest labels.
   6. **Confirm gate** — show the full drafted issue and `AskUserQuestion`:
      create / edit / cancel. **Never create without confirmation.**
   7. **Create** — `gh issue create --title --body --label` /
      `glab issue create --title --description --label`; on failure fall back to
      `--web`.
   8. **Report** — print the issue URL and number.
   - *Why:* The confirmation gate plus manual invocation are the safety contract
     for an action that writes to a shared external system; host detection makes
     the same skill serve both git hosts.
   - *Verify:* `head -8 SKILL.md` shows valid frontmatter with all five fields;
     reading the body confirms all eight workflow phases and an explicit
     "never create without confirmation" instruction.

4. **Write the `references/` templates.** Create `bug-report.md`,
   `feature-request.md`, `general-issue.md` (body skeletons mined from the
   global `github-bug.md`/`github-feature.md` content), and
   `host-commands.md` (a `gh` ↔ `glab` command/flag equivalence table:
   `issue create`, `--body`↔`--description`, `--label`, `--web`, auth/list/view).
   - *Why:* Progressive disclosure keeps `SKILL.md` lean; the host-commands map
     prevents `gh`/`glab` flag mistakes (their flags differ — notably
     `--body` vs `--description`).
   - *Verify:* All four files exist; `host-commands.md` lists the create/list/
     view/auth command for both CLIs side by side.

5. **Write `README.md` and `CHANGELOG.md`.** README with the six required
   sections (Overview, Features, Installation, Usage, Plugin Structure tree,
   Components). CHANGELOG seeded at `## v0.1.0` with the initial feature note.
   - *Why:* `plugin-patterns.md` requires a README with those six sections;
     every plugin in the repo ships a CHANGELOG.
   - *Verify:* README contains all six section headings; CHANGELOG has a
     `v0.1.0` entry.

6. **Register in `marketplace.json` and bump marketplace version.** Add an
   `issue-agent` plugin entry (`source: git-subdir`, `url`, `path:
   kit/plugins/issue-agent`, `version: 0.1.0`, `description`, `category:
   development`, `tags`). Bump the top-level marketplace `version` `3.8.0` →
   `3.9.0` (MINOR — new plugin).
   - *Why:* Plugins are discovered only via `marketplace.json`; per repo rules
     the plugin `version` lives here, not in `plugin.json`. A new plugin is a
     MINOR marketplace bump.
   - *Verify:* `python3 -m json.tool .claude-plugin/marketplace.json` parses
     (the `.claude/settings.json` PostToolUse validator also runs); the new
     entry's `path` matches the real directory; top-level `version` is `3.9.0`.

7. **Update root `CLAUDE.md` plugin table.** Add an `issue-agent` row and change
   the count "17 plugins" → "18 plugins" and the version reference to v3.9.0.
   - *Why:* `CLAUDE.md` documents the plugin roster and count; leaving it stale
     misleads future sessions.
   - *Verify:* The table includes `issue-agent`; the prose count reads "18
     plugins" and references `agentics-kit` v3.9.0.

## Acceptance Criteria

- [ ] `kit/plugins/issue-agent/` exists with `plugin.json` (name `issue-agent`,
      no `version`), `README.md`, `CHANGELOG.md`, and
      `skills/create-issue/SKILL.md`.
- [ ] `create-issue` SKILL.md has `disable-model-invocation: true`, a ≤200-char
      three-part description, and `allowed-tools` covering
      `Bash(gh *)`, `Bash(glab *)`, `Bash(git *)`, `AskUserQuestion`, `Read`,
      `Grep`, `Glob`.
- [ ] The skill detects GitHub vs GitLab from the remote and uses the matching
      CLI, with the correct per-CLI flags (`--body` vs `--description`).
- [ ] The skill ingests all four context sources (selection, session, bug,
      feature) and always shows a confirmation gate before creating an issue.
- [ ] `marketplace.json` registers `issue-agent` at `version: 0.1.0` with a
      valid `path`, and the top-level marketplace `version` is `3.9.0`; the JSON
      parses cleanly.
- [ ] Root `CLAUDE.md` lists `issue-agent` and reads "18 plugins".

## Verification

End-to-end, after implementation:

1. **Load the plugin locally:**
   `claude --plugin-dir ~/devbox/agentics/kit/plugins/issue-agent` and confirm
   `/issue-agent:create-issue` appears (and does **not** auto-activate when you
   merely *discuss* a bug — manual-invoke check).
2. **Host detection:** in a GitHub-remote repo, invoke
   `/issue-agent:create-issue bug <desc>` and confirm it selects `gh` and runs
   `gh auth status`; in a GitLab-remote repo confirm it selects `glab`.
3. **Confirmation gate:** drive the skill to the draft, choose **cancel**, and
   confirm **no** issue is created (no `gh/glab issue create` runs).
4. **Happy path (optional, real write):** with auth present, confirm **create**
   and verify the printed URL resolves to a real issue with the expected title
   prefix, body sections, and labels.
5. **JSON integrity:** `python3 -m json.tool .claude-plugin/marketplace.json`
   exits 0; the `.claude/settings.json` auto-validator reports no errors.

## Next Steps *(optional)*

- Add a background mirror agent + `-bg` command (git-agent triad):
  ```text
  Extend the issue-agent plugin in kit/plugins/issue-agent with a background
  variant following the git-agent triad pattern: add agents/agent-create-issue.md
  (mirrors the create-issue skill, runs in background, tools limited to
  Bash(gh *), Bash(glab *), Bash(git *), Read, Grep) and commands/create-issue-bg.md
  (a thin command that dispatches the agent with run_in_background: true). Bump the
  marketplace version (MINOR) and update the CHANGELOG and README. Keep the
  interactive skill's confirmation gate; the background agent should instead take
  an explicit "auto-create" flag and skip the gate only when set.
  ```

- Supersede the loose global github-* commands:
  ```text
  Review the user-global commands ~/.claude/commands/github-{issue,bug,feature}.md
  and ~/.claude/agents/ticket-creator.md against the new issue-agent plugin.
  Recommend whether to deprecate/remove the global ones in favor of the plugin,
  and if so draft the removal plus a short note in ~/.claude/GITHUB_COMMANDS.md
  pointing users to /issue-agent:create-issue. Do not delete anything without
  confirmation.
  ```

- Add Linear/Jira backends:
  ```text
  Extend issue-agent's create-issue skill to optionally target Linear or Jira in
  addition to GitHub/GitLab. Detect or ask for the backend, add a references file
  documenting the Linear/Jira issue-create API or MCP calls and required tokens,
  and gate those backends behind explicit configuration so the default GitHub/GitLab
  flow is unchanged. Bump the marketplace version and update docs.
  ```
