# OpenClaw Father - Architecture Overview

## Overview

OpenClaw Father is a reference implementation agent that demonstrates how OpenClaw agents should be structured and deployed. It serves as both:

1. **OpenClaw Agent** - A production-ready agent for the OpenClaw ecosystem
2. **Claude Code Skill** - A reusable skill for the Claude Code editor extension

The agent provides comprehensive guidance for OpenClaw installation, configuration, channel setup, security, and troubleshooting. Its unique "father" personality embodies mentorship, knowledge sharing, and continuous learning.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Knowledge Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  knowledge/  │  │ live-docs/   │  │  lessons/    │          │
│  │  (cached)    │  │  (fetched)   │  │  (learned)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Dual-Format Layer                            │
│  ┌──────────────────────┐    ┌──────────────────────┐          │
│  │   OpenClaw Agent     │    │  Claude Code Skill   │          │
│  │  (openclaw.json)     │    │  (skill package)     │          │
│  └──────────────────────┘    └──────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        Users Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ OpenClaw CLI │  │  ClawHub UI  │  │ Claude Code  │          │
│  │  Terminal    │  │  Web Client  │  │   Editor     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘

Data Flow:
User Message → Gateway → Agent Skill → Knowledge Query → Response Generation → User
```

## Dual-Format Design

### OpenClaw Agent Format
- **Configuration**: `openclaw.json` defines agent metadata, skills, and channels
- **Skills**: 7 agent skills (install, configure, channel-setup, security, health-check, learn-lesson, sync-knowledge)
- **Channels**: Terminal, Slack, Discord, Matrix, WhatsApp
- **Deployment**: Hosted by deployers through OpenClaw gateway

### Claude Code Skill Format
- **Packaging**: Skill definition with instructions and capabilities
- **Integration**: Direct access to Claude Code's editor context
- **Distribution**: Published through skill registry
- **Usage**: Invoked via `/openclaw-father` command in Claude Code

### Key Differences
- **OpenClaw Agent**: Full-featured with multi-channel support, SSH-based deployment
- **Claude Code Skill**: Editor-integrated, single-channel (editor), focused on developer workflow
- **Knowledge Base**: Shared between both formats through `knowledge/` directory

## Knowledge Sharing System

The knowledge/ directory serves as the single source of truth for both formats:

```
knowledge/
├── agent-setup/
│   ├── install-procedure.md
│   └── generate-config.md
├── channels/
│   ├── slack.md
│   ├── discord.md
│   ├── matrix.md
│   └── whatsapp.md
├── security/
│   ├── security-checklist.md
│   └── dm-policy.md
├── providers/
│   └── model-providers.md
├── operations/
│   ├── health-check.md
│   └── troubleshooting.md
└── schemas/
    └── lessons-learned.json
```

**Sync Process**:
1. Author edits files in `knowledge/`
2. CI pipeline validates markdown and JSON schemas
3. Changes are copied to `claude-code/references/` for skill packaging
4. Both formats access the same authoritative knowledge

## Live Documentation Strategy

OpenClaw documentation is updated frequently. To stay current, we use a two-tier system:

### Tier 1: Live Fetch
- Agent fetches latest docs from `docs.openclaw.ai` on demand
- Provides users with most up-to-date information
- Requires internet connection

### Tier 2: Cached Baseline
- `knowledge/` directory contains cached documentation
- Serves as fallback when offline
- Updated weekly via CI workflow

**Version Tracking**:
- `version-tracker.json` tracks last sync timestamp
- Compares local vs remote versions
- Triggers sync when outdated

## Learning System

OpenClaw Father continuously improves through experience accumulation:

### Lessons Learned Storage
- **Location**: `lessons-learned.json` in agent workspace
- **Schema**: Structured format with problem, solution, context tags
- **Deduplication**: Prevents duplicate lessons
- **Privacy**: No sensitive data in lessons

### Learning Workflow
1. Agent encounters new problem or solution
2. User confirms lesson is worth saving
3. Agent extracts structured lesson
4. Deduplication check prevents duplicates
5. Lesson added to `lessons-learned.json`
6. Future queries benefit from accumulated experience

### Privacy Safeguards
- No API keys, tokens, or passwords in lessons
- No IP addresses or hostnames
- Generic context only (e.g., "Ubuntu 22.04 server" not "192.168.1.50")

## Rentable Agent Model

OpenClaw Father can be deployed as a service:

### Deployment Models
1. **ClawHub Registry**: List agent in public registry
2. **npm Package**: Distribute as installable package
3. **Git Clone**: Direct repository deployment

### Service Architecture
```
Deployer's Server
├── OpenClaw Gateway
├── OpenClaw Father Agent
├── Agent Workspace
│   ├── lessons-learned.json (per-tenant)
│   ├── AGENTS.md (custom branding)
│   └── SOUL.md (personality tuning)
└── Channel Connections
    ├── Slack Bot
    ├── Discord Bot
    └── Matrix Bot
