# OpenClaw Channel Setup Guides

This guide covers configuration for all supported messaging channels where OpenClaw agents can interact.

## Overview Table

| Channel | Setup Complexity | Auth Method | Best For | Limitations |
|---------|-----------------|-------------|----------|-------------|
| **Telegram** | ⭐ Easy | Bot Token | Personal use, groups | Rate limits on bots |
| **Discord** | ⭐⭐ Medium | Bot Token | Communities, servers | Intent requirements |
| **Slack** | ⭐⭐ Medium | OAuth/App Token | Enterprise teams | Socket Mode limits |
| **WhatsApp** | ⭐⭐⭐ Hard | Webhook/OAuth | Business messaging | Meta approval required |
| **Signal** | ⭐⭐ Medium | Phone/Link | Privacy-focused | Limited group support |
| **iMessage** | ⭐⭐⭐ Complex | Apple Script | macOS only | Platform-specific |
| **Matrix** | ⭐⭐ Medium | Access Token | Decentralized comms | Self-hosted |
| **Teams** | ⭐⭐ Medium | Azure App | Enterprise | Microsoft ecosystem |
| **Feishu** | ⭐⭐ Medium | App ID/Secret | China market | Regional availability |
| **Google Chat** | ⭐⭐ Medium | OAuth | Google Workspace | Google ecosystem |
| **Mattermost** | ⭐⭐ Medium | Bot Token | Self-hosted teams | On-premise focus |
| **LINE** | ⭐⭐ Medium | Channel Access | Japan/Asia | Regional restrictions |
| **Zalo** | ⭐⭐⭐ Hard | OAuth/ZOA | Vietnam market | Regional restrictions |

## Telegram

### Setup

1. **Create Bot via BotFather**
   - Open Telegram and search for `@BotFather`
   - Send `/newbot` command
   - Follow prompts to choose a name and username
   - Copy the bot token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

2. **Configure openclaw.json**
   ```json5
   {
     channels: {
       telegram: {
         botToken: "${TELEGRAM_BOT_TOKEN}",  // or paste token directly (not recommended)
         dmPolicy: "pairing",  // "pairing", "allowlist", "open", "disabled"
         allowFrom: [],  // For allowlist mode: ["user_id_1", "user_id_2"]
         groups: {
           enabled: true,
           requireMention: true,  // Bot must be @mentioned in groups
           groupAllowFrom: ["group_id_1", "group_id_2"]  // Empty = all groups
         }
       }
     }
   }
   ```

3. **Set Environment Variable** (Recommended)
   ```bash
   echo 'TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"' >> ~/.openclaw/.env
   chmod 600 ~/.openclaw/.env
   ```

4. **Test Connectivity**
   - Start a DM with your bot on Telegram
   - Send a message like "hello"
   - If `dmPolicy: "pairing"`, you'll receive a pairing code
   - Approve with: `openclaw pairing approve <CODE>`

### Finding User/Group IDs

```bash
# Use OpenClaw's built-in tool after receiving a message
openclaw telegram list-chats  # Shows recent chats with IDs
```

### Common Gotchas

- **Bot doesn't respond**: Check `dmPolicy` setting (default: "pairing" requires approval)
- **Can't mention in groups**: Ensure bot is admin or has permission to send messages
- **Rate limits**: Telegram bots have 30 msgs/sec limit per bot
- **Token expired**: Tokens don't expire, but if regenerated, update config

## Discord

### Setup

1. **Create Discord Application**
   - Go to https://discord.com/developers/applications
   - Click "New Application", choose name
   - Go to "Bot" section, click "Add Bot"
   - Copy bot token (click "Reset Token" if needed)

2. **Configure Intents**
   - In Bot section, enable:
     - **Message Content Intent** (required to read messages)
     - **Server Members Intent** (if needed)
   - Save changes

3. **Invite Bot to Server**
   - Go to "OAuth2" → "URL Generator"
   - Select scopes: `bot`, `applications.commands`
   - Select permissions: Read Messages, Send Messages, Embed Links
   - Use generated URL to invite bot

