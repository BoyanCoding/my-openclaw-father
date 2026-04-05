# OpenClaw Model Providers

This guide covers configuration for all supported model providers, from API key setup to advanced routing strategies.

## Provider Overview

| Provider | API Prefix | Default Model | Context Window | Pricing Tier | Best For |
|----------|------------|---------------|----------------|--------------|----------|
| **Anthropic** | `anthropic:` | claude-opus-4-6 | 200K tokens | Premium | Complex reasoning, code analysis |
| **OpenAI** | `openai:` | gpt-5.2 | 128K tokens | Premium | General tasks, chat, tools |
| **Google** | `google:` | gemini-2.5-pro | 1M tokens | Standard | Long context, multimodal |
| **Mistral** | `mistral:` | mistral-large | 128K tokens | Standard | European hosting, code |
| **xAI** | `xai:` | grok-3 | 128K tokens | Standard | Twitter/X integration |
| **OpenRouter** | `openrouter:` | Various | Varies | Variable | Multi-provider proxy |
| **Groq** | `groq:` | llama-3.3-70b | 8K tokens | Low | Fast inference, testing |
| **Ollama** | `ollama:` | Various | Varies | Free | Local, privacy, offline |

## Anthropic (Claude)

### API Key Acquisition

1. Go to https://console.anthropic.com
2. Sign up or log in
3. Navigate to "API Keys"
4. Create new API key
5. Copy key (format: `sk-ant-xxx...`)

### Configuration

**Environment Variable (Recommended):**
```bash
echo 'ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.openclaw/.env
chmod 600 ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      anthropic: {
        apiKey: "${ANTHROPIC_API_KEY}",
        baseUrl: "https://api.anthropic.com",  // Optional custom endpoint
        defaultModel: "claude-opus-4-6"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `claude-opus-4-6` | 200K | Complex reasoning, deep analysis |
| `claude-sonnet-4-6` | 200K | Balanced performance, speed |
| `claude-haiku-4-5` | 200K | Fast, simple tasks |

### Provider-Specific Tips

- **Rate limits**: Start with 5 requests/second, increase gradually
- **Context window**: 200K tokens is huge, but costs scale with usage
- **Cost optimization**: Use Haiku for simple tasks, Opus only when needed
- **Streaming**: Supported by default, reduces perceived latency

## OpenAI

### API Key Acquisition

1. Go to https://platform.openai.com
2. Sign up or log in
3. Navigate to "API Keys"
4. Create new secret key
5. Copy key (format: `sk-proj-xxx...`)

### Configuration

**Environment Variable:**
```bash
echo 'OPENAI_API_KEY="sk-proj-your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      openai: {
        apiKey: "${OPENAI_API_KEY}",
        baseUrl: "https://api.openai.com/v1",  // Optional
        defaultModel: "gpt-5.2"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `gpt-5.2` | 128K | General purpose, reasoning |
| `gpt-4o` | 128K | Fast, multimodal |
| `o3` | 200K | Complex reasoning, coding |
| `gpt-4o-mini` | 128K | Fast, cost-effective |

### Provider-Specific Tips

- **Rate limits**: Tier-based, higher tiers get more requests
- **Cost**: o3 is expensive, use sparingly
- **Multimodal**: GPT-4o has excellent vision capabilities
- **Function calling**: Strong tool use support

## Google (Gemini)

### API Key Acquisition

1. Go to https://console.cloud.google.com
2. Create new project or select existing
3. Enable "Gemini API"
4. Navigate to "APIs & Services" → "Credentials"
5. Create API key
6. Copy key (format: `AIzaSy...`)

### Configuration

**Environment Variable:**
```bash
echo 'GOOGLE_API_KEY="AIzaSy-your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      google: {
        apiKey: "${GOOGLE_API_KEY}",
        baseUrl: "https://generativelanguage.googleapis.com/v1beta",
        defaultModel: "gemini-2.5-pro"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `gemini-2.5-pro` | 1M | Very long context, multimodal |
| `gemini-2.5-flash` | 1M | Fast, cost-effective |
| `gemini-2.0-flash-thinking` | 1M | Reasoning tasks |

### Provider-Specific Tips

- **Massive context**: 1M tokens is industry-leading
- **Cost**: Very competitive pricing
- **Multimodal**: Excellent vision and audio support
- **Rate limits**: Generous free tier

## Mistral

### API Key Acquisition

1. Go to https://console.mistral.ai
2. Sign up or log in
3. Navigate to "API Keys"
4. Create new API key
5. Copy key (format: `xxx...`)

### Configuration

**Environment Variable:**
```bash
echo 'MISTRAL_API_KEY="your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      mistral: {
        apiKey: "${MISTRAL_API_KEY}",
        baseUrl: "https://api.mistral.ai/v1",
        defaultModel: "mistral-large"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `mistral-large` | 128K | General purpose, multilingual |
