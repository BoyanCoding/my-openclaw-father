# OpenClaw Configuration Test Scenarios

This document defines test scenarios for OpenClaw configuration flows. Each scenario specifies a user request, expected agent behavior, and verification criteria.

## Scenario 1: Anthropic Provider with OAuth

**User Prompt:** "Configure OpenClaw to use Anthropic with OAuth"

**Expected Agent Behavior:**
1. Check if `openclaw.yaml` exists, create if not
2. Set up gateway configuration:
   ```yaml
   gateway:
     bind: "0.0.0.0:8080"
     authToken: "<generate-secure-token>"
   ```
3. Configure Anthropic provider:
   ```yaml
   providers:
     anthropic:
       type: anthropic
       auth:
         type: oauth
         # Guide user through OAuth flow or accept existing token
         clientId: "your-client-id"
         clientSecret: "your-client-secret"
         redirectUri: "http://localhost:8080/callback"
       models:
         - claude-3-5-sonnet
         - claude-3-haiku
   ```
4. Offer to generate OAuth credentials or walk through Anthropic console setup
5. Set default provider
6. Validate configuration with `openclaw config validate`
7. Restart service if running

**Key Checks:**
- [ ] Agent creates or updates `openclaw.yaml`
- [ ] Gateway section has secure authToken
- [ ] Anthropic provider type is correct
- [ ] OAuth credentials structure is valid
- [ ] Models list includes requested Claude models
- [ ] Configuration passes validation
- [ ] Service restarts without errors
- [ ] OAuth flow can complete (test with API call)

**Edge Cases to Test:**
- Missing OAuth credentials
- Invalid client ID/secret
- Redirect URI mismatch
- Token expiration and refresh

---

## Scenario 2: OpenAI Provider with API Key

**User Prompt:** "Set up OpenAI as the provider with my API key"

