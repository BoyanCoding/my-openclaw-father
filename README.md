# OpenClaw Father

A friendly expert agent that helps you install and configure [OpenClaw](https://openclaw.ai) AI assistants on remote servers. Available as both an **OpenClaw agent** (chat via Telegram/Discord/web) and a **Claude Code skill** (use locally).

## What It Does

- **Installs OpenClaw** on remote servers via SSH (curl, npm, or Docker)
- **Configures model providers** (Anthropic, OpenAI, Google, Mistral, local/Ollama)
- **Sets up messaging channels** (Telegram, Discord, Slack, WhatsApp, and 10+ more)
- **Hardens security** (gateway auth, DM policies, file permissions, tool restrictions)
- **Diagnoses issues** (health checks, log analysis, config validation)
- **Learns from experience** (accumulates lessons from each installation)

## Quick Start

### As a Claude Code Skill

1. Clone this repo:
```bash
git clone https://github.com/boyanpc/my-openclaw-father.git
```

2. Install as a Claude Code plugin:
```bash
claude install-plugin ./my-openclaw-father/claude-code
```

3. Ask Claude to help:
```
"Install OpenClaw on my server at 192.168.1.100 via SSH"
```

### As an OpenClaw Agent

1. Clone this repo into your OpenClaw workspace:
```bash
git clone https://github.com/boyanpc/my-openclaw-father.git ~/.openclaw/workspace/my-openclaw-father
```

2. Add the agent to your `openclaw.json`:
```json5
{
  agents: {
    list: [{
      id: "openclaw-father",
      name: "OpenClaw Father",
      default: true,
      workspace: "~/.openclaw/workspace/my-openclaw-father/openclaw"
    }]
  }
}
```

3. Copy the workspace files:
```bash
cp -r my-openclaw-father/openclaw/* ~/.openclaw/workspace/
```

4. Restart your gateway:
```bash
openclaw gateway restart
```

5. Chat with the agent via your preferred channel.

## Architecture

```
my-openclaw-father/
├── knowledge/        Shared knowledge base (cached docs)
├── openclaw/         OpenClaw agent definition
│   ├── AGENTS.md     Agent routing
│   ├── SOUL.md       Personality
│   ├── IDENTITY.md   Who the agent is
│   ├── TOOLS.md      Tool policies
│   ├── skills/       7 agent skills
│   └── templates/    Config templates
├── claude-code/      Claude Code skill
│   ├── SKILL.md      Main skill definition
│   ├── references/   Knowledge copies
│   └── scripts/      Helper scripts
├── scripts/          Shared installation & sync scripts
├── evals/            Evaluation scenarios
└── docs/             Documentation
```

### Live Knowledge System

OpenClaw updates daily, so this agent uses a **two-tier knowledge system**:

1. **Live (Tier 1):** Fetches docs.openclaw.ai on demand — always current
2. **Cached (Tier 2):** Local `knowledge/` files — baseline fallback + offline use

A weekly CI workflow detects doc changes and opens PRs to keep cached knowledge fresh.

### Dual Format

| Feature | OpenClaw Agent | Claude Code Skill |
|---------|---------------|-------------------|
| How users interact | Telegram, Discord, web chat | CLI prompt |
| How it SSHes | Uses OpenClaw's `exec` tool | Uses Claude Code's `Bash` tool |
| How it learns | OpenClaw's memory system | Project memory files |
| Knowledge source | Same `knowledge/` folder | Same `knowledge/` folder (via references/) |

## Agent Skills

| Skill | Purpose |
|-------|---------|
| `install-openclaw` | Install OpenClaw via curl, npm, or Docker |
| `configure-server` | Set up model providers, gateway, daemon |
| `setup-channel` | Connect Telegram, Discord, Slack, WhatsApp, etc. |
| `security-hardening` | DM policies, auth, permissions, audit |
| `health-check` | Diagnose and fix issues |
| `learn-lesson` | Accumulate experience from each session |
| `sync-knowledge` | Fetch latest OpenClaw docs |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/install-openclaw.sh` | Remote installation via SSH |
| `scripts/generate-config.sh` | Generate openclaw.json from parameters |
| `scripts/health-check.sh` | Run diagnostics on a remote server |
| `scripts/sync-openclaw-docs.sh` | Fetch latest docs from docs.openclaw.ai |

## Example Session

```
User: Install me a new OpenClaw agent at 100.125.199.68 via SSH with user admin

Agent: Great! I'd love to help you set up OpenClaw on your server.
       Let me check a few things first:

       1. What SSH port should I use? (default: 22)
       2. Do you have a preference for the install method?
          - curl (recommended, fastest)
          - npm (if you manage Node yourself)
          - Docker (for isolated deployment)

User: Port 22, curl is fine

Agent: Perfect! Let me check the latest installation docs and
       verify SSH connectivity to your server...

       [fetches docs.openclaw.ai/install]
       [tests SSH: ssh -o ConnectTimeout=10 -p 22 admin@100.125.199.68 "echo ok"]
       Connected! Running Ubuntu 22.04 with 12GB free disk space.

       I'll run this command on your server:
       curl -fsSL https://openclaw.ai/install.sh | bash

       This will install Node.js (if needed) and OpenClaw.
       Shall I proceed?
```

## Development

```bash
# Clone
git clone https://github.com/boyanpc/my-openclaw-father.git
cd my-openclaw-father

# Validate JSON
python3 -c "import json; json.load(open('knowledge/lessons-learned.json'))"

# Check shell scripts
bash -n scripts/*.sh

# Update cached docs
./scripts/sync-openclaw-docs.sh --dry-run
```

## Contributing

See [CONTRIBUTING.md](docs/contributing.md) for guidelines. Key points:

- Knowledge lives in `knowledge/` — edit there, CI syncs to `claude-code/references/`
- Skills are SKILL.md files with YAML frontmatter
- Lessons learned go in `knowledge/lessons-learned.json`
- All PRs must pass CI (lint, validate, sync check)

## License

MIT — see [LICENSE](LICENSE).
