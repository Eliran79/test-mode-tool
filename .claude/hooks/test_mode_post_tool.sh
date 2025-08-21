#!/bin/bash
# Test Mode PostToolUse Hook - Logging and Cleanup
# Provides comprehensive logging and monitoring for test mode tool usage
# Implements security monitoring and usage analytics

# Security: Strict error handling and secure environment
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

# Load security utilities with validation
readonly UTILS_FILE="$(dirname "$0")/hook_utils.sh"
if [[ ! -f "$UTILS_FILE" ]] || [[ ! -r "$UTILS_FILE" ]]; then
    echo "🚫 SECURITY ERROR: Cannot load hook utilities" >&2
    exit 0  # PostToolUse should not fail the operation
fi

# Security: Source utilities in secure manner
if ! source "$UTILS_FILE"; then
    echo "🚫 SECURITY ERROR: Failed to load hook utilities" >&2
    exit 0  # PostToolUse should not fail the operation
fi

# Security: Constants for usage tracking
readonly MAX_LOG_ENTRIES=1000
readonly MAX_LOG_FILE_SIZE=1048576  # 1MB
readonly USAGE_LOG_RETENTION_DAYS=30

# Security: Create usage analytics entry
log_tool_usage() {
    local tool_name="$1"
    local project_name="$2"
    local success="$3"
    local mode_type="${4:-inactive}"
    local execution_time="${5:-0}"
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local session_id="${CLAUDE_SESSION_ID:-$(date +%s)-$$}"
    
    # Security: Sanitize all inputs
    tool_name=$(printf '%s' "$tool_name" | tr -cd '[:alnum:]' | head -c 50)
    project_name=$(printf '%s' "$project_name" | tr -cd '[:alnum:]_-' | head -c 50)
    success=$(printf '%s' "$success" | tr -cd '[:alnum:]' | head -c 10)
    mode_type=$(printf '%s' "$mode_type" | tr -cd '[:alnum:]-' | head -c 20)
    
    # Security: Create usage log directory with proper permissions
    local usage_log_dir=".claude/logs"
    if [[ ! -d "$usage_log_dir" ]]; then
        mkdir -p "$usage_log_dir" && chmod 750 "$usage_log_dir"
    fi
    
    # Security: Project-specific usage log
    local usage_log_file="${usage_log_dir}/test-mode-usage-${project_name}.log"
    
    # Security: Check log file size and rotate if necessary
    if [[ -f "$usage_log_file" ]]; then
        local file_size=$(stat -f%z "$usage_log_file" 2>/dev/null || stat -c%s "$usage_log_file" 2>/dev/null || echo 0)
        if [[ $file_size -gt $MAX_LOG_FILE_SIZE ]]; then
            rotate_log_file "$usage_log_file" "$project_name"
        fi
    fi
    
    # Security: Create structured log entry
    local log_entry
    log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg session_id "$session_id" \
        --arg tool_name "$tool_name" \
        --arg project_name "$project_name" \
        --arg success "$success" \
        --arg mode_type "$mode_type" \
        --arg execution_time "$execution_time" \
        '{
            timestamp: $timestamp,
            session_id: $session_id,
            tool_name: $tool_name,
            project_name: $project_name,
            success: $success,
            mode_type: $mode_type,
            execution_time: ($execution_time | tonumber)
        }')
    
    # Security: Append to log with proper permissions
    printf '%s\n' "$log_entry" >> "$usage_log_file"
    chmod 640 "$usage_log_file" 2>/dev/null || true
}

# Security: Log file rotation with retention policy
rotate_log_file() {
    local log_file="$1"
    local project_name="$2"
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local archived_file="${log_file}.${timestamp}"
    
    # Security: Move current log to archive
    mv "$log_file" "$archived_file" 2>/dev/null || return 1
    
    # Security: Compress archived log
    if command -v gzip >/dev/null 2>&1; then
        gzip "$archived_file" 2>/dev/null || true
    fi
    
    # Security: Clean up old log files based on retention policy
    cleanup_old_logs "$project_name"
    
    log_security_event "INFO" "Log file rotated: $log_file" "$project_name"
}

# Security: Cleanup old log files
cleanup_old_logs() {
    local project_name="$1"
    local log_dir=".claude/logs"
    
    if [[ ! -d "$log_dir" ]]; then
        return 0
    fi
    
    # Security: Find and remove old log files
    find "$log_dir" -name "test-mode-usage-${project_name}.log.*" -type f -mtime +$USAGE_LOG_RETENTION_DAYS -delete 2>/dev/null || true
    find "$log_dir" -name "test-mode-security-${project_name}.log.*" -type f -mtime +$USAGE_LOG_RETENTION_DAYS -delete 2>/dev/null || true
}

