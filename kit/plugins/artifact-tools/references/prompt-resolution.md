# Resolving the mode, the directory, and the prompts

Loaded by `prompt-artifact` Steps 1–3.

## Step 1 — Resolve the mode

Settle this before touching the filesystem:

| Arguments contain | Mode | Publishes |
|-------------------|------|-----------|
| `--library` (anywhere) | **library** | one gallery page covering every saved prompt |
| anything else — a `.md` path, or nothing | **single** | one prompt page |

## Step 2 — Resolve the prompts directory

Match `prompt`'s resolution exactly, or the two skills disagree about where
prompts live and this one publishes a stale or empty set. First match wins:

```bash
PROMPTS_DIR=$(python3 - <<'EOF'
import json, os, subprocess, sys
# 1. promptsDirectory via Claude settings precedence: project-local, project,
#    then user-global. All three files, in this order — dropping the
#    settings.local.json read is how this skill starts publishing from a
#    different directory than prompt saves to.
for path in (os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
             os.path.join(os.getcwd(), '.claude', 'settings.json'),
             os.path.join(os.path.expanduser('~'), '.claude', 'settings.json')):
    try:
        v = json.load(open(path)).get('promptsDirectory', '').strip()
        if v:
            print(v.rstrip('/')); sys.exit(0)
    except Exception:
        pass
# 2. git root + docs/prompts
try:
    root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'],
                                   stderr=subprocess.DEVNULL, text=True).strip()
    print(os.path.join(root, 'docs', 'prompts')); sys.exit(0)
except Exception:
    pass
# 3. cwd-relative
print(os.path.join(os.getcwd(), 'docs', 'prompts'))
EOF
)
```

## Step 3 — Resolve the prompt(s)

**Single mode.** Take the `.md` path if the user gave one. If not, `Glob`
`$PROMPTS_DIR/*.md` and ask via `AskUserQuestion`. Never guess — publishing the
wrong prompt is a silent error the user only finds after sharing the link.

Read the frontmatter: `type`, `intent`, `techniques`, `created`, and
`artifact-url:`. The body below the frontmatter's closing `---` is the prompt;
the H1 is the title.

**Read the keys you need and ignore the rest.** `type: proposal` prompts also
carry `status:`, `modified:`, and `generated-sha:`; more keys will follow. An
unrecognized key is not an error and must never abort the read or blank a card —
render `modified:` beside `created:` in the metadata row when present, and drop
anything else silently.

**Library mode.** `Glob` `$PROMPTS_DIR/*.md`. If nothing matches, tell the user:

> "No saved prompts found in `<PROMPTS_DIR>`. Run `/plan-agent:prompt` to
> create your first one."

**STOP.** Never publish an empty gallery — a page announcing nothing still costs
a URL and reads as a broken deliverable.
