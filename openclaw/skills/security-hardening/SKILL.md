---
name: security-hardening
description: Harden OpenClaw security including DM policies, gateway auth, API key storage, file permissions, and tool policies. Use after installation or when auditing security.
---

# Security Hardening for OpenClaw

Let's lock down your OpenClaw installation to keep it secure. I'll walk you through a comprehensive security audit and hardening process.

## Before We Begin

I'll always fetch the latest security documentation to ensure you're following current best practices.

*(Fetch and review latest security docs before proceeding)*

## Security Assessment Overview

I'll check 10 critical security areas and provide a PASS/WARN/FAIL report for each:

1. ✓ DM Policy Configuration
2. ✓ Gateway Authentication
3. ✓ API Key Storage
4. ✓ File Permissions
5. ✓ Tool Policies
6. ✓ Sandbox Configuration
7. ✓ Browser Security
8. ✓ Network Exposure
9. ✓ Credential Management
10. ✓ Audit Logging

Let's go through each one.

---

## 1. DM Policy Assessment

### Check Current Policy

```bash
# View current DM policy
cat ~/.openclaw/openclaw.json | grep -A 10 "dmPolicy"
```

### Recommended Configuration

**Best Practice:** Start with "pairing" mode, then move to "allowlist" for production.

```json
{
  "channels": {
    "*": {
      "dmPolicy": {
        "mode": "allowlist",
        "allowedUsers": ["@trusted-user-1", "@trusted-user-2"],
        "pairingCode": "secure-code-123"
      }
    }
  }
}
```

**Security Levels:**
- `open` - ❌ Anyone can DM (not recommended)
- `pairing` - ⚠️ Users must be approved (good for testing)
- `allowlist` - ✓ Only pre-approved users (recommended)

### Pairing Workflow

1. **User initiates**: New user sends DM
2. **You approve**: `openclaw approve-DM @username --channel telegram`
3. **User confirmed**: User can now chat
4. **Add to allowlist**: Once trusted, add to permanent allowlist

---

## 2. Gateway Authentication

### Verify Token Mode

```bash
# Check auth mode
cat ~/.openclaw/openclaw.json | grep -A 5 '"auth"'
```

**Required Configuration:**

```json
{
  "gateway": {
    "auth": {
      "mode": "token",
      "tokens": {
        "default": "${OPENCLAW_GATEWAY_TOKEN}"
      }
    }
  }
}
```

### Check Bind Address

```bash
# Verify bind address
cat ~/.openclaw/openclaw.json | grep "bindAddress"
```

**Security Levels:**
- `127.0.0.1` - ✓ Localhost only (most secure)
- `0.0.0.0` - ⚠️ All interfaces (use with auth + firewall)
- Specific IP - ✓ Bind to specific interface

**Recommendation:** Use `127.0.0.1` + SSH tunnel for remote access:

```bash
# On your local machine
ssh -L 18789:localhost:18789 user@server
```

---

## 3. API Key Storage Audit

### Check for Leaked Keys

```bash
# Scan config for API keys (should NOT be in openclaw.json)
grep -i 'api.*key.*sk-' ~/.openclaw/openclaw.json

# Expected: No matches found
```

**If keys are found in config:** Move them to `.env` immediately!

### Verify .env Setup

```bash
# Check .env exists
ls -la ~/.openclaw/.env

# Verify format
cat ~/.openclaw/.env
```

**Correct format:**

```bash
# API Keys - NEVER commit to version control
OPENAI_API_KEY=sk-proj-abc123
ANTHROPIC_API_KEY=sk-ant-def456
OPENCLAW_GATEWAY_TOKEN=your-random-token-here
```

**Reference in config:**

```json
{
  "models": {
    "providers": {
      "openai": {
        "apiKey": "${OPENAI_API_KEY}"
      }
    }
  }
}
```

---

## 4. File Permissions

### Secure Sensitive Files

```bash
# Set restrictive permissions
chmod 600 ~/.openclaw/.env
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/auth-profiles.json
chmod 700 ~/.openclaw/credentials/

# Verify
ls -la ~/.openclaw/
```

**Expected output:** All sensitive files should show `-rw-------` (600)

### Check for World-Readable Files

```bash
# Find world-readable files in .openclaw
find ~/.openclaw -type f -perm /o=r -ls
```

**If any found:** Fix permissions immediately with `chmod 600`.

---

## 5. Tool Policy Review

### Check Allowed Tools

```bash
# View tool permissions
cat ~/.openclaw/openclaw.json | grep -A 20 '"tools"'
```

### Recommended Restrictions

```json
{
  "agents": {
    "tools": {
      "bash": {
        "enabled": true,
        "allowCommands": ["git", "npm", "ls", "cat", "grep", "find"],
        "denyCommands": ["rm -rf", "dd", "mkfs", "chmod 777"]
      },
      "filesystem": {
        "enabled": true,
        "allowRead": true,
        "allowWrite": true,
        "allowedPaths": ["~/openclaw-workspace", "/tmp"],
        "deniedPaths": ["/etc", "/usr", "/root", "~/.ssh"]
      },
      "network": {
        "enabled": true,
        "allowDomains": ["api.openai.com", "api.anthropic.com"],
        "denyDomains": ["*"]
      }
    }
  }
}
```

**Recommendation:** For non-main agents, disable dangerous tools:

```json
{
  "agents": {
    "restricted": {
      "tools": {
        "bash": { "enabled": false },
        "filesystem": { "enabled": false, "allowRead": true }
      }
    }
  }
}
```

---

## 6. Sandbox Configuration

