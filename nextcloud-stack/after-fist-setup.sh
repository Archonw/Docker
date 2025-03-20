#!/bin/bash

CONFIG_FILE="/mnt/docker/Nextcloud/config/www/nextcloud/config/config.php"
BACKUP_FILE="${CONFIG_FILE}.bak"

# Überprüfen, ob die Datei existiert
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Fehler: Die Datei $CONFIG_FILE wurde nicht gefunden!"
    exit 1
fi

# Prüfen, ob die Konfiguration bereits existiert
if grep -q "'memcache.locking' => '\\\\OC\\\\Memcache\\\\Redis'," "$CONFIG_FILE"; then
    echo "✅ Redis-Konfiguration ist bereits vorhanden."
else
    # Backup der Datei erstellen
    cp "$CONFIG_FILE" "$BACKUP_FILE"

    # Redis-Konfiguration hinzufügen
    sed -i "/);/i \
  'memcache.locking' => '\\\\OC\\\\Memcache\\\\Redis',\n\
  'redis' => array (\n\
    'host' => 'redis',\n\
    'password' => '',\n\
    'port' => 6379,\n\
  )," "$CONFIG_FILE"

    echo "✅ Redis-Konfiguration erfolgreich hinzugefügt."
fi

# Prüfen, ob 'default_phone_region' bereits existiert
if grep -q "'default_phone_region' => 'DE'," "$CONFIG_FILE"; then
    echo "✅ 'default_phone_region' ist bereits gesetzt."
else
    sed -i "/);/i \
  'default_phone_region' => 'DE'," "$CONFIG_FILE"
    echo "✅ 'default_phone_region' erfolgreich hinzugefügt."
fi

# Prüfen, ob 'maintenance_window_start' bereits existiert
if grep -q "'maintenance_window_start' => 1," "$CONFIG_FILE"; then
    echo "✅ 'maintenance_window_start' ist bereits gesetzt."
else
    sed -i "/);/i \
  'maintenance_window_start' => 1," "$CONFIG_FILE"
    echo "✅ 'maintenance_window_start' erfolgreich hinzugefügt."
fi

echo "📄 Backup wurde erstellt: $BACKUP_FILE"
