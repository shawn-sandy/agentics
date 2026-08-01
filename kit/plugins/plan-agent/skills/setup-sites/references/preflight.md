# Preflight, docs directory, and templates

Loaded before Step 1. Covers Steps 1, 2, and 3.

## Step 1 — Preflight: confirm a git repo and resolve the live URL

Confirm the cwd is a git work tree, then derive the published URL from the `origin` remote. A project repo publishes under a path prefix (`https://<owner>.github.io/<repo>/`); a user/org root repo named `<owner>.github.io` publishes at the apex (`https://<owner>.github.io/`).

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not inside a git repository. cd into your project first."; exit 1; }

python3 - <<'EOF'
import re, subprocess
try:
    url = subprocess.check_output(["git", "remote", "get-url", "origin"],
                                  text=True, stderr=subprocess.DEVNULL).strip()
except Exception:
    url = ""
owner = repo = ""
m = re.search(r'github\.com[:/]+([^/]+)/(.+?)(?:\.git)?/?$', url)
if m:
    owner, repo = m.group(1), m.group(2)
if not owner:
    print("REMOTE=none")
    print("Note: no GitHub origin remote found — using placeholders for the hub.")
elif repo.lower() == f"{owner.lower()}.github.io":
    print(f"REMOTE={owner}/{repo}")
    print(f"LIVE_URL=https://{owner}.github.io/")
    print("SITE_KIND=root  (served at the apex, no path prefix)")
else:
    print(f"REMOTE={owner}/{repo}")
    print(f"LIVE_URL=https://{owner}.github.io/{repo}/")
    print("SITE_KIND=project  (served under /%s/ — links MUST stay relative)" % repo)
EOF
```

Keep `owner`, `repo`, and the computed `LIVE_URL` for Steps 4, 5, and 7. If there is no remote, continue anyway with placeholder values and warn the user that the live URL is unknown until a GitHub remote exists.

---

## Step 2 — Resolve the docs directory and sanity-check `plansDirectory`

The deploy workflow uploads `docs/` and nothing else, so generated HTML must live under `docs/`. Two failure modes to close here:

1. **`plansDirectory` set but outside `docs/`** — plans would generate where Pages never looks. Warn and ask before proceeding.
2. **`plansDirectory` unset and `docs/plans/` missing** — `implementation-plan` resolves its output dir as `--dir` → `plansDirectory` (project-local → project → global) → **`${PWD}/docs/plans`** as the final fallback, so the first plan always lands inside the repo. Seed `docs/plans/` now (with a committed `.gitkeep`) anyway, so the directory is tracked and Pages serves it from the first deploy.

```bash
mkdir -p docs
python3 - <<'EOF'
import json, os
def read(p):
    try: return json.load(open(p)).get("plansDirectory", "").strip()
    except Exception: return ""
val = read(os.path.join(".claude", "settings.local.json")) or \
      read(os.path.join(".claude", "settings.json")) or \
      read(os.path.join(os.path.expanduser("~"), ".claude", "settings.json"))
if val:
    norm = val[2:] if val.startswith("./") else val
    inside = (not os.path.isabs(norm)) and (norm.rstrip("/") + "/").startswith("docs/")
    print(f"plansDirectory = {val}")
    if not inside:
        print("WARNING: plansDirectory is OUTSIDE docs/ — Pages only serves docs/.")
        print("         Move plans under docs/ (e.g. docs/plans) or edit the")
        print("         workflow's upload `path:` to match, or plans won't publish.")
else:
    # Unset: implementation-plan falls back to ${PWD}/docs/plans. Seed it (tracked
    # via .gitkeep) so the directory exists and Pages serves it from the first deploy.
    os.makedirs(os.path.join("docs", "plans"), exist_ok=True)
    open(os.path.join("docs", "plans", ".gitkeep"), "a").close()
    print("plansDirectory unset — seeded docs/plans/ (with .gitkeep) so generated")
    print("plans are tracked and deploy from the first commit.")
EOF
```

If the warning fires, surface it to the user and ask whether to proceed before scaffolding.

---

## Step 3 — Locate the plugin templates directory

The four artifacts ship as templates inside this plugin. The plugin may be a versioned cached copy or loaded directly — try every layout:

```bash
TEMPLATES_DIR=$( { \
  find ~/.claude/plugins -path "*/plan-agent/*/templates/pages" -type d 2>/dev/null | sort -rV; \
  find ~/.claude/plugins -path "*/plan-agent/templates/pages"   -type d 2>/dev/null; \
  find "$PWD"            -path "*/plan-agent/templates/pages"   -type d 2>/dev/null; \
} | head -1 )
[ -n "$TEMPLATES_DIR" ] || { echo "Templates not found. Install plan-agent or load it with --plugin-dir."; exit 1; }
echo "TEMPLATES_DIR=$TEMPLATES_DIR"
```

If empty, output that message and **STOP**.