### Check Sandbox Mode

```bash
# View sandbox settings
cat ~/.openclaw/openclaw.json | grep -A 15 '"sandbox"'
```

### Recommended Sandbox Settings

```json
{
  "agents": {
    "sandbox": {
      "enabled": true,
      "mode": "restricted",
      "allowNetwork": true,
      "allowFileSystem": true,
      "allowedPaths": ["~/openclaw-workspace", "/tmp"],
      "deniedPaths": ["/etc", "/usr", "/root", "~/.ssh", "~/.gnupg"],
      "chroot": null,
      "maxMemory": "512M",
      "maxCpu": 1
    }
  }
}
```

**Sandbox Modes:**
- `none` - ❌ No restrictions (dangerous)
- `basic` - ⚠️ Basic path restrictions
- `restricted` - ✓ Full isolation (recommended)
- `strict` - 🔒 Maximum security (limits functionality)

---

## 7. Browser Security

### Check Browser Settings

```bash
# View browser config
cat ~/.openclaw/openclaw.json | grep -A 10 '"browser"'
```

### Recommended Configuration

```json
{
  "agents": {
    "tools": {
      "browser": {
        "enabled": true,
        "headless": true,
        "ssrfPolicy": {
          "mode": "allowlist",
          "allowDomains": ["*.openai.com", "*.anthropic.com"],
          "denyDomains": ["169.254.169.254", "metadata.google.internal"]
        }
      }
    }
  }
}
```

**SSRF (Server-Side Request Forgery) Protection:**
- `allowlist` - ✓ Only allow specific domains (recommended)
- `denylist` - ⚠️ Block specific domains
- `none` - ❌ No protection (dangerous)

**Always block:**
- `169.254.169.254` (cloud metadata)
- `metadata.google.internal` (GCP metadata)
- Internal IP ranges

---

## 8. Network Exposure

### Check Open Ports

```bash
# Check if gateway is listening publicly
ss -tlnp | grep 18789
```

**Expected:** `127.0.0.1:18789` (local only)
**Warning:** `0.0.0.0:18789` (public - use with auth!)

### Firewall Rules

If binding to `0.0.0.0`, set up firewall:

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow from YOUR_IP to any port 18789

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="YOUR_IP" port protocol="tcp" port="18789" accept'
sudo firewall-cmd --reload
```

---

## 9. Credential Management

### Audit Stored Credentials

```bash
# Check auth-profiles.json
cat ~/.openclaw/auth-profiles.json

# Check credentials directory
ls -la ~/.openclaw/credentials/
```

### Best Practices

1. **Never store credentials in config files**
2. **Use environment variables** for all secrets
3. **Rotate keys regularly** - every 90 days
4. **Use separate keys** for dev/prod
5. **Revoke unused keys** immediately

---

## 10. Audit Logging

### Enable Logging

```json
{
  "logging": {
    "level": "info",
    "file": "/var/log/openclaw/openclaw.log",
    "auditLog": "/var/log/openclaw/audit.log",
    "auditEvents": ["dm_request", "auth_success", "auth_fail", "tool_use"]
  }
}
```

### Review Logs Regularly

```bash
# Check auth failures
grep "auth_fail" /var/log/openclaw/audit.log

# Check DM requests
grep "dm_request" /var/log/openclaw/audit.log

# Check tool usage
grep "tool_use" /var/log/openclaw/audit.log
```

---

## Security Report

After completing the audit, I'll generate a report:

```
OpenClaw Security Audit Report
================================

1. DM Policy:          ✓ PASS - Allowlist mode active
2. Gateway Auth:       ✓ PASS - Token auth enabled
3. API Key Storage:    ⚠️ WARN - Keys in .env (good)
4. File Permissions:   ✗ FAIL - openclaw.json is 644 (should be 600)
5. Tool Policies:      ✓ PASS - Dangerous tools restricted
6. Sandbox:            ✓ PASS - Restricted mode active
7. Browser Security:   ✓ PASS - SSRF protection enabled
8. Network Exposure:   ✓ PASS - Bound to 127.0.0.1
9. Credential Mgmt:    ✓ PASS - No keys in config
10. Audit Logging:     ⚠️ WARN - Logging not enabled

Overall: 7 PASS, 2 WARN, 1 FAIL
```

---

## 10-Step Security Checklist

Follow these steps to secure your OpenClaw installation:

1. ✓ Set DM policy to "allowlist" mode
2. ✓ Enable token authentication on gateway
3. ✓ Move all API keys to `.env` file
4. ✓ Run `chmod 600` on `.env`, `openclaw.json`, `auth-profiles.json`
5. ✓ Restrict bash tools (deny dangerous commands)
6. ✓ Enable sandbox in "restricted" mode
7. ✓ Configure SSRF protection for browser tool
8. ✓ Bind gateway to `127.0.0.1` or set up firewall
9. ✓ Enable audit logging for auth events
10. ✓ Review logs weekly and rotate keys quarterly

---

## Summary

Your OpenClaw installation is now hardened! Here's what we did:

- ✓ DM policy restricted to trusted users
- ✓ Gateway secured with token authentication
- ✓ API keys moved to secure `.env` file
- ✓ File permissions locked down to 600
- ✓ Tool policies configured for safe operation
- ✓ Sandbox enabled for agent isolation
- ✓ Browser protected against SSRF attacks
- ✓ Network exposure minimized
- ✓ Audit logging enabled for monitoring

**Recommended maintenance:**
- Review security logs weekly
- Rotate API keys every 90 days
- Re-audit after any major config changes

Stay secure! 🔒
