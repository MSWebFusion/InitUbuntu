#!/usr/bin/env bash
set -euo pipefail

# Avant apt-get install…
apt update

echo "⏳ Attente du verrou dpkg…"
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done
# 1) Installation Docker + Compose
apt install -y \
    ca-certificates \
    curl \
    software-properties-common \
    apt-transport-https \
    gnupg \
    lsb-release

# Ajout du dépôt officiel Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

# Universe pour docker-compose-plugin
add-apt-repository universe -y


apt update

# Avant apt-get install…
echo "⏳ Attente du verrou dpkg…"
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done

apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Active Docker
systemctl enable --now docker

# 2) Ajout de deployer au groupe docker
usermod -aG docker deployer

# 3) Préparation du dossier de travail
WORKDIR=/opt/api-backend
mkdir -p "${WORKDIR}"
chown deployer:deployer "${WORKDIR}"
cd "${WORKDIR}"

# 3.1) Génération automatique du docker-compose.yml
#    On suppose que generate_compose.sh est exécutable et dans le même dossier que run_all.sh
echo "→ Génération de ${WORKDIR}/docker-compose.yml"
bash /chemin/vers/generate_compose.sh \
  --sa-password "${SA_PASSWORD}" \
  --db-name     "${DB_NAME}" \
  --csharp-repo "${CSHARP_REPO}" \
  --rust-repo   "${RUST_REPO}" \
  --out         "${WORKDIR}/docker-compose.yml"
# On remet la bonne ownership sur le fichier
chown deployer:deployer "${WORKDIR}/docker-compose.yml"

# 4) Vérification de ton docker-compose.yml
if [ ! -f docker-compose.yml ]; then
  echo "❌ Erreur : docker-compose.yml introuvable dans ${WORKDIR}"
  exit 1
fi

# 5) Déploiement des services
# on pull d'abord pour s'assurer d'avoir les dernières images
docker compose pull sqlserver csharp_api rust_api

# on recrée uniquement csharp_api et rust_api (sqlserver reste intact)
docker compose up -d --no-deps --force-recreate csharp_api rust_api

echo "✔️  Services SQL, C# et Rust déployés."