| `codestral` | 32K | Code generation, programming |
| `mistral-small` | 32K | Fast, simple tasks |

### Provider-Specific Tips

- **European hosting**: Data stays in EU (GDPR compliant)
- **Code**: Codestral is excellent for programming
- **Cost**: Very competitive pricing
- **Multilingual**: Strong non-English support

## xAI (Grok)

### API Key Acquisition

1. Go to https://x.ai
2. Sign up or log in with X account
3. Navigate to API section
4. Create API key
5. Copy key

### Configuration

**Environment Variable:**
```bash
echo 'XAI_API_KEY="your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      xai: {
        apiKey: "${XAI_API_KEY}",
        baseUrl: "https://api.x.ai/v1",
        defaultModel: "grok-3"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `grok-3` | 128K | General purpose, current events |
| `grok-vision-beta` | 128K | Multimodal tasks |

### Provider-Specific Tips

- **Real-time knowledge**: Access to recent X/Twitter data
- **Rate limits**: Still evolving, check documentation
- **Cost**: Competitive pricing

## OpenRouter

### API Key Acquisition

1. Go to https://openrouter.ai
2. Sign up or log in
3. Navigate to "API Keys"
4. Create new API key
5. Copy key

### Configuration

**Environment Variable:**
```bash
echo 'OPENROUTER_API_KEY="your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      openrouter: {
        apiKey: "${OPENROUTER_API_KEY}",
        baseUrl: "https://openrouter.ai/api/v1",
        defaultModel: "anthropic/claude-opus-4-6"
      }
    }
  }
}
```

### Available Models

OpenRouter provides access to 100+ models from multiple providers:

- `anthropic/claude-opus-4-6`
- `openai/gpt-5.2`
- `google/gemini-2.5-pro`
- `meta-llama/llama-3.3-70b`
- And many more...

### Provider-Specific Tips

- **Unified API**: Single API for multiple providers
- **Fallback**: Can automatically fallback to alternative models
- **Cost**: Shows pricing per model before request
- **Rate limits**: Varies by underlying provider

## Groq

### API Key Acquisition

1. Go to https://console.groq.com
2. Sign up or log in
3. Navigate to "API Keys"
4. Create new API key
5. Copy key

### Configuration

**Environment Variable:**
```bash
echo 'GROQ_API_KEY="your-key-here"' >> ~/.openclaw/.env
```

**openclaw.json:**
```json5
{
  models: {
    providers: {
      groq: {
        apiKey: "${GROQ_API_KEY}",
        baseUrl: "https://api.groq.com/openai/v1",
        defaultModel: "llama-3.3-70b-versatile"
      }
    }
  }
}
```

### Available Models

| Model | Context | Best For |
|-------|---------|----------|
| `llama-3.3-70b-versatile` | 128K | General purpose |
| `llama-3.3-8b-instant` | 128K | Very fast, simple tasks |
| `mixtral-8x7b-32768` | 32K | Fast, cost-effective |

### Provider-Specific Tips

- **Speed**: Extremely fast inference (100+ tokens/second)
- **Cost**: Very low cost per token
- **Latency**: Best for real-time applications
- **Context**: Limited compared to other providers

## Ollama (Local)

### Setup

1. **Install Ollama:**
   ```bash
   # macOS
   brew install ollama

   # Linux
   curl -fsSL https://ollama.com/install.sh | sh

   # Windows
   # Download from https://ollama.com
   ```

2. **Pull Models:**
   ```bash
   ollama pull llama3.3
   ollama pull codellama
   ```

3. **Start Server:**
   ```bash
   ollama serve  # Runs on localhost:11434
   ```

### Configuration

**openclaw.json:**
```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://localhost:11434",
        defaultModel: "llama3.3",
        // No API key needed for local
      }
    }
  }
}
```

### Available Models

Pull any model from Ollama library:
- `llama3.3` (70B)
- `codellama` (34B)
- `mistral` (7B)
- `phi3` (3.8B)
- And many more...

### Provider-Specific Tips

- **Privacy**: All data stays local
- **Cost**: Free (just hardware)
- **Speed**: Depends on your hardware
- **Models**: Limited to open-source models
- **Networking**: Ensure localhost:11434 is accessible

## Model Selection for Agents

Configure default models for agents in `openclaw.json`:

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic:claude-opus-4-6",  // Primary model
        fallbacks: [                           // Fallback chain
          "openai:gpt-5.2",
          "google:gemini-2.5-pro"
        ]
      }
    },
    "code-assistant": {
      model: {
        primary: "anthropic:claude-opus-4-6",
        fallbacks: ["openai:o3"]
      }
    },
    "fast-chat": {
      model: {
        primary: "groq:llama-3.3-8b-instant",
        fallbacks: ["anthropic:claude-haiku-4-5"]
      }
    },
    "long-context": {
      model: {
        primary: "google:gemini-2.5-pro",  // 1M context
        fallbacks: ["anthropic:claude-opus-4-6"]
      }
    }
  }
}
```

