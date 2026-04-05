# OpenClaw Channel Test Scenarios

This document defines test scenarios for OpenClaw channel configuration. Each scenario specifies a channel setup request, expected agent behavior, and verification criteria.

## Scenario 1: Set Up Telegram from Scratch

**User Prompt:** "Set up Telegram for my OpenClaw"

**Expected Agent Behavior:**

**Phase 1: Bot Creation Guidance**
1. Instruct user to create Telegram bot:
   - Open Telegram, search for @BotFather
   - Send `/newbot` command
   - Follow prompts to name the bot and get the token
   - Remind user to keep token secure

**Phase 2: Channel Configuration**
2. Create or update `openclaw.yaml`:
   ```yaml
   channels:
     telegram:
       type: telegram
       enabled: true
       botToken: "${TELEGRAM_BOT_TOKEN}"
       webhookUrl: "https://your-domain.com/webhook/telegram"  # optional
       polling: true  # default for simple setups
       allowedUsers:
         - type: "id"
           value: "123456789"
           label: "Admin"
       commands:
         - command: "/start"
           description: "Start interacting with OpenClaw"
           handler: "default"
       settings:
         timeout: 30
         maxRetries: 3
   ```

**Phase 3: Environment Setup**
3. Prompt for bot token (secure input)
4. Set environment variable or update config securely
5. Get user's Telegram ID (instruct to message @userinfobot)
6. Add user to allowedUsers

**Phase 4: Verification**
7. Start OpenClaw service
8. Test bot with `/start` command
9. Verify bot responds

**Key Checks:**
- [ ] User receives clear BotFather instructions
- [ ] Bot token collected securely (not echoed)
- [ ] Configuration has correct Telegram channel structure
- [ ] Bot token stored in env var or secure location
- [ ] User ID obtained and added to allowedUsers
- [ ] Service starts without errors
- [ ] Bot responds to `/start` command
- [ ] Bot messages are routed to AI provider
- [ ] User can have a conversation through the bot

**Edge Cases to Test:**
- Invalid bot token
- Bot token with restricted permissions
- Webhook setup (requires HTTPS/domain)
- Multiple allowed users
- Group chat configuration
- Bot in production channel

---

## Scenario 2: Add Discord to Existing Telegram Setup

**User Prompt:** "Add Discord to my existing Telegram setup"

**Expected Agent Behavior:**
1. Read existing configuration
2. Identify current Telegram channel setup
3. Guide user through Discord bot creation:
   - Go to Discord Developer Portal
   - Create application
   - Create bot user
   - Get bot token
   - Enable required intents (Message Content, Server Members)
4. Generate OAuth2 URL for bot invitation
5. Add Discord channel to config:
   ```yaml
   channels:
     telegram:
       # ... existing config preserved ...
     discord:
       type: discord
       enabled: true
       botToken: "${DISCORD_BOT_TOKEN}"
       clientId: "${DISCORD_CLIENT_ID}"
       clientSecret: "${DISCORD_CLIENT_SECRET}"
       allowedUsers:
         - type: "id"
           value: "discord_user_id"
           label: "Admin"
       commands:
         - command: "!openclaw"
           description: "Interact with OpenClaw"
       settings:
         presence:
           status: "online"
           activity: "AI Assistant"
   ```
6. Test both channels independently
7. Test concurrent usage

**Key Checks:**
- [ ] Existing Telegram config preserved unchanged
- [ ] Discord Developer Portal instructions are clear
- [ ] Bot token and client credentials collected
- [ ] Required intents enabled
- [ ] OAuth2 invite URL generated correctly
- [ ] Discord channel configuration is valid
- [ ] Both channels work independently
- [ ] Both channels can be used simultaneously
- [ ] No conflicts between channels

**Edge Cases to Test:**
- Missing Discord intents
- Bot without guild permissions
- Different command prefixes for different channels
- Channel-specific configurations
- Rate limiting per channel

---

## Scenario 3: Switch Telegram from Polling to Webhook

**User Prompt:** "Switch my Telegram bot to use webhook instead of polling"

**Expected Agent Behavior:**
1. Check current Telegram configuration (polling mode)
2. Check if HTTPS domain is available
3. If no domain, offer options:
   - Use ngrok/cloudflare tunnel for testing
   - Help set up domain
4. Update configuration:
   ```yaml
   channels:
     telegram:
       type: telegram
       enabled: true
       botToken: "${TELEGRAM_BOT_TOKEN}"
       webhookUrl: "https://your-domain.com/webhook/telegram"
       webhook:
         maxConnections: 40
         allowedUpdates: ["message", "callback_query"]
         dropPendingUpdates: false
       polling: false  # Disable polling
       # ... rest of config
   ```
5. Set up webhook endpoint in OpenClaw
6. Register webhook with Telegram API:
   ```bash
   curl -X POST "https://api.telegram.org/bot<token>/setWebhook" \
     -d "url=https://your-domain.com/webhook/telegram"
   ```
7. Verify webhook is set
8. Test bot response through webhook

