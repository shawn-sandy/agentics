# Harden ship preflight

> Upgrades the git-agent ship pre-flight to run all checks then report together, adds an env-parity check for worktrees, a browser probe with UNVERIFIED marker, and an external-blocker CI class.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [harden-ship-preflight.md](plans/harden-ship-preflight.md)
**Type:** fix

## What shipped

- Changed pre-flight from fail-fast to run-all-then-report: all checks run before surfacing failures.
- Added env-parity check: warns when a worktree is missing `.env` files present in the main checkout.
- Added browser probe step: launches a headless browser smoke-test and marks results `UNVERIFIED` when the probe can't connect.
- Added external-blocker CI class: a separate category for CI failures caused by infrastructure outside the PR's scope.
- Bumped git-agent to 4.17.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/ship/references/preflight-and-verify.md` | Pre-flight reference | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill core | Modified |
| `kit/plugins/git-agent/skills/ship/references/preflight-guards.md` | Guard rules | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR agent core | Modified |
| `kit/plugins/git-agent/skills/ship/references/ci-autofix.md` | CI autofix reference | Modified |
| `kit/plugins/git-agent/README.md` | Plugin readme | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/test-ship-preflight.sh` | Pre-flight tests | Created |

## How it works

The run-all-then-report change means a PR with three pre-flight failures surfaces all three at once instead of stopping at the first. This reduces round-trips: one review cycle catches every issue rather than revealing them one at a time.

The env-parity check compares `.env*` files in the main checkout against those in the active worktree. Worktrees share the git object store but not the working-tree files, so a `.env.local` added to the main checkout is invisible in a worktree that predates it. Missing env files cause confusing runtime errors rather than clear pre-flight failures.

The browser probe step uses a headless Chromium launch to verify that a dev server (when started by the build) is reachable and returns a non-error page. When the probe can't connect — because no server was started, or it crashed — the smoke-test result is stamped `UNVERIFIED` in the pre-flight report rather than failing outright, since some repos have no web server to probe.

The external-blocker CI class separates infrastructure failures (runner outages, dependency registry timeouts, billing-blocked quota) from code failures. A CI check in the external-blocker class is surfaced as a warning rather than a blocking failure, since re-running the check without any code change is the correct response.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [harden-ship-preflight.md](plans/harden-ship-preflight.md)
