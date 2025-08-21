# Test Mode Sub-Agents

This directory contains specialized sub-agents for test mode operations. These agents are designed to work within the constraints of test mode, focusing on analysis and documentation rather than modification.

## Available Agents

### test-mode-observer.md
The core test mode agent that:
- Executes tests and analyzes failures
- Investigates root causes without making modifications
- Documents findings in detailed reports
- Suggests specific fixes for human implementation
- **Tools**: Read, LS, Grep, Glob, Bash, TodoWrite (NO Edit/Write tools)

**Use when**: You need to analyze test failures while in test mode

### test-reporter.md  
Specialized reporting agent that:
- Generates comprehensive test session reports
- Identifies patterns across multiple test failures
- Creates stakeholder-appropriate summaries
- Tracks metrics and trends over time
- **Tools**: Read, LS, Grep, Glob, TodoWrite (read-only operations only)

**Use when**: You need detailed reports and analysis summaries

## Agent Activation

These agents are automatically available when test mode is active. The test-mode-observer is the primary agent used during test mode sessions.

### Switching to Test Mode Observer
```bash
# This happens automatically when test mode is activated
# Manual activation if needed:
Task: Switch to test-mode-observer sub-agent for test analysis
```

### Using Test Reporter
```bash
# For comprehensive reporting after test sessions:
Task: Use test-reporter agent to generate session summary
```

## Agent Constraints

All test mode agents operate under strict constraints:

### ✅ Allowed Operations
- Read files and analyze code
- Execute tests and capture output
- Search and grep through codebase
- Document findings via TodoWrite
- Generate reports and summaries

### ❌ Forbidden Operations  
- Edit, Write, or MultiEdit any files
- Modify test expectations or assertions
- Change configuration files
- Install packages or dependencies
- Create workarounds or mocks

## Security Model

These agents are designed as defensive security tools:
- **Preserve Test Intent**: Don't change what tests are trying to validate
- **Document Issues**: Capture problems for human resolution
- **No Workarounds**: Resist urge to "fix" by avoiding real problems
- **Information Focus**: Treat test failures as valuable diagnostic data

## Integration with Test Mode

When test mode is active:
1. File modification tools are blocked by hooks
2. test-mode-observer becomes the primary active agent
3. All analysis is done in read-only mode
4. Findings are documented for human developers

This ensures that test failures remain as valuable diagnostic information rather than problems to be automatically "fixed" through workarounds.