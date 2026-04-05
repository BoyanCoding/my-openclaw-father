# OpenClaw Security Test Scenarios

This document defines test scenarios for OpenClaw security configuration and hardening. Each scenario specifies a security context, expected agent behavior, and verification criteria.

## Scenario 1: Fresh Install Security Hardening

**User Prompt:** "Secure my new OpenClaw installation"

**Expected Agent Behavior:**
1. **Audit Current Configuration:**
   - Check bind address (should not be 0.0.0.0 for exposed servers)
   - Check authToken strength
   - Check for hardcoded credentials
   - Review security policies

2. **Generate Secure Configuration:**
   ```yaml
   gateway:
     bind: "127.0.0.1:8080"  # Local only, or specific IP
     authToken: "<generate-cryptographically-secure-token-64+chars>"
     tls:
       enabled: true
       certFile: "/etc/openclaw/tls/cert.pem"
       keyFile: "/etc/openclaw/tls/key.pem"

   security:
     authentication:
       required: true
       type: "token"
     rateLimit:
       enabled: true
       requestsPerMinute: 60
       burst: 10
     cors:
       enabled: false  # Disable by default
     logging:
       level: "info"
       audit: true
       logPath: "/var/log/openclaw/audit.log"
   ```

3. **Generate TLS Certificate:**
   - Offer self-signed cert for testing
   - Recommend Let's Encrypt for production
   - Generate with strong cipher suite

4. **Configure Firewall:**
   - Suggest ufw/iptables rules
   - Restrict port access
   - Block non-essential traffic

5. **Set File Permissions:**
   ```bash
   chmod 600 /etc/openclaw/config.yaml
   chmod 640 /var/log/openclaw/audit.log
   chown root:openclaw /etc/openclaw/*
   ```

6. **Document Security Baseline**

**Key Checks:**
- [ ] Bind address is not 0.0.0.0 (or explicitly approved)
- [ ] AuthToken is cryptographically secure (64+ chars, random)
- [ ] TLS enabled with valid certificate
- [ ] No hardcoded credentials in config
- [ ] Rate limiting enabled
- [ ] CORS disabled by default
- [ ] Audit logging enabled
- [ ] File permissions are restrictive (600/640)
- [ ] Firewall rules applied
- [ ] Service runs as non-root user

