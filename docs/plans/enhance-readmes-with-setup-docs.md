---
status: completed
type: artifact
created: 2026-02-22
modified: 2026-02-26
---

# Installation Instructions Enhancement Plan

## Overview
Add comprehensive installation instructions to the README files for both developers testing plugins locally and end users (when marketplace is ready). Current documentation jumps directly to usage without proper prerequisites, setup steps, or troubleshooting guidance.

## Key Findings
- Main README has "Quick Start" but lacks prerequisites and installation steps
- Individual plugin READMEs have inconsistent installation sections
- Marketplace API is documented but marked "in progress" - needs clarity
- Two distinct audiences: developers (local testing with `--plugin-dir`) and future end users (via marketplace API/CLI)
- Existing documentation follows progressive disclosure pattern and clear section structures

## Implementation Plan

### Phase 1: Main README Enhancement
**File:** `/Users/shawnsandy/devbox/agentics/README.md`

#### 1. Add Prerequisites Section
**Insert after line 13 (after Overview, before Project Structure)**

Add comprehensive prerequisites covering:
- Required: Claude Code CLI (version 1.0.0+) with verification command
- Optional (for API dev): Node.js 18.0.0+, npm/yarn
- Platform support: macOS 12.0+, Linux (Ubuntu 20.04+), Windows (WSL2 recommended)
- Optional tools: Git, curl, jq for JSON parsing

#### 2. Add Installation Section
**Insert after Prerequisites section**

Create two-track installation guide:
- **For Plugin Users (Testing Example Plugins):**
  - Quick start with git clone
  - Direct plugin loading with `--plugin-dir`
  - Verification step
  - Note: No dependencies required for basic plugin testing

- **For Marketplace API Developers:**
  - Clone repository
  - Install dependencies (when API implemented)
  - Start dev server
  - Note: API is in development, plugins work independently

Include troubleshooting subsection for common issues:
- "claude: command not found"
- Plugin not loading
- Permission errors

#### 3. Enhance Quick Start → Rename to "Usage Guide"
**Modify existing section at lines 29-84**

Restructure into clear audience segments:
- **For Plugin Users:**
  - Single plugin testing
  - Multiple plugin testing
  - Add tip about automatic skill activation vs explicit commands

- **For API Developers:**
  - Keep existing marketplace workflow
  - Emphasize "in progress" status more clearly
  - Add setup prerequisites reference

### Phase 2: Plugin Directory README Enhancement
**File:** `/Users/shawnsandy/devbox/agentics/plugins/README.md`

#### 1. Enhance "Testing Plugins Locally" Section
**Modify section starting around line 24**

Add:
- Prerequisites check subsection (verify Claude Code, working directory, list plugins)
- Troubleshooting common issues (plugin not found, command not recognized, skill not activating)
- Working directory clarification (use absolute paths if needed)

### Phase 3: Individual Plugin README Standardization

#### hello-world Plugin
**File:** `/Users/shawnsandy/devbox/agentics/plugins/hello-world/README.md`

Standardize Installation section to include:
- Prerequisites (Claude Code CLI, Git)
- Two loading patterns:
  - Option 1: From repository root
  - Option 2: From plugin directory
- Via Marketplace (labeled as "Planned")
- Verification test with expected output

#### dev-tools Plugin
**File:** `/Users/shawnsandy/devbox/agentics/plugins/dev-tools/README.md`

Standardize Installation section to include:
- Prerequisites with optional dependencies clearly labeled (Prettier, Black)
- Two loading patterns (same as hello-world)
- Via Marketplace (labeled as "Planned")
- Verification for both commands and skills
- Note about formatter dependencies being detected

### Phase 4: Marketplace Data README Enhancement
**File:** `/Users/shawnsandy/devbox/agentics/marketplace-data/README.md`

Add Installation section covering:
- Prerequisites (for API testing vs plugin usage)
- Setup instructions for testing marketplace configuration
- Direct plugin testing (no API needed)
- API workflow (when available) with clear "in development" status

## Content Guidelines

### Consistent Section Ordering
All READMEs should follow:
1. Title
2. Overview
3. Features
4. Installation (with Prerequisites subsection)
5. Usage
6. Structure/Components
7. Development/Contributing

### Terminology Standards
- **Plugin** (not extension, add-on, module)
- **Command** (explicit `/plugin:command` invocation)
- **Skill** (auto-activated based on user intent)
- **Local testing** (using `--plugin-dir`)
- **Marketplace installation** (future CLI-based install)

### Audience Labels
- "For Plugin Users" - Testing example plugins
- "For Developers" - Plugin development
- "For API Developers" - Marketplace API work

### Code Block Conventions
- Use bash language identifier
- Include explanatory comments
- Show expected output when relevant
- Provide both relative and absolute path examples

## Critical Files to Modify

1. `/Users/shawnsandy/devbox/agentics/README.md` (highest priority)
   - Add Prerequisites section
   - Add Installation section
   - Enhance Quick Start → Usage Guide

2. `/Users/shawnsandy/devbox/agentics/plugins/README.md`
   - Enhance testing section with prerequisites and troubleshooting

3. `/Users/shawnsandy/devbox/agentics/plugins/hello-world/README.md`
   - Standardize Installation section

4. `/Users/shawnsandy/devbox/agentics/plugins/dev-tools/README.md`
   - Standardize Installation section with dependency handling

5. `/Users/shawnsandy/devbox/agentics/marketplace-data/README.md`
   - Add Installation section

## Implementation Priorities

**Priority 1 (Critical):**
- Main README Prerequisites
- Main README Installation
- Main README Usage Guide enhancement

**Priority 2 (High Value):**
- Plugin directory README enhancements
- Individual plugin README standardization

**Priority 3 (Completeness):**
- Marketplace data README installation section

## Verification Steps

After implementation:
1. **Beginner Test:** Can a complete beginner follow main README and load a plugin successfully?
2. **Command Accuracy:** All code examples execute without errors
3. **Prerequisites Verification:** All version numbers and requirements are accurate and testable
4. **Troubleshooting Coverage:** Common issues are addressed with solutions
5. **Link Integrity:** No broken internal documentation links
6. **Formatting Consistency:** All files use consistent markdown formatting and structure

## Edge Cases Addressed

1. **Working Directory Confusion:** Show expected `pwd` output or use absolute paths in examples
2. **Version Mismatches:** Clear version requirements with verification commands
3. **Optional Dependencies:** Label optional vs required, explain degraded functionality
4. **Platform Differences:** Note Windows WSL2 recommendation, platform-specific install commands
5. **API Status Clarity:** Consistent "(in progress)" or "(planned)" labels for incomplete features

## Success Criteria

✅ User can determine prerequisites before starting
✅ User can install and test a plugin in under 5 minutes
✅ Clear separation between local testing (works now) and marketplace (planned)
✅ Consistent installation patterns across all plugin documentation
✅ Troubleshooting guidance for common setup issues
✅ Progressive disclosure (simple path first, advanced later)
