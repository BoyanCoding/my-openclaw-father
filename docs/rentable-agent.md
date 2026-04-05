# Rentable Agent Deployment Model

## What "Rentable Agent" Means

OpenClaw Father is designed to be deployed as a **rentable agent** - a service that deployers can offer to users who need help with OpenClaw installation and configuration, without requiring those users to run their own agent.

**Key Characteristics**:
- **Deployed by service providers**: Hosted on servers maintained by individuals or organizations
- **Accessed by users**: Users connect to the agent through various channels
- **Multi-tenant**: Single deployment serves multiple users
- **Isolated experience**: Each user gets personalized lessons and context
- **Monetizable**: Deployers can offer the service for free or as a paid offering

## Deployment Options

### Option 1: ClawHub Registry

List your agent in the public ClawHub registry:

```json
{
  "name": "openclaw-father",
  "version": "0.1.0",
  "description": "Mentor agent for OpenClaw installation and configuration",
  "author": "Your Name",
  "repository": "https://github.com/yourusername/openclaw-father",
  "homepage": "https://github.com/yourusername/openclaw-father#readme",
  "license": "MIT",
  "channels": ["terminal", "slack", "discord", "matrix", "whatsapp"],
  "pricing": {
    "type": "free",
    "notes": "Open-source, community-supported"
  },
  "hosting": {
    "type": "self-hosted",
    "requirements": {
      "os": ["linux", "macos"],
      "node": ">=18.0.0",
      "memory": "512MB",
      "disk": "100MB"
    }
  }
}
```

**Benefits**:
- Discoverable by users searching for agents
- Automatic updates from registry
- Community trust and verification

### Option 2: npm Package

Distribute as an installable npm package:

```bash
# Users install via npm
npm install -g openclaw-father

# Or as a local dependency
npm install openclaw-father
```

**package.json**:
```json
{
  "name": "openclaw-father",
  "version": "0.1.0",
  "description": "OpenClaw mentor agent for installation and configuration",
  "main": "agent/index.js",
  "bin": {
    "openclaw-father": "bin/openclaw-father.js"
  },
  "scripts": {
    "start": "node agent/index.js",
    "test": "jest",
    "health-check": "./scripts/health-check.sh"
  },
  "keywords": [
    "openclaw",
    "agent",
    "mentor",
    "installation",
    "configuration"
  ],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "@anthropic-ai/sdk": "^0.27.0",
    "openclaw-sdk": "^1.0.0"
  }
}
```

**Benefits**:
- Easy installation for users
- Version management via npm
- Automatic dependency resolution

### Option 3: Git Clone

Direct repository deployment:

```bash
# Clone the repository
git clone https://github.com/yourusername/openclaw-father.git
cd openclaw-father

# Install dependencies
npm install

# Configure and start
cp openclaw.json.example openclaw.json
# Edit openclaw.json with your settings
npm start
```

**Benefits**:
- Full control over configuration
- Can fork and customize
- No registry dependency

## Step-by-Step Deployment Guide

### Step 1: Clone Repository

```bash
# Clone the agent repository
git clone https://github.com/yourusername/openclaw-father.git
cd openclaw-father

# Or deploy via SSH on remote server
ssh user@yourserver.com
git clone https://github.com/yourusername/openclaw-father.git
cd openclaw-father
```

### Step 2: Configure openclaw.json

Create your agent configuration:

```json
{
  "agentName": "OpenClaw Father",
  "agentId": "openclaw-father",
  "version": "0.1.0",
  "description": "Your mentor for OpenClaw installation and configuration",
  "persona": "father",
  "skills": [
    "install",
    "configure",
    "channel-setup",
    "security",
    "health-check",
    "learn-lesson",
    "sync-knowledge"
  ],
  "channels": {
    "terminal": {
      "enabled": true
    },
    "slack": {
      "enabled": true,
      "botToken": "${SLACK_BOT_TOKEN}",
      "signingSecret": "${SLACK_SIGNING_SECRET}"
    },
    "discord": {
      "enabled": true,
      "botToken": "${DISCORD_BOT_TOKEN}"
    }
  },
  "knowledge": {
    "path": "./knowledge",
    "syncOnStartup": true
  },
  "workspace": {
    "path": "./workspace",
    "lessonsFile": "lessons-learned.json"
  },
  "api": {
    "provider": "anthropic",
    "apiKey": "${ANTHROPIC_API_KEY}",
    "model": "claude-3-5-sonnet-20241022"
  }
}
```

### Step 3: Set Up Workspace Files

