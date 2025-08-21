#!/bin/bash
# Test Mode Hook Utilities - Secure shared functions for test mode hooks
# Provides comprehensive security validation and project isolation

# Security: Strict error handling to prevent undefined behavior
set -euo pipefail

# Security: Secure PATH - only use standard system paths
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Security Constants
readonly MAX_PATH_LENGTH=4096
readonly MAX_JSON_SIZE=32768
readonly MAX_PROJECT_NAME_LENGTH=255
readonly ALLOWED_PROJECT_NAME_PATTERN='^[a-zA-Z0-9_-]+$'

# Logging function with sanitization
log_security_event() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local project_name="${3:-unknown}"
    
    # Security: Sanitize all inputs for logging
    level=$(printf '%s' "$level" | tr -cd '[:alnum:]')
    message=$(printf '%s' "$message" | tr -cd '[:print:][:space:]' | head -c 500)
    project_name=$(printf '%s' "$project_name" | tr -cd '[:alnum:]_-' | head -c 50)
    
    # Security: Create logs directory with secure permissions
    local log_dir=".claude/logs"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" && chmod 750 "$log_dir"
    fi
    
    # Security: Project-isolated log file with secure permissions
    local log_file="${log_dir}/test-mode-security-${project_name}.log"
    printf '[%s] %s: %s\n' "$timestamp" "$level" "$message" >> "$log_file"
    chmod 640 "$log_file" 2>/dev/null || true
}

