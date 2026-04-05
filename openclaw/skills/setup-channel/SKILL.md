---
name: setup-channel
description: Connect a messaging channel to OpenClaw. Supports Telegram, Discord, Slack, WhatsApp, and more. Use when the user wants to chat with their agent via a messaging app.
---

# Setting Up a Messaging Channel

Let's connect your OpenClaw agent to a messaging platform. I'll help you get it working step-by-step.

## Before We Begin

I'll always fetch the latest channel documentation to ensure you have current setup instructions.

*(Fetch and review latest channel docs before proceeding)*

## Choose Your Channel

OpenClaw supports many messaging platforms. Which one would you like to use?

### Supported Channels

- **Telegram** - Fast, lightweight, popular for bots
- **Discord** - Great for communities, rich embeds
- **Slack** - Best for teams, enterprise-ready
- **WhatsApp** - Ubiquitous, good for personal use
- **Signal** - Privacy-focused, encrypted
- **iMessage** - Apple ecosystem integration
- **Matrix** - Decentralized, self-hostable
- **Microsoft Teams** - Enterprise Microsoft environments
- **Feishu/Lark** - Popular in China
- **LINE** - Popular in Asia
- **Zalo** - Popular in Vietnam

I have no bias toward any channel - pick the one that works best for you!

## Channel Setup Guides

### Telegram

**Step 1: Create a Bot**

1. Open Telegram and search for **@BotFather**
2. Send `/newbot` and follow the prompts
3. Choose a name and username for your bot
4. BotFather will give you a token like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

**Step 2: Configure OpenClaw**

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "${TELEGRAM_BOT_TOKEN}"
    }
  }
}
```

**Step 3: Store Token Securely**

```bash
# Add to .env
echo "TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz" >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
```

**Step 4: Test**

```bash
# Restart gateway to apply config
openclaw gateway restart

# Send /start to your bot in Telegram
```

### Discord

**Step 1: Create a Discord Application**

1. Go to https://discord.com/developers/applications
2. Click "New Application" and name it
3. Go to "Bot" → "Add Bot"
4. Copy the token under "TOKEN" (click "Reset Token" if needed)

**Step 2: Configure Bot Permissions**

Under "Privileged Gateway Intents", enable:
- Message Content Intent
- Server Members Intent (if needed)

**Step 3: Configure OpenClaw**

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "${DISCORD_BOT_TOKEN}",
      "clientId": "${DISCORD_CLIENT_ID}",
      "guildId": "${DISCORD_GUILD_ID}"
    }
  }
}
```

**Step 4: Invite Bot to Server**

Use this URL (replace YOUR_CLIENT_ID):
```
https://discord.com/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=8&scope=bot%20applications.commands
```

**Step 5: Test**

```bash
# Restart gateway
openclaw gateway restart

# Send a message in your Discord server
```

### Slack

**Step 1: Create a Slack App**

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name it and select your workspace

**Step 2: Configure OAuth**

1. Go to "OAuth & Permissions"
2. Add these scopes under "Bot Token Scopes":
   - `chat:write`
   - `channels:read`
   - `groups:read`
   - `im:read`
   - `im:write`
   - `app_mentions:read`
3. Install to workspace and copy the "Bot User OAuth Token"

**Step 3: Enable Events**

1. Go to "Event Subscriptions"
2. Enable events
3. Add a request URL (your public URL + `/slack/events`)
4. Subscribe to: `message.channels`, `message.groups`, `message.im`

**Step 4: Configure OpenClaw**

```json
{
  "channels": {
    "slack": {
      "enabled": true,
      "token": "${SLACK_BOT_TOKEN}",
      "signingSecret": "${SLACK_SIGNING_SECRET}"
    }
  }
}
```

**Step 5: Test**

```bash
# Restart gateway
openclaw gateway restart

# Send a message in your Slack workspace
```

### WhatsApp

**Step 1: Set Up Meta Business**

1. Go to https://developers.facebook.com
2. Create a Meta app (Business type)
3. Add "WhatsApp" product

**Step 2: Verify Phone Number**

1. Go to WhatsApp → Configuration
2. Add your phone number
3. Complete verification (SMS/call)

**Step 3: Get Credentials**

1. Copy the "Access Token"
2. Note your "Phone Number ID"
3. Copy the "Webhook Verify Token"

**Step 4: Configure OpenClaw**

```json
{
  "channels": {
    "whatsapp": {
      "enabled": true,
      "accessToken": "${WHATSAPP_ACCESS_TOKEN}",
      "phoneNumbrId": "${WHATSAPP_PHONE_NUMBER_ID}",
      "webhookVerifyToken": "${WHATSAPP_VERIFY_TOKEN}"
    }
  }
}
```

**Step 5: Test**

```bash
# Restart gateway
openclaw gateway restart

# Send a WhatsApp message to your number
```

### Other Channels

For **Signal, iMessage, Matrix, Teams, Feishu, LINE, Zalo**, the setup is similar:

1. Create a bot/application in the platform's developer portal
2. Get credentials (token, API key, webhook URL)
3. Store credentials in `.env`
4. Configure in `openclaw.json`
5. Restart gateway and test

Each platform has specific steps - I'll reference the latest docs for detailed instructions.

## DM Policy and Group Settings

### Direct Message Policy

I recommend starting with **"pairing" mode** - this means you must explicitly approve new DM conversations:

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": {
        "mode": "pairing",
        "pairingCode": "default"
      }
    }
  }
}
```

**How pairing works:**
1. A new user DMs your bot
2. OpenClaw logs the request
3. You approve with: `openclaw approve-DM @username`
4. The user can now chat

To tighten security later, you can switch to **"allowlist"** mode:

```json
{
  "dmPolicy": {
    "mode": "allowlist",
    "allowedUsers": ["@user1", "@user2"]
  }
}
```

### Group Settings

For group chats, you can control how your agent responds:

```json
{
  "channels": {
    "telegram": {
      "groupSettings": {
        "requireMention": true,
        "groupAllowFrom": ["verified_groups"],
        "respondToCommands": true
      }
    }
  }
}
```

- **requireMention**: Only respond when mentioned (@bot)
- **groupAllowFrom**: List of allowed group IDs
- **respondToCommands**: Always respond to /commands

## Test Connectivity

Let's verify your channel is working:

1. **Send a test message** - "Hello OpenClaw!"
2. **Check gateway logs**:
   ```bash
   openclaw logs --follow
   ```
3. **Verify response** - You should get a reply

If it's not working, check the logs for errors and we'll troubleshoot together.

## Next Steps

Your channel is set up! Here are some optional next steps:

1. **Customize the bot** - Change name, avatar, welcome message
2. **Set up commands** - Add custom slash commands
3. **Harden security** - Lock down permissions (use `security-hardening` skill)
4. **Add more channels** - Connect multiple platforms

What would you like to do next?
