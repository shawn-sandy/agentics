---
status: completed
type: artifact
created: 2026-05-11
---

# Plan: SKILL.md description-length warning — hook + command

## Context

The `optimizing-descriptions` skill (`kit/plugins/skill-reviewer/skills/optimizing-descriptions/SKILL.md`) targets a ≤160-char budget for skill `description:` frontmatter. The rationale is the default `skillListingBudgetFraction` (1% of context ≈ 8,000 chars for ~50 skills ≈ 160 chars each); over-budget descriptions risk being truncated or dropped from the skill listing at runtime.

Today there is no automated feedback when an over-long description is written. Authors discover the problem only when they remember to manually run the skill. After a stress-test interview, the agreed approach combines an **always-on hook** with a **named slash command**, both sharing a single measurement script, plus a one-time **audit** of existing over-budget skills so the hook does not warn on pre-existing content the contributor did not introduce.

References:

- Repo-level hooks pattern in [`.claude/settings.json`](../../.claude/settings.json) (lines 10–31) — two PostToolUse `Write|Edit` matchers with inline `OK:` / `WARNING:` echoes.
- Plugin-shipped hooks precedent in [`kit/plugins/plan-interview/hooks.json`](../../kit/plugins/plan-interview/hooks.json) — a plugin that ships its own hooks file alongside `plugin.json`.
- Command pattern documented in [`.claude/rules/plugin-patterns.md`](../../.claude/rules/plugin-patterns.md) — YAML frontmatter + markdown body, invoked via `/plugin-name:command-name`.
- Measurement logic source-of-truth: Step 5 of [`kit/plugins/skill-reviewer/skills/optimizing-descriptions/SKILL.md`](../../kit/plugins/skill-reviewer/skills/optimizing-descriptions/SKILL.md).

## Objective

Add the following to the `skill-reviewer` plugin:

1. **`scripts/measure-description.sh`** — single source of truth for description measurement, called by both surfaces. Handles missing description (`ERROR`), multi-line/folded YAML (`WARNING: approximate`), and emits `OK:` / `WARNING:` with character counts.
2. **`hooks.json`** — PostToolUse hook matching `Write|Edit|MultiEdit`. Extracts `file_path` from the event payload (with a MultiEdit fallback path), invokes the shared script, and dedups so it fires only when the `description:` line actually changes.
3. **`commands/check-description.md`** — slash command `/skill-reviewer:check-description [path-or-glob]` that calls the shared script on demand for one or many files.
4. **`tests/fixtures/skill-description-hook/`** — fixture SKILL.md files at 160, 161, and 200 chars, a missing-description fixture, and a multi-line fixture, plus a bash harness (`run.sh`) that calls `scripts/measure-description.sh` directly and asserts on its output. Note: the harness tests the shared script surface, not the hook’s dedup or repo-guard logic.

Prerequisite: audit and trim existing over-budget descriptions in `kit/plugins/` so the hook does not warn on already-shipped content.

## Files to modify

<ul>
  <li><strong>Audit (pre-step):</strong> any <code>kit/plugins/&lt;plugin&gt;/skills/&lt;skill&gt;/SKILL.md</code> whose <code>description:</code> currently exceeds 160 chars.</li>
  <li><strong>New:</strong> <code>kit/plugins/skill-reviewer/scripts/measure-description.sh</code> — shared measurement script (committed with <code>+x</code>).</li>
  <li><strong>New:</strong> <code>kit/plugins/skill-reviewer/hooks.json</code> — PostToolUse hook entry.</li>
  <li><strong>New:</strong> <code>kit/plugins/skill-reviewer/commands/check-description.md</code> — user-invokable slash command.</li>
  <li><strong>New:</strong> <code>tests/fixtures/skill-description-hook/</code> — fixtures (<code>desc-160.md</code>, <code>desc-161.md</code>, <code>desc-200.md</code>, <code>desc-missing.md</code>, <code>desc-multiline.md</code>) and harness (<code>run.sh</code>).</li>
  <li><strong>Edit:</strong> <code>kit/plugins/skill-reviewer/README.md</code> — document hook, command, shared script, audit history, and disable instructions.</li>
  <li><strong>Edit:</strong> <code>kit/plugins/skill-reviewer/CHANGELOG.md</code> — single MINOR-bump entry covering all new components.</li>
  <li><strong>Edit:</strong> <code>.claude-plugin/marketplace.json</code> — bump <code>skill-reviewer</code> version (MINOR).</li>
