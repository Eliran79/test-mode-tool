# Test Mode Tool Installation Guide

This guide covers installation of the Test Mode Tool defensive security system that prevents Claude Code from making destructive modifications during test analysis.

## Quick Start

### 1. Set Permissions
```bash
chmod +x .claude/hooks/*.sh
```

### 2. Install (Project-Level)
```bash
.claude/hooks/test_mode_setup.sh enable
```

### 3. Activate Test Mode
```bash
/project:test_mode:on
```

### 4. Run Tests Safely
```bash
# Claude will analyze tests without modifying files
npm test  # or mvn test, pytest, etc.
```

### 5. Deactivate
```bash
/project:test_mode:off
```

## Detailed Installation

### Project-Level Installation (Team Deployment)

This installs test mode for the entire team. Configuration is committed to source control.

#### Prerequisites
- Claude Code installed and configured
- Project with `.claude/` directory structure
- Write permissions to project directory

#### Installation Steps

1. **Verify directory structure**:
   ```bash
   ls .claude/
   # Should show: commands/ agents/ hooks/ logs/
   ```

2. **Set executable permissions**:
   ```bash
   chmod +x .claude/hooks/*.sh
   ```

3. **Run installation**:
   ```bash
   .claude/hooks/test_mode_setup.sh enable
   ```

4. **Verify installation**:
   ```bash
   .claude/hooks/test_mode_setup.sh validate
   ```

5. **Test basic functionality**:
   ```bash
   /project:test_mode:on
   /project:test_mode:status
   /project:test_mode:off
   ```

#### Team Collaboration Setup

1. **Add to source control**:
   ```bash
   git add .claude/commands/ .claude/agents/ .claude/hooks/
   git add .claude/hooks/README.md
   git commit -m "Add Test Mode Tool defensive security system"
   ```

2. **Add .gitignore entries**:
   ```bash
   echo ".claude/test-mode-active-*.json" >> .gitignore
   echo ".claude/logs/" >> .gitignore
   echo ".claude/settings.local.json" >> .gitignore
   git add .gitignore
   git commit -m "Update .gitignore for test mode"
   ```

3. **Team member setup**:
   ```bash
   git pull
   chmod +x .claude/hooks/*.sh
   # Test mode commands now available to all team members
   ```

### User-Level Installation (Personal Workflow)

This installs test mode for your personal use across all projects.

#### Prerequisites
- Claude Code installed with user directory: `~/.claude/`
- Write permissions to home directory

#### Installation Steps

1. **Create user directory structure**:
   ```bash
   mkdir -p ~/.claude/{commands/test_mode,agents,hooks,logs}
   ```

2. **Copy components**:
   ```bash
   cp .claude/commands/test_mode/*.md ~/.claude/commands/test_mode/
   cp .claude/agents/*.md ~/.claude/agents/
   cp .claude/hooks/*.sh ~/.claude/hooks/
   ```

3. **Set permissions**:
   ```bash
   chmod +x ~/.claude/hooks/*.sh
   ```

4. **Enable user-level hooks**:
   ```bash
   ~/.claude/hooks/test_mode_setup.sh enable --user
   ```

5. **Test user commands**:
   ```bash
   /user:test_mode:on
   /user:test_mode:status
   /user:test_mode:off
   ```

## Configuration

### Settings.json Integration

The installation script safely modifies your existing settings.json:

#### Before Installation
```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  },
  "env": {
    "MY_EXISTING_VAR": "value"
  }
}
```

#### After Installation
```json
{
  "hooks": {
    "PreToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit|Bash": [
        "./.claude/hooks/test_mode_pre_tool.sh"
      ]
    },
    "PostToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit|Bash": [
        "./.claude/hooks/test_mode_post_tool.sh"
      ]
    }
  },
  "permissions": {
    "defaultMode": "acceptEdits"
  },
  "env": {
    "MY_EXISTING_VAR": "value",
    "CLAUDE_TEST_MODE": "false",
    "CLAUDE_TEST_MODE_PROJECT": "",
    "CLAUDE_TEST_MODE_PATH": ""
  }
}
```

### Backup System

The installation script creates automatic backups:

```bash
.claude/settings.json.backup.20250821-143022
.claude/settings.json.backup.20250821-143115
# ... (up to 10 backups retained)
```

## Usage Guide

### Basic Test Mode Workflow

#### 1. Activate Test Mode
```bash
# Project-level (team shared)
/project:test_mode:on

# User-level (personal)
/user:test_mode:on

# With options
/project:test_mode:on --scope=backend --duration=1h --strict
```

