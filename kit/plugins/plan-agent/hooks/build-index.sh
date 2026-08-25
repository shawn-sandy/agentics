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
from urllib.parse import urlsplit
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

# ── Collect plan sources ───────────────────────────────────────────────────────
# Two kinds of plan share this gallery. A rendered <stem>.html is a plan whose
# author kept a local file; a <stem>.md spec carrying an http(s) artifact-url:
# and no sibling .html is a plan published straight to claude.ai. The .html
# always wins its stem — a spec still holding the URL from an earlier publish
# must not card twice, and the file is the copy the author chose to keep.
html_files, spec_files = [], []
for dirpath, dirnames, filenames in os.walk(plans_dir):
    dirnames[:] = [d for d in dirnames if not d.startswith('.') and d not in ('archive', 'artifacts')]
    for name in filenames:
        if name.endswith('.html') and name != 'index.html':
            html_files.append(os.path.join(dirpath, name))
        elif name.endswith('.md'):
            spec_files.append(os.path.join(dirpath, name))

def stem_of(path):
    """Plans-dir-relative path minus its extension — a plan's stable identity
    across a publish flip. scripts/merge-plans-index.mjs keys cards on this
    rather than on href precisely because the href does not survive one."""
    return os.path.splitext(os.path.relpath(path, plans_dir))[0]

html_stems = {stem_of(f) for f in html_files}

# ── Parse metadata ─────────────────────────────────────────────────────────────
def get_meta(content, name, fallback=''):
    m = re.search(r'<meta\s+name="' + re.escape(name) + r'"\s+content="([^"]*)"', content)
    return m.group(1).strip() if m else fallback

def get_title(content, fname):
    m = re.search(r'<title>(?:Plan:\s*)?([^<]+)</title>', content, re.IGNORECASE)
    # Unescape here so titles are plain text; e() escapes exactly once at render,
    # keeping regeneration idempotent (no &amp;amp; drift).
    return html.unescape(m.group(1).strip()) if m else os.path.basename(fname)

def is_http_url(value):
    """A real http(s) URL with a host — parsed, not prefix-matched.

    `https://` and `https:// host/x` both pass a `^https?://` test. The second
    matters beyond a broken card: build-plan-html.mjs puts the same value into
    the republish prompt, so the two checks have to agree on what counts."""
    if not value or any(ch.isspace() for ch in value):
        return False
    try:
        parts = urlsplit(value)
    except ValueError:
        return False
    return parts.scheme.lower() in ('http', 'https') and bool(parts.hostname)

def split_spec(text):
    """(frontmatter dict, body). Partitions each line on its first colon only —
    glance: and artifact-url: values both contain more of them."""
    m = re.match(r'\A---[ \t]*\n(.*?)\n---[ \t]*\n', text, re.DOTALL)
    if not m:
        return {}, text
    fm = {}
    for line in m.group(1).splitlines():
        key, sep, value = line.partition(':')
        if sep and key.strip() and not key.lstrip().startswith('#'):
            fm[key.strip()] = value.strip()
    return fm, text[m.end():]

def spec_title(body, fname):
    m = re.search(r'^#[ \t]+(?:Plan:[ \t]*)?(.+?)[ \t]*$', body, re.MULTILINE)
    return m.group(1) if m else os.path.basename(fname)

# The sections build-plan-html.mjs refuses to render a spec without. Reused here
# as the answer to "is this file a plan?" so the gallery and the renderer share
# one definition instead of drifting apart. It is load-bearing, not defensive:
# docs/plans also holds session exports, which carry their own artifact-url: and
# would otherwise be promoted into the plans gallery by the key alone.
PLAN_SECTIONS = ('Objective', 'Steps', 'Acceptance Criteria', 'Verification')

def is_plan_spec(body):
    return all(re.search(r'^##[ \t]+' + re.escape(name) + r'[ \t]*$', body, re.MULTILINE)
               for name in PLAN_SECTIONS)

def spec_steps(body):
    """(done, total) from the numbered items under ## Steps. A [x] straight
    after the number is the completed marker the renderer reads, so the gallery
    counts the same thing the plan page draws. `### Phase:` headings inside the
    section do not end it — the stop pattern needs exactly two hashes."""
    m = re.search(r'^##[ \t]+Steps[ \t]*$(.*?)(?=^##[ \t]|\Z)', body, re.MULTILINE | re.DOTALL)
    if not m:
        return 0, 0
    markers = re.findall(r'^[ \t]*\d+\.[ \t]+(\[x\])?', m.group(1), re.MULTILINE)
    return sum(1 for marker in markers if marker), len(markers)

def e(s):
    return html.escape(str(s))

