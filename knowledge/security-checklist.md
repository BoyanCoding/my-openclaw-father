# OpenClaw Security Checklist

This guide covers security hardening for OpenClaw deployments, from basic setup to enterprise-grade configurations.

## DM Policy Options

The `dmPolicy` setting controls who can send DMs to your OpenClaw bot. This is your primary security control.

### Policy Modes

| Policy | Security | Use Case | Configuration |
|--------|----------|----------|--------------|
| **pairing** | 🔒 High | Default, recommended | Users pair via one-time code |
| **allowlist** | 🔒🔒 Very High | Locked-down, known users | Only pre-approved sender IDs |
| **open** | ⚠️ Low | Testing only | Anyone can DM (dangerous) |
| **disabled** | 🔒🔒🔒 Maximum | No DM access | Groups/channel-only |

### Configuration Examples

```json5
// 1. Pairing Mode (Recommended)
{
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "pairing"  // Default, safest for most users
    }
  }
}

// 2. Allowlist Mode (Locked Down)
{
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "allowlist",
      allowFrom: [
        "123456789",  // Telegram user ID
        "987654321"   // Another user
      ]
    }
  }
}

// 3. Open Mode (Dangerous - Use with caution!)
{
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "open",
      allowFrom: ["*"]  // Required for open mode - anyone can DM!
    }
  }
}

// 4. Disabled Mode (No DMs)
{
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "disabled"
    }
  }
}
```

## Pairing Workflow

Pairing is the default and recommended security model. It allows users to request access, which you must explicitly approve.

### How Pairing Works

1. **User DMs bot**: New user sends a message to your bot
2. **Bot responds**: User receives a pairing code (e.g., `ABC123`)
3. **Operator approval**: You run `openclaw pairing approve ABC123`
4. **Access granted**: User can now send commands
5. **Persistent**: User remains approved until explicitly removed

### Pairing Commands

```bash
# List pending and approved pairings
openclaw pairing list

# Approve a pairing request
openclaw pairing approve ABC123

# Approve with custom label
openclaw pairing approve ABC123 --label "John Doe"

# Approve for specific channel
openclaw pairing approve ABC123 --channel telegram

# Remove approved pairing
openclaw pairing remove USER_ID

# Remove from specific channel
openclaw pairing remove USER_ID --channel discord

# Show pairing details
openclaw pairing show USER_ID
```

### Per-Channel Pairing

Pairing works independently across channels:

```bash
# Approve for Telegram only
openclaw pairing approve CODE123 --channel telegram

# Approve for all channels
openclaw pairing approve CODE123
```

### Pairing Storage

Approved pairings are stored in:
```
~/.openclaw/state/pairings.json
```

Format:
```json5
{
  "pairings": {
    "telegram:123456789": {
      "channel": "telegram",
      "userId": "123456789",
      "approvedAt": "2025-01-15T10:30:00Z",
      "label": "John Doe",
      "approvedBy": "operator"
    }
  }
}
```

### Transitioning from Pairing to Allowlist

Once you've identified your trusted users, transition to allowlist for tighter control:

1. **Export current pairings**:
   ```bash
   openclaw pairing export --format json > pairings.json
   ```

2. **Update config**:
   ```json5
   {
     channels: {
       telegram: {
         dmPolicy: "allowlist",
         allowFrom: ["123456789", "987654321"]  // From export
       }
     }
   }
   ```

3. **Restart gateway**:
   ```bash
   openclaw gateway restart
   ```

## Allowlist Setup

Allowlist mode provides the tightest security by only allowing pre-approved users.

### Finding User IDs

```bash
# Telegram - after receiving a message
openclaw telegram list-chats

# Discord - enable Developer Mode, right-click user, Copy ID
# Slack - check logs for user_id when message received
```

### Allowlist Best Practices

1. **Start with pairing** to identify legitimate users
2. **Export user IDs** from approved pairings
3. **Migrate to allowlist** for production
4. **Regular audits** - review and remove old entries

```json5
{
  channels: {
    telegram: {
      dmPolicy: "allowlist",
      allowFrom: [
        "123456789",  // Alice
        "987654321"   // Bob
      ]
    },
    discord: {
      botToken: "${DISCORD_BOT_TOKEN}",
      dmPolicy: "allowlist",
      allowFrom: [
        "123456789012345678",  // Alice's Discord ID
        "987654321098765432"   // Bob's Discord ID
      ]
    }
  }
}
```

## Gateway Authentication

The OpenClaw gateway has three authentication modes for its API endpoint.

### Authentication Modes

