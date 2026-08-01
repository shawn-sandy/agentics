#!/usr/bin/env bash
# Publish saved artifacts and regenerate the artifacts gallery.
# Copies every .html from the local inbox (.claude/artifacts/) into the deployed
# docs/artifacts/ tree, then builds docs/artifacts/index.html from the shared
# plans-gallery template. PROJECT_ROOT is passed as $1.
# Always exits 0 — publish failures must never block the caller. The `|| true`
# on the python invocation guarantees that even an uncaught exception in the
# embedded script cannot propagate a non-zero status.
set -eu

PROJECT_ROOT="${1:-$(pwd)}"

python3 - "$PROJECT_ROOT" <<'EOF' || true
import os, re, sys, html, shutil
from datetime import datetime

# Best-effort + observable: the shell `|| true` guarantees a zero exit, but a
# silent swallow would hide real failures (permission errors, a malformed
# template). Log any uncaught exception to stderr first so a debugging user
# still gets a signal about why the gallery did not update.
def _log_uncaught(exc_type, exc, tb):
    print(f'[build-artifacts-index] publish failed (non-blocking): {exc}', file=sys.stderr)
sys.excepthook = _log_uncaught

project_root = sys.argv[1]
os.chdir(project_root)

# ── Resolve source (local inbox) and destination (deployed tree) ───────────────
inbox_dir  = os.path.join(os.getcwd(), '.claude', 'artifacts')
output_dir = os.path.join(os.getcwd(), 'docs', 'artifacts')

# ── Locate plugin templates directory (same discovery as build-index.sh) ───────
def find_templates_dir():
    candidates = []
    for base in (os.path.expanduser('~/.claude/plugins'), project_root):
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, _ in os.walk(base):
            dirnames[:] = [d for d in dirnames if not d.startswith('.')]
            if os.path.basename(dirpath) == 'templates' and 'plan-agent' in dirpath:
                candidates.append(dirpath)
    def version_key(p):
        m = re.search(r'/(\d+\.\d+\.\d+)/', p)
        return tuple(int(x) for x in m.group(1).split('.')) if m else (0, 0, 0)
    candidates.sort(key=version_key, reverse=True)
    # Prefer a project-local template (a repo that vendors plan-agent is
    # authoritative over the installed cache); else fall back to the cache.
    root = os.path.abspath(project_root) + os.sep
    local = [c for c in candidates if os.path.abspath(c).startswith(root)]
    return (local or candidates)[0] if candidates else ''

templates_dir = find_templates_dir()

# ── Publish: copy any inbox artifacts into the deployed tree ───────────────────
def _html_files(d):
    if not os.path.isdir(d):
        return []
    return [n for n in os.listdir(d)
            if n.endswith('.html') and n != 'index.html'
            and os.path.isfile(os.path.join(d, n))]

inbox_files = _html_files(inbox_dir)
if inbox_files:
    os.makedirs(output_dir, exist_ok=True)
    for name in inbox_files:
        shutil.copy2(os.path.join(inbox_dir, name), os.path.join(output_dir, name))

# ── Render set = every artifact currently published ────────────────────────────
# Build the gallery from docs/artifacts/ (the committed, deployed set), not just
# the inbox. The inbox is gitignored, so on a clean checkout it is empty; reading
# only the inbox would unlink every already-published artifact on the next save.
artifacts = _html_files(output_dir)
if not artifacts:
    print('[build-artifacts-index] no artifacts to publish', file=sys.stderr)
    sys.exit(0)

def _artifact_created(name):
    """YYYY-MM-DD suffix in the save-artifact filename, else ''."""
    m = re.search(r'-(\d{4}-\d{2}-\d{2})(?:-\d+)?\.html$', name)
    return m.group(1) if m else ''

def _sort_key(name):
    d = _artifact_created(name)
    if d:
        y, mo, dd = (int(x) for x in d.split('-'))
        return (0, -y, -mo, -dd, name)
    return (1, 0, 0, 0, name)

artifacts.sort(key=_sort_key)
count = len(artifacts)
generated_at = datetime.now().strftime('%Y-%m-%d %H:%M')

# ── Build gallery cards ────────────────────────────────────────────────────────
def get_title(content, fname):
    m = re.search(r'<title>([^<]+)</title>', content, re.IGNORECASE)
    return html.unescape(m.group(1).strip()) if m else fname

def e(s):
    return html.escape(str(s))

cards = []
for name in artifacts:
    try:
        content = open(os.path.join(output_dir, name), encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    title   = get_title(content, name)
    created = _artifact_created(name)
    # Row shape, same as the plans gallery it shares a template with — but with
    # no status glyph. Every artifact card carries data-status="", and the
    # stylesheet collapses the glyph column for those rather than rendering an
    # empty one.
    cards.append(f'''<a class="gallery-card" href="{e(name)}"
   data-status="" data-type="artifact" data-effort="" data-month="{e(created[:7] if created else '')}" data-title="{e(title.lower())}">
  <span class="r-title">{e(title)}</span>
  <span class="r-meta">artifact</span>
  <span class="r-date">{e(created)}</span>
</a>''')

gallery_entries = '\n'.join(cards)

# ── Topbar ─────────────────────────────────────────────────────────────────────
# Counted off disk, not parsed out of the sibling indexes: the four gallery
# generators run in arbitrary order and a parse would read a stale one.
def docs_count(*parts):
    d = os.path.join(os.getcwd(), 'docs', *parts)
    try:
        return sum(1 for n in os.listdir(d) if n.endswith('.html') and n != 'index.html')
    except OSError:
        return 0

def apply_shell(text, docs_root, active):
    text = text.replace('{{DOCS_ROOT}}', docs_root)
    text = text.replace('{{COUNT_PLANS}}',      str(docs_count('plans')))
    text = text.replace('{{COUNT_PROTOTYPES}}', str(docs_count('prototypes')))
    text = text.replace('{{COUNT_ARTIFACTS}}',  str(docs_count('artifacts')))
    text = text.replace('{{COUNT_SOCIAL}}',     str(docs_count('media', 'social')))
    for key in ('HOME', 'PLANS', 'PROTOTYPES', 'ARTIFACTS', 'SOCIAL'):
        text = text.replace('{{CUR_%s}}' % key,
                            'aria-current="page"' if key == active else '')
    return text

# ── Render index.html from the shared template ─────────────────────────────────
template_path = os.path.join(templates_dir, 'plans-gallery.html') if templates_dir else ''
output_path   = os.path.join(output_dir, 'index.html')

if template_path and os.path.isfile(template_path):
    with open(template_path, encoding='utf-8') as fh:
        content = fh.read()
    content = content.replace('{{GALLERY_TITLE}}',   'Artifacts')
    content = content.replace('{{GALLERY_SUB}}',
                              '&mdash; pages published from a working session, newest first.')
    content = content.replace('{{GALLERY_ENTRIES}}', gallery_entries)
    content = content.replace('{{PLAN_COUNT}}',      str(count))
    content = content.replace('{{GENERATED_AT}}',    generated_at)
    content = apply_shell(content, '../', 'ARTIFACTS')
else:
    content = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Artifacts Index</title>
</head>
<body>
<h1>Artifacts</h1>
<p>Generated {generated_at} &middot; {count} artifacts</p>
<div class="gallery">
{gallery_entries}
</div>
</body>
</html>"""

with open(output_path, 'w', encoding='utf-8') as fh:
    fh.write(content)

print(f'[build-artifacts-index] wrote {output_path} ({count} artifacts, {generated_at})')
EOF