</ul>

## Steps

<ol>
  <li>
    <strong>Audit existing SKILL.md files and trim over-budget descriptions.</strong>
    <br/><em>Why:</em> Without this pre-step, the new hook will warn on already-shipped over-budget descriptions the moment a contributor edits an unrelated section of those files — creating churn for problems they did not introduce.
    <br/><em>Verify:</em> Run an audit one-liner that iterates every <code>kit/plugins/**/SKILL.md</code>, extracts the description value, and prints any file whose value exceeds 160 chars. Confirm zero output. Concretely: a <code>find kit/plugins -name SKILL.md</code> piped through a shell loop that applies the same extract-strip logic as Step 5 of <code>optimizing-descriptions/SKILL.md</code> and echoes <code>&quot;$file: $len&quot;</code> only when <code>$len -gt 160</code>.
    <br/><br/>
    For each over-budget file, run <code>/skill-reviewer:optimizing-descriptions</code> on it and apply the rewrite. Commit the audit as its own commit so the hook addition lands on a clean baseline.
  </li>

  <li>
    <strong>Create <code>kit/plugins/skill-reviewer/scripts/measure-description.sh</code></strong> as the single source of truth for measurement.
    <br/><em>Why:</em> Both the hook and the slash command need identical extract/strip/measure logic. Inline duplication in two surfaces would drift.
    <br/><em>Verify:</em> Script is executable (<code>test -x kit/plugins/skill-reviewer/scripts/measure-description.sh</code>); <code>git ls-files --stage</code> shows mode <code>100755</code> for the file; invoking <code>./scripts/measure-description.sh tests/fixtures/skill-description-hook/desc-200.md</code> emits the expected <code>WARNING:</code> line.
    <br/><br/>
    Script contract:
    <ul>
      <li>Argument: one file path.</li>
      <li>Exit 0 in all measurable cases; exit non-zero only for unreadable file.</li>
      <li>Output on stdout, one line:
        <ul>
          <li><code>OK: SKILL.md description is N chars (≤160) in &lt;path&gt;</code> — when ≤160 and well-formed.</li>
          <li><code>WARNING: SKILL.md description is N chars (&gt;160) in &lt;path&gt; — run /skill-reviewer:optimizing-descriptions to trim</code> — when over-budget.</li>
          <li><code>WARNING: multi-line description detected in &lt;path&gt; — measurement may be approximate; run /skill-reviewer:optimizing-descriptions</code> — when the first <code>description:</code> line is empty/folded.</li>
          <li><code>ERROR: SKILL.md has no description: frontmatter in &lt;path&gt; — required by Claude Code</code> — when no <code>description:</code> line found.</li>
        </ul>
      </li>
      <li>Internal logic: reuse the exact extract-strip parameter expansion from Step 5 of <code>optimizing-descriptions/SKILL.md</code>. Detect multi-line when the stripped value is empty AND the immediately-following line is indented (folded scalar).</li>
      <li>Commit with executable bit: <code>git update-index --chmod=+x kit/plugins/skill-reviewer/scripts/measure-description.sh</code>.</li>
    </ul>
  </li>

  <li>
    <strong>Create <code>kit/plugins/skill-reviewer/hooks.json</code></strong> registering a PostToolUse hook that calls the shared script with dedup.
    <br/><em>Why:</em> The always-on warning surface. Must match <code>Write|Edit|MultiEdit</code> (covers all the ways a SKILL.md gets written), tolerate MultiEdit’s different payload shape, and avoid firing on every keystroke-equivalent save by deduping on the <code>description:</code> line hash.
    <br/><em>Verify:</em> <code>jq empty kit/plugins/skill-reviewer/hooks.json</code> exits 0; the matcher is <code>&quot;Write|Edit|MultiEdit&quot;</code>; the command string includes the dedup state-file logic.
    <br/><br/>
    Hook command (POSIX shell; reads tool event JSON on stdin):
    <pre><code>file=$(jq -r '.tool_input.file_path // .tool_input.edits[0].file_path // empty' 2&gt;/dev/null); case &quot;$file&quot; in *SKILL.md) ;; *) exit 0 ;; esac; [ -f &quot;$file&quot; ] || exit 0; repo_root=$(git -C &quot;$(dirname &quot;$file&quot;)&quot; rev-parse --show-toplevel 2&gt;/dev/null); [ -n &quot;$repo_root&quot; ] &amp;&amp; case &quot;$file&quot; in &quot;$repo_root&quot;/*) ;; *) exit 0 ;; esac; [ -n &quot;$repo_root&quot; ] || exit 0; line=$(grep &quot;^description:&quot; &quot;$file&quot; | head -1); state=&quot;/tmp/skill-desc-hook-$(printf '%s' &quot;$file&quot; | shasum -a 256 | cut -d' ' -f1).hash&quot;; new=$(printf '%s' &quot;$line&quot; | shasum -a 256 | cut -d' ' -f1); old=$(cat &quot;$state&quot; 2&gt;/dev/null); [ &quot;$new&quot; = &quot;$old&quot; ] &amp;&amp; exit 0; printf '%s' &quot;$new&quot; &gt; &quot;$state&quot;; &quot;${CLAUDE_PLUGIN_ROOT}/scripts/measure-description.sh&quot; &quot;$file&quot;</code></pre>
    <br/>
    Notes:
    <ul>
      <li><strong>Payload extraction:</strong> falls back through <code>.tool_input.file_path</code> (Write/Edit) then <code>.tool_input.edits[0].file_path</code> (MultiEdit).</li>
      <li><strong>Repo-local guard (replaces “any *SKILL.md” scoping):</strong> after resolving <code>file</code>, the hook runs <code>git -C &quot;$(dirname &quot;$file&quot;)&quot; rev-parse --show-toplevel</code> to find the owning git repository. If the file is not inside a git repo (exit non-zero) OR it is in a different repo than where the hook is running, the hook exits silently. This ensures the hook only fires on SKILL.md files that are actively being developed in the current project — external plugins installed to <code>~/.claude/plugins/</code> or other paths outside the repo root are silently skipped. If <code>git</code> is unavailable, the hook exits silently (fail-safe).</li>
      <li><strong>Dedup contract:</strong>
        <ul>
          <li>Key file: <code>/tmp/skill-desc-hook-&lt;sha256-of-absolute-path&gt;.hash</code>.</li>
          <li>Value: sha256 of the literal <code>description:</code> line (including the prefix), or empty string if no such line.</li>
          <li>First write (no prior hash) → fires (empty ≠ new hash), then persists the new hash.</li>
          <li>Subsequent writes with unchanged <code>description:</code> line → silent exit before invoking the script.</li>
          <li>Cleanup: relies on OS <code>/tmp</code> cleanup (macOS purges on boot; Linux varies by tmpfiles config). Stale entries cause at most one missed warning on the first invocation after cleanup, which is acceptable.</li>
        </ul>
      </li>
      <li><strong>Script reference:</strong> uses <code>${CLAUDE_PLUGIN_ROOT}</code> which Claude Code sets to the plugin’s installed root directory. Verify both <code>--plugin-dir</code> dev mode and <code>/plugin install</code> mode in Step 9.</li>
      <li><strong>Output:</strong> the shared script’s one-line message is echoed to the hook’s stdout, matching the existing <code>OK:</code> / <code>WARNING:</code> / <code>ERROR:</code> prefix convention used by repo-level hooks.</li>
    </ul>
  </li>

  <li>
    <strong>Create <code>kit/plugins/skill-reviewer/commands/check-description.md</code></strong> as a thin wrapper that calls the shared script.
    <br/><em>Why:</em> The user-invokable surface for ad-hoc and batch checks (e.g. files the user has not edited this session). Must not re-spec the bash inline — it calls the same shared script the hook uses, so a threshold change in one place applies everywhere.
    <br/><em>Verify:</em> The command file exists with valid YAML frontmatter and a one-sentence <code>description:</code>; invoking <code>/skill-reviewer:check-description</code> with no argument lists every <code>**/SKILL.md</code> with measurement output; invoking it with a path argument measures that one file.
    <br/><br/>
    Frontmatter and body (the body instructs Claude to resolve targets and call the shared script):
    <pre><code>---
