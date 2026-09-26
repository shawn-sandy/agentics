#!/usr/bin/env bash
set -euo pipefail

# Pins the insight-record contract in implementing-insights: every implemented
# recommendation gets a claude.ai artifact that is republished to the same URL
# as its status changes.
#
# SCOPE: the skill is prose for the model, so this binds to what the prose must
# keep saying (the tool is allowed, the template is named, the URL rides in the
# PR body, each publish is read back, the ledger links the record) and to the
# shipped template itself, which is real HTML and is checked for the artifact
# page contract: no document wrapper, every color token defined on bare :root,
# both dark-theme blocks, a token body background, allowlisted hosts only, and
# a style for every lifecycle status the skill names. It cannot prove the model
# publishes; the plan's live publish, republish, and read-back is that proof.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/memory-tools/skills/implementing-insights"
SKILL="$SKILL_DIR/SKILL.md"
TEMPLATE="$SKILL_DIR/references/insight-record.html"
STATUSES="in-progress pr-open merged closed done"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "1. allowed-tools lists Artifact"
if sed -n '/^---$/,/^---$/p' "$SKILL" | grep -E '^allowed-tools:' | grep -qw 'Artifact'; then
  pass
else
  fail "SKILL.md frontmatter allowed-tools does not list Artifact — publishing would prompt mid-run"
fi

echo "2. SKILL.md names the record template and the template exists"
if grep -q 'references/insight-record\.html' "$SKILL" && [ -f "$TEMPLATE" ]; then
  pass
else
  fail "SKILL.md must reference references/insight-record.html and the file must exist"
fi

echo "3. the record URL rides in the PR body (a later session finds it there)"
if grep -iE 'PR body' "$SKILL" | grep -qi 'record'; then
  pass
else
  fail "no line in SKILL.md puts the record URL in the PR body"
fi

echo "4. each publish is read back through the Artifact tool"
if grep -qE 'action: "read"' "$SKILL"; then
  pass
else
  fail "SKILL.md never reads a published record back (Artifact action: \"read\")"
fi

echo "5. the outcome ledger has a Record column"
if grep -qE '^\| *# *\|.*\| *Record *\|' "$SKILL"; then
  pass
else
  fail "the ledger example table in SKILL.md has no Record column"
fi

echo "6. every lifecycle status is named in SKILL.md"
missing=""
for s in $STATUSES; do
  grep -q "\`$s\`" "$SKILL" || missing="$missing $s"
done
if [ -z "$missing" ]; then
  pass
else
  fail "SKILL.md does not name status(es):$missing"
fi

# Prose units: each paragraph and each bullet, with wrapped lines joined, so a
# check that two ideas share one instruction survives rewrapping.
units() {
  python3 - "$SKILL" <<'PYEOF'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
for block in re.split(r"\n\s*\n", text):
    for unit in re.split(r"\n(?=\s*[-*] |\s*\d+\. )", block):
        print(" ".join(unit.split()))
PYEOF
}

echo "6b. the record slug is restricted before it becomes a file path"
if units | grep -i 'slug' | grep -qF '[a-z0-9-]'; then
  pass
else
  fail "no instruction reduces <item-slug> to [a-z0-9-] — untrusted report text could traverse out of ~/.claude/insights/"
fi

echo "6c. dispatched agents receive the record URL for the PR body"
if units | grep -i 'agent' | grep -qi 'record URL'; then
  pass
else
  fail "no instruction hands the record URL to the agent that opens the PR — the PR body would ship without it"
fi

echo "6d. record paths are unique per item and never empty"
if grep -qE 'insights/<[^>]+>-<[^>]*number[^>]*>-<item-slug>\.html' "$SKILL" \
  && units | grep -i 'slug' | grep -qi 'empty'; then
  pass
else
  fail "the record path must carry the item number (two same-named items collide) and name a fallback for an empty slug"
fi

echo "6e. a failed publish leaves the PR body without a record line"
if units | grep -iE 'publish(ing)? fail' | grep -qE 'Insight record:|PR body'; then
  pass
