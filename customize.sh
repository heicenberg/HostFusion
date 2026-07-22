#!/system/bin/sh

# HostFusion - Customize script
# Этот скрипт выполняется во время установки модуля

ui_print "📦 HostFusion Installer"
ui_print "************************"

# Проверяем версию Magisk
if [ -d /data/adb/magisk ]; then
    ui_print "✅ Magisk detected"
elif [ -d /data/adb/ksu ]; then
    ui_print "✅ KernelSU detected"
else
    ui_print "⚠️  Unknown root solution"
fi

# Создаем конфиг если его нет
if [ ! -f /data/adb/modules/hostfusion/config.conf ]; then
    ui_print "📝 Creating default config..."
    cp -f $MODPATH/config.conf /data/adb/modules/hostfusion/config.conf
fi

# Устанавливаем права
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755
set_perm_recursive $MODPATH/system/etc 0 0 0755 0644

ui_print "✅ Installation complete!"
ui_print "🔄 Reboot to activate"