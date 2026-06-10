#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE="$ROOT/kit/plugins/social-media-tools/templates/react-card.html"
PORT_SCRIPT="$ROOT/kit/plugins/social-media-tools/scripts/find_free_port.py"
FAILURES=0

WORKDIR="$(mktemp -d)"
SERVER_PID=""

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "=== React Card Smoke Test ==="

echo "0. Template exists..."
if [ -f "$TEMPLATE" ]; then
  echo "  PASS"
else
  echo "  FAIL: $TEMPLATE not found"
  exit 1
fi

echo "1. Populate template with sample Button component..."
python3 - "$TEMPLATE" "$WORKDIR/react-card.html" <<'PYEOF'
import sys

template_path, out_path = sys.argv[1], sys.argv[2]


def esc(text):
    # HTML-escape order: & first, then <, then >, then "
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


component_code = '''import * as React from "react";

// Render a <button> & forward the typed props below.
type ButtonProps = {
  label: string;
  variant?: "primary" | "ghost";
  disabled?: boolean;
};

export function Button({ label, variant = "primary", disabled = false }: ButtonProps) {
  const className = `btn btn--${variant}`;
  return (
    <button type="button" className={className} disabled={disabled}>
      {label}
    </button>
  );
}
'''

props = [
    ("label", "string", "Yes", "—", "Visible button text"),
    ('variant', '"primary" | "ghost"', "No", '"primary"', "Visual style of the button"),
    ("disabled", "boolean", "No", "false", "Disables pointer and keyboard interaction"),
]
props_rows = "\n".join(
    "<tr>" + "".join("<td>{}</td>".format(esc(cell)) for cell in row) + "</tr>"
    for row in props
)

preview_markup = (
    '<div class="preview-state">'
    '<span class="preview-state-label">Primary</span>'
    '<button style="background:#238636;color:#ffffff;border:none;'
    'border-radius:6px;padding:6px 16px;font-size:13px;">Save changes</button>'
    "</div>\n"
    '      <div class="preview-state">'
    '<span class="preview-state-label">Ghost</span>'
    '<button style="background:transparent;color:#e6edf3;border:1px solid #30363d;'
    'border-radius:6px;padding:6px 16px;font-size:13px;">Cancel</button>'
    "</div>"
)

substitutions = {
    "{{COMPONENT_NAME}}": esc("Button"),
    "{{FRAMEWORK_BADGE}}": "React · TSX",
    "{{PREVIEW_MARKUP}}": preview_markup,
    "{{COMPONENT_CODE}}": esc(component_code),
    "{{PROPS_ROWS}}": props_rows,
    "{{REPO_SLUG}}": esc("shawn-sandy/agentics"),
    "{{SOURCE_PATH}}": esc("src/components/Button.tsx"),
    "{{COPY_PANELS}}": '<div class="copy-panel">sample</div>',
}

with open(template_path, encoding="utf-8") as f:
    html = f.read()

for placeholder, value in substitutions.items():
    html = html.replace(placeholder, value)

with open(out_path, "w", encoding="utf-8") as f:
    f.write(html)
PYEOF
if [ -s "$WORKDIR/react-card.html" ]; then
  echo "  PASS"
else
  echo "  FAIL: populated react-card.html not written"
  exit 1
fi

echo "2. Serve temp dir and curl the page..."
PORT="$(python3 "$PORT_SCRIPT")"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$WORKDIR" >/dev/null 2>&1 &
SERVER_PID=$!

RESPONSE="$WORKDIR/response.html"
CURL_OK=0
for _ in $(seq 1 25); do
  if curl -fsS "http://127.0.0.1:${PORT}/react-card.html" -o "$RESPONSE" 2>/dev/null; then
    CURL_OK=1
    break
  fi
  sleep 0.2
done
if [ "$CURL_OK" -eq 1 ] && [ -s "$RESPONSE" ]; then
  echo "  PASS"
else
  echo "  FAIL: could not fetch page from http.server on port $PORT"
  exit 1
fi

echo "3. Contains class=\"preview-pane\"..."
if grep -q 'class="preview-pane"' "$RESPONSE"; then
  echo "  PASS"
else
  echo "  FAIL: class=\"preview-pane\" not found"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Contains language-tsx..."
if grep -q 'language-tsx' "$RESPONSE"; then
  echo "  PASS"
else
  echo "  FAIL: language-tsx not found"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Props tbody has >= 3 <tr> rows..."
TR_COUNT=$(sed -n '/<tbody>/,/<\/tbody>/p' "$RESPONSE" | grep -c '<tr>' || true)
if [ "$TR_COUNT" -ge 3 ]; then
  echo "  PASS ($TR_COUNT rows)"
else
  echo "  FAIL: expected >= 3 props rows, found $TR_COUNT"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Contains class=\"props-table\" with th scope=\"col\"..."
if grep -q 'class="props-table"' "$RESPONSE" && grep -q '<th scope="col">' "$RESPONSE"; then
  echo "  PASS"
else
  echo "  FAIL: props-table or th scope=\"col\" not found"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Contains --card-width in :root..."
if sed -n '/:root {/,/}/p' "$RESPONSE" | grep -qE '\-\-card-width'; then
  echo "  PASS"
else
  echo "  FAIL: --card-width not found in :root block"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Zero remaining {{ placeholders..."
PLACEHOLDER_COUNT=$(grep -c '{{' "$RESPONSE" || true)
if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
  echo "  PASS"
else
  echo "  FAIL: $PLACEHOLDER_COUNT line(s) still contain {{ placeholders"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "FAILED ($FAILURES failures)"
  exit 1
fi