entries = []
for f in html_files:
    try:
        content = open(f, encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    entries.append({
        'href': os.path.relpath(f, plans_dir),
        'stem': stem_of(f),
        'base': os.path.basename(f),
        'title': get_title(content, f),
        'status': get_meta(content, 'plan-status', 'todo'),
        'type': get_meta(content, 'plan-type', 'untyped'),
        'effort': get_meta(content, 'plan-effort', '').lower(),
        'created': get_meta(content, 'plan-created', ''),
        'proto': bool(get_meta(content, 'plan-prototype', '')),
        # Every step is one `class="step-card"`, a finished one adds
        # ` completed`; the lookahead keeps `step-card-header` (one per step)
        # and the stylesheet's own `.step-card` rule out of the total.
        'steps_total': len(re.findall(r'class="step-card(?=[" ])', content)),
        'steps_done': len(re.findall(r'class="step-card completed"', content)),
        'artifact': False,
    })

for f in spec_files:
    if stem_of(f) in html_stems:
        continue                       # the published file wins its stem
    try:
        text = open(f, encoding='utf-8', errors='replace').read()
    except Exception:
        continue
    fm, body = split_spec(text)
    url = fm.get('artifact-url', '')
    if not url:
        continue                       # no link and no file — nothing to open
    if not is_plan_spec(body):
        continue                       # a published document, but not a plan
    if not is_http_url(url):
        # This href lands raw in a page people click, so the value is checked
        # here rather than trusted from frontmatter: a hand-edited javascript:
        # or data: value would otherwise turn the gallery into its delivery.
        print(f'[build-index] {os.path.basename(f)}: ignoring non-http(s) artifact-url',
              file=sys.stderr)
        continue
    steps_done, steps_total = spec_steps(body)
    entries.append({
        'href': url,
        'stem': stem_of(f),
        'base': os.path.basename(f),
        'title': spec_title(body, f),
        'status': fm.get('status', 'todo'),
        'type': fm.get('type', 'untyped'),
        'effort': fm.get('effort', '').lower(),
        'created': fm.get('created', ''),
        'proto': bool(fm.get('prototype', '')),
        'steps_total': steps_total,
        'steps_done': steps_done,
        'artifact': True,
    })

def _plan_created_sort_key(entry):
    """In-progress plans first, then created desc; undated plans sort last by
    filename. The gallery leads with the work actually in flight — 88 cards in
    pure date order buries the four plans someone is mid-way through.
    Artifacts live in their own gallery (docs/artifacts/), not here."""
    flight = 0 if entry['status'] == 'in-progress' else 1
    try:
        year, month, day = (int(x) for x in entry['created'].split('-')[:3])
        return (flight, 0, -year, -month, -day, entry['base'])
    except Exception:
        return (flight, 1, 0, 0, 0, entry['base'])

entries.sort(key=_plan_created_sort_key)

# Emptiness is judged on cardable plans, not on files found: a plans directory
# holding only specs without an artifact-url has nothing this page can link, and
# blanking an existing gallery is worse than leaving it alone.
if not entries:
    print(f'[build-index] no plan files found in {plans_dir} — skipping', file=sys.stderr)
    sys.exit(0)

generated_at = datetime.now().strftime('%Y-%m-%d %H:%M')

# ── Build gallery entries ──────────────────────────────────────────────────────
cards = []
for entry in entries:
    status  = entry['status']
    created = entry['created']
    effort  = entry['effort']
    title   = entry['title']
    steps_done, steps_total = entry['steps_done'], entry['steps_total']

    # YYYY-MM, or empty when the plan carries no created date. The gallery
    # script turns it into a heading at load time; nothing between the cards
    # would survive a merge-driver splice.
    month = created[:7] if re.match(r'^\d{4}-\d{2}', created) else ''

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
                 'open the plan and follow its View prototype link">proto</span>') if entry['proto'] else ''
    # An artifact plan leaves the site when clicked and has no file in the repo.
    # Both facts are announced twice — a chip for anyone scanning the row, a
    # visually-hidden note for anyone who only hears the link.
    artifact_txt = (' &middot; <span class="artifact-chip" title="Published to claude.ai — '
                    'no local file in this repo">artifact</span>') if entry['artifact'] else ''
    away_attrs = ' target="_blank" rel="noopener"' if entry['artifact'] else ''
    away_note  = '<span class="sr-only"> (opens on claude.ai)</span>' if entry['artifact'] else ''
    # Server-rendered so the progress survives with JavaScript off; the
    # gallery script draws the bar beside it from the two data attributes.
    steps_span = (f'\n  <span class="r-steps">{steps_done} / {steps_total} steps</span>'
                  if status == 'in-progress' and steps_total else '')

    # Row, not card: bare anchor, no nested <a>, no <li>, and
    # `<a class="gallery-card"` kept as the leading attribute pair — all three
    # are what scripts/merge-plans-index.mjs splices on.
    cards.append(f'''<a class="gallery-card" href="{e(entry["href"])}"{away_attrs}
   data-local="{e(entry["stem"])}" data-status="{e(status)}" data-type="{e(entry["type"])}" data-effort="{e(effort)}" data-month="{e(month)}" data-title="{e(title.lower())}" data-steps-done="{steps_done}" data-steps-total="{steps_total}">
  <span class="glyph" aria-hidden="true">{glyph}</span><span class="sr-only">{e(status_display)}</span>
  <span class="r-title">{e(title)}</span>
  <span class="r-meta">{e(entry["type"])}{effort_txt}{proto_txt}{artifact_txt}</span>
  <span class="r-date">{e(created)}</span>{steps_span}{away_note}
</a>''')

gallery_entries = '\n'.join(cards)
# Counted off the cards actually emitted, never off the source lists: the loops
# above skip anything they cannot open (a broken symlink, a file whose
# permissions changed between the walk and the read) and every spec with no
# artifact to link, and every consumer of this number — the page's own "N plans"
# line, the topbar Plans tab, and the `wrote … (N items)` line the plans-library
# skill compares its card count against — is claiming how many rows the page
# has. Sourcing it from the pre-parse list makes all three overstate by exactly
# the number of files silently dropped, which reads to the skill as a corrupt
# write.
plan_count = len(cards)

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
