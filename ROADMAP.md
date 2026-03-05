# Roadmap

This document tracks planned features for the agentics project. For current features, see [README.md](./README.md).

## Status: Planned

### Marketplace API

A REST API for discovering and serving Claude Code plugins.

**Planned endpoints:**

```bash
# Register a marketplace
POST /api/v1/marketplaces

# Sync and discover plugins
POST /api/v1/marketplaces/:name/sync

# List available plugins
GET /api/v1/plugins
```

**Prerequisites (when implemented):**
- Node.js 18.0.0 or later
- npm or yarn package manager

**Setup (when implemented):**
```bash
npm install
npm run dev
# API will be available at http://localhost:3000
```

### CLI Tools

- `agentics install` — Install plugins from the command line
- Plugin search and filtering
- Plugin scaffolding tools
- Publishing workflow

### Infrastructure

- Remote marketplace support
- Plugin versioning and update management
- Dependency management between plugins

## How to Track Progress

Feature requests and progress are tracked via [GitHub Issues](https://github.com/shawn-sandy/agentics/issues). If you'd like to contribute to any planned feature, see [CONTRIBUTING.md](./CONTRIBUTING.md).
