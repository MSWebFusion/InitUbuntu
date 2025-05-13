#!/bin/bash

echo "🔧 Ajout de la clé GPG Microsoft..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

echo "📦 Ajout du dépôt pour Ubuntu 22.04 (compatible avec 24.04)..."
echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | sudo tee /etc/apt/sources.list.d/mssql-release.list

echo "🔄 Mise à jour des paquets..."
sudo apt update

echo "📥 Installation de mssql-tools et unixODBC..."
sudo ACCEPT_EULA=Y apt install -y mssql-tools unixodbc-dev

echo "🛠️ Ajout de sqlcmd au PATH..."
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

echo "✅ Installation terminée ! Tu peux maintenant lancer :"
echo "   sqlcmd -S localhost -U SA -P 'TonMotDePasse'"

