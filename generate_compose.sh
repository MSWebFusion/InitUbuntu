#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 \
  --sa-password SA_PASSWORD \
  --db-name DB_NAME \
  --csharp-repo CSHARP_REPO \
  --rust-repo RUST_REPO \
  [--out FILE]

Génère un docker-compose.yml dans FILE (défaut ./docker-compose.yml).

  --sa-password   mot de passe pour l’utilisateur sa de SQL Server
  --db-name       nom de la base à créer/utiliser
  --csharp-repo   dépôt de l’image C# (ex: ghcr.io/MSWebFusion/flexibook)
  --rust-repo     dépôt de l’image Rust (ex: ghcr.io/MSWebFusion/rust_api)
  --out           chemin de sortie (par défaut docker-compose.yml)
EOF
  exit 1
}

# Lecture des arguments
OUT=./docker-compose.yml
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

# Vérification
: "${SA_PASSWORD:?– il faut passer --sa-password}"
: "${DB_NAME:?      – il faut passer --db-name}"
: "${CSHARP_REPO:?  – il faut passer --csharp-repo}"
: "${RUST_REPO:?    – il faut passer --rust-repo}"

# Génération
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

  csharp_api:
    container_name: csharp_api
    image: ${CSHARP_REPO}:\${TAG}
    restart: unless-stopped
    environment:
      ConnectionStrings__DefaultConnection: "Server=sqlserver;Database=${DB_NAME};User Id=sa;Password=${SA_PASSWORD};"
      ASPNETCORE_URLS: "http://+:5000"
    ports:
      - "5000:5000"
    depends_on:
      - sqlserver
    volumes:
      - csharp-wwwroot:/app/wwwroot

  rust_api:
    container_name: rust_api
    image: ${RUST_REPO}:\${TAG}
    restart: unless-stopped
    environment:
      DATABASE_URL: "sqlserver://sa:${SA_PASSWORD}@sqlserver:1433/${DB_NAME}"
    ports:
      - "8080:8080"
    depends_on:
      - sqlserver

volumes:
  sqlserver-data:
  csharp-wwwroot:
  rust-data:  # décommente si nécessaire
EOF

echo "✔️  $OUT généré avec succès."
