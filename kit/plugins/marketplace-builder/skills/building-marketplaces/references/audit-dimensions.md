# Audit Dimensions: Scoring Criteria and Examples

Score each dimension 0, 1, or 2. Maximum total: **10 points**.

---

## Dimension 1: Repository Foundation (max 2)

Evaluates Claude Code integration readiness.

| Check | What to look for |
|-------|-----------------|
| CLAUDE.md | Present at root, >10 lines, has key sections (Project Overview, Tech Stack, Commands, Structure, Conventions) |
| `.claude/rules/` | Directory exists with at least one `.md` rule file |
| CLAUDE.local.md pattern | Either the file exists, or `.gitignore` includes `CLAUDE.local.md` |

**Scoring:**
- **2** — CLAUDE.md present with key sections + `.claude/rules/` has rule files + CLAUDE.local.md pattern documented
- **1** — CLAUDE.md present but incomplete (missing sections or <10 lines), OR `.claude/rules/` missing
- **0** — No CLAUDE.md at project root

---

## Dimension 2: Project Documentation (max 2)

Evaluates basic project documentation completeness.

| Check | What to look for |
|-------|-----------------|
| README.md | Present with overview, setup/installation, and usage sections |
| LICENSE | Any license file present |
| CONTRIBUTING.md | Contribution guidelines present (or equivalent section in README) |
| CHANGELOG.md | Version history present |
| .gitignore | Present and non-trivial (>5 entries, not just defaults) |

**Scoring:**
- **2** — README.md with substantive content + 3 or more of the other docs present
- **1** — README.md present + 1-2 other docs
- **0** — No README.md

---

## Dimension 3: Code Organization (max 2)

Evaluates directory structure and project layout.

| Check | What to look for |
|-------|-----------------|
| Directory structure | Clear top-level organization (not a flat dump of files in root) |
| Naming conventions | Consistent naming (kebab-case, camelCase, etc.) across directories and files |
| Separation of concerns | Source, tests, config, and docs are in distinct directories |
| Package manifest | package.json, Cargo.toml, pyproject.toml, go.mod, or equivalent present |

**Scoring:**
- **2** — Organized directory structure + package manifest present + consistent naming
- **1** — Some structure exists but incomplete (e.g., tests mixed with source, or no manifest)
- **0** — Flat file structure or chaotic organization, no manifest

---

## Dimension 4: Developer Experience (max 2)

Evaluates automation and onboarding quality.

| Check | What to look for |
|-------|-----------------|
| Build/test/lint scripts | Defined in package manifest (e.g., `npm test`, `make lint`) or Makefile |
| CI/CD config | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, or similar |
| Onboarding path | Can a new developer get the project running in under 5 minutes? (README has setup steps, dependencies are declared) |

**Scoring:**
- **2** — Scripts defined in manifest + CI/CD config present + clear onboarding path
- **1** — Some scripts exist but no CI, OR CI exists but no documented scripts
- **0** — No build/test automation, no CI/CD

---

## Dimension 5: Marketplace Readiness (max 2)

Evaluates Claude Code marketplace infrastructure. This is the dimension that differentiates this skill from general repo audits.

| Check | What to look for |
|-------|-----------------|
| `marketplace.json` | `.claude-plugin/marketplace.json` exists with required fields: `name` (kebab-case), `owner` (object with `name`), `plugins` (array) |
| Reserved names | Marketplace name is not reserved: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences` |
| Plugin structure | At least one plugin in `plugins/` with valid `.claude-plugin/plugin.json` (required: `name`, `description`, `version`) |
| Plugin entries | Each plugin listed in marketplace.json has required fields: `name`, `source` |
| Source validity | Relative source paths start with `./`, no `../` path traversal |
| Version placement | Version not set in both `plugin.json` and `marketplace.json` for the same plugin (`plugin.json` always wins silently) |
| Components | At least one plugin contains a `skills/` directory with a SKILL.md or `commands/` directory with command files |
| Validation | Passes `claude plugin validate .` or `/plugin validate .` |

**Scoring:**
- **2** — Valid marketplace.json + at least one valid plugin with skills or commands + passes validation
- **1** — Partial: marketplace.json exists OR plugin directories exist, but not both working together
- **0** — Neither marketplace.json nor any plugin structure present

---

## Grade Scale

| Total Score | Grade | Meaning |
|-------------|-------|---------|
| 9-10 | Marketplace-ready | Ready to distribute; may need polish |
| 7-8 | Well-structured | Good foundation; needs marketplace-specific files |
| 4-6 | Needs scaffolding | Has some structure; significant gaps to fill |
| 0-3 | Fresh start | Minimal structure; scaffold from the ground up |

---

## Example Audit Output

For a 4/10 "Needs scaffolding" repository:

```
## Marketplace Readiness Report

**Repository:** /Users/dev/my-tools
**Git:** Initialized, remote: origin (github.com/dev/my-tools), branch: main

### Inventory Summary

| Item | Status |
|------|--------|
| CLAUDE.md | missing |
| .claude/rules/ | missing |
| marketplace.json | missing |
| Plugin directories | 0 found |
| Skills detected | 0 |
| README.md | present |
| Package manifest | package.json |
| CI/CD | .github/workflows/ci.yml |

### Scores

| Dimension | Score | Max |
|-----------|-------|-----|
| Repository Foundation | 0 | 2 |
| Project Documentation | 1 | 2 |
| Code Organization | 2 | 2 |
| Developer Experience | 1 | 2 |
| Marketplace Readiness | 0 | 2 |
| **Total** | **4** | **10** |

**Grade:** Needs scaffolding

### Critical Gaps

1. **Repository Foundation (0/2):** No CLAUDE.md — Claude Code has no project context
2. **Marketplace Readiness (0/2):** No marketplace infrastructure at all

### Per-dimension Findings

- **Repository Foundation:** No CLAUDE.md, no .claude/rules/, no CLAUDE.local.md pattern
- **Project Documentation:** README.md present with overview and setup. Missing: LICENSE, CONTRIBUTING.md, CHANGELOG.md
- **Code Organization:** Clean directory structure (src/, tests/, config/). package.json present. Consistent kebab-case naming.
- **Developer Experience:** CI workflow present. package.json has test script but no lint or build scripts.
- **Marketplace Readiness:** No .claude-plugin/ directory. No plugins/ directory. No skills or commands.

### Top 3 Actions

1. Create `.claude-plugin/marketplace.json` with required fields and at least one plugin entry
2. Create `CLAUDE.md` with project overview, tech stack, and common commands
3. Scaffold a plugin directory with a skill or command to populate the marketplace
```