```json5
{
  gateway: {
    // Mode 1: Token-based (Recommended)
    auth: {
      mode: "token",
      token: "${GATEWAY_TOKEN}"  // Random 32+ char string
    },

    // Mode 2: Password-based (Legacy, less secure)
    auth: {
      mode: "password",
      password: "${GATEWAY_PASSWORD}"
    },

    // Mode 3: Trusted proxy (Only behind reverse proxy)
    auth: {
      mode: "trusted-proxy",
      trustedProxies: ["127.0.0.1", "10.0.0.0/8"]
    }
  }
}
```

### Token Generation

Generate a secure gateway token:

```bash
# Generate random token
openssl rand -hex 32

# Add to .env
echo 'GATEWAY_TOKEN="your_generated_token"' >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
```

### Recommended Configuration

```json5
{
  gateway: {
    port: 18789,
    auth: {
      mode: "token",
      token: "${GATEWAY_TOKEN}"
    }
  }
}
```

## API Key Storage

**CRITICAL**: Never store API keys directly in `openclaw.json`. Use environment variables.

### Correct Approach

1. **Create `.env` file**:
   ```bash
   touch ~/.openclaw/.env
   chmod 600 ~/.openclaw/.env
   ```

2. **Add keys to `.env`**:
   ```bash
   # Model providers
   ANTHROPIC_API_KEY="sk-ant-..."
   OPENAI_API_KEY="sk-..."
   GOOGLE_API_KEY="..."

   # Channel tokens
   TELEGRAM_BOT_TOKEN="123456789:ABC..."
   DISCORD_BOT_TOKEN="MTE..."
   SLACK_BOT_TOKEN="xoxb-..."
   SLACK_APP_TOKEN="xapp-..."

   # Gateway
   GATEWAY_TOKEN="generated_token_here"
   ```

3. **Reference in `openclaw.json`**:
   ```json5
   {
     models: {
       providers: {
         anthropic: {
           apiKey: "${ANTHROPIC_API_KEY}"
         }
       }
     },
     channels: {
       telegram: {
         botToken: "${TELEGRAM_BOT_TOKEN}"
       }
     },
     gateway: {
       auth: {
         mode: "token",
         token: "${GATEWAY_TOKEN}"
       }
     }
   }
   ```

### Auth Profiles

For complex setups, use `auth-profiles.json`:

```bash
~/.openclaw/auth-profiles.json
```

```json5
{
  "profiles": {
    "default": {
      "type": "api-key",
      "apiKey": "${ANTHROPIC_API_KEY}"
    },
    "work": {
      "type": "oauth",
      "clientId": "${WORK_CLIENT_ID}",
      "clientSecret": "${WORK_CLIENT_SECRET}",
      "refreshToken": "${WORK_REFRESH_TOKEN}"
    }
  }
}
```

Reference profiles in `openclaw.json`:
```json5
{
  models: {
    providers: {
      anthropic: {
        authProfile: "default"
      }
    }
  }
}
```

## File Permissions

Secure all sensitive files with restrictive permissions.

### Permission Commands

```bash
# Secure .env file
chmod 600 ~/.openclaw/.env

# Secure config file
chmod 600 ~/.openclaw/openclaw.json

# Secure auth profiles
chmod 600 ~/.openclaw/auth-profiles.json

# Secure state directory
chmod 700 ~/.openclaw/state

# Secure logs (may contain sensitive data)
chmod 600 /tmp/openclaw/*.log
```

### Verify Permissions

```bash
# Check permissions
ls -la ~/.openclaw/

# Should show:
# -rw------- (600) for .env, openclaw.json, auth-profiles.json
# drwx------ (700) for state/
```

## Tool Policy

Control which tools agents can use via `tools.allow` and `tools.deny`.

### Tool Policy Configuration

```json5
{
  agents: {
    defaults: {
      tools: {
        // Allow specific tools (whitelist mode)
        allow: [
          "read",
          "write",
          "bash",
          "search"
        ],

        // Deny dangerous tools (blacklist mode)
        deny: [
          "browser.control",
          "system.exec",
          "database.write"
        ],

        // Mode: "allow" (whitelist) or "deny" (blacklist)
        mode: "allow"  // Recommended: start with allow mode
      }
    }
  }
}
```

### High-Security Configuration

```json5
{
  agents: {
    defaults: {
      tools: {
        mode: "allow",
        allow: [
          "read",           // Read files only
          "search"          // Search codebase
        ],
        deny: [
          "write",          // No file modifications
          "bash",           // No command execution
          "browser.control", // No browser control
          "database.write", // No DB writes
          "network.request" // No network requests
        ]
      }
    }
  }
}
```

### Per-Agent Tool Policies

