# Test Mode Hook System

This directory contains the secure hook infrastructure for the Test Mode Tool defensive security system. These hooks prevent Claude Code from making destructive modifications during test analysis while maintaining complete project isolation.

## Hook Components

### Core Hook Scripts

#### `test_mode_pre_tool.sh`
**PreToolUse hook** that intercepts tool calls before execution:
- **Blocks destructive tools**: Edit, Write, MultiEdit, NotebookEdit when test mode is active
- **Filters bash commands**: Blocks dangerous commands (rm, mv, cp, >, >>) while allowing safe ones
- **Project validation**: Ensures operations occur in the correct project context
- **Security messages**: Provides clear violation messages with actionable guidance

#### `test_mode_post_tool.sh`  
**PostToolUse hook** for monitoring and logging:
- **Usage logging**: Tracks all hook activations and violations
- **Security monitoring**: Detects suspicious activity patterns
- **Analytics**: Collects metrics on test mode usage
- **Non-blocking**: Never interferes with normal tool execution

#### `test_mode_setup.sh`
**Installation and configuration script**:
- **Safe JSON modification**: Atomically modifies settings.json with backups
- **Hook management**: Enables/disables hooks securely
- **Project isolation**: Manages project-specific configurations
- **Cleanup operations**: Complete removal of test mode components

#### `hook_utils.sh`
**Shared security utilities**:
- **Input validation**: Comprehensive JSON and path validation
- **Security functions**: Anti-traversal protection and sanitization
- **Status management**: Project-isolated status file operations
- **Error handling**: Standardized error reporting and logging

## Security Architecture

### Multi-Layer Security Model

#### Layer 1: Input Validation
- **JSON size limits**: Maximum 32KB to prevent DoS attacks
- **Syntax validation**: Full JSON parsing before processing
- **Path validation**: Anti-traversal protection with length limits
- **Command filtering**: Whitelist/blacklist with pattern detection

#### Layer 2: Project Isolation  
- **Context validation**: Verify operations occur in correct project
- **Path matching**: Status files must match current working directory
- **Name validation**: Project names restricted to safe character sets
- **Stale file cleanup**: Automatic removal of mismatched status files

#### Layer 3: Atomic Operations
- **Backup creation**: Always backup before modifications
- **Temporary files**: Use atomic file replacement
- **Rollback capability**: Automatic recovery on failures
- **Validation**: Verify all changes before committing

#### Layer 4: Monitoring & Logging
- **Security events**: Log all violations and suspicious activity
- **Usage analytics**: Track patterns and metrics
- **Retention policies**: Automatic log rotation and cleanup
- **Non-sensitive logging**: Never log sensitive information

### Threat Model Protection

#### File System Attacks
- ✅ **Directory traversal**: Blocked by path validation
- ✅ **Symlink attacks**: Real path resolution required  
- ✅ **Permission escalation**: Minimal required permissions
- ✅ **Disk space attacks**: File size limits enforced

#### Command Injection
- ✅ **Shell injection**: Command patterns validated
- ✅ **Path injection**: All paths sanitized
- ✅ **JSON injection**: Strict parsing with size limits
- ✅ **Environment pollution**: Clean environment enforced

#### Logic Attacks
- ✅ **Race conditions**: Atomic operations with locking
- ✅ **State manipulation**: Status file integrity validation
- ✅ **Bypass attempts**: Multiple validation layers
- ✅ **Configuration corruption**: Backup and validation required

## Installation Guide

### Project-Level Installation (Team Deployment)

1. **Initialize directory structure** (already done):
   ```bash
   # Directory structure created:
   .claude/
   ├── commands/test_mode/    # Slash commands
   ├── agents/               # Specialized agents  
   ├── hooks/                # Security hooks
   └── logs/                 # Log files
   ```

2. **Set executable permissions**:
   ```bash
   chmod +x .claude/hooks/*.sh
   ```

3. **Enable test mode hooks**:
   ```bash
   .claude/hooks/test_mode_setup.sh enable
   ```

4. **Verify installation**:
   ```bash
   .claude/hooks/test_mode_setup.sh validate
   ```

### User-Level Installation (Personal Workflow)

1. **Create user directory structure**:
   ```bash
   mkdir -p ~/.claude/{commands/test_mode,agents,hooks,logs}
   ```

2. **Copy hook scripts to user directory**:
   ```bash
   cp .claude/hooks/*.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/*.sh
   ```

3. **Enable user-level hooks**:
   ```bash
   ~/.claude/hooks/test_mode_setup.sh enable --user
   ```

## Usage Instructions

### Activating Test Mode

#### Project-Level (Team)
```bash
# Activate test mode for current project
/project:test_mode:on [--scope=backend|frontend|all] [--duration=30m|1h|2h]

# Check status
/project:test_mode:status

# Deactivate
/project:test_mode:off
```

#### User-Level (Personal)  
```bash
# Activate personal test mode
/user:test_mode:on [--scope=backend|frontend|all] [--duration=30m|1h|2h]

# Check status  
/user:test_mode:status

# Deactivate
/user:test_mode:off
```

