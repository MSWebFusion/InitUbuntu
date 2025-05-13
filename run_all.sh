#!/usr/bin/env bash
set -euo pipefail

# Assurez-vous d'être root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que root (ou avec sudo)." >&2
  exit 1
fi

# Liste des scripts à lancer dans l'ordre
SCRIPTS=(
  "init_security.sh"
  "installationSqlCmd.sh"
  "Setup_Sql-Express.sh"
)

# Vérification, chmod +x et exécution
for script in "${SCRIPTS[@]}"; do
  if [ ! -f "$script" ]; then
    echo "Erreur : le script '$script' est introuvable dans $(pwd)." >&2
    exit 1
  fi

  echo "→ Préparation de $script"
  chmod +x "$script"

  echo "→ Exécution de $script"
  bash "./$script"
done

echo "✔️  Tous les scripts ont été exécutés avec succès."

