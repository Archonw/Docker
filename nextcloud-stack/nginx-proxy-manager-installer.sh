
#!/bin/bash

# Benutzer informieren
echo "Dieses Skript installiert Nginx-Proxy-Manager als Docker-Container."
echo ""

# Speicherpfad für die docker-compose.yml
DOCKER_DIR="/mnt/docker/nginx-proxy-manager"

# Verzeichnis erstellen, falls nicht vorhanden
echo "📂 Erstelle Verzeichnis: $DOCKER_DIR"
sudo mkdir -p "$DOCKER_DIR"
sudo chown $(id -u):$(id -g) "$DOCKER_DIR"

# docker-compose.yml erstellen
echo "📝 Erstelle docker-compose.yml für Nginx-Proxy-Manager..."
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

# Warten, damit Container Zeit haben zu starten
sleep 5


# Überprüfen, ob alle Container im Status "running" sind
CONTAINERS=("nginx-proxy-manager")
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
echo "✅ Nginx-Proxy-Manager wurde erfolgreich installiert!"
echo "📌 Webinterface: http://$(hostname -I | awk '{print $1}'):20081"
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
