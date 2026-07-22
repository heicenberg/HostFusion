#!/system/bin/sh

# HostFusion - Common functions
# This file is sourced by other scripts

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOG" = "true" ]; then
        echo "[$timestamp] [$level] $message" >> /data/adb/modules/hostfusion/hostfusion.log
    fi
    
    # Also print to console if not in silent mode
    if [ "$SILENT" != "true" ]; then
        case "$level" in
            "ERROR")   echo "${RED}❌ $message${NC}" ;;
            "WARN")    echo "${YELLOW}⚠️  $message${NC}" ;;
            "INFO")    echo "${BLUE}ℹ️  $message${NC}" ;;
            "SUCCESS") echo "${GREEN}✅ $message${NC}" ;;
            *)         echo "$message" ;;
        esac
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check internet connectivity
check_internet() {
    log "INFO" "Checking internet connectivity..."
    
    if command_exists ping; then
        ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
    elif command_exists curl; then
        curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1
    else
        return 1
    fi
}

# Download file with fallback
download_file() {
    local url="$1"
    local output="$2"
    local retries="${3:-3}"
    
    log "INFO" "Downloading from $url"
    
    local attempt=1
    while [ $attempt -le $retries ]; do
        if command_exists curl; then
            curl -s -L --connect-timeout 30 --max-time 60 -o "$output" "$url" && return 0
        elif command_exists wget; then
            wget -q -T 30 -t 1 -O "$output" "$url" && return 0
        else
            log "ERROR" "Neither curl nor wget available"
            return 1
        fi
        log "WARN" "Download attempt $attempt failed, retrying..."
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log "ERROR" "Failed to download after $retries attempts"
    return 1
}

# Verify file exists and is not empty
verify_file() {
    local file="$1"
    if [ ! -f "$file" ] || [ ! -s "$file" ]; then
        log "ERROR" "File verification failed: $file"
        return 1
    fi
    return 0
}

# Create backup of current hosts
backup_hosts() {
    local hosts_file="$1"
    local backup_dir="/data/adb/modules/hostfusion/backups"
    
    mkdir -p "$backup_dir"
    
    if [ -f "$hosts_file" ]; then
        local backup_name="hosts_$(date '+%Y%m%d_%H%M%S')"
        cp -f "$hosts_file" "$backup_dir/$backup_name"
        log "SUCCESS" "Backup created: $backup_name"
        
        # Rotate backups
        local backup_count=$(ls -1 "$backup_dir"/hosts_* 2>/dev/null | wc -l)
        if [ $backup_count -gt "$MAX_BACKUPS" ]; then
            ls -1t "$backup_dir"/hosts_* | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f
            log "INFO" "Rotated old backups"
        fi
    else
        log "WARN" "No existing hosts file to backup"
    fi
}

# Load configuration
load_config() {
    local config_file="/data/adb/modules/hostfusion/config.conf"
    
    if [ -f "$config_file" ]; then
        . "$config_file"
        log "INFO" "Configuration loaded from $config_file"
    else
        log "WARN" "Config file not found, using defaults"
        # Set defaults
        URL_PRIMARY="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        AUTO_UPDATE=true
        UPDATE_INTERVAL=86400
        ENABLE_LOG=true
        ENABLE_BACKUP=true
        MAX_BACKUPS=5
        VERIFY_SHA=false
        MERGE_CUSTOM=true
    fi
}

# Initialize logging
init_logging() {
    local log_dir="/data/adb/modules/hostfusion"
    mkdir -p "$log_dir"
    
    if [ "$ENABLE_LOG" = "true" ]; then
        # Rotate log if too large (>1MB)
        local log_file="$log_dir/hostfusion.log"
        if [ -f "$log_file" ] && [ $(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null) -gt 1048576 ]; then
            mv "$log_file" "$log_file.old"
            log "INFO" "Log rotated"
        fi
    fi
}