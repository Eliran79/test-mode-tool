# Test Mode Tool for Claude Code
## Preventing the "Never Give Up" Problem

> **Inspiration:** Based on the VibeTDD experiments discovery that Claude Code's "never give up" behavior leads to destructive workarounds instead of proper error reporting.

## Problem Statement

Claude Code, when encountering test failures, will:
- Modify source code to make tests pass instead of reporting issues
- Change test expectations (`shouldThrow` → `shouldNotThrow`)
- Add mocks to avoid real implementation challenges
- Refactor working code to "fix" test problems

**Solution:** Use Claude Code's native hooks, custom slash commands, and sub-agents to create a test mode that enforces read-only behavior.

## Implementation Strategy

### Two Deployment Options with Isolation

#### Option A: Project-Level (Recommended for Teams)
- Commands: `/project:test_mode:*` - Only affects current project
- Configuration stored in `.claude/` (committed to source control)
- Status tracking per-project to prevent interference
- Team can collaborate on test mode configurations

#### Option B: User-Level (Personal Workflow)
- Commands: `/user:test_mode:*` - Available across all projects for this user
- Configuration stored in `~/.claude/` (personal settings)
- Project-specific status tracking to avoid conflicts
- Individual developer productivity tool

### Three-Layer Protection System

1. **Custom Slash Commands** - User-friendly interface with project isolation
2. **Hooks System** - Block file modification tools with project-aware checks
3. **Test-Mode Sub-Agent** - Specialized agent with limited tool access

### Tool Overview

```bash
# Project-level (team shared)
/project:test_mode:on [--scope=backend] [--duration=30m]
/project:test_mode:off  
/project:test_mode:status

# User-level (personal across all projects)
/user:test_mode:on [--scope=backend] [--duration=30m]
/user:test_mode:off
/user:test_mode:status
```

### Cross-Project Isolation Strategy

1. **Project-Specific Status Files**: Each project tracks its own test mode state
2. **Directory-Aware Hooks**: Hooks verify they're running in the correct project context
3. **Scoped Environment Variables**: Include project identifier in env vars
4. **Separate Log Files**: Per-project logging to prevent data mixing
5. **Precedence Rules**: Clear hierarchy when both user and project configs exist

## Implementation Plan

## Implementation Plan

### Phase 1A: Project-Level Commands (Team Deployment)

#### /create .claude/commands/test_mode/
Create the test mode command structure in the project (committed to source control):

```
.claude/commands/test_mode/
├── on.md              # /project:test_mode:on command
├── off.md             # /project:test_mode:off command
├── status.md          # /project:test_mode:status command
└── README.md          # Team documentation
```

#### /create .claude/commands/test_mode/on.md
```markdown
---
name: test_mode_on
description: "Activate test mode for THIS PROJECT ONLY - blocks file modifications and enables test-only agent"
tools: "Read,LS,Grep,Glob,Task,Bash"
---

# Project Test Mode Activation

You are activating TEST MODE for **THIS PROJECT ONLY**. 

**ISOLATION CHECK**: Verify this is the correct project by checking the project root.

## Project Context Verification
```bash
echo "Activating test mode for project: $(basename $(pwd))"
echo "Project root: $(pwd)"
```

## Arguments Processing
Process the arguments: $ARGUMENTS

Arguments format: [--scope=backend|frontend|all] [--duration=30m|1h|2h] [--strict]

## Activation Steps

1. **Verify project isolation** - Ensure we're in the right directory
2. **Update PROJECT settings** (.claude/settings.json in current project)
3. **Create PROJECT-specific status file** (.claude/test-mode-active-$(basename $(pwd)).json)
4. **Enable PROJECT-scoped hooks** with directory validation
5. **Switch to test mode sub-agent** for this project only

## Project-Specific Status File
Create status file with project identifier:
```json
{
  "project_name": "$(basename $(pwd))",
  "project_path": "$(pwd)",
  "active": true,
  "scope": "$SCOPE",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "project-level"
}
```

## Context for Future Interactions

```
🔒 PROJECT TEST MODE ACTIVE 🔒
Project: $(basename $(pwd))

You are now in PROJECT-SPECIFIC TEST MODE.
File modifications are BLOCKED for this project only.
Other projects remain unaffected.

When tests fail:
✅ Document what failed and why  
✅ Analyze root causes specific to this project
✅ Suggest fixes for human review
❌ Don't modify code to make tests pass
❌ Don't change test expectations

Remember: Test failures are VALUABLE INFORMATION!
```

Execute: .claude/hooks/test_mode_setup.sh enable "$SCOPE" "$DURATION" "$STRICT" "$(pwd)"
```

### Phase 1B: User-Level Commands (Personal Workflow)

#### /create ~/.claude/commands/test_mode/
Create user-level commands (not committed, personal settings):

```
~/.claude/commands/test_mode/
├── on.md              # /user:test_mode:on command  
├── off.md             # /user:test_mode:off command
├── status.md          # /user:test_mode:status command
└── README.md          # Personal documentation
```

#### /create ~/.claude/commands/test_mode/on.md
```markdown
---
name: test_mode_on
description: "Activate user-level test mode - applies to current project with user preferences"
tools: "Read,LS,Grep,Glob,Task,Bash"
---

# User-Level Test Mode Activation

You are activating YOUR PERSONAL test mode for the current project.

**PROJECT ISOLATION**: This affects only the current working directory.

## Project Context Detection
```bash
PROJECT_NAME="$(basename $(pwd))"
PROJECT_PATH="$(pwd)"
echo "Activating user test mode for: $PROJECT_NAME"
echo "Location: $PROJECT_PATH"
```

## User-Level Configuration
- Uses your personal preferences from ~/.claude/settings.json
- Creates project-specific status in current directory  
- Applies your personal test mode sub-agent configurations
- Isolated from other projects you're working on

## Status File with Project Isolation
Create: `.claude/test-mode-active-user-$PROJECT_NAME.json`

```json
{
  "project_name": "$PROJECT_NAME",
  "project_path": "$PROJECT_PATH", 
  "active": true,
  "scope": "$SCOPE",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "user-level",
  "user": "$(whoami)"
}
```

## Isolation Verification
Before activation, verify:
1. No conflicting project-level test mode active
2. Current directory is a valid project root
3. User has appropriate permissions

Execute user test mode setup with project isolation.
```

