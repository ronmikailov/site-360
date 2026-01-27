# Site360

**Construction Site Management Platform**

Bringing transparency, efficiency, and data-driven decision-making to the building industry.

---

## Vision

The construction world currently relies on fragmented communication (WhatsApp, paper logs) for critical operations. Site360 replaces these manual processes with a centralized system for:

- 📊 **Material Usage Tracking** — Real-time monitoring against building plans
- 📅 **Project Timeline Management** — Track progress and milestones
- ✅ **Standards Compliance** — Ensure adherence to building specifications

---

## Project Status

🚧 **Early Development** - Site360 is currently in the planning and architecture phase. The core infrastructure (AI orchestration, issue tracking, MCP integration) is being established.

### Planned Applications

- **📱 Mobile App** (React Native) - Native iOS and Android apps for on-site data collection and real-time updates
- **🌐 Web App** (Next.js) - Full-featured web dashboard for project management, analytics, and reporting
- **🔄 Real-time Sync** - Seamless data synchronization across all platforms via Supabase Realtime

---

## Core Features

Site360 provides comprehensive control and monitoring across all critical aspects of construction management:

### 📐 Planning & Design Control
- **Planning Control** - Ensure work follows approved plans and correct versions
- **Design Change Control** - Track changes made vs. changes approved, maintain change history
- **Documentation Control** - Daily logs, photos, and time-stamped records with no gaps

### 📊 Progress & Performance Tracking
- **Schedule/Pace Control** - Real-time progress monitoring against targets and milestones
- **Material Control** - Actual consumption vs. planned usage with automatic variance alerts
- **Loss/Theft Prevention** - Material tracking and anomaly detection
- **Quality Control** - Defect tracking, rework monitoring, and quality assurance workflows

### 👷 Workforce & Resources
- **Subcontractor Management** - Output tracking, deviation monitoring, and performance analytics
- **Workforce Control** - Attendance tracking correlated with pace and productivity
- **Equipment Control** - Availability monitoring, usage tracking, shortage/surplus alerts

### ⚠️ Safety & Compliance
- **Safety Control** - Risk tracking, incident reporting, Near Miss documentation
- **Regulatory Compliance** - Ensure adherence to regulations and legal requirements
- **Site Organization** - Order, cleanliness, and environmental monitoring

### 🎯 Overall Management
- **Comprehensive Control Dashboard** - Identify blind spots and areas lacking control
- **Real-time Alerts** - Automatic notifications for any deviations from plans or targets
- **Cross-Platform Access** - Available on mobile (on-site) and web (office)

### 🔗 Technical Features
- **MCP Integration** - Connect to Model Context Protocol servers for building plan analysis
- **Offline Capability** - Mobile apps work without internet, sync when connected
- **Photo Documentation** - Camera integration for visual progress tracking
- **Real-time Sync** - Instant data synchronization across all devices via Supabase

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Supabase (PostgreSQL, Auth, Realtime) |
| **API** | Cloudflare Workers |
| **Web App** | Next.js 15+ with Cloudflare Pages |
| **Mobile App** | React Native (iOS & Android) |
| **AI Integration** | MCP (Model Context Protocol) |
| **State Management** | Zustand / React Query |
| **Styling** | Tailwind CSS, shadcn/ui |

---

## Getting Started

### Prerequisites

