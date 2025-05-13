#!/usr/bin/env bash
set -euo pipefail

# 1. Met à jour et installe Docker, docker-compose et prérequis
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    software-properties-common \
    apt-transport-https \
    gnupg \
    lsb-release

# Ajout du dépôt officiel Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Universe pour docker-compose classique
sudo add-apt-repository universe -y

sudo apt update
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-compose

# Active et démarre Docker
sudo systemctl enable --now docker

# 2. Préparation du dossier de travail
WORKDIR=/opt/sqlserver-docker
sudo mkdir -p "${WORKDIR}/backups"
sudo chown "${USER}:${USER}" "${WORKDIR}" "${WORKDIR}/backups"
cd "${WORKDIR}"

# 3. Création du docker-compose.yml
cat > docker-compose.yml << 'EOF'
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: sql_express
    environment:
      ACCEPT_EULA: "Y"                    # Obligatoire pour la licence
      SA_PASSWORD: "MettreTonMdp"        # Mot de passe admin conforme
      MSSQL_PID: "Express"               # Version gratuite Express
    ports:
      - "1433:1433"                      # Expose le port SQL Server
    volumes:
      - sql_data:/var/opt/mssql          # Données persistantes
      - ./backups:/var/opt/mssql/backups # Dossier de backup local

volumes:
  sql_data:
EOF

# 4. Lancement du conteneur
docker-compose up -d

echo "✔️  SQL Server Express est en cours d’exécution dans Docker."
echo "    - Vous pouvez vérifier avec  docker-compose ps"
echo "    - Pour vous connecter :"
echo "      docker exec -it sql_express /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'mettreTonMotDePasse' -Q 'SELECT @@VERSION;'"

