#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

load_config
init_logging

log "SUCCESS" "🚀 HostFusion Update Started"

# --- 1. Пытаемся использовать встроенный файл (самый надёжный) ---
LOCAL_HOSTS="$MODDIR/system/etc/hosts"

if [ -f "$LOCAL_HOSTS" ] && [ -s "$LOCAL_HOSTS" ]; then
    log "INFO" "Found built-in hosts file. Using it."
    
    if [ "$ENABLE_BACKUP" = "true" ]; then
        backup_hosts "/system/etc/hosts"
    fi
    
    cp -f "$LOCAL_HOSTS" /system/etc/hosts
    chmod 0644 /system/etc/hosts
    chown root:root /system/etc/hosts
    
    log "SUCCESS" "🎉 Hosts file updated from built-in source!"
    log "INFO" "Hosts size: $(wc -c < /system/etc/hosts) bytes"
    
    # Очищаем DNS и выходим
    if command_exists ndc; then
        ndc resolver flushdefaultif 2>/dev/null
        ndc resolver flushnet 0 2>/dev/null
        log "INFO" "DNS cache flushed"
    fi
    
    log "SUCCESS" "✅ HostFusion update completed!"
    exit 0
fi

# --- 2. Если встроенного файла нет, пробуем скачать ---
log "WARN" "Built-in hosts file not found. Trying to download..."

# Проверяем и подготавливаем curl (вызов вашей новой функции!)
if ! ensure_curl; then
    log "ERROR" "Curl setup failed and no built-in hosts file found."
    exit 1
fi

TEMP_DIR="/data/local/tmp/hostfusion"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || exit 1

TEMP_HOSTS="$TEMP_DIR/hosts_new"

# Скачиваем файл
if download_file "$URL_PRIMARY" "$TEMP_HOSTS"; then
    log "SUCCESS" "Download completed"
    
    if [ "$ENABLE_BACKUP" = "true" ]; then
        backup_hosts "/system/etc/hosts"
    fi
    
    cp -f "$TEMP_HOSTS" /system/etc/hosts
    chmod 0644 /system/etc/hosts
    chown root:root /system/etc/hosts
    
    log "SUCCESS" "🎉 Hosts file updated from remote source!"
else
    log "ERROR" "Download failed"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Очистка
rm -rf "$TEMP_DIR"

# Очищаем DNS
if command_exists ndc; then
    ndc resolver flushdefaultif 2>/dev/null
    ndc resolver flushnet 0 2>/dev/null
    log "INFO" "DNS cache flushed"
fi

log "SUCCESS" "✅ HostFusion update completed at $(date '+%Y-%m-%d %H:%M:%S')"