#### /create .claude/commands/test_mode/off.md
```markdown
---
name: test_mode_off
description: "Deactivate test mode and restore normal file modification permissions"
---

# Test Mode Deactivation

You are deactivating TEST MODE for this project.

## Deactivation Steps

1. **Restore Claude Code settings** - Remove test mode hooks
2. **Remove test mode status file** (.claude/test-mode-active.json)
3. **Return to main Claude agent** (exit sub-agent if active)
4. **Display deactivation confirmation**

## Restoration Actions

1. Remove or comment out the test mode hooks from `.claude/settings.json`
2. Delete `.claude/test-mode-active.json` if it exists
3. Confirm normal file modification permissions are restored

## Success Message

Display when complete:
```
✅ TEST MODE DEACTIVATED ✅

Normal file modification permissions restored.
You can now:
- Edit source files
- Write new files
- Modify configurations
- Make changes to fix issues

Ready for normal development mode!
```

Now restore normal development capabilities.
```

#### /create .claude/commands/test_mode/status.md
```markdown
---
name: test_mode_status  
description: "Check current test mode status and display restrictions"
---

# Test Mode Status Check

Check if test mode is currently active for this project.

## Status Check Steps

1. **Check for test mode status file** (.claude/test-mode-active.json)
2. **Verify hooks configuration** in .claude/settings.json
3. **Display current mode and restrictions**

## Status Display

If test mode is ACTIVE, show:
```
🔒 TEST MODE ACTIVE

Status: ACTIVE
Scope: [scope from status file]
Started: [timestamp from status file]  
Expires: [expiration if set]

CURRENT RESTRICTIONS:
❌ File modifications blocked (Edit, Write, MultiEdit)
❌ Configuration changes blocked
✅ Test execution allowed
✅ Read-only analysis allowed
✅ Documentation updates allowed

To exit: /project:test_mode:off
```

If test mode is INACTIVE, show:
```
🔓 TEST MODE INACTIVE

Status: INACTIVE
All file modification permissions available.

To activate: /project:test_mode:on
```

## Quick Health Check

Also verify:
- Are test mode hooks properly configured?
- Is the test-mode-observer sub-agent available?
- Any recent violations logged?

Display any issues found.
```

### Phase 2: Project-Isolated Hooks Configuration

#### /create .claude/hooks/test_mode_pre_tool.sh (Project-Level)
```bash
#!/bin/bash
# Project-Isolated Test Mode PreToolUse Hook

# Read JSON input from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# PROJECT ISOLATION: Verify we're in the correct project
current_project="$(basename $(pwd))"
project_path="$(pwd)"

# Check if test mode is active for THIS PROJECT
project_status_file=".claude/test-mode-active-${current_project}.json"
user_status_file=".claude/test-mode-active-user-${current_project}.json"

# Determine which test mode is active (precedence: project > user)
active_status_file=""
if [[ -f "$project_status_file" ]]; then
    active_status_file="$project_status_file"
    test_mode_type="project-level"
elif [[ -f "$user_status_file" ]]; then
    active_status_file="$user_status_file"
    test_mode_type="user-level"
else
    # No test mode active for this project
    exit 0
fi

# Verify the status file matches current project
stored_project_path=$(cat "$active_status_file" | jq -r '.project_path // empty')
if [[ "$stored_project_path" != "$project_path" ]]; then
    echo "⚠️ Test mode status file project mismatch - cleaning up stale status"
    rm "$active_status_file"
    exit 0
fi

# Read test mode configuration for this project
test_mode_config=$(cat "$active_status_file")
scope=$(echo "$test_mode_config" | jq -r '.scope // "all"')
strict_mode=$(echo "$test_mode_config" | jq -r '.strict // false')

# Tools that modify files (BLOCKED in test mode)
blocked_tools=("Edit" "Write" "MultiEdit" "NotebookEdit")

# Check if current tool is blocked
for blocked_tool in "${blocked_tools[@]}"; do
    if [[ "$tool_name" == "$blocked_tool" ]]; then
        # Tool is blocked, return project-specific blocking response
        cat << EOF
{
    "decision": "block",
    "reason": "🚫 PROJECT TEST MODE VIOLATION: $tool_name tool blocked!\n\nProject: $current_project ($test_mode_type)\nPath: $project_path\n\n💡 You are in test-only mode for this project. Focus on:\n✅ Running tests and analyzing results\n✅ Documenting findings specific to $current_project\n✅ Reading code and understanding problems\n\n❌ File modifications blocked in this project:\n❌ No source code changes\n❌ No configuration updates\n❌ No test expectation changes\n\nTo exit: /$test_mode_type:test_mode:off\n\nOther projects remain unaffected by this test mode.\nRemember: Test failures are VALUABLE INFORMATION!"
}
EOF
        exit 0
    fi
done

# Special handling for Bash tool - project-specific restrictions
if [[ "$tool_name" == "Bash" ]]; then
    bash_command=$(echo "$input" | jq -r '.tool_input.command // empty')
    
    # List of risky bash commands that could modify files
    risky_commands=("rm" "mv" "cp" ">" ">>" "chmod" "chown" "mkdir" "rmdir" "touch" "dd" "tee")
    
    for risky in "${risky_commands[@]}"; do
        if [[ "$bash_command" == *"$risky"* ]]; then
            cat << EOF
{
    "decision": "block", 
    "reason": "🚫 PROJECT TEST MODE VIOLATION: Bash command '$bash_command' could modify files in project $current_project!\n\n✅ Allowed bash commands in test mode:\n- git status, git log, git diff\n- ls, find, grep, cat, head, tail\n- mvn test, npm test, pytest\n- ps, top, df, du (monitoring)\n\n❌ Blocked commands in $current_project:\n- File operations: rm, mv, cp, touch\n- Directory operations: mkdir, rmdir\n- Permission changes: chmod, chown\n- Output redirection: >, >>\n\nTo exit: /$test_mode_type:test_mode:off\nOther projects remain unaffected."
}
EOF
            exit 0
        fi
    done
fi

# Tool is allowed, continue normally
exit 0
```

#### /create ~/.claude/hooks/test_mode_pre_tool.sh (User-Level)
```bash
#!/bin/bash
# User-Level Test Mode PreToolUse Hook with Project Isolation

# Read JSON input from stdin
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

# PROJECT ISOLATION: Check current project context
current_project="$(basename $(pwd))"
project_path="$(pwd)"

# Only check for user-level test mode status
user_status_file=".claude/test-mode-active-user-${current_project}.json"

if [[ ! -f "$user_status_file" ]]; then
    # No user-level test mode active for this project
    exit 0
fi

# Verify project path matches to prevent stale status files
stored_project_path=$(cat "$user_status_file" | jq -r '.project_path // empty')
if [[ "$stored_project_path" != "$project_path" ]]; then
    echo "⚠️ Cleaning up stale user test mode status for different project path"
    rm "$user_status_file"
    exit 0
fi

# Check if project-level test mode takes precedence
if [[ -f ".claude/test-mode-active-${current_project}.json" ]]; then
    # Project-level test mode takes precedence, skip user-level
    exit 0
fi

# Continue with user-level test mode logic (same blocking logic as project-level)
# ... [rest of blocking logic identical to project version]
```

