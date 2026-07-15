---
type: task
intent: Make all three artifact-tools skills always generate a readable, relevant title for the artifacts they publish.
techniques: Clarity/directness, XML context tags, CoT scaffolding, Output format
created: 2026-07-15
---

# Task: Artifact Title Generation

<context>
The repo `agentics` is a Claude Code plugin marketplace. The `artifact-tools` plugin
(kit/plugins/artifact-tools/) has three skills that each publish a claude.ai artifact
via the Artifact tool: diff-artifact, plan-artifact, session-artifact.

The Artifact tool uses the page's <title> element to name the artifact in the browser
tab and in the user's artifact gallery. Titles are currently unreliable:

- kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md:129 says only
  "Set a `<title>`" — no rule for what the title should contain.
- kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md:64 says only to keep the
  title stable across republishes — it never says how to pick it in the first place.
- kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py:89
  derives the title as `(first_user or "Session export").splitlines()[0][:80]` — the
  first user message truncated to 80 chars. This produces mid-word truncated titles
  like "ensure that the plugins in the artifact-tool always gen" instead of a readable
  subject.

A bad title is a real cost, not cosmetic: artifacts persist in a shared gallery, and a
truncated or generic title ("Session export", "Untitled diff") makes an artifact
unfindable later and unreadable to anyone the user shares it with.
</context>

<task>
Make all three artifact-tools skills always produce a readable, relevant artifact title.

Do this in two parts:

1. Create one shared reference file at
   kit/plugins/artifact-tools/references/titles.md containing the title rules (below).
   Have each of the three SKILL.md files replace its current ad-hoc title guidance with
   a single pointer to that reference, read at the point in the workflow where the page
   is written.

2. Fix the title fallback in
   kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py so it
   stops emitting mid-word truncations. The script's derived title is a fallback the
   skill may override; it must still be readable on its own.
</task>

<title_rules>
The rules the reference file must express:

- The title is a bare subject — a noun phrase naming what the artifact is ABOUT.
  No type prefix ("Diff:", "Plan:", "Session:"), no repo name, no branch name.
  Good: "Artifact title generation". Bad: "Diff: artifact title generation".
- Target roughly 60 characters. Never truncate mid-word — if the subject is too long,
  write a shorter subject rather than cutting one.
- Derive the subject from the artifact's actual content, not from the user's phrasing:
  the changed files and their common theme for a diff, the plan's objective for a plan,
  the work accomplished for a session. A verbatim slice of the request is not a title.
- Title Case is not required; sentence case reads better and is the default.
- Keep the title stable across republishes of the same artifact — the title is how the
  user finds their tab. Only change it on a hard pivot in what the artifact covers.
- Never ship a placeholder: "Untitled", "Session export", "Artifact", or an empty title
  are all failures. If no subject can be derived, name the most specific concrete thing
  the content touches.
</title_rules>

<thinking>
Before editing, read all three SKILL.md files and export_session.py in full. For each,
identify: where the page HTML is authored, where the title is currently set or implied,
and what content is already in scope at that point that a title could be derived from.
Then decide the smallest edit per file that routes it through the shared reference.
</thinking>

<constraints>
- Follow the repo's plugin conventions in CLAUDE.md and .claude/rules/.
- Bump the artifact-tools version in .claude-plugin/marketplace.json (minor — new
  reference file and behavior change) and add a CHANGELOG.md entry under
  kit/plugins/artifact-tools/. Do not add a version field to plugin.json.
- No emojis in generated markdown.
- Keep the reference file short. It is loaded at runtime; every line costs context.
- Do not restate the title rules inside the SKILL.md files — point to the reference.
</constraints>

<verification>
Show the export_session.py title fallback handling three inputs, and state the output
for each:
1. A short first user message (under 60 chars) — expect it used as-is.
2. A long first user message that would previously truncate mid-word — expect a
   word-boundary result, no dangling partial word.
3. An empty transcript — expect a readable derived subject, not "Session export".

Then quote the final title guidance line from each of the three SKILL.md files and the
full contents of references/titles.md.
</verification>

<output_format>
Report, in this order:
1. Every file created or modified, one line each, with what changed.
2. The three verification outputs above.
3. Anything you found that the rules do not cover and a one-line recommendation.
</output_format>
