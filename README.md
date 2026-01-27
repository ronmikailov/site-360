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

## Core Features

### 🚨 Discrepancy Alerts
Real-time notifications when actual material usage or project progress deviates from approved building plans.

### 📋 Daily Checks
Digital logs for site managers and contractors to record daily activities and material consumption.

### 🔗 MCP Integration
Connection to Model Context Protocol (MCP) servers to pull and analyze building plans and specifications.

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Supabase (PostgreSQL, Auth, Realtime) |
| **Functions** | Cloudflare Workers |
| **Frontend** | Cloudflare Pages |
| **AI Integration** | MCP (Model Context Protocol) |

---

## Getting Started

```bash
# Clone the repository
git clone https://github.com/ronmikailov/site-360.git
cd site-360

# Install dependencies
pnpm install

# Set up environment
cp .env.example .env.local
# Edit .env.local with your credentials

# Start development
pnpm dev
```

---

## Project Structure

```
site360/
├── .claude/          # AI agent configurations
├── .beads/           # Issue tracking
├── docs/             # Documentation
├── CLAUDE.md         # AI orchestration rules
└── README.md         # This file
```

---

## Documentation

See the `docs/` directory for:
- [Vision](docs/vision.md)
- [Features](docs/features.md)
- [Control Parameters](docs/control-parameters.md)
- [Tech Stack](docs/tech-stack.md)

---

## Development

This project uses the **Claude Code Orchestrator Kit** for AI-assisted development:

```bash
/health-bugs      # Find and fix bugs
/health-security  # Security scanning
/speckit.plan     # Create implementation plans
bd ready          # See available issues
```

---

## License

MIT