#### /create .claude/hooks/test_mode_setup.sh (Enhanced with Isolation)
```bash
#!/bin/bash
# Test Mode Setup Script with Project Isolation

setup_test_mode_hooks() {
    local action="$1"        # "enable" or "disable"
    local scope="$2"         # "all", "backend", "frontend"
    local duration="$3"      # "30m", "1h", etc.
    local strict="$4"        # "true" or "false"
    local project_path="$5"  # Full path to project (for isolation)
    
    local project_name="$(basename "$project_path")"
    local settings_file=".claude/settings.json"
    
    # Create settings file if it doesn't exist
    if [[ ! -f "$settings_file" ]]; then
        echo "{}" > "$settings_file"
    fi
    
    if [[ "$action" == "enable" ]]; then
        echo "🔒 Enabling test mode for project: $project_name"
        echo "📁 Project path: $project_path"
        
        # Add project-specific test mode hooks to settings
        jq --arg project_name "$project_name" \
           '.hooks.PreToolUse."Edit|Write|MultiEdit|NotebookEdit|Bash" = ["./claude/hooks/test_mode_pre_tool.sh"] |
            .hooks.PostToolUse."Edit|Write|MultiEdit|NotebookEdit|Bash" = ["./claude/hooks/test_mode_post_tool.sh"] |
            .env.CLAUDE_TEST_MODE = "true" |
            .env.CLAUDE_TEST_MODE_PROJECT = $project_name |
            .env.CLAUDE_TEST_MODE_PATH = "'$project_path'"' \
            "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"
        
        echo "✅ Project-specific test mode hooks enabled in $settings_file"
        
    elif [[ "$action" == "disable" ]]; then
        echo "🔓 Disabling test mode for project: $project_name"
        
        # Remove test mode hooks from settings
        jq 'del(.hooks.PreToolUse."Edit|Write|MultiEdit|NotebookEdit|Bash") |
            del(.hooks.PostToolUse."Edit|Write|MultiEdit|NotebookEdit|Bash") |
            .env.CLAUDE_TEST_MODE = "false" |
            del(.env.CLAUDE_TEST_MODE_PROJECT) |
            del(.env.CLAUDE_TEST_MODE_PATH)' \
            "$settings_file" > "$settings_file.tmp" && mv "$settings_file.tmp" "$settings_file"
        
        echo "✅ Test mode hooks disabled for project: $project_name"
    fi
}

# Create project-specific test mode status file
create_test_mode_status() {
    local scope="$1"
    local duration="$2"
    local strict="$3"
    local project_path="$4"
    local mode_type="$5"  # "project-level" or "user-level"
    
    local project_name="$(basename "$project_path")"
    local status_file
    
    if [[ "$mode_type" == "project-level" ]]; then
        status_file=".claude/test-mode-active-${project_name}.json"
    else
        status_file=".claude/test-mode-active-user-${project_name}.json"
    fi
    
    local expires_at=""
    if [[ -n "$duration" ]]; then
        expires_at=$(date -u -d "+$duration" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
    fi
    
    cat > "$status_file" << EOF
{
    "project_name": "$project_name",
    "project_path": "$project_path",
    "active": true,
    "scope": "$scope",
    "strict": $strict,
    "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "expires_at": "$expires_at",
    "type": "$mode_type",
    "version": "1.0.0"
}
EOF
    
    echo "✅ Project-isolated test mode status file created: $status_file"
}

# Remove project-specific test mode status file
remove_test_mode_status() {
    local project_path="$1"
    local mode_type="$2"
    
    local project_name="$(basename "$project_path")"
    local status_file
    
    if [[ "$mode_type" == "project-level" ]]; then
        status_file=".claude/test-mode-active-${project_name}.json"
    else
        status_file=".claude/test-mode-active-user-${project_name}.json"
    fi
    
    if [[ -f "$status_file" ]]; then
        rm "$status_file"
        echo "✅ Project-specific test mode status file removed: $status_file"
    fi
}

# Cleanup stale status files (for maintenance)
cleanup_stale_status_files() {
    local current_path="$(pwd)"
    
    # Find all test mode status files and verify they match current project
    for status_file in .claude/test-mode-active-*.json; do
        if [[ -f "$status_file" ]]; then
            stored_path=$(cat "$status_file" | jq -r '.project_path // empty')
            if [[ "$stored_path" != "$current_path" ]]; then
                echo "🧹 Removing stale status file: $status_file (points to $stored_path)"
                rm "$status_file"
            fi
        fi
    done
}

# Main script logic with project isolation
case "$1" in
    "enable")
        cleanup_stale_status_files
        setup_test_mode_hooks enable "${2:-all}" "${3:-}" "${4:-false}" "${5:-$(pwd)}"
        create_test_mode_status "${2:-all}" "${3:-}" "${4:-false}" "${5:-$(pwd)}" "project-level"
        ;;
    "disable")
        setup_test_mode_hooks disable "${2:-all}" "${3:-}" "${4:-false}" "${5:-$(pwd)}"
        remove_test_mode_status "${5:-$(pwd)}" "project-level"
        ;;
    "cleanup")
        cleanup_stale_status_files
        ;;
    *)
        echo "Usage: $0 {enable|disable|cleanup} [scope] [duration] [strict] [project_path]"
        exit 1
        ;;
esac
```

## Project Isolation & Precedence Rules

### Decision Guide: Project vs User Level

#### Use Project-Level When:
- **Team Development**: Multiple developers need consistent test mode behavior
- **Code Reviews**: Enforcing test-only analysis during review process  
- **CI/CD Integration**: Automated test mode activation in pipelines
- **Shared Standards**: Organization wants consistent test mode configuration
- **Repository-Specific Rules**: Different projects need different test mode behaviors

#### Use User-Level When:
- **Personal Workflow**: Individual developer productivity enhancement
- **Consistent Personal Preferences**: Same test mode behavior across all projects
- **Quick Setup**: Don't want to configure each project individually
- **Experimentation**: Testing test mode functionality before team adoption

### Precedence Rules (No Interference)

1. **Project-Level Takes Priority**: If both exist, project-level test mode overrides user-level
2. **Project-Specific Status**: Each project tracks its own test mode state independently
3. **Isolated Configurations**: User settings don't affect projects with project-level configs
4. **Directory-Scoped**: Test mode only affects the current project directory
5. **Clean Separation**: Switching between projects automatically switches test mode context

