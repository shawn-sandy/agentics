# Installation Instructions Enhancement

> Adds prerequisites, two-track installation guides, and audience-segmented usage sections to the root README, plugin directory README, and individual plugin READMEs.

<!-- generated:start -->

**Status:** Shipped 2026-02-26   **Plan:** [enhance-readmes-with-setup-docs.md](plans/enhance-readmes-with-setup-docs.md)   **Type:** artifact

## What shipped

- Root `README.md`: Prerequisites section added (Claude Code CLI, optional Node.js for API dev, platform support); Installation section with two tracks (Plugin Users vs Marketplace API Developers); Quick Start renamed to "Usage Guide" with audience segments.
- `plugins/README.md`: Enhanced "Testing Plugins Locally" section with prerequisites check and troubleshooting subsections.
- `plugins/hello-world/README.md`: Standardized Installation section — two loading patterns, "Via Marketplace (Planned)" entry, verification step.
- `plugins/dev-tools/README.md`: Standardized Installation section — optional dependency labels (Prettier, Black), verification for both commands and skills.
- `marketplace-data/README.md`: Installation section added covering prerequisites, direct plugin testing, and API workflow (labeled "in development").
- Consistent terminology established: Plugin, Command, Skill, Local testing, Marketplace installation; code blocks include expected output and language identifiers.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `README.md` | Root documentation | Modified |
| `plugins/README.md` | Plugin directory guide | Modified |
| `plugins/hello-world/README.md` | hello-world plugin docs | Modified |
| `plugins/dev-tools/README.md` | dev-tools plugin docs | Modified |
| `marketplace-data/README.md` | Marketplace data docs | Modified |

## How it works

The documentation identifies two distinct audiences — plugin users (who need `--plugin-dir` and git clone) and marketplace API developers (who need Node.js and npm) — and routes each audience through separate setup tracks. The Progressive Disclosure pattern keeps the "simple path first" structure intact while adding detail in subsections.

Troubleshooting subsections address the three most common new-user failures: "claude: command not found", plugin not loading, and permission errors. All code examples use `bash` language identifiers and include verification commands with expected output.

Note: `plugins/hello-world/` and `plugins/dev-tools/` were later removed from the marketplace (see `remove-dev-tools-hello-world-plugins`). The enhanced READMEs shipped as part of this plan but were deleted alongside the plugins.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [enhance-readmes-with-setup-docs.md](plans/enhance-readmes-with-setup-docs.md)