```json5
{
  agents: {
    "code-assistant": {
      tools: {
        mode: "allow",
        allow: ["read", "write", "search", "bash"]
      }
    },
    "read-only-bot": {
      tools: {
        mode: "allow",
        allow: ["read", "search"]
      }
    },
    "admin-bot": {
      tools: {
        mode: "deny",
        deny: []  // No restrictions (use with caution!)
      }
    }
  }
}
```

## Sandbox Configuration

Control agent access to system resources.

### Sandbox Modes

```json5
{
  agents: {
    defaults: {
      sandbox: {
        // Mode options:
        // - "off": No sandboxing (dangerous)
        // - "all": Full sandboxing (recommended)
        // - "non-main": Sandbox non-main agents only
        mode: "all",

        // Scope: Isolation level
        // - "session": Each session isolated
        // - "agent": Each agent isolated
        scope: "session",

        // Workspace access:
        // - "rw": Read-write (default)
        // - "ro": Read-only
        // - "none": No workspace access
        workspaceAccess: "rw",

        // Allowed paths (whitelist)
        allowedPaths: [
          "~/openclaw-workspace",
          "/tmp/openclaw"
        ],

        // Blocked paths (blacklist)
        blockedPaths: [
          "~/.ssh",
          "~/.gnupg",
          "/etc",
          "/sys",
          "/proc"
        ]
      }
    }
  }
}
```

### Recommended Sandbox Setup

```json5
{
  agents: {
    defaults: {
      sandbox: {
        mode: "all",
        scope: "session",
        workspaceAccess: "rw",
        allowedPaths: [
          "~/openclaw-workspace",
          "/tmp/openclaw"
        ],
        blockedPaths: [
          "~/.ssh",
          "~/.gnupg",
          "~/.aws",
          "/etc",
          "/root"
        ]
      }
    }
  }
}
```

## Browser Control Security

If using browser control tools, configure SSRF protection.

```json5
{
  agents: {
    defaults: {
      browser: {
        // SSRF Policy: Prevent server-side request forgery
        ssrfPolicy: {
          // Allow specific domains
          allow: [
            "*.example.com",
            "docs.internal.com"
          ],

          // Block dangerous patterns
          block: [
            "localhost",
            "127.0.0.1",
            "0.0.0.0",
            "169.254.169.254",  // Metadata endpoint
            "10.*",
            "192.168.*",
            "172.16.*",
            "file://",
            "ftp://",
            "data:"
          ],

          // Maximum page size (bytes)
          maxPageSize: 10485760,  // 10MB

          // Timeout (seconds)
          timeout: 30
        },

        // Headless mode (no GUI)
        headless: true,

        // Disable DevTools
        disableDevTools: true
      }
    }
  }
}
```

## Security Audit Checklist

Complete these steps before deploying to production.

### Phase 1: Initial Setup

- [ ] **DM Policy**: Set to `pairing` (not `open`)
- [ ] **Environment Variables**: All secrets in `.env` file
- [ ] **File Permissions**: `chmod 600` on `.env`, `openclaw.json`
- [ ] **Gateway Auth**: Use token mode with strong token
- [ ] **Tool Policy**: Set to `allow` mode with specific tools
- [ ] **Sandbox**: Enable `mode: "all"` with restricted paths

### Phase 2: Channel Configuration

- [ ] **Channel Tokens**: In `.env`, not in config
- [ ] **Group Mentions**: `requireMention: true` for all groups
- [ ] **Bot Permissions**: Minimum required permissions only
- [ ] **Webhook Security**: Verify webhook URLs use HTTPS
- [ ] **Rate Limiting**: Configure per-channel rate limits

### Phase 3: Network Security

- [ ] **Firewall**: Block direct access to gateway port
- [ ] **Reverse Proxy**: Use nginx/traefik with SSL
- [ ] **IP Whitelist**: Restrict gateway access to known IPs
- [ ] **SSL Certificates**: Use valid certificates for webhooks
- [ ] **VPN/Private Network**: Deploy gateway behind VPN

### Phase 4: Operational Security

- [ ] **Logging**: Enable security logs (no sensitive data)
- [ ] **Monitoring**: Alert on suspicious activity
- [ ] **Backup**: Secure backups of config (encrypted)
- [ ] **Updates**: Regular security updates
- [ ] **Audit Trail**: Log all approved pairings

### Phase 5: Verification

- [ ] **Test Open Mode**: Verify open mode is NOT enabled
- [ ] **Test Unknown User**: Verify unknown users blocked
- [ ] **Test Tool Restrictions**: Verify blocked tools don't work
- [ ] **Test Sandbox**: Verify blocked paths inaccessible
- [ ] **Test Browser SSRF**: Verify localhost blocked

