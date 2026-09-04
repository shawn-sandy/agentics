# How-To Guides

One guide per plugin. Every skill gets the same four-part entry: the slash command to type, the plain-English phrasing that triggers it, what actually happens, and the gotcha worth knowing. Skills marked command-only cannot be triggered by natural language.

Every plugin installs the same way: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install <name>@agentics-kit`.

| Plugin | Skills | What it covers |
|--------|--------|----------------|
| [artifact-tools](./artifact-tools.md) | 5 | Publish diffs, session recaps, plans, prompts, and explainers as live claude.ai artifact pages without leaving Claude Code. |
| [code-review](./code-review.md) | 1 | Reviews code for bugs, security issues, and breaking changes, and can fix a whole branch against the repo's own rules. |
| [code-testing-agent](./code-testing-agent.md) | 6 | Covers the test lifecycle: suggesting tests tied to real behavior, auditing an existing suite, running scoped tests, driving red-green TDD loops, and proving a change is merge-ready without waiting on CI. |
| [content-tools](./content-tools.md) | 1 | Turns work products — HTML artifacts and Markdown files — into draft posts for a static site. |
| [git-agent](./git-agent.md) | 8 | Git workflow automation — branch, commit, pull request, merge, issue, and post-merge cleanup — across GitHub (`gh`) and GitLab (`glab`). |
| [memory-tools](./memory-tools.md) | 3 | Audit and reshape Claude Code project memory — CLAUDE.md files, the path-scoped rule files in `.claude/rules/`, and usage-insights follow-through. |
| [plan-agent](./plan-agent.md) | 18 | Authoring, reviewing, implementing, and publishing implementation plans — from a vague idea through a rendered HTML plan to a shipped PR. |
| [settings-sync](./settings-sync.md) | 2 | Back up and restore your Claude Code user settings through a dedicated git repo. |
| [skill-reviewer](./skill-reviewer.md) | 4 | Audit, scaffold, and tune Claude Code skills — SKILL.md quality scores, `allowed-tools` permissions, and frontmatter budgets. |
| [social-media-tools](./social-media-tools.md) | 17 | Turn code, commits, blog posts, videos, React components, artifacts, and whole sessions into platform-aware social copy and dark-mode card images — with a mandatory secret scrub in front of every share. |
| [wcag-compliance-reviewer](./wcag-compliance-reviewer.md) | 1 | Audits HTML, CSS, and React/TypeScript code for WCAG 2.2 Level AA accessibility violations and supplies the fix for each one. |

Total: 66 skills across 11 plugins.

Back to the [root README](../../../README.md#how-to-guides), where the same list sits beside the Plugin Reference Table.
