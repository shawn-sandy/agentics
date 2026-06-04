---
status: todo
type: fix
created: 2026-05-30
repo-name: agentics
---

# Plan: Auto-resolve marketplace.json version conflicts with a git merge driver

## Context

Every plugin's `version` lives in one shared file, `.claude-plugin/marketplace.json`, inside a single `plugins[]` array. The version guard — `scripts/check-version-bump.sh`, wired into both CI (`.github/workflows/version-guard.yml`) and a local `PostToolUse` hook in `.claude/settings.json` — requires every PR that touches a plugin's files to bump that plugin's version line in that same file.

The result: nearly every PR edits `marketplace.json`. When one PR merges to `main`, every other open PR goes stale and hits **both** problems repeatedly:

1. **Textual merge conflict** on the closely-packed `version` lines when rebasing on `main`.
2. **Version-guard failure** afterward, because the rebased version may now equal or trail the new `main` value.

The user wants this handled **without relying on CI**. The chosen approach is a **custom git merge driver**: git auto-resolves `marketplace.json` conflicts locally (during merge *and* rebase) by keeping the higher semver per plugin and unioning the arrays — so the textual conflict never reaches manual resolution, and the higher-version-wins rule keeps the guard satisfied in the common case (two PRs bumping *different* plugins).

This solves problem (1) completely and problem (2) for the common case. The rare residual — two PRs bumping the **same** plugin to the **same** version — is left to the existing guard, whose message already says exactly what to do ("bump version above X"). No CI changes are required; the existing guard stays as a safety net.

## Objective

Add a dependency-free git merge driver that auto-resolves `.claude-plugin/marketplace.json` conflicts by keeping `max(ours, theirs)` per-plugin semver and unioning `plugins[]`/`removed[]`, registered automatically per-clone so rebases and merges stop producing version conflicts.

## Files to create / modify

- **NEW** `scripts/merge-marketplace.mjs` — the merge driver (Node, no external deps).
- **NEW** `.gitattributes` — map `marketplace.json` to the driver.
- **NEW** `scripts/setup-merge-driver.sh` — idempotent `git config` registration of the driver.
- **NEW** `tests/fixtures/merge-marketplace/` — base/ours/theirs/expected fixtures for the driver.
- **EDIT** `.claude/settings.json` — add a `SessionStart` hook that runs `setup-merge-driver.sh` idempotently.
- **EDIT** `CONTRIBUTING.md` — document the one-time setup + the new conflict-free flow.
- **EDIT** `.claude/rules/marketplace.md` — note the merge driver as the version-conflict mechanism.

## Steps

1. **Write the merge driver `scripts/merge-marketplace.mjs`.** Accept the three git-supplied paths as argv: base (`%O`), ours (`%A`), theirs (`%B`). `JSON.parse` all three. Merge: union `plugins[]` and `removed[]` by `name` (keep "ours" order, append entries new in "theirs"); for each matching plugin and for the top-level `version`, set `max(ours, theirs)` using the same numeric-triplet semver comparison already implemented in `scripts/check-version-bump.sh`. Write the merged object back to the **ours path (`%A`)** with 2-space indent + trailing newline (matching the existing file). Exit `0` on success; exit `1` (leaving the file untouched so git keeps conflict markers) if any input fails to parse or a value is non-`X.Y.Z`.
   - *Why:* The driver is the whole solution — git invokes it on every conflicting merge/rebase of this file. Reusing the existing semver-compare logic keeps one definition of "higher version." Failing loudly (exit 1) on unparseable input avoids silently corrupting the registry.
   - *Verify:* `node scripts/merge-marketplace.mjs base.json ours.json theirs.json` against the fixtures from step 4 leaves `ours.json` equal to `expected.json` and exits 0; a malformed input exits 1.

2. **Create `.gitattributes`** at repo root containing `.claude-plugin/marketplace.json merge=mkt-version` (single line, trailing newline).
   - *Why:* `.gitattributes` is committed and tells git which files use the named driver. This is the only committed half of the wiring; the driver *definition* is per-clone (step 3).
   - *Verify:* `git check-attr merge -- .claude-plugin/marketplace.json` prints `merge: mkt-version`.

3. **Write `scripts/setup-merge-driver.sh`** — idempotent registration: `git config merge.mkt-version.name "marketplace.json version-aware merge"` and `git config merge.mkt-version.driver "node \"$(git rev-parse --show-toplevel)/scripts/merge-marketplace.mjs\" %O %A %B"`. Make it safe to run repeatedly (config set is idempotent) and a no-op outside a git work tree. `chmod +x`.
   - *Why:* Merge-driver *definitions* cannot be committed (they live in local `.git/config`), so every clone needs a one-time registration. A script makes it one command for humans and callable from the session hook.
   - *Verify:* Run the script, then `git config --get merge.mkt-version.driver` prints the expected `node … %O %A %B` command; running it twice does not duplicate or error.

