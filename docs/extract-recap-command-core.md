# Say the recap workflow once, not three times

> Extracts the shared gather/scrub/build/publish workflow from three artifact-tools recap commands into a single `references/recap-core.md`, reducing each command to its unique audience framing while preserving four distinct republish URL keys.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/references/recap-core.md` containing the shared workflow: PR and session gathering (20-file diff cap, `--name-only` fallback), the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name.
- Reduced `eng-recap.md`, `team-recap.md`, and `product-doc.md` from ~2,000 combined words each to under 500 words each — retaining only their audience, section list, plain-language posture, and republish key (respectively `eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`).
- Each command's `artifact-url:` prohibition was preserved: none of the three may write the key that belongs to `session-artifact`.
- Added `tests/plugins/test-recap-command-dedupe.sh` asserting the three commands share fewer than 50 identical lines, each is under 500 words, `references/recap-core.md` exists, and each command file writes its own distinct key with no cross-assignment.
- Bumped `artifact-tools` minor version in `.claude-plugin/marketplace.json`.
- `product-doc` inherited the page-build requirements and SVG-inlining destination from the shared workflow (it previously lacked them).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared gather/scrub/build/publish workflow | Created |
| `tests/plugins/test-recap-command-dedupe.sh` | Duplication and key-assignment smoke test | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Reduced to engineer framing + `eng-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Reduced to whole-team framing + `team-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Reduced to product framing + `product-artifact-url:` | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Refactor entry | Modified |

## How it works

The key insight driving the extraction was that `eng-recap` and `team-recap` shared 168 identical lines / 1,568 words — but not all shared lines were safe to collapse. A line-by-line inventory separated "shared workflow" from "coincidental matches" (section headings whose content differs per audience). Only the former went into `recap-core.md`.

`recap-core.md` owns the full workflow parameterised by key name: gather the session or PR, run `security-scrub` as a blocking gate, build the page, publish via the `Artifact` tool, record the republish URL, and fall back to local HTML when publishing is unavailable. The 20-file diff cap and `--name-only` fallback live here.

Each reduced command now states only what genuinely differs: its audience, the sections it expects (eng-recap has Architecture and code paths, no Glossary; team-recap has Glossary and diagrams; product-doc has Features and Known gaps), its plain-language posture, its republish key name, and a delegation line to `references/recap-core.md`.

The republish-key separation was the sharp edge. Four distinct keys live on the same shared session record. The test verifies per-file assignments — not by counting key names across files (which would miss the prohibition text naming keys a command must *not* write) — but by running individual greps on each file.

`tests/plugins/test-artifact-tools.sh` was updated to assert the shared contracts against `references/recap-core.md` rather than the individual command files, since the extraction moved the gather block and diff cap there.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)
- Related: [kit/plugins/artifact-tools/references/recap-core.md](../kit/plugins/artifact-tools/references/recap-core.md)
- Related: [kit/plugins/artifact-tools/CHANGELOG.md](../kit/plugins/artifact-tools/CHANGELOG.md)
