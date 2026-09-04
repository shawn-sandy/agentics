#!/usr/bin/env bash
set -euo pipefail

# MCP server definitions live in ~/.claude.json, but backing up the whole file
# would capture unrelated machine and account state. The settings-sync contract
# is narrower: when includeMcpServers is true, extract only the top-level
# mcpServers object to the backup repo's mcp-servers.json control file, include
# that generated file in the Step 4 secret scan, and restore by printing
# claude mcp add-json commands rather than mutating ~/.claude.json.
#
# This test runs the skill's own snippets, extracted by their markdown markers.
# The token is assembled at runtime so this repository never stores a literal
# credential-shaped value.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKUP_SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"
RESTORE_SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-restore/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
REPO="$TMP/backup"
mkdir -p "$HOME_DIR/.claude" "$REPO" "$TMP/bin"

git -c init.defaultBranch=main init -q "$REPO"
git -C "$REPO" config user.name test
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config commit.gpgsign false

printf '#!/bin/sh\necho 9.9.9-test\n' > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"

cat > "$HOME_DIR/.claude/settings-sync.json" <<JSON
{
  "repoPath": "$REPO",
  "includeLocalSettings": false,
  "includeMcpServers": true
}
JSON

FAKE_TOKEN="sk-test-$(printf 'x%.0s' {1..24})"
cat > "$HOME_DIR/.claude.json" <<JSON
{
  "theme": "dark",
  "mcpServers": {
    "secret-demo": {
      "command": "node",
      "args": ["server.js"],
      "env": {
        "OPENAI_API_KEY": "$FAKE_TOKEN"
      }
    }
  },
  "unrelated": {
    "mcpServers": {
      "nested": {
        "command": "false"
      }
    }
  }
}
JSON
CLAUDE_JSON_SUM="$(cksum < "$HOME_DIR/.claude.json")"

extract() {
  local file="$1" marker="$2"
  SNIPPET="$(awk -v m="$marker" 'index($0, m) == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$file")"
  if [ -z "$SNIPPET" ]; then
    echo "FAIL: no bash block after '$marker' in $file"
    exit 1
  fi
  SNIPPET="${SNIPPET//<repo-path>/$REPO}"
}

run_block() {
  local label="$1" snippet="$2" out="$3" rc=0
  HOME="$HOME_DIR" PATH="$TMP/bin:$PATH" bash -c "$snippet" >"$out" 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: $label exited $rc"
    sed 's/^/  | /' "$out"
    exit 1
  fi
}

extract "$BACKUP_SKILL" '**Extract MCP servers.**';        EXTRACT="$SNIPPET"
extract "$BACKUP_SKILL" '**Scan the backup sources.**';    SCAN="$SNIPPET"
extract "$BACKUP_SKILL" '**Commit only real changes.**';   COMMIT="$SNIPPET"
extract "$RESTORE_SKILL" '**Print MCP add-json commands.**'; MCP_COMMANDS="$SNIPPET"
RESTORE_STEP3="$(awk '/^### Step 3/ {f=1; next} /^### Step 4/ {exit} f' "$RESTORE_SKILL")"

run_block "MCP extraction block" "$EXTRACT" "$TMP/extract.out"
run_block "secret scan block" "$SCAN" "$TMP/scan.out"
run_block "commit block" "$COMMIT" "$TMP/commit.out"
run_block "restore MCP command block" "$MCP_COMMANDS" "$TMP/restore.out"

FAILURES=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    FAILURES=$((FAILURES + 1))
  fi
}

check "mcp-servers.json is generated"             test -f "$REPO/mcp-servers.json"
check "generated file contains the named server"   grep -q '"secret-demo"' "$REPO/mcp-servers.json"
check "generated file keeps the server token"      grep -qF "$FAKE_TOKEN" "$REPO/mcp-servers.json"
check "generated file excludes unrelated root keys" bash -c '! grep -q "\"theme\"\\|\"unrelated\"\\|\"nested\"" "$1"' _ "$REPO/mcp-servers.json"
check "generated file parses as JSON"              python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$REPO/mcp-servers.json"
check "Step 4 scan reports mcp-servers.json"       grep -qF "$REPO/mcp-servers.json" "$TMP/scan.out"
check "Step 4 scan reports the fake token"         grep -qF "$FAKE_TOKEN" "$TMP/scan.out"
check "metadata lists mcp-servers.json"            python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); sys.exit(0 if "mcp-servers.json" in data["filesIncluded"] else 1)' "$REPO/.settings-sync-meta.json"
check "restore prints add-json command"            grep -q '^claude mcp add-json secret-demo ' "$TMP/restore.out"
check "restore command carries server JSON"        grep -qF "$FAKE_TOKEN" "$TMP/restore.out"
check "restore command does not modify ~/.claude.json" test "$(cksum < "$HOME_DIR/.claude.json")" = "$CLAUDE_JSON_SUM"
check "restore marks mcp-servers.json as control" bash -c 'grep -qF "$1" <<<"$2"' _ '`mcp-servers.json` is a generated control file' "$RESTORE_STEP3"

echo
echo "scan output:"
sed 's/^/  | /' "$TMP/scan.out"
echo
echo "restore output:"
sed 's/^/  | /' "$TMP/restore.out"

if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
