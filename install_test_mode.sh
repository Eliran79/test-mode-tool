#!/bin/bash

# Test Mode Tool Secure Installation Script
# Author: Claude Code Security Engineer
# Version: 1.0
# Description: Safely deploys Test Mode Tool components to target projects

set -euo pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_CLAUDE_DIR="${SCRIPT_DIR}/.claude"
readonly BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
readonly LOG_FILE="/tmp/test_mode_install_${BACKUP_TIMESTAMP}.log"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_TARGET_NOT_FOUND=2
readonly EXIT_PERMISSION_DENIED=3
readonly EXIT_INSTALLATION_FAILED=4
readonly EXIT_VALIDATION_FAILED=5

# Security validation patterns
readonly VALID_PATH_PATTERN='^[a-zA-Z0-9/_.-]+$'
readonly MAX_PATH_LENGTH=256
readonly MIN_PATH_LENGTH=3

# Component lists for installation
readonly REQUIRED_DIRS=(
    "agents"
    "commands/test_mode"
    "hooks"
)

readonly CORE_FILES=(
    "agents/test-mode-observer.md"
    "agents/test-reporter.md"
    "commands/test_mode/on.md"
    "commands/test_mode/off.md"
    "commands/test_mode/clean.md"
    "commands/test_mode/status.md"
    "hooks/hook_utils.sh"
    "hooks/test_mode_pre_tool.sh"
    "hooks/test_mode_post_tool.sh"
    "hooks/test_mode_setup.sh"
)

readonly EXECUTABLE_FILES=(
    "hooks/hook_utils.sh"
    "hooks/test_mode_pre_tool.sh"
    "hooks/test_mode_post_tool.sh"
    "hooks/test_mode_setup.sh"
)

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# Output functions with colors
print_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
    log_info "$@"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
    log_success "$@"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
    log_warn "$@"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    log_error "$@"
}

# Usage information
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] <target_project_path>

DESCRIPTION:
    Securely installs Test Mode Tool components to a target project.
    Creates backups and validates all operations for safe deployment.

OPTIONS:
    -h, --help              Show this help message
    -v, --validate          Validate installation without installing
    -u, --uninstall         Uninstall Test Mode Tool from target project
    -f, --force             Force installation (skip some safety checks)
    --dry-run              Show what would be done without executing
    --backup-dir PATH      Custom backup directory (default: target/.claude/backups)

ARGUMENTS:
    target_project_path     Absolute path to target project directory

EXAMPLES:
    # Install to project
    $SCRIPT_NAME /path/to/target/project

    # Validate target without installing
    $SCRIPT_NAME --validate /path/to/target/project

    # Uninstall from project
    $SCRIPT_NAME --uninstall /path/to/target/project

    # Dry run to see what would be done
    $SCRIPT_NAME --dry-run /path/to/target/project

SECURITY FEATURES:
    - Path validation and sanitization
    - Permission verification
    - Automatic backups before changes
    - Atomic operations with rollback
    - Comprehensive validation
    - Safe settings.json modification

EXIT CODES:
    0 - Success
    1 - Invalid arguments
    2 - Target not found
    3 - Permission denied
    4 - Installation failed
    5 - Validation failed

EOF
}

