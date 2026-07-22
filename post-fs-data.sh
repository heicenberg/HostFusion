#!/system/bin/sh

# HostFusion - Post-FS Data Script
# Runs early in boot process

MODDIR=${0%/*}

# Ensure directories exist
mkdir -p /data/adb/modules/hostfusion
mkdir -p /data/adb/modules/hostfusion/backups

# Set permissions
chmod 0755 /data/adb/modules/hostfusion
chmod 0644 /data/adb/modules/hostfusion/config.conf 2>/dev/null

# Log start
. "$MODDIR/common.sh"
log "INFO" "🔧 HostFusion post-fs-data script executed"