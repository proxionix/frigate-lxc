#!/usr/bin/env bash

# Copyright (c) 2024 Proxionix
# License: MIT

# Importation des utilitaires
source /scripts/utils/hardware.sh
source /scripts/utils/network.sh

# Variables globales
FRIGATE_VERSION="0.15.0"
GITHUB_REPO="blakeblackshear/frigate"
LOG_FILE="/var/log/frigate-install.log"
INSTALL_DIR="/opt/frigate"
CONFIG_DIR="/config"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction de journalisation
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a $LOG_FILE ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a $LOG_FILE ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a $LOG_FILE ;;
    esac
}

# Vérification des prérequis système
check_system_requirements() {
    log "INFO" "Vérification des prérequis système..."
    
    # Vérification CPU
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        log "ERROR" "Minimum 2 cœurs CPU requis (détecté: $cpu_cores)"
        exit 1
    fi

    # Vérification RAM
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 4096 ]; then
        log "WARN" "4GB RAM recommandé (détecté: ${total_ram}MB)"
    fi

    # Vérification espace disque
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$free_space" -lt 20 ]; then
        log "WARN" "20GB d'espace libre recommandé (détecté: ${free_space}GB)"
    fi
}

# Installation des dépendances
install_dependencies() {
    log "INFO" "Installation des dépendances système..."
    apt-get update
    apt-get install -y \
        curl sudo mc git gpg \
        ca-certificates automake \
        build-essential xz-utils \
        libtool ccache pkg-config \
        python3 python3-pip \
        nodejs npm \
        ffmpeg v4l-utils \
        libavcodec-dev libavformat-dev \
        libswscale-dev libv4l-dev \
        libxvidcore-dev libx264-dev \
        libjpeg-dev libpng-dev \
        libtiff-dev gfortran \
        libatlas-base-dev libssl-dev \
        libusb-1.0-0-dev jq moreutils
}

# Configuration du hardware
setup_hardware() {
    log "INFO" "Configuration du hardware..."
    
    # Installation des pilotes GPU selon le matériel détecté
    detect_and_setup_gpu
    
    if [[ "$CTTYPE" == "0" ]]; then
        configure_privileged_container
    else
        configure_unprivileged_container
    fi
}

# Installation de Frigate
install_frigate() {
    log "INFO" "Installation de Frigate v${FRIGATE_VERSION}..."
    
    # Création des répertoires
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Téléchargement et extraction
    cd "$INSTALL_DIR"
    wget -q "https://github.com/${GITHUB_REPO}/archive/refs/tags/v${FRIGATE_VERSION}.tar.gz" -O frigate.tar.gz
    tar xzf frigate.tar.gz --strip-components=1
    rm frigate.tar.gz

    # Installation des dépendances Python
    pip3 install -r requirements.txt
    
    # Build de l'interface web
    cd web
    npm install
    npm run build
}

# Configuration du service systemd
setup_service() {
    log "INFO" "Configuration du service Frigate..."
    
    # Création de l'utilisateur frigate
    useradd -r -s /bin/false frigate || true
    
    # Configuration du service
    cat > /etc/systemd/system/frigate.service << EOF
[Unit]
Description=Frigate NVR
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=frigate
Group=frigate
WorkingDirectory=${INSTALL_DIR}
Environment="FRIGATE_CONFIG_PATH=${CONFIG_DIR}/config.yml"
ExecStart=/usr/local/bin/python3 -m frigate
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

    # Configuration de base
    cat > "${CONFIG_DIR}/config.yml" << EOF
mqtt:
  enabled: false

cameras:
  # Ajoutez vos caméras ici
  test:
    ffmpeg:
      inputs:
        - path: rtsp://exemple.com/stream
          roles:
            - detect
            - record

detectors:
  cpu:
    type: cpu
    
EOF

    # Ajustement des permissions
    chown -R frigate:frigate "$INSTALL_DIR"
    chown -R frigate:frigate "$CONFIG_DIR"
    
    # Activation du service
    systemctl daemon-reload
    systemctl enable --now frigate
}

# Fonction principale
main() {
    log "INFO" "Démarrage de l'installation de Frigate..."
    
    check_system_requirements
    install_dependencies
    setup_hardware
    install_frigate
    setup_service
    
    log "INFO" "Installation terminée avec succès!"
    log "INFO" "Interface web disponible sur: http://$(hostname):5000"
    log "INFO" "Fichier de configuration: ${CONFIG_DIR}/config.yml"
}

# Gestion des erreurs
set -euo pipefail
trap 'log "ERROR" "Une erreur est survenue à la ligne $LINENO"' ERR

# Lancement du script
main "$@"
