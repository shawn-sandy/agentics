---
allowed-tools:
  - Bash
  - Read
---

Start a local HTTP server to browse the Plans gallery and Media library HTML files.

## Steps

1. Find a free port using Python:
   ```bash
   python3 -c "import socket; s=socket.socket(); s.bind(('',0)); print(s.getsockname()[1]); s.close()"
   ```

2. Start the server in the background from the `docs/` directory at the root of this repo (not the worktree):
   ```bash
   cd ~/devbox/agentics/docs && python3 -m http.server <PORT> --bind 127.0.0.1 &
   ```

3. Print the URLs for the user:
   - Plans gallery: `http://localhost:<PORT>/plans/`
   - Media library: `http://localhost:<PORT>/media/social/`

4. Open the Plans gallery in the default browser:
   ```bash
   open "http://localhost:<PORT>/plans/"
   ```

5. Tell the user the server is running and how to stop it (`kill %1` or `kill <PID>`).