**Edge Cases to Test:**
- Server behind reverse proxy (nginx, Caddy)
- Docker deployment (TLS termination at proxy)
- Air-gapped environment (can't reach CA)
- Custom port requirements

---

## Scenario 2: Open Policy → Pairing → Allowlist

**User Prompt:** "My OpenClaw is open to everyone. Secure it."

**Expected Agent Behavior:**

**Phase 1: Immediate Lockdown**
1. Check current security policy state
2. If completely open, enable pairing mode:
   ```yaml
   security:
     policy:
       mode: "pairing"  # Temporary middle ground
       pairingWindow: 3600  # 1 hour to pair devices
     authentication:
       required: true
   ```
3. Restart service with new policy
4. Inform user of pairing code/URL

**Phase 2: Transition to Allowlist**
1. After user pairs their devices, switch to allowlist:
   ```yaml
   security:
     policy:
       mode: "allowlist"
       allowedIdentities:
         - type: "telegram"
           id: "123456789"
           label: "Admin Phone"
         - type: "ip"
           value: "192.168.1.100"
           label: "Home PC"
     authentication:
       required: true
   ```

**Key Checks:**
- [ ] Agent detects open policy (no auth required)
- [ ] Immediate action taken (pairing mode enabled)
- [ ] User informed of pairing process
- [ ] Pairing window is time-limited
- [ ] Allowlist mode activated after pairing
- [ ] All paired identities listed in config
- [ ] Open access is definitively closed
- [ ] Configuration validated

**Edge Cases to Test:**
- No devices paired during window (extend window or manual add)
- User loses pairing access (manual admin override)
- Existing connections during transition
- Multiple users to pair

---

## Scenario 3: Add Team Members to Allowlist

**User Prompt:** "Add my team members Alice and Bob to the allowlist"

**Expected Agent Behavior:**
1. Query for each team member's identity:
   - For Telegram: Chat ID or username
   - For Discord: User ID or server role
   - For email: Email address
   - For IP: IP address or CIDR

2. Add to allowlist configuration:
   ```yaml
   security:
     policy:
       mode: "allowlist"
       allowedIdentities:
         - type: "telegram"
           id: "123456789"
           label: "Admin"
           role: "admin"
         - type: "telegram"
           id: "987654321"
           label: "Alice"
           role: "user"
         - type: "telegram"
           id: "555555555"
           label: "Bob"
           role: "user"
         - type: "discord"
           id: "alice_discord_id"
           label: "Alice (Discord)"
           role: "user"
   ```

3. Verify identities (optionally test with a message)
4. Apply configuration and reload
5. Test access for each added member

**Key Checks:**
- [ ] Each identity collected with clear labeling
- [ ] Identity types match channel capabilities
- [ ] Labels are descriptive (name + channel)
- [ ] Roles assigned appropriately
- [ ] Configuration validates
- [ ] Service reloads without errors
- [ ] Each team member can access OpenClaw
- [ ] Non-allowed members still blocked

**Edge Cases to Test:**
- Duplicate identities (same person, different channels)
- Invalid identity format (bad chat ID)
- Identity across multiple channels (Telegram + Discord)
- Role-based permissions (admin vs user)

---

## Scenario 4: Rotate Gateway Token

**User Prompt:** "Rotate the gateway authentication token"

**Expected Agent Behavior:**
1. **Generate New Token:**
   - Use cryptographically secure RNG
   - Length: 64+ characters
   - Mixed case, numbers, symbols
   - Don't display in plaintext (show only first/last 8 chars)

2. **Update Configuration:**
   ```yaml
   gateway:
     authToken: "<new-secure-token>"
   ```

3. **Handle Active Connections:**
   - Graceful rotation: accept both old and new for 5 minutes
   - Or immediate rotation: restart service
   - Offer choice based on usage

4. **Update Consumers:**
   - List all places token is used (channel configs, env vars)
   - Prompt to update each
   - Offer to restart dependent services

5. **Verify Rotation:**
   - Test new token works
   - Confirm old token rejected (after grace period)

**Key Checks:**
- [ ] New token is cryptographically secure
- [ ] Token not displayed in full in output
- [ ] Configuration updated atomically
- [ ] Old token invalidated (after grace period)
- [ ] New token authenticates successfully
- [ ] All dependent configs identified and updated
- [ ] Service remains available during rotation (graceful mode)

**Edge Cases to Test:**
- Token hardcoded in multiple files
- Token in environment variables requiring service restart
- Token used by external integrations
- Rotation during active usage spike

---

## Scenario 5: Detect and Fix Misconfigurations

**User Prompt:** "Audit my OpenClaw security configuration"

**Expected Agent Behavior:**

**Comprehensive Security Audit:**
1. **Check Common Misconfigurations:**
   - [ ] Hardcoded API keys in config files
   - [ ] Bind address 0.0.0.0 on public-facing server
   - [ ] Default or weak authToken
   - [ ] Authentication disabled
   - [ ] CORS configured with wildcard origin
   - [ ] Rate limiting disabled
   - [ ] TLS disabled
   - [ ] Log files with overly permissive permissions
   - [ ] Running as root user
   - [ ] Outdated dependencies
   - [ ] Insecure TLS protocols/ciphers

2. **Generate Audit Report:**
   ```
   Security Audit Report
   =====================
   ✓ PASS: TLS enabled with valid certificate
   ✗ FAIL: Bind address 0.0.0.0 exposes service to all interfaces
   ✗ WARN: Rate limiting disabled (vulnerable to DoS)
   ✗ FAIL: Default authToken detected (should be rotated)
   ✓ PASS: Running as non-root user
   ```

3. **Provide Remediation Steps:**
   For each FAIL/WARN, provide:
   - Description of the vulnerability
   - Severity level (Critical/High/Medium/Low)
   - Specific fix command or config change
   - Verification step to confirm fix

4. **Offer Auto-Fix:**
   For critical issues, offer to apply fixes automatically

**Key Checks:**
- [ ] All 10+ common misconfigurations checked
- [ ] Audit report is clear and actionable
- [ ] Severity levels assigned appropriately
- [ ] Remediation steps are specific and tested
- [ ] Auto-fix available for critical issues
- [ ] Configuration backup before changes
- [ ] Verification steps for each fix

**Edge Cases to Test:**
- Configuration with multiple issues
- False positives (secure setup that looks insecure)
- Conflicting security requirements
- Partially hardened config (some things fixed, others not)

---

## Testing Notes

**Prerequisites:**
- Test environment with various security configurations
- Ability to simulate security issues
- TLS certificate generation tools
- Mock users/channels for allowlist testing

**Security Testing Tools to Use:**
- `yamllint` for config syntax
- `jq` for JSON config validation
- `openssl` for certificate generation
- `ss` or `netstat` for binding verification
- `ps aux` for user permission check
- File permission testing

**Attack Simulation:**
- Test authentication bypass attempts
- Simulate DoS with rate limiting disabled
- Try common default credentials
- Test TLS downgrade attacks
- Attempt CORS exploitation

**Success Criteria:**
- All security scenarios produce hardened configurations
- No hardcoded credentials in generated configs
- All secrets use environment variables
- TLS is enabled and valid
- Authentication is required
- Rate limiting is configured
- Audit logging is enabled
- File permissions are restrictive
