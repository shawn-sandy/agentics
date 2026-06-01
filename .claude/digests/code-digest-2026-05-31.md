# Code Digest — 2026-05-31

Mode: history (last 7 days)
Generated: 2026-05-31
Entries: 4

---

### 1. feat(issue-agent): open created issue in browser with --no-open flag (v0.2.0)

- **Source:** `2c802a16`
- **Card type:** feature-card
- **Platform:** LinkedIn
- **Summary:** New post-creation UX that automatically opens the created issue in the browser after a successful `gh`/`glab` issue create, with a `--no-open` opt-out flag for automation and non-interactive scenarios.
- **Key change / highlight:** `gh issue view <number> --web` (or `glab issue view`) is called after successful CLI creation; wrapped in error handling so a browser-open failure is non-fatal and never masks the issue URL.
- **Security:** PASS ✓
- **Already saved:** [SAVED: `docs/media/social/feature-issue-agent-v0-2-0-2026-05-31.html`]
- **share-code prompt:**
  ```
  /social-media-tools:share-code feature-card for LinkedIn: issue-agent now auto-opens the created issue in the browser after gh/glab create, with --no-open opt-out and graceful error fallback (v0.2.0)
  ```

---

### 2. feat(plan-agent): add plans-open skill to open gallery without rebuild

- **Source:** `1cad25d2`
- **Card type:** feature-card
- **Platform:** Twitter/X
- **Summary:** New minimal skill (`allowed-tools: Bash` only) that opens the existing plans gallery `index.html` instantly — no file scanning, no template substitution, no write operations.
- **Key change / highlight:** Reads `plansDirectory` from `.claude/settings.json` via an inline python3 heredoc (json.load → fallback to `docs/plans/`), checks for `index.html`, then opens it. If `index.html` is missing, prompts the user to run `/plan-agent:plans-library` first.
- **Security:** PASS ✓
- **share-code prompt:**
  ```
  /social-media-tools:share-code feature-card for Twitter/X: plan-agent now has a plans-open skill that opens the existing plans gallery instantly without any rebuild
  ```

---

### 3. feat(plan-agent): add Step 9 implement-or-exit prompt after plan delivery

- **Source:** `1c6fdacf`
- **Card type:** diff-card
- **Platform:** Bluesky
- **Summary:** The plan-agent workflow now ends with an explicit decision gate: implement now, schedule for later, or exit — preventing plans from being silently abandoned after delivery.
- **Key change / highlight:** Step 9 is a post-delivery prompt that respects the plan-then-act separation; the agent asks the user what to do next rather than defaulting to immediate implementation or stopping without offering a path forward.
- **Security:** PASS ✓
- **share-code prompt:**
  ```
  /social-media-tools:share-code diff-card for Bluesky: plan-agent Step 9 implement-or-exit prompt that closes the loop after plan delivery instead of leaving the user hanging
  ```

---

### 4. feat(plan-agent): add PostToolUse hook to auto-rebuild plans index (v0.14.1)

- **Source:** `b042e242`
- **Card type:** feature-card
- **Platform:** Twitter/X
- **Summary:** A Python PostToolUse hook that automatically rebuilds the plans gallery `index.html` after every plan HTML write, with a 2-second debounce to handle rapid sequential edits.
- **Key change / highlight:** Security-conscious implementation: uses `os.lstat` for stamp files (avoids symlink attacks), per-project stamp path via `hashlib.md5(os.getcwd())`, always exits 0 so a rebuild failure never blocks a plan write. Prefers `$CLAUDE_PLUGIN_ROOT/hooks/build-index.sh`, falls back to the project's own script.
- **Security:** PASS ✓
- **share-code prompt:**
  ```
  /social-media-tools:share-code feature-card for Twitter/X: plan-agent PostToolUse hook that auto-rebuilds the plans gallery after every plan write with 2s debounce and symlink-safe stamp files
  ```
