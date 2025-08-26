#!/bin/bash
# Test Mode Setup Script - Secure Installation and Configuration
# Implements atomic operations with comprehensive security validation
# Supports both enabling and disabling hooks with project isolation

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

# Security: Constants
readonly SETTINGS_FILE=".claude/settings.json"
readonly SETTINGS_BACKUP_DIR=".claude/backups"
readonly MAX_BACKUP_FILES=10

# Security: Display usage information
show_usage() {
    cat << EOF
Usage: $0 {enable|disable|validate|cleanup} [options]

Commands:
  enable    Enable test mode hooks with project isolation
  disable   Disable test mode hooks and cleanup
  validate  Validate current hook configuration
  cleanup   Clean up stale files and backups

Enable Options:
  --scope=SCOPE      Scope: all, backend, frontend (default: all)
  --duration=TIME    Duration: 30m, 1h, 2h, etc. (default: none)
  --strict          Enable strict mode (whitelist only)
  --project=PATH    Project path (default: current directory)

Examples:
  $0 enable --scope=backend --duration=1h
  $0 enable --strict
  $0 disable
  $0 validate
  $0 cleanup
EOF
}

# Security: Create secure backup of settings file
create_settings_backup() {
    local settings_file="$1"
    local project_name="$2"
    
    # Security: Create backup directory with proper permissions
    if [[ ! -d "$SETTINGS_BACKUP_DIR" ]]; then
        mkdir -p "$SETTINGS_BACKUP_DIR" && chmod 750 "$SETTINGS_BACKUP_DIR"
    fi
    
    # Security: Generate secure backup filename
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="${SETTINGS_BACKUP_DIR}/settings-${project_name}-${timestamp}.json"
    
    # Security: Create atomic backup
    if [[ -f "$settings_file" ]]; then
        if ! cp "$settings_file" "$backup_file.tmp" 2>/dev/null; then
            log_security_event "ERROR" "Failed to create backup" "$project_name"
            return 1
        fi
        
        mv "$backup_file.tmp" "$backup_file"
        chmod 640 "$backup_file" 2>/dev/null || true
        
        log_security_event "INFO" "Settings backup created: $backup_file" "$project_name"
    fi
    
    # Security: Cleanup old backups
    cleanup_old_backups "$project_name"
    
    printf '%s' "$backup_file"
}

# Security: Cleanup old backup files
cleanup_old_backups() {
    local project_name="$1"
    
    if [[ ! -d "$SETTINGS_BACKUP_DIR" ]]; then
        return 0
    fi
    
    # Security: Find and remove old backups (keep only recent ones)
    local backup_pattern="settings-${project_name}-*.json"
    local backup_count
    backup_count=$(find "$SETTINGS_BACKUP_DIR" -name "$backup_pattern" -type f | wc -l)
    
    if [[ $backup_count -gt $MAX_BACKUP_FILES ]]; then
        # Security: Remove oldest backups
        find "$SETTINGS_BACKUP_DIR" -name "$backup_pattern" -type f -printf '%T@ %p\n' 2>/dev/null | \
        sort -n | head -n $((backup_count - MAX_BACKUP_FILES)) | \
        cut -d' ' -f2- | xargs rm -f 2>/dev/null || true
    fi
}

# Security: Validate JSON syntax and structure
validate_json_file() {
    local json_file="$1"
    
    if [[ ! -f "$json_file" ]]; then
        return 1
    fi
    
    # Security: Check file size
    local file_size=$(stat -f%z "$json_file" 2>/dev/null || stat -c%s "$json_file" 2>/dev/null || echo 0)
    if [[ $file_size -gt $MAX_JSON_SIZE ]]; then
        log_security_event "ERROR" "JSON file too large: $file_size bytes"
        return 1
    fi
    
    # Security: Validate JSON syntax
    local json_content
    if ! json_content=$(cat "$json_file" 2>/dev/null); then
        return 1
    fi
    
    if ! validate_json_input "$json_content"; then
        return 1
    fi
    
    # Security: Validate required structure
    if ! printf '%s' "$json_content" | jq -e 'type == "object"' >/dev/null 2>&1; then
        log_security_event "ERROR" "Invalid JSON structure - not an object"
        return 1
    fi
    
    return 0
}