Create the agent workspace with essential files:

**AGENTS.md** (Team Context):
```markdown
# OpenClaw Father

You are OpenClaw Father, a mentor agent for OpenClaw installation and configuration.

## Your Purpose
Help users successfully install, configure, and troubleshoot OpenClaw agents.

## Your Personality
- Patient and supportive like a wise mentor
- Encourages learning and independence
- Shares lessons learned from experience
- Asks questions to understand user's environment

## Your Capabilities
- Guide users through OpenClaw installation
- Explain configuration options
- Help set up communication channels
- Review security configurations
- Troubleshoot common issues
- Learn from interactions to improve future help

## Your Knowledge Base
You have access to comprehensive documentation about:
- OpenClaw installation procedures
- Channel configuration (Slack, Discord, Matrix, WhatsApp)
- Security best practices
- Model provider setup
- Common troubleshooting scenarios
```

**SOUL.md** (Agent Personality):
```markdown
# OpenClaw Father's Soul

## Core Identity
I am OpenClaw Father, a nurturing mentor dedicated to helping users succeed with OpenClaw.

## Values
- Empowerment: Help users help themselves
- Patience: Everyone starts somewhere
- Continuous Learning: Every interaction teaches me something
- Community: We're all in this together

## Communication Style
- Warm and encouraging tone
- Clear, step-by-step guidance
- Asks clarifying questions before providing solutions
- Celebrates user successes
- Admits when uncertain and seeks additional context

## Approach to Problems
1. Understand the user's context and constraints
2. Draw on accumulated experience (lessons learned)
3. Provide clear, actionable steps
4. Verify understanding before moving forward
5. Document what we learned for next time

## Boundaries
- I don't execute commands on user systems
- I don't store sensitive information
- I encourage users to verify my suggestions
- I recommend official OpenClaw docs as the ultimate authority
```

**workspace/lessons-learned.json** (Experience Storage):
```json
{
  "$schema": "../knowledge/schemas/lessons-learned.json",
  "version": "1.0",
  "deploymentId": "your-deployment-unique-id",
  "lessons": []
}
```

### Step 4: Configure Channels for User Access

**Slack Setup**:
```bash
# Create Slack app at https://api.slack.com/apps
# Add bot permissions:
# - channels:read
# - channels:history
# - chat:write
# - groups:read
# - groups:history
# - im:read
# - im:history
# - mpim:read
# - mpim:history

# Install app to workspace
# Copy Bot User OAuth Token
export SLACK_BOT_TOKEN="xoxb-your-token-here"
export SLACK_SIGNING_SECRET="your-signing-secret-here"
```

**Discord Setup**:
```bash
# Create Discord application at https://discord.com/developers/applications
# Create bot user
# Copy bot token
export DISCORD_BOT_TOKEN="your-bot-token-here"
```

**Matrix Setup**:
```bash
# Create Matrix bot account
# Get access token
export MATRIX_HOMESERVER="https://matrix.org"
export MATRIX_ACCESS_TOKEN="your-access-token"
export MATRIX_USER_ID="@yourbot:matrix.org"
```

### Step 5: Set DM Policy

Configure direct message policy for user interactions:

```json
{
  "dmPolicy": {
    "mode": "pairing",
    "autoPair": true,
    "maxConcurrentUsers": 100,
    "userTimeout": 30,
    "messageRetentionDays": 7
  }
}
```

**Policy Options**:
- **pairing**: Users must pair with the agent (recommended)
- **open**: Anyone can message directly (use with caution)
- **approval**: Admin approval required for new users

### Step 6: Start the Gateway

```bash
# Install dependencies
npm install

# Start the agent
npm start

# Or use PM2 for process management
pm2 start agent/index.js --name openclaw-father
pm2 save
pm2 startup
```

**Systemd Service** (alternative to PM2):
```ini
# /etc/systemd/system/openclaw-father.service
[Unit]
Description=OpenClaw Father Agent
After=network.target

[Service]
Type=simple
User=openclaw
WorkingDirectory=/opt/openclaw-father
ExecStart=/usr/bin/node /opt/openclaw-father/agent/index.js
Restart=always
RestartSec=10
Environment=ANTHROPIC_API_KEY=your-key-here
Environment=SLACK_BOT_TOKEN=your-token-here

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable openclaw-father
sudo systemctl start openclaw-father
sudo systemctl status openclaw-father
```

## Monetization Model

### Free Agent, Paid Service

**Open-Source Agent**:
- Agent code is free and open-source (MIT license)
- Anyone can deploy their own instance
- Community contributes improvements