4. **Configure openclaw.json**
   ```json5
   {
     channels: {
       discord: {
         botToken: "${DISCORD_BOT_TOKEN}",
         dmPolicy: "pairing",
         allowFrom: [],
         guilds: {
           "guild_id_1": {
             channels: {
               "channel_id_1": {
                 requireMention: true,
                 allowedUsers: []
               }
             }
           }
         }
       }
     }
   }
   ```

5. **Set Environment Variable**
   ```bash
   echo 'DISCORD_BOT_TOKEN="your_bot_token_here"' >> ~/.openclaw/.env
   ```

### Finding Guild/Channel IDs

- Enable Developer Mode in Discord (Settings → Advanced → Developer Mode)
- Right-click server/channel → Copy ID

### Common Gotchas

- **Missing messages**: Ensure "Message Content Intent" is enabled
- **Permission errors**: Bot needs "Read Messages" and "Send Messages" in channels
- **Slash commands**: Register with `openclaw discord register-commands`
- **Rate limits**: Discord has strict rate limits, OpenClaw handles retries

## Slack

### Setup

1. **Create Slack App**
   - Go to https://api.slack.com/apps
   - Click "Create New App", choose "From scratch"
   - Enter app name and select workspace

2. **Configure Bot Permissions**
   - Go to "OAuth & Permissions"
   - Add Bot Token Scopes:
     - `chat:write` - Send messages
     - `im:history` - Read DMs
     - `channels:history` - Read public channels
     - `groups:history` - Read private channels
     - `app_mentions:read` - Read mentions
   - Install app to workspace
   - Copy **Bot Token** (starts with `xoxb-`)

3. **Enable Socket Mode** (Recommended)
   - Go to "Socket Mode"
   - Enable Socket Mode
   - Copy **App-Level Token** (starts with `xapp-`)

4. **Configure openclaw.json**
   ```json5
   {
     channels: {
       slack: {
         botToken: "${SLACK_BOT_TOKEN}",
         appToken: "${SLACK_APP_TOKEN}",
         dmPolicy: "pairing",
         allowFrom: [],
         channels: {
           "C1234567890": {  // Channel ID
             requireMention: false
           }
         },
         slashCommands: {
           enabled: true,
           command: "openclaw"
         }
       }
     }
   }
   ```

5. **Set Environment Variables**
   ```bash
   echo 'SLACK_BOT_TOKEN="xoxb-your-token"' >> ~/.openclaw/.env
   echo 'SLACK_APP_TOKEN="xapp-your-token"' >> ~/.openclaw/.env
   ```

### Finding Channel IDs

```bash
# List channels after first message received
openclaw slack list-channels
```

### Socket Mode vs HTTP Mode

- **Socket Mode** (default): OpenClaw connects to Slack, no public endpoint needed
- **HTTP Mode**: Requires public HTTPS endpoint, configure `socketMode: false` and provide `signingSecret`

### Common Gotchas

- **Bot not responding**: Check Socket Mode is enabled and appToken is correct
- **Can't read messages**: Verify bot is invited to channels and has scopes
- **Slash commands not working**: Run `openclaw slack register-commands` after changes

## WhatsApp

### Setup

1. **Meta Business Setup**
   - Go to https://developers.facebook.com/apps
   - Create app, choose "Business" type
   - Add "WhatsApp" product
   - Get phone number from WhatsApp API settings

