#!/system/bin/sh

# HostFusion - Common functions

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$ENABLE_LOG" = "true" ]; then
        echo "[$timestamp] [$level] $message" >> /data/adb/modules/hostfusion/hostfusion.log
    fi
    
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

# Download file with fallback
download_file() {
    local url="$1"
    local output="$2"
    local retries="${3:-3}"
    
    log "INFO" "Downloading from $url"
    
    # User-Agent для обхода ограничений GitHub
    local UA="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.6045.163 Mobile Safari/537.36"
    
    local attempt=1
    while [ $attempt -le $retries ]; do
        # Пробуем curl
        if command_exists curl; then
            log "INFO" "Using curl"
            curl -k -s -L -A "$UA" --connect-timeout 30 --max-time 60 -o "$output" "$url" && return 0
        # Пробуем wget с User-Agent
        elif command_exists wget; then
            log "INFO" "Using wget"
            wget --no-check-certificate -q -T 30 -U "$UA" -O "$output" "$url" && return 0
        # Пробуем busybox wget с User-Agent
        elif command_exists busybox && busybox --list 2>/dev/null | grep -q wget; then
            log "INFO" "Using busybox wget"
            busybox wget --no-check-certificate -q -T 30 -U "$UA" -O "$output" "$url" && return 0
        else
            log "ERROR" "No download tool available"
            return 1
        fi
        log "WARN" "Download attempt $attempt failed, retrying..."
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log "ERROR" "Failed to download after $retries attempts"
    return 1
}

# Backup hosts
backup_hosts() {
    local hosts_file="$1"
    local backup_dir="/data/adb/modules/hostfusion/backups"
    
    mkdir -p "$backup_dir"
    
    if [ -f "$hosts_file" ]; then
        local backup_name="hosts_$(date '+%Y%m%d_%H%M%S')"
        cp -f "$hosts_file" "$backup_dir/$backup_name"
        log "SUCCESS" "Backup created: $backup_name"
        
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
        local log_file="$log_dir/hostfusion.log"
        if [ -f "$log_file" ] && [ $(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null) -gt 1048576 ]; then
            mv "$log_file" "$log_file.old"
            log "INFO" "Log rotated"
        fi
    fi
}