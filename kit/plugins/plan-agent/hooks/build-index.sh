#!/usr/bin/env bash
# Regenerate the plans index.html from all non-index HTML plan files.
# Called by rebuild-plans-index.py; PROJECT_ROOT is passed as $1.
# Always exits 0 — index-rebuild failures must never block plan writes.
set -eu

PROJECT_ROOT="${1:-$(pwd)}"

# Directory holding this script. Used to resolve the plan-agent templates when
# CLAUDE_PLUGIN_ROOT is unset (i.e. run standalone by CI or by hand, not as a
# plugin hook). Bounded: a fixed set of candidate paths, never a filesystem walk.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$PROJECT_ROOT" "$SCRIPT_DIR" <<'EOF'
import glob, json, os, re, sys, html
from datetime import datetime

project_root = sys.argv[1]
script_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(os.path.abspath(__file__))
os.chdir(project_root)

# ── Resolve plans directory ────────────────────────────────────────────────────
def resolve_plans_dir():
    # Claude settings precedence: project-local → project → user-global. The
    # local file is first because it is the one a developer uses to point their
    # own checkout somewhere else; skipping it sends the gallery to a directory
    # they are not writing to.
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

plans_dir = resolve_plans_dir()
if not os.path.isdir(plans_dir):
    print(f'[build-index] plans directory not found: {plans_dir}', file=sys.stderr)
    sys.exit(0)

# ── Locate plugin templates directory ─────────────────────────────────────────
# CLAUDE_PLUGIN_ROOT is set only when this runs as a plugin hook. The three
# copies of this script are byte-identical, and two of them (scripts/ and
# docs/plans/) run standalone where it is unset — so fall back to a fixed,
# bounded list of candidates resolved from this script's own location and the
# project root. No filesystem walk: each candidate is a single isdir() check.
def resolve_templates_dir():
    plugin_root = os.environ.get('CLAUDE_PLUGIN_ROOT', '').strip()
    candidates = []
    if plugin_root:
        candidates.append(os.path.join(plugin_root, 'templates'))
    vendored = os.path.join('kit', 'plugins', 'plan-agent', 'templates')
    candidates += [
        # Bundled hook: <plugin>/hooks/build-index.sh → <plugin>/templates
        os.path.join(script_dir, os.pardir, 'templates'),
        # scripts/build-plans-index.sh → repo root
        os.path.join(script_dir, os.pardir, vendored),
        # docs/plans/build-index.sh → repo root
        os.path.join(script_dir, os.pardir, os.pardir, vendored),
        # Explicitly-passed project root that vendors plan-agent
        os.path.join(os.path.abspath(project_root), vendored),
    ]
    for path in candidates:
        if os.path.isdir(path):
            return os.path.abspath(path)

    # Last resort: the installed plugin cache. A consumer project that installed
    # plan-agent normally (rather than vendoring it) and runs this script by hand
    # or in CI has no CLAUDE_PLUGIN_ROOT and nothing to anchor to — without this
    # it would silently fall back to the bare inline gallery. Fixed-depth glob
    # over one known layout, not a filesystem walk: newest version wins.
    cached = glob.glob(os.path.expanduser(
        '~/.claude/plugins/cache/*/plan-agent/*/templates'
    ))
    def version_key(p):
        m = re.search(r'/(\d+)\.(\d+)\.(\d+)/templates/?$', p)
        return tuple(int(x) for x in m.groups()) if m else (0, 0, 0)
    for path in sorted(cached, key=version_key, reverse=True):
        if os.path.isdir(path):
            return os.path.abspath(path)
    return ''

templates_dir = resolve_templates_dir()

