#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

load_config
init_logging

log "SUCCESS" "🚀 HostFusion Update Started"

# Используем встроенный hosts-файл
LOCAL_HOSTS="$MODDIR/system/etc/hosts"

if [ -f "$LOCAL_HOSTS" ] && [ -s "$LOCAL_HOSTS" ]; then
    log "INFO" "Using built-in hosts file"
    
    # Создаем бэкап если нужно
    if [ "$ENABLE_BACKUP" = "true" ]; then
        backup_hosts "/system/etc/hosts"
    fi
    
    # Копируем файл
    cp -f "$LOCAL_HOSTS" /system/etc/hosts
    chmod 0644 /system/etc/hosts
    chown root:root /system/etc/hosts
    
    log "SUCCESS" "🎉 Hosts file updated from built-in source!"
    log "INFO" "Hosts size: $(wc -c < /system/etc/hosts) bytes"
else
    log "ERROR" "Built-in hosts file not found at $LOCAL_HOSTS"
    log "ERROR" "Please ensure system/etc/hosts exists in the module"
    exit 1
fi

# Очищаем DNS кэш
if command_exists ndc; then
    ndc resolver flushdefaultif 2>/dev/null
    ndc resolver flushnet 0 2>/dev/null
    log "INFO" "DNS cache flushed"
else
    log "WARN" "DNS flush command not available"
fi

log "SUCCESS" "✅ HostFusion update completed at $(date '+%Y-%m-%d %H:%M:%S')"