**Paid Service Options**:
1. **Hosted Instance**: You host and maintain the agent for users
2. **Priority Support**: Faster response times for paid subscribers
3. **Custom Integrations**: Tailored channel or workflow integrations
4. **SLA Guarantee**: Uptime and response time guarantees
5. **Advanced Features**: Analytics, custom branding, white-labeling

### Pricing Examples

**Tier 1: Community (Free)**
- Access to public agent instance
- Community support
- Best-effort availability
- Standard response times

**Tier 2: Professional ($10/month)**
- Dedicated instance
- Priority support
- 99.9% uptime SLA
- < 5 minute response time
- Custom branding

**Tier 3: Enterprise ($50/month)**
- Private deployment
- 24/7 support
- 99.99% uptime SLA
- < 1 minute response time
- Custom integrations
- Analytics dashboard
- White-label options

### Payment Processing

Integrate payment processing for paid tiers:

```javascript
// Example: Stripe integration
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/subscribe', async (req, res) => {
  const { email, paymentMethodId, tier } = req.body;
  
  const customer = await stripe.customers.create({
    email,
    payment_method: paymentMethodId,
    invoice_settings: {
      default_payment_method: paymentMethodId,
    },
  });
  
  const subscription = await stripe.subscriptions.create({
    customer: customer.id,
    items: [{ price: getPriceId(tier) }],
  });
  
  // Provision agent instance
  await provisionAgentInstance(customer.id, tier);
  
  res.json({ subscriptionId: subscription.id });
});
```

## Multi-Tenant Architecture

### Isolation Strategy

Each tenant (user or organization) gets isolated experience:

```
Deployment Root
├── workspace/
│   ├── tenant-abc123/
│   │   ├── lessons-learned.json
│   │   ├── AGENTS.md (custom)
│   │   └── SOUL.md (custom)
│   ├── tenant-def456/
│   │   ├── lessons-learned.json
│   │   └── ...
│   └── shared/
│       └── knowledge/ (read-only)
```

**Tenant Identification**:
```javascript
function getTenantId(userId) {
  // Extract tenant from user ID
  // Could be org ID, customer ID, etc.
  return userId.split('-')[0];
}

function getTenantWorkspace(tenantId) {
  return path.join('./workspace', tenantId);
}
```

**Lessons Isolation**:
```javascript
async function addLesson(tenantId, lesson) {
  const workspace = getTenantWorkspace(tenantId);
  const lessonsFile = path.join(workspace, 'lessons-learned.json');
  
  const lessons = JSON.parse(await fs.readFile(lessonsFile));
  lessons.lessons.push(lesson);
  
  await fs.writeFile(lessonsFile, JSON.stringify(lessons, null, 2));
}
```

## Customization

### Branding

Customize agent appearance for your deployment:

**Custom AGENTS.md**:
```markdown
# MyCompany OpenClaw Assistant

You are the MyCompany OpenClaw Assistant, helping our team with OpenClaw setup.

## Your Context
- You support MyCompany's development team
- We use Ubuntu 22.04 servers
- Our preferred channels are Slack and Discord
- We prioritize security and compliance

## Custom Procedures
- Follow MyCompany's security guidelines
- Use our internal ticketing system for issues
- Document everything in our internal wiki
```

**Custom SOUL.md**:
```markdown
# MyCompany Assistant's Soul

## Identity
I am the MyCompany OpenClaw Assistant, dedicated to our team's success.

## Company Values
- Security first
- Documentation is key
- Help teammates learn
- Continuous improvement
```

### Channel Customization

Configure channels to match your brand:

**Slack Bot Customization**:
```javascript
const slackApp = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  customConfig: {
    botDisplayName: 'MyCompany OpenClaw',
    botIconUrl: 'https://mycompany.com/bot-icon.png'
  }
});
```

**Discord Bot Customization**:
```javascript
const discordClient = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages]
});

discordClient.once('ready', () => {
  discordClient.user.setActivity('OpenClaw Support', { type: ActivityType.Watching });
  discordClient.user.setUsername('MyCompany OpenClaw');
});
```

## Security Considerations for Public-Facing Agents

### Authentication and Authorization

**User Verification**:
```javascript
async function verifyUser(userId) {
  // Check if user is authorized
  const authorizedUsers = await getAuthorizedUsers();
  return authorizedUsers.includes(userId);
}

async function checkRateLimit(userId) {
  // Implement rate limiting
  const requests = await getUserRequests(userId, timeWindow);
  return requests <= MAX_REQUESTS_PER_WINDOW;
}
```

