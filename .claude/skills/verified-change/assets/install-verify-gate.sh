#!/usr/bin/env bash
# Copies the verified-change merge gate into the current repo as scripts/verify.sh.
#
# Invoked through the bin/install-verify-gate wrapper, which is what puts it on
# the Bash tool's PATH under a bare name. See that file for why a documented
# ${CLAUDE_PLUGIN_ROOT} path could never run.
#
# Usage:
#   install-verify-gate            # install into ./scripts/verify.sh
#   install-verify-gate --force    # overwrite an existing one
set -euo pipefail

SRC="$(dirname "$0")/verify.sh"
DEST="scripts/verify.sh"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "install-verify-gate: unknown argument '$arg' (expected --force)" >&2; exit 2 ;;
  esac
done

if [ ! -f "$SRC" ]; then
  echo "install-verify-gate: template missing at $SRC" >&2
  exit 1
fi

if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  echo "install-verify-gate: $DEST already exists. Re-run with --force to overwrite it." >&2
  exit 1
fi

mkdir -p scripts
cp "$SRC" "$DEST"
chmod +x "$DEST"

# Verify the write rather than trusting the copy: cp reports success on a
# truncated write to a full disk, and a gate that is half a file is worse than
# no gate because it still exits 0 on the lines that survived.
if ! cmp -s "$SRC" "$DEST"; then
  echo "install-verify-gate: $DEST does not match the template after copying." >&2
  exit 1
fi

echo "install-verify-gate: wrote $DEST"
echo "Run it with: bash scripts/verify.sh"