### Cross-Project Isolation Mechanisms

#### 1. Project-Specific Status Files
```bash
# Each project gets its own status file
.claude/test-mode-active-myapp.json          # Project: myapp
.claude/test-mode-active-api-service.json    # Project: api-service
.claude/test-mode-active-user-myapp.json     # User-level for myapp
.claude/test-mode-active-user-frontend.json  # User-level for frontend
```

#### 2. Directory Validation in Hooks
```bash
# Hooks verify they're operating on the correct project
stored_project_path=$(cat "$status_file" | jq -r '.project_path')
current_path="$(pwd)"

if [[ "$stored_project_path" != "$current_path" ]]; then
    # Clean up stale status file and exit
    rm "$status_file"
    exit 0
fi
```

#### 3. Project-Scoped Environment Variables
```bash
# Environment variables include project identifier
CLAUDE_TEST_MODE_PROJECT="myapp"
CLAUDE_TEST_MODE_PATH="/home/user/projects/myapp"
CLAUDE_TEST_MODE_USER="john.doe"
```

#### 4. Separate Log Files per Project
```bash
# Each project maintains separate logs
.claude/logs/test-mode-myapp-20250821-143022.log
.claude/logs/test-mode-api-service-20250821-143115.log
```

### Configuration Examples

#### Project-Level Setup (Committed to Repo)
```json
// .claude/settings.json (committed)
{
  "hooks": {
    "PreToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit|Bash": ["./claude/hooks/test_mode_pre_tool.sh"]
    }
  },
  "permissions": {
    "defaultMode": "acceptEdits"
  },
  "env": {
    "CLAUDE_TEST_MODE": "false",
    "CLAUDE_TEST_MODE_PROJECT": "myapp"
  }
}
```

#### User-Level Setup (Personal Settings)
```json
// ~/.claude/settings.json (not committed)
{
  "hooks": {
    "PreToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit|Bash": ["~/.claude/hooks/test_mode_pre_tool.sh"]
    }
  },
  "env": {
    "CLAUDE_TEST_MODE_USER_ENABLED": "true",
    "CLAUDE_TEST_MODE_USER_STRICT": "false"
  }
}
```

### Conflict Resolution

#### When Both Project and User Configs Exist:
1. **Hooks**: Project-level hooks take precedence
2. **Status**: Project-level status file checked first
3. **Settings**: Project settings override user settings
4. **Commands**: Both `/project:test_mode:*` and `/user:test_mode:*` available
5. **Clean Deactivation**: Deactivating one doesn't affect the other

#### Example Conflict Scenario:
```bash
# User has user-level test mode active
/user:test_mode:on

# Team member activates project-level test mode  
/project:test_mode:on

# Result: Project-level takes precedence
# User-level remains configured but inactive for this project
# Other projects still use user-level settings

# Deactivating project-level returns to user-level
/project:test_mode:off  # Now user-level is active again
```

#### /create .claude/agents/
Directory for project sub-agents:

```
.claude/agents/
├── test-mode-observer.md     # Specialized test mode agent
├── test-reporter.md          # Focused on test result analysis
└── README.md                 # Sub-agent documentation
```

#### /create .claude/agents/test-mode-observer.md
```markdown
---
name: test-mode-observer
description: "Specialized agent for test mode - focuses ONLY on test execution and analysis without any file modifications. MUST BE USED when test mode is active. Proactively analyzes test failures and documents findings."
tools: Read,LS,Grep,Glob,Bash,TodoWrite
---

# Test Mode Observer Agent

You are a specialized test analysis agent operating in **TEST MODE**. Your purpose is to execute tests, analyze failures, and document findings WITHOUT making any code modifications.

## Core Responsibilities

### ✅ PRIMARY FUNCTIONS:
1. **Execute Tests**: Run test suites and analyze results
2. **Investigate Failures**: Deep dive into test failures to understand root causes  
3. **Document Findings**: Create detailed reports of issues discovered
4. **Suggest Solutions**: Propose fixes for human developers to implement
5. **Monitor Test Health**: Track test execution patterns and success rates

### ❌ STRICTLY FORBIDDEN:
- **NO FILE MODIFICATIONS**: Never use Edit, Write, or MultiEdit tools
- **NO TEST CHANGES**: Don't modify test expectations to make them pass
- **NO WORKAROUNDS**: Don't add mocks to avoid configuration issues
- **NO SOURCE FIXES**: Don't change source code to make tests pass

## Behavioral Guidelines

### When Tests Fail:
1. **Document the failure** - Capture exact error messages and stack traces
2. **Analyze root cause** - Investigate why the test is failing  
3. **Suggest specific fixes** - Propose exact changes needed (for human to implement)
4. **Identify patterns** - Look for related failures or systemic issues

### Investigation Techniques:
- Read source code to understand expected behavior
- Examine test setup and configuration files
- Check dependencies and environment requirements  
- Review recent changes that might have caused failures
- Look for missing files, incorrect paths, or configuration issues

### Reporting Format:
When documenting findings, use this structure:

```markdown
## Test Failure Analysis

### Failed Test: [test name]
**Error**: [exact error message]
**Location**: [file:line number]

### Root Cause Analysis:
[Detailed explanation of why the test failed]

### Recommended Fix:
[Specific code changes needed]

### Impact Assessment:  
[How this affects other tests/functionality]

### Next Steps:
- [ ] [Specific action 1]
- [ ] [Specific action 2]
```

## Test Execution Strategy

### Preferred Test Commands:
- `mvn test` - Maven projects
- `npm test` - Node.js projects  
- `pytest` - Python projects
- `./gradlew test` - Gradle projects
- `cargo test` - Rust projects

### Read-Only Investigation Commands:
- `git status` - Check repository state
- `git log --oneline -10` - Recent changes
- `find . -name "*.test.*"` - Locate test files
- `grep -r "error\|fail" logs/` - Search for error patterns
- `ls -la target/` - Check build artifacts

## Continuous Improvement

After each test session:
1. **Update TodoWrite** with findings and recommendations
2. **Identify recurring issues** that need architectural attention
3. **Suggest process improvements** for future test runs
4. **Document lessons learned** about the codebase

## Emergency Protocol

If you encounter a situation where you feel compelled to modify files:
1. **STOP immediately**
2. **Document the temptation** - What made you want to modify files?
3. **Explain the issue** to the human developer
4. **Suggest they exit test mode** if modifications are truly necessary

Remember: Your value comes from providing accurate, detailed analysis - not from "fixing" things. Test failures are information, not problems to hide.
```

