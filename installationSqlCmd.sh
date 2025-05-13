#!/bin/bash
set -euo pipefail

echo "🧹 Suppression d'éventuelles installations précédentes..."
sudo apt-get remove --purge -y mssql-tools unixodbc-dev || true
sudo rm -f /etc/apt/sources.list.d/mssql-release.list

echo "🔧 Ajout de la clé GPG Microsoft (si nécessaire)..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

echo "📦 Ajout du dépôt pour Ubuntu 22.04 (compatible avec Ubuntu 24.04)..."
echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

echo "🔄 Mise à jour des paquets..."
sudo apt-get update

echo "📥 Installation de mssql-tools et unixODBC avec acceptation de la licence..."
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

echo "🛠️ Ajout immédiat de sqlcmd et bcp au PATH pour cette session..."
export PATH="$PATH:/opt/mssql-tools/bin"

echo "🗂️ Ajout permanent au PATH pour tous les utilisateurs via /etc/profile.d..."
sudo tee /etc/profile.d/mssql-tools.sh > /dev/null << 'EOF'
# Microsoft SQL Tools
export PATH="\$PATH:/opt/mssql-tools/bin"
EOF
sudo chmod 644 /etc/profile.d/mssql-tools.sh

echo "🔗 Création de liens symboliques dans /usr/local/bin..."
sudo ln -sf /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd
sudo ln -sf /opt/mssql-tools/bin/bcp /usr/local/bin/bcp

echo "🧪 Vérification de l'installation de sqlcmd..."
if command -v sqlcmd >/dev/null 2>&1; then
  echo "✅ sqlcmd est disponible et fonctionnel :"
  sqlcmd -? | head -n 5
else
  echo "❌ ERREUR : sqlcmd n'est pas détecté. Vérifiez manuellement l'installation."
  exit 1
fi

echo "🎉 Installation terminée avec succès !"
echo "   Exemple : sqlcmd -S localhost -U SA -P 'VotreMotDePasse' -Q 'SELECT @@VERSION;'"
