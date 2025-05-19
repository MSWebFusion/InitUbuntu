#!/usr/bin/env bash
set -euo pipefail

# Récupère le dossier du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Définit un TAG par défaut si non fourni\ nTAG="${TAG:-latest}"

# 0) Installer git pour les builds locaux
echo "→ Mise à jour et installation de git"
apt update
# Attente du verrou dpkg
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done
apt install -y git

# 1) Installation Docker + Compose
echo "→ Installation de Docker et Docker Compose"
# Attente du verrou dpkg
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done
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
# Attente du verrou dpkg
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  sleep 5
done
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker

# 2) Ajout de deployer au groupe docker
echo "→ Ajout de 'deployer' au groupe docker"
usermod -aG docker deployer

# 3) Préparation du dossier de travail
WORKDIR=/opt/api-backend
echo "→ Préparation de ${WORKDIR}"
mkdir -p "${WORKDIR}"
chown deployer:deployer "${WORKDIR}"
cd "${WORKDIR}"

# 4) Build d'images locales si les dépôts Git sont fournis
if [[ -n "${CSHARP_GIT_REPO:-}" ]]; then
  echo "→ Build de l'image C# depuis ${CSHARP_GIT_REPO}"
  rm -rf csharp_src
  git clone "${CSHARP_GIT_REPO}" csharp_src

  # chemin relatif vers le dossier qui contient le Dockerfile
  CS_SRC_DIR="csharp_src/Api/Api"

  # on vérifie que le Dockerfile existe bien
  if [[ ! -f "${CS_SRC_DIR}/Dockerfile" ]]; then
    echo "❌ Impossible de trouver ${CS_SRC_DIR}/Dockerfile"
    exit 1
  fi

  # build en pointant le Dockerfile et le contexte sur ce dossier
  docker build --pull \
    -t "${CSHARP_REPO}:${TAG}" \
    -f "${CS_SRC_DIR}/Dockerfile" \
    "${CS_SRC_DIR}"
fi

if [[ -n "${RUST_GIT_REPO:-}" ]]; then
  echo "→ Build de l'image Rust depuis ${RUST_GIT_REPO}"
  rm -rf rust_src
  git clone "${RUST_GIT_REPO}" rust_src

  # chemin relatif vers le dossier qui contient le Dockerfile Rust
  RUST_SRC_DIR="rust_src/Api/Api"

  # on vérifie que le Dockerfile existe bien
  if [[ ! -f "${RUST_SRC_DIR}/Dockerfile" ]]; then
    echo "❌ Impossible de trouver ${RUST_SRC_DIR}/Dockerfile"
    exit 1
  fi

  # build en pointant le Dockerfile et le contexte sur ce dossier
  docker build --pull \
    -t "${RUST_REPO}:${TAG}" \
    -f "${RUST_SRC_DIR}/Dockerfile" \
    "${RUST_SRC_DIR}"
fi

# 5) Génération automatique du docker-compose.yml
echo "→ Génération de ${WORKDIR}/docker-compose.yml"
bash "${SCRIPT_DIR}/generate_compose.sh" \
  --sa-password "${SA_PASSWORD}" \
  --db-name     "${DB_NAME}" \
  --csharp-repo "${CSHARP_REPO}" \
  --rust-repo   "${RUST_REPO}" \
  --out         "${WORKDIR}/docker-compose.yml"
chown deployer:deployer "${WORKDIR}/docker-compose.yml"

# 6) Vérification du docker-compose.yml
if [ ! -f docker-compose.yml ]; then
  echo "❌ Erreur : docker-compose.yml introuvable dans ${WORKDIR}"
  exit 1
fi

# 7) Auth GitHub Container Registry (optionnel)
if [[ -n "${GHCR_USER:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  echo "→ Authentification à GitHub Container Registry…"
  docker login ghcr.io -u "${GHCR_USER}" -p "${GHCR_TOKEN}" || \
    echo "⚠️  Échec login GHCR, je continue sans auth."
else
  echo "ℹ️  Pas de GHCR_USER/GHCR_TOKEN, pull en public."
fi

# 8) Pull et démarrage des services
echo "→ Pull des images Docker"
docker compose pull
echo "→ Démarrage des services"
docker compose up -d --force-recreate

echo "✔️  Services SQL, C# et Rust déployés."
