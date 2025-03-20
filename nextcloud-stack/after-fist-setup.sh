#!/bin/bash

CONFIG_FILE="/mnt/docker/Nextcloud/config/www/nextcloud/config/config.php"
BACKUP_FILE="${CONFIG_FILE}.bak"

# Überprüfen, ob die Datei existiert
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Fehler: Die Datei $CONFIG_FILE wurde nicht gefunden!"
    exit 1
fi

# Backup der Datei erstellen
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "📄 Backup wurde erstellt: $BACKUP_FILE"

# Prüfen und Einfügen der Konfigurationen
declare -A CONFIG_ENTRIES=(
    ["'memcache.local' => '\\\\OC\\\\Memcache\\\\APCu',"]="✅ 'memcache.local' ist bereits gesetzt."
    ["'memcache.locking' => '\\\\OC\\\\Memcache\\\\Redis',"]="✅ 'memcache.locking' ist bereits gesetzt."
    ["'redis' => array (\n    'host' => 'redis',\n    'password' => '',\n    'port' => 6379,\n  ),"]="✅ Redis-Konfiguration ist bereits vorhanden."
    ["'default_phone_region' => 'DE',"]="✅ 'default_phone_region' ist bereits gesetzt."
    ["'maintenance_window_start' => 1,"]="✅ 'maintenance_window_start' ist bereits gesetzt."
)

for ENTRY in "${!CONFIG_ENTRIES[@]}"; do
    if grep -qF "$ENTRY" "$CONFIG_FILE"; then
        echo "${CONFIG_ENTRIES[$ENTRY]}"
    else
        sed -i "/);/i \\
  $ENTRY" "$CONFIG_FILE"
        echo "✅ $ENTRY erfolgreich hinzugefügt."
    fi
done

echo "✅ Alle Konfigurationen wurden aktualisiert."
