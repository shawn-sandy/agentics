#!/usr/bin/env bash
# Regenerate docs/designs/index.html from every design-canvas directory.
# Forked from build-prototypes-index.sh (the prototypes-gallery generator) and
# retargeted to docs/designs/. The unit of listing differs: a canvas is a
# DIRECTORY holding one or more *.dc.html artboards, so this walks
# subdirectories rather than flat .html files. Runs two ways:
#   - As a PostToolUse hook: JSON arrives on stdin; rebuild only when the write
#     targeted docs/designs/ (so it never touches the other galleries).
#   - Manually / in tests: `bash build-designs-index.sh <project-root>` with
#     no hook payload — always rebuilds.
# Always exits 0 — index-rebuild failures must never block artboard writes.
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
    */docs/designs/index.html|docs/designs/index.html) exit 0 ;;  # our own generated file, skip
    */docs/designs/*|docs/designs/*)               : ;;      # an artboard write (abs or relative), proceed
    *)                                             exit 0 ;; # unrelated write, skip
  esac
fi

PROJECT_ROOT="${1:-$(pwd)}"

# `|| true` guarantees the hook never exits non-zero (and never blocks a write)
# even if the embedded Python raises on chdir, template I/O, or output writes.
python3 - "$PROJECT_ROOT" <<'EOF' || true
import json, os, re, sys, html
from urllib.parse import urlsplit
from datetime import datetime

project_root = sys.argv[1]
os.chdir(project_root)

designs_dir = os.path.join(os.getcwd(), 'docs', 'designs')
if not os.path.isdir(designs_dir):
    print(f'[build-designs-index] designs directory not found: {designs_dir}', file=sys.stderr)
    sys.exit(0)

# ── Locate plugin templates directory (newest version wins) ─────────────────
def find_templates_dir():
    # Prefer the checked-out repo's template so local runs/tests reflect THIS
    # change rather than whatever is installed under ~/.claude/plugins.
    repo_templates = os.path.join(project_root, 'kit', 'plugins', 'plan-agent', 'templates')
    if os.path.isfile(os.path.join(repo_templates, 'designs-gallery.html')):
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
    # Prefer the newest candidate that actually ships designs-gallery.html;
    # an installed older plugin may not have it yet (the repo copy does).
    for c in candidates:
        if os.path.isfile(os.path.join(c, 'designs-gallery.html')):
            return c
    return candidates[0] if candidates else ''

templates_dir = find_templates_dir()

# ── Collect canvas directories ──────────────────────────────────────────────
# One card per canvas DIRECTORY, not per artboard: /plan-agent:design writes a
# directory of *.dc.html artboards per canvas, and listing each artboard
# separately would bury a five-screen flow under five near-identical rows.
# A directory with no artboard is not a canvas (a stray sibling folder, or a
# canvas mid-write), so it produces no card. The generated index.html sits at
# the top of docs/designs/ as a FILE, so the isdir test already excludes it;
# the explicit name check keeps that true even if something ever creates a
# directory by that name.
def get_title(content, fname):
    m = re.search(r'<title>([^<]+)</title>', content, re.IGNORECASE)
    # Unescape here so titles are plain text; e() escapes exactly once at
    # render, keeping regeneration idempotent (no &amp;amp; drift) and the
    # visible row text in step with data-title, which the search filter reads.
    return html.unescape(m.group(1).strip()) if m else os.path.basename(fname)

def e(s):
    return html.escape(str(s))

canvases = []
for name in os.listdir(designs_dir):
    if name.startswith('.') or name == 'index.html':
        continue
    canvas_dir = os.path.join(designs_dir, name)
    if not os.path.isdir(canvas_dir):
        continue
    try:
        artboards = sorted(n for n in os.listdir(canvas_dir) if n.endswith('.dc.html'))
    except OSError:
        continue
    if not artboards:
        continue

    first = artboards[0]
    first_path = os.path.join(canvas_dir, first)
    try:
        content = open(first_path, encoding='utf-8', errors='replace').read()
        title = get_title(content, first_path)
    except Exception:
        title = name
    # Fall back to the directory name for an untitled artboard: the slug is the
    # only other thing that identifies the canvas to a reader.
    if not title or title == first:
        title = name

    # Newest artboard mtime dates the canvas — editing any one board makes the
    # whole canvas recent, which is how someone scanning the list thinks of it.
    newest = 0.0
    for n in artboards:
        try:
            newest = max(newest, os.path.getmtime(os.path.join(canvas_dir, n)))
        except OSError:
            pass
    date = datetime.fromtimestamp(newest).strftime('%Y-%m-%d') if newest else ''

    canvases.append({
        'name': name,
        'href': f'{name}/{first}',
        'title': title,
        'count': len(artboards),
        'date': date,
    })

# Newest-first, ties broken by directory name. Sorting by name first and then
# by date with a stable sort gives exactly that, without inverting a string.
canvases.sort(key=lambda c: c['name'])
canvases.sort(key=lambda c: c['date'], reverse=True)

cards = []
for c in canvases:
    # Row shape, matching the prototypes gallery. No status glyph: designs carry
    # no status, so the row leads with its title.
    n = c['count']
    meta = f'{n} artboard' if n == 1 else f'{n} artboards'

    cards.append(f'''<a class="gallery-card" href="{e(c['href'])}"
   data-month="{e(c['date'][:7])}" data-title="{e(c['title'].lower())}">
  <span class="r-title">{e(c['title'])}</span>
  <span class="r-meta">{e(meta)}</span>
  <span class="r-date">{e(c['date'])}</span>
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
    that includes nested plans and skips archive/ and artifacts/, plus the
    artifact-only plans that have no local file at all. A flat listdir here
    would print a different Plans total on this page than the Plans page prints
    on its own, which reads as data loss rather than as the two different
    counting rules it actually is.

    An artifact-only plan is a .md spec with an http(s) artifact-url:, no
    sibling .html, and the four sections build-plan-html.mjs refuses to render
    without — the same three gates build-index.sh applies before it emits a
    card, because this number has to equal the cards on that page. The section
    check is load-bearing: docs/plans also holds session exports, which carry
    their own artifact-url:. Kept verbatim in build-artifacts-index.sh,
    build-designs-index.sh and build-prototypes-index.sh."""
    sections = ('Objective', 'Steps', 'Acceptance Criteria', 'Verification')
    total = 0
    for dirpath, dirnames, filenames in os.walk(directory):
        dirnames[:] = [d for d in dirnames
                       if not d.startswith('.') and d not in ('archive', 'artifacts')]
        rendered = {f for f in filenames if f.endswith('.html')}
        total += sum(1 for f in rendered if f != 'index.html')
        for f in filenames:
            if not f.endswith('.md') or f[:-3] + '.html' in rendered:
                continue
            try:
                text = open(os.path.join(dirpath, f), encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            fm = re.match(r'\A---[ \t]*\n(.*?)\n---[ \t]*\n', text, re.DOTALL)
            if not fm:
                continue
            url = ''
            for line in fm.group(1).splitlines():
                key, sep, value = line.partition(':')
                if sep and key.strip() == 'artifact-url':
                    url = value.strip()
            # Parsed, not prefix-matched — the same rule build-index.sh applies
            # before it emits a card, because this number has to equal the cards
            # on that page. `https://` and `https:// host/x` pass a prefix test.
            if any(ch.isspace() for ch in url):
                continue
            try:
                parts = urlsplit(url)
            except ValueError:
                continue
            if parts.scheme.lower() not in ('http', 'https') or not parts.hostname:
                continue
            body = text[fm.end():]
            if all(re.search(r'^##[ \t]+' + re.escape(s) + r'[ \t]*$', body, re.MULTILINE)
                   for s in sections):
                total += 1
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

design_count = len(cards)
generated_at = datetime.now().strftime('%Y-%m-%d %H:%M')

template_path = os.path.join(templates_dir, 'designs-gallery.html') if templates_dir else ''
output_path   = os.path.join(designs_dir, 'index.html')

if template_path and os.path.isfile(template_path):
    with open(template_path, encoding='utf-8') as fh:
        out = fh.read()
    out = out.replace('{{GALLERY_ENTRIES}}', gallery_entries)
    out = out.replace('{{DESIGN_COUNT}}', str(design_count))
    out = out.replace('{{GENERATED_AT}}', generated_at)
    # 'DESIGNS' matches no collection key, so no tab is marked current. The
    # topbar has no Designs entry yet; adding one is a deliberate follow-up,
    # and an unrecognised key is a no-op for the loop above.
    out = apply_shell(out, designs_dir, 'DESIGNS')
else:
    out = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Designs Index</title>
</head>
<body>
<h1>Designs</h1>
<p>Generated {generated_at} &middot; {design_count} designs</p>
<div class="gallery">
{gallery_entries if gallery_entries else '<p>No designs yet.</p>'}
</div>
</body>
</html>"""

with open(output_path, 'w', encoding='utf-8') as fh:
    fh.write(out)

print(f'[build-designs-index] wrote {output_path} ({design_count} designs, {generated_at})')
EOF
