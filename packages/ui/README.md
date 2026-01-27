# @site360/ui

Shared UI component library using shadcn/ui and Tailwind CSS.

## Features

- Reusable components for web and mobile
- Tailwind CSS styling
- shadcn/ui components
- TypeScript support
- Consistent design system

## Usage

```typescript
import { Button, Card } from '@site360/ui';

export function MyComponent() {
  return (
    <Card>
      <Button>Click me</Button>
    </Card>
  );
}
```

## Development

```bash
# Build the package
pnpm build

# Type checking
pnpm type-check
```
