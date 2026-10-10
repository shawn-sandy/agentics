# Changelog

## 0.1.0 — 2026-10-09

### Added

- **`/git-agent-launcher`**, the kit's first mod. It opens a pane listing every git-agent skill
  and command with its description, in typeahead order, with digit hotkeys on the first nine.
  A press stages `/git-agent:<name> ` in the prompt and keeps any typed draft as its arguments.
  A command staged by an earlier press is replaced rather than stacked. Nothing runs until
  Enter. Where the prompt box refuses the fill, a toast names the command to type. Surfaces
  that draw no pane (the VS Code chat panel, `claude -p`) get the list as text. Requires Claude
  Code 2.1.287+.
- **`hooks/register.test.ts`**: fifteen `claude plugin test` cases.
  - The pane and press cases mount on both the terminal and desktop surfaces. They cover the
    filter, order, and hotkeys; the empty-draft and kept-draft fills; three replaced-command
    drafts; the refusal toast; and the install line.
  - Each surface also gets its own registration case, and its own pane-versus-text case.
  - The headless, late-attach, and attach-then-detach cases start with no surface.
