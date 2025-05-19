#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 \\
  --sa-password   SA_PASSWORD \\  
  --db-name       DB_NAME \\  
  --csharp-repo   CSHARP_REPO \\  
  --rust-repo     RUST_REPO

Exemple :
  $0 \\
    --sa-password "Cjulpy4084!_;" \\
    --db-name "db_aa4484_bookingfusion" \\
    --csharp-repo "ghcr.io/MSWebFusion/flexibook" \\
    --rust-repo "ghcr.io/MSWebFusion/rust_api"
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

# Vérification que tout est passé
: "${SA_PASSWORD:?--sa-password est obligatoire}"
: "${DB_NAME:?      --db-name est obligatoire}"
: "${CSHARP_REPO:?  --csharp-repo est obligatoire}"
: "${RUST_REPO:?    --rust-repo est obligatoire}"

# --- 2) Export des variables pour les scripts ---
export SA_PASSWORD DB_NAME CSHARP_REPO RUST_REPO

# --- 3) Lancement des scripts dans l’ordre ---
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
