#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 \\
  --server-ip     <IP_ADDRESS>   # IP ou hostname de ton VPS \\
  --repo           <REPO_NAME>   # nom du dépôt infra (sans org ni .git) \\
  --sa-password    <SA_PWD>      # mot de passe SA pour SQL Server \\
  --db-name        <DB_NAME>     # nom de la base à utiliser \\
  --csharp-repo    <CSHARP_REPO> # ex: ghcr.io/MSWebFusion/flexibook \\
  --rust-repo      <RUST_REPO>   # ex: ghcr.io/MSWebFusion/rust_api

Exemple :
  export GITHUB_TOKEN=ghp_…
  ./bootstrap.sh \\
    --server-ip     46.202.175.110 \\
    --repo          mon-repo-d-infra \\
    --sa-password   "Cjulpy4084!_;" \\
    --db-name       db_aa4484_bookingfusion \\
    --csharp-repo   ghcr.io/MSWebFusion/flexibook \\
    --rust-repo     ghcr.io/MSWebFusion/rust_api
EOF
  exit 1
}

# --- 1) Parse des arguments ---
if [[ $# -lt 12 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-ip)
      SERVER_IP="$2"; shift 2;;
    --repo)
      REPO_NAME="$2"; shift 2;;
    --sa-password)
      SA_PASSWORD="$2"; shift 2;;
    --db-name)
      DB_NAME="$2"; shift 2;;
    --csharp-repo)
      CSHARP_REPO="$2"; shift 2;;
    --rust-repo)
      RUST_REPO="$2"; shift 2;;
    *)
      echo "❌ Option inconnue : $1"
      usage
      ;;
  esac
done

# --- 2) Vérifications ---
: "${GITHUB_TOKEN:?Il faut exporter GITHUB_TOKEN avant d'appeler ce script.}"
: "${SERVER_IP:?--server-ip est obligatoire}"
: "${REPO_NAME:?--repo est obligatoire}"
: "${SA_PASSWORD:?--sa-password est obligatoire}"
: "${DB_NAME:?--db-name est obligatoire}"
: "${CSHARP_REPO:?--csharp-repo est obligatoire}"
: "${RUST_REPO:?--rust-repo est obligatoire}"

SSH_USER="root"
REMOTE_DIR="/opt/bootstrap"
GITHUB_USER="MSWebFusion"

echo "→ Bootstrap sur ${SERVER_IP}, dépôt '${REPO_NAME}', base '${DB_NAME}'."

# --- 3) Installer Git sur le serveur ---
ssh "${SSH_USER}@${SERVER_IP}" <<'EOF'
  set -euo pipefail
  apt update
  apt install -y git
EOF

# --- 4) Cloner le repo en HTTPS ---
ssh "${SSH_USER}@${SERVER_IP}" bash -lc " \
  rm -rf ${REMOTE_DIR} && \
  mkdir -p ${REMOTE_DIR} && \
  git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${REPO_NAME}.git ${REMOTE_DIR} \
"

# --- 5) Lancer run_all.sh avec tes paramètres dynamiques ---
ssh "${SSH_USER}@${SERVER_IP}" bash -lc " \
  cd ${REMOTE_DIR} && \
  chmod +x *.sh && \
  sudo ./run_all.sh \
    --sa-password '${SA_PASSWORD}' \
    --db-name     '${DB_NAME}' \
    --csharp-repo '${CSHARP_REPO}' \
    --rust-repo   '${RUST_REPO}' \
"

echo "✔️  Bootstrap terminé sur ${SERVER_IP}, repo '${REPO_NAME}' cloné et provisioning lancé."
