#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCS_DIR="$REPO_ROOT/docs"
PORT="${1:-0}"

if [ ! -d "$DOCS_DIR" ]; then
  echo "Error: docs/ directory not found at $DOCS_DIR" >&2
  exit 1
fi

if [ "$PORT" = "0" ]; then
  PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()")
fi

echo ""
echo "Serving docs at:"
echo "  Plans gallery:  http://localhost:$PORT/plans/"
echo "  Media library:  http://localhost:$PORT/media/social/"
echo ""
echo "Press Ctrl+C to stop."
echo ""

cd "$DOCS_DIR"
python3 -m http.server "$PORT" --bind 127.0.0.1
