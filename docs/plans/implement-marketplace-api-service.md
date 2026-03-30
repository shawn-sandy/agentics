---
status: in-progress
created: 2026-01-19
modified: 2026-02-26
---

# Claude Plugin Marketplace API - Implementation Plan

## Overview

Building a **CLI/API registry** for Claude Code plugins with install & manage capabilities using Node.js/TypeScript. This will be a RESTful API service that acts as a centralized registry for discovering, searching, and managing Claude Code plugin marketplaces.

## Architecture

**Type**: RESTful API service + CLI tool
**Stack**: Node.js, TypeScript, Express
**Storage**: File-based JSON (migrateable to database)
**Integration**: GitHub API for syncing marketplace data

## Project Structure

```
agentics/
├── src/
│   ├── index.ts                          # Express server entry point
│   ├── config/environment.ts             # Environment configuration
│   ├── routes/
│   │   ├── marketplaces.ts               # Marketplace endpoints
│   │   ├── plugins.ts                    # Plugin endpoints
│   │   └── search.ts                     # Search endpoints
│   ├── controllers/
│   │   ├── marketplace.controller.ts
│   │   ├── plugin.controller.ts
│   │   └── search.controller.ts
│   ├── services/
│   │   ├── marketplace.service.ts        # CRITICAL: Core business logic
│   │   ├── plugin.service.ts             # Plugin operations
│   │   ├── github.service.ts             # CRITICAL: GitHub integration
│   │   └── storage.service.ts            # CRITICAL: Data persistence
│   ├── models/
│   │   └── types.ts                      # CRITICAL: Data models
│   ├── validators/
│   │   ├── marketplace.validator.ts      # Zod schemas
│   │   └── plugin.validator.ts
│   ├── middleware/
│   │   ├── error-handler.ts
│   │   ├── validation.ts
│   │   └── cors.ts
│   └── utils/
│       ├── logger.ts
│       ├── semver.ts
│       └── response.ts
├── data/
│   ├── marketplaces.json                 # Marketplace registry
│   └── cache/                            # Cached metadata
├── cli/
│   └── index.ts                          # CLI tool
├── tests/
│   ├── unit/
│   └── integration/
├── .env.example
├── tsconfig.json
├── package.json
└── README.md
```

## Core Data Models

### Marketplace Schema
```typescript
interface Marketplace {
  id: string;                        // Unique identifier
  name: string;
  description: string;
  version: string;
  source: {
    type: 'github' | 'git' | 'local';
    repo?: string;                   // e.g., "anthropics/claude-code"
    url?: string;
    branch?: string;
  };
  owner: {
    name: string;
    email?: string;
    url?: string;
  };
  pluginCount: number;
  plugins: PluginSummary[];
  tags: string[];
  verified: boolean;
  lastUpdated: string;
  createdAt: string;
}
```

### Plugin Schema
```typescript
interface Plugin {
  id: string;                       // ${name}@${marketplaceId}
  name: string;
  version: string;
  description: string;
  marketplaceId: string;
  author?: { name: string; email?: string };
  category?: string;
  tags?: string[];
  components: {
    commands?: string[];
    skills?: string[];
    agents?: string[];
    hooks?: string[];
    mcp?: boolean;
  };
  installInfo: {
    installCommand: string;
    marketplaceCommand: string;
  };
}
```

## API Endpoints

### Marketplaces
- `GET /api/v1/marketplaces` - List all marketplaces
- `GET /api/v1/marketplaces/:id` - Get marketplace details
- `POST /api/v1/marketplaces` - Register new marketplace
- `PUT /api/v1/marketplaces/:id` - Update marketplace
- `DELETE /api/v1/marketplaces/:id` - Remove marketplace
- `POST /api/v1/marketplaces/:id/sync` - Sync from GitHub
- `GET /api/v1/marketplaces/:id/plugins` - List marketplace plugins

### Plugins
- `GET /api/v1/plugins` - List all plugins (paginated)
- `GET /api/v1/plugins/:id` - Get plugin details
- `GET /api/v1/plugins/search?q=<query>` - Search plugins
- `GET /api/v1/plugins/categories` - List categories
- `GET /api/v1/plugins/popular` - Popular plugins

### Health
- `GET /api/health` - Health check
- `GET /api/v1/stats` - Registry statistics

## Implementation Steps

### Phase 1: Project Setup
1. Initialize package.json with dependencies
2. Configure TypeScript (tsconfig.json)
3. Set up Express server with basic routing
4. Configure environment variables (.env.example)
5. Set up ESLint and Prettier
6. Create basic project structure

**Key Dependencies**:
- express, cors, helmet, dotenv
- zod (validation), semver (versioning)
- winston (logging), octokit (GitHub API)
- typescript, tsx, vitest

### Phase 2: Core Data Layer
1. **Create src/models/types.ts** - Define all TypeScript interfaces
2. **Create src/services/storage.service.ts** - File-based JSON storage
3. **Create src/validators/marketplace.validator.ts** - Zod schemas
4. **Create src/validators/plugin.validator.ts** - Zod schemas
5. Initialize data/marketplaces.json with empty array
6. Create data/cache/ directory

