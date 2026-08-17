---
session-id: "014e06c5-a979-4289-bf3f-f00d2efbcde4"
date: 2026-08-17
source: "014e06c5-a979-4289-bf3f-f00d2efbcde4.jsonl"
type: session-export
title: "Screenshot verification and plan Context completeness"
eng-artifact-url: https://claude.ai/code/artifact/968b158a-de88-470f-ae12-12d4571a6fb3
---

# Screenshot verification and plan Context completeness

## At a glance

**Files touched:** 8 (7 in-repo, 1 outside) · **Plugins bumped:** 2 · **Decisions:** 4 · **Open items:** 4

Two independent, unrelated fixes landed in one session. First: `social-media-tools`'s shared Playwright screenshot pipeline gained a post-capture verification step — it checked the DOM was ready before capture but never checked the output file afterward, so a blank PNG still counted as success. That fix is committed and pushed (`0bedc78`, branch `claude/project-optimization-review-595e98`). Second: `plan-agent`'s `implementation-plan` and `build-proposal` skills, plus the personal global plan-mode skeleton, got an explicit "no follow-up question" completeness bar added to their `## Context` section guidance — still uncommitted in the working tree. Both fixes originated from a plugin/skills review run against an external article on agent-prompting technique (source URL in the session, not reproduced here).

## Architecture and code paths

**Screenshot pipeline** — `kit/plugins/social-media-tools/references/rendering-pipeline.md` is a single shared reference file, not duplicated per-skill. Ten `SKILL.md` files read it: `share-code`, `share-react`, `share-github`, `share-project`, `share-session`, `share-selection`, `share-explanation`, `share-blog`, `share-video`, and one more matched by the same grep. The pipeline is Steps 1–4 (`find_free_port.py` → `python3 -m http.server` → Playwright `browser_resize`/`browser_navigate`/`browser_snapshot`/`browser_take_screenshot` targeting `.card` → `kill $SERVER_PID`), followed by the new **Step 5 — Verify screenshot output**: `SIZE=$(wc -c < "$SAVE_PATH_PNG" ...)`, missing/zero/sub-5KB routes to the existing **Fallback** message instead of Phase 6 (Deliver). One file change reaches all ten skills with no per-skill edit.

**Plan Context sections** — three independent copies of the same guidance, no shared code path between them:
- `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` — the canonical section definitions `implementation-plan`'s Workflow Step 2.2 reads before drafting a spec.
- `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` — the copyable starter the same step also reads.
- `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` — `build-proposal`'s equivalent: both the prose section-order description (item 4) and its own copyable Skeleton code block.
- `~/.claude/reference/SKELETON.md` (outside this repo) — the global starter `~/.claude/rules/plan-mode.md` Step 2 tells any Claude Code session to copy for a new plan, in any project.

Worth knowing before touching any of these again: `implementation-plan` already has a `## Decisions` section, and `build-proposal` already has `Locked & resolved decisions` — both exist specifically so "a resumed session reads this instead of re-deriving" (verbatim from `section-catalog.md`). Context is the *why*; Decisions/Locked-decisions is the *settled how*. Don't merge them.

Not modified, but load-bearing context if extending verification-gate patterns elsewhere: `kit/plugins/plan-agent/skills/build/references/completion-gates.md` is this repo's reference implementation of a mandatory, bounded, escalate-rather-than-fake-success verification gate — the pattern the screenshot check is a lightweight instance of.

## Decisions

- **Screenshot check uses a 5,000-byte heuristic, not pixel inspection.** `wc -c` on the output file is free; a real "is this blank" check would need an image-decode dependency the pipeline doesn't have. A solid-color/blank PNG compresses far smaller than a populated card with text and a gradient, so byte count is a reasonable proxy. Marked with an inline `ponytail:` comment naming the ceiling (a legitimately sparse card could false-positive) and the upgrade path (real pixel sampling).
- **Verification runs after server cleanup, not before.** Step 5 sits after Step 4 (`kill $SERVER_PID`), so a failed verification never leaves the HTTP server orphaned — cleanup isn't gated on the check succeeding.
- **Context-section fix scope was cut down mid-session.** The original plan was a heavier rewrite of `implementation-plan`/`build-proposal`'s Context guidance. After reading `section-catalog.md`, `right-sizing.md`, and `artifact-shape.md` in full — not just `implementation-plan/SKILL.md`'s summary line — it became clear both skills already solve the cold-read problem via `## Decisions`/`Locked & resolved decisions`. The actual change shipped is one added sentence per file stating the completeness test in words, plus a clause naming the Context/Decisions boundary — not a restructure.
- **`~/.claude/rules/plan-mode.md`'s own Required Structure gloss for `context` was left untouched.** It's now slightly thinner than `SKELETON.md`'s copy ("Background and motivation; why this work is needed" vs. the strengthened placeholder). Not fixed because the request named `SKELETON.md` specifically, and `SKELETON.md` is the file actually copied into new plans — `plan-mode.md`'s line is reference prose, not copied. Practical fix landed in the higher-leverage file; the inconsistency is flagged below, not resolved.

## Tradeoffs and rejected options

- **Rejected: pixel-level screenshot verification.** More accurate than byte count, but needs an image-processing dependency not currently in the pipeline. Revisit if the 5KB heuristic produces false positives or negatives in practice — the `ponytail:` comment in `rendering-pipeline.md` names this as the upgrade path.
- **Rejected: a retry-on-failure loop for the screenshot step**, mirroring `plan-agent:build`'s 3-try fix loop. Out of scope for what was asked; current behavior on any Step 5 failure is the same single Fallback message the pipeline already used for other failure modes (Playwright unavailable, capture failure) — consistent, not new.
- **Rejected: rewriting the Context section definitions wholesale** in `implementation-plan`/`build-proposal`. Would have duplicated or blurred what `## Decisions`/`Locked & resolved decisions` already do. A one-sentence addition was chosen once the existing design was understood — see Decisions above.
- **Rejected: applying "unpack jargon on first use" broadly** across plan-mode/plan-agent writing style (raised earlier in the session as a general ELI5-vs-planning-workflow question). Conflicts on purpose with the existing "precise names over plain words" rule for an expert-engineer-only reader. Scoped out entirely — not partially applied anywhere.

## Learnings

- **A skill's top-level `SKILL.md` workflow steps can undersell how complete its `guidelines/`/`references/` files already are.** The Context-section gap was originally diagnosed from `implementation-plan/SKILL.md`'s one-line summary ("Optional by judgment: Context…") without reading `guidelines/section-catalog.md` or `guidelines/right-sizing.md` first. Those turned out to already solve the described problem, just under a different section name. Read the `guidelines/`/`references/` files before diagnosing a gap in a mature skill, not just the top-level workflow steps.
- **One shared reference file can back many skills in this plugin family.** `social-media-tools/references/rendering-pipeline.md` is read by ten separate `SKILL.md` files; the fix didn't need touching any of them. Worth checking for a shared reference before assuming a fix needs per-skill duplication.
- **No automated test exercises the Playwright screenshot pipeline end-to-end** — it needs a live browser, which this session didn't have. What ran instead (`test-no-shell-expansion.sh`, `test-react-card-smoke.sh`, `test-share-react-registration.sh`) confirms no shell-expansion regression and no template-registration regression, but none of them execute the new Step 5 logic against a real capture. That's a real coverage gap, not just an unexercised edge case — see Tests and verification below.

## Tests and verification

- `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` — run after each version bump (`social-media-tools` 2.23.0→2.23.1, `plan-agent` 9.4.1→9.4.2). Both pass.
- `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"` — run after each `marketplace.json` edit to confirm valid JSON.
- `tests/plugins/test-no-shell-expansion.sh` — pass. Confirms the new `$SAVE_PATH_PNG`/`$SIZE` variables in `rendering-pipeline.md` don't introduce a `${VAR}`-style expansion (this repo's Bash tool rejects those outright).
- `tests/social-media-tools/test-react-card-smoke.sh`, `tests/social-media-tools/test-share-react-registration.sh` — pass.
- `tests/plugins/test-build-proposal.sh`, `test-proposal-prompt-pipeline.sh`, `test-goal-prompt.sh`, `test-resources-section.sh`, `test-write-prompt-proposal-type.sh` — pass. None assert on the new Context-section prose specifically; expected, since the change is prose-only with no structural or parser-visible effect.
- `tests/plugins/test-humanized-skeleton.sh` — run, passed, and confirmed irrelevant on inspection (it checks the renderer's HTML output, not these markdown guideline/reference files).
- **Knowingly untested:** the screenshot verification logic was never run against a real Playwright capture — no live browser in this session. The 5KB threshold is unverified against an actual blank-vs-populated card pair.

## Review follow-ups and tech debt

- **Uncommitted:** `.claude-plugin/marketplace.json`, `kit/plugins/plan-agent/CHANGELOG.md`, `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md`, `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md`, `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md`. The plan-agent Context-completeness change is not yet committed or pushed.
- **Known ceiling, documented in place:** the screenshot Step 5's 5KB threshold is a byte-count heuristic (inline `ponytail:` comment in `rendering-pipeline.md`), untested against a real capture. Upgrade path if it misfires: sample actual pixel content instead of byte count.
- **Left inconsistent on purpose:** `~/.claude/rules/plan-mode.md`'s Required Structure line for `context` still reads "Background and motivation; why this work is needed" — thinner than the strengthened `SKELETON.md` it points at. Flagged mid-session as optional polish, not applied because it wasn't named in the request.
- **Not implemented this session** — three more gaps identified during the earlier plugin-review pass against the source article, no action taken beyond the screenshot fix:
  1. Only `plan-agent:build` uses an explicit completion-gate/"don't finish until X" pattern; roughly 30 of 63 skills in this repo have no verification step mentioned at all (some legitimately don't need one — routers, display-only skills).
  2. `code-review-agent` doesn't verify its own findings against cited line numbers before reporting them.
  3. Only 3 of 63 skills in the repo ship a worked example of their actual output shape.

## Files touched

**`social-media-tools` — committed (`0bedc78`, pushed to `claude/project-optimization-review-595e98`)**
- `kit/plugins/social-media-tools/references/rendering-pipeline.md` — added Step 5 (post-capture PNG existence/size check); widened Fallback's trigger to include verification failure.
- `kit/plugins/social-media-tools/CHANGELOG.md` — new `v2.23.1` entry.
- `.claude-plugin/marketplace.json` — `social-media-tools` 2.23.0 → 2.23.1.

**`plan-agent` — uncommitted**
- `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` — added the no-follow-up test and the Context/Decisions boundary sentence to the `## Context` entry.
- `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` — same addition to the copyable Context placeholder.
- `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` — same addition, two spots: the section-order description (item 4) and the copyable Skeleton block's Context placeholder.
- `kit/plugins/plan-agent/CHANGELOG.md` — new `9.4.2` entry.
- `.claude-plugin/marketplace.json` — `plan-agent` 9.4.1 → 9.4.2.

**Outside this repo — untracked, no version/changelog mechanism applies**
- `~/.claude/reference/SKELETON.md` — same Context-completeness addition, personal dotfiles.
