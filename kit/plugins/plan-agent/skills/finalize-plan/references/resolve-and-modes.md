# Resolving the plan file and edit mode

Loaded at Step 1. Covers argument parsing, plans-directory precedence, and the spec-versus-legacy edit mode.

## Step 1 — Resolve the plan file and edit mode

Parse `$ARGUMENTS`:

0. If `$ARGUMENTS` contains `--all`, skip single-file resolution entirely and follow **Sweep mode (`--all`)** below. Sweep mode replaces the single-plan sequence of Steps 2–6 as the top-level flow, invoking those steps per candidate/selected plan as its S2 and S4 sub-steps direct.
1. If `$ARGUMENTS` contains a token ending in `.html` or `.md`, use that as the plan filename. Reduce to basename only (strip any leading path components). Resolve against these roots in order until the file is found:
   a. `--dir` value (if passed)
   b. `plansDirectory` via Claude Code's settings precedence — project-local `.claude/settings.local.json`, then project `.claude/settings.json`, then global `~/.claude/settings.json`
   c. `docs/plans/` under `$PWD`
2. If `$ARGUMENTS` is empty, resolve the plans directory (honor `--dir` if passed; otherwise the same precedence as root b), then find the most recently modified `.html` file (excluding `index.html`) under it:
```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
# Claude settings precedence: project-local → project → user-global
candidates = (
    os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
    os.path.join(os.getcwd(), '.claude', 'settings.json'),
    os.path.join(os.path.expanduser('~'), '.claude', 'settings.json'),
)
for path in candidates:
    try:
        v = json.load(open(path)).get('plansDirectory', '').strip()
        if v:
            print(v); sys.exit(0)
    except Exception:
        pass
print(os.path.join(os.getcwd(), 'docs', 'plans'))
EOF
)
find "$PLANS_DIR" -maxdepth 1 -name "*.html" ! -name "index.html" -print0 \
  | xargs -0 ls -t 2>/dev/null | head -1
```
3. If no file is found, tell the user: `"No plan found. Pass a filename: /plan-agent:finalize-plan my-plan.md"` and **STOP**.

**Determine the edit mode** from the resolved stem (`<plans-dir>/<name>` without extension):

- **Spec mode** — `<stem>.md` exists and its first markdown heading (after any YAML frontmatter block) is `# Plan:`. The spec is what you edit; `<stem>.html` is regenerated from it in Step 5.
- **Legacy mode** — no such spec (or the `.md` beside the plan is not a spec). Edit `<stem>.html` attributes directly, as before the markdown-first pipeline.

If the user passed a `.md` file that is not a plan spec (no `# Plan:` heading), say so and **STOP** — old-style markdown plans are `plan-agent:plan-status` territory, not finalize-plan's.

Announce: `"Reviewing plan for completion: <resolved-path> (<spec|legacy> mode)"`