### Phase 3: Marketplace Service
1. **Create src/services/marketplace.service.ts**
   - CRUD operations for marketplaces
   - Marketplace registration and validation
   - Sync coordination
2. **Create src/services/github.service.ts**
   - Fetch marketplace.json from GitHub
   - Parse plugin metadata
   - Handle GitHub API errors
3. Implement marketplace sync logic

### Phase 4: Plugin Service
1. **Create src/services/plugin.service.ts**
   - Plugin indexing and aggregation
   - Search functionality
   - Category filtering
2. Build plugin cache from synced marketplaces
3. Implement semver version management

### Phase 5: API Routes & Controllers
1. **Create src/routes/marketplaces.ts** - Marketplace endpoints
2. **Create src/controllers/marketplace.controller.ts**
3. **Create src/routes/plugins.ts** - Plugin endpoints
4. **Create src/controllers/plugin.controller.ts**
5. **Create src/routes/search.ts** - Search endpoints
6. **Create src/controllers/search.controller.ts**

### Phase 6: Middleware & Utilities
1. Create src/middleware/error-handler.ts - Global error handling
2. Create src/middleware/validation.ts - Request validation
3. Create src/middleware/cors.ts - CORS configuration
4. Create src/utils/logger.ts - Winston logger setup
5. Create src/utils/response.ts - Standardized responses
6. Create src/utils/semver.ts - Version helpers

### Phase 7: CLI Tool
1. Create cli/index.ts with commands:
   - `agentics marketplace add <repo>`
   - `agentics marketplace sync <id>`
   - `agentics plugin search <query>`
   - `agentics serve --port 3000`
2. Add bin entry to package.json

### Phase 8: Testing
1. Set up Vitest configuration
2. Create unit tests for services
3. Create integration tests for API endpoints
4. Add test fixtures
5. Aim for 80%+ coverage

### Phase 9: Documentation
1. Update README.md with:
   - Installation instructions
   - API documentation
   - Usage examples
   - Configuration options
2. Create .env.example with required variables
3. Add API examples and curl commands

## Critical Files to Create (Priority Order)

1. **package.json** - Project dependencies and scripts
2. **tsconfig.json** - TypeScript configuration
3. **src/models/types.ts** - Core data models and interfaces
4. **src/services/storage.service.ts** - Data persistence layer
5. **src/services/marketplace.service.ts** - Marketplace business logic
6. **src/services/github.service.ts** - GitHub integration
7. **src/routes/marketplaces.ts** - API routes
8. **src/index.ts** - Express server setup

## Environment Variables

```bash
# Server
PORT=3000
NODE_ENV=development

# GitHub
GITHUB_TOKEN=ghp_xxxxx                # Optional, for higher rate limits
GITHUB_API_URL=https://api.github.com

# Storage
DATA_DIR=./data
CACHE_DIR=./data/cache

# Logging
LOG_LEVEL=info
```

## Verification Plan

### 1. Start Development Server
```bash
npm run dev
```

### 2. Register Official Marketplace
```bash
curl -X POST http://localhost:3000/api/v1/marketplaces \
  -H "Content-Type: application/json" \
  -d '{
    "name": "claude-code-plugins",
    "description": "Official Claude Code plugins",
    "source": {
      "type": "github",
      "repo": "anthropics/claude-code"
    },
    "owner": {
      "name": "Anthropic"
    }
  }'
```

### 3. Sync Marketplace Data
```bash
curl -X POST http://localhost:3000/api/v1/marketplaces/claude-code-plugins/sync
```

### 4. List All Marketplaces
```bash
curl http://localhost:3000/api/v1/marketplaces
```

### 5. Search for Plugins
```bash
curl "http://localhost:3000/api/v1/plugins/search?q=code+review"
```

### 6. Get Plugin Details
```bash
curl http://localhost:3000/api/v1/plugins/code-review@claude-code-plugins
```

### 7. Use CLI Tool
```bash
# Add marketplace
agentics marketplace add anthropics/claude-code

# Sync marketplace
agentics marketplace sync claude-code-plugins

# Search plugins
agentics plugin search "feature development"
```

### 8. Run Tests
```bash
npm test
npm run test:coverage
```

### Expected Results
- ✅ Server starts on port 3000
- ✅ Marketplace registered successfully
- ✅ Sync fetches ~13 plugins from GitHub
- ✅ Search returns relevant plugins
- ✅ Plugin details include install commands
- ✅ CLI commands work correctly
- ✅ All tests pass with 80%+ coverage

## Security Considerations

1. **Input Validation**: Use Zod for all inputs
2. **Rate Limiting**: Protect API endpoints
3. **CORS**: Configure allowed origins
4. **GitHub Token**: Store in environment variables only
5. **Error Messages**: Don't expose internal details
6. **Dependency Security**: Regular npm audit

## Future Enhancements

1. PostgreSQL/MongoDB migration
2. Authentication for write operations
3. Download analytics and popularity tracking
4. CDN integration for caching
5. GitHub webhooks for auto-sync
6. Plugin validation and security scanning
7. Web UI for browsing
8. Plugin reviews and ratings
