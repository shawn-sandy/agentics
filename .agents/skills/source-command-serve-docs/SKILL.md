---
name: "source-command-serve-docs"
description: "Migrated source command `serve-docs`"
---

# source-command-serve-docs

Use this skill when the user asks to run the migrated source command `serve-docs`.

## Command Template

Start a local HTTP server to browse the Plans gallery and Media library HTML files.

## Steps

1. Find a free port using Python:
   ```bash
   python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()"
   ```

2. Resolve the repo root from the current working directory using `git rev-parse --show-toplevel`, then start the server in the background from the `docs/` directory:
   ```bash
   REPO_ROOT="$(git rev-parse --show-toplevel)" && cd "$REPO_ROOT/docs" && python3 -m http.server <PORT> --bind 127.0.0.1 &
   ```

3. Print the URLs for the user:
   - Plans gallery: `http://localhost:<PORT>/plans/`
   - Media library: `http://localhost:<PORT>/media/social/`

4. Open the Plans gallery in the default browser:
   ```bash
   open "http://localhost:<PORT>/plans/" 2>/dev/null || xdg-open "http://localhost:<PORT>/plans/" 2>/dev/null || true
   ```

5. Tell the user the server is running and how to stop it (`kill %1` or `kill <PID>`).
