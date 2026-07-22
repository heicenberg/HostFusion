#!/system/bin/sh

# HostFusion - Service Script
# Runs in background to handle automatic updates

MODDIR=${0%/*}

# Wait for system to fully boot
sleep 30

# Load common functions
. "$MODDIR/common.sh"

# Load config
load_config

# Log start
log "SUCCESS" "🔄 HostFusion service started"
log "INFO" "Auto-update: $AUTO_UPDATE, Interval: $UPDATE_INTERVAL seconds"

# Check for updates periodically
while true; do
    if [ "$AUTO_UPDATE" = "true" ]; then
        log "INFO" "Checking for update (auto mode)..."
        "$MODDIR/update_hosts.sh" >> /dev/null 2>&1
        log "INFO" "Waiting $UPDATE_INTERVAL seconds until next check..."
    fi
    sleep "$UPDATE_INTERVAL"
done