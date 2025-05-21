#!/usr/bin/env bash
set -euo pipefail

# Valeurs par défaut et validations
: "${TAG:=latest}"                  # fallback générique
: "${CSHARP_TAG:?CSHARP_TAG doit être défini par le script appelant}"
: "${DB_NAME:?      il faut passer --db-name}"
# RUST_TAG est optionnel
: "${RUST_TAG:-}"

# Usage
usage() {
  cat <<EOF
Usage: $0 \
  --sa-password SA_PASSWORD \
  --db-name DB_NAME \
  [--csharp-repo CSHARP_REPO] \
  [--rust-repo RUST_REPO] \
  [--out FILE]

Génère un docker-compose.yml en utilisant les tags de commit pour les images C# et Rust.

Options :
  --sa-password   mot de passe pour l’utilisateur sa de SQL Server
  --db-name       nom de la base à créer/utiliser
  --csharp-repo   dépôt de l’image C# (ex: ghcr.io/mswebfusion/flexibook)
  --rust-repo     dépôt de l’image Rust (ex: ghcr.io/mswebfusion/rust_api)
  --out           chemin de sortie (défaut /opt/api-backend/docker-compose.yml)
EOF
  exit 1
}

# Valeur par défaut de sortie
OUT="/opt/api-backend/docker-compose.yml"

# Lecture des arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --sa-password) SA_PASSWORD=$2; shift 2;;
    --db-name)     DB_NAME=$2;       shift 2;;
    --csharp-repo) CSHARP_REPO=$2;   shift 2;;
    --rust-repo)   RUST_REPO=$2;     shift 2;;
    --out)         OUT=$2;           shift 2;;
    *) usage;;
  esac
done

# Validations
: "${SA_PASSWORD:?– il faut passer --sa-password}"
: "${DB_NAME:?      – il faut passer --db-name}"

# Normalisation lowercase
if [[ -n "${CSHARP_REPO:-}" ]]; then
  CSHARP_REPO="${CSHARP_REPO,,}"
fi
if [[ -n "${RUST_REPO:-}" ]]; then
  RUST_REPO="${RUST_REPO,,}"
fi

# Prépare le répertoire de sortie
mkdir -p "$(dirname "$OUT")"

# Début du docker-compose
cat > "$OUT" <<EOF
services:
  sqlserver:
    container_name: sqlserver
    image: mcr.microsoft.com/mssql/server:2022-latest
    restart: unless-stopped
    environment:
      SA_PASSWORD: "${SA_PASSWORD}"
      ACCEPT_EULA: "Y"
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-data:/var/opt/mssql

EOF

# Service C#
if [[ -n "${CSHARP_REPO:-}" ]]; then
  cat >> "$OUT" <<EOF

  csharp_api:
    container_name: csharp_api
    image: ${CSHARP_REPO}:${CSHARP_TAG}
    restart: unless-stopped
    environment:
      ConnectionStrings__DefaultConnection: "Server=sqlserver;Database=${DB_NAME};User Id=sa;Password=${SA_PASSWORD};TrustServerCertificate=True;"
      ASPNETCORE_URLS: "http://+:5000"
    ports:
      - "5000:5000"
    depends_on:
      sqlserver
    volumes:
      - csharp-wwwroot:/app/wwwroot
EOF
fi

# Service Rust
if [[ -n "${RUST_REPO:-}" && -n "${RUST_TAG:-}" ]]; then
  cat >> "$OUT" <<EOF

  rust_api:
    container_name: rust_api
    image: ${RUST_REPO}:${RUST_TAG}
    restart: unless-stopped
    environment:
      DATABASE_URL: "sqlserver://sa:${SA_PASSWORD}@sqlserver:1433/${DB_NAME}"
    ports:
      - "8080:8080"
    depends_on:
      - sqlserver
EOF
fi

# Volumes
cat >> "$OUT" <<EOF

volumes:
  sqlserver-data:
EOF
if [[ -n "${CSHARP_REPO:-}" ]]; then
  cat >> "$OUT" <<EOF
  csharp-wwwroot:
EOF
fi
if [[ -n "${RUST_REPO:-}" && -n "${RUST_TAG:-}" ]]; then
  cat >> "$OUT" <<EOF
  rust-data:
EOF
fi

echo "✔️  $OUT généré avec succès (C# tag=${CSHARP_TAG}${RUST_TAG:+, Rust tag=${RUST_TAG}})."
