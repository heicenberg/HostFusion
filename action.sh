#!/system/bin/sh

# HostFusion - Action Script
# Called from Magisk Manager when user presses "Action" button

MODDIR=${0%/*}

cd "$MODDIR" || exit

# Run update script
exec /system/bin/sh "$MODDIR/update_hosts.sh"