# Security: Atomic JSON modification
modify_settings_file() {
    local action="$1"
    local scope="$2"
    local duration="$3"
    local strict="$4"
    local project_path="$5"
    local project_name="$6"
    
    # Security: Create settings file if it doesn't exist
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo '{}' > "$SETTINGS_FILE"
        chmod 640 "$SETTINGS_FILE" 2>/dev/null || true
    fi
    
    # Security: Validate existing settings file
    if ! validate_json_file "$SETTINGS_FILE"; then
        log_security_event "ERROR" "Invalid existing settings file" "$project_name"
        echo "🚫 SECURITY ERROR: Invalid existing settings file" >&2
        return 1
    fi
    
    # Security: Create backup before modification
    local backup_file
    backup_file=$(create_settings_backup "$SETTINGS_FILE" "$project_name")
    
    # Security: Prepare atomic modification
    local temp_file="${SETTINGS_FILE}.tmp.$$"
    
    if [[ "$action" == "enable" ]]; then
        # Security: Enable test mode hooks with validation
        if ! jq --arg project_name "$project_name" \
               --arg project_path "$project_path" \
               --arg scope "$scope" \
               --arg strict "$strict" \
               --arg duration "$duration" \
               '
               .hooks.PreToolUse += [{"matcher": {"tools": ["Edit", "Write", "MultiEdit", "NotebookEdit", "Bash"]}, "hooks": ["./.claude/hooks/test_mode_pre_tool.sh"]}] |
               .hooks.PostToolUse += [{"matcher": {"tools": ["Edit", "Write", "MultiEdit", "NotebookEdit", "Bash"]}, "hooks": ["./.claude/hooks/test_mode_post_tool.sh"]}] |
               .env.CLAUDE_TEST_MODE = "true" |
               .env.CLAUDE_TEST_MODE_PROJECT = $project_name |
               .env.CLAUDE_TEST_MODE_PATH = $project_path |
               .env.CLAUDE_TEST_MODE_SCOPE = $scope |
               .env.CLAUDE_TEST_MODE_STRICT = $strict |
               if $duration != "" then .env.CLAUDE_TEST_MODE_DURATION = $duration else . end
               ' "$SETTINGS_FILE" > "$temp_file" 2>/dev/null; then
            
            log_security_event "ERROR" "Failed to modify settings file" "$project_name"
            rm -f "$temp_file" 2>/dev/null || true
            return 1
        fi
        
        log_security_event "INFO" "Test mode hooks enabled in settings" "$project_name"
        
    elif [[ "$action" == "disable" ]]; then
        # Security: Disable test mode hooks
        if ! jq '
               .hooks.PreToolUse = (.hooks.PreToolUse | map(select(.matcher.tools | index("Edit") == null and index("Write") == null and index("MultiEdit") == null and index("NotebookEdit") == null and index("Bash") == null))) |
               .hooks.PostToolUse = (.hooks.PostToolUse | map(select(.matcher.tools | index("Edit") == null and index("Write") == null and index("MultiEdit") == null and index("NotebookEdit") == null and index("Bash") == null))) |
               .env.CLAUDE_TEST_MODE = "false" |
               del(.env.CLAUDE_TEST_MODE_PROJECT) |
               del(.env.CLAUDE_TEST_MODE_PATH) |
               del(.env.CLAUDE_TEST_MODE_SCOPE) |
               del(.env.CLAUDE_TEST_MODE_STRICT) |
               del(.env.CLAUDE_TEST_MODE_DURATION)
               ' "$SETTINGS_FILE" > "$temp_file" 2>/dev/null; then
            
            log_security_event "ERROR" "Failed to modify settings file" "$project_name"
            rm -f "$temp_file" 2>/dev/null || true
            return 1
        fi
        
        log_security_event "INFO" "Test mode hooks disabled in settings" "$project_name"
    fi
    
    # Security: Validate modified JSON
    if ! validate_json_file "$temp_file"; then
        log_security_event "ERROR" "Generated invalid JSON during modification" "$project_name"
        rm -f "$temp_file" 2>/dev/null || true
        echo "🚫 SECURITY ERROR: Generated invalid settings file" >&2
        return 1
    fi
    
    # Security: Atomic replacement
    if ! mv "$temp_file" "$SETTINGS_FILE" 2>/dev/null; then
        log_security_event "ERROR" "Failed to atomically replace settings file" "$project_name"
        rm -f "$temp_file" 2>/dev/null || true
        return 1
    fi
    
    chmod 640 "$SETTINGS_FILE" 2>/dev/null || true
    return 0
}

