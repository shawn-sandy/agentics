# How do I... git-agent-launcher

A pane of every git-agent skill and command: pressing one stages it in the prompt for you to run.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install git-agent-launcher@agentics-kit`. Needs Claude Code 2.1.287+ and git-agent installed.

This plugin is a mod. It has no skills, so there is no natural-language trigger, only the command it registers.

## /git-agent-launcher

Lists git-agent's 13 entries with their descriptions so you can pick one instead of remembering its spelling.

- **Command** — `/git-agent-launcher`
- **Say it instead** — Command-only: a mod's registered command has no natural-language trigger.
- **What happens** — A pane opens and takes the keyboard. Digits `1`–`9` press the first nine entries, and a click presses any of them. A press puts `/git-agent:<name> ` in the prompt box, followed by whatever you had typed, so `fix typo in readme` becomes `/git-agent:commit-bg fix typo in readme`. The keyboard returns to the prompt box, and Enter runs it. The pane stays open for another press; Escape closes it.
- **Watch out** — Nothing runs on the press itself. That is deliberate: `commit-agent` and `pr-agent` push without asking. Pressing a second entry replaces the first one's staged command instead of stacking two. In the VS Code chat panel and under `claude -p` no pane draws, so the command answers with the list as text. If a surface's prompt box refuses the staged text, a toast tells you what to type.