**Key Checks:**
- [ ] Current polling mode detected
- [ ] HTTPS domain availability verified
- [ ] Webhook URL is properly formatted
- [ ] Webhook configuration includes all required settings
- [ ] Polling is explicitly disabled
- [ ] Webhook endpoint is configured in OpenClaw
- [ ] Telegram API confirms webhook is set
- [ ] Bot responds faster than polling
- [ ] Webhook receives updates correctly

**Edge Cases to Test:**
- Self-signed certificate (requires certificate upload)
- Domain behind proxy/Cloudflare
- Webhook already set by another service
- Switching back to polling
- Webhook URL changes

---

## Scenario 4: Configure Slack with OAuth

**User Prompt:** "Set up Slack with OAuth authentication"

**Expected Agent Behavior:**
1. Guide user through Slack app creation:
   - Go to api.slack.com/apps
   - Create new app (From scratch)
   - Configure OAuth & Permissions
   - Set Redirect URL
   - Select scopes (chat:write, channels:read, etc.)
   - Install app to workspace
2. Collect credentials:
   - Client ID
   - Client Secret
   - Signing Secret (for verification)
   - Bot Token (xoxb-...)
3. Configure channel:
   ```yaml
   channels:
     slack:
       type: slack
       enabled: true
       oauth:
         clientId: "${SLACK_CLIENT_ID}"
         clientSecret: "${SLACK_CLIENT_SECRET}"
         signingSecret: "${SLACK_SIGNING_SECRET}"
         redirectUri: "https://your-domain.com/slack/callback"
       botToken: "${SLACK_BOT_TOKEN}"
       allowedChannels:
         - type: "id"
           value: "C1234567890"
           label: "general"
       settings:
         app_mention: true
         DM: true
         workspace: "T1234567890"
   ```
4. Set up OAuth callback endpoint
5. Verify bot installation
6. Test in a Slack channel

**Key Checks:**
- [ ] Slack app creation instructions are complete
- [ ] All OAuth credentials collected
- [ ] OAuth scopes are correctly specified
- [ ] Redirect URL matches Slack configuration
- [ ] Signing secret configured for request verification
- [ ] Bot token has correct permissions
- [ ] Allowed channels configured
- [ ] Bot responds to mentions and DMs
- [ ] OAuth flow completes successfully

**Edge Cases to Test:**
- Bot without required scopes
- Workspace admin approval required
- Enterprise grid (multiple workspaces)
- Limited channel permissions
- Bot rate limits

---

## Scenario 5: Multi-Channel Setup (Telegram + Discord + Slack)

**User Prompt:** "Set up OpenClaw to work on Telegram, Discord, and Slack simultaneously"

**Expected Agent Behavior:**
1. Check for existing channels
2. Guide through setup for each channel (can do in parallel)
3. Create unified configuration:
   ```yaml
   channels:
     telegram:
       type: telegram
       enabled: true
       botToken: "${TELEGRAM_BOT_TOKEN}"
       polling: true
       allowedUsers:
         - type: "id"
           value: "123456789"
           label: "Admin"
     discord:
       type: discord
       enabled: true
       botToken: "${DISCORD_BOT_TOKEN}"
       clientId: "${DISCORD_CLIENT_ID}"
       allowedUsers:
         - type: "id"
           value: "discord_user_id"
           label: "Admin"
     slack:
       type: slack
       enabled: true
       botToken: "${SLACK_BOT_TOKEN}"
       signingSecret: "${SLACK_SIGNING_SECRET}"
       allowedChannels:
         - type: "id"
           value: "C1234567890"
           label: "general"
   ```
4. Configure shared settings:
   ```yaml
   routing:
     channelStrategy: "round-robin"  # or "priority", "load-balanced"
     fallbackChannel: "telegram"
     maxConcurrency: 10
   ```
5. Set up all channels
6. Test each channel independently
7. Test concurrent usage across all channels
8. Verify message routing

**Key Checks:**
- [ ] All three channels configured correctly
- [ ] No configuration conflicts between channels
- [ ] Each channel works independently
- [ ] All channels can be used simultaneously
- [ ] Message routing is consistent
- [ ] No message loss under load
- [ ] User identities are consistent across channels
- [ ] Rate limiting works per channel
- [ ] Fallback channel works if one fails

**Edge Cases to Test:**
- Same user on multiple channels
- One channel goes down during multi-channel usage
- Different command formats per channel
- Channel-specific configurations
- Message ordering across channels
- Rate limiting across channels

---

## Testing Notes

**Prerequisites:**
- Valid bot tokens for each platform (or test endpoints)
- Test accounts on Telegram, Discord, Slack
- Ability to create apps and bots
- HTTPS domain for webhook testing
- Test channels/servers for each platform

**Mocking Strategy:**
- Use platform-specific test APIs
- Mock webhook endpoints for local testing
- Use ngrok for local webhook development
- Create test bots that don't affect production

**Common Issues to Test:**
- Invalid or expired tokens
- Missing permissions/scopes
- Rate limiting from platforms
- Webhook failures and retries
- Concurrent message handling
- Message format differences between platforms
- Special characters and encoding

**Success Criteria:**
- All channels connect successfully
- Messages flow bidirectionally
- Commands work on all channels
- Multi-channel setup is stable
- Configuration validates
- No resource leaks or memory issues
- Graceful handling of channel failures
