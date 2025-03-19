#!/bin/bash

# Benutzer informieren
echo "Die folgenden Eingaben betreffen die MariaDB-Datenbankkonfiguration."
echo "Diese Daten werden in der Datei /mnt/docker/Mariadb/docker-compose.yml gespeichert und werden bei der Ersteinrichtung von Nextcloud erneut benötigt."

# Benutzereingaben für MariaDB-Konfiguration
read -p "Bitte geben Sie ein MySQL Root Passwort ein: " MYSQL_ROOT_PASSWORD
read -p "Bitte geben Sie einen Namen für das Datenbankkonto ein (Standard: nextcloud): " MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-nextcloud}
read -p "Bitte geben Sie einen Datenbank-Namen ein (Standard: nextcloud): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-nextcloud}
read -p "Bitte geben Sie ein Datenbank-Passwort ein: " MYSQL_PASSWORD

# Benutzer für Docker-Gruppe abfragen
read -p "Welchen Benutzer möchten Sie zur Docker-Gruppe hinzufügen? " DOCKER_USER

# UID und GID des Benutzers ermitteln
USER_ID=$(id -u "$DOCKER_USER")
GROUP_ID=$(id -g "$DOCKER_USER")

if [ -z "$USER_ID" ] || [ -z "$GROUP_ID" ]; then
    echo "Fehler: Der Benutzer '$DOCKER_USER' existiert nicht."
    exit 1
fi

echo "Benutzer $DOCKER_USER hat UID=$USER_ID und GID=$GROUP_ID."

# Prüfen, ob curl installiert ist, falls nicht, curl installieren
if ! command -v curl &> /dev/null; then
    echo "curl ist nicht installiert. Installation wird durchgeführt..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

# Docker und Docker Compose Installation
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh  # Docker-Installationsskript ausführen
sudo apt install -y docker-compose

# Verzeichnisse erstellen
echo "Creating directories..."
sudo mkdir -p /mnt/docker/Nginx-Proxy-Manager /mnt/docker/Nextcloud /mnt/docker/Mariadb /mnt/data
<<<<<<< HEAD:nextcloud-stack/nextcloud-stack-installer.sh
sudo chown -R "$USER_ID:$GROUP_ID" /mnt/data /mnt/docker
sudo usermod -aG docker "$DOCKER_USER"
=======
sudo chown -R 1000:1000 /mnt/data /mnt/docker
sudo usermod -aG docker nextcloud
>>>>>>> 54ce4f418027e16f3b9f84b310ee1832f974ea41:nextcloud-stack/install-docker.sh

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

  nginx-proxy-manager:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - '20080:80'
      - '20081:81'
      - '20443:443'
    volumes:
      - /mnt/docker/Nginx-Proxy-Manager/data:/data
      - /mnt/docker/Nginx-Proxy-Manager/letsencrypt:/etc/letsencrypt
    networks:
      - nextcloud_network

networks:
  nextcloud_network:
    driver: bridge
EOL


cd /mnt/docker/ && docker-compose up -d


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
    echo "✅ Alle Container wurden erfolgreich gestartet."
    echo "Nextcloud ist jetzt unter folgender Adresse erreichbar:"
    echo "🌐 https://${SERVER_IP}:443"
else
    echo "❌ ACHTUNG: Einige Container konnten nicht gestartet werden!"
    for CONTAINER in "${FAILED_CONTAINERS[@]}"; do
        echo "   - $CONTAINER (Status: nicht 'running')"
    done
    echo "📄 Bitte überprüfe die Logs mit:"
    echo "   docker logs <container_name>"
    exit 1
fi

