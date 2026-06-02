---
name: plans-open
description: "Opens the existing plans gallery without rebuilding. Opens index.html directly; run plans-library first if not yet built. Use when asked to reopen the plans gallery or browse plans without a rebuild."
allowed-tools: Bash
---

# plans-open

Open the existing `index.html` gallery directly — no file scanning, no template substitution, no write operations. If `index.html` does not exist, prompt the user to run `/plan-agent:plans-library` first.

---

## Step 1 — Resolve the plans directory

Read `plansDirectory` from `.claude/settings.json` (project first, then global `~/.claude/settings.json`). Fall back to `${PWD}/docs/plans` if neither file sets it.

```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
project = os.path.join(os.getcwd(), '.claude', 'settings.json')
global_ = os.path.join(os.path.expanduser('~'), '.claude', 'settings.json')
for path in (project, global_):
    try:
        v = json.load(open(path)).get('plansDirectory', '').strip()
        if v:
            print(v); sys.exit(0)
    except Exception:
        pass
print(os.path.join(os.getcwd(), 'docs', 'plans'))
EOF
)
```

---

## Step 2 — Check for index.html

```bash
test -f "$PLANS_DIR/index.html"
```

If `index.html` does not exist, output:

> "No gallery found. Run `/plan-agent:plans-library` to build it first."

**STOP.**

---

## Step 3 — Open in browser

```bash
GALLERY_PATH=$(realpath "$PLANS_DIR/index.html" 2>/dev/null || echo "$PLANS_DIR/index.html")
open "$GALLERY_PATH" 2>/dev/null || xdg-open "$GALLERY_PATH" 2>/dev/null || true
```

Tell the user:

> "Plans gallery opened: `<PLANS_DIR>/index.html`"

---

## Step 4 — Stop

**STOP.** Do not run git commands or invoke other skills after opening the gallery.
