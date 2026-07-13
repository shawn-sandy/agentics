---
status: in-progress
created: 2026-03-05
---

# Open-Source Readiness Plan

**Goal:** Prepare the agentics repository for public open-source release so that new users can discover, understand, install, and contribute to the plugin marketplace effectively.

---

## Phase 1: Critical Fixes (Must do before going public)

These are issues that would confuse or mislead users on first contact.

### 1.1 Fix README clone URL placeholders
- **File:** `README.md` (lines 70, 101)
- **Change:** Replace `https://github.com/yourusername/agentics.git` with `https://github.com/shawn-sandy/agentics.git`

### 1.2 Fix README copyright mismatch
- **File:** `README.md` (line 511)
- **Change:** Replace `Copyright (c) 2024 Agentics Project` with `Copyright (c) 2026 Shawn Sandy` to match `LICENSE` file

### 1.3 Fix hardcoded local paths in README
- **File:** `README.md` (line 376)
- **Change:** Replace `~/devbox/agentics` with generic path using the repo clone approach:
  ```
  /plugin marketplace add /path/to/agentics
  ```

### 1.4 Fix hardcoded local paths in CLAUDE.md
- **File:** `CLAUDE.md`
- **Change:** Replace `~/devbox/agentics/plugins/<name>` with `./plugins/<name>` (relative) or a clearly-generic placeholder. Also update marketplace add example.

### 1.5 Add all 9 plugins to README (currently only shows 5)
- **File:** `README.md` (lines 264-369)
- **Change:** Add sections for the 4 missing plugins:
  - `wcag-compliance-reviewer` (v1.1.0)
  - `skill-reviewer` (v1.4.0)
  - `code-test-suggestion` (v2.2.1)
  - `git-agent` (v1.0.0)

### 1.6 Fix stale version numbers in README
- **File:** `README.md`
- **Changes:**
  - `code-review v1.0.0` → `v2.1.0`
  - `plan-interview v1.0.0` → `v1.3.0`
  - `claude-md-optimizer v1.0.0` → `v1.5.0`

### 1.7 Fix project structure tree in README
- **File:** `README.md` (lines 47-59)
- **Change:** Add the 4 missing plugin directories to the tree

### 1.8 Fix dev-tools cross-contamination
- **File:** `README.md` (line 295-296)
- **Change:** Remove the `/dev-tools:plan-interview` row — it belongs to the plan-interview plugin, not dev-tools. Verify the actual dev-tools plugin only has a `format` command.

### 1.9 Update Test Marketplace section with all 9 plugins
- **File:** `README.md` (lines 376-382)
- **Change:** Add install lines for the 4 new plugins

### 1.10 Update Roadmap "Current Features" list
- **File:** `README.md` (lines 458-465)
- **Change:** Add the 4 newer plugins to the current features list

---

## Phase 2: Move Non-Existent API Content to ROADMAP.md

The README currently describes a REST API, npm install, npm run dev workflow that doesn't exist. This will confuse users.

### 2.1 Create ROADMAP.md
- **File:** `ROADMAP.md` (new)
- **Content:** Move the following sections from README.md:
  - "For Marketplace API Developers" installation section (lines 95-118)
  - "For API Developers" usage section (lines 228-262)
  - "In Progress" and "Planned Features" items from Roadmap (lines 467-479)
- Include a clear "Status: Planned" label
- Link back from README

### 2.2 Clean up README after extraction
- **File:** `README.md`
- **Changes:**
  - Remove the "Optional (For API Development)" prerequisites (Node.js, npm) — not needed today
  - Remove "For Marketplace API Developers" installation section
  - Remove "For API Developers" usage section
  - Simplify the Roadmap section to link to ROADMAP.md
  - Keep the README focused on what works today: plugins + marketplace

---

## Phase 3: Community Infrastructure

Standard files that open-source consumers and contributors expect.

### 3.1 Create CONTRIBUTING.md
- **File:** `CONTRIBUTING.md` (new)
- **Content:**
  - How to report bugs (GitHub Issues)
  - How to propose new plugins
  - Plugin development workflow (create, test with --plugin-dir, register in marketplace.json)
  - PR process and conventions
  - Code of conduct reference
  - Link to plugin structure docs in `plugins/README.md`

### 3.2 Create CODE_OF_CONDUCT.md
- **File:** `CODE_OF_CONDUCT.md` (new)
- **Content:** Contributor Covenant v2.1 (standard)

### 3.3 Create SECURITY.md
- **File:** `SECURITY.md` (new)
- **Content:**
  - How to report security vulnerabilities (email or GitHub private advisory)
  - Scope (plugin marketplace, not Claude Code itself)
  - Supported versions

### 3.4 Create GitHub Issue Templates
- **Files:**
  - `.github/ISSUE_TEMPLATE/bug_report.md`
  - `.github/ISSUE_TEMPLATE/feature_request.md`
  - `.github/ISSUE_TEMPLATE/new_plugin.md`
- **Content:** Structured templates with relevant fields

### 3.5 Create GitHub PR Template
- **File:** `.github/PULL_REQUEST_TEMPLATE.md`
- **Content:** Checklist for plugin PRs (manifest updated, version synced, tested locally, README updated)

---

## Phase 4: Polish and Optimization

Nice-to-have improvements that make the repo more professional and useful.

### 4.1 Add marketplace owner field note
- **File:** `.claude-plugin/marketplace.json`
- **Change:** Consider whether the personal email `shawnsandy04@gmail.com` should remain or be replaced with a project-specific contact. Not blocking, but worth deciding.

### 4.2 Improve README hero section
- **File:** `README.md`
- **Change:** Add a one-liner quick start at the very top (before the overview) showing the fastest path to value:
  ```
  ## Quick Start
  git clone https://github.com/shawn-sandy/agentics.git
  cd agentics
  claude --plugin-dir ./plugins/code-review
  # Then ask: "Review this code for issues"
  ```

### 4.3 Add badges to README
- **File:** `README.md`
- **Change:** Add standard badges (license, plugin count, Claude Code version requirement)

### 4.4 Verify all plugin CHANGELOGs exist and are current
- **Check each plugin directory** for CHANGELOG.md
- Create missing ones with at least the current version entry

### 4.5 Verify all plugin homepage URLs
- **Check each plugin.json** for correct `homepage` pointing to the plugin's directory in the repo (per CLAUDE.md convention)

---

## Summary of Files to Modify

| File | Phase | Action |
|------|-------|--------|
| `README.md` | 1, 2 | Major update — fix URLs, versions, structure, remove API sections |
| `CLAUDE.md` | 1 | Fix local path examples |
| `ROADMAP.md` | 2 | New file — extracted API plans |
| `CONTRIBUTING.md` | 3 | New file |
| `CODE_OF_CONDUCT.md` | 3 | New file |
| `SECURITY.md` | 3 | New file |
| `.github/ISSUE_TEMPLATE/*` | 3 | New files (3 templates) |
| `.github/PULL_REQUEST_TEMPLATE.md` | 3 | New file |
| `.claude-plugin/marketplace.json` | 4 | Review owner email |
| Various `plugin.json` files | 4 | Verify homepage URLs |
| Various `CHANGELOG.md` files | 4 | Verify existence |

---

## Execution Order

Phases 1 and 2 should be done first (they fix misleading content). Phase 3 can follow immediately. Phase 4 is optional polish that can be done incrementally.
