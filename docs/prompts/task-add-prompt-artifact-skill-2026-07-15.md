---
type: task
intent: Add a prompt-artifact skill to the artifact-tools plugin that publishes prompts saved by plan-agent:write-prompt as claude.ai artifacts, in single-prompt and library modes.
techniques: Clarity/directness, XML context tags, output-format spec
created: 2026-07-15
---

# Task: Add Prompt-Artifact Skill

<context>
Repo: shawn-sandy/agentics — a Claude Code plugin marketplace.

The `plan-agent:write-prompt` skill generates AI prompts and saves each one as a
markdown file under the resolved prompts directory (`promptsDirectory` in
.claude/settings.json, else `$(git rev-parse --show-toplevel)/docs/prompts`).
Saved files look like `task-refactor-auth-middleware-2026-06-04.md` with
frontmatter: type, intent, techniques, created — followed by an H1 and the raw
prompt text.

The `artifact-tools` plugin (kit/plugins/artifact-tools/) currently ships three
skills: diff-artifact, session-artifact, plan-artifact. Read
kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md first — it is the
closest sibling and the pattern to follow: resolve the target file, read
`artifact-url:` from frontmatter, publish fresh or republish to the same URL,
gate on security-scrub, fall back to local HTML if Artifact is unavailable.

For the library mode, read kit/plugins/plan-agent/skills/plans-library/SKILL.md
— it builds a filterable gallery from a directory of files. Reuse its filtering
and card-layout approach rather than inventing a second gallery idiom.
</context>

Add a fourth skill, `prompt-artifact`, to the `artifact-tools` plugin. It
publishes saved prompts as claude.ai artifacts in two modes: a single prompt by
default, or the whole prompt library when passed `--library`.

Requirements:

1. Create `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` with
   frontmatter:
   - `name: prompt-artifact`
   - `description` in the three-part house format (short label + capability +
     "Use when..." trigger phrase), under 200 chars, matching the voice of the
     sibling skills' descriptions. It must name both modes.
   - `allowed-tools` scoped to exactly what the workflow uses — model it on
     plan-artifact's list.

2. Mode selection, resolved before any other work:
   - `--library` anywhere in the arguments selects library mode.
   - Anything else — a `.md` path, or no argument at all — selects single mode.

3. Single mode workflow, in order:
   - Resolve the prompt file. Accept a `.md` path argument. If none given, Glob
     the resolved prompts directory and pick via AskUserQuestion. Never guess.
   - Read frontmatter: type, intent, techniques, created, and `artifact-url:`.
   - Run the blocking `social-media-tools:security-scrub` gate on the prompt
     body before any publish. A finding stops the publish.
   - Build a self-contained HTML page in the scratchpad and publish it with the
     Artifact tool.
   - First publish (no `artifact-url:`): publish fresh, then write the returned
     URL back into the source `.md` frontmatter.
   - Republish (`artifact-url:` present): pass it as Artifact's `url` parameter
     so the same page updates.

4. Library mode workflow, in order:
   - Glob every `.md` in the resolved prompts directory. If none exist, say so
     and stop — do not publish an empty gallery.
   - Run the security-scrub gate over every prompt body. A finding in any one
     prompt stops the whole publish and names the offending file; do not
     silently drop it from the gallery and publish the rest.
   - Build one self-contained gallery page: a card per prompt showing title,
     type, intent, and created date, with the full prompt body expandable
     in place. Filter chips by `type` (task, system, creative, analytical),
     driven by inlined JS.
   - Track the gallery's own URL in a `.artifact-url` sidecar file in the
     prompts directory — the gallery has no single source `.md` to write
     frontmatter into. Absent sidecar means first publish; present means pass
     its contents as Artifact's `url` parameter and rewrite it with the
     returned URL.
   - Add the sidecar path to .gitignore only if the repo's existing convention
     calls for it; otherwise commit it so the URL survives across clones.

5. Both modes:
   - Local-HTML fallback when Artifact is unavailable, as the sibling skills do.
   - Every prompt body renders in a `<pre>` block with a copy-to-clipboard
     button that copies the raw prompt text verbatim — no HTML entities, no
     added whitespace. This is the page's whole point; a copy that pastes back
     entity-escaped is a bug. In library mode each card gets its own button.
   - Theme-aware styling (light and dark) and a favicon, per Artifact tool
     rules. Fully inlined CSS/JS — a strict CSP blocks every external request.

6. Register and document the change:
   - Bump `artifact-tools` version in `.claude-plugin/marketplace.json` — MINOR,
     since this adds a skill.
   - Add a CHANGELOG.md entry under kit/plugins/artifact-tools/.
   - Update the plugin's README.md and the artifact-tools row in the root
     CLAUDE.md plugin table to mention prompt-artifact and both its modes.

Match the existing skills' prose voice, heading structure, and level of detail.
Keep SKILL.md as the single runtime artifact — no separate reference files
unless the sibling skills already use them.
