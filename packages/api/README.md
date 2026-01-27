# @site360/api

API client and TypeScript types for communicating with Site360 backend services.

## Features

- Type-safe API client
- Request/response types
- Error handling
- Authentication helpers

## Usage

```typescript
import { apiClient } from '@site360/api';

// Make API requests
const projects = await apiClient.projects.list();
```

## Development

```bash
# Build the package
pnpm build

# Type checking
pnpm type-check
```