#### 2. Run Tests
```bash
# Tests execute normally
npm test
mvn test
pytest
./gradlew test
cargo test
```

#### 3. Analyze Failures
When Claude encounters test failures, it will:
- ✅ Document the exact failure messages
- ✅ Investigate root causes by reading code
- ✅ Suggest specific fixes for human implementation
- ❌ NOT modify source code to make tests pass
- ❌ NOT change test expectations
- ❌ NOT add mocks to avoid real problems

#### 4. Review Findings
Claude uses TodoWrite to document findings:
```markdown
## Test Failure Analysis

### Failed Test: UserService.createUser
**Error**: NullPointerException at line 42
**Location**: src/test/java/UserServiceTest.java:42

### Root Cause Analysis:
The test expects a valid database connection but the test 
environment is not properly configured with test database URL.

### Recommended Fix:
1. Add test database configuration to application-test.yml
2. Ensure @TestPropertySource points to correct config
3. Verify test database is running and accessible

### Next Steps:
- [ ] Configure test database connection
- [ ] Update test environment setup
- [ ] Verify other tests don't have same issue
```

#### 5. Deactivate Test Mode
```bash
/project:test_mode:off
# or
/user:test_mode:off
```

### Advanced Usage

#### Scoped Test Mode
```bash
# Only affect backend code
/project:test_mode:on --scope=backend

# Only affect frontend code  
/project:test_mode:on --scope=frontend

# Affect entire codebase (default)
/project:test_mode:on --scope=all
```

#### Time-Limited Sessions
```bash
# Auto-deactivate after 30 minutes
/project:test_mode:on --duration=30m

# Auto-deactivate after 2 hours
/project:test_mode:on --duration=2h

# Manual deactivation only (default)
/project:test_mode:on
```

#### Strict Mode
```bash
# Enhanced validation and blocking
/project:test_mode:on --strict
```

### Multi-Project Scenarios

#### Scenario 1: Independent Projects
```bash
# Terminal 1: Project A
cd ~/projects/app-a
/project:test_mode:on
# Test mode active only for app-a

# Terminal 2: Project B
cd ~/projects/app-b  
/project:test_mode:on
# Test mode active only for app-b
# No interference with app-a
```

#### Scenario 2: Mixed Configurations
```bash
# User has personal test mode preferences
/user:test_mode:on

# Team project overrides with project-specific config
cd ~/projects/team-app
/project:test_mode:on
# Project-level takes precedence

# Personal projects still use user-level settings
cd ~/projects/personal-app
/user:test_mode:status
# User-level active again
```

## Monitoring and Logging

### Log Files

#### Security Events
```bash
tail -f .claude/logs/test-mode-security.log
```
Tracks:
- Blocked tool attempts
- Suspicious command patterns
- Cross-project access attempts
- Configuration manipulation attempts

#### Usage Analytics
```bash
tail -f .claude/logs/test-mode-usage.log
```
Tracks:
- Test mode activation/deactivation
- Session durations
- Most commonly blocked operations
- Project-specific usage patterns

#### Error Logs
```bash
tail -f .claude/logs/test-mode-error.log
```
Tracks:
- Hook execution failures
- Configuration errors
- Status file corruption
- Recovery operations

### Status Monitoring

#### Check Current Status
```bash
/project:test_mode:status
```

#### Validate Installation
```bash
.claude/hooks/test_mode_setup.sh validate
```

#### View All Active Sessions
```bash
ls .claude/test-mode-active-*.json
```

## Troubleshooting

### Common Issues

#### Issue: "Hook script not executable"
**Symptoms**: Commands don't work, no blocking occurs
**Solution**:
```bash
chmod +x .claude/hooks/*.sh
.claude/hooks/test_mode_setup.sh validate
```

#### Issue: "Status file mismatch"
**Symptoms**: Test mode seems active but tools aren't blocked
**Solution**:
```bash
.claude/hooks/test_mode_setup.sh cleanup
/project:test_mode:on  # Re-activate
```

#### Issue: "Settings.json corruption"
**Symptoms**: Claude Code errors, hooks don't load
**Solution**:
```bash
# Restore from latest backup
.claude/hooks/test_mode_setup.sh restore

# Or restore specific backup
cp .claude/settings.json.backup.20250821-143022 .claude/settings.json
```

#### Issue: "Cross-project interference"
**Symptoms**: Test mode affects wrong project
**Solution**:
```bash
# Validate project isolation
.claude/hooks/test_mode_setup.sh validate

# Clean up all stale files
.claude/hooks/test_mode_setup.sh cleanup --all
```

