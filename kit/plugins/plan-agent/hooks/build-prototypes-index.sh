#!/usr/bin/env bash
# Regenerate docs/prototypes/index.html from all non-index prototype HTML files.
# Forked from build-index.sh (the plans-gallery generator) and retargeted to
# docs/prototypes/ with proto-* metadata. Runs two ways:
#   - As a PostToolUse hook: JSON arrives on stdin; rebuild only when the write
#     targeted docs/prototypes/ (so it never touches the plans gallery).
#   - Manually / in tests: `bash build-prototypes-index.sh <project-root>` with
#     no hook payload — always rebuilds.
# Always exits 0 — index-rebuild failures must never block prototype writes.
set -eu

# ── Optional hook gating (stdin payload) ────────────────────────────────────
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT="$(cat 2>/dev/null || true)"
fi
if [ -n "$HOOK_INPUT" ]; then
  FILE_PATH="$(printf '%s' "$HOOK_INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print((d.get("tool_input") or {}).get("file_path", ""))
except Exception:
    print("")' 2>/dev/null || true)"
  case "$FILE_PATH" in
    "")                                            : ;;      # no path → manual/CLI run, proceed
    */docs/prototypes/index.html|docs/prototypes/index.html) exit 0 ;;  # our own generated file, skip
    */docs/prototypes/*|docs/prototypes/*)         : ;;      # a prototype write (abs or relative), proceed
    *)                                             exit 0 ;; # unrelated write, skip
  esac
fi

PROJECT_ROOT="${1:-$(pwd)}"

# `|| true` guarantees the hook never exits non-zero (and never blocks a write)
# even if the embedded Python raises on chdir, template I/O, or output writes.
python3 - "$PROJECT_ROOT" <<'EOF' || true
import json, os, re, sys, html
from datetime import datetime

project_root = sys.argv[1]
os.chdir(project_root)

protos_dir = os.path.join(os.getcwd(), 'docs', 'prototypes')
if not os.path.isdir(protos_dir):
    print(f'[build-prototypes-index] prototypes directory not found: {protos_dir}', file=sys.stderr)
    sys.exit(0)

# ── Locate plugin templates directory (newest version wins) ─────────────────
def find_templates_dir():
    # Prefer the checked-out repo's template so local runs/tests reflect THIS
    # change rather than whatever is installed under ~/.claude/plugins.
    repo_templates = os.path.join(project_root, 'kit', 'plugins', 'plan-agent', 'templates')
    if os.path.isfile(os.path.join(repo_templates, 'prototypes-gallery.html')):
        return repo_templates

    plugin_root = os.path.expanduser('~/.claude/plugins')
    candidates = []
    for base in (plugin_root,):
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
    # Prefer the newest candidate that actually ships prototypes-gallery.html;
    # an installed older plugin may not have it yet (the repo copy does).
    for c in candidates:
        if os.path.isfile(os.path.join(c, 'prototypes-gallery.html')):
            return c
    return candidates[0] if candidates else ''

templates_dir = find_templates_dir()

# ── Collect prototype files (excluding the generated index) ─────────────────
proto_files = [
    os.path.join(protos_dir, n)
    for n in os.listdir(protos_dir)
    if n.endswith('.html') and n != 'index.html'
]

def get_meta(content, name, fallback=''):
    m = re.search(r'<meta\s+name="' + re.escape(name) + r'"\s+content="([^"]*)"', content)
    return m.group(1).strip() if m else fallback

def get_title(content, fname):
    m = re.search(r'<title>([^<]+)</title>', content, re.IGNORECASE)
    # Unescape here so titles are plain text; e() escapes exactly once at
    # render, keeping regeneration idempotent (no &amp;amp; drift) and the
    # visible row text in step with data-title, which the search filter reads.
    return html.unescape(m.group(1).strip()) if m else os.path.basename(fname)

def created_sort_key(path):
    """Newest-first by proto-created; files without it sort last by filename."""
    try:
        with open(path, encoding='utf-8', errors='replace') as fh:
            head = fh.read(2000)
        d = get_meta(head, 'proto-created', '')
        if d:
            parts = d.split('-')
            return (0, -int(parts[0]), -int(parts[1]), -int(parts[2]), os.path.basename(path))
    except Exception:
        pass
    return (1, 0, 0, 0, os.path.basename(path))

proto_files.sort(key=created_sort_key)

def e(s):
    return html.escape(str(s))

cards = []
for f in proto_files:
    try:
        content = open(f, encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    title   = get_title(content, f)
    created = get_meta(content, 'proto-created', '')
    source  = get_meta(content, 'proto-source', '')
    rel     = os.path.basename(f)

    # Row shape, matching the plans gallery. No status glyph: prototypes carry
    # no status, so the row leads with its title.
    meta = f'from {e(source)}' if source else e(rel)

    cards.append(f'''<a class="gallery-card" href="{e(rel)}"
   data-month="{e(created[:7] if created else '')}" data-title="{e(title.lower())}">
  <span class="r-title">{e(title)}</span>
  <span class="r-meta">{meta}</span>
  <span class="r-date">{e(created)}</span>
</a>''')

gallery_entries = '\n'.join(cards)

# ── Topbar ─────────────────────────────────────────────────────────────────────
# Counts come off the filesystem, not out of the sibling index.html files: the
# four gallery generators run in arbitrary order, so a parse would report
# whichever index happened to be stale. Hrefs are relative to this page's own
# output directory, and the plans collection follows plansDirectory rather than
# assuming docs/plans.
def resolve_plans_dir():
    # Claude settings precedence: project-local → project → user-global.
    for path in (
        os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
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

def docs_count(directory):
    try:
        return sum(1 for n in os.listdir(directory)
                   if n.endswith('.html') and n != 'index.html')
    except OSError:
        return 0

def plans_count(directory):
    """The plans collection counted the way the plans gallery counts it: a walk
    that includes nested plans and skips archive/ and artifacts/. A flat listdir
    here would print a different Plans total on this page than the Plans page
    prints on its own, which reads as data loss rather than as the two
    different counting rules it actually is."""
    total = 0
    for dirpath, dirnames, filenames in os.walk(directory):
        dirnames[:] = [d for d in dirnames
                       if not d.startswith('.') and d not in ('archive', 'artifacts')]
        total += sum(1 for f in filenames
                     if f.endswith('.html') and f != 'index.html')
    return total

def apply_shell(text, output_dir, active):
    docs = os.path.join(os.getcwd(), 'docs')
    plans_dir = resolve_plans_dir()
    collections = (
        ('HOME',       os.path.join(docs, 'index.html'), None),
        ('PLANS',      os.path.join(plans_dir, 'index.html'), plans_dir),
        ('PROTOTYPES', os.path.join(docs, 'prototypes', 'index.html'), os.path.join(docs, 'prototypes')),
        ('ARTIFACTS',  os.path.join(docs, 'artifacts', 'index.html'), os.path.join(docs, 'artifacts')),
        ('SOCIAL',     os.path.join(docs, 'media', 'social', 'index.html'), os.path.join(docs, 'media', 'social')),
    )
    for key, target, collection in collections:
        text = text.replace('{{HREF_%s}}' % key, os.path.relpath(target, output_dir))
        if collection is not None:
            count = plans_count(collection) if key == 'PLANS' else docs_count(collection)
            text = text.replace('{{COUNT_%s}}' % key, str(count))
        text = text.replace('{{CUR_%s}}' % key,
                            'aria-current="page"' if key == active else '')
    return text

proto_count = len(cards)
generated_at = datetime.now().strftime('%Y-%m-%d %H:%M')

template_path = os.path.join(templates_dir, 'prototypes-gallery.html') if templates_dir else ''
output_path   = os.path.join(protos_dir, 'index.html')

if template_path and os.path.isfile(template_path):
    with open(template_path, encoding='utf-8') as fh:
        out = fh.read()
    out = out.replace('{{GALLERY_ENTRIES}}', gallery_entries)
    out = out.replace('{{PROTO_COUNT}}', str(proto_count))
    out = out.replace('{{GENERATED_AT}}', generated_at)
    out = apply_shell(out, protos_dir, 'PROTOTYPES')
else:
    out = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Prototypes Index</title>
</head>
<body>
<h1>Prototypes</h1>
<p>Generated {generated_at} &middot; {proto_count} prototypes</p>
<div class="gallery">
{gallery_entries if gallery_entries else '<p>No prototypes yet.</p>'}
</div>
</body>
</html>"""

with open(output_path, 'w', encoding='utf-8') as fh:
    fh.write(out)

print(f'[build-prototypes-index] wrote {output_path} ({proto_count} prototypes, {generated_at})')
EOF