#### /create .claude/agents/test-reporter.md
```markdown
---
name: test-reporter
description: "Generates comprehensive test reports and analysis summaries from test mode sessions. Use when you need detailed reporting of test results and findings."
tools: Read,LS,Grep,Glob,TodoWrite
---

# Test Reporter Agent

You are specialized in creating comprehensive test analysis reports from test mode sessions.

## Report Generation

### Test Session Summary Report:
- Overall test execution statistics
- Failure patterns and trends  
- Root cause analysis summary
- Recommended actions prioritized by impact
- Codebase health assessment

### Individual Test Analysis:
- Detailed failure investigation
- Code quality observations
- Performance bottlenecks identified
- Architecture issues discovered

### Format:
Generate reports in markdown format suitable for:
- Developer handoff documentation
- Team standup summaries  
- Project status updates
- Technical debt tracking

## Key Metrics to Track:
- Test pass/fail rates by module
- Time to diagnose issues
- Recurring failure patterns  
- Configuration vs. logic issues
- Test coverage gaps identified

Focus on actionable insights rather than just listing failures.
```

### Phase 4: Settings Integration

#### /create .claude/settings.json
Configuration file that integrates all test mode components:

```json
{
  "hooks": {
    "PreToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit": [
        "./claude/hooks/test_mode_pre_tool.sh"
      ],
      "Bash": [
        "./claude/hooks/test_mode_pre_tool.sh"  
      ]
    },
    "PostToolUse": {
      "Edit|Write|MultiEdit|NotebookEdit|Bash": [
        "./claude/hooks/test_mode_post_tool.sh"
      ]
    }
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read",
      "LS", 
      "Grep",
      "Glob",
      "Task",
      "Bash(git status:*)",
      "Bash(mvn test:*)",
      "Bash(npm test:*)", 
      "Bash(pytest:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)"
    ],
    "deny": [
      "Edit(*)",
      "Write(*)", 
      "MultiEdit(*)",
      "NotebookEdit(*)"
    ]
  },
  "env": {
    "CLAUDE_TEST_MODE": "false",
    "CLAUDE_TEST_MODE_SCOPE": "all"
  }
}
```

#### /create .claude/settings.local.json
Local-only settings that don't get committed to source control:

```json
{
  "env": {
    "CLAUDE_TEST_MODE_DEBUG": "true",
    "CLAUDE_TEST_MODE_LOG_LEVEL": "info"
  }
}
```

### Phase 5: Enhanced Command Integration

#### /create .claude/commands/test_mode/activate.sh
Enhanced activation script that ties everything together:

```bash
#!/bin/bash
# Test Mode Activation Script - Called by /project:test_mode:on

SCOPE="${1:-all}"
DURATION="${2:-}"
STRICT="${3:-false}"

echo "🔒 Activating Test Mode..."

# Step 1: Enable hooks
.claude/hooks/test_mode_setup.sh enable "$SCOPE" "$DURATION" "$STRICT"

# Step 2: Update environment variables
if command -v jq >/dev/null 2>&1; then
    # Update settings.json environment variables
    jq '.env.CLAUDE_TEST_MODE = "true" | 
        .env.CLAUDE_TEST_MODE_SCOPE = "'$SCOPE'" |
        .env.CLAUDE_TEST_MODE_STRICT = "'$STRICT'"' \
        .claude/settings.json > .claude/settings.json.tmp && \
        mv .claude/settings.json.tmp .claude/settings.json
fi

# Step 3: Display activation banner
cat << EOF

🔒 TEST MODE ACTIVATED 🔒

Configuration:
- Scope: $SCOPE
- Strict Mode: $STRICT
$([ -n "$DURATION" ] && echo "- Duration: $DURATION")

RESTRICTIONS NOW ACTIVE:
❌ Edit, Write, MultiEdit tools BLOCKED
❌ Risky bash commands BLOCKED  
❌ File modifications prevented by hooks
✅ Test execution ALLOWED
✅ Read-only analysis ALLOWED
✅ Documentation updates ALLOWED

The test-mode-observer sub-agent is now available for specialized test analysis.

To exit test mode: /project:test_mode:off

Remember: Test failures are VALUABLE INFORMATION, not problems to fix!

EOF

# Step 4: Switch to test mode sub-agent (if not already active)
echo "Switching to test-mode-observer sub-agent..."
echo "Use 'Task: Switch to test-mode-observer sub-agent for test analysis' in your next prompt."
```

#### /create .claude/commands/test_mode/deactivate.sh
Deactivation script that cleans up all components:

```bash
#!/bin/bash
# Test Mode Deactivation Script

echo "🔓 Deactivating Test Mode..."

# Step 1: Disable hooks
.claude/hooks/test_mode_setup.sh disable

# Step 2: Reset environment variables
if command -v jq >/dev/null 2>&1; then
    jq '.env.CLAUDE_TEST_MODE = "false" | 
        del(.env.CLAUDE_TEST_MODE_SCOPE) |
        del(.env.CLAUDE_TEST_MODE_STRICT)' \
        .claude/settings.json > .claude/settings.json.tmp && \
        mv .claude/settings.json.tmp .claude/settings.json
fi

# Step 3: Archive test mode logs (optional)
if [[ -f ".claude/test-mode-usage.log" ]]; then
    mkdir -p .claude/logs/
    mv .claude/test-mode-usage.log ".claude/logs/test-mode-$(date +%Y%m%d-%H%M%S).log"
    echo "📊 Test mode usage log archived"
fi

# Step 4: Display deactivation confirmation
cat << EOF

✅ TEST MODE DEACTIVATED ✅

Normal development mode restored:
✅ All file modification tools available
✅ No command restrictions
✅ Full Claude Code functionality  

You can now:
- Edit source files
- Write new files  
- Modify configurations
- Use all available tools

Ready for normal development!

EOF
```

## Usage Examples & Isolation in Practice

### Basic Workflows (Project Isolation)

#### Project-Level Workflow (Team Setting)
```bash
# Developer A in project "myapp"
cd ~/projects/myapp
/project:test_mode:on --scope=backend

# This only affects myapp project
# Status file: .claude/test-mode-active-myapp.json
# Other projects unaffected

# Developer A switches to different project
cd ~/projects/api-service
/project:test_mode:status
# Output: "🔓 TEST MODE INACTIVE" (different project)

# Developer B working on same myapp project
cd ~/projects/myapp
/project:test_mode:status  
# Output: "🔒 TEST MODE ACTIVE" (shared project state)
```