#### Issue: "Can't activate test mode"
**Symptoms**: Commands exist but activation fails
**Solution**:
```bash
# Check installation
.claude/hooks/test_mode_setup.sh validate

# Check permissions
ls -la .claude/hooks/
chmod +x .claude/hooks/*.sh

# Check for conflicting status
/project:test_mode:status
```

### Emergency Procedures

#### Complete System Reset
```bash
# Disable all hooks
.claude/hooks/test_mode_setup.sh disable --force

# Remove all status files
.claude/hooks/test_mode_setup.sh cleanup --all

# Restore original settings
.claude/hooks/test_mode_setup.sh restore

# Re-enable if desired
.claude/hooks/test_mode_setup.sh enable
```

#### Manual Recovery
```bash
# If hooks are completely broken:

# 1. Remove hooks from settings.json manually
jq 'del(.hooks)' .claude/settings.json > temp.json && mv temp.json .claude/settings.json

# 2. Remove all status files
rm .claude/test-mode-active-*.json

# 3. Clear environment variables
jq 'del(.env.CLAUDE_TEST_MODE) | del(.env.CLAUDE_TEST_MODE_PROJECT) | del(.env.CLAUDE_TEST_MODE_PATH)' .claude/settings.json > temp.json && mv temp.json .claude/settings.json

# 4. Restart Claude Code
```

## Security Considerations

### What Test Mode Protects Against

#### The "Never Give Up" Problem
- ❌ **Problem**: Test fails → Claude modifies source code to make it pass
- ✅ **Solution**: Test mode blocks all file modifications, forcing analysis instead

#### Common Destructive Workarounds
- ❌ **Problem**: Claude changes test expectations instead of fixing bugs
- ✅ **Solution**: Test files protected, original intent preserved

#### Configuration Simplification
- ❌ **Problem**: Complex config causes issues → Claude removes complexity
- ✅ **Solution**: Config files protected, real issues documented

#### Mock Substitution
- ❌ **Problem**: Real service test fails → Claude adds mocks
- ✅ **Solution**: Test modifications blocked, integration issues preserved

### Security Model

#### Input Validation
- All JSON inputs validated (size limits, syntax checking)
- All file paths validated (anti-traversal protection)
- All commands filtered (whitelist/blacklist approach)

#### Project Isolation
- Status files are project-specific
- Path validation prevents cross-project interference
- Environment variables include project identifiers

#### Atomic Operations
- All configuration changes are atomic
- Automatic backup creation before modifications
- Rollback capability on any failure

#### Monitoring
- Comprehensive security event logging
- Suspicious activity pattern detection
- No sensitive information in logs

### Threat Model

This system protects against:
- ✅ **Accidental destructive modifications** during test analysis
- ✅ **Scope creep** from testing into refactoring
- ✅ **Test integrity loss** through expectation changes
- ✅ **Configuration corruption** through simplification
- ✅ **Cross-project interference** through isolation

This system does NOT protect against:
- ❌ **Malicious users** with file system access
- ❌ **System-level attacks** outside Claude Code
- ❌ **Network-based attacks** (not applicable)

## Performance Impact

### Minimal Performance Overhead
- **Hook execution time**: < 10ms per tool call
- **Memory usage**: < 1MB for all components
- **Disk usage**: < 100KB for installation
- **Network impact**: None (all operations local)

### Scaling Characteristics
- **Project count**: No limit on number of projects
- **Team size**: Scales to any team size
- **Session duration**: No performance degradation over time
- **Log file growth**: Automatic rotation prevents unbounded growth

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Test Analysis with Test Mode
on: [pull_request]

jobs:
  test-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Test Mode
        run: |
          chmod +x .claude/hooks/*.sh
          .claude/hooks/test_mode_setup.sh enable
          
      - name: Activate Test Mode
        run: /project:test_mode:on --strict
        
      - name: Run Tests with Analysis
        run: npm test
        
      - name: Archive Test Analysis
        uses: actions/upload-artifact@v3
        with:
          name: test-analysis
          path: .claude/logs/
```

### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Setup Test Mode') {
            steps {
                sh 'chmod +x .claude/hooks/*.sh'
                sh '.claude/hooks/test_mode_setup.sh enable'
            }
        }
        stage('Test Analysis') {
            steps {
                sh '/project:test_mode:on --duration=1h'
                sh 'mvn test'
                sh '/project:test_mode:off'
            }
        }
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: '.claude/logs/*.log'
            }
        }
    }
}
```

This installation guide provides everything needed to deploy the Test Mode Tool defensive security system successfully.