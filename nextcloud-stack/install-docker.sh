#!/bin/bash

# Benutzer informieren
echo "Die folgenden Eingaben betreffen die MariaDB-Datenbankkonfiguration."
echo "Diese Daten werden in der Datei /mnt/docker/Mariadb/docker-compose.yml gespeichert und werden bei der Ersteinrichtung von Nextcloud erneut benötigt."

# Benutzereingaben für MariaDB-Konfiguration
echo "Bitte geben Sie ein MySQL Root Passwort ein:"
read MYSQL_ROOT_PASSWORD
echo "Bitte geben Sie einen MySQL Datenbanknamen ein (Standard: nextcloud):"
read MYSQL_DATABASE
MYSQL_DATABASE=${MYSQL_DATABASE:-nextcloud}
echo "Bitte geben Sie einen MySQL Benutzernamen ein (Standard: nextcloud):"
read MYSQL_USER
MYSQL_USER=${MYSQL_USER:-nextcloud}
echo "Bitte geben Sie ein MySQL Benutzerpasswort ein:"
read MYSQL_PASSWORD

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

# Verzeichnisse erstellen
echo "Creating directories..."
mkdir -p /mnt/docker/Nginx-Proxy-Manager /mnt/docker/Nextcloud /mnt/docker/Mariadb

# docker-compose.yml für MariaDB erstellen
echo "Creating MariaDB docker-compose.yml..."
cat <<EOL > /mnt/docker/Mariadb/docker-compose.yml
---
services:
  mariadb:
    image: lscr.io/linuxserver/mariadb:latest
    container_name: mariadb
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Berlin
      - MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
      - MYSQL_DATABASE=$MYSQL_DATABASE
      - MYSQL_USER=$MYSQL_USER
      - MYSQL_PASSWORD=$MYSQL_PASSWORD
      - REMOTE_SQL=http://URL1/your.sql,https://URL2/your.sql #optional
    volumes:
      - /mnt/docker/Mariadb/config:/config
    ports:
      - 3306:3306
    restart: unless-stopped
EOL

echo "Die Konfiguration wurde in /mnt/docker/Mariadb/docker-compose.yml gespeichert."

# docker-compose.yml für Nextcloud erstellen
echo "Creating Nextcloud docker-compose.yml..."
cat <<EOL > /mnt/docker/Nextcloud/docker-compose.yml
---
services:
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
    restart: unless-stopped
EOL

# docker-compose.yml für Nginx Proxy Manager erstellen
echo "Creating Nginx Proxy Manager docker-compose.yml..."
cat <<EOL > /mnt/docker/Nginx-Proxy-Manager/docker-compose.yml
services:
  app:
    image: 'docker.io/jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '20080:80'
      - '20081:81'
      - '20443:443'
    volumes:
      - /mnt/docker/Nginx-Proxy-Manager/data:/data
      - /mnt/docker/Nginx-Proxy-Manager/letsencrypt:/etc/letsencrypt
EOL

# MariaDB Container starten
echo "Starting MariaDB..."
docker run -d \
  --name mariadb \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Berlin \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e MYSQL_DATABASE=$MYSQL_DATABASE \
  -e MYSQL_USER=$MYSQL_USER \
  -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
  -v /mnt/docker/Mariadb/config:/config \
  -p 3306:3306 \
  --restart unless-stopped \
  lscr.io/linuxserver/mariadb:latest

# Nextcloud Container starten
echo "Starting Nextcloud..."
docker run -d \
  --name nextcloud \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Berlin \
  -v /mnt/docker/Nextcloud/config:/config \
  -v /mnt/data:/data \
  -p 443:443 \
  --restart unless-stopped \
  lscr.io/linuxserver/nextcloud:latest

# Nginx Proxy Manager Container starten
echo "Starting Nginx Proxy Manager..."
docker run -d \
  --name nginx-proxy-manager \
  -v /mnt/docker/Nginx-Proxy-Manager/data:/data \
  -v /mnt/docker/Nginx-Proxy-Manager/letsencrypt:/etc/letsencrypt \
  -p 20080:80 \
  -p 20081:81 \
  -p 20443:443 \
  --restart unless-stopped \
  jc21/nginx-proxy-manager:latest

echo "Alle Container wurden erfolgreich gestartet."

