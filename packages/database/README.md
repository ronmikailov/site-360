# @site360/database

Supabase database types, utilities, and client configuration shared across all Site360 applications.

## Features

- TypeScript types for database schema
- Supabase client configuration
- Database utilities and helpers
- Query builders

## Usage

```typescript
import { supabase } from '@site360/database';

// Use the Supabase client
const { data, error } = await supabase
  .from('projects')
  .select('*');
```

## Development

```bash
# Build the package
pnpm build

# Type checking
pnpm type-check
```
