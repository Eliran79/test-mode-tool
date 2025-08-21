# Test Mode Commands

This directory contains project-level test mode commands for Claude Code. These commands enable a defensive security mode that prevents Claude from making destructive modifications during test analysis.

## Available Commands

### `/project:test_mode:on`
Activates test mode for THIS PROJECT ONLY. Blocks file modifications and enables read-only test analysis.

**Usage:**
```bash
/project:test_mode:on [--scope=backend|frontend|all] [--duration=30m|1h|2h] [--strict]
```

**Options:**
- `--scope`: Limit test mode to specific parts of the codebase
- `--duration`: Auto-deactivate after specified time
- `--strict`: Enable stricter validation and blocking

### `/project:test_mode:off`
Deactivates test mode and restores normal file modification permissions.

**Usage:**
```bash
/project:test_mode:off
```

### `/project:test_mode:status`
Check current test mode status and display active restrictions.

**Usage:**
```bash
/project:test_mode:status
```

## How Test Mode Works

1. **File Modification Blocking**: Hooks prevent Edit, Write, MultiEdit, and risky Bash commands
2. **Project Isolation**: Each project maintains independent test mode state
3. **Specialized Agents**: Switches to test-mode-observer agent for read-only analysis
4. **Status Tracking**: Project-specific status files prevent cross-project interference

## When to Use Test Mode

- **Code Reviews**: Analyze test failures without accidentally fixing them
- **Test Investigation**: Deep dive into failing tests while preserving their diagnostic value
- **Regression Analysis**: Understand what broke without making workaround changes
- **Architecture Analysis**: Use test failures to identify design issues

## Project Isolation

These commands only affect the current project. Other projects remain unaffected:
- Status files are project-specific: `.claude/test-mode-active-{project-name}.json`
- Hooks validate project context before taking action
- Settings changes are local to this project directory

## Team Usage

This configuration is committed to source control, so all team members have access to consistent test mode behavior. Team members can activate test mode independently without affecting each other's work in other projects.

## Security

Test mode is a defensive security feature designed to:
- Prevent destructive AI workarounds during testing
- Preserve test failure information as valuable diagnostic data
- Enforce read-only analysis of test results
- Maintain test integrity by preventing expectation changes

For more information, see the main project documentation.