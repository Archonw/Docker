#!/bin/bash

# Benutzer informieren
echo "Die folgenden Eingaben betreffen die MariaDB-Datenbankkonfiguration."
echo "Diese Daten werden in der Datei /mnt/docker/Mariadb/docker-compose.yml gespeichert und werden bei der Ersteinrichtung von Nextcloud erneut benötigt."

# Benutzereingaben für MariaDB-Konfiguration
echo "Bitte geben Sie ein MySQL Root Passwort ein:"
read MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
echo "Bitte geben Sie einen Namen für das Datenbankkonto ein:"
read MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-nextcloud}
echo "Bitte geben Sie einen Datenbank-Name ein:"
read MYSQL_USER
MYSQL_USER=${MYSQL_USER:-nextcloud}
echo "Bitte geben Sie ein Datenbank-Passwort ein:"
read MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# Prüfen, ob curl installiert ist, falls nicht, curl installieren
if ! command -v curl &> /dev/null
then
    echo "curl is not installed. Installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl
fi

# Docker und Docker Compose Installation
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh  # Docker-Installationsskript ausführen
sudo apt install docker-compose

# Verzeichnisse erstellen
echo "Creating directories..."
sudo mkdir -p /mnt/docker/Nginx-Proxy-Manager /mnt/docker/Nextcloud /mnt/docker/Mariadb /mnt/data
sudo chown -R 1000:1000 /mnt/data /mnt/docker
sudo usermod -aG docker nextcloud

# docker-compose.yml für die Container erstellen
echo "Creating /mnt/docker/docker-compose.yml"
cat <<EOL > /mnt/docker/docker-compose.yml
version: '3.8'

services:
  mariadb:
    image: lscr.io/linuxserver/mariadb:latest
    container_name: mariadb
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE:-nextcloud}
      - MYSQL_USER=${MYSQL_USER:-nextcloud}
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
      - PUID=1000
      - PGID=1000
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

echo "Alle Container wurden erfolgreich gestartet." 
