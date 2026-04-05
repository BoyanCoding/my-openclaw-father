# Contributing to OpenClaw Father

Thank you for your interest in contributing to OpenClaw Father! This document provides guidelines and instructions for contributing to the project.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check existing issues to avoid duplicates
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Environment details (OS, OpenClaw version, etc.)
   - Relevant logs or error messages

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Write tests for new functionality
5. Ensure all tests pass: `npm test`
6. Commit your changes: `git commit -am 'Add my feature'`
7. Push to the branch: `git push origin feature/my-feature`
8. Create a Pull Request

**PR Guidelines**:
- Keep changes focused and atomic
- Write clear commit messages
- Update documentation as needed
- Follow existing code style
- Add tests for new features
- Ensure CI checks pass

## How to Add Knowledge

### Editing Existing Knowledge

Knowledge files are in the `knowledge/` directory:

```bash
knowledge/
├── agent-setup/
│   ├── install-procedure.md
│   └── generate-config.md
├── channels/
│   ├── slack.md
│   ├── discord.md
│   ├── matrix.md
│   └── whatsapp.md
├── security/
│   ├── security-checklist.md
│   └── dm-policy.md
├── providers/
│   └── model-providers.md
└── operations/
    ├── health-check.md
    └── troubleshooting.md
```

**To edit**:
1. Navigate to the appropriate subdirectory
2. Edit the markdown file
3. Follow the existing format and structure
4. Test changes locally
5. Submit a PR

**Format Requirements**:
- Use markdown (.md) format
- Include clear headings (H1, H2, H3)
- Add code examples with language specification
- Include troubleshooting section if applicable
- Link to related documentation

### Adding New Knowledge Files

1. Create the file in the appropriate `knowledge/` subdirectory
2. Follow the standard template:
```markdown
# Title

## Overview
Brief description of what this covers.

## Prerequisites
- Requirement 1
- Requirement 2

## Procedure
Step-by-step instructions with code examples.

## Troubleshooting
Common issues and solutions.

## Related
- Link to related docs
```

3. Update the sync script if needed (for new docs sources)
4. Update both OpenClaw agent and Claude Code skill to use the new knowledge
5. Add tests for knowledge retrieval

## How to Add a New Channel Guide

If you want to add support for a new communication channel:

1. **Create the channel guide**:
```bash
vim knowledge/channels/new-channel.md
```

2. **Include these sections**:
- Overview of the channel
- Prerequisites (accounts, tokens, permissions)
- Step-by-step setup instructions
- Configuration example for `openclaw.json`
- Troubleshooting common issues
- Example usage

3. **Update the agent**:
```javascript
// agent/skills/channel-setup.js
const supportedChannels = [
  'slack', 'discord', 'matrix', 'whatsapp', 'new-channel'
];

async function setupChannel(channelName) {
  const guidePath = `knowledge/channels/${channelName}.md`;
  // ... implementation
}
```

4. **Update the skill registry**:
```json
// openclaw.json
{
  "skills": [
    {
      "name": "channel-setup",
      "description": "Help set up communication channels",
      "channels": ["slack", "discord", "matrix", "whatsapp", "new-channel"]
    }
  ]
}
```

5. **Add tests**:
```javascript
// tests/channel-setup.test.js
describe('Channel Setup', () => {
  it('should provide guide for new-channel', async () => {
    const guide = await getChannelGuide('new-channel');
    expect(guide).toContain('# New Channel Setup');
  });
});
```

6. **Update documentation**:
- Add to architecture.md
- Update README.md with new channel
- Add to contributing.md

## How to Add a New Model Provider

To add support for a new AI model provider:

1. **Create provider documentation**:
```bash
vim knowledge/providers/new-provider.md
```

2. **Document the following**:
- Provider overview
- API key setup
- Configuration example
- Supported models
- Cost considerations
- Rate limits
- Example usage

3. **Update the provider guide**:
```bash
vim knowledge/providers/model-providers.md
# Add section for new provider
```

4. **Implement provider support** (if adding code):
```javascript
// agent/providers/new-provider.js
class NewProvider {
  constructor(config) {
    this.apiKey = config.apiKey;
    this.model = config.model || 'default-model';
  }

  async generate(messages, options) {
    // Implementation
  }
}
```