description: Measure description-frontmatter length for one or more SKILL.md files via the shared measure-description.sh script and warn if any exceed the 160-char budget.
---

# Check SKILL.md description length

Run the shared measurement script on one or more SKILL.md files.

## Resolve target files

- If `$ARGUMENTS` is empty: use `Glob` for `**/SKILL.md` from `$PWD`.
- If `$ARGUMENTS` is a path to an existing file ending in `SKILL.md`: use it directly.
- If `$ARGUMENTS` looks like a glob: use `Glob` with the pattern.
- Otherwise: ask the user to clarify.

## Measure each file

For each resolved file, run the shared script:

```bash
&quot;${CLAUDE_PLUGIN_ROOT}/scripts/measure-description.sh&quot; &quot;$file&quot;
```

This emits one line per file: `OK:`, `WARNING:` (over budget), `WARNING:` (multi-line), or `ERROR:` (missing description).

## Report

Print all script output. For any over-budget file, suggest running `/skill-reviewer:optimizing-descriptions` to trim it (the script’s WARNING message already includes this pointer).
</code></pre>
  </li>

  <li>
    <strong>Create <code>tests/fixtures/skill-description-hook/</code></strong> with fixture SKILL.md files and a harness.
    <br/><em>Why:</em> Manual verification in a Claude session catches gross failures but does not exercise edge cases (exactly-160, exactly-161, missing description, multi-line). A bash harness that pipes synthetic PostToolUse JSON into the hook command catches regressions automatically.
    <br/><em>Verify:</em> Running <code>tests/fixtures/skill-description-hook/run.sh</code> produces zero failed assertions; each fixture file’s expected output (recorded inline in the harness) matches actual output.
    <br/><br/>
    Files:
    <ul>
      <li><code>desc-160.md</code> — description exactly 160 chars → expect <code>OK: 160 chars</code>.</li>
      <li><code>desc-161.md</code> — description exactly 161 chars → expect <code>WARNING: 161 chars (&gt;160)</code>.</li>
      <li><code>desc-200.md</code> — description 200 chars → expect <code>WARNING: 200 chars (&gt;160)</code>.</li>
      <li><code>desc-missing.md</code> — no <code>description:</code> line → expect <code>ERROR: no description:</code>.</li>
      <li><code>desc-multiline.md</code> — <code>description: |</code> literal block scalar → expect <code>WARNING: multi-line</code>.</li>
      <li><code>run.sh</code> — harness that for each fixture: calls <code>scripts/measure-description.sh</code> directly and asserts the expected output prefix and char-count match.</li>
    </ul>
  </li>

  <li>
    <strong>Update <code>kit/plugins/skill-reviewer/README.md</code></strong> to document every new component.
    <br/><em>Why:</em> Plugin patterns rule requires README documentation of all components. Users seeing the warning need to know its origin and how to silence it.
    <br/><em>Verify:</em> README contains: a “Hooks” section referencing <code>hooks.json</code> and the 160-char target; a “Commands” entry for <code>/skill-reviewer:check-description</code> with usage; a note about the shared script at <code>scripts/measure-description.sh</code>; a note that existing skills were audited and trimmed; explicit disable instructions (override <code>hooks</code> in user <code>.claude/settings.json</code>).
  </li>

  <li>
    <strong>Append a MINOR-bump entry to <code>kit/plugins/skill-reviewer/CHANGELOG.md</code>.</strong>
    <br/><em>Why:</em> <code>.claude/rules/marketplace.md</code> classifies “new hook” and “new command” each as MINOR; one combined entry covers both.
    <br/><em>Verify:</em> CHANGELOG.md has a new top entry with the bumped version and one-line descriptions of: hook, command, shared script, test fixture, and the existing-skills audit.
  </li>

  <li>
    <strong>Bump <code>skill-reviewer</code> version in <code>.claude-plugin/marketplace.json</code>.</strong>
    <br/><em>Why:</em> Version lives in marketplace.json for relative-path plugins; CHANGELOG and marketplace version must agree.
    <br/><em>Verify:</em> <code>jq '.plugins[] | select(.name==&quot;skill-reviewer&quot;) | .version' .claude-plugin/marketplace.json</code> returns the new version and matches the latest CHANGELOG entry.
  </li>
