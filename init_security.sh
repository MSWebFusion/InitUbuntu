#!/usr/bin/env bash
set -euo pipefail

# 1) Mise à jour du système
apt update
DEBIAN_FRONTEND=noninteractive apt -y upgrade

# 2) Création de l’utilisateur non-root "deployer" (si nécessaire)
if ! id deployer &>/dev/null; then
  adduser --disabled-password --gecos "" deployer
  usermod -aG sudo deployer
fi

# 3) Génération et installation d’une paire SSH pour deployer
KEY_PATH=/root/deployer_ed25519
if [ ! -f "${KEY_PATH}" ]; then
  echo "→ Génération de la clé SSH pour deployer…"
  ssh-keygen -t ed25519 -f "${KEY_PATH}" -N "" -C "deployer@$(hostname)"
  
  # Prépare le dossier .ssh de deployer
  mkdir -p /home/deployer/.ssh
  chmod 700 /home/deployer/.ssh
  
  # Installe la clé publique
  cat "${KEY_PATH}.pub" >> /home/deployer/.ssh/authorized_keys
  chmod 600 /home/deployer/.ssh/authorized_keys
  chown -R deployer:deployer /home/deployer/.ssh
  
  echo "  → Clé privée : ${KEY_PATH}"
  echo "  → Clé publique installée dans /home/deployer/.ssh/authorized_keys"
else
  echo "→ Clé SSH pour deployer déjà existante (${KEY_PATH}), on ne la régénère pas."
fi

# 4) Installation des paquets de sécurité
apt install -y ufw fail2ban

# 5) Configuration UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 1433/tcp       # port SQL Server
ufw allow 5000/tcp       # port API .NET
ufw allow 8080/tcp       # port API Rust
ufw allow http           # si vous hébergez un front
ufw allow https          # pour TLS
ufw --force enable

# 6) Activation de fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

echo "✔️  init_security.sh terminé."
exit 0