# Security: Generate usage statistics
generate_usage_stats() {
    local project_name="$1"
    local usage_log_file=".claude/logs/test-mode-usage-${project_name}.log"
    
    if [[ ! -f "$usage_log_file" ]]; then
        return 0
    fi
    
    # Security: Extract statistics with size limit
    local total_entries blocked_tools allowed_tools
    total_entries=$(wc -l < "$usage_log_file" 2>/dev/null | head -1)
    
    if [[ $total_entries -gt $MAX_LOG_ENTRIES ]]; then
        log_security_event "WARN" "Usage log file too large: $total_entries entries" "$project_name"
        return 0
    fi
    
    # Security: Count tool usage patterns
    blocked_tools=$(grep -c '"success":"false"' "$usage_log_file" 2>/dev/null || echo 0)
    allowed_tools=$(grep -c '"success":"true"' "$usage_log_file" 2>/dev/null || echo 0)
    
    # Security: Log statistics summary
    log_security_event "STATS" "Usage: $total_entries total, $blocked_tools blocked, $allowed_tools allowed" "$project_name"
}

# Security: Monitor for suspicious activity patterns
detect_suspicious_activity() {
    local tool_name="$1"
    local project_name="$2"
    local usage_log_file=".claude/logs/test-mode-usage-${project_name}.log"
    
    if [[ ! -f "$usage_log_file" ]]; then
        return 0
    fi
    
    local recent_window=300  # 5 minutes
    local current_time=$(date +%s)
    
    # Security: Check for rapid repeated blocked attempts
    local recent_blocks
    recent_blocks=$(awk -v tool="$tool_name" -v window="$recent_window" -v current="$current_time" '
        BEGIN { count = 0 }
        /"success":"false"/ && $0 ~ tool {
            # Extract timestamp and convert to epoch
            match($0, /"timestamp":"([^"]*)"/, ts)
            if (ts[1]) {
                cmd = "date -d \"" ts[1] "\" +%s 2>/dev/null || date -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" ts[1] "\" +%s 2>/dev/null || echo 0"
                cmd | getline epoch
                close(cmd)
                if (current - epoch <= window) count++
            }
        }
        END { print count }
    ' "$usage_log_file" 2>/dev/null || echo 0)
    
    # Security: Alert on suspicious patterns
    if [[ $recent_blocks -gt 10 ]]; then
        log_security_event "ALERT" "Suspicious activity: $recent_blocks rapid blocked attempts for $tool_name" "$project_name"
    fi
}

# Security: Validate hook execution
validate_post_execution() {
    local current_dir project_path project_name
    
    current_dir=$(pwd)
    if ! validate_project_path "$current_dir"; then
        log_security_event "ERROR" "Invalid project path in PostToolUse hook"
        return 1
    fi
    
    project_path="$current_dir"
    project_name=$(basename "$project_path")
    
    if ! validate_project_name "$project_name"; then
        log_security_event "ERROR" "Invalid project name in PostToolUse hook"
        return 1
    fi
    
    printf '%s|%s' "$project_path" "$project_name"
}

# Main hook execution
main() {
    local start_time=$(date +%s%3N)
    
    # Security: Validate execution context
    local project_context project_path project_name
    if ! project_context=$(validate_post_execution); then
        exit 0  # PostToolUse should not fail the operation
    fi
    
    IFS='|' read -r project_path project_name <<< "$project_context"
    
    # Security: Read and validate input (non-blocking)
    local input tool_name success_status
    if input=$(cat 2>/dev/null); then
        if validate_json_input "$input" 2>/dev/null; then
            tool_name=$(printf '%s' "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null)
            success_status=$(printf '%s' "$input" | jq -r '.success // "unknown"' 2>/dev/null)
        else
            tool_name="unknown"
            success_status="unknown"
        fi
    else
        tool_name="unknown" 
        success_status="unknown"
    fi
    
    # Security: Determine test mode status
    local mode_type="inactive"
    if test_mode_info=$(check_test_mode_status "$project_path" "$project_name" 2>/dev/null); then
        IFS='|' read -r mode_type status_file <<< "$test_mode_info"
    fi
    
    # Security: Calculate execution time
    local end_time execution_time
    end_time=$(date +%s%3N)
    execution_time=$((end_time - start_time))
    
    # Security: Log tool usage
    log_tool_usage "$tool_name" "$project_name" "$success_status" "$mode_type" "$execution_time"
    
    # Security: Detect suspicious activity for blocked tools
    if [[ "$success_status" == "false" && "$mode_type" != "inactive" ]]; then
        detect_suspicious_activity "$tool_name" "$project_name"
    fi
    
    # Security: Periodic maintenance
    if [[ $((RANDOM % 100)) -eq 0 ]]; then
        cleanup_old_logs "$project_name"
        generate_usage_stats "$project_name"
    fi
    
    # Security: Success exit (PostToolUse should not block operations)
    exit 0
}

# Security: Execute main function with error handling (non-blocking)
main "$@" 2>/dev/null || exit 0