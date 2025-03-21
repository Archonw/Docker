#!/bin/bash

# Benutzer informieren
echo "Dieses Skript installiert Vaultwarden als Docker-Container."
echo ""

# Admin-Token abfragen
read -sp "Bitte geben Sie den Admin-Token für Vaultwarden ein: " ADMIN_TOKEN
echo ""

# Verzeichnis für Vaultwarden erstellen
DOCKER_DIR="/mnt/docker/vaultwarden"
mkdir -p "$DOCKER_DIR"

# docker-compose.yml für Vaultwarden erstellen
echo "📝 Erstelle docker-compose.yml für Vaultwarden..."
cat <<EOL > "$INSTALL_DIR/docker-compose.yml"
version: '3.8'

services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      - SIGNUPS_ALLOWED=false
      - INVITATIONS_ALLOWED=true
      - WEBSOCKET_ENABLED=true
      - LOG_FILE=/data/vaultwarden.log
      - USE_SYSLOG=true
      - EXTENDED_LOGGING=true
      - LOG_LEVEL=error
      - ADMIN_TOKEN=${ADMIN_TOKEN}
    volumes:
      - /mnt/docker/vaultwarden/data:/data
    ports:
      - "4743:80"  # WebUI Port
    networks:
      - nextcloud_network

networks:
  nextcloud_network:
    driver: bridge

EOL

# Vaultwarden-Container starten
echo "🚀 Starte Vaultwarden-Container..."
cd "$DOCKER_DIR"
docker-compose up -d

SERVER_IP=$(hostname -I | awk '{print $1}')


# Warten, damit Container Zeit haben zu starten
sleep 5


# Überprüfen, ob alle Container im Status "running" sind
CONTAINERS=("vaultwarden")
FAILED_CONTAINERS=()

for CONTAINER in "${CONTAINERS[@]}"; do
    STATUS=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)

    if [ "$STATUS" != "true" ]; then
        FAILED_CONTAINERS+=("$CONTAINER")
    fi
done

if [ ${#FAILED_CONTAINERS[@]} -eq 0 ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')


# Erfolgsmeldung
echo ""
echo "✅ Vaultwarden wurde erfolgreich installiert!"
echo "📌 Webinterface: http://$(hostname -I | awk '{print $1}'):4743/admin"
echo ""



else
    echo "❌ ACHTUNG: Der Container konnten nicht gestartet werden!"
    for CONTAINER in "${FAILED_CONTAINERS[@]}"; do
        echo "   - $CONTAINER (Status: nicht 'running')"
    done
    echo "📄 Bitte überprüfe die Logs mit:"
    echo "   docker logs <container_name>"
    exit 1
fi
