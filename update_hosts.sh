#!/system/bin/sh

# HostFusion - Update Script
# Main script for updating hosts file

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

# Load configuration
load_config

# Initialize logging
init_logging

log "SUCCESS" "🚀 HostFusion Update Started"
log "INFO" "Primary source: $URL_PRIMARY"

# Create temp directory
TEMP_DIR="/data/local/tmp/hostfusion"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

# Download hosts file
log "INFO" "Downloading hosts file..."
TEMP_HOSTS="$TEMP_DIR/hosts_new"

if download_file "$URL_PRIMARY" "$TEMP_HOSTS"; then
    log "SUCCESS" "Download completed"
else
    if [ -n "$URL_BACKUP" ]; then
        log "WARN" "Primary source failed, trying backup..."
        if download_file "$URL_BACKUP" "$TEMP_HOSTS"; then
            log "SUCCESS" "Backup download completed"
        else
            log "ERROR" "All download sources failed"
            exit 1
        fi
    else
        log "ERROR" "Download failed and no backup source"
        exit 1
    fi
fi

# Verify downloaded file
if ! verify_file "$TEMP_HOSTS"; then
    log "ERROR" "Downloaded file verification failed"
    exit 1
fi

# Backup existing hosts
if [ "$ENABLE_BACKUP" = "true" ]; then
    backup_hosts "/system/etc/hosts"
fi

# Merge custom hosts if enabled
if [ "$MERGE_CUSTOM" = "true" ] && [ -f "$CUSTOM_HOSTS_FILE" ]; then
    log "INFO" "Merging custom hosts..."
    cat "$TEMP_HOSTS" "$CUSTOM_HOSTS_FILE" > "$TEMP_DIR/hosts_merged"
    cp -f "$TEMP_DIR/hosts_merged" "$TEMP_HOSTS"
fi

# Install new hosts file
log "INFO" "Installing new hosts file..."
cp -f "$TEMP_HOSTS" "/system/etc/hosts"

# Set proper permissions
chmod 0644 "/system/etc/hosts"
chown root:root "/system/etc/hosts"

# Flush DNS cache
log "INFO" "Flushing DNS cache..."
if command_exists ndc; then
    ndc resolver flushdefaultif 2>/dev/null
    ndc resolver flushnet 0 2>/dev/null
elif [ -f /system/bin/ndc ]; then
    /system/bin/ndc resolver flushdefaultif 2>/dev/null
    /system/bin/ndc resolver flushnet 0 2>/dev/null
else
    log "WARN" "DNS flush command not available"
fi

# Cleanup
rm -rf "$TEMP_DIR"

log "SUCCESS" "🎉 HostFusion update completed successfully!"
log "INFO" "Hosts file updated at $(date '+%Y-%m-%d %H:%M:%S')"