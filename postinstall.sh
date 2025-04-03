#!/bin/bash
# → C’est un script bash, exécuté sous Linux.

# === VARIABLES ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")       # → Crée un timestamp (ex: 20250331_141500)
LOG_DIR="./logs"                         # → Dossier où seront stockés les logs
LOG_FILE="$LOG_DIR/postinstall_$TIMESTAMP.log"  # → Nom du fichier log avec timestamp
CONFIG_DIR="./config"                    # → Dossier avec fichiers de config personnalisés
PACKAGE_LIST="./lists/packages.txt"      # → Fichier contenant la liste des paquets à installer
USERNAME=$(logname)                      # → Récupère le nom de l’utilisateur connecté (hors root)
USER_HOME="/home/$USERNAME"              # → Son répertoire personnel

# === FUNCTIONS ===
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
  # → Fonction qui affiche et écrit dans le fichier log
}

check_and_install() {
  local pkg=$1
  if dpkg -s "$pkg" &>/dev/null; then
    log "$pkg is already installed."
  else
    log "Installing $pkg..."
    apt install -y "$pkg" &>>"$LOG_FILE"
    if [ $? -eq 0 ]; then
      log "$pkg successfully installed."
    else
      log "Failed to install $pkg."
    fi
  fi
}
# → Fonction pour vérifier si un paquet est installé, sinon l’installer

ask_yes_no() {
  read -p "$1 [y/N]: " answer
  case "$answer" in
    [Yy]* ) return 0 ;; # → Si "y" ou "Y", retourne vrai
    * ) return 1 ;;     # → Sinon, retourne faux
  esac
}
# → Fonction pour poser une question Oui/Non à l’utilisateur

# === INITIAL SETUP ===
mkdir -p "$LOG_DIR"          # → Crée le dossier des logs s’il n’existe pas
touch "$LOG_FILE"            # → Crée le fichier de log
log "Starting post-installation script. Logged user: $USERNAME"

if [ "$EUID" -ne 0 ]; then
  log "This script must be run as root."
  exit 1
fi
# → Vérifie que le script est lancé en root (obligatoire pour installer/configurer)

# === 1. SYSTEM UPDATE ===
log "Updating system packages..."
apt update && apt upgrade -y &>>"$LOG_FILE"
# → Met à jour les paquets système, log les sorties

# === 2. PACKAGE INSTALLATION ===
if [ -f "$PACKAGE_LIST" ]; then
  log "Reading package list from $PACKAGE_LIST"
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    check_and_install "$pkg"
  done < "$PACKAGE_LIST"
else
  log "Package list file $PACKAGE_LIST not found. Skipping package installation."
fi
# → Lit chaque ligne du fichier `packages.txt` (ignore les lignes vides ou avec #),
#   puis installe chaque paquet

# === 3. UPDATE MOTD ===
if [ -f "$CONFIG_DIR/motd.txt" ]; then
  cp "$CONFIG_DIR/motd.txt" /etc/motd
  log "MOTD updated."
else
  log "motd.txt not found."
fi
# → Remplace le message de bienvenue terminal

# === 4. CUSTOM .bashrc ===
if [ -f "$CONFIG_DIR/bashrc.append" ]; then
  cat "$CONFIG_DIR/bashrc.append" >> "$USER_HOME/.bashrc"
  chown "$USERNAME:$USERNAME" "$USER_HOME/.bashrc"
  log ".bashrc customized."
else
  log "bashrc.append not found."
fi
# → Ajoute du contenu personnalisé à `.bashrc`

# === 5. CUSTOM .nanorc ===
if [ -f "$CONFIG_DIR/nanorc.append" ]; then
  cat "$CONFIG_DIR/nanorc.append" >> "$USER_HOME/.nanorc"
  chown "$USERNAME:$USERNAME" "$USER_HOME/.nanorc"
  log ".nanorc customized."
else
  log "nanorc.append not found."
fi
# → Pareil pour `.nanorc` (config de l’éditeur nano)

# === 6. ADD SSH PUBLIC KEY ===
if ask_yes_no "Would you like to add a public SSH key?"; then
  read -p "Paste your public SSH key: " ssh_key
  mkdir -p "$USER_HOME/.ssh"
  echo "$ssh_key" >> "$USER_HOME/.ssh/authorized_keys"
  chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
  chmod 700 "$USER_HOME/.ssh"
  chmod 600 "$USER_HOME/.ssh/authorized_keys"
  log "SSH public key added."
fi
# → Demande si tu veux ajouter une clé SSH,
#   puis crée `.ssh/authorized_keys` avec les bons droits

# === 7. SSH CONFIGURATION: KEY AUTH ONLY ===
if [ -f /etc/ssh/sshd_config ]; then
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart ssh
  log "SSH configured to accept key-based authentication only."
else
  log "sshd_config file not found."
fi
# → Modifie la config SSH pour forcer l’utilisation de clés (désactive le mot de passe)

log "Post-installation script completed."
# → Fin du script

exit
