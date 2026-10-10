#!/usr/bin/env bash
set -u

# Validates and tests every mod plugin: a kit plugin whose hooks/hooks.json
# names a hooks module under "modules". tests/run-all.sh picks this file up,
# so mods join the merge gate's unit stage with no stage of their own.
#
# Mods need Claude Code 2.1.287+, and CI runners have no claude CLI, so with
# no CLI or an older one this prints a SKIP line and exits 0. That line is a
# skip, not a pass.
#
# `validate --strict` is not used: every relative-path plugin in this repo
# omits `version` by rule (marketplace.json carries it), and --strict fails
# every one of them on that warning. The JSON report is read instead, and any
# error, or any warning but that one, fails.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FLOOR=2.1.287

# Exits 0 when dotted version $1 is at least $2.
at_least() {
  awk -v have="$1" -v want="$2" 'BEGIN {
    split(have, h, "."); split(want, w, ".")
    for (i = 1; i <= 3; i++) if (h[i] + 0 != w[i] + 0) exit !(h[i] + 0 > w[i] + 0)
    exit 0
  }'
}

version="$(claude --version 2>/dev/null | awk '{ print $1 }')"
if [ -z "$version" ] || ! at_least "$version" "$FLOOR"; then
  echo "SKIP (claude < $FLOOR)"
  exit 0
fi

FAILURES=0
MODS=0

# Expected mods come from two sources: marketplace entries tagged "mod", and
# any hooks/hooks.json that names "modules". The tag is independent of the
# field under test, so a mod whose hooks.json loses or misspells "modules"
# still gets checked, and fails, instead of being skipped.
EXPECTED="$(node -e '
  const fs = require("fs"), path = require("path"), root = process.argv[1];
  const names = new Set(JSON.parse(fs.readFileSync(path.join(root, ".claude-plugin/marketplace.json"), "utf8"))
    .plugins.filter(p => (p.tags ?? []).includes("mod")).map(p => p.name));
  for (const d of fs.readdirSync(path.join(root, "kit/plugins"))) {
    try {
      if ("modules" in JSON.parse(fs.readFileSync(path.join(root, "kit/plugins", d, "hooks/hooks.json"), "utf8"))) names.add(d);
    } catch {}
  }
  console.log([...names].sort().join("\n"));
' "$ROOT")"

for name in $EXPECTED; do
  dir="$ROOT/kit/plugins/$name"
  MODS=$((MODS + 1))
  echo "=== $name (claude $version) ==="

  echo "0. hooks/hooks.json names at least one module..."
  if node -e 'const m = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).modules; process.exit(Array.isArray(m) && m.length > 0 ? 0 : 1)' "$dir/hooks/hooks.json" 2>/dev/null; then
    echo "  PASS"
  else
    echo "  FAIL: $dir/hooks/hooks.json is missing, unreadable, or names no modules"
    FAILURES=$((FAILURES + 1))
    continue
  fi

  echo "1. claude plugin validate: no errors, no warnings but the repo's missing version..."
  if claude plugin validate --json "$dir" 2>&1 | node -e '
    const report = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const files = [report.manifest, ...(report.contents ?? [])].filter(Boolean);
    const bad = files.flatMap(f => [
      ...f.errors.map(x => `error ${x.path}: ${x.message}`),
      ...f.warnings.filter(x => !(f === report.manifest && x.path === "version")).map(x => `warning ${x.path}: ${x.message}`),
    ]);
    for (const f of files) for (const n of f.notes ?? []) console.log("  " + n);
    for (const b of bad) console.log("  " + b);
    process.exit(bad.length ? 1 : 0);
  '; then
    echo "  PASS"
  else
    echo "  FAIL"
    FAILURES=$((FAILURES + 1))
  fi

  echo "2. claude plugin test..."
  if claude plugin test "$dir" 2>&1 | sed 's/^/  /'; [ "${PIPESTATUS[0]}" -eq 0 ]; then
    echo "  PASS"
  else
    echo "  FAIL"
    FAILURES=$((FAILURES + 1))
  fi
done

echo
echo "$MODS mod plugin(s) checked, $FAILURES failure(s)"
[ "$FAILURES" -eq 0 ]
