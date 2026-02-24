# dev-tools Commands

Slash commands provided by the `dev-tools` plugin.

## Available Commands

### `/dev-tools:format`

Format code in a file or directory using the appropriate formatter for the detected language.

**Invocation:**

```
/dev-tools:format
/dev-tools:format [path]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `path`   | No       | File or directory path to format. Defaults to current file/context. |

**Supported Languages & Formatters:**

| Language / File Type | Formatter |
|----------------------|-----------|
| JavaScript, TypeScript | Prettier |
| JSON | Prettier |
| Markdown | Prettier |
| CSS, SCSS | Prettier |
| HTML | Prettier |
| Python | Black (preferred) or autopep8 |

**Examples:**

```
/dev-tools:format
# → Formats the current file in context

/dev-tools:format src/index.ts
# → prettier --write src/index.ts

/dev-tools:format src/components
# → prettier --write "src/components/**/*.{ts,tsx,js,jsx}"

/dev-tools:format .
# → Formats all supported files in the current directory
```

**Behavior:**

- Respects existing configuration files (`.prettierrc`, `pyproject.toml`, etc.)
- Skips `node_modules`, `.git`, and other standard ignored directories
- Reports which files were formatted and any files that were skipped
- Notifies the user when a file type is not supported
- Reports missing formatter tools and suggests installation

---

### `/dev-tools:plan-interview`

Stress-test an implementation plan through a structured multi-round interview before coding begins.

**Invocation:**

```
/dev-tools:plan-interview
/dev-tools:plan-interview [plan-file-path]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `plan-file-path` | No | Path to a `.md` plan file. Auto-detected if omitted. |

**Allowed Tools:** `Read`, `Glob`, `AskUserQuestion`, `Write`, `Edit`

**Plan File Resolution (priority order):**

1. Explicit `$ARGUMENTS` path, if provided
2. Currently open `.md` file in the IDE that contains plan structure markers
3. `plansDirectory` key in `.claude/settings.json` → most recently modified `.md` file
4. Latest `.md` file in `~/.claude/plans/`

**Interview Rounds:**

| Round | Trigger | Focus |
|-------|---------|-------|
| Round 1 — Technical & Trade-offs | Always | Architecture decisions, build-vs-buy, performance, integrations |
| Round 2a — UI/UX & Flows | Medium/complex plans, or any plan with UI signals | User flows, loading/error states, responsive behavior, animations |
| Round 2b — Accessibility | Immediately after Round 2a | Keyboard navigation, ARIA, WCAG 2.1 AA, semantic HTML |
| Round 3 — Edge Cases | Complex plans only | Failure modes, concurrency, regression risks, best practices |

**Complexity thresholds:**

- **Short/focused** (1–2 files, single concern) → 1 round
- **Medium** (feature with UI + logic) → 2 rounds
- **Complex** (architecture, 3+ domains) → 3 rounds

**Output:**

After the interview, produces a structured `## Plan Interview Summary` covering:

- Key decisions confirmed
- Open risks and concerns
- Recommended next steps
- Simplification opportunities (if any)

Optionally appends the summary to the plan file upon user confirmation.

**Examples:**

```
/dev-tools:plan-interview
# → Auto-detects latest plan in ~/.claude/plans/

/dev-tools:plan-interview ~/.claude/plans/auth-refactor.md
# → Interviews the specified plan file
```

---

## Command Files

| File | Command | Description |
|------|---------|-------------|
| `format.md` | `/dev-tools:format` | Format code using language-appropriate tools |
| `plan-interview.md` | `/dev-tools:plan-interview` | Structured plan stress-test interview |

## Notes

- Commands in this plugin work best when run from within the project directory being worked on
- `format` requires the relevant formatter tool (`prettier`, `black`, etc.) to be installed in the environment
- `plan-interview` is most useful after using `EnterPlanMode` to write an implementation plan
- See the [plugin README](../README.md) for installation and full plugin documentation