**DM Policy Enforcement**:
```javascript
async function handleDirectMessage(userId, message) {
  if (dmPolicy.mode === 'pairing') {
    const isPaired = await checkPairedUser(userId);
    if (!isPaired) {
      return 'Please pair with this agent first. Use /pair command.';
    }
  }
  
  if (dmPolicy.mode === 'approval') {
    const isApproved = await checkApprovedUser(userId);
    if (!isApproved) {
      return 'Your access request is pending approval.';
    }
  }
  
  // Process message
  return await processMessage(userId, message);
}
```

### Data Privacy

**No Sensitive Data Storage**:
```javascript
function sanitizeLesson(lesson) {
  // Remove sensitive information
  const sanitized = {
    problem: removeSensitive(lesson.problem),
    solution: removeSensitive(lesson.solution),
    context: {
      platform: lesson.context.platform,
      // Remove hostnames, IPs, etc.
    },
    tags: lesson.tags
  };
  
  return sanitized;
}

function removeSensitive(text) {
  return text
    .replace(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g, '[IP]')
    .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL]')
    .replace(/token_[\w-]+/g, '[TOKEN]')
    .replace(/api[_-]?key[\s=:][\w-]+/gi, '[API_KEY]');
}
```

**Message Retention Policy**:
```javascript
async function cleanupOldMessages() {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - messageRetentionDays);
  
  await MessageHistory.deleteMany({
    timestamp: { $lt: cutoffDate }
  });
}
```

### Input Validation

**Sanitize User Input**:
```javascript
function sanitizeInput(input) {
  // Remove potentially dangerous content
  return input
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/javascript:/gi, '')
    .replace(/on\w+\s*=/gi, '');
}
```

**Command Injection Prevention**:
```javascript
function safeExecuteCommand(command) {
  // Whitelist allowed commands
  const allowedCommands = ['health-check', 'sync-knowledge', 'status'];
  
  if (!allowedCommands.includes(command)) {
    throw new Error('Command not allowed');
  }
  
  // Execute command safely
  return executeCommand(command);
}
```

### Access Control

**Role-Based Access**:
```javascript
const roles = {
  admin: ['*'],
  user: ['install', 'configure', 'channel-setup', 'security'],
  readonly: ['health-check']
};

function checkPermission(userId, skill) {
  const userRole = getUserRole(userId);
  const allowedSkills = roles[userRole];
  
  return allowedSkills.includes('*') || allowedSkills.includes(skill);
}
```

## Monitoring and Maintenance

### Health Monitoring

```bash
# Health check script
#!/bin/bash
# scripts/health-check.sh

echo "Checking OpenClaw Father agent status..."

# Check if process is running
if pgrep -f "node.*agent/index.js" > /dev/null; then
  echo "✓ Agent process is running"
else
  echo "✗ Agent process is not running"
  exit 1
fi

# Check API connectivity
if curl -s -f https://api.anthropic.com/v1/models > /dev/null; then
  echo "✓ API is reachable"
else
  echo "✗ API is not reachable"
  exit 1
fi

# Check disk space
usage=$(df -h /opt/openclaw-father | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $usage -lt 90 ]; then
  echo "✓ Disk space is OK (${usage}% used)"
else
  echo "✗ Disk space is low (${usage}% used)"
  exit 1
fi

echo "All checks passed!"
```

### Logging

```javascript
// Configure logging
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}
```

### Analytics

```javascript
// Track usage patterns (without PII)
async function trackUsage(tenantId, skill, success) {
  await Analytics.create({
    tenantId: hashTenantId(tenantId), // Hash for privacy
    skill,
    success,
    timestamp: new Date()
  });
}

// Generate weekly report
async function generateWeeklyReport() {
  const stats = await Analytics.aggregate([
    { $match: { timestamp: { $gte: weekAgo } } },
    { $group: { _id: '$skill', count: { $sum: 1 } } }
  ]);
  
  logger.info('Weekly usage stats:', stats);
}
```

## Best Practices

1. **Start Small**: Deploy to a single channel first, expand gradually
2. **Monitor Closely**: Set up alerts for errors and unusual activity
3. **Iterate**: Gather user feedback and improve continuously
4. **Document**: Keep deployment docs up to date
5. **Test**: Test changes in staging before production
6. **Backup**: Regular backups of workspace and lessons
7. **Update**: Keep dependencies and knowledge base current
8. **Secure**: Regular security audits and updates
