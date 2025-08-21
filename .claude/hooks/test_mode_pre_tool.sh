#!/bin/bash
# Test Mode PreToolUse Hook - Defensive Security System
# Blocks destructive modifications when test mode is active
# Implements comprehensive security validation and project isolation

# Security: Strict error handling and secure environment
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Load security utilities with validation
readonly UTILS_FILE="$(dirname "$0")/hook_utils.sh"
if [[ ! -f "$UTILS_FILE" ]] || [[ ! -r "$UTILS_FILE" ]]; then
    echo "🚫 SECURITY ERROR: Cannot load hook utilities" >&2
    exit 1
fi

# Security: Source utilities in secure manner
if ! source "$UTILS_FILE"; then
    echo "🚫 SECURITY ERROR: Failed to load hook utilities" >&2
    exit 1
fi

# Security: Validate execution environment
validate_execution_environment() {
    # Security: Ensure we're in a safe directory
    local current_dir
    current_dir=$(pwd)
    
    if ! validate_project_path "$current_dir"; then
        log_security_event "CRITICAL" "Invalid execution directory" 
        echo "🚫 SECURITY VIOLATION: Invalid execution directory" >&2
        exit 1
    fi
    
    # Security: Validate .claude directory exists and has proper permissions
    if [[ ! -d ".claude" ]]; then
        log_security_event "ERROR" "Missing .claude directory"
        echo "🚫 SECURITY ERROR: Missing .claude directory" >&2
        exit 1
    fi
    
    # Security: Check directory permissions
    local claude_perms
    claude_perms=$(stat -f%A ".claude" 2>/dev/null || stat -c%a ".claude" 2>/dev/null)
    if [[ ! "$claude_perms" =~ ^[0-7][5-7][0-5]$ ]]; then
        log_security_event "WARN" "Insecure .claude directory permissions: $claude_perms"
    fi
}

# Security: Comprehensive input validation
validate_hook_input() {
    local input="$1"
    
    # Security: Validate JSON input
    if ! validate_json_input "$input"; then
        log_security_event "CRITICAL" "Invalid JSON input to PreToolUse hook"
        echo "🚫 SECURITY VIOLATION: Invalid input format" >&2
        exit 1
    fi
    
    # Security: Extract and validate tool name
    local tool_name
    tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
    
    if [[ -z "$tool_name" ]]; then
        log_security_event "ERROR" "Missing tool_name in hook input"
        echo "🚫 SECURITY ERROR: Missing tool name" >&2
        exit 1
    fi
    
    # Security: Validate tool name format
    if [[ ! "$tool_name" =~ ^[a-zA-Z][a-zA-Z0-9]*$ ]]; then
        log_security_event "CRITICAL" "Invalid tool name format: $tool_name"
        echo "🚫 SECURITY VIOLATION: Invalid tool name format" >&2
        exit 1
    fi
    
    printf '%s' "$tool_name"
}

# Security: Project context validation
validate_project_context() {
    local current_project_path current_project_name
    
    # Security: Get and validate current project context
    current_project_path=$(pwd)
    current_project_name=$(basename "$current_project_path")
    
    if ! validate_project_path "$current_project_path" || ! validate_project_name "$current_project_name"; then
        log_security_event "CRITICAL" "Invalid project context"
        echo "🚫 SECURITY VIOLATION: Invalid project context" >&2
        exit 1
    fi
    
    printf '%s|%s' "$current_project_path" "$current_project_name"
}

# Security: Test mode status validation
check_test_mode_status() {
    local project_path="$1"
    local project_name="$2"
    
    # Security: Clean up any stale status files first
    cleanup_stale_status_files "$project_path" "$project_name"
    
    # Security: Check for active test mode (precedence: project > user)
    local project_status_file user_status_file
    project_status_file=$(get_status_file_path "$project_name" "project-level")
    user_status_file=$(get_status_file_path "$project_name" "user-level")
    
    # Security: Validate status files
    if [[ -f "$project_status_file" ]]; then
        if validate_status_file "$project_status_file" "$project_path"; then
            log_security_event "INFO" "Project-level test mode active" "$project_name"
            printf 'project-level|%s' "$project_status_file"
            return 0
        else
            log_security_event "WARN" "Invalid project-level status file" "$project_name"
            rm -f "$project_status_file" 2>/dev/null || true
        fi
    fi
    
    if [[ -f "$user_status_file" ]]; then
        if validate_status_file "$user_status_file" "$project_path"; then
            log_security_event "INFO" "User-level test mode active" "$project_name"
            printf 'user-level|%s' "$user_status_file"
            return 0
        else
            log_security_event "WARN" "Invalid user-level status file" "$project_name"
            rm -f "$user_status_file" 2>/dev/null || true
        fi
    fi
    
    # No active test mode found
    return 1
}

