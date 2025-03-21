#!/bin/bash

# Benutzer informieren
echo "Die folgenden Eingaben betreffen die MariaDB-Datenbankkonfiguration."
echo "Diese Daten werden in der Datei /mnt/docker/docker-compose.yml gespeichert und werden bei der Ersteinrichtung von Nextcloud erneut benötigt."
echo ""

# Benutzereingaben für MariaDB-Konfiguration
read -p "Bitte geben Sie ein MySQL Root Passwort ein: " MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
echo ""

read -p "Bitte geben Sie einen Namen für das Datenbank-Name ein: " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-nextcloud}
echo ""

read -p "Bitte geben Sie einen Datenbankkonto ein: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-nextcloud}
echo ""

read -p "Bitte geben Sie ein Datenbank-Passwort ein: " MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD}
echo ""

# Benutzer für Docker-Gruppe abfragen
read -p "Welchen Linux-Benutzer wird die Docker-Container verwalten?: " DOCKER_USER
echo ""

# UID und GID des Benutzers ermitteln
USER_ID=$(id -u "$DOCKER_USER")
GROUP_ID=$(id -g "$DOCKER_USER")

if [ -z "$USER_ID" ] || [ -z "$GROUP_ID" ]; then
    echo "Fehler: Der Benutzer '$DOCKER_USER' existiert nicht."
    exit 1
fi

echo "Benutzer $DOCKER_USER hat UID=$USER_ID und GID=$GROUP_ID."
echo ""

# Prüfen, ob curl installiert ist, falls nicht, curl installieren
if ! command -v curl &> /dev/null; then
    echo "curl ist nicht installiert. Installation wird durchgeführt..."
    sudo apt-get update
    sudo apt-get install -y curl
fi
echo ""
echo "Wenn Pakete fehlen werden diese installiert. Dafür muss das sudo Passwort eingegeben werden"
# Docker und Docker Compose Installation
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh  # Docker-Installationsskript ausführen
sudo apt install -y docker-compose

# Verzeichnisse erstellen
echo "Creating directories..."
sudo mkdir -p /mnt/docker/Nginx-Proxy-Manager /mnt/docker/Nextcloud /mnt/docker/Mariadb /mnt/data
sudo chown -R "$USER_ID:$GROUP_ID" /mnt/data /mnt/docker
sudo usermod -aG docker "$DOCKER_USER"

# docker-compose.yml für die Container erstellen
echo "Creating /mnt/docker/docker-compose.yml"
cat <<EOL > /mnt/docker/docker-compose.yml
version: '3.8'

services:
  mariadb:
    image: lscr.io/linuxserver/mariadb:latest
    container_name: mariadb
    environment:
      - PUID=$USER_ID
      - PGID=$GROUP_ID
      - TZ=Europe/Berlin
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    volumes:
      - /mnt/docker/Mariadb/config:/config
      - /mnt/data:/data
    ports:
      - 3306:3306
    restart: unless-stopped
    networks:
      - nextcloud_network

  nextcloud:
    image: lscr.io/linuxserver/nextcloud:latest
    container_name: nextcloud
    environment:
      - PUID=$USER_ID
      - PGID=$GROUP_ID
      - TZ=Europe/Berlin
    volumes:
      - /mnt/docker/Nextcloud/config:/config
      - /mnt/data:/data
    ports:
      - 443:443
    depends_on:
      - mariadb
    restart: unless-stopped
    networks:
      - nextcloud_network

  redis:
    container_name: redis
    image: redis:latest
    restart: unless-stopped
    networks:
      - nextcloud_network

networks:
  nextcloud_network:
    driver: bridge
EOL


newgrp docker <<EOF
cd /mnt/docker/
docker-compose up -d


SERVER_IP=$(hostname -I | awk '{print $1}')


# Warten, damit Container Zeit haben zu starten
sleep 5


# Überprüfen, ob alle Container im Status "running" sind
CONTAINERS=("mariadb" "nextcloud" "nginx-proxy-manager")
FAILED_CONTAINERS=()

for CONTAINER in "${CONTAINERS[@]}"; do
    STATUS=$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)

    if [ "$STATUS" != "true" ]; then
        FAILED_CONTAINERS+=("$CONTAINER")
    fi
done

if [ ${#FAILED_CONTAINERS[@]} -eq 0 ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo ""
    echo "✅ Alle Container wurden erfolgreich gestartet."
    echo ""
    echo "Nextcloud ist jetzt unter folgender Adresse erreichbar:"
    echo "   🌐 https://${SERVER_IP}:443"

    echo ""
    echo "📌 **Datenbank-Konfiguration für die Nextcloud-Einrichtung**"
    echo "------------------------------------------"
    echo " 🔹 **Datenbank-Typ:**      MySQL/MariaDB"
    echo " 🔹 **Datenbankkonto:**     ${MYSQL_USER}"
    echo " 🔹 **Datenbank-Passwort:** ${MYSQL_PASSWORD}"
    echo " 🔹 **Datenbank-Name:**     ${MYSQL_DATABASE}"
    echo " 🔹 **Datenbank-Host:**     mariadb:3306"
    echo "------------------------------------------"
    echo "ℹ️  Bitte notiere dir diese Daten für die Ersteinrichtung in der Nextcloud-Weboberfläche."
    echo ""

else
    echo "❌ ACHTUNG: Einige Container konnten nicht gestartet werden!"
    for CONTAINER in "${FAILED_CONTAINERS[@]}"; do
        echo "   - $CONTAINER (Status: nicht 'running')"
    done
    echo "📄 Bitte überprüfe die Logs mit:"
    echo "   docker logs <container_name>"
    exit 1
fi

EOF