4. **Add driver fixtures under `tests/fixtures/merge-marketplace/`** — `base.json`, `ours.json`, `theirs.json`, `expected.json` covering: (a) two *different* plugins bumped on each side (both bumps survive), (b) the *same* plugin bumped to different versions (higher wins), (c) a new plugin added only on "theirs" (appears in result), (d) top-level `version` differing (higher wins). Keep them minimal (2–3 plugins).
   - *Why:* Fixtures make the driver's behavior testable in isolation without fabricating git history, and document the intended resolution rules. Mirrors the existing `tests/fixtures/` convention.
   - *Verify:* Running the driver (step 1) on the fixtures reproduces `expected.json` byte-for-byte.

5. **Add a `SessionStart` hook to `.claude/settings.json`** that runs `test -f scripts/setup-merge-driver.sh && bash scripts/setup-merge-driver.sh >/dev/null 2>&1 || true`, so any Claude Code session in this repo self-registers the driver. Preserve the existing `PostToolUse` block exactly.
   - *Why:* Removes the manual setup step for the primary workflow (Claude Code sessions) while staying idempotent and silent; non-Claude contributors get the CONTRIBUTING instruction instead. Keeps the "no CI" promise — nothing runs server-side.
   - *Verify:* `jq '.hooks | keys' .claude/settings.json` shows both `PostToolUse` and `SessionStart`; `jq empty .claude/settings.json` passes; a fresh session leaves `merge.mkt-version.driver` configured.

6. **Document the flow in `CONTRIBUTING.md` and `.claude/rules/marketplace.md`.** In CONTRIBUTING: a short "First-time setup" line (`bash scripts/setup-merge-driver.sh`) and a note that `marketplace.json` version conflicts now auto-resolve to the higher version on rebase/merge. In `marketplace.md`: under versioning, note the merge driver resolves concurrent bumps and that the guard still enforces "bump above main" for same-plugin same-version collisions.
   - *Why:* Non-Claude contributors need the one-time command; future maintainers need to know conflicts are auto-resolved by design (not by hand) so they don't "fix" the driver away.
   - *Verify:* Both files render the new section; the CONTRIBUTING command matches the script path exactly.

## Acceptance Criteria

- [ ] Two branches bumping **different** plugins merge/rebase onto each other with **no conflict markers** in `marketplace.json`, and both bumps are present in the result.
- [ ] Two branches bumping the **same** plugin to different versions resolve to the **higher** version automatically.
- [ ] A plugin added on only one side survives the merge (no entry lost).
- [ ] `git check-attr merge -- .claude-plugin/marketplace.json` reports `mkt-version`.
- [ ] After `setup-merge-driver.sh` (or a fresh Claude Code session), `git config --get merge.mkt-version.driver` is set.
- [ ] The merged `marketplace.json` is valid JSON (`jq empty` passes) with unchanged 2-space formatting.
- [ ] The existing version-guard (`scripts/check-version-bump.sh`, CI, local hook) is unmodified and still runs.
- [ ] No new CI workflow is added.

## Verification

End-to-end, on a throwaway clone or branches (driver registered via step 3):

1. From `main`, create branch `a` bumping plugin **memory-tools** and branch `b` bumping plugin **code-review** (different plugins, different version lines).
2. Merge `a` into `main`, then rebase `b` onto the new `main`: confirm git reports the `marketplace.json` conflict was **auto-resolved** (no markers, no manual edit), both bumps present, `jq empty` passes.
3. Repeat with both branches bumping the **same** plugin to different versions; confirm the higher version wins automatically.
4. Run `node scripts/merge-marketplace.mjs` against `tests/fixtures/merge-marketplace/{base,ours,theirs}.json` and diff the output against `expected.json` — must match byte-for-byte.
5. Confirm the version guard still behaves: a branch that changes a plugin's files but leaves its version equal to main still fails `bash scripts/check-version-bump.sh` (safety net intact).
6. `jq '.hooks | keys' .claude/settings.json` shows `PostToolUse` + `SessionStart`; `jq empty .claude/settings.json` passes.

## Next Steps *(optional)*

- Wire same-plugin auto-rebump into git-agent:
  ```text
  In the agentics repo, extend kit/plugins/git-agent/skills/ship-autonomous so that when the Version Guard check fails because a plugin's resolved version equals main after a merge-driver resolution, it auto-increments that plugin's PATCH version in .claude-plugin/marketplace.json, adds the matching CHANGELOG.md entry, and re-pushes — bounded to one attempt. Reuse scripts/check-version-bump.sh to detect the condition.
  ```

- Add a CI guard that the driver stays wired:
  ```text
  In the agentics repo, add a lightweight CI step (or extend version-guard.yml) that asserts .gitattributes maps .claude-plugin/marketplace.json to merge=mkt-version and that scripts/merge-marketplace.mjs exists and passes its fixture test under tests/fixtures/merge-marketplace/. This catches accidental removal of the merge-driver wiring.
  ```
