
#!/bin/bash

echo "🔧 Dieses Skript installiert den Nginx Proxy Manager als Docker-Container."

# Speicherpfad für die docker-compose.yml
DOCKER_DIR="/mnt/docker/nginx-proxy-manager"

# Verzeichnis erstellen, falls nicht vorhanden
echo "📂 Erstelle Verzeichnis: $DOCKER_DIR"
sudo mkdir -p "$DOCKER_DIR"
sudo chown $(id -u):$(id -g) "$DOCKER_DIR"

# docker-compose.yml erstellen
echo "📝 Erstelle docker-compose.yml..."
cat <<EOL > "$DOCKER_DIR/docker-compose.yml"
version: '3.8'

services:
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

# Docker-Container starten
echo "🚀 Starte Nginx Proxy Manager..."
cd "$DOCKER_DIR"
docker-compose up -d

# Erfolgsmeldung
echo "✅ Nginx Proxy Manager wurde erfolgreich installiert!"
echo "📌 Webinterface erreichbar unter: http://<SERVER-IP>:20081"