</ol>

## Verification

End-to-end test, run **both** modes (dev `--plugin-dir` AND installed `/plugin install`) and capture each result:

<ol>
  <li><strong>Fixture harness:</strong> Run <code>tests/fixtures/skill-description-hook/run.sh</code> — all assertions pass.</li>
  <li><strong>Hook — under budget:</strong> In a Claude session, ask Claude to <code>Edit</code> a SKILL.md whose description is &lt;160 chars and changes the description line. Expect <code>OK: SKILL.md description is N chars (≤160)</code>.</li>
  <li><strong>Hook — over budget:</strong> Edit the description to a 200-char string. Expect <code>WARNING: 200 chars (&gt;160) — run /skill-reviewer:optimizing-descriptions</code>.</li>
  <li><strong>Hook — dedup:</strong> Edit a non-description part of the same SKILL.md. Expect <strong>no output</strong> (the <code>description:</code> line hash is unchanged).</li>
  <li><strong>Hook — missing description:</strong> Write a SKILL.md with no <code>description:</code> line. Expect <code>ERROR: no description: frontmatter</code>.</li>
  <li><strong>Hook — multi-line description:</strong> Write a SKILL.md with <code>description: |</code> literal block scalar. Expect <code>WARNING: multi-line description detected</code>.</li>
  <li><strong>Hook — MultiEdit:</strong> Use a MultiEdit operation to change a SKILL.md’s description. Expect the same warning behavior as Edit (the fallback jq path resolves correctly).</li>
  <li><strong>Hook — no-op (wrong file type):</strong> <code>Write</code> a non-SKILL.md file (e.g. README.md). Expect zero output (early <code>exit 0</code>).</li>
  <li><strong>Hook — no-op (external plugin):</strong> Simulate an external SKILL.md path outside the repo root (e.g. <code>/tmp/external-plugin/SKILL.md</code>) by temporarily hardcoding a fake path into the payload. Expect zero output — the git-root guard should reject it silently.</li>
  <li><strong>Installed-mode parity:</strong> <code>/plugin install skill-reviewer@agentics-kit</code> in a fresh session, then repeat tests 2 and 3. Expect identical output. Verifies <code>${CLAUDE_PLUGIN_ROOT}</code> resolves and the script is executable post-install.</li>
  <li><strong>Exec bit:</strong> <code>git ls-files --stage kit/plugins/skill-reviewer/scripts/measure-description.sh</code> shows mode <code>100755</code>.</li>
  <li><strong>Optimizing-descriptions non-loop:</strong> Run <code>/skill-reviewer:optimizing-descriptions</code> on a SKILL.md the hook just warned on. The edit-to-trim should produce a single <code>OK:</code> message from the hook, not a loop or duplicate warning.</li>
  <li><strong>Existing repo hooks still fire:</strong> Edit any file to trigger the existing repo-level PostToolUse hooks (marketplace.json validator, plan-hygiene warning). Both still emit their <code>OK:</code>/<code>WARNING:</code> output alongside the new plugin hook.</li>
  <li><strong>Command — single file:</strong> Run <code>/skill-reviewer:check-description kit/plugins/skill-reviewer/skills/optimizing-descriptions/SKILL.md</code> — reports one line for that file.</li>
  <li><strong>Command — no-arg:</strong> Run <code>/skill-reviewer:check-description</code> from the repo root — reports one line per <code>**/SKILL.md</code>.</li>
  <li><strong>Audit baseline:</strong> Confirm step 1 left zero over-budget SKILL.md files in <code>kit/plugins/</code> (re-run the audit one-liner from Step 1 and expect zero output).</li>
  <li><strong>JSON validity:</strong> <code>jq empty kit/plugins/skill-reviewer/hooks.json</code> and <code>jq empty .claude-plugin/marketplace.json</code> both exit 0.</li>
