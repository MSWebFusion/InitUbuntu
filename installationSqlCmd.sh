#!/bin/bash
set -euo pipefail

echo "🔧 Ajout de la clé GPG Microsoft..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
  | sudo apt-key add -

echo "📦 Ajout du dépôt pour Ubuntu 22.04 (compatible avec 24.04)..."
echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" \
  | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

echo "🔄 Mise à jour des paquets..."
sudo apt update

echo "📥 Installation de mssql-tools et unixODBC..."
sudo ACCEPT_EULA=Y apt install -y mssql-tools unixodbc-dev

echo "🛠️ Ajout de sqlcmd et bcp au PATH pour tous les utilisateurs..."
# Création d'un script dans /etc/profile.d pour ajouter au PATH
sudo tee /etc/profile.d/mssql-tools.sh > /dev/null << 'EOF'
# Microsoft SQL Tools
export PATH="\$PATH:/opt/mssql-tools/bin"
EOF
sudo chmod 644 /etc/profile.d/mssql-tools.sh

echo "🔗 Création de liens symboliques dans /usr/local/bin..."
sudo ln -sf /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd
sudo ln -sf /opt/mssql-tools/bin/bcp    /usr/local/bin/bcp

echo "✅ Installation terminée !"
echo "   Vous pouvez maintenant lancer par exemple :"
echo "     sqlcmd -S localhost -U SA -P 'VotreMotDePasse' -Q 'SELECT @@VERSION;'"
