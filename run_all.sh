#!/usr/bin/env bash
set -euo pipefail


export GHCR_USER="mswebfusion"
export GHCR_TOKEN="ghp_XXXXXXXXXXXXXXXXXXXX"

# valeur par défaut si non fourni
TAG="latest"

# initialisation pour éviter unbound variable
CSHARP_REPO="${CSHARP_REPO:-}"
RUST_REPO="${RUST_REPO:-}"

usage() {
  cat <<EOF
Usage: $0 \\
  --sa-password   SA_PASSWORD \\  
  --db-name       DB_NAME \\  
  [--tag          TAG (default: latest)] \\  
  [--csharp-repo  <owner>/<repo>] \\  
  [--rust-repo    <owner>/<repo>]

Exemple :
  $0 \\
    --sa-password "Cjulpy4084!_;" \\
    --db-name "db_aa4484_bookingfusion" \\
    --tag "v1.0.0" \\
    --csharp-repo "MSWebFusion/flexibook" \\
    --rust-repo "MSWebFusion/rust_api"
EOF
  exit 1
}

# --- 1) Parse des arguments ---
if [[ $# -eq 0 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sa-password)
      SA_PASSWORD="$2"; shift 2;;
    --db-name)
      DB_NAME="$2"; shift 2;;
    --tag)
      TAG="$2"; shift 2;;
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

# --- 1.b) Préfixage automatique et lowercase ---
if [[ -n "${CSHARP_REPO}" ]]; then
  # lowercase
  CSHARP_REPO="${CSHARP_REPO,,}"
  # ajoute ghcr.io/ si absent
  if [[ "${CSHARP_REPO}" != ghcr.io/* ]]; then
    CSHARP_REPO="ghcr.io/${CSHARP_REPO}"
  fi
fi

if [[ -n "${RUST_REPO}" ]]; then
  RUST_REPO="${RUST_REPO,,}"
  if [[ "${RUST_REPO}" != ghcr.io/* ]]; then
    RUST_REPO="ghcr.io/${RUST_REPO}"
  fi
fi

# --- 1.c) Déduction des URLs Git pour build local ---
if [[ -n "${CSHARP_REPO}" ]]; then
  repo_path="${CSHARP_REPO#ghcr.io/}"
  CSHARP_GIT_REPO="https://github.com/${repo_path}.git"
fi
if [[ -n "${RUST_REPO}" ]]; then
  repo_path="${RUST_REPO#ghcr.io/}"
  RUST_GIT_REPO="https://github.com/${repo_path}.git"
fi

# --- 2) Validation des obligatoires ---
: "${SA_PASSWORD:?--sa-password est obligatoire}"
: "${DB_NAME:?      --db-name est obligatoire}"

# --- 3) Export des variables pour les scripts enfants ---
export SA_PASSWORD DB_NAME TAG
export CSHARP_REPO RUST_REPO
export CSHARP_GIT_REPO RUST_GIT_REPO

# --- 4) Lancement des scripts dans l’ordre ---
SCRIPTS=(
  init_security.sh
  installationSqlCmd.sh
  Setup_Sql-Express.sh
)

for script in "${SCRIPTS[@]}"; do
  if [[ ! -f "$script" ]]; then
    echo "❌ Fichier introuvable : $script"
    exit 1
  fi
  chmod +x "$script"
  echo "→ Exécution de $script"
  bash "./$script"
done

echo "✔️  run_all.sh : tout a été installé et déployé avec succès."