## Secure Baseline Configuration

Copy this configuration for a secure baseline setup:

```json5
{
  // Channel security
  channels: {
    telegram: {
      botToken: "${TELEGRAM_BOT_TOKEN}",
      dmPolicy: "pairing",  // Require pairing
      groups: {
        enabled: true,
        requireMention: true  // Require @mention in groups
      }
    },
    discord: {
      botToken: "${DISCORD_BOT_TOKEN}",
      dmPolicy: "pairing"
    }
  },

  // Gateway security
  gateway: {
    port: 18789,
    auth: {
      mode: "token",
      token: "${GATEWAY_TOKEN}"  // Strong random token
    }
  },

  // Agent security
  agents: {
    defaults: {
      tools: {
        mode: "allow",  // Whitelist mode
        allow: ["read", "write", "search"]
      },
      sandbox: {
        mode: "all",
        scope: "session",
        workspaceAccess: "rw",
        blockedPaths: [
          "~/.ssh",
          "~/.gnupg",
          "~/.aws",
          "/etc",
          "/root"
        ]
      },
      browser: {
        ssrfPolicy: {
          block: ["localhost", "127.0.0.1", "169.254.169.254"]
        },
        headless: true
      }
    }
  },

  // Model provider security
  models: {
    providers: {
      anthropic: {
        apiKey: "${ANTHROPIC_API_KEY}"
      }
    }
  }
}
```

## Warning Signs

Watch for these security red flags:

### Critical Warnings

🚨 **Open DM Policy + Tools Enabled**
```json5
// DANGEROUS - Anyone can run tools!
dmPolicy: "open",
allowFrom: ["*"],
tools: { allow: ["bash", "write"] }
```

🚨 **API Keys in Config**
```json5
// NEVER commit this!
apiKey: "sk-ant-123456789"  // Visible in git!
```

🚨 **Public Network Exposure**
```json5
// Gateway exposed to internet without auth
gateway: {
  port: 18789,
  auth: { mode: "none" }  // No authentication!
}
```

🚨 **Browser Control + Open Access**
```json5
// SSRF risk
dmPolicy: "open",
browser: { ssrfPolicy: { block: [] } }  // Nothing blocked!
```

### Warning Indicators

⚠️ **Permissive Tool Policy**
- Tools set to `deny` mode with empty deny list
- All tools allowed including dangerous ones

⚠️ **Weak Sandbox**
- Sandbox mode set to `off`
- No blocked paths configured
- Workspace access set to `rw` with no restrictions

⚠️ **Missing Rate Limits**
- No rate limiting on channels
- No request throttling

⚠️ **Unrestricted Webhooks**
- Webhook URLs using HTTP instead of HTTPS
- No webhook signature verification

## Security Monitoring

Monitor these metrics for security issues:

```bash
# Check for failed pairing attempts
openclaw pairing list --failed

# View recent authentication failures
tail -f /tmp/openclaw/openclaw.log | grep "auth failed"

# Check for suspicious tool usage
openclaw logs --tool "bash" --since "1h ago"

# Monitor unknown user attempts
openclaw logs --unknown-users --since "24h ago"

# Audit all approved pairings
openclaw pairing audit
```

## Incident Response

If security breach is suspected:

1. **Immediate Actions**
   ```bash
   # Stop gateway
   openclaw gateway stop

   # Change all API keys
   # Update .env file

   # Rotate gateway token
   openssl rand -hex 32 > ~/.openclaw/.new-token
   ```

2. **Review Logs**
   ```bash
   # Export logs for analysis
   openclaw logs export --since "7d ago" > incident-logs.json
   ```

3. **Audit Access**
   ```bash
   # Review all approved pairings
   openclaw pairing list

   # Remove suspicious pairings
   openclaw pairing remove USER_ID
   ```

4. **Update Configuration**
   ```bash
   # Switch to allowlist mode
   # Update openclaw.json with dmPolicy: "allowlist"

   # Restart with secure config
   openclaw gateway start
   ```

## Next Steps

After securing your installation:

1. **Run security audit**: `openclaw security audit`
2. **Test security controls**: Verify unknown users blocked
3. **Set up monitoring**: Configure alerts for suspicious activity
4. **Document access**: Maintain record of approved users
5. **Regular reviews**: Periodically audit pairings and permissions

For additional security resources:
- [model-providers.md](./model-providers.md) - Secure API key management
- [channel-setup-guides.md](./channel-setup-guides.md) - Channel-specific security
- [troubleshooting.md](./troubleshooting.md) - Security-related issues
