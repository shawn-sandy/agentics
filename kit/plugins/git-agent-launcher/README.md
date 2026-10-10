# git-agent-launcher

A clickable list of git-agent's skills and commands, so you never have to remember thirteen
`/git-agent:<name>` spellings.

`/git-agent-launcher` opens a pane listing every git-agent entry with its description. Pressing
one stages `/git-agent:<name> ` in the prompt box. It does not run it. You add arguments if you
want, and Enter is what runs it. This matters because `commit-agent` and `pr-agent` push without
asking, so a misclick has to stay harmless.

This is a **mod**: a Claude Code plugin whose `hooks/hooks.json` names a hooks module. It has no
skills, agents, or settings hooks.

## Requirements

- Claude Code **2.1.287+** in the terminal, **2.1.286+** in the Desktop Code tab. Mods are early
  access, and an older CLI does not load the module.
- [`git-agent`](../git-agent/README.md) installed. Without it the pane shows the install command
  and nothing else.

## Install

```text
/plugin marketplace add shawn-sandy/agentics
/plugin install git-agent-launcher@agentics-kit
```

## Usage

1. Type `/git-agent-launcher`. The pane opens and takes the keyboard.
2. Press a digit `1`–`9` for the first nine entries, or click any entry. Entries 10–13 are
   reached by click, or with Tab and Enter.
3. The prompt box now holds `/git-agent:<name> `, followed by whatever you had typed. The
   keyboard is back in the prompt box, so add arguments or press Enter.

| Prompt before the press | Entry pressed | Prompt after |
|---|---|---|
| (empty) | `commit-agent` | `/git-agent:commit-agent ` |
| `fix typo in readme` | `commit-bg` | `/git-agent:commit-bg fix typo in readme` |
| `/git-agent:commit-agent fix typo` | `commit-bg` | `/git-agent:commit-bg fix typo` |

A command staged by an earlier press is replaced, not stacked, and what followed it is kept. The
pane stays open for another press. Escape, or the pane's close mark, closes it. Ctrl+X Tab
returns the keyboard to an open pane.

## Where it draws

| Surface | What you get |
|---|---|
| Terminal | The pane: docked beside the transcript in the fullscreen layout, inline above the prompt otherwise |
| Desktop Code tab | The pane |
| VS Code chat panel, `claude -p`, cloud sessions | No pane; the command answers with the list as text, one `/git-agent:<name> — <description>` per line |

If a surface's prompt box does not accept the staged text, a toast names the command to type
instead: `Type /git-agent:<name> in the prompt`.

## Trust contract

Mods are unsandboxed and run with your permissions. This one reads the command list and the
prompt box. It writes only the prompt box, its own pane, and a toast. `claude plugin validate kit/plugins/git-agent-launcher` should report exactly the
following, and anything else is a defect:

```text
./register.tsx hooks: session.start, session.attach, session.detach, command.run{command=git-agent-launcher}, ui.render{component=Pane, requestId=git-agent-launcher}
./register.tsx answers its own command: command.run{command=git-agent-launcher}
./register.tsx calls: $.command.list (via gitAgentEntries), $.command.register, $.prompt.fill (via stage), $.prompt.read (via stage), $.ui.open, $.ui.resolve, $.ui.toast (via stage)
```

- **Not in that report:** `$.fs`, `$.process`, `$.http`, `$.model`, `$.session`, or `$.env`.
- **`session.attach` and `session.detach`:** these hooks only observe. They track which drawing
  surfaces are attached, so a `claude -p` run, or a session whose last client has left, gets
  the text list instead of a pane nobody can see.
- **The one warning:** the manifest's `version: No version specified` warning is expected. This
  repo keeps versions in `marketplace.json` only.

## Plugin Structure

```text
git-agent-launcher/
├── .claude-plugin/
│   └── plugin.json         # manifest, no version key
├── hooks/
│   ├── hooks.json          # { "modules": ["./register.tsx"] }
│   ├── register.tsx        # the hooks module
│   └── register.test.ts    # claude plugin test, terminal and desktop surfaces
├── tsconfig.json           # extends the API types the engine lays in .claude-plugin/types/ (gitignored)
├── CHANGELOG.md
└── README.md
```

## Components

| Component | What it does |
|---|---|
| `/git-agent-launcher` | Registered on `session.start`; opens the pane (`focus`, `closeOnEscape`), or answers with the text list where no pane draws |
| `Pane` render | Lists `$.command.list()` entries whose `plugin` is `git-agent`, in typeahead order: a plain Button per entry and its description, dimmed |
| Press | `$.prompt.read()` and then `$.prompt.fill(..., mode: 'replace')`; a toast when the fill is refused |

## Development

```bash
claude --plugin-dir ./kit/plugins/git-agent-launcher   # load it for one session
claude plugin validate kit/plugins/git-agent-launcher   # the trust report above
claude plugin test kit/plugins/git-agent-launcher       # the regression tests
bash tests/plugins/test-mod-plugins.sh                  # both, for every mod; the merge gate runs this
```