#### User-Level Workflow (Personal Setting)
```bash
# Developer working across multiple projects
cd ~/projects/frontend-app
/user:test_mode:on --duration=1h

# Switch to different project - test mode follows
cd ~/projects/backend-api  
/user:test_mode:status
# Output: "🔒 TEST MODE ACTIVE" (user preference applied)

# But only to projects without project-level config
cd ~/projects/team-project  # has .claude/commands/test_mode/
/user:test_mode:status
# Output: "🔓 TEST MODE INACTIVE" (project-level takes precedence)
```

### Advanced Isolation Scenarios

#### Scenario 1: Developer with Mixed Configurations
```bash
# Developer has user-level test mode as default
~/.claude/commands/test_mode/on.md exists

# Working on personal project
cd ~/personal/side-project
/user:test_mode:on  # Uses personal preferences

# Switch to team project 
cd ~/work/team-app
/project:test_mode:on  # Uses team configuration
# Both are active simultaneously but in different projects!

# Check status in each project:
cd ~/personal/side-project && /user:test_mode:status    # ACTIVE
cd ~/work/team-app && /project:test_mode:status         # ACTIVE
```

#### Scenario 2: Project Override Behavior
```bash
# Team project with strict test mode requirements
cd ~/projects/critical-app
/project:test_mode:on --strict

# Developer also has user-level preferences
/user:test_mode:on  # This gets ignored due to precedence

# Verification:
/project:test_mode:status  # Shows: "🔒 PROJECT TEST MODE ACTIVE"
/user:test_mode:status     # Shows: "🔓 USER TEST MODE INACTIVE (project override)"

# Edit attempt gets blocked with project-specific message:
# "🚫 PROJECT TEST MODE VIOLATION: Edit tool blocked!
#  Project: critical-app (project-level)"
```

#### Scenario 3: Cross-Project Development
```bash
# Developer working on 3 projects simultaneously

# Terminal 1: Personal project
cd ~/personal/blog && /user:test_mode:on

# Terminal 2: Team project A  
cd ~/work/app-a && /project:test_mode:on --scope=backend

# Terminal 3: Team project B (no test mode)
cd ~/work/app-b
# Normal development mode

# Each terminal has independent test mode state:
# Terminal 1: User-level test mode active
# Terminal 2: Project-level test mode active  
# Terminal 3: No test mode restrictions

# No interference between projects!
```

### Team Deployment Examples

#### Setting Up Team Configuration
```bash
# Team lead sets up project-level test mode
cd ~/team-project
/create .claude/commands/test_mode/
# Configure team-specific commands

# Commit to repository
git add .claude/
git commit -m "Add test mode configuration for team"
git push

# Team members pull changes
git pull
# Now /project:test_mode:* commands are available to everyone
```

#### Individual Developer Onboarding  
```bash
# New team member joins
git clone https://github.com/company/app.git
cd app

# Test mode is immediately available (project-level)
/project:test_mode:status  # Available without setup

# Developer also wants personal test mode for other projects
/create ~/.claude/commands/test_mode/
# Configure personal commands

# Now has both options:
# /project:test_mode:* for team projects
# /user:test_mode:* for personal projects
```

### CI/CD Integration with Isolation

#### Multi-Project CI Pipeline
```yaml
# .github/workflows/test-analysis.yml
name: Test Analysis
on: [pull_request]

jobs:
  test-mode-analysis:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        project: [frontend, backend, api]
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Activate Project Test Mode
        run: |
          cd ${{ matrix.project }}
          echo "Activating test mode for project: ${{ matrix.project }}"
          /project:test_mode:on --scope=all --strict
          
      - name: Run Tests with Analysis
        run: |
          cd ${{ matrix.project }}  
          # Each project analyzed independently
          # No cross-project interference
          
      - name: Archive Results  
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.project }}
          path: ${{ matrix.project }}/.claude/logs/
```

### Build Tool Integration (Project-Specific)

#### Maven with Project Isolation
```xml
<!-- pom.xml in specific project -->
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>exec-maven-plugin</artifactId>
    <executions>
        <execution>
            <id>activate-project-test-mode</id>
            <phase>test</phase>
            <configuration>
                <executable>bash</executable>
                <arguments>
                    <argument>-c</argument>
                    <argument>
                        echo "Project: $(basename $(pwd))";
                        echo "Activate: /project:test_mode:on --scope=backend"
                    </argument>
                </arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```

#### Package.json per Project
```json
{
  "name": "frontend-app",
  "scripts": {
    "test:ai": "echo 'Project: frontend-app' && echo 'Activate: /project:test_mode:on --scope=frontend' && npm test",
    "test:ai-user": "echo 'Activate: /user:test_mode:on' && npm test"
  }
}
```

### Monitoring with Project Context

#### OpenTelemetry with Project Isolation
```bash
# Each project gets tagged independently
export OTEL_RESOURCE_ATTRIBUTES="project=$(basename $(pwd)),team=backend,test_mode_level=project"

# Metrics are automatically segmented by project:
# claude_code.test_mode.violation.count{project="myapp"}
# claude_code.test_mode.violation.count{project="api-service"}  
# claude_code.test_mode.violation.count{project="frontend"}
```

#### Monitoring Dashboard Configuration
```yaml
# Grafana dashboard for test mode usage
panels:
  - title: "Test Mode Violations by Project"
    query: |
      rate(claude_code_test_mode_violations_total[5m]) 
      by (project, test_mode_level)
    
  - title: "Active Test Mode Sessions"
    query: |
      claude_code_test_mode_active_sessions 
      by (project, user, test_mode_level)
```

This isolation system ensures that:
- ✅ **No cross-project interference** - Each project maintains independent test mode state
- ✅ **Team consistency** - Project-level configs ensure team members have same experience  
- ✅ **Personal flexibility** - User-level configs work for personal projects
- ✅ **Clear precedence** - Project-level always overrides user-level when both exist
- ✅ **Easy switching** - Moving between projects automatically switches test mode context
- ✅ **Clean separation** - Activating/deactivating in one project doesn't affect others

## Scenarios This Tool Defends Against

### 1. Test Failure Workarounds
**Problem:** Test fails → Claude changes source code to make it pass  
**Defense:** `PreToolUse` hook blocks `Edit`/`Write` tools with clear explanation

**Example:**
```bash
# Claude tries: Edit src/UserService.java
# Hook responds: 
🚫 TEST MODE VIOLATION: Edit tool blocked in test mode!
Focus on documenting the test failure instead of fixing code.
```

### 2. Configuration "Simplification"  
**Problem:** Complex config causes issues → Claude removes complexity  
**Defense:** Config files protected by edit tool blocking + bash command filtering

**Example:**
```bash
# Claude tries: Write application.yml  
# Hook blocks and suggests: "Document the configuration issue for human review"
```

