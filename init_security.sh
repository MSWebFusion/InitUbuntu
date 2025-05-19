#!/usr/bin/env bash
set -euo pipefail

# 1) Mise à jour du système
apt update
DEBIAN_FRONTEND=noninteractive apt -y upgrade

# 2) Création d'un utilisateur non-root "deployer" (si nécessaire)
if ! id deployer &>/dev/null; then
  adduser --disabled-password --gecos "" deployer
  usermod -aG sudo deployer
fi

# 3) Installation des paquets de sécurité
apt install -y ufw fail2ban

# 4) Configuration UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 1433/tcp       # port SQL Server
ufw allow 5000/tcp       # port api .NET
ufw allow 8080/tcp       # port rust api
ufw allow http           # si vous avez un serveur web
ufw allow https          # pour TLS
ufw --force enable

# 5) Activation de fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

exit 0