# Security: Create project-specific status file
create_status_file() {
    local scope="$1"
    local duration="$2"
    local strict="$3"
    local project_path="$4"
    local project_name="$5"
    local mode_type="${6:-project-level}"
    
    # Security: Get status file path
    local status_file
    status_file=$(get_status_file_path "$project_name" "$mode_type")
    
    # Security: Calculate expiration time
    local expires_at=""
    if [[ -n "$duration" ]]; then
        local duration_seconds
        case "$duration" in
            *m) duration_seconds=$((${duration%m} * 60)) ;;
            *h) duration_seconds=$((${duration%h} * 3600)) ;;
            *d) duration_seconds=$((${duration%d} * 86400)) ;;
            *) 
                log_security_event "WARN" "Invalid duration format: $duration" "$project_name"
                duration_seconds=3600  # Default to 1 hour
                ;;
        esac
        
        expires_at=$(date -u -d "+${duration_seconds} seconds" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
                    date -u -v+"${duration_seconds}"S +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
                    date -u +%Y-%m-%dT%H:%M:%SZ)
    fi
    
    # Security: Create status file with atomic operation
    local temp_status="${status_file}.tmp.$$"
    
    if ! jq -n \
        --arg project_name "$project_name" \
        --arg project_path "$project_path" \
        --arg scope "$scope" \
        --arg strict "$strict" \
        --arg mode_type "$mode_type" \
        --arg started_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg expires_at "$expires_at" \
        '{
            project_name: $project_name,
            project_path: $project_path,
            active: true,
            scope: $scope,
            strict: ($strict == "true"),
            type: $mode_type,
            started_at: $started_at,
            expires_at: (if $expires_at != "" then $expires_at else null end)
        }' > "$temp_status" 2>/dev/null; then
        
        log_security_event "ERROR" "Failed to create status file" "$project_name"
        rm -f "$temp_status" 2>/dev/null || true
        return 1
    fi
    
    # Security: Validate generated status file
    if ! validate_json_file "$temp_status"; then
        log_security_event "ERROR" "Generated invalid status file" "$project_name"
        rm -f "$temp_status" 2>/dev/null || true
        return 1
    fi
    
    # Security: Atomic replacement
    if ! mv "$temp_status" "$status_file" 2>/dev/null; then
        log_security_event "ERROR" "Failed to create status file atomically" "$project_name"
        rm -f "$temp_status" 2>/dev/null || true
        return 1
    fi
    
    chmod 640 "$status_file" 2>/dev/null || true
    log_security_event "INFO" "Status file created: $status_file" "$project_name"
}

# Security: Remove status files
remove_status_files() {
    local project_path="$1"
    local project_name="$2"
    
    # Security: Clean up stale files first
    cleanup_stale_status_files "$project_path" "$project_name"
    
    # Security: Remove both project-level and user-level status files
    local project_status_file user_status_file
    project_status_file=$(get_status_file_path "$project_name" "project-level")
    user_status_file=$(get_status_file_path "$project_name" "user-level")
    
    for status_file in "$project_status_file" "$user_status_file"; do
        if [[ -f "$status_file" ]]; then
            rm -f "$status_file" 2>/dev/null || true
            log_security_event "INFO" "Removed status file: $status_file" "$project_name"
        fi
    done
}

# Security: Validate current hook configuration
validate_hook_configuration() {
    local project_path="$1"
    local project_name="$2"
    
    local issues=0
    
    echo "🔍 Validating test mode hook configuration..."
    echo "Project: $project_name"
    echo "Path: $project_path"
    echo
    
    # Security: Check settings file
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo "❌ Missing settings file: $SETTINGS_FILE"
        ((issues++))
    elif ! validate_json_file "$SETTINGS_FILE"; then
        echo "❌ Invalid settings file: $SETTINGS_FILE"
        ((issues++))
    else
        echo "✅ Settings file valid: $SETTINGS_FILE"
    fi
    
    # Security: Check hook files
    local hook_files=("test_mode_pre_tool.sh" "test_mode_post_tool.sh" "hook_utils.sh" "test_mode_setup.sh")
    for hook_file in "${hook_files[@]}"; do
        local hook_path=".claude/hooks/$hook_file"
        if [[ ! -f "$hook_path" ]]; then
            echo "❌ Missing hook file: $hook_path"
            ((issues++))
        elif [[ ! -x "$hook_path" ]]; then
            echo "⚠️  Hook file not executable: $hook_path"
            chmod +x "$hook_path" 2>/dev/null || true
        else
            echo "✅ Hook file valid: $hook_path"
        fi
    done
    
    # Security: Check status files
    local status_info
    if status_info=$(check_test_mode_status "$project_path" "$project_name" 2>/dev/null); then
        IFS='|' read -r mode_type status_file <<< "$status_info"
        echo "✅ Test mode active: $mode_type ($status_file)"
    else
        echo "ℹ️  Test mode inactive"
    fi
    
    # Security: Check directory permissions
    if [[ -d ".claude" ]]; then
        local claude_perms
        claude_perms=$(stat -f%A ".claude" 2>/dev/null || stat -c%a ".claude" 2>/dev/null || echo "???")
        echo "ℹ️  .claude directory permissions: $claude_perms"
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        echo "✅ Hook configuration valid"
        return 0
    else
        echo "❌ Found $issues configuration issues"
        return 1
    fi
}