### What Happens When Test Mode is Active

#### Blocked Operations
- **File modifications**: Edit, Write, MultiEdit, NotebookEdit tools blocked
- **Dangerous bash commands**: rm, mv, cp, >, >>, chmod, chown blocked
- **Configuration changes**: Package installs and config modifications blocked

#### Allowed Operations
- **Read-only analysis**: Read, LS, Grep, Glob tools available
- **Test execution**: npm test, mvn test, pytest, etc. allowed
- **Safe bash commands**: git status, ls, find, grep, cat, head, tail
- **Documentation**: TodoWrite for capturing findings

#### Security Messages
When blocked operations are attempted:
```
🚫 PROJECT TEST MODE VIOLATION: Edit tool blocked!

Project: my-app (project-level)
Path: /path/to/my-app

💡 You are in test-only mode for this project. Focus on:
✅ Running tests and analyzing results
✅ Documenting findings specific to my-app
✅ Reading code and understanding problems

❌ File modifications blocked in this project:
❌ No source code changes
❌ No configuration updates  
❌ No test expectation changes

To exit: /project:test_mode:off

Other projects remain unaffected by this test mode.
Remember: Test failures are VALUABLE INFORMATION!
```

## Project Isolation

### How Isolation Works

#### Status Files
Each project gets its own status file:
```bash
.claude/test-mode-active-my-app.json          # Project: my-app
.claude/test-mode-active-api-service.json     # Project: api-service  
.claude/test-mode-active-user-my-app.json     # User-level for my-app
```

#### Path Validation
```bash
# Hooks verify project context
stored_project_path=$(cat "$status_file" | jq -r '.project_path')
current_path="$(pwd)"

if [[ "$stored_project_path" != "$current_path" ]]; then
    # Clean up stale status file and exit
    rm "$status_file"
    exit 0
fi
```

#### Environment Variables
```bash
# Project-specific environment
CLAUDE_TEST_MODE_PROJECT="my-app"
CLAUDE_TEST_MODE_PATH="/path/to/my-app"
CLAUDE_TEST_MODE_USER="username"
```

### Cross-Project Testing
```bash
# Developer working on multiple projects simultaneously

# Terminal 1: Project A
cd ~/projects/app-a && /project:test_mode:on

# Terminal 2: Project B  
cd ~/projects/app-b && /project:test_mode:on

# Terminal 3: Project C (no test mode)
cd ~/projects/app-c
# Normal development mode

# Each terminal has independent test mode state!
```

## Troubleshooting

### Common Issues

#### "Hook script not executable"
```bash
chmod +x .claude/hooks/*.sh
```

#### "Status file mismatch"
```bash
# Clean up stale status files
.claude/hooks/test_mode_setup.sh cleanup
```

#### "Settings.json corruption"
```bash
# Restore from backup
.claude/hooks/test_mode_setup.sh restore
```

#### "Cross-project interference"
```bash
# Validate project isolation
.claude/hooks/test_mode_setup.sh validate
```

### Emergency Procedures

#### Complete Disable
```bash
# Emergency disable all hooks
.claude/hooks/test_mode_setup.sh disable --force

# Remove all status files
.claude/hooks/test_mode_setup.sh cleanup --all
```

#### Configuration Reset
```bash
# Restore original settings
.claude/hooks/test_mode_setup.sh restore

# Validate configuration
.claude/hooks/test_mode_setup.sh validate
```

## Security Considerations

### File Permissions
- Hook scripts: `755` (executable by owner, readable by all)
- Status files: `644` (readable by owner and group)
- Log files: `640` (readable by owner and group only)

### Log Security
- No sensitive information logged (paths, commands yes; data no)
- Automatic log rotation (1MB max per file)
- Maximum 10 backup files retained
- Secure log file permissions

### Network Security
- No network operations performed by hooks
- All operations are local file system only
- No external dependencies or downloads

### Process Security
- Hooks run with minimal privileges
- Clean PATH environment enforced
- No privilege escalation possible
- Process isolation maintained

## Maintenance

### Regular Tasks

#### Log Cleanup
```bash
# Rotate logs manually
.claude/hooks/test_mode_setup.sh rotate-logs

# Clean old logs
find .claude/logs -name "*.log.*" -mtime +30 -delete
```

#### Status Validation
```bash
# Validate all status files weekly
.claude/hooks/test_mode_setup.sh validate --verbose
```

#### Backup Management
```bash
# Clean old backups (keep latest 5)
.claude/hooks/test_mode_setup.sh cleanup-backups
```

### Monitoring

#### Security Events
Monitor `.claude/logs/test-mode-security.log` for:
- Repeated violation attempts
- Unusual command patterns
- Cross-project access attempts
- Configuration manipulation attempts

#### Usage Metrics
Track `.claude/logs/test-mode-usage.log` for:
- Test mode activation frequency
- Average session duration
- Most blocked operations
- Project-specific usage patterns

This hook system provides enterprise-grade security for the Test Mode Tool while maintaining usability and complete project isolation.