## Model Selection by Use Case

### Coding & Programming

**Best choices:**
1. `anthropic:claude-opus-4-6` - Best for complex code
2. `openai:o3` - Excellent for debugging
3. `mistral:codestral` - Fast code generation

**Configuration:**
```json5
{
  agents: {
    "coder": {
      model: {
        primary: "anthropic:claude-opus-4-6",
        fallbacks: ["openai:o3", "mistral:codestral"]
      }
    }
  }
}
```

### General Chat & Assistance

**Best choices:**
1. `anthropic:claude-sonnet-4-6` - Balanced speed/quality
2. `openai:gpt-5.2` - General purpose
3. `groq:llama-3.3-70b` - Fast and cost-effective

**Configuration:**
```json5
{
  agents: {
    "assistant": {
      model: {
        primary: "anthropic:claude-sonnet-4-6",
        fallbacks: ["openai:gpt-5.2"]
      }
    }
  }
}
```

### Long Context Analysis

**Best choices:**
1. `google:gemini-2.5-pro` - 1M context
2. `anthropic:claude-opus-4-6` - 200K context

**Configuration:**
```json5
{
  agents: {
    "analyst": {
      model: {
        primary: "google:gemini-2.5-pro",
        fallbacks: ["anthropic:claude-opus-4-6"]
      },
      maxTokens: 900000  // Use most of context window
    }
  }
}
```

### Fast Responses

**Best choices:**
1. `groq:llama-3.3-8b-instant` - Extremely fast
2. `anthropic:claude-haiku-4-5` - Fast and capable

**Configuration:**
```json5
{
  agents: {
    "responder": {
      model: {
        primary: "groq:llama-3.3-8b-instant",
        fallbacks: ["anthropic:claude-haiku-4-5"]
      }
    }
  }
}
```

### Multimodal (Vision/Audio)

**Best choices:**
1. `openai:gpt-4o` - Excellent vision
2. `google:gemini-2.5-pro` - Multimodal support
3. `anthropic:claude-opus-4-6` - Good vision

**Configuration:**
```json5
{
  agents: {
    "vision": {
      model: {
        primary: "openai:gpt-4o",
        fallbacks: ["google:gemini-2.5-pro"]
      }
    }
  }
}
```

## Fallback Configuration

Configure automatic fallback when models fail or hit rate limits:

```json5
{
  models: {
    providers: {
      anthropic: {
        apiKey: "${ANTHROPIC_API_KEY}",
        retryConfig: {
          maxRetries: 3,
          backoffMs: 1000,
          retryableErrors: [429, 500, 502, 503]
        }
      }
    },
    fallbacks: {
      enabled: true,
      strategy: "sequential",  // or "parallel", "cost-based"
      fallbacks: [
        {
          model: "anthropic:claude-opus-4-6",
          triggers: ["rate_limit", "error", "timeout"]
        },
        {
          model: "openai:gpt-5.2",
          triggers: ["rate_limit", "error"]
        },
        {
          model: "google:gemini-2.5-pro",
          triggers: ["rate_limit"]
        }
      ]
    }
  }
}
```

## Custom Provider Setup

Configure custom or self-hosted model providers:

```json5
{
  models: {
    providers: {
      "custom-llama": {
        baseUrl: "http://localhost:8000/v1",
        apiKey: "${CUSTOM_API_KEY}",  // Optional
        apiFormat: "openai",  // or "anthropic", "google", "custom"
        defaultModel: "llama-3.3-70b",
        headers: {
          "X-Custom-Header": "value"
        },
        catalog: {
          "llama-3.3-70b": {
            contextWindow: 128000,
            supportsStreaming: true,
            supportsTools: true
          }
        }
      }
    }
  }
}
```

### API Format Options

- `openai`: OpenAI-compatible API (v1/chat/completions)
- `anthropic`: Anthropic Messages API
- `google`: Google Gemini API
- `custom`: Custom request/response format (requires adapter)

## Cost Optimization

Strategies to reduce API costs:

### 1. Model Tiering