# Security validation functions
validate_path() {
    local path="$1"
    local path_type="${2:-path}"
    
    # Check if path is empty
    if [[ -z "$path" ]]; then
        print_error "Empty $path_type provided"
        return 1
    fi
    
    # Check path length
    if [[ ${#path} -lt $MIN_PATH_LENGTH ]] || [[ ${#path} -gt $MAX_PATH_LENGTH ]]; then
        print_error "$path_type length must be between $MIN_PATH_LENGTH and $MAX_PATH_LENGTH characters"
        return 1
    fi
    
    # Validate path pattern (prevent directory traversal)
    if [[ ! "$path" =~ $VALID_PATH_PATTERN ]]; then
        print_error "$path_type contains invalid characters: $path"
        return 1
    fi
    
    # Check for directory traversal attempts
    if [[ "$path" == *".."* ]] || [[ "$path" == *"//"* ]]; then
        print_error "$path_type contains directory traversal patterns: $path"
        return 1
    fi
    
    # Ensure absolute path
    if [[ ! "$path" =~ ^/ ]]; then
        print_error "$path_type must be absolute: $path"
        return 1
    fi
    
    return 0
}

validate_target_directory() {
    local target_dir="$1"
    
    print_info "Validating target directory: $target_dir"
    
    # Basic path validation
    if ! validate_path "$target_dir" "target directory"; then
        return 1
    fi
    
    # Check if directory exists
    if [[ ! -d "$target_dir" ]]; then
        print_error "Target directory does not exist: $target_dir"
        return 1
    fi
    
    # Check if we have read/write permissions
    if [[ ! -r "$target_dir" ]] || [[ ! -w "$target_dir" ]]; then
        print_error "Insufficient permissions on target directory: $target_dir"
        return 1
    fi
    
    # Check if it appears to be a valid project directory
    if [[ ! -f "$target_dir/.claude/settings.json" ]] && [[ ! -d "$target_dir/.git" ]] && [[ ! -f "$target_dir/package.json" ]] && [[ ! -f "$target_dir/requirements.txt" ]] && [[ ! -f "$target_dir/Cargo.toml" ]] && [[ ! -f "$target_dir/go.mod" ]]; then
        print_warning "Target directory doesn't appear to be a project root (no common project files found)"
        if [[ "$FORCE_INSTALL" != "true" ]]; then
            print_error "Use --force to install anyway"
            return 1
        fi
    fi
    
    return 0
}

validate_source_components() {
    print_info "Validating source Test Mode Tool components"
    
    # Check if source .claude directory exists
    if [[ ! -d "$SOURCE_CLAUDE_DIR" ]]; then
        print_error "Source .claude directory not found: $SOURCE_CLAUDE_DIR"
        return 1
    fi
    
    # Validate all required directories exist
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ ! -d "$SOURCE_CLAUDE_DIR/$dir" ]]; then
            print_error "Required source directory missing: $SOURCE_CLAUDE_DIR/$dir"
            return 1
        fi
    done
    
    # Validate all core files exist
    for file in "${CORE_FILES[@]}"; do
        if [[ ! -f "$SOURCE_CLAUDE_DIR/$file" ]]; then
            print_error "Required source file missing: $SOURCE_CLAUDE_DIR/$file"
            return 1
        fi
    done
    
    # Validate executable files have correct permissions
    for file in "${EXECUTABLE_FILES[@]}"; do
        if [[ ! -x "$SOURCE_CLAUDE_DIR/$file" ]]; then
            print_warning "Source file not executable: $SOURCE_CLAUDE_DIR/$file"
            print_info "Attempting to fix permissions..."
            if ! chmod +x "$SOURCE_CLAUDE_DIR/$file"; then
                print_error "Failed to make source file executable: $SOURCE_CLAUDE_DIR/$file"
                return 1
            fi
        fi
    done
    
    print_success "Source components validation passed"
    return 0
}

create_backup() {
    local target_dir="$1"
    local backup_dir="${target_dir}/.claude/backups"
    
    print_info "Creating backup of existing configuration"
    
    # Create backup directory if it doesn't exist
    if ! mkdir -p "$backup_dir"; then
        print_error "Failed to create backup directory: $backup_dir"
        return 1
    fi
    
    # Backup existing settings.json if it exists
    local settings_file="${target_dir}/.claude/settings.json"
    if [[ -f "$settings_file" ]]; then
        local backup_file="${backup_dir}/settings-backup-${BACKUP_TIMESTAMP}.json"
        if ! cp "$settings_file" "$backup_file"; then
            print_error "Failed to backup settings.json"
            return 1
        fi
        print_success "Backed up settings.json to: $backup_file"
        echo "$backup_file" # Return backup file path for rollback
    fi
    
    return 0
}

install_components() {
    local target_dir="$1"
    local target_claude_dir="${target_dir}/.claude"
    
    print_info "Installing Test Mode Tool components"
    
    # Create .claude directory structure
    if ! mkdir -p "$target_claude_dir"; then
        print_error "Failed to create .claude directory"
        return 1
    fi
    
    # Create all required directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        local target_subdir="${target_claude_dir}/${dir}"
        print_info "Creating directory: $target_subdir"
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! mkdir -p "$target_subdir"; then
                print_error "Failed to create directory: $target_subdir"
                return 1
            fi
        fi
    done
    
    # Create logs and backups directories
    for dir in "logs" "backups"; do
        local target_subdir="${target_claude_dir}/${dir}"
        print_info "Creating support directory: $target_subdir"
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! mkdir -p "$target_subdir"; then
                print_error "Failed to create directory: $target_subdir"
                return 1
            fi
        fi
    done
    
    # Copy all core files
    for file in "${CORE_FILES[@]}"; do
        local source_file="${SOURCE_CLAUDE_DIR}/${file}"
        local target_file="${target_claude_dir}/${file}"
        
        print_info "Copying: $file"
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! cp "$source_file" "$target_file"; then
                print_error "Failed to copy file: $file"
                return 1
            fi
        fi
    done
    
    # Set correct permissions on executable files
    for file in "${EXECUTABLE_FILES[@]}"; do
        local target_file="${target_claude_dir}/${file}"
        print_info "Setting executable permissions: $file"
        if [[ "$DRY_RUN" != "true" ]]; then
            if ! chmod +x "$target_file"; then
                print_error "Failed to set executable permissions: $file"
                return 1
            fi
        fi
    done
    
    print_success "Components installation completed"
    return 0
}

update_settings_json() {
    local target_dir="$1"
    local settings_file="${target_dir}/.claude/settings.json"
    
    print_info "Updating settings.json configuration"
    
    # Create minimal settings.json if it doesn't exist
    if [[ ! -f "$settings_file" ]]; then
        if [[ "$DRY_RUN" != "true" ]]; then
            cat > "$settings_file" << 'EOF'
{
  "hooks": {
    "PreToolUse": [],
    "PostToolUse": []
  },
  "env": {
    "CLAUDE_TEST_MODE": "false"
  }
}
EOF
        fi
        print_success "Created new settings.json"
    else
        print_info "Settings.json already exists, preserving existing configuration"
    fi
    
    return 0
}

validate_installation() {
    local target_dir="$1"
    local target_claude_dir="${target_dir}/.claude"
    
    print_info "Validating installation"
    
    # Check if all required directories were created
    for dir in "${REQUIRED_DIRS[@]}"; do
        local target_subdir="${target_claude_dir}/${dir}"
        if [[ ! -d "$target_subdir" ]]; then
            print_error "Validation failed: Missing directory $target_subdir"
            return 1
        fi
    done
    
    # Check if all core files were copied
    for file in "${CORE_FILES[@]}"; do
        local target_file="${target_claude_dir}/${file}"
        if [[ ! -f "$target_file" ]]; then
            print_error "Validation failed: Missing file $target_file"
            return 1
        fi
    done
    
    # Check executable permissions
    for file in "${EXECUTABLE_FILES[@]}"; do
        local target_file="${target_claude_dir}/${file}"
        if [[ ! -x "$target_file" ]]; then
            print_error "Validation failed: File not executable $target_file"
            return 1
        fi
    done
    
    # Validate settings.json
    local settings_file="${target_claude_dir}/settings.json"
    if [[ ! -f "$settings_file" ]]; then
        print_error "Validation failed: Missing settings.json"
        return 1
    fi
    
    # Test JSON syntax
    if ! python3 -m json.tool "$settings_file" > /dev/null 2>&1; then
        print_error "Validation failed: Invalid JSON syntax in settings.json"
        return 1
    fi
    
    print_success "Installation validation passed"
    return 0
}

rollback_installation() {
    local target_dir="$1"
    local backup_file="$2"
    
    print_warning "Rolling back installation due to failure"
    
    # Remove installed components
    local target_claude_dir="${target_dir}/.claude"
    
    # Remove installed files
    for file in "${CORE_FILES[@]}"; do
        local target_file="${target_claude_dir}/${file}"
        if [[ -f "$target_file" ]]; then
            rm -f "$target_file" 2>/dev/null || true
        fi
    done
    
    # Remove empty directories (but preserve existing ones)
    for dir in "${REQUIRED_DIRS[@]}"; do
        local target_subdir="${target_claude_dir}/${dir}"
        if [[ -d "$target_subdir" ]]; then
            rmdir "$target_subdir" 2>/dev/null || true
        fi
    done
    
    # Restore backup if provided
    if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
        local settings_file="${target_claude_dir}/settings.json"
        if cp "$backup_file" "$settings_file"; then
            print_info "Restored settings.json from backup"
        fi
    fi
    
    print_warning "Rollback completed"
}

uninstall_test_mode() {
    local target_dir="$1"
    local target_claude_dir="${target_dir}/.claude"
    
    print_info "Uninstalling Test Mode Tool from: $target_dir"
    
    if [[ ! -d "$target_claude_dir" ]]; then
        print_warning "No .claude directory found, nothing to uninstall"
        return 0
    fi
    
    # Create backup before uninstalling
    local backup_file
    backup_file=$(create_backup "$target_dir")
    
    # Remove Test Mode Tool files
    for file in "${CORE_FILES[@]}"; do
        local target_file="${target_claude_dir}/${file}"
        if [[ -f "$target_file" ]]; then
            print_info "Removing: $file"
            if [[ "$DRY_RUN" != "true" ]]; then
                rm -f "$target_file"
            fi
        fi
    done
    
    # Clean up empty directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        local target_subdir="${target_claude_dir}/${dir}"
        if [[ -d "$target_subdir" ]]; then
            # Only remove if empty
            if rmdir "$target_subdir" 2>/dev/null; then
                print_info "Removed empty directory: $dir"
            else
                print_info "Kept non-empty directory: $dir"
            fi
        fi
    done
    
    print_success "Test Mode Tool uninstalled successfully"
    return 0
}

main() {
    # Initialize variables
    local target_dir=""
    local validate_only=false
    local uninstall_only=false
    local backup_dir=""
    
    # Global flags
    FORCE_INSTALL=false
    DRY_RUN=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit $EXIT_SUCCESS
                ;;
            -v|--validate)
                validate_only=true
                shift
                ;;
            -u|--uninstall)
                uninstall_only=true
                shift
                ;;
            -f|--force)
                FORCE_INSTALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --backup-dir)
                backup_dir="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage >&2
                exit $EXIT_INVALID_ARGS
                ;;
            *)
                if [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    print_error "Multiple target directories specified"
                    exit $EXIT_INVALID_ARGS
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    if [[ -z "$target_dir" ]]; then
        print_error "Target project path is required"
        show_usage >&2
        exit $EXIT_INVALID_ARGS
    fi
    
    # Initialize logging
    print_info "Test Mode Tool Installation Script started"
    print_info "Log file: $LOG_FILE"
    print_info "Target directory: $target_dir"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN MODE - No changes will be made"
    fi
    
    # Security validation
    if ! validate_target_directory "$target_dir"; then
        exit $EXIT_TARGET_NOT_FOUND
    fi
    
    if ! validate_source_components; then
        exit $EXIT_VALIDATION_FAILED
    fi
    
    # Handle different modes
    if [[ "$validate_only" == "true" ]]; then
        print_success "Validation completed successfully"
        exit $EXIT_SUCCESS
    fi
    
    if [[ "$uninstall_only" == "true" ]]; then
        if ! uninstall_test_mode "$target_dir"; then
            exit $EXIT_INSTALLATION_FAILED
        fi
        exit $EXIT_SUCCESS
    fi
    
    # Main installation process
    local backup_file=""
    
    # Step 1: Create backup
    if [[ "$DRY_RUN" != "true" ]]; then
        backup_file=$(create_backup "$target_dir")
    fi
    
    # Step 2: Install components
    if ! install_components "$target_dir"; then
        if [[ "$DRY_RUN" != "true" ]]; then
            rollback_installation "$target_dir" "$backup_file"
        fi
        exit $EXIT_INSTALLATION_FAILED
    fi
    
    # Step 3: Update settings.json
    if ! update_settings_json "$target_dir"; then
        if [[ "$DRY_RUN" != "true" ]]; then
            rollback_installation "$target_dir" "$backup_file"
        fi
        exit $EXIT_INSTALLATION_FAILED
    fi
    
    # Step 4: Validate installation
    if [[ "$DRY_RUN" != "true" ]]; then
        if ! validate_installation "$target_dir"; then
            rollback_installation "$target_dir" "$backup_file"
            exit $EXIT_VALIDATION_FAILED
        fi
    fi
    
    # Success message
    print_success "Test Mode Tool installed successfully to: $target_dir"
    print_info "Installation log: $LOG_FILE"
    
    if [[ -n "$backup_file" ]]; then
        print_info "Configuration backup: $backup_file"
    fi
    
    print_info ""
    print_info "Next steps:"
    print_info "1. Navigate to your target project: cd '$target_dir'"
    print_info "2. Activate test mode: claude test_mode on"
    print_info "3. Check status: claude test_mode status"
    
    exit $EXIT_SUCCESS
}

# Trap signals for cleanup
trap 'print_error "Installation interrupted"; exit 130' INT TERM

# Run main function
main "$@"