```

### Monetization Options
- **Free Agent**: Open-source, community-supported
- **Paid Service**: Deployer offers hosted instance with SLA
- **Premium Features**: Custom integrations, priority support

### Multi-Tenant Isolation
- Each deployment has separate `lessons-learned.json`
- Workspace customization per deployment
- Channel credentials isolated per instance

## Data Flow

### User Interaction Flow

```
1. User sends message through channel
   [User] → "How do I add Slack to OpenClaw?"
       ↓
2. Gateway receives and routes to agent
   [Gateway] → OpenClaw Father
       ↓
3. Agent skill processes request
   [Skill: channel-setup] → Search knowledge/slack.md
       ↓
4. Knowledge retrieval
   [Knowledge Base] → Return Slack setup procedure
       ↓
5. Response generation
   [Agent] → Format response with steps and code blocks
       ↓
6. Response delivered to user
   [Gateway] → [Channel] → [User]
```

### SSH Deployment Flow

```
1. User requests agent setup
   [User] → "Help me deploy OpenClaw Father"
       ↓
2. Agent generates SSH commands
   [Agent] → Generate deployment script
       ↓
3. User executes on target server
   [User Server] → ssh user@host "bash <(curl -s ...)"
       ↓
4. Agent installs and configures
   [Target Server] → Clone repo, install dependencies, configure
       ↓
5. Agent reports success
   [Agent] → "Deployment complete. Gateway ready."
       ↓
6. User starts using agent
   [User] → Connected to new agent instance
```

### Knowledge Sync Flow

```
1. CI trigger (weekly or manual)
   [GitHub Actions] → sync-docs.yml
       ↓
2. Fetch remote documentation
   [CI] → curl docs.openclaw.ai/{pages}
       ↓
3. Update cached knowledge
   [CI] → Write to knowledge/{files}
       ↓
4. Update version tracker
   [CI] → Update version-tracker.json
       ↓
5. Commit changes
   [CI] → git commit && git push
       ↓
6. Agent uses updated knowledge
   [Agent] → Read refreshed knowledge/
```

## Extension Points

### Adding New Skills
1. Create skill definition in `openclaw.json`
2. Implement skill logic in agent code
3. Add knowledge files to `knowledge/`
4. Update skill registry

### Adding New Channels
1. Add channel guide to `knowledge/channels/{channel}.md`
2. Configure channel in `openclaw.json`
3. Set up bot credentials
4. Test channel integration

### Adding New Knowledge
1. Edit files in `knowledge/` directory
2. Follow markdown format
3. Update CI sync configuration
4. Test knowledge retrieval

## Security Architecture

### Credential Management
- API keys stored in environment variables
- Channel tokens in encrypted storage
- SSH keys managed per deployment
- No credentials in code or knowledge files

### Access Control
- DM policy: Pair users with agents by default
- Channel whitelisting for public deployments
- Rate limiting per user
- Audit logging for admin operations

### Data Isolation
- Separate workspaces per deployment
- Lessons learned isolated per tenant
- No cross-tenant data sharing
- User data not persisted to knowledge base
