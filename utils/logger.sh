#!/bin/bash

# Centralized Logging Utility
# Provides consistent logging across all scripts in the biography system

# Auto-load configuration for LOGS_DIR
# Determine the correct path to auto-config.sh based on logger.sh location
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/auto-config.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/auto-config.sh"
else
    # Fallback for scripts in subdirectories
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/auto-config.sh"
fi

# Get the calling script name for log identification
CALLING_SCRIPT=""
if [[ "${BASH_SOURCE[1]}" ]]; then
    CALLING_SCRIPT="$(basename "${BASH_SOURCE[1]}" .sh)"
else
    CALLING_SCRIPT="unknown"
fi

# Log function - writes timestamped messages to script-specific log file
log() {
    local message="$1"
    local log_file="$LOGS_DIR/${CALLING_SCRIPT}.log"
    
    # Ensure logs directory exists
    mkdir -p "$LOGS_DIR"
    
    # Write timestamped log entry
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$log_file"
}

# Log with level (INFO, WARN, ERROR)
log_level() {
    local level="$1"
    local message="$2"
    log "[$level] $message"
}

# Convenience functions for different log levels
log_info() {
    log_level "INFO" "$1"
}

log_warn() {
    log_level "WARN" "$1"
}

log_error() {
    log_level "ERROR" "$1"
}

# Log script start with calling script info
log_start() {
    local script_description="${1:-Script execution}"
    log_info "=== $script_description started ==="
}

# Log script completion
log_end() {
    local script_description="${1:-Script execution}"
    log_info "=== $script_description completed ==="
}