else
  fail "no instruction says what the PR body and agent hand-off do when the first publish failed and there is no URL"
fi

echo "7. the template meets the artifact page contract"
if [ ! -f "$TEMPLATE" ]; then
  fail "template missing — nothing to check"
elif out="$(python3 - "$TEMPLATE" "$STATUSES" <<'PYEOF'
import re, sys

path, statuses = sys.argv[1], sys.argv[2].split()
src = open(path, encoding="utf-8").read()
errors = []

m = re.search(r"<title>(.*?)</title>", src[:8192], re.S)
title = (m.group(1).strip() if m else "")
if not title or title.lower() in {"untitled", "artifact", "insight record"}:
    errors.append(f"no specific <title> in the first 8KB (got {title!r})")

for tag in ("!doctype", "html", "head", "body"):
    if re.search(rf"<{tag}[\s>]", src, re.I):
        errors.append(f"document wrapper tag <{tag}> present — the publish skeleton adds it")

css = "\n".join(re.findall(r"<style[^>]*>(.*?)</style>", src, re.S))

def block(selector_regex):
    m = re.search(selector_regex + r"\s*\{([^{}]*)\}", css)
    return m.group(1) if m else None

root = block(r"(?<![\w\]\)-]):root(?![\w:\[(-])")
if root is None:
    errors.append("no bare :root token block")
    root = ""
defined = set(re.findall(r"(--[\w-]+)\s*:", root))

media = re.search(r"@media\s*\(prefers-color-scheme:\s*dark\)\s*\{(\s*[^{}]*\{[^{}]*\})\s*\}", css)
guarded = None
if media:
    g = re.search(r':root:not\(\[data-theme="light"\]\)\s*\{([^{}]*)\}', media.group(1))
    guarded = g.group(1) if g else None
if guarded is None:
    errors.append('no @media (prefers-color-scheme: dark) block guarded by :root:not([data-theme="light"])')
toggled = block(r':root\[data-theme="dark"\]')
if toggled is None:
    errors.append('no :root[data-theme="dark"] block')

for name, body in (("prefers-color-scheme", guarded), ("data-theme", toggled)):
    if body is None:
        continue
    if not re.search(r"color-scheme:\s*dark", body):
        errors.append(f"{name} dark block does not set color-scheme: dark")
    extra = set(re.findall(r"(--[\w-]+)\s*:", body)) - defined
    if extra:
        errors.append(f"{name} dark block defines tokens missing from bare :root: {sorted(extra)}")

used = set(re.findall(r"var\((--[\w-]+)", src))
undefined = used - defined
if undefined:
    errors.append(f"tokens used but not defined on bare :root: {sorted(undefined)}")

body_rule = block(r"(?<![\w.#-])body")
if not body_rule or not re.search(r"background(-color)?:\s*var\(--", body_rule):
    errors.append("body has no token background — the host theme would show through")

for s in statuses:
    if f'[data-status="{s}"]' not in css:
        errors.append(f'no style for status [data-status="{s}"]')

script_hosts = {"cdnjs.cloudflare.com", "cdn.jsdelivr.net", "unpkg.com", "cdn.tailwindcss.com", "code.jquery.com"}
for host in re.findall(r"<script[^>]+src=\"https?://([^/\"]+)", src):
    if host not in script_hosts:
        errors.append(f"script host {host} is not on the artifact CDN allowlist")
for host in re.findall(r"<link[^>]+href=\"https?://([^/\"]+)", src):
    if host not in {"fonts.googleapis.com", "fonts.gstatic.com"}:
        errors.append(f"link host {host} is blocked by the artifact CSP")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print(f"title {title!r}; {len(defined)} tokens; {len(statuses)} statuses styled")
PYEOF
)"; then
  echo "  $out"
  pass
else
  fail "$out"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "test-insight-records: all checks passed"
else
  echo "test-insight-records: $FAILURES check(s) failed"
  exit 1
fi