</ol>

## Next steps (out of scope)

- Generalize the script to also warn on the 1,024-char platform hard limit (currently only the 160-char budget target).
- Add a companion hook that runs `auditing-allowed-tools` recommendations on SKILL.md writes that change `allowed-tools:`.
- Add a `.claude/rules/hook-authoring.md` codifying the `OK:`/`WARNING:`/`ERROR:` echo convention and the dedup-state pattern (none exists today — `plugin-patterns.md` covers commands and skills only).
- Add a `--quiet` or threshold-override flag to the slash command for users who want a different budget (e.g. ~286 chars for ≤28-skill setups, per the budget advisory in `optimizing-descriptions/SKILL.md`).
- Extend the test fixture harness to also exercise the slash command end-to-end (currently only the hook).

## Interview Summary

Conducted via `/plan-interview:plan-interview` on 2026-05-11.

### Key decisions confirmed

- **Filename renamed** from `add-a-hook-that-snappy-petal.md` → `add-skill-description-length-hook.md`.
- **Both** activation surfaces — always-on hook AND named slash command.
- **Hook matcher:** `Write|Edit|MultiEdit` with jq fallback path for MultiEdit’s `edits[0].file_path` shape.
- **Shared script** at `scripts/measure-description.sh` is the single source of truth; hook and command both call it.
- **Edge inputs:** missing `description:` → `ERROR`; multi-line/folded YAML → `WARNING: approximate`.
- **Dedup:** hook fires only when the `description:` line hash changes (state in `/tmp`).
- **Path scoping:** repo-local guard — fires only for `*SKILL.md` paths inside the current git repo; external/installed plugin paths are skipped.
- **Backfill pre-step:** audit and trim existing over-budget SKILL.md files in `kit/plugins/` before shipping the hook.
- **Test coverage:** unit-style bash fixture at `tests/fixtures/skill-description-hook/` covering 160 / 161 / 200 / missing / multi-line cases.

### Open risks recorded

- `${CLAUDE_PLUGIN_ROOT}` resolution must be verified in both `--plugin-dir` and `/plugin install` modes (Verification step 10).
- Script exec bit must be committed with `git update-index --chmod=+x` (Verification step 11).
- Hook output visibility (Claude-side vs. user-side) confirmed by Verification steps 2–7 — if the warning never reaches a human, value is reduced.
- Dedup state semantics documented in Step 3 (key format, first-write behavior, cleanup policy).

### Simplification opportunity noted (not adopted)

The scope grew ~5× from the original “warn me if >160” ask. A simpler v1 could ship the hook + shared script only and defer the command, fixture, dedup, and audit to follow-up PRs. The user elected the comprehensive single-PR approach; if implementation feels heavy, the staged approach remains a viable fallback.