5. **Add tests**:
```javascript
// tests/providers/new-provider.test.js
describe('NewProvider', () => {
  it('should generate completion', async () => {
    const provider = new NewProvider({ apiKey: 'test-key' });
    const result = await provider.generate([]);
    expect(result).toBeDefined();
  });
});
```

## How to Add Troubleshooting Entries

To add troubleshooting information:

1. **Edit the troubleshooting guide**:
```bash
vim knowledge/operations/troubleshooting.md
```

2. **Add entries following this format**:
```markdown
### Problem: Error message
**Symptoms**: What the user experiences

**Cause**: Why it happens

**Solution**:
1. Step 1
2. Step 2
3. Step 3

**Prevention**: How to avoid it in the future
```

3. **Categorize problems**:
- Installation issues
- Configuration errors
- Channel connection problems
- API authentication failures
- Performance issues

4. **Add code examples** where helpful:
```bash
# Check if agent is running
pgrep -f "node.*agent/index.js"

# View agent logs
tail -f /var/log/openclaw-father/agent.log

# Test API connectivity
curl -I https://api.anthropic.com/v1/models
```

## How to Add Lessons to the Seed File

The seed file contains pre-populated lessons that the agent starts with:

1. **Edit the seed file**:
```bash
vim knowledge/schemas/lessons-seed.json
```

2. **Add lessons following the schema**:
```json
{
  "id": "lesson-unique-id",
  "problem": "Clear description of the problem",
  "solution": "Clear description of the solution",
  "context": {
    "platform": "ubuntu-22.04",
    "openclaw_version": "1.2.0",
    "channel": "slack",
    "tags": ["installation", "permissions"]
  },
  "tags": ["slack", "permissions", "troubleshooting"],
  "timestamp": "2026-04-05T10:00:00Z",
  "verified": true,
  "source": "community"
}
```

3. **Guidelines for lessons**:
- **Be specific**: Clear problem and solution
- **Be generalizable**: Don't include specific hostnames, IPs, or tokens
- **Add context**: Platform, version, channel
- **Use tags**: Help categorize and search
- **Verify**: Test the solution before adding
- **Credit**: Note the source if from community contribution

4. **Example lesson**:
```json
{
  "id": "lesson-slack-scope-001",
  "problem": "Slack bot fails to post messages with error 'missing_scope'",
  "solution": "Add 'chat:write' OAuth scope to the Slack app configuration and reinstall the bot to the workspace",
  "context": {
    "platform": "any",
    "openclaw_version": "1.0.0",
    "channel": "slack"
  },
  "tags": ["slack", "permissions", "oauth", "scopes"],
  "timestamp": "2026-04-05T10:00:00Z",
  "verified": true,
  "source": "core-team"
}
```

## PR Process

### Before Submitting

1. **Run tests locally**:
```bash
npm test
```

2. **Check code style**:
```bash
npm run lint
```

3. **Build the project**:
```bash
npm run build
```

4. **Test knowledge sync**:
```bash
npm run sync-knowledge
```

### After Submitting

1. **CI Checks**:
   - All tests must pass
   - Linting must pass
   - Build must succeed
   - Knowledge sync must complete cleanly

2. **Code Review**:
   - Address reviewer feedback
   - Make requested changes
   - Push updates to the branch

3. **Merge**:
   - Wait for approval
   - Squash commits if requested
   - Delete branch after merge

### Knowledge Sync Validation

For PRs that modify `knowledge/` files:

1. **Verify sync script works**:
```bash
./scripts/sync-knowledge.sh
```

2. **Check that files are copied correctly**:
```bash
diff -r knowledge/ claude-code/references/
```

3. **Ensure version tracker updates**:
```bash
cat version-tracker.json
# Verify hashes match
```

4. **Test both formats**:
```bash
# Test OpenClaw agent
node test-agent.js

# Test Claude Code skill
npm test -- --skill
```

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

**Positive behavior includes**:
- Being respectful and considerate
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes**:
- Harassment or discriminatory language
- Personal attacks or insulting comments
- Public or private harassment
- Publishing others' private information
- Unprofessional conduct
- Trolling or disrespectful commentary

### Responsibilities

Project maintainers are responsible for clarifying standards of acceptable behavior and will take appropriate and fair corrective action in response to any instances of unacceptable behavior.

### Scope