# Secure JSON validation and parsing
validate_json_input() {
    local json_input="$1"
    local max_size="${2:-$MAX_JSON_SIZE}"
    
    # Security: Check input size to prevent DoS
    local input_size=${#json_input}
    if [[ $input_size -gt $max_size ]]; then
        log_security_event "ERROR" "JSON input too large: $input_size bytes"
        return 1
    fi
    
    # Security: Validate JSON syntax without executing
    if ! printf '%s' "$json_input" | jq empty 2>/dev/null; then
        log_security_event "ERROR" "Invalid JSON input detected"
        return 1
    fi
    
    # Security: Check for suspicious JSON content
    if printf '%s' "$json_input" | grep -qE '(\$\(|`|eval|exec|\|\||&&|;)'; then
        log_security_event "CRITICAL" "Suspicious JSON content detected"
        return 1
    fi
    
    return 0
}

# Secure path validation with anti-traversal protection
validate_project_path() {
    local path="$1"
    
    # Security: Check path length
    if [[ ${#path} -gt $MAX_PATH_LENGTH ]]; then
        log_security_event "ERROR" "Path too long: ${#path} characters"
        return 1
    fi
    
    # Security: Prevent directory traversal attacks
    if [[ "$path" =~ \.\./|/\.\./|/\.\.$|^\.\. ]]; then
        log_security_event "CRITICAL" "Directory traversal attempt detected: $path"
        return 1
    fi
    
    # Security: Ensure absolute path
    if [[ ! "$path" =~ ^/ ]]; then
        log_security_event "ERROR" "Relative path not allowed: $path"
        return 1
    fi
    
    # Security: Check for dangerous characters
    if [[ "$path" =~ [[:cntrl:]] || "$path" =~ \$\( || "$path" =~ \` || "$path" =~ \| ]]; then
        log_security_event "CRITICAL" "Dangerous characters in path: $path"
        return 1
    fi
    
    # Security: Verify path exists and is a directory
    if [[ ! -d "$path" ]]; then
        log_security_event "ERROR" "Invalid project path: $path"
        return 1
    fi
    
    return 0
}

# Secure project name validation
validate_project_name() {
    local project_name="$1"
    
    # Security: Check length
    if [[ ${#project_name} -gt $MAX_PROJECT_NAME_LENGTH ]]; then
        log_security_event "ERROR" "Project name too long: ${#project_name} characters"
        return 1
    fi
    
    # Security: Validate against allowed pattern
    if [[ ! "$project_name" =~ $ALLOWED_PROJECT_NAME_PATTERN ]]; then
        log_security_event "ERROR" "Invalid project name format: $project_name"
        return 1
    fi
    
    # Security: Prevent reserved names
    case "$project_name" in
        ""|"con"|"prn"|"aux"|"nul"|"com"*|"lpt"*|"."*|".."*|"~"*)
            log_security_event "ERROR" "Reserved project name: $project_name"
            return 1
            ;;
    esac
    
    return 0
}

# Secure status file management with project isolation
get_status_file_path() {
    local project_name="$1"
    local mode_type="${2:-project-level}"
    
    # Security: Validate inputs
    if ! validate_project_name "$project_name"; then
        return 1
    fi
    
    # Security: Sanitize mode type
    case "$mode_type" in
        "project-level")
            printf '.claude/test-mode-active-%s.json' "$project_name"
            ;;
        "user-level")
            printf '.claude/test-mode-active-user-%s.json' "$project_name"
            ;;
        *)
            log_security_event "ERROR" "Invalid mode type: $mode_type"
            return 1
            ;;
    esac
}

# Secure status file validation
validate_status_file() {
    local status_file="$1"
    local current_project_path="$2"
    
    # Security: Check file exists and is readable
    if [[ ! -r "$status_file" ]]; then
        return 1
    fi
    
    # Security: Check file size
    local file_size=$(stat -f%z "$status_file" 2>/dev/null || stat -c%s "$status_file" 2>/dev/null || echo 0)
    if [[ $file_size -gt $MAX_JSON_SIZE ]]; then
        log_security_event "ERROR" "Status file too large: $file_size bytes"
        return 1
    fi
    
    # Security: Read and validate JSON content
    local status_content
    if ! status_content=$(cat "$status_file" 2>/dev/null); then
        log_security_event "ERROR" "Cannot read status file: $status_file"
        return 1
    fi
    
    if ! validate_json_input "$status_content"; then
        log_security_event "ERROR" "Invalid JSON in status file: $status_file"
        return 1
    fi
    
    # Security: Validate required fields exist
    local stored_path stored_project
    stored_path=$(printf '%s' "$status_content" | jq -r '.project_path // empty' 2>/dev/null)
    stored_project=$(printf '%s' "$status_content" | jq -r '.project_name // empty' 2>/dev/null)
    
    if [[ -z "$stored_path" || -z "$stored_project" ]]; then
        log_security_event "ERROR" "Missing required fields in status file: $status_file"
        return 1
    fi
    
    # Security: Validate stored project name
    if ! validate_project_name "$stored_project"; then
        log_security_event "ERROR" "Invalid project name in status file: $stored_project"
        return 1
    fi
    
    # Security: Validate stored path
    if ! validate_project_path "$stored_path"; then
        log_security_event "ERROR" "Invalid project path in status file: $stored_path"
        return 1
    fi
    
    # Security: Verify project isolation - paths must match
    if [[ "$stored_path" != "$current_project_path" ]]; then
        log_security_event "WARN" "Project path mismatch - possible stale status file"
        return 1
    fi
    
    # Security: Check if test mode is actually active
    local is_active
    is_active=$(printf '%s' "$status_content" | jq -r '.active // false' 2>/dev/null)
    if [[ "$is_active" != "true" ]]; then
        return 1
    fi
    
    return 0
}

# Secure command filtering for Bash tool
is_command_allowed() {
    local command="$1"
    local strict_mode="${2:-false}"
    
    # Security: Sanitize command input
    command=$(printf '%s' "$command" | head -c 1000)
    
    # Security: Block dangerous command patterns
    local dangerous_patterns=(
        '\brm\b.*-[rf]'       # rm with -r or -f flags
        '\bmv\b'              # mv command
        '\bcp\b.*-[rf]'       # cp with -r or -f flags  
        '>'                   # output redirection
        '>>'                  # append redirection
        '\|\|'                # OR operator
        '&&.*rm'              # AND with rm
        '&&.*mv'              # AND with mv
        ';.*rm'               # semicolon with rm
        ';.*mv'               # semicolon with mv
        '\$\('                # command substitution
        '`'                   # backtick execution
        '\beval\b'            # eval command
        '\bexec\b'            # exec command
        '\bchmod\b.*[+]x'     # chmod +x (make executable)
        '\bsu\b'              # su command
        '\bsudo\b'            # sudo command
        '\bcurl\b.*\|'        # curl with pipe
        '\bwget\b.*\|'        # wget with pipe
        '\bnc\b'              # netcat
        '\bnetcat\b'          # netcat
        '/dev/'               # device access
        '/proc/'              # proc filesystem
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$command" =~ $pattern ]]; then
            log_security_event "CRITICAL" "Dangerous command blocked: $command"
            return 1
        fi
    done
    
    # Security: Whitelist of allowed commands in strict mode
    if [[ "$strict_mode" == "true" ]]; then
        local allowed_commands=(
            '^git status'
            '^git log'
            '^git diff'
            '^git show'
            '^ls'
            '^find .* -name'
            '^grep'
            '^rg'
            '^cat'
            '^head'
            '^tail'
            '^less'
            '^pwd'
            '^echo'
            '^date'
            '^mvn test'
            '^npm test'
            '^npm run test'
            '^pytest'
            '^python -m pytest'
            '^java.*test'
            '^./gradlew test'
            '^make test'
            '^go test'
            '^cargo test'
        )
        
        local command_allowed=false
        for allowed_pattern in "${allowed_commands[@]}"; do
            if [[ "$command" =~ $allowed_pattern ]]; then
                command_allowed=true
                break
            fi
        done
        
        if [[ "$command_allowed" == "false" ]]; then
            log_security_event "INFO" "Command not in whitelist: $command"
            return 1
        fi
    fi
    
    return 0
}

# Secure cleanup of stale status files
cleanup_stale_status_files() {
    local current_project_path="$1"
    local current_project_name="$2"
    
    # Security: Validate inputs
    if ! validate_project_path "$current_project_path" || ! validate_project_name "$current_project_name"; then
        return 1
    fi
    
    # Security: Only clean files in .claude directory
    if [[ ! -d ".claude" ]]; then
        return 0
    fi
    
    # Security: Find and validate status files
    local status_files
    if ! status_files=$(find .claude -maxdepth 1 -name 'test-mode-active-*.json' -type f 2>/dev/null); then
        return 0
    fi
    
    while IFS= read -r status_file; do
        if [[ -n "$status_file" && -f "$status_file" ]]; then
            # Security: Check if this is a stale file
            if ! validate_status_file "$status_file" "$current_project_path" 2>/dev/null; then
                log_security_event "INFO" "Removing stale status file: $status_file"
                rm -f "$status_file" 2>/dev/null || true
            fi
        fi
    done <<< "$status_files"
}

# Security: Cleanup old log files
cleanup_old_logs() {
    local project_name="$1"
    local log_dir=".claude/logs"
    local retention_days="${2:-30}"
    
    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi
    
    # Security: Validate project name
    if ! validate_project_name "$project_name"; then
        return 1
    fi
    
    # Security: Find and remove old log files
    find "$log_dir" -name "test-mode-usage-${project_name}.log.*" -type f -mtime +$retention_days -delete 2>/dev/null || true
    find "$log_dir" -name "test-mode-security-${project_name}.log.*" -type f -mtime +$retention_days -delete 2>/dev/null || true
    
    log_security_event "INFO" "Cleaned up old log files" "$project_name"
}

# Security: Export only necessary functions
readonly -f log_security_event validate_json_input validate_project_path
readonly -f validate_project_name get_status_file_path validate_status_file
readonly -f is_command_allowed cleanup_stale_status_files cleanup_old_logs