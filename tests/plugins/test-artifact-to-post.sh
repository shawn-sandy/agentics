#!/usr/bin/env bash
# Objective smoke test for the content-tools artifact-to-post skill.
#
# Objective under test: an artifact converts to a draft MDX post whose
# interactive blocks survive and whose prose cannot break an MDX build.
#
# SCOPE HONESTY: this repo has no Astro install, so nothing here validates a
# real MDX build. The authoritative gate is the manual run against a real site
# (plan step 7) — the site's own build command. What this test pins is the
# skill contract and the escaping rules, which is what silently rots.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$ROOT/kit/plugins/content-tools"
MANIFEST="$PLUGIN/.claude-plugin/plugin.json"
SKILL="$PLUGIN/skills/artifact-to-post/SKILL.md"
MDX_REF="$PLUGIN/references/mdx-safety.md"
CFG_REF="$PLUGIN/references/content-config.md"
MARKET="$ROOT/.claude-plugin/marketplace.json"
FIXTURE="$ROOT/tests/fixtures/artifact-to-post/sample-artifact.html"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Plugin manifest: exists, valid, and carries NO version key (a plugin.json
#    version silently overrides the marketplace value for relative-path plugins).
[ -f "$MANIFEST" ] || fail "plugin.json missing at $MANIFEST"
python3 -c "
import json,sys
m=json.load(open('$MANIFEST'))
assert m.get('name')=='content-tools', 'plugin.json name is not content-tools'
assert 'version' not in m, 'plugin.json must not carry a version key'
" || fail "plugin.json invalid"

# 2. Registered in marketplace.json at 1.0.0 with a documentation category.
python3 -c "
import json
p=[x for x in json.load(open('$MARKET'))['plugins'] if x['name']=='content-tools']
assert p, 'content-tools not registered in marketplace.json'
e=p[0]
assert e['version']=='1.0.0', 'expected version 1.0.0, got '+e['version']
assert e['category']=='documentation', 'expected documentation category'
assert e['source']['path']=='kit/plugins/content-tools', 'wrong source path'
assert 'mdx' in e['tags'] and 'astro' in e['tags'], 'expected specific tags'
" || fail "marketplace registration wrong"

# 3. Skill frontmatter valid, description within budget.
[ -f "$SKILL" ] || fail "SKILL.md missing at $SKILL"
head -1 "$SKILL" | grep -qx -- '---' || fail "SKILL.md does not open with frontmatter"
grep -qE '^name: artifact-to-post$' "$SKILL" || fail "skill name missing/wrong"
grep -qE '^allowed-tools: ' "$SKILL" || fail "allowed-tools not declared"
budget="$(python3 "$ROOT/tests/plugins/measure_description_budget.py" "$SKILL")"
total="${budget%% *}"
[ "$total" -le 200 ] || fail "description is $total chars, budget is 200"

# 4. The prose rewrite is ordered BEFORE the MDX-safety pass. The rewrite is
#    what introduces the hazards, so a pass that ran first validates dead text.
rewrite_line=$(grep -n '^## Phase 5 — Prose rewrite' "$SKILL" | cut -d: -f1)
safety_line=$(grep -n '^## Phase 6 — MDX-safety pass' "$SKILL" | cut -d: -f1)
[ -n "$rewrite_line" ] || fail "no prose-rewrite phase in SKILL.md"
[ -n "$safety_line" ] || fail "no MDX-safety phase in SKILL.md"
[ "$rewrite_line" -lt "$safety_line" ] || fail "safety pass is ordered before the prose rewrite"
grep -q 'after' "$SKILL" || fail "ordering rationale missing"

# 5. Config-driven: no hardcoded site literals in the skill body.
for lit in 'src/content/posts' 'astro build' 'localhost:4321'; do
  grep -qF "$lit" "$SKILL" && fail "hardcoded site literal in SKILL.md: $lit"
done
for key in posts_dir draft_flag images_dir preview_url build_command interactivity_ceiling; do
  grep -qF "$key" "$SKILL" || fail "SKILL.md never reads config value: $key"
done

# 6. claude.ai URLs refused with a pointer at save-artifact — no WebFetch.
grep -qF 'claude.ai' "$SKILL" || fail "claude.ai URL handling not documented"
grep -qF 'social-media-tools:save-artifact' "$SKILL" || fail "no pointer to save-artifact"
grep -qE '^allowed-tools:.*WebFetch' "$SKILL" && fail "WebFetch must not be an allowed tool"

# 7. Security scrub is a blocking gate that fails loudly when unavailable.
grep -qF 'security-scrub' "$SKILL" || fail "security-scrub gate missing"
scrub_line=$(grep -n 'security-scrub' "$SKILL" | head -1 | cut -d: -f1)
write_line=$(grep -n '^## Phase 8 — Write the post' "$SKILL" | cut -d: -f1)
[ "$scrub_line" -lt "$write_line" ] || fail "security scrub runs after the write step"
grep -qE 'not (installed|available)' "$SKILL" || fail "no loud failure path when social-media-tools is absent"
# Observed in a real run: the agent announced the scrub was unavailable, then
# self-reviewed and wrote the post anyway. Loud is not the contract — stopping is.
grep -qF 'write nothing and end the turn' "$SKILL" || fail "scrub gate warns but does not stop"

# 7b. Rung 4 is a fallback, not a capped rung. A real run read
#     interactivity_ceiling: 3 as forbidding rung 4 and DELETED the canvas block.
grep -qF 'Rung 4 is never capped' "$MDX_REF" || fail "ceiling wrongly caps rung 4"
grep -qF 'Never drop a block' "$MDX_REF" || fail "no-content-loss rule missing"
grep -qF 'no block is ever dropped' "$SKILL" || fail "SKILL.md does not forbid dropping blocks"

# 7c. Phase 0 must use the launch message's base directory, not a filesystem
#     hunt — real runs burned turns on `find` and hit sandbox denials.
grep -qF 'Base directory for this skill' "$SKILL" || fail "Phase 0 does not use the skill base directory"
grep -qF 'Do not `find` or `Glob` for them' "$SKILL" || fail "Phase 0 does not forbid searching for the references"

# 8. References document the ladder and the JSX rules.
[ -f "$MDX_REF" ] || fail "references/mdx-safety.md missing"
for rung in 'Rung 1' 'Rung 2' 'Rung 3' 'Rung 4'; do
  grep -qF "### $rung" "$MDX_REF" || fail "mdx-safety.md missing $rung"
done
prev=0
for rung in 1 2 3 4; do
  line=$(grep -n "^### Rung $rung" "$MDX_REF" | cut -d: -f1)
  [ "$line" -gt "$prev" ] || fail "ladder rungs are out of order at rung $rung"
  prev="$line"
done
grep -qF 'className' "$MDX_REF" || fail "class -> className rule missing from mdx-safety.md"
grep -qF 'htmlFor' "$MDX_REF" || fail "for -> htmlFor rule missing from mdx-safety.md"
for hazard in 'Array<string>' '{ id }' '<T>'; do
  grep -qF "$hazard" "$MDX_REF" || fail "canonical hazard not documented: $hazard"
done

# 9. Config reference documents every field and both prerequisite checks.
[ -f "$CFG_REF" ] || fail "references/content-config.md missing"
for f in posts_dir extension frontmatter.title frontmatter.description \
         frontmatter.date frontmatter.author draft_flag images_dir \
         preview_url build_command interactivity_ceiling; do
  grep -qF "$f" "$CFG_REF" || fail "content-config.md missing field: $f"
done
grep -qF '@astrojs/mdx' "$CFG_REF" || fail "mdx dependency prerequisite check missing"
grep -qF 'collection' "$CFG_REF" || fail "content-collection glob prerequisite check missing"
grep -qiE 'never auto-install' "$CFG_REF" || fail "no-auto-install rule missing"

# 10. Fixture carries every rung marker and every hazard.
[ -f "$FIXTURE" ] || fail "fixture missing at $FIXTURE"
for r in 1 2 3 4; do
  grep -qF "data-rung=\"$r\"" "$FIXTURE" || fail "fixture missing rung $r block"
done
for hazard in 'Array&lt;string&gt;' '{ id }' '&lt;T&gt;' '&lt;https://example.com/docs&gt;'; do
  grep -qF "$hazard" "$FIXTURE" || fail "fixture missing hazard: $hazard"
done
grep -qF '<pre><code' "$FIXTURE" || fail "fixture missing fenced region"

# 11. The escaping contract, actually run. Implements the rule documented in
#     mdx-safety.md section (b) against text lifted from the fixture: prose
#     regions get escaped, fenced regions are left byte-identical.
python3 - "$FIXTURE" <<'PY' || fail "escaping guard failed"
import html, re, sys

src = open(sys.argv[1]).read()
raw_prose = re.search(r'<p>(.*?)</p>', src, re.S).group(1)
prose = html.unescape(re.sub(r'<[^>]+>', '', raw_prose)).strip()
fence = html.unescape(re.search(r'<pre><code[^>]*>(.*?)</code></pre>', src, re.S).group(1))
doc = prose + "\n\n```ts\n" + fence + "```\n"

HAZARD = re.compile(r'(?<!\\)[{}]|<[A-Za-z][^>\s]*>')

def escape_prose(text):
    """Escape braces, wrap <word...> in a code span. Inline code spans skipped."""
    out = []
    for i, part in enumerate(re.split(r'(`[^`]*`)', text)):
        if i % 2:                      # already an inline code span
            out.append(part)
            continue
        part = part.replace('{', r'\{').replace('}', r'\}')
        part = re.sub(r'(<[A-Za-z][^>\s]*>)', r'`\1`', part)
        out.append(part)
    return ''.join(out)

def safety_pass(text):
    """Transform prose regions only; fenced regions pass through untouched."""
    return ''.join(
        seg if i % 2 else escape_prose(seg)
        for i, seg in enumerate(re.split(r'(```.*?```)', text, flags=re.S))
    )

result = safety_pass(doc)
segs = re.split(r'(```.*?```)', result, flags=re.S)

for i, seg in enumerate(segs):
    if i % 2:
        continue
    for j, part in enumerate(re.split(r'(`[^`]*`)', seg)):
        if j % 2:
            continue
        hit = HAZARD.search(part)
        assert not hit, f"unescaped hazard survived in prose: {hit.group(0)!r}"

fenced = [s for i, s in enumerate(segs) if i % 2]
assert fenced, "fenced region disappeared from the output"
assert fenced[0] == "```ts\n" + fence + "```", "fenced region was modified by the safety pass"
assert 'Array<string>' in fenced[0] and '{ id }' in fenced[0], "fenced hazards were rewritten"
assert r'\{' not in fenced[0], "escaping leaked into the fenced region"
PY

echo "PASS: artifact-to-post smoke test (11 checks; MDX build validated manually — no Astro here)"