This Code of Conduct applies both within project spaces and in public spaces when an individual is representing the project or its community.

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team. All complaints will be reviewed and investigated and will result in a response that is deemed necessary and appropriate to the circumstances.

## Development Setup

### Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/yourusername/openclaw-father.git
cd openclaw-father

# Add upstream remote
git remote add upstream https://github.com/original/openclaw-father.git
```

### Install Dependencies

```bash
npm install
```

### Run Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- channel-setup.test.js
```

### Development Mode

```bash
# Run with hot reload
npm run dev

# Run with debug output
DEBUG=openclaw-father:* npm start
```

### Build for Production

```bash
npm run build
```

## Documentation Standards

### Code Comments

- Use JSDoc for JavaScript functions
- Explain complex logic
- Note any workarounds or hacks
- Keep comments up to date with code changes

```javascript
/**
 * Sets up a communication channel for the OpenClaw agent
 * @param {string} channelName - The name of the channel (slack, discord, etc.)
 * @param {Object} config - Channel configuration object
 * @returns {Promise<Object>} Setup result with status and message
 * @throws {Error} If channel is not supported or configuration is invalid
 */
async function setupChannel(channelName, config) {
  // Implementation
}
```

### README Files

- Keep README.md up to date
- Include installation instructions
- Document configuration options
- Provide usage examples
- List contributing guidelines

### API Documentation

- Document all public APIs
- Provide usage examples
- Note parameter types and return values
- Include error conditions

## Testing Guidelines

### Unit Tests

- Test individual functions and modules
- Mock external dependencies
- Cover edge cases
- Test error conditions

```javascript
describe('setupChannel', () => {
  it('should setup Slack channel with valid config', async () => {
    const config = { botToken: 'xoxb-test' };
    const result = await setupChannel('slack', config);
    expect(result.success).toBe(true);
  });

  it('should throw error for unsupported channel', async () => {
    await expect(
      setupChannel('unsupported', {})
    ).rejects.toThrow('Unsupported channel');
  });
});
```

### Integration Tests

- Test multiple components working together
- Use test fixtures for consistency
- Clean up after tests
- Test real-world scenarios

```javascript
describe('Agent Integration', () => {
  let agent;

  beforeEach(() => {
    agent = createTestAgent();
  });

  afterEach(() => {
    agent.cleanup();
  });

  it('should process install command end-to-end', async () => {
    const response = await agent.process('install');
    expect(response).toContain('Installation complete');
  });
});
```

### Knowledge Tests

- Verify knowledge files are valid markdown
- Test knowledge retrieval
- Check for broken links
- Validate JSON schemas

```javascript
describe('Knowledge Base', () => {
  it('should retrieve Slack guide', async () => {
    const guide = await getKnowledge('channels/slack');
    expect(guide).toContain('# Slack Setup');
  });

  it('should validate lessons schema', () => {
    const lessons = require('../knowledge/schemas/lessons-learned.json');
    expect(() => validateLessons(lessons)).not.toThrow();
  });
});
```

## Release Process

### Version Bumping

- Follow semantic versioning (MAJOR.MINOR.PATCH)
- MAJOR: Breaking changes
- MINOR: New features (backwards compatible)
- PATCH: Bug fixes

### Changelog

Update CHANGELOG.md with:
- Version number
- Release date
- Added features
- Fixed bugs
- Breaking changes

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version bumped in package.json
- [ ] Git tag created
- [ ] Release published to GitHub
- [ ] npm package published (if applicable)

## License

By contributing to OpenClaw Father, you agree that your contributions will be licensed under the **MIT License**.

### MIT License Summary

- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ❗ Liability and warranty disclaimed
- ⚠️ Must include license and copyright notice

### Copyright Notice

When adding new files, include the license header:

```javascript
/**
 * OpenClaw Father - Mentor Agent for OpenClaw
 * 
 * Copyright (c) 2026 Your Name
 * Licensed under the MIT License
 */
```

## Getting Help

If you need help contributing:

1. **Read the documentation**: Check existing docs first
2. **Search issues**: Someone may have asked before
3. **Join discussions**: GitHub Discussions for questions
4. **Ask maintainers**: Open an issue for help
5. **Check community**: Discord, Slack, or other community channels

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in relevant documentation
- Invited to become maintainers for significant contributions

Thank you for contributing to OpenClaw Father!