- [Claude Code CLI](https://claude.com/claude-code) installed
- [Beads](https://github.com/steveyegge/beads) for issue tracking
- Supabase account with project set up

### Setup

```bash
# Clone the repository
git clone https://github.com/ronmikailov/site-360.git
cd site360

# Configure environment variables
cp .env.local.example .env.local
# Edit .env.local with your Supabase credentials

# Initialize Beads issue tracking (if not done)
bd onboard

# Start working
bd ready    # View available issues
```

---

## Project Structure

```
site360/
├── .beads/                        # Beads issue tracking state
├── .claude/                       # Claude Code agent configurations
│   ├── agents/                    # Specialized AI agents
│   ├── commands/                  # Custom slash commands
│   ├── skills/                    # Reusable AI skills
│   └── settings.json              # Claude Code settings
├── apps/                          # Application code (planned)
│   ├── mobile/                    # React Native mobile app
│   │   ├── android/               # Android native code
│   │   ├── ios/                   # iOS native code
│   │   └── src/                   # React Native source
│   └── web/                       # Next.js web application
│       ├── app/                   # Next.js app directory
│       ├── components/            # React components
│       └── lib/                   # Utilities and helpers
├── packages/                      # Shared packages (planned)
│   ├── database/                  # Supabase types and utilities
│   ├── ui/                        # Shared UI components
│   └── api/                       # API client and types
├── workers/                       # Cloudflare Workers (planned)
│   └── api/                       # API endpoints
├── claude-code-orchestrator-kit/  # Agent orchestration framework
├── docs/                          # Project documentation
├── .env.local                     # Environment configuration (git-ignored)
├── .mcp.json                      # MCP server configuration
├── AGENTS.md                      # Agent usage guidelines
├── CLAUDE.md                      # AI orchestration instructions
└── README.md                      # This file
```

---

## Documentation

### Project Documentation
- **[Control Parameters](docs/control-parameters.md)** - Comprehensive guide to all 14 control dimensions
- `CLAUDE.md` - AI agent orchestration patterns and workflows
- `AGENTS.md` - Quick reference for Beads issue tracking
- `.claude/commands/` - Available slash commands for development

### Control System Overview

Site360 monitors construction sites across 14 critical dimensions:

| Category | Control Parameters |
|----------|-------------------|
| **Planning & Design** | Planning Control • Design Change Control • Documentation Control |
| **Progress & Materials** | Schedule/Pace Control • Material Control • Loss/Theft Prevention • Quality Control |
| **Workforce & Resources** | Subcontractor Control • Workforce Control • Equipment Control |
| **Safety & Compliance** | Safety Control • Regulatory Compliance • Site Organization Control |
| **Management** | Overall Management Control (Blind Spot Detection) |

See **[Control Parameters Documentation](docs/control-parameters.md)** for detailed information on each dimension.

---

## Development Workflow

This project uses **Claude Code** with the **Orchestrator Kit** for AI-assisted development.

### Issue Tracking with Beads

```bash
bd ready                              # View available work
bd show <id>                          # View issue details
bd update <id> --status in_progress   # Claim an issue
bd close <id>                         # Complete work
bd sync                               # Sync with git
```

### AI-Assisted Development

Available slash commands:

```bash
/health-bugs        # Automated bug detection and fixing
/health-security    # Security vulnerability scanning
/health-cleanup     # Dead code detection and removal
/health-deps        # Dependency audit and updates
/speckit.plan       # Create implementation plans
/speckit.implement  # Execute implementation tasks
/beads-init         # Initialize Beads tracking
```

### MCP Integration

The project is configured with MCP servers for:
- **Supabase** - Database operations and management
- **Context7** - Up-to-date documentation retrieval
- **Sequential Thinking** - Enhanced reasoning capabilities
- **Playwright** - Browser automation for testing

### Application Development

#### Web App (Next.js)
```bash
cd apps/web
pnpm install
pnpm dev              # Start development server on localhost:3000
pnpm build            # Build for production
pnpm type-check       # Run TypeScript checks
```

#### Mobile App (React Native)
```bash
cd apps/mobile
pnpm install

# iOS
pnpm ios              # Run on iOS simulator
pnpm ios:device       # Run on connected iOS device

# Android
pnpm android          # Run on Android emulator
pnpm android:device   # Run on connected Android device
```

#### Shared Packages
```bash
cd packages/database  # Database types and Supabase client
cd packages/ui        # Shared UI components (shadcn/ui)
cd packages/api       # API client and types
```

---

## License

MIT
