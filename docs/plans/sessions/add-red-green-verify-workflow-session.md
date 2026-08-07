---
title: "Red-green-verify plans — plan-agent 8.7.0"
pr: 529
pr-url: https://github.com/shawn-sandy/agentics/pull/529
merge-commit: 1b4f657
follow-up-issue: https://github.com/shawn-sandy/agentics/issues/530
date: 2026-08-06
type: session-recap
eng-artifact-url: https://claude.ai/code/artifact/034adde7-2d79-468a-9e04-228b3d096ddd
---

# Red-green-verify plans — plan-agent 8.7.0

Republish record for the engineering recap. Re-running `/artifact-tools:eng-recap`
in a later session should pass `eng-artifact-url` to the `Artifact` tool's `url`
parameter so the published page updates in place rather than minting a new link.

Only `eng-artifact-url` belongs to this writer. `artifact-url`,
`product-artifact-url`, and `team-artifact-url` belong to `session-artifact`,
`product-doc`, and `team-recap` — those keys share this record and must not be
overwritten by an eng-recap run.

## What shipped

The `implementation-plan` skill now detects whether a plan should force its tests
to fail before implementation exists, and shapes the steps into
`### Phase: RED / GREEN / VERIFY / SHIP` when it should. No renderer, parser, or
`build` change — 8.6.0's phase machinery already carried it. 6 files, +291/-7.

## Gallery copy

`docs/artifacts/eng-recap-2026-08-06.html` (inbox copy at
`.claude/artifacts/eng-recap-2026-08-06.html`, gitignored). The mermaid diagram
ships as source text rather than rendered SVG: the published artifact is private,
so the browser pane could not reach it to capture the rendered output, and
localhost is policy-blocked in this environment.

## Open items

Both tracked in [issue #530](https://github.com/shawn-sandy/agentics/issues/530):

1. `extract-plan-spec.mjs` drops `[x]` step markers and `- [x]` criteria on the
   HTML to spec direction. Pre-existing, reproduced on unphased plans.
2. RED failure evidence does not survive a `build` phase checkpoint, but SHIP
   requires it in the PR body.