```json5
{
  agents: {
    "simple-tasks": {
      model: {
        primary: "anthropic:claude-haiku-4-5",  // Cheapest
        fallbacks: ["groq:llama-3.3-8b"]
      }
    },
    "complex-tasks": {
      model: {
        primary: "anthropic:claude-sonnet-4-6",  // Mid-tier
        fallbacks: ["anthropic:claude-opus-4-6"]  // Premium
      }
    }
  }
}
```

### 2. Context Management

```json5
{
  agents: {
    defaults: {
      maxTokens: 4000,  // Limit output tokens
      contextCompaction: {
        enabled: true,
        reserveTokens: 10000,  // Keep buffer
        strategy: "summarize"  // Summarize old messages
      }
    }
  }
}
```

### 3. Local Models for Testing

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://localhost:11434",
        defaultModel: "llama3.3"
      }
    }
  },
  agents: {
    "test-agent": {
      model: {
        primary: "ollama:llama3.3",  // Free local testing
        fallbacks: ["anthropic:claude-opus-4-6"]  // Fallback to cloud
      }
    }
  }
}
```

### 4. Response Caching

```json5
{
  models: {
    cache: {
      enabled: true,
      ttl: 3600,  // Cache for 1 hour
      maxSize: 1000  // Max cached responses
    }
  }
}
```

## Rate Limit Management

Handle rate limits across providers:

```json5
{
  models: {
    providers: {
      anthropic: {
        rateLimit: {
          requestsPerMinute: 50,
          tokensPerMinute: 40000,
          strategy: "retry-with-backoff"
        }
      },
      openai: {
        rateLimit: {
          requestsPerMinute: 100,
          tokensPerMinute: 150000,
          strategy: "retry-with-backoff"
        }
      }
    },
    globalRateLimit: {
      requestsPerSecond: 10,
      queueSize: 100
    }
  }
}
```

## Environment Variable Reference

Common environment variables for model providers:

```bash
# Anthropic
ANTHROPIC_API_KEY="sk-ant-xxx"

# OpenAI
OPENAI_API_KEY="sk-proj-xxx"

# Google
GOOGLE_API_KEY="AIzaSyxxx"

# Mistral
MISTRAL_API_KEY="xxx"

# xAI
XAI_API_KEY="xxx"

# OpenRouter
OPENROUTER_API_KEY="xxx"

# Groq
GROQ_API_KEY="xxx"

# Custom providers
CUSTOM_API_KEY="xxx"

# Gateway (for agent API calls)
GATEWAY_TOKEN="xxx"
```

## Testing Provider Configuration

Verify your provider setup:

```bash
# Test specific provider
openclaw models test anthropic

# Test all configured providers
openclaw models test --all

# List available models from provider
openclaw models list --provider anthropic

# Check model capabilities
openclaw models info anthropic:claude-opus-4-6
```

## Troubleshooting Model Providers

### 401 Authentication Errors

**Symptoms**: API returns 401 Unauthorized

**Diagnosis**:
```bash
# Verify .env file exists
ls -la ~/.openclaw/.env

# Check key format
cat ~/.openclaw/.env | grep API_KEY
```

**Resolution**:
- Verify API key is correct and not expired
- Check environment variable name matches provider
- Ensure `.env` file has correct permissions (600)
- Regenerate API key if needed

### 429 Rate Limit Errors

**Symptoms**: API returns 429 Too Many Requests

**Diagnosis**:
```bash
# Check rate limits in config
openclaw models info --provider anthropic
```

**Resolution**:
- Reduce request frequency
- Configure fallback providers
- Upgrade API tier for higher limits
- Enable automatic retries with backoff

### Context Length Exceeded

**Symptoms**: Error about context window or token limit

**Diagnosis**:
```bash
# Check model context window
openclaw models info anthropic:claude-opus-4-6

# Monitor token usage
openclaw logs --tokens --since "1h ago"
```

**Resolution**:
- Enable context compaction
- Reduce `maxTokens` setting
- Switch to model with larger context
- Clear old sessions

### Network/Timeout Errors

**Symptoms**: Requests timeout or fail to connect

**Diagnosis**:
```bash
# Test connectivity
curl -I https://api.anthropic.com

# Check DNS
nslookup api.anthropic.com
```

**Resolution**:
- Check internet connection
- Verify firewall allows API access
- Configure proxy if needed
- Increase timeout settings

## Next Steps

After configuring model providers:

1. **Test configuration**: `openclaw models test --all`
2. **Set up fallbacks**: Configure fallback chain for reliability
3. **Optimize costs**: Use appropriate models per task
4. **Monitor usage**: Track token usage and costs
5. **Secure keys**: Ensure API keys are in `.env` only

For more information:
- [security-checklist.md](./security-checklist.md) - API key security
- [troubleshooting.md](./troubleshooting.md) - Common issues