### 3. Mock Substitution
**Problem:** Real database test fails → Claude adds mocks  
**Defense:** Test files protected in strict mode, sub-agent focused on analysis

**Example:**
```bash  
# Claude in test-mode-observer can't modify test files
# Instead generates: "Test requires real database - recommend setting up test DB"
```

### 4. Scope Creep During Testing
**Problem:** Test phase expands into refactoring session  
**Defense:** File modification tools completely blocked, only test execution allowed

### 5. Architecture Modifications
**Problem:** Test reveals design issue → Claude starts architectural changes  
**Defense:** All structural files protected, forces documentation via TodoWrite

### 6. Dependency Changes  
**Problem:** Test needs new library → Claude modifies package.json/pom.xml  
**Defense:** Build files blocked, test-mode-observer documents dependency needs

## Implementation Commands

### /create Project-Level Setup (Team Deployment)
```bash
# Create project-specific structure (committed to repo)
mkdir -p .claude/commands/test_mode
mkdir -p .claude/agents  
mkdir -p .claude/hooks
mkdir -p .claude/logs

# Create project-specific gitignore entries
echo ".claude/settings.local.json" >> .gitignore
echo ".claude/test-mode-active-*.json" >> .gitignore  
echo ".claude/logs/test-mode-*.log" >> .gitignore

echo "✅ Created project-level test mode structure"
```

### /create User-Level Setup (Personal Workflow)
```bash
# Create user-level structure (not committed)
mkdir -p ~/.claude/commands/test_mode
mkdir -p ~/.claude/agents
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/logs

# Create personal settings if not exists
if [[ ! -f ~/.claude/settings.json ]]; then
    echo '{"hooks": {}, "env": {}}' > ~/.claude/settings.json
fi

echo "✅ Created user-level test mode structure"
```

### /run Test Project Isolation
Test that projects don't interfere with each other:

```bash
echo "🧪 Testing cross-project isolation..."

# Create test projects
mkdir -p /tmp/test-project-a /tmp/test-project-b
cd /tmp/test-project-a
echo "console.log('project-a');" > app.js

cd /tmp/test-project-b  
echo "console.log('project-b');" > app.js

# Test isolation
cd /tmp/test-project-a
echo "Project A: $(basename $(pwd)) at $(pwd)"
# Simulate: /project:test_mode:on
touch .claude/test-mode-active-test-project-a.json

cd /tmp/test-project-b
echo "Project B: $(basename $(pwd)) at $(pwd)"
# Should be independent
if [[ ! -f ".claude/test-mode-active-test-project-a.json" ]]; then
    echo "✅ Project isolation working - no cross-project status files"
else
    echo "❌ Project isolation failed - status file leaked"
fi

# Cleanup
rm -rf /tmp/test-project-a /tmp/test-project-b
echo "✅ Project isolation test completed"
```

### /run Test Precedence Rules
```bash
echo "🧪 Testing precedence rules..."

# Set up test scenario
PROJECT_NAME="test-precedence-$(date +%s)"
mkdir -p "/tmp/$PROJECT_NAME"
cd "/tmp/$PROJECT_NAME"

# Create project-level config
mkdir -p .claude/commands/test_mode
echo "project-level config" > .claude/commands/test_mode/on.md

# Create user-level config  
mkdir -p ~/.claude/commands/test_mode
echo "user-level config" > ~/.claude/commands/test_mode/on.md

# Test precedence logic
echo "Project dir: $(pwd)"
echo "Project name: $PROJECT_NAME"

# Simulate checking for project-level first
if [[ -f ".claude/commands/test_mode/on.md" ]]; then
    echo "✅ Project-level config found - takes precedence"
    CONFIG_LEVEL="project"
elif [[ -f ~/.claude/commands/test_mode/on.md ]]; then
    echo "✅ User-level config found - used as fallback"
    CONFIG_LEVEL="user"
fi

echo "Selected config level: $CONFIG_LEVEL"

# Cleanup
cd /tmp && rm -rf "$PROJECT_NAME"
echo "✅ Precedence test completed"
```

### /run Verify Hook Isolation
```bash
echo "🧪 Testing hook isolation..."

# Test that hooks verify project context
PROJECT_PATH="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

echo "Testing hook isolation for project: $PROJECT_NAME"
echo "Project path: $PROJECT_PATH"

# Create test status file
cat > ".claude/test-mode-active-${PROJECT_NAME}.json" << EOF
{
    "project_name": "$PROJECT_NAME",
    "project_path": "$PROJECT_PATH",
    "active": true,
    "type": "project-level"
}
EOF

# Test hook logic (simulate)
STORED_PATH=$(cat ".claude/test-mode-active-${PROJECT_NAME}.json" | jq -r '.project_path')

if [[ "$STORED_PATH" == "$PROJECT_PATH" ]]; then
    echo "✅ Hook isolation working - paths match"
else
    echo "❌ Hook isolation failed - path mismatch"
    echo "  Expected: $PROJECT_PATH"
    echo "  Got: $STORED_PATH"
fi

# Test stale file detection (simulate different path)
cat > ".claude/test-mode-active-stale.json" << EOF
{
    "project_name": "stale-project",
    "project_path": "/some/other/path",
    "active": true
}
EOF

STALE_PATH=$(cat ".claude/test-mode-active-stale.json" | jq -r '.project_path')
if [[ "$STALE_PATH" != "$PROJECT_PATH" ]]; then
    echo "✅ Stale file detected - would be cleaned up"
    rm ".claude/test-mode-active-stale.json"
else
    echo "❌ Stale file detection failed"
fi

# Cleanup
rm ".claude/test-mode-active-${PROJECT_NAME}.json"
echo "✅ Hook isolation test completed"
```

### /run Configure Team Sharing (Project-Level)
```bash
echo "🔧 Configuring team sharing..."

# Ensure we're in a git repository
if [[ ! -d ".git" ]]; then
    echo "⚠️ Not in a git repository. Initialize first:"
    echo "  git init"
    echo "  git remote add origin <repo-url>"
    exit 1
fi

# Add team configuration to source control
git add .claude/commands/ .claude/agents/ .claude/hooks/
git add .claude/settings.json

# Don't commit local status files
echo ".claude/test-mode-active-*.json" >> .gitignore
echo ".claude/logs/" >> .gitignore
git add .gitignore

# Commit team configuration
git commit -m "Add isolated test mode configuration for team

- Project-level test mode commands
- Isolated hooks with project validation  
- Test-mode-observer sub-agent
- Cross-project interference prevention"

echo "✅ Team configuration committed"
echo "🚀 Team members can now use /project:test_mode:* commands"
```

