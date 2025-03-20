#!/bin/bash

# Test, ob der Benutzer auf den Docker-Daemon zugreifen kann
if ! docker info &>/dev/null; then
    echo "❌ Fehler: Der aktuelle Benutzer hat keine Berechtigung, Docker-Befehle auszuführen."
    echo "ℹ️  Bitte melde dich einmal ab und wieder an, um die neuen Gruppenrechte zu übernehmen."
    echo "🔄 Danach kannst du das Skript erneut starten."
    exit 1
fi

echo "✅ Benutzer hat Docker-Berechtigungen. Skript wird fortgesetzt..."

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

# Funktion zum sicheren Einfügen einer Konfiguration
add_config_entry() {
    local key="$1"
    local value="$2"

    if grep -qE "^[[:space:]]*'$key'" "$CONFIG_FILE"; then
        echo "✅ $key ist bereits gesetzt."
    else
        sed -i "/);/i \\
  '$key' => $value," "$CONFIG_FILE"
        echo "✅ $key erfolgreich hinzugefügt."
    fi
}

# mimetypes migtration Anpassung
docker exec -it nextcloud occ maintenance:repair --include-expensive
echo "Mimetypes migrations wurde ausgeführ"

# fehlende Indizes einfügen
docker exec -it nextcloud occ db:add-missing-indices
echo "Fehlende Indizes wurden ergänzt"

# Einträge setzen
add_config_entry "memcache.local" "'\\\\OC\\\\Memcache\\\\APCu'"
add_config_entry "memcache.locking" "'\\\\OC\\\\Memcache\\\\Redis'"

# Redis-Block nur hinzufügen, wenn er nicht existiert
if ! grep -qE "^[[:space:]]*'redis'" "$CONFIG_FILE"; then
    sed -i "/);/i \\
  'redis' => array (\\
    'host' => 'redis',\\
    'password' => '',\\
    'port' => 6379,\\
  )," "$CONFIG_FILE"
    echo "✅ Redis-Konfiguration erfolgreich hinzugefügt."
else
    echo "✅ Redis-Konfiguration ist bereits vorhanden."
fi

# Phone Region & Maintenance Window prüfen
add_config_entry "default_phone_region" "'DE'"
add_config_entry "maintenance_window_start" "1"

echo "✅ Alle Konfigurationen wurden aktualisiert."