# Security: Tool blocking logic
block_tool() {
    local tool_name="$1"
    local mode_type="$2"
    local project_name="$3"
    local reason="${4:-Tool blocked in test mode}"
    
    log_security_event "BLOCK" "Tool blocked: $tool_name (mode: $mode_type)" "$project_name"
    
    cat << EOF >&2

🚫 TEST MODE VIOLATION: $tool_name tool blocked!

Project: $project_name
Mode: $mode_type
Reason: $reason

TEST MODE RESTRICTIONS ACTIVE:
❌ File modifications are BLOCKED (Edit, Write, MultiEdit, NotebookEdit)
❌ Destructive operations are BLOCKED
✅ Read-only analysis is ALLOWED (Read, LS, Grep, Glob)  
✅ Test execution is ALLOWED (safe Bash commands)
✅ Documentation updates are ALLOWED (Task tool)

REMEMBER: Test failures are VALUABLE INFORMATION!
Focus on:
- Documenting what the tests reveal
- Analyzing the root cause
- Creating tasks for human developers

To modify files, deactivate test mode first:
/project:test_mode:off

EOF
    
    exit 1
}

# Security: Bash command validation
validate_bash_command() {
    local input="$1"
    local project_name="$2"
    local strict_mode="${3:-false}"
    
    # Security: Extract command from JSON input
    local command
    command=$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)
    
    if [[ -z "$command" ]]; then
        log_security_event "ERROR" "Missing command in Bash tool input" "$project_name"
        block_tool "Bash" "validation-failed" "$project_name" "Missing command parameter"
    fi
    
    # Security: Validate command safety
    if ! is_command_allowed "$command" "$strict_mode"; then
        log_security_event "BLOCK" "Dangerous Bash command blocked: $command" "$project_name"
        
        cat << EOF >&2

🚫 TEST MODE VIOLATION: Dangerous Bash command blocked!

Command: $command
Project: $project_name

SECURITY POLICY: Destructive commands are blocked in test mode.

ALLOWED commands include:
✅ git status, git log, git diff, git show
✅ ls, find, grep, cat, head, tail
✅ Test commands: mvn test, npm test, pytest, etc.
✅ Read-only analysis commands

BLOCKED commands include:
❌ rm, mv, cp (with destructive flags)
❌ Output redirection (>, >>)
❌ Command chaining with dangerous operations
❌ File permission changes
❌ System administration commands

Use safe alternatives or deactivate test mode to proceed.

EOF
        exit 1
    fi
    
    log_security_event "ALLOW" "Safe Bash command allowed: $command" "$project_name"
}

# Main hook execution
main() {
    # Security: Validate execution environment
    validate_execution_environment
    
    # Security: Read and validate input
    local input
    input=$(cat)
    
    local tool_name
    tool_name=$(validate_hook_input "$input")
    
    # Security: Validate project context
    local project_context project_path project_name
    project_context=$(validate_project_context)
    IFS='|' read -r project_path project_name <<< "$project_context"
    
    # Security: Check if test mode is active for this project
    local test_mode_info mode_type status_file
    if test_mode_info=$(check_test_mode_status "$project_path" "$project_name"); then
        IFS='|' read -r mode_type status_file <<< "$test_mode_info"
        
        # Security: Extract strict mode setting
        local strict_mode
        strict_mode=$(cat "$status_file" | jq -r '.strict // false' 2>/dev/null)
        
        log_security_event "INFO" "Test mode active - evaluating tool: $tool_name" "$project_name"
        
        # Security: Apply tool-specific restrictions
        case "$tool_name" in
            "Edit"|"Write"|"MultiEdit"|"NotebookEdit")
                block_tool "$tool_name" "$mode_type" "$project_name" \
                    "File modification tools are blocked to prevent destructive changes"
                ;;
            "Bash")
                validate_bash_command "$input" "$project_name" "$strict_mode"
                ;;
            "Read"|"LS"|"Grep"|"Glob"|"Task")
                log_security_event "ALLOW" "Safe tool allowed: $tool_name" "$project_name"
                ;;
            *)
                # Security: Unknown tools are blocked by default in strict mode
                if [[ "$strict_mode" == "true" ]]; then
                    block_tool "$tool_name" "$mode_type" "$project_name" \
                        "Unknown tools are blocked in strict mode"
                else
                    log_security_event "ALLOW" "Tool allowed (non-strict mode): $tool_name" "$project_name"
                fi
                ;;
        esac
    else
        # Test mode not active - allow all tools
        log_security_event "INFO" "Test mode inactive - tool allowed: $tool_name" "$project_name"
    fi
    
    # Security: Tool is allowed to proceed
    exit 0
}

# Security: Execute main function with error handling
if ! main "$@"; then
    log_security_event "ERROR" "Hook execution failed"
    echo "🚫 SECURITY ERROR: Hook execution failed" >&2
    exit 1
fi