**Expected Agent Behavior:**
1. Prompt for API key (secure input, don't echo to terminal)
2. Create/update configuration:
   ```yaml
   providers:
     openai:
       type: openai
       auth:
         type: api_key
         apiKey: "${OPENAI_API_KEY}" # or prompt for value
       baseURL: "https://api.openai.com/v1" # optional, custom base
       models:
         - gpt-4
         - gpt-4-turbo
         - gpt-3.5-turbo
   ```
3. Offer to store key in environment variable or encrypted config
4. Set as default provider
5. Validate configuration
6. Test connection with minimal API call

**Key Checks:**
- [ ] API key not displayed in plaintext (use env var or secure storage)
- [ ] Provider type is `openai`
- [ ] Auth type is `api_key`
- [ ] Models list includes standard OpenAI models
- [ ] Configuration validates successfully
- [ ] API key can authenticate (test call succeeds)
- [ ] Env variable reference is correct format

**Edge Cases to Test:**
- Invalid API key format
- API key with restricted permissions
- Custom base URL (Azure OpenAI, proxy)
- Models user doesn't have access to

---

## Scenario 3: Google Gemini Provider

**User Prompt:** "Configure Google Gemini as the AI provider"

**Expected Agent Behavior:**
1. Prompt for Google credentials (API key or service account)
2. Create configuration:
   ```yaml
   providers:
     gemini:
       type: gemini
       auth:
         type: api_key
         apiKey: "${GEMINI_API_KEY}"
       models:
         - gemini-1.5-pro
         - gemini-1.5-flash
         - gemini-1.0-pro
   ```
3. Offer OAuth alternative for service accounts
4. Set default provider if requested
5. Validate and test connection

**Key Checks:**
- [ ] Provider type is `gemini`
- [ ] API key or OAuth credentials configured
- [ ] Models list includes current Gemini models
- [ ] Configuration validates
- [ ] Test API call succeeds
- [ ] Rate limits and quotas mentioned to user

**Edge Cases to Test:**
- Service account JSON credentials
- OAuth2 token flow
- Vertex AI endpoint (custom region)
- API key restrictions (HTTP referrer, IP)

---

## Scenario 4: Multi-Provider Failover Setup

**User Prompt:** "Set up Anthropic as primary with OpenAI as fallback"

**Expected Agent Behavior:**
1. Configure both providers:
   ```yaml
   providers:
     anthropic:
       type: anthropic
       auth:
         type: api_key
         apiKey: "${ANTHROPIC_API_KEY}"
       models: [claude-3-5-sonnet]
     openai:
       type: openai
       auth:
         type: api_key
         apiKey: "${OPENAI_API_KEY}"
       models: [gpt-4-turbo]
   ```
2. Configure failover logic:
   ```yaml
   routing:
     defaultProvider: anthropic
     failover:
       enabled: true
       providers: [openai]
       maxRetries: 3
       timeoutMs: 30000
   ```
3. Test failover with simulated failure
4. Document failover behavior

**Key Checks:**
- [ ] Both providers configured correctly
- [ ] Default provider set to primary
- [ ] Failover section exists with enabled: true
- [ ] Failover providers list includes fallback
- [ ] Timeout and retry settings reasonable
- [ ] Configuration validates
- [ ] Failover actually triggers on primary failure

**Edge Cases to Test:**
- Primary provider slow but not failed
- Both providers fail
- Failover provider also fails
- Circuit breaker patterns
- Cost-aware routing (cheaper fallback)

---

## Scenario 5: Minimal Configuration

**User Prompt:** "Give me a minimal working config"

**Expected Agent Behavior:**
1. Create smallest valid configuration:
   ```yaml
   gateway:
     bind: "127.0.0.1:8080"
     authToken: "minsecure-token-change-me"
   providers:
     anthropic:
       type: anthropic
       auth:
         type: api_key
         apiKey: "${ANTHROPIC_API_KEY}"
       models: [claude-3-5-sonnet]
   routing:
     defaultProvider: anthropic
   ```
2. Explain what each section does
3. Warn about security (token, bind address)
4. Skip optional sections (channels, security policies)
5. Validate minimal config works

**Key Checks:**
- [ ] Configuration has only required fields
- [ ] Validates successfully
- [ ] Service starts with minimal config
- [ ] Can make basic API call
- [ ] User understands limitations (no channels, open security)

**Edge Cases to Test:**
- Missing required fields
- Invalid required values
- Minimal config in different formats (JSON, TOML)

---

## Scenario 6: Reconfigure Existing Installation

**User Prompt:** "Switch from OpenAI to Anthropic and add a Telegram channel"

**Expected Agent Behavior:**
1. Read existing configuration
2. Backup current config
3. Identify changes needed:
   - Add Anthropic provider
   - Remove or disable OpenAI provider
   - Update defaultProvider
   - Add Telegram channel configuration
4. Create new config:
   ```yaml
   providers:
     anthropic:
       type: anthropic
       auth: {type: api_key, apiKey: "${ANTHROPIC_API_KEY}"}
       models: [claude-3-5-sonnet]
     openai:
       type: openai
       enabled: false  # Disable instead of remove
       # ... existing config preserved
   channels:
     telegram:
       type: telegram
       botToken: "${TELEGRAM_BOT_TOKEN}"
       # ... telegram config
   routing:
     defaultProvider: anthropic
   ```
5. Validate new configuration
6. Ask for confirmation before applying
7. Apply changes and restart service
8. Test both new provider and new channel

**Key Checks:**
- [ ] Existing config read and preserved where appropriate
- [ ] Backup created before changes
- [ ] Old provider disabled, not deleted (easy rollback)
- [ ] New provider configured correctly
- [ ] Channel added with proper structure
- [ ] User confirms changes before applying
- [ ] Configuration validates
- [ ] Service restarts successfully
- [ ] Both new provider and channel functional

**Edge Cases to Test:**
- Invalid existing config (can't parse)
- Provider in use by active channel
- Removing default provider without replacement
- Channel credentials missing
- Rollback on failure

---

## Testing Notes

**Prerequisites:**
- Valid API keys for each provider (or test endpoints)
- Configuration schema reference
- Mock API servers for testing without real keys
- Template configurations for comparison

**Automation Strategy:**
- Use YAML parsing to verify structure
- Validate against JSON schema
- Test with real config files in isolated environment
- Mock API responses for connection testing

**Common Pitfalls to Check:**
- Hardcoded credentials (should use env vars)
- Invalid bind addresses (0.0.0.0 vs 127.0.0.1 security)
- Missing required fields
- Type mismatches (string vs number, array vs object)
- Deprecated configuration options

**Success Criteria:**
- All generated configurations are valid YAML
- All configurations pass schema validation
- Service starts with each configuration
- API calls succeed through configured providers
- Failover works as expected in multi-provider setups