# ── Collect and sort plan files ────────────────────────────────────────────────
plan_files = []
for dirpath, dirnames, filenames in os.walk(plans_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.') and d not in ('archive', 'artifacts')]
    for name in filenames:
        if name.endswith('.html') and name != 'index.html':
            plan_files.append(os.path.join(dirpath, name))
def _plan_created_sort_key(path):
    """In-progress plans first, then plan-created desc; undated plans sort last
    by filename. The gallery leads with the work actually in flight — 88 cards
    in pure date order buries the four plans someone is mid-way through.
    Artifacts live in their own gallery (docs/artifacts/), not here.
    Reads 4000 chars: the <head> now carries a theme script ahead of the
    plan-* meta tags."""
    base = os.path.basename(path)
    try:
        with open(path, encoding='utf-8', errors='replace') as fh:
            head = fh.read(4000)
        st = re.search(r'<meta\s+name="plan-status"\s+content="([^"]*)"', head)
        flight = 0 if (st and st.group(1).strip() == 'in-progress') else 1
        m = re.search(r'<meta\s+name="plan-created"\s+content="([^"]*)"', head)
        if m:
            parts = m.group(1).strip().split('-')
            return (flight, 0, -int(parts[0]), -int(parts[1]), -int(parts[2]), base)
        return (flight, 1, 0, 0, 0, base)
    except Exception:
        pass
    return (1, 1, 0, 0, 0, base)

plan_files.sort(key=_plan_created_sort_key)

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
    # Unescape here so titles are plain text; e() escapes exactly once at render,
    # keeping regeneration idempotent (no &amp;amp; drift).
    return html.unescape(m.group(1).strip()) if m else os.path.basename(fname)

def e(s):
    return html.escape(str(s))

cards = []
for f in plan_files:
    try:
        content = open(f, encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    rel_path = os.path.relpath(f, plans_dir)
    status   = get_meta(content, 'plan-status', 'todo')
    ptype    = get_meta(content, 'plan-type',   'untyped')
    effort   = get_meta(content, 'plan-effort', '').lower()
    created  = get_meta(content, 'plan-created', '')
    title = get_title(content, f)

    prototype = get_meta(content, 'plan-prototype', '')
    # YYYY-MM, or empty when the plan carries no created date. The gallery
    # script turns it into a heading at load time; nothing between the cards
    # would survive a merge-driver splice.
    month = created[:7] if re.match(r'^\d{4}-\d{2}', created) else ''

    # Step progress, counted out of the rendered plan HTML this loop already
    # read. Every step is one `class="step-card"`, a finished one adds
    # ` completed`; the lookahead keeps `step-card-header` (one per step) and
    # the stylesheet's own `.step-card` rule out of the total.
    steps_total = len(re.findall(r'class="step-card(?=[" ])', content))
    steps_done  = len(re.findall(r'class="step-card completed"', content))

    status_display = status.replace('-', ' ') if status else 'unstatused'
    # aria-hidden glyph + visually-hidden text: the card layout this replaced
    # carried a readable status pill, and a bare glyph would drop that for
    # anyone not looking at the page.
    glyph = '&#10003;' if status == 'completed' else '&#9675;'
    # High effort is the one meta value worth colouring — it is the signal
    # someone scanning for "what will this cost me" is looking for.
    effort_txt = ''
    if effort:
        effort_txt = (f' &middot; <span class="hi">{e(effort)}</span>'
                      if effort == 'high' else f' &middot; {e(effort)}')
    # Kept as its own span rather than folded into the meta text: a plan with a
    # prototype is worth spotting in a scan, and tests/plugins/
    # test-prototype-plan-link.mjs asserts the marker is a text-bearing span
    # with no nested anchor (the row is already one).
    proto_txt = (' &middot; <span class="proto-chip" title="This plan has a prototype — '
                 'open the plan and follow its View prototype link">proto</span>') if prototype else ''
    # Server-rendered so the progress survives with JavaScript off; the
    # gallery script draws the bar beside it from the two data attributes.
    steps_span = (f'\n  <span class="r-steps">{steps_done} / {steps_total} steps</span>'
                  if status == 'in-progress' and steps_total else '')

    # Row, not card: bare anchor, no nested <a>, no <li>, and
    # `<a class="gallery-card"` kept as the leading attribute pair — all three
    # are what scripts/merge-plans-index.mjs splices on.
    cards.append(f'''<a class="gallery-card" href="{e(rel_path)}"
   data-status="{e(status)}" data-type="{e(ptype)}" data-effort="{e(effort)}" data-month="{e(month)}" data-title="{e(title.lower())}" data-steps-done="{steps_done}" data-steps-total="{steps_total}">
  <span class="glyph" aria-hidden="true">{glyph}</span><span class="sr-only">{e(status_display)}</span>
  <span class="r-title">{e(title)}</span>
  <span class="r-meta">{e(ptype)}{effort_txt}{proto_txt}</span>
  <span class="r-date">{e(created)}</span>{steps_span}
</a>''')

gallery_entries = '\n'.join(cards)

# ── Topbar ─────────────────────────────────────────────────────────────────────
# Counts come off the filesystem, not out of the sibling index.html files: the
# four gallery generators run in arbitrary order, so a parse would report
# whichever index happened to be stale.
#
# Every tab href is computed relative to THIS page's own output directory, and
# the plans collection is read from the resolved plans_dir rather than a fixed
# docs/plans. A project that sets plansDirectory elsewhere still gets a correct
# count and links that resolve from the right depth.
def docs_count(directory):
    try:
        return sum(1 for n in os.listdir(directory)
                   if n.endswith('.html') and n != 'index.html')
    except OSError:
        return 0

def apply_shell(text, output_dir, active, plans_count=None):
    docs = os.path.join(os.getcwd(), 'docs')
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
            # The page's own collection reports what it actually rendered — the
            # gallery walks subdirectories and skips archive/, so a flat
            # listdir would disagree with the cards on the page.
            n = plans_count if (key == 'PLANS' and plans_count is not None) else docs_count(collection)
            text = text.replace('{{COUNT_%s}}' % key, str(n))
        text = text.replace('{{CUR_%s}}' % key,
                            'aria-current="page"' if key == active else '')
    return text

# ── Build index.html ───────────────────────────────────────────────────────────
template_path = os.path.join(templates_dir, 'plans-gallery.html') if templates_dir else ''
output_path   = os.path.join(plans_dir, 'index.html')

if template_path and os.path.isfile(template_path):
    with open(template_path, encoding='utf-8') as fh:
        content = fh.read()
    content = content.replace('{{GALLERY_TITLE}}',   'Plans')
    content = content.replace('{{GALLERY_SUB}}',
                              '&mdash; in flight first, then newest. Search matches titles.')
    content = content.replace('{{GALLERY_ENTRIES}}', gallery_entries)
    content = content.replace('{{PLAN_COUNT}}',      str(plan_count))
    content = content.replace('{{GENERATED_AT}}',    generated_at)
    content = apply_shell(content, plans_dir, 'PLANS', plans_count=plan_count)
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
  .gallery{{display:block}}
  /* The row markup the generator emits, styled just enough to be readable:
     this branch only runs when the plan-agent template cannot be found, and
     without a .sr-only clip the hidden status text renders as loose words
     beside every glyph. */
  .gallery-card{{display:grid;grid-template-columns:1.25rem minmax(0,1fr) 9rem 3.5rem;gap:.25rem .9rem;align-items:baseline;padding:.6rem .5rem;border-bottom:1px solid #e5e7eb;text-decoration:none;color:inherit}}
  .gallery-card:hover{{background:#f9fafb}}
  .gallery-card[data-status=""]{{grid-template-columns:minmax(0,1fr) 9rem 3.5rem}}
  .sr-only{{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0 0 0 0);clip-path:inset(50%);white-space:nowrap;border:0}}
  .glyph{{font-family:ui-monospace,Consolas,monospace;font-size:.8rem;text-align:center;color:#4b5563}}
  .gallery-card[data-status="completed"] .glyph{{color:#15803d}}
  .gallery-card[data-status="in-progress"] .glyph{{color:#b45309}}
  .r-title{{font-size:.95rem;line-height:1.4}}
  .gallery-card[data-status="in-progress"] .r-title{{font-weight:600}}
  .r-meta,.r-date,.r-steps{{font-family:ui-monospace,Consolas,monospace;font-size:.7rem;color:#4b5563}}
  .r-date{{text-align:right}}
  .r-steps{{grid-column:2 / -1}}
  @media (max-width:700px){{
    .gallery-card{{grid-template-columns:1.25rem minmax(0,1fr) 3.5rem}}
    .r-meta{{grid-column:2 / -1}}
  }}
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

print(f'[build-index] wrote {output_path} ({plan_count} items, {generated_at})')
EOF