### /run Configure Personal Settings (User-Level)
```bash
echo "🔧 Configuring personal test mode..."

# Set up user-level configuration
USER_CONFIG="$HOME/.claude/settings.json"

# Add user-level test mode configuration
if [[ -f "$USER_CONFIG" ]]; then
    # Merge with existing config
    jq '.env.CLAUDE_TEST_MODE_USER_ENABLED = "true" |
        .env.CLAUDE_TEST_MODE_USER_PREFERENCE = "standard"' \
        "$USER_CONFIG" > "${USER_CONFIG}.tmp" && \
        mv "${USER_CONFIG}.tmp" "$USER_CONFIG"
else
    # Create new config
    cat > "$USER_CONFIG" << 'EOF'
{
  "env": {
    "CLAUDE_TEST_MODE_USER_ENABLED": "true",
    "CLAUDE_TEST_MODE_USER_PREFERENCE": "standard"
  },
  "hooks": {},
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
EOF
fi

echo "✅ Personal test mode configured"
echo "🚀 You can now use /user:test_mode:* commands across all projects"
echo "💡 Project-level configs will still take precedence when they exist"
```

### /run End-to-End Isolation Test
```bash
echo "🧪 Running comprehensive isolation test..."

# Test complete workflow with multiple projects
TEST_ROOT="/tmp/claude-test-mode-isolation"
mkdir -p "$TEST_ROOT"

# Create 3 test projects
for project in project-a project-b project-c; do
    PROJECT_DIR="$TEST_ROOT/$project"
    mkdir -p "$PROJECT_DIR/.claude/commands/test_mode"
    cd "$PROJECT_DIR"
    
    echo "Testing project: $project"
    
    # Create project-specific test file
    echo "console.log('$project');" > app.js
    
    # Simulate test mode activation
    cat > ".claude/test-mode-active-$project.json" << EOF
{
    "project_name": "$project",
    "project_path": "$PROJECT_DIR",
    "active": true,
    "scope": "all",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "type": "project-level"
}
EOF
    
    echo "✅ Project $project: test mode status created"
done

# Verify isolation between projects
cd "$TEST_ROOT/project-a"
PROJECT_A_STATUS=$(ls .claude/test-mode-active-*.json 2>/dev/null | wc -l)

cd "$TEST_ROOT/project-b"  
PROJECT_B_STATUS=$(ls .claude/test-mode-active-*.json 2>/dev/null | wc -l)

cd "$TEST_ROOT/project-c"
PROJECT_C_STATUS=$(ls .claude/test-mode-active-*.json 2>/dev/null | wc -l)

if [[ "$PROJECT_A_STATUS" -eq 1 && "$PROJECT_B_STATUS" -eq 1 && "$PROJECT_C_STATUS" -eq 1 ]]; then
    echo "✅ Perfect isolation: Each project has exactly 1 status file"
else
    echo "❌ Isolation failed: Status file counts: A=$PROJECT_A_STATUS, B=$PROJECT_B_STATUS, C=$PROJECT_C_STATUS"
fi

# Test cross-directory status checking
cd "$TEST_ROOT/project-a"
if [[ ! -f ".claude/test-mode-active-project-b.json" ]]; then
    echo "✅ No cross-project status file leakage"
else
    echo "❌ Cross-project status file found in wrong directory"
fi

# Cleanup
rm -rf "$TEST_ROOT"
echo "✅ End-to-end isolation test completed successfully"
```

## Future Enhancements

### Multi-Project Coordination
- **Shared test mode state** across related repositories
- **Cross-project test dependencies** managed through test mode
- **Organization-wide test mode policies** via enterprise managed settings

### Advanced Sub-Agents
- **Performance Test Analyzer** - Specialized for load/stress test analysis
- **Security Test Auditor** - Focused on security test results and vulnerabilities
- **Integration Test Coordinator** - Manages complex multi-service test scenarios

### IDE Integration
- **VS Code Extension** - Visual indicators for test mode status in editor
- **IntelliJ Plugin** - Test mode controls integrated with IDE testing tools
- **Real-time Violation Notifications** - Desktop alerts for test mode violations

### AI Training Integration
- **Violation Pattern Analysis** - ML analysis of common test mode violations
- **Behavioral Training Data** - Generate training examples for better AI testing behavior
- **Reinforcement Learning Signals** - Reward good test analysis, penalize fix attempts

### Enterprise Features
- **Centralized Test Mode Dashboard** - Organization-wide view of test mode usage
- **Policy Enforcement** - Automatic test mode activation for critical code reviews
- **Compliance Reporting** - Track test mode usage for audit purposes
- **Custom Rule Engine** - Define organization-specific test mode restrictions

## Success Metrics

This tool will be successful if it:

### 1. **Reduces Destructive AI Workarounds** 
   - **Measurement:** Count of blocked edit attempts during test mode
   - **Target:** 90% reduction in test-fixing code modifications
   - **Tracking:** Via `claude_code.code_edit_tool.decision` metrics with "reject" decision

### 2. **Improves Test Result Quality**
   - **Measurement:** Length and detail of test failure analysis reports
   - **Target:** 3x more detailed failure documentation  
   - **Tracking:** Via TodoWrite entries and test-mode-observer sub-agent outputs

### 3. **Maintains Development Velocity**
   - **Measurement:** Time to toggle test mode on/off
   - **Target:** <10 seconds to activate/deactivate
   - **Tracking:** Via custom timing metrics in hooks

### 4. **Prevents Scope Creep**
   - **Measurement:** Duration of test-only sessions vs. mixed sessions
   - **Target:** 80% of test sessions remain focused on testing
   - **Tracking:** Via session duration metrics when test mode active

### 5. **Generates Better Insights**
   - **Measurement:** Actionable recommendations per test session
   - **Target:** Average 5+ specific recommendations per failed test
   - **Tracking:** Via analysis of test-mode-observer sub-agent outputs

### 6. **Team Adoption Rate**
   - **Measurement:** Team members actively using test mode
   - **Target:** 75% of team uses test mode for code reviews
   - **Tracking:** Via unique user metrics in OpenTelemetry data

### 7. **Reduces Architectural Debt**
   - **Measurement:** Issues identified but not "fixed" during test mode
   - **Target:** 50% more architectural issues documented
   - **Tracking:** Via TodoWrite task creation during test mode sessions

---

*This tool addresses the fundamental "never give up" problem identified in the VibeTDD experiments by creating hard boundaries that channel AI persistence into productive observation rather than destructive modification. By leveraging Claude Code's native hooks, permissions, and sub-agent systems, it integrates seamlessly into existing development workflows while providing robust protection against the problematic behaviors discovered in AI-assisted development.*