2. **Configure Webhook**
   - Set webhook URL to your OpenClaw gateway (or use ngrok for testing)
   - Subscribe to `messages` webhook events
   - Verify token in openclaw.json

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       whatsapp: {
         phoneNumber: "1234567890",
         accessToken: "${WHATSAPP_ACCESS_TOKEN}",
         webhookVerifyToken: "random_verify_token",
         dmPolicy: "pairing",
         allowFrom: [],
         businessAccountId: "your_business_account_id"
       }
     }
   }
   ```

4. **Test with Test Message**
   - Use WhatsApp API testing tools
   - Send test message to your WhatsApp number

### Common Gotchas

- **Message templates**: WhatsApp requires pre-approved templates for outbound messages
- **24-hour window**: Can only send free-form messages within 24h of user message
- **Rate limits**: Strict limits, use carefully

## Signal

### Setup

1. **Install Signal CLI**
   ```bash
   # Ubuntu/Debian
   sudo apt install signal-cli

   # macOS
   brew install signal-cli
   ```

2. **Register Phone Number**
   ```bash
   signal-cli -u +1234567890 register
   signal-cli -u +1234567890 verify CODE
   ```

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       signal: {
         phoneNumber: "+1234567890",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Desktop app required**: Signal CLI needs Signal Desktop linked
- **Group support**: Limited compared to other platforms

## iMessage

### Setup

1. **macOS Only**
   - Requires macOS with AppleScript support
   - OpenClaw uses AppleScript to interface with Messages app

2. **Configure openclaw.json**
   ```json5
   {
     channels: {
       imessage: {
         enabled: true,
         requirePairing: true,  // Always recommended
         allowFrom: ["john@example.com", "+1234567890"]
       }
     }
   }
   ```

3. **Grant Permissions**
   - System Settings → Privacy → Automation
   - Allow terminal/Node.js to control Messages

### Common Gotchas

- **Mac required**: Doesn't work on Linux/Windows
- **Apple ID needed**: Must be signed into iMessage
- **Phone numbers**: Use E.164 format (+ country code)

## Matrix

### Setup

1. **Create Matrix Bot Account**
   - Register account on your homeserver (e.g., matrix.org)
   - Note username and password

2. **Get Access Token**
   ```bash
   curl -X POST https://matrix.org/_matrix/client/r0/login \
     -d '{"type":"m.login.password","user":"username","password":"password"}'
   # Copy access_token from response
   ```

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       matrix: {
         homeserverUrl: "https://matrix.org",
         accessToken: "${MATRIX_ACCESS_TOKEN}",
         userId: "@username:matrix.org",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Homeserver differences**: Configuration may vary by homeserver
- **Encryption**: E2EE not supported, use unencrypted rooms

## Microsoft Teams

### Setup

1. **Create Azure Bot**
   - Go to https://portal.azure.com
   - Create "Azure Bot" resource
   - Get Microsoft App ID and secret

2. **Configure Messaging Endpoint**
   - Set endpoint to your OpenClaw gateway
   - Add "Teams" channel to bot

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       teams: {
         appId: "${TEAMS_APP_ID}",
         appSecret: "${TEAMS_APP_SECRET}",
         tenantId: "your_tenant_id",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Azure required**: Need Azure account
- **Approval process**: Bot must be approved for Teams store

## Feishu (Lark Suite)

### Setup

1. **Create Feishu App**
   - Go to https://open.feishu.cn/app
   - Create app, get App ID and App Secret

2. **Enable Bot Capabilities**
   - Enable "Receive Messages" capability
   - Configure event subscription

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       feishu: {
         appId: "${FEISHU_APP_ID}",
         appSecret: "${FEISHU_APP_SECRET}",
         encryptKey: "optional_encryption_key",
         verificationToken: "verify_token",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **China region**: Different API endpoints for China vs international
- **Message formatting**: Markdown support varies

## Google Chat

### Setup

1. **Create Google Cloud Project**
   - Go to https://console.cloud.google.com
   - Create project, enable Google Chat API

2. **Configure Bot**
   - Go to Google Chat API configuration
   - Add bot information
   - Enable "Direct Message"

3. **Deploy as Chat App**
   - Publish bot to Google Workspace Marketplace
   - Or use "Preview" for testing

4. **Configure openclaw.json**
   ```json5
   {
     channels: {
       googlechat: {
         projectId: "your-project-id",
         credentialsPath: "/path/to/service-account.json",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Google Workspace**: Requires Workspace subscription for full features
- **Service account**: Need proper credentials

## Mattermost

### Setup

1. **Create Bot Account**
   - Go to System Console → Integrations → Bot Accounts
   - Create bot, copy access token

2. **Configure openclaw.json**
   ```json5
   {
     channels: {
       mattermost: {
         url: "https://your-mattermost-server.com",
         botToken: "${MATTERMOST_BOT_TOKEN}",
         dmPolicy: "pairing",
         allowFrom: [],
         teams: {
           "team_id": {
             channels: ["channel_id_1", "channel_id_2"]
           }
         }
       }
     }
   }
   ```

### Common Gotchas

- **Self-hosted**: Need own Mattermost instance
- **API version**: Check Mattermost server version compatibility

## LINE

### Setup

1. **Create LINE Channel**
   - Go to https://developers.line.biz
   - Create provider and Messaging API channel
   - Get Channel Access Token

2. **Configure Webhook**
   - Set webhook URL to OpenClaw gateway
   - Verify endpoint

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       line: {
         channelSecret: "${LINE_CHANNEL_SECRET}",
         channelAccessToken: "${LINE_CHANNEL_ACCESS_TOKEN}",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Message types**: LINE has specific message type requirements
- **Rich menus**: Can be configured via LINE console

## Zalo

### Setup

1. **Create Zalo App**
   - Go to https://developers.zalo.me
   - Create app, get App ID and Secret Key

2. **Configure OA**
   - Setup Official Account (OA)
   - Configure webhook

3. **Configure openclaw.json**
   ```json5
   {
     channels: {
       zalo: {
         appId: "${ZALO_APP_ID}",
         secretKey: "${ZALO_SECRET_KEY}",
         accessToken: "${ZALO_ACCESS_TOKEN}",
         dmPolicy: "pairing",
         allowFrom: []
       }
     }
   }
   ```

### Common Gotchas

- **Vietnam market**: Primarily for Vietnamese users
- **OA approval**: Requires Zalo approval for production use

## Testing Channel Connectivity

After configuring any channel:

```bash
# Test gateway status
openclaw gateway status

# Check logs for connection status
tail -f /tmp/openclaw/openclaw.log

# Send test message from channel
# Should see logs showing message received
```

## Common Configuration Patterns

### DM Policy Modes

```json5
// 1. Pairing (default, recommended)
dmPolicy: "pairing"  // Users must pair via one-time code

// 2. Allowlist (locked down)
dmPolicy: "allowlist"
allowFrom: ["user_id_1", "user_id_2"]  // Only these users

// 3. Open (dangerous)
dmPolicy: "open"  // Anyone can DM (not recommended)
allowFrom: ["*"]  // Required for open mode

// 4. Disabled
dmPolicy: "disabled"  // No DMs allowed
```

### Group Configuration

```json5
groups: {
  enabled: true,              // Allow group messages
  requireMention: true,       // Must @mention bot
  groupAllowFrom: [],         // Empty = all groups, or specific IDs
  requireMentionForCommands: true  // Commands also need mention
}
```

### Per-Channel Settings

```json5
// Discord-specific
guilds: {
  "guild_id": {
    channels: {
      "channel_id": {
        requireMention: false,      // Don't need @mention here
        allowedUsers: ["user_id"],  // Empty = all users
        allowCommands: true         // Enable slash commands
      }
    }
  }
}

// Slack-specific
channels: {
  "channel_id": {
    requireMention: false,
    allowedUsers: []
  }
}
```

## Security Best Practices

1. **Never commit tokens**: Use environment variables
2. **Restrict access**: Start with `dmPolicy: "pairing"`
3. **Require mentions**: Always set `requireMention: true` in groups
4. **Monitor logs**: Watch for suspicious activity
5. **Rotate tokens**: Regularly update bot tokens
6. **Limit scope**: Only enable channels you actually use

For complete security guidelines, see [security-checklist.md](./security-checklist.md).

## Troubleshooting Channels

### Bot Not Responding

1. Check logs: `tail -f /tmp/openclaw/openclaw.log`
2. Verify `dmPolicy` setting
3. Test gateway: `openclaw gateway status`
4. Check bot token is correct
5. Verify bot has necessary permissions

### Webhook Failures

1. Verify endpoint is reachable (use ngrok for testing)
2. Check firewall allows inbound traffic
3. Verify webhook secret/token matches

### Rate Limiting

1. Reduce message frequency
2. Implement queuing for bulk operations
3. Check platform-specific limits

## Next Steps

After channel setup:
1. Configure DM policy and security
2. Test connectivity
3. Set up agents to respond to messages
4. Monitor logs for issues
