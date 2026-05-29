---
status: completed
type: refactor
created: 2026-05-29
repo-name: agentics
---

# Plan: Remove Background Feature from social-media-tools

## Context

The `social-media-tools` plugin (v1.3.1) added a background dispatch layer that routes all social share requests through a subagent (`agent-social-share`) running with `run_in_background: true`. This requires broad tool permissions — including `Agent`, `ToolSearch`, `ExitPlanMode`, `WebFetch`, and three Playwright MCP tools — on every card-generating flow. The overhead is not worth the fire-and-forget convenience, and the permission surface is too large. We are removing the background feature entirely so the plugin's skills run interactively and directly.

---

## Scope of Removal

### Files to DELETE (6 files + empty directory)

| File | Why |
|------|-----|
| `kit/plugins/social-media-tools/commands/social-share-bg.md` | Background router command |
| `kit/plugins/social-media-tools/commands/digest-bg.md` | Background digest command |
| `kit/plugins/social-media-tools/commands/session-bg.md` | Background session command |
| `kit/plugins/social-media-tools/agents/agent-social-share.md` | Background share runner |
| `kit/plugins/social-media-tools/agents/agent-digest.md` | Background digest runner |
| `kit/plugins/social-media-tools/references/non-interactive-mode.md` | Background contract spec (only used by background agents/skills) |

After deleting both agent files, remove the now-empty `kit/plugins/social-media-tools/agents/` directory (`git rm -r` handles this automatically).

### Files to MODIFY

#### 1. `skills/social-share/SKILL.md` — Core router (most significant change)

Currently Phase 3 always appends `--background` to `DISPATCH_FLAGS`, and Phase 4 dispatches via `Agent(subagent_type: "agent-social-share", run_in_background: true)`.

**Changes:**
- Phase 3: Remove `--background` from `DISPATCH_FLAGS`; keep `--platform=<PLATFORM> <EXTRA_FLAGS>`
- Phase 4: Replace `Agent(...)` dispatch with `Skill("social-media-tools:<TARGET_SKILL>", args="<DISPATCH_FLAGS>")` — direct invocation
- `allowed-tools`: Remove `Agent, ToolSearch, ExitPlanMode`; add `Skill` (already supports `Bash, Read, Write`)

#### 2. Individual share skills — Remove `--background` flag handling

Each skill in `skills/*/SKILL.md` references `--background` mode behavior and the `non-interactive-mode.md` reference. Remove:
- Any `--background` flag from the declared flags section
- Any "Background mode:" or "If `--background`:" conditionals
- Any `include: references/non-interactive-mode.md` directives
- The `SOCIAL-SHARE: DONE ...` completion-line contract

Affected skills (pattern applies to all):
- `skills/share-code/SKILL.md`
- `skills/share-blog/SKILL.md`
- `skills/share-github/SKILL.md`
- `skills/share-project/SKILL.md`
- `skills/share-selection/SKILL.md`
- `skills/share-session/SKILL.md`
- `skills/media-library/SKILL.md`
- `skills/share-scan/SKILL.md`

#### 3. `commands/digest.md` — Simplify

Remove any reference to `digest-bg` as an alternative. The interactive digest command stays as-is.

#### 4. `README.md`

Remove:
- Background commands table entries (`social-share-bg`, `digest-bg`, `session-bg`)
- Background agents section (`agent-social-share`, `agent-digest`)
- All `-bg` usage examples
- The "Background mode" feature description paragraph
- References to `non-interactive-mode.md`

#### 5. `CHANGELOG.md`

Add a new `v2.0.0` entry (MAJOR — removing commands and agents):
```
## v2.0.0 — 2026-05-29

BREAKING CHANGE: Remove background dispatch layer.

- Deleted commands: `social-share-bg`, `digest-bg`, `session-bg`
- Deleted agents: `agent-social-share`, `agent-digest`
- Deleted reference: `non-interactive-mode.md`
- `social-share` router now invokes target skills directly via `Skill(...)` instead of dispatching a background agent
- Removed `--background` flag from all share skills
- Reduced permission surface on the router: no more `Agent`, `ToolSearch`, `ExitPlanMode`, or `WebFetch` in the dispatch layer
- Note: individual share skills still use Playwright for screenshots via `rendering-pipeline.md` — Playwright prompts appear interactively per-skill rather than being pre-approved in the agent layer
```

#### 6. `.claude-plugin/marketplace.json`

Bump `social-media-tools` version from `"1.3.1"` to `"2.0.0"`.

---

## Files NOT Changed

- All 6 HTML templates (`templates/*.html`) — no background-specific content
- `scripts/find_free_port.py`, `scripts/session_usage.py` — used by interactive skills
- `references/rendering-pipeline.md` — used by interactive Playwright screenshot step
- `references/copy-panels.md`, `references/language-map.md`, `references/platforms.md`, `references/reuse-check.md`, `references/saving-and-delivery.md`, `references/variables.md`
- `skills/security-scrub/` — standalone, no background dependency
- `plugin.json` — no version field (version lives in marketplace.json)

---

## Verification

1. **Plugin structure:** Run `/validate-plugin social-media-tools` after changes
2. **Deleted files and directory are gone:** `find kit/plugins/social-media-tools/commands -name "*-bg*"` should return nothing; `ls kit/plugins/social-media-tools/agents/` should error (directory removed)
3. **No --background references remain:** `grep -r "\-\-background" kit/plugins/social-media-tools/` should return nothing
4. **Router skill is self-contained:** `cat kit/plugins/social-media-tools/skills/social-share/SKILL.md` — Phase 4 should reference `Skill(...)`, not `Agent(...)`
5. **Marketplace version updated:** Check `.claude-plugin/marketplace.json` shows `"version": "2.0.0"` for `social-media-tools`
6. **Plan file committed:** Include this plan file in the commit per CLAUDE.md convention
