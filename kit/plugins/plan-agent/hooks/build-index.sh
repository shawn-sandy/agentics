#!/usr/bin/env bash
# Regenerate the plans index.html from all non-index HTML plan files.
# Called by rebuild-plans-index.py; PROJECT_ROOT is passed as $1.
# Always exits 0 — index-rebuild failures must never block plan writes.
set -eu

PROJECT_ROOT="${1:-$(pwd)}"

python3 - "$PROJECT_ROOT" <<'EOF'
import json, os, re, sys, html
from datetime import datetime

project_root = sys.argv[1]
os.chdir(project_root)

# ── Resolve plans directory ────────────────────────────────────────────────────
def resolve_plans_dir():
    for path in (
        os.path.join(os.getcwd(), '.claude', 'settings.json'),
        os.path.join(os.path.expanduser('~'), '.claude', 'settings.json'),
    ):
        try:
            v = json.load(open(path)).get('plansDirectory', '').strip()
            if v:
                return v if os.path.isabs(v) else os.path.join(os.getcwd(), v)
        except Exception:
            pass
    return os.path.join(os.getcwd(), 'docs', 'plans')

plans_dir = resolve_plans_dir()
if not os.path.isdir(plans_dir):
    print(f'[build-index] plans directory not found: {plans_dir}', file=sys.stderr)
    sys.exit(0)

# ── Locate plugin templates directory ─────────────────────────────────────────
def find_templates_dir():
    plugin_root = os.path.expanduser('~/.claude/plugins')
    candidates = []
    for base in (plugin_root, project_root):
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, _ in os.walk(base):
            dirnames[:] = [d for d in dirnames if not d.startswith('.')]
            if os.path.basename(dirpath) == 'templates' and 'plan-agent' in dirpath:
                candidates.append(dirpath)
    def version_key(p):
        import re
        m = re.search(r'/(\d+\.\d+\.\d+)/', p)
        return tuple(int(x) for x in m.group(1).split('.')) if m else (0, 0, 0)
    candidates.sort(key=version_key, reverse=True)
    return candidates[0] if candidates else ''

templates_dir = find_templates_dir()

# ── Collect and sort plan files ────────────────────────────────────────────────
plan_files = []
for dirpath, dirnames, filenames in os.walk(plans_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.') and d != 'archive']
    for name in filenames:
        if name.endswith('.html') and name != 'index.html':
            plan_files.append(os.path.join(dirpath, name))
plan_files.sort(key=lambda p: os.path.getmtime(p), reverse=True)

if not plan_files:
    print(f'[build-index] no plan files found in {plans_dir} — skipping', file=sys.stderr)
    sys.exit(0)

plan_count = len(plan_files)
generated_at = datetime.now().strftime('%Y-%m-%d %H:%M')

# ── Parse metadata and build gallery entries ───────────────────────────────────
def get_meta(content, name, fallback=''):
    m = re.search(r'<meta\s+name="' + re.escape(name) + r'"\s+content="([^"]*)"', content)
    return m.group(1).strip() if m else fallback

def get_title(content, fname):
    m = re.search(r'<title>(?:Plan:\s*)?([^<]+)</title>', content, re.IGNORECASE)
    return m.group(1).strip() if m else os.path.basename(fname)

def e(s):
    return html.escape(str(s))

cards = []
for f in plan_files:
    try:
        content = open(f, encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    status   = get_meta(content, 'plan-status', 'todo')
    ptype    = get_meta(content, 'plan-type',   'untyped')
    created  = get_meta(content, 'plan-created', '')
    title    = get_title(content, f)
    rel_path = os.path.relpath(f, plans_dir)

    status_display = status.replace('-', ' ')
    date_span = f'<span class="card-date">{e(created)}</span>' if created else ''

    cards.append(f'''<a class="gallery-card" href="{e(rel_path)}"
   data-status="{e(status)}" data-type="{e(ptype)}" data-title="{e(html.unescape(title).lower())}">
  <div class="card-badges">
    <span class="status-chip status-{e(status)}">{e(status_display)}</span>
    <span class="type-chip type-{e(ptype)}">{e(ptype)}</span>
  </div>
  <div class="card-title">{e(title)}</div>
  <div class="card-meta">
    {date_span}
    <span class="card-file">{e(rel_path)}</span>
  </div>
</a>''')

gallery_entries = '\n'.join(cards)

# ── Build index.html ───────────────────────────────────────────────────────────
template_path = os.path.join(templates_dir, 'plans-gallery.html') if templates_dir else ''
output_path   = os.path.join(plans_dir, 'index.html')

if template_path and os.path.isfile(template_path):
    with open(template_path, encoding='utf-8') as fh:
        content = fh.read()
    content = content.replace('{{GALLERY_ENTRIES}}', gallery_entries)
    content = content.replace('{{PLAN_COUNT}}',      str(plan_count))
    content = content.replace('{{GENERATED_AT}}',    generated_at)
else:
    content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Plans Index</title>
<style>
  body{{font-family:system-ui,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem;color:#111}}
  h1{{font-size:1.4rem;margin-bottom:.25rem}}
  .meta{{color:#6b7280;font-size:.85rem;margin-bottom:2rem}}
  .gallery{{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:1rem}}
  .gallery-card{{display:block;border:1px solid #e5e7eb;border-radius:6px;padding:1rem;text-decoration:none;color:inherit;transition:border-color .15s}}
  .gallery-card:hover{{border-color:#2563eb}}
  .card-badges{{display:flex;gap:.4rem;margin-bottom:.5rem;flex-wrap:wrap}}
  .status-chip,.type-chip{{font-size:.65rem;font-weight:700;letter-spacing:.06em;text-transform:uppercase;padding:.15rem .5rem;border-radius:999px}}
  .status-todo{{background:#f3f4f6;color:#6b7280}}
  .status-in-progress{{background:#fef3c7;color:#d97706}}
  .status-completed{{background:#f0fdf4;color:#16a34a}}
  .type-chip{{background:#eff6ff;color:#2563eb}}
  .card-title{{font-weight:600;margin-bottom:.35rem;font-size:.95rem}}
  .card-meta{{font-size:.75rem;color:#9ca3af;display:flex;gap:.75rem;flex-wrap:wrap}}
</style>
</head>
<body>
<h1>Plans Index</h1>
<p class="meta">Generated {generated_at} &middot; {plan_count} plans</p>
<div class="gallery">
{gallery_entries}
</div>
</body>
</html>"""

with open(output_path, 'w', encoding='utf-8') as fh:
    fh.write(content)

print(f'[build-index] wrote {output_path} ({plan_count} plans, {generated_at})')
EOF
