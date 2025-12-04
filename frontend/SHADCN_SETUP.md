# Using shadcn-vue CLI - Setup Guide

## Prerequisites

### Required Node.js Version

To use the `shadcn-vue` CLI, you need:

- **Node.js v20.10+** or **v22+** (recommended)
- Current version: `v20.5.1` ❌ (needs upgrade)

### Check Your Node Version

```bash
node --version
```

## Upgrading Node.js

### Option 1: Using nvm (Recommended)

```bash
# Install or update nvm if needed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install latest LTS version
nvm install --lts

# Or install specific version
nvm install 22

# Use the new version
nvm use 22

# Set as default
nvm alias default 22
```

### Option 2: Using Homebrew (macOS)

```bash
brew upgrade node
```

### Option 3: Download from nodejs.org

Visit [https://nodejs.org/](https://nodejs.org/) and download the latest LTS version.

## Adding shadcn-vue Components

Once Node.js is upgraded, you can use the CLI to add components:

### Add Dropdown Menu

```bash
npx -y shadcn-vue@latest add dropdown-menu
```

### Add Sidebar (sidebar-07 variant)

```bash
npx -y shadcn-vue@latest add sidebar-07
```

### Add Login Page (login-01 variant)

```bash
npx -y shadcn-vue@latest add login-01
```

### Add Signup Page (signup-03 variant)

```bash
npx -y shadcn-vue@latest add signup-03
```

## How the CLI Works

The shadcn-vue CLI will:

1. Check your `components.json` configuration
2. Download component files from the registry
3. Place them in the correct directory (`@/components/ui/`)
4. Install any missing dependencies
5. Update your configuration if needed

## Current Workaround

Since the current Node.js version doesn't support the CLI, components have been manually created following the shadcn-vue architecture:

- ✅ Components follow shadcn-vue patterns
- ✅ Uses `radix-vue` primitives
- ✅ Styled with Tailwind CSS
- ✅ Properly typed with TypeScript
- ✅ Compatible with the rest of the system

## Benefits of Using the CLI

When you upgrade Node.js, using the CLI will provide:

- Automatic dependency installation
- Official component implementations
- Easy updates and maintenance
- Access to all component variants
- Consistent file structure

## Verification

After adding components via CLI, verify they work:

```bash
# Start dev server
pnpm dev

# Check for any errors in the console
# Visit http://localhost:5173
```

## Component Configuration

Your project is already configured for shadcn-vue in `components.json`:

```json
{
  "$schema": "https://shadcn-vue.com/schema.json",
  "style": "default",
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/style.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
```

## Resources

- [shadcn-vue Documentation](https://www.shadcn-vue.com/)
- [Component Registry](https://www.shadcn-vue.com/docs/components)
- [radix-vue Documentation](https://www.radix-vue.com/)
- [Tailwind CSS Documentation](https://tailwindcss.com/)