# Security: Parse command line arguments
parse_arguments() {
    local action="$1"
    shift
    
    local scope="all"
    local duration=""
    local strict="false"
    local project_path="$(pwd)"
    
    # Security: Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --scope=*)
                scope="${1#*=}"
                # Security: Validate scope
                case "$scope" in
                    "all"|"backend"|"frontend") ;;
                    *)
                        echo "🚫 SECURITY ERROR: Invalid scope: $scope" >&2
                        return 1
                        ;;
                esac
                ;;
            --duration=*)
                duration="${1#*=}"
                # Security: Validate duration format
                if [[ ! "$duration" =~ ^[0-9]+[mhd]$ ]]; then
                    echo "🚫 SECURITY ERROR: Invalid duration format: $duration" >&2
                    return 1
                fi
                ;;
            --strict)
                strict="true"
                ;;
            --project=*)
                project_path="${1#*=}"
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "🚫 SECURITY ERROR: Unknown option: $1" >&2
                return 1
                ;;
        esac
        shift
    done
    
    # Security: Validate project path
    if ! validate_project_path "$project_path"; then
        echo "🚫 SECURITY ERROR: Invalid project path: $project_path" >&2
        return 1
    fi
    
    printf '%s|%s|%s|%s|%s' "$action" "$scope" "$duration" "$strict" "$project_path"
}

# Main execution function
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local action="$1"
    shift
    
    # Security: Validate action
    case "$action" in
        "enable"|"disable"|"validate"|"cleanup") ;;
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        *)
            echo "🚫 SECURITY ERROR: Invalid action: $action" >&2
            show_usage
            exit 1
            ;;
    esac
    
    # Security: Parse arguments
    local args action scope duration strict project_path project_name
    if ! args=$(parse_arguments "$action" "$@"); then
        exit 1
    fi
    
    IFS='|' read -r action scope duration strict project_path <<< "$args"
    project_name=$(basename "$project_path")
    
    if ! validate_project_name "$project_name"; then
        echo "🚫 SECURITY ERROR: Invalid project name: $project_name" >&2
        exit 1
    fi
    
    # Security: Change to project directory
    cd "$project_path" || {
        echo "🚫 SECURITY ERROR: Cannot access project directory: $project_path" >&2
        exit 1
    }
    
    # Security: Execute action
    case "$action" in
        "enable")
            echo "🔒 Enabling test mode for project: $project_name"
            echo "📁 Project path: $project_path"
            echo "⚙️  Scope: $scope"
            echo "⏱️  Duration: ${duration:-unlimited}"
            echo "🛡️  Strict mode: $strict"
            echo
            
            if modify_settings_file "$action" "$scope" "$duration" "$strict" "$project_path" "$project_name"; then
                create_status_file "$scope" "$duration" "$strict" "$project_path" "$project_name" "project-level"
                echo "✅ Test mode enabled successfully"
            else
                echo "❌ Failed to enable test mode"
                exit 1
            fi
            ;;
            
        "disable")
            echo "🔓 Disabling test mode for project: $project_name"
            echo
            
            if modify_settings_file "$action" "$scope" "$duration" "$strict" "$project_path" "$project_name"; then
                remove_status_files "$project_path" "$project_name"
                echo "✅ Test mode disabled successfully"
            else
                echo "❌ Failed to disable test mode"
                exit 1
            fi
            ;;
            
        "validate")
            validate_hook_configuration "$project_path" "$project_name"
            ;;
            
        "cleanup")
            echo "🧹 Cleaning up test mode files for project: $project_name"
            cleanup_stale_status_files "$project_path" "$project_name"
            cleanup_old_backups "$project_name"
            cleanup_old_logs "$project_name"
            echo "✅ Cleanup completed"
            ;;
    esac
}

# Security: Execute main function with proper error handling
if ! main "$@"; then
    exit 1
fi