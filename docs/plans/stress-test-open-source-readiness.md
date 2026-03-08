# Stress Test: Open-Source Readiness Plan

## Context

The open-source readiness plan (`docs/plans/open-source-readiness-plan.md`) proposes 4 phases to prepare this repo for public release. This stress test identifies gaps, risks, and missed items.

---

## Round 1: What the Plan Gets Right

The plan correctly identifies the highest-visibility issues:
- Broken clone URLs, stale versions, missing plugins in README
- Hardcoded local paths in README and CLAUDE.md
- Copyright mismatch
- Need for CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
- Extracting non-existent API content to ROADMAP.md

These are solid Phase 1/2 priorities. No objections.

---

## Round 2: Critical Gaps the Plan Missed

### Gap 1: `.claude/settings.json` is tracked in git with personal paths
**Severity:** CRITICAL
**File:** `.claude/settings.json`
```json
"Bash(git -C /Users/shawnsandy/devbox/agentics ls-files)"
```
The plan mentions fixing CLAUDE.md paths but **completely misses** that `.claude/settings.json` is version-controlled and contains a macOS-specific absolute path. This file should either:
- Be added to `.gitignore` (it's machine-specific config), or
- Have the personal path removed

**Recommendation:** Add `.claude/settings.json` to `.gitignore` and remove it from tracking. Machine-specific permissions don't belong in a shared repo.

### Gap 2: `plugins/hello-world/TESTING.md` has hardcoded personal paths
**Severity:** CRITICAL
**File:** `plugins/hello-world/TESTING.md`
Contains multiple occurrences of `/Users/shawnsandy/devbox/agentics` — a macOS personal path. The plan only addresses README.md and CLAUDE.md paths but doesn't audit plugin-level documentation for the same issue.

**Recommendation:** Search ALL `.md` files for `/Users/shawnsandy`, `~/devbox`, and other personal path patterns. Fix them globally, not just in the two files mentioned.

### Gap 3: `plugins/README.md` also only lists 5 of 9 plugins
**Severity:** HIGH
The plan correctly identifies that the main README is missing 4 plugins, but doesn't mention that `plugins/README.md` has the exact same problem — it only documents hello-world, dev-tools, code-review, plan-interview, and claude-md-optimizer. The 4 newer plugins (wcag-compliance-reviewer, skill-reviewer, code-test-suggestion, git-agent) are missing there too.

**Recommendation:** Add item to Phase 1 to update `plugins/README.md` alongside the main README.

### Gap 4: Plan files contain personal paths too
**Severity:** MODERATE
Multiple files in `docs/plans/*.md` contain `/Users/shawnsandy/devbox/agentics` and `~/devbox/agentics`. Since the user chose to **keep** the plan files, these personal paths will be visible publicly.

**Recommendation:** Do a global find-and-replace across `docs/plans/` to genericize personal paths, or accept this as low-priority since plan files are historical artifacts.

---

## Round 3: Risks and Sequencing Issues

### Risk 1: README editing scope is massive
The plan touches README.md in **7 of the 10 Phase 1 items** plus Phase 2. That's a lot of edits to one file. Risk of merge conflicts if done incrementally or if the plan is interrupted.

**Recommendation:** Batch all README changes into a single coherent rewrite rather than 7 separate edits. This reduces risk and produces a more cohesive document.

### Risk 2: No verification step for the completed work
The plan has no "how to verify" section. After making all these changes, how do you confirm nothing is broken?

**Recommendation:** Add a verification checklist:
- [ ] `grep -r '/Users/shawnsandy' .` returns zero results (no personal paths)
- [ ] `grep -r 'yourusername' .` returns zero results (no placeholder URLs)
- [ ] All 9 plugins listed in README match marketplace.json names and versions
- [ ] All internal links in README resolve to existing files
- [ ] `plugins/README.md` lists all 9 plugins
- [ ] `.claude/settings.json` is either cleaned or gitignored

### Risk 3: GitHub workflow uses external marketplace, not local
**File:** `.github/workflows/claude-code-review.yml`
The workflow references `anthropics/claude-code` marketplace and `code-review@claude-code-plugins` — not the local agentics-kit. This isn't necessarily wrong (it may be intentional), but external contributors might expect the repo's own plugins to be used in CI.

**Recommendation:** Document this intentional choice or update the workflow to use the local marketplace.

---

## Round 4: Questionable Decisions

### Decision: Creating 3 separate issue templates
The plan proposes `bug_report.md`, `feature_request.md`, and `new_plugin.md`. For a repo this size (9 plugins, no runtime code), 3 templates may be over-engineering. A single well-structured template or just the default GitHub issue form might suffice until the community grows.

**Recommendation:** Start with 1 template (bug report) and the default form. Add more when needed.

### Decision: ROADMAP.md as a separate file
Moving API plans to ROADMAP.md is reasonable, but roadmap files tend to go stale fast. If nobody maintains it, it becomes another source of outdated information.

**Recommendation:** Keep ROADMAP.md minimal — a short list of planned features with no implementation details. Link to GitHub Issues/Discussions for living roadmap tracking.

### Decision: Phase 4 "verify all plugin CHANGELOGs exist"
Some plugins may not have meaningful changelog entries yet. Creating placeholder CHANGELOGs just to check a box adds noise without value.

**Recommendation:** Only create CHANGELOGs for plugins that have had multiple versions. Skip for v1.0.0 plugins where the changelog would just say "Initial release."

---

## Round 5: What's Missing Entirely

### Missing 1: No `.gitignore` audit
The plan doesn't check whether `.gitignore` properly excludes things like `.claude/settings.json`, `.claude.local.md`, `.env`, `node_modules`, OS files (`.DS_Store`), etc. For an open-source repo, a clean `.gitignore` is essential.

### Missing 2: No license check on individual plugins
Several `plugin.json` files include `"license": "MIT"` but the plan doesn't verify this is consistent across all 9 plugins. If some say MIT and others say nothing, that creates ambiguity.

### Missing 3: No consideration of GitHub repo settings
Going public isn't just about files — the GitHub repo itself needs:
- A proper description and topics/tags
- "About" section filled in
- Discussions enabled (optional)
- Branch protection on `main`

This is outside the plan's scope but worth a reminder.

---

## Summary: Amendments Needed

| Priority | Amendment | Add to Phase |
|----------|-----------|-------------|
| CRITICAL | Gitignore + remove `.claude/settings.json` from tracking | Phase 1 |
| CRITICAL | Fix personal paths in `plugins/hello-world/TESTING.md` | Phase 1 |
| CRITICAL | Global search for ALL personal paths across ALL files | Phase 1 |
| HIGH | Update `plugins/README.md` (not just main README) with all 9 plugins | Phase 1 |
| MODERATE | Add verification checklist to the plan | Phase 1 |
| MODERATE | Batch all README edits into one coherent rewrite | Execution strategy |
| LOW | Simplify to 1 issue template instead of 3 | Phase 3 |
| LOW | Audit `.gitignore` completeness | Phase 1 |
| LOW | Verify license consistency across all plugin.json files | Phase 4 |

The plan is **solid in direction but incomplete in scope**. The biggest miss is that personal paths exist in more places than just README.md and CLAUDE.md — they're in `.claude/settings.json`, `plugins/hello-world/TESTING.md`, and scattered across `docs/plans/`. A global sweep is needed, not targeted file-